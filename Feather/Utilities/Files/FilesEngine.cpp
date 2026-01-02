#include "FilesEngine.hpp"
#include <fstream>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cstdarg>
#include <sstream>
#include <iomanip>
#include <CommonCrypto/CommonDigest.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <compression.h>
#include <vector>
#include <algorithm>

// Thread-local error message storage
static thread_local char lastErrorMessage[1024] = {0};

// Helper function to set error message
static void setError(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vsnprintf(lastErrorMessage, sizeof(lastErrorMessage), format, args);
    va_end(args);
}

// MARK: - Magic Byte Detection

static const struct MagicSignature {
    const uint8_t* bytes;
    size_t length;
    FileType type;
} magicSignatures[] = {
    // Mach-O magic numbers
    {(const uint8_t*)"\xFE\xED\xFA\xCE", 4, FileTypeMachO}, // 32-bit
    {(const uint8_t*)"\xFE\xED\xFA\xCF", 4, FileTypeMachO}, // 64-bit
    {(const uint8_t*)"\xCE\xFA\xED\xFE", 4, FileTypeMachO}, // 32-bit reverse
    {(const uint8_t*)"\xCF\xFA\xED\xFE", 4, FileTypeMachO}, // 64-bit reverse
    {(const uint8_t*)"\xCA\xFE\xBA\xBE", 4, FileTypeMachO}, // Fat binary
    {(const uint8_t*)"\xBE\xBA\xFE\xCA", 4, FileTypeMachO}, // Fat binary reverse
    
    // Archives
    {(const uint8_t*)"PK\x03\x04", 4, FileTypeArchive}, // ZIP/IPA
    {(const uint8_t*)"PK\x05\x06", 4, FileTypeArchive}, // ZIP empty
    {(const uint8_t*)"PK\x07\x08", 4, FileTypeArchive}, // ZIP spanned
    
    // Images
    {(const uint8_t*)"\xFF\xD8\xFF", 3, FileTypeImage}, // JPEG
    {(const uint8_t*)"\x89PNG", 4, FileTypeImage}, // PNG
    {(const uint8_t*)"GIF89a", 6, FileTypeImage}, // GIF
    {(const uint8_t*)"GIF87a", 6, FileTypeImage}, // GIF
    
    // Video
    {(const uint8_t*)"ftyp", 4, FileTypeVideo}, // MP4/MOV (at offset 4)
    
    // PDF
    {(const uint8_t*)"%PDF", 4, FileTypePDF},
    
    // XML/Plist
    {(const uint8_t*)"<?xml", 5, FileTypeXML},
    {(const uint8_t*)"bplist", 6, FileTypePlist}, // Binary plist
};

FileType detectFileType(const char* filePath) {
    if (!filePath) {
        setError("Invalid file path");
        return FileTypeUnknown;
    }
    
    int fd = open(filePath, O_RDONLY);
    if (fd < 0) {
        setError("Cannot open file: %s", filePath);
        return FileTypeUnknown;
    }
    
    uint8_t buffer[32];
    ssize_t bytesRead = read(fd, buffer, sizeof(buffer));
    close(fd);
    
    if (bytesRead < 0) {
        setError("Cannot read file: %s", filePath);
        return FileTypeUnknown;
    }
    
    // Check magic signatures
    for (const auto& sig : magicSignatures) {
        if ((size_t)bytesRead >= sig.length) {
            if (memcmp(buffer, sig.bytes, sig.length) == 0) {
                // Special handling for IPA (ZIP with .ipa extension)
                if (sig.type == FileTypeArchive) {
                    const char* ext = strrchr(filePath, '.');
                    if (ext && strcasecmp(ext, ".ipa") == 0) {
                        return FileTypeIPA;
                    }
                }
                return sig.type;
            }
        }
    }
    
    // Check for video files (ftyp at offset 4)
    if (bytesRead >= 12 && memcmp(buffer + 4, "ftyp", 4) == 0) {
        return FileTypeVideo;
    }
    
    // Check file extension as fallback
    const char* ext = strrchr(filePath, '.');
    if (ext) {
        ext++; // Skip the dot
        if (strcasecmp(ext, "json") == 0) return FileTypeJSON;
        if (strcasecmp(ext, "plist") == 0) return FileTypePlist;
        if (strcasecmp(ext, "xml") == 0) return FileTypeXML;
        if (strcasecmp(ext, "txt") == 0 || strcasecmp(ext, "text") == 0) return FileTypeText;
        if (strcasecmp(ext, "p12") == 0 || strcasecmp(ext, "pfx") == 0) return FileTypeP12;
        if (strcasecmp(ext, "mobileprovision") == 0) return FileTypeMobileProvision;
        if (strcasecmp(ext, "dylib") == 0) return FileTypeDylib;
        if (strcasecmp(ext, "mp3") == 0 || strcasecmp(ext, "m4a") == 0) return FileTypeAudio;
    }
    
    // Check if it's plain text
    bool isText = true;
    for (ssize_t i = 0; i < bytesRead; i++) {
        if (buffer[i] == 0 || (buffer[i] < 32 && buffer[i] != '\n' && buffer[i] != '\r' && buffer[i] != '\t')) {
            isText = false;
            break;
        }
    }
    
    if (isText) return FileTypeText;
    
    return FileTypeUnknown;
}

// MARK: - File Info

FileInfo getFileInfo(const char* filePath) {
    FileInfo info = {0};
    
    if (!filePath) {
        setError("Invalid file path");
        return info;
    }
    
    strncpy(info.path, filePath, sizeof(info.path) - 1);
    
    const char* fileName = strrchr(filePath, '/');
    if (fileName) {
        fileName++;
    } else {
        fileName = filePath;
    }
    strncpy(info.name, fileName, sizeof(info.name) - 1);
    
    struct stat st;
    if (stat(filePath, &st) == 0) {
        info.size = st.st_size;
        info.isDirectory = S_ISDIR(st.st_mode);
        info.isExecutable = (st.st_mode & S_IXUSR) != 0;
    } else {
        setError("Cannot stat file: %s", filePath);
    }
    
    if (!info.isDirectory) {
        info.type = detectFileType(filePath);
        
        // Read magic signature
        int fd = open(filePath, O_RDONLY);
        if (fd >= 0) {
            uint8_t magic[16];
            ssize_t read_bytes = read(fd, magic, sizeof(magic));
            close(fd);
            
            if (read_bytes > 0) {
                char* sig = info.magicSignature;
                for (int i = 0; i < read_bytes && i < 8; i++) {
                    snprintf(sig, 4, "%02X ", magic[i]);
                    sig += 3;
                }
            }
        }
    }
    
    return info;
}

// MARK: - Hashing

HashResult calculateHashes(const char* filePath) {
    HashResult result = {0};
    
    if (!filePath) {
        setError("Invalid file path");
        return result;
    }
    
    std::ifstream file(filePath, std::ios::binary);
    if (!file.is_open()) {
        setError("Cannot open file for hashing: %s", filePath);
        return result;
    }
    
    CC_MD5_CTX md5Context;
    CC_SHA1_CTX sha1Context;
    CC_SHA256_CTX sha256Context;
    
    CC_MD5_Init(&md5Context);
    CC_SHA1_Init(&sha1Context);
    CC_SHA256_Init(&sha256Context);
    
    char buffer[8192];
    while (file.read(buffer, sizeof(buffer)) || file.gcount() > 0) {
        size_t count = file.gcount();
        CC_MD5_Update(&md5Context, buffer, count);
        CC_SHA1_Update(&sha1Context, buffer, count);
        CC_SHA256_Update(&sha256Context, buffer, count);
    }
    
    file.close();
    
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    unsigned char sha1[CC_SHA1_DIGEST_LENGTH];
    unsigned char sha256[CC_SHA256_DIGEST_LENGTH];
    
    CC_MD5_Final(md5, &md5Context);
    CC_SHA1_Final(sha1, &sha1Context);
    CC_SHA256_Final(sha256, &sha256Context);
    
    // Convert to hex strings
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        sprintf(result.md5 + (i * 2), "%02x", md5[i]);
    }
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        sprintf(result.sha1 + (i * 2), "%02x", sha1[i]);
    }
    
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        sprintf(result.sha256 + (i * 2), "%02x", sha256[i]);
    }
    
    return result;
}

// MARK: - IPA Analysis

IPAInfo analyzeIPA(const char* ipaPath) {
    IPAInfo info = {0};
    
    if (!ipaPath) {
        setError("Invalid IPA path");
        return info;
    }
    
    // For now, return basic stub info
    // Full implementation would need to unzip and parse Info.plist
    strncpy(info.bundleId, "com.unknown.app", sizeof(info.bundleId) - 1);
    strncpy(info.version, "1.0", sizeof(info.version) - 1);
    strncpy(info.minOSVersion, "13.0", sizeof(info.minOSVersion) - 1);
    strncpy(info.displayName, "Unknown App", sizeof(info.displayName) - 1);
    info.hasProvisioning = false;
    info.isSigned = false;
    info.numberOfExecutables = 1;
    
    return info;
}

// MARK: - Mach-O Analysis

MachOInfo analyzeMachO(const char* machoPath) {
    MachOInfo info = {0};
    
    if (!machoPath) {
        setError("Invalid Mach-O path");
        return info;
    }
    
    int fd = open(machoPath, O_RDONLY);
    if (fd < 0) {
        setError("Cannot open Mach-O file: %s", machoPath);
        return info;
    }
    
    uint32_t magic;
    if (read(fd, &magic, sizeof(magic)) != sizeof(magic)) {
        close(fd);
        setError("Cannot read magic number");
        return info;
    }
    
    info.isValid = true;
    
    switch (magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            info.is64Bit = false;
            info.architectureCount = 1;
            strncpy(info.architectures, "arm", sizeof(info.architectures) - 1);
            break;
            
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            info.is64Bit = true;
            info.architectureCount = 1;
            strncpy(info.architectures, "arm64", sizeof(info.architectures) - 1);
            break;
            
        case FAT_MAGIC:
        case FAT_CIGAM:
        case FAT_MAGIC_64:
        case FAT_CIGAM_64: {
            // Fat binary
            struct fat_header header;
            lseek(fd, 0, SEEK_SET);
            if (read(fd, &header, sizeof(header)) == sizeof(header)) {
                uint32_t nfat_arch = OSSwapBigToHostInt32(header.nfat_arch);
                info.architectureCount = nfat_arch;
                strncpy(info.architectures, "universal", sizeof(info.architectures) - 1);
            }
            break;
        }
            
        default:
            info.isValid = false;
            close(fd);
            setError("Invalid Mach-O magic number");
            return info;
    }
    
    close(fd);
    return info;
}

// MARK: - Directory Scanning

FileInfo* scanDirectory(const char* dirPath, bool recursive, int* count) {
    if (!dirPath || !count) {
        setError("Invalid parameters for directory scan");
        return nullptr;
    }
    
    std::vector<FileInfo> files;
    
    DIR* dir = opendir(dirPath);
    if (!dir) {
        setError("Cannot open directory: %s", dirPath);
        *count = 0;
        return nullptr;
    }
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        // Skip . and ..
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        
        char fullPath[1024];
        snprintf(fullPath, sizeof(fullPath), "%s/%s", dirPath, entry->d_name);
        
        FileInfo info = getFileInfo(fullPath);
        files.push_back(info);
        
        if (recursive && info.isDirectory) {
            int subCount = 0;
            FileInfo* subFiles = scanDirectory(fullPath, true, &subCount);
            if (subFiles) {
                for (int i = 0; i < subCount; i++) {
                    files.push_back(subFiles[i]);
                }
                free(subFiles);
            }
        }
    }
    
    closedir(dir);
    
    *count = files.size();
    
    if (files.empty()) {
        return nullptr;
    }
    
    // Allocate and copy to C array
    FileInfo* result = (FileInfo*)malloc(sizeof(FileInfo) * files.size());
    if (result) {
        memcpy(result, files.data(), sizeof(FileInfo) * files.size());
    }
    
    return result;
}

// MARK: - Bulk Operations

int bulkDelete(const char** paths, int count) {
    if (!paths || count <= 0) {
        setError("Invalid parameters for bulk delete");
        return 0;
    }
    
    int deleted = 0;
    for (int i = 0; i < count; i++) {
        if (remove(paths[i]) == 0) {
            deleted++;
        }
    }
    
    return deleted;
}

int bulkCopy(const char** sourcePaths, const char* destDir, int count) {
    if (!sourcePaths || !destDir || count <= 0) {
        setError("Invalid parameters for bulk copy");
        return 0;
    }
    
    int copied = 0;
    for (int i = 0; i < count; i++) {
        const char* fileName = strrchr(sourcePaths[i], '/');
        if (!fileName) fileName = sourcePaths[i];
        else fileName++;
        
        char destPath[1024];
        snprintf(destPath, sizeof(destPath), "%s/%s", destDir, fileName);
        
        std::ifstream src(sourcePaths[i], std::ios::binary);
        std::ofstream dst(destPath, std::ios::binary);
        
        if (src && dst) {
            dst << src.rdbuf();
            if (dst.good()) {
                copied++;
            }
        }
    }
    
    return copied;
}

int bulkMove(const char** sourcePaths, const char* destDir, int count) {
    if (!sourcePaths || !destDir || count <= 0) {
        setError("Invalid parameters for bulk move");
        return 0;
    }
    
    int moved = 0;
    for (int i = 0; i < count; i++) {
        const char* fileName = strrchr(sourcePaths[i], '/');
        if (!fileName) fileName = sourcePaths[i];
        else fileName++;
        
        char destPath[1024];
        snprintf(destPath, sizeof(destPath), "%s/%s", destDir, fileName);
        
        if (rename(sourcePaths[i], destPath) == 0) {
            moved++;
        }
    }
    
    return moved;
}

// MARK: - Archive Operations

int createZip(const char** sourcePaths, int count, const char* outputPath) {
    if (!sourcePaths || !outputPath || count <= 0) {
        setError("Invalid parameters for create zip");
        return -1;
    }
    
    // Stub implementation - would need full zip library
    setError("ZIP creation not yet implemented");
    return -1;
}

int extractZip(const char* zipPath, const char* destDir) {
    if (!zipPath || !destDir) {
        setError("Invalid parameters for extract zip");
        return -1;
    }
    
    // Stub implementation - would need full zip library
    setError("ZIP extraction not yet implemented");
    return -1;
}

bool validateArchive(const char* archivePath) {
    if (!archivePath) {
        setError("Invalid archive path");
        return false;
    }
    
    FileType type = detectFileType(archivePath);
    if (type != FileTypeArchive && type != FileTypeIPA) {
        setError("Not an archive file");
        return false;
    }
    
    // Basic validation - check if file is readable
    int fd = open(archivePath, O_RDONLY);
    if (fd < 0) {
        setError("Cannot open archive");
        return false;
    }
    
    close(fd);
    return true;
}

// MARK: - File Comparison

bool compareFiles(const char* file1, const char* file2, uint64_t* diffSize) {
    if (!file1 || !file2) {
        setError("Invalid file paths for comparison");
        return false;
    }
    
    std::ifstream f1(file1, std::ios::binary);
    std::ifstream f2(file2, std::ios::binary);
    
    if (!f1 || !f2) {
        setError("Cannot open files for comparison");
        return false;
    }
    
    f1.seekg(0, std::ios::end);
    f2.seekg(0, std::ios::end);
    
    uint64_t size1 = f1.tellg();
    uint64_t size2 = f2.tellg();
    
    if (size1 != size2) {
        if (diffSize) *diffSize = std::abs((int64_t)(size1 - size2));
        return false;
    }
    
    f1.seekg(0);
    f2.seekg(0);
    
    char buf1[8192], buf2[8192];
    uint64_t differences = 0;
    
    while (f1 && f2) {
        f1.read(buf1, sizeof(buf1));
        f2.read(buf2, sizeof(buf2));
        
        size_t count1 = f1.gcount();
        size_t count2 = f2.gcount();
        
        if (count1 != count2) {
            if (diffSize) *diffSize = differences + std::abs((int64_t)(count1 - count2));
            return false;
        }
        
        for (size_t i = 0; i < count1; i++) {
            if (buf1[i] != buf2[i]) {
                differences++;
            }
        }
    }
    
    if (diffSize) *diffSize = differences;
    
    return differences == 0;
}

// MARK: - Integrity Check

bool checkIntegrity(const char* filePath, const char* expectedHash) {
    if (!filePath || !expectedHash) {
        setError("Invalid parameters for integrity check");
        return false;
    }
    
    HashResult hashes = calculateHashes(filePath);
    
    // Compare with SHA256 (most common)
    return strcasecmp(hashes.sha256, expectedHash) == 0;
}

// MARK: - Memory Management

void freeFileInfoArray(FileInfo* array) {
    if (array) {
        free(array);
    }
}

// MARK: - Error Handling

const char* getLastError() {
    return lastErrorMessage;
}
