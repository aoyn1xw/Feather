#ifndef FilesEngine_h
#define FilesEngine_h

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - File Type Detection
typedef enum {
    FileTypeUnknown = 0,
    FileTypeText,
    FileTypeImage,
    FileTypeVideo,
    FileTypeAudio,
    FileTypeArchive,
    FileTypeIPA,
    FileTypeMachO,
    FileTypePlist,
    FileTypeJSON,
    FileTypeXML,
    FileTypePDF,
    FileTypeP12,
    FileTypeMobileProvision,
    FileTypeDylib
} FileType;

// MARK: - File Info Structure
typedef struct {
    char path[1024];
    char name[256];
    FileType type;
    uint64_t size;
    char magicSignature[64];
    bool isDirectory;
    bool isExecutable;
    bool isSigned;
} FileInfo;

// MARK: - Hash Result Structure
typedef struct {
    char md5[33];
    char sha1[41];
    char sha256[65];
} HashResult;

// MARK: - IPA Analysis Structure
typedef struct {
    char bundleId[256];
    char version[64];
    char minOSVersion[32];
    char displayName[256];
    bool hasProvisioning;
    bool isSigned;
    int numberOfExecutables;
} IPAInfo;

// MARK: - Mach-O Analysis Structure
typedef struct {
    bool isValid;
    bool is64Bit;
    bool isArm64e;
    int architectureCount;
    char architectures[256];
    bool hasEncryption;
    bool isPIE;
    int numberOfLoadCommands;
} MachOInfo;

// MARK: - Core API

/**
 * Detect file type by magic bytes
 */
FileType detectFileType(const char* filePath);

/**
 * Get detailed file information
 */
FileInfo getFileInfo(const char* filePath);

/**
 * Calculate file hashes (MD5, SHA1, SHA256)
 */
HashResult calculateHashes(const char* filePath);

/**
 * Analyze IPA file
 */
IPAInfo analyzeIPA(const char* ipaPath);

/**
 * Analyze Mach-O binary
 */
MachOInfo analyzeMachO(const char* machoPath);

/**
 * Fast directory scanning
 * Returns array of FileInfo structures
 * @param dirPath Directory to scan
 * @param recursive Whether to scan recursively
 * @param count Output parameter for number of files found
 * @return Array of FileInfo (caller must free)
 */
FileInfo* scanDirectory(const char* dirPath, bool recursive, int* count);

/**
 * Bulk delete files
 * @param paths Array of file paths
 * @param count Number of paths
 * @return Number of successfully deleted files
 */
int bulkDelete(const char** paths, int count);

/**
 * Bulk copy files
 * @param sourcePaths Array of source paths
 * @param destDir Destination directory
 * @param count Number of files
 * @return Number of successfully copied files
 */
int bulkCopy(const char** sourcePaths, const char* destDir, int count);

/**
 * Bulk move files
 * @param sourcePaths Array of source paths
 * @param destDir Destination directory
 * @param count Number of files
 * @return Number of successfully moved files
 */
int bulkMove(const char** sourcePaths, const char* destDir, int count);

/**
 * Create zip archive
 * @param sourcePaths Array of file/directory paths to zip
 * @param count Number of items
 * @param outputPath Output zip file path
 * @return 0 on success, error code otherwise
 */
int createZip(const char** sourcePaths, int count, const char* outputPath);

/**
 * Extract zip archive
 * @param zipPath Path to zip file
 * @param destDir Destination directory
 * @return 0 on success, error code otherwise
 */
int extractZip(const char* zipPath, const char* destDir);

/**
 * Validate archive integrity
 * @param archivePath Path to archive
 * @return true if valid, false otherwise
 */
bool validateArchive(const char* archivePath);

/**
 * Compare two files (binary diff)
 * @param file1 First file path
 * @param file2 Second file path
 * @param diffSize Output parameter for size of differences
 * @return true if files are identical, false otherwise
 */
bool compareFiles(const char* file1, const char* file2, uint64_t* diffSize);

/**
 * Check file integrity
 * @param filePath File to check
 * @param expectedHash Expected hash (SHA256)
 * @return true if integrity check passes
 */
bool checkIntegrity(const char* filePath, const char* expectedHash);

/**
 * Free FileInfo array returned by scanDirectory
 */
void freeFileInfoArray(FileInfo* array);

/**
 * Get error message for last operation
 */
const char* getLastError();

#ifdef __cplusplus
}
#endif

#endif /* FilesEngine_h */
