import Foundation

// MARK: - Swift Wrapper for FilesEngine

/// Swift-friendly wrapper around the C++ FilesEngine
class FilesEngine {
    
    // MARK: - File Type Enum
    enum FileType: Int32 {
        case unknown = 0
        case text
        case image
        case video
        case audio
        case archive
        case ipa
        case machO
        case plist
        case json
        case xml
        case pdf
        case p12
        case mobileProvision
        case dylib
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .text: return "Text"
            case .image: return "Image"
            case .video: return "Video"
            case .audio: return "Audio"
            case .archive: return "Archive"
            case .ipa: return "IPA"
            case .machO: return "Mach-O"
            case .plist: return "Property List"
            case .json: return "JSON"
            case .xml: return "XML"
            case .pdf: return "PDF"
            case .p12: return "Certificate"
            case .mobileProvision: return "Provisioning Profile"
            case .dylib: return "Dynamic Library"
            }
        }
    }
    
    // MARK: - File Information
    struct FileInformation {
        let path: String
        let name: String
        let type: FileType
        let size: UInt64
        let magicSignature: String
        let isDirectory: Bool
        let isExecutable: Bool
        let isSigned: Bool
    }
    
    // MARK: - Hash Information
    struct HashInformation {
        let md5: String
        let sha1: String
        let sha256: String
    }
    
    // MARK: - IPA Information
    struct IPAInformation {
        let bundleId: String
        let version: String
        let minOSVersion: String
        let displayName: String
        let hasProvisioning: Bool
        let isSigned: Bool
        let numberOfExecutables: Int
    }
    
    // MARK: - Mach-O Information
    struct MachOInformation {
        let isValid: Bool
        let is64Bit: Bool
        let isArm64e: Bool
        let architectureCount: Int
        let architectures: String
        let hasEncryption: Bool
        let isPIE: Bool
        let numberOfLoadCommands: Int
    }
    
    // MARK: - Core Functions
    
    /// Detect file type by analyzing magic bytes
    static func detectFileType(at path: String) -> FileType? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        let rawType = __ObjC.detectFileType(cStr)
        return FileType(rawValue: rawType)
    }
    
    /// Get detailed file information
    static func getFileInfo(at path: String) -> FileInformation? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        var cInfo = __ObjC.getFileInfo(cStr)
        
        let pathStr = withUnsafeBytes(of: &cInfo.path) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let nameStr = withUnsafeBytes(of: &cInfo.name) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let magicStr = withUnsafeBytes(of: &cInfo.magicSignature) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        return FileInformation(
            path: pathStr,
            name: nameStr,
            type: FileType(rawValue: cInfo.type) ?? .unknown,
            size: cInfo.size,
            magicSignature: magicStr,
            isDirectory: cInfo.isDirectory,
            isExecutable: cInfo.isExecutable,
            isSigned: cInfo.isSigned
        )
    }
    
    /// Calculate file hashes (MD5, SHA1, SHA256)
    static func calculateHashes(for path: String) -> HashInformation? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        var cHashes = __ObjC.calculateHashes(cStr)
        
        let md5Str = withUnsafeBytes(of: &cHashes.md5) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let sha1Str = withUnsafeBytes(of: &cHashes.sha1) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let sha256Str = withUnsafeBytes(of: &cHashes.sha256) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        return HashInformation(
            md5: md5Str,
            sha1: sha1Str,
            sha256: sha256Str
        )
    }
    
    /// Analyze IPA file
    static func analyzeIPA(at path: String) -> IPAInformation? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        var cInfo = __ObjC.analyzeIPA(cStr)
        
        let bundleIdStr = withUnsafeBytes(of: &cInfo.bundleId) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let versionStr = withUnsafeBytes(of: &cInfo.version) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let minOSStr = withUnsafeBytes(of: &cInfo.minOSVersion) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        let displayNameStr = withUnsafeBytes(of: &cInfo.displayName) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        return IPAInformation(
            bundleId: bundleIdStr,
            version: versionStr,
            minOSVersion: minOSStr,
            displayName: displayNameStr,
            hasProvisioning: cInfo.hasProvisioning,
            isSigned: cInfo.isSigned,
            numberOfExecutables: Int(cInfo.numberOfExecutables)
        )
    }
    
    /// Analyze Mach-O binary
    static func analyzeMachO(at path: String) -> MachOInformation? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        var cInfo = __ObjC.analyzeMachO(cStr)
        
        let archStr = withUnsafeBytes(of: &cInfo.architectures) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        return MachOInformation(
            isValid: cInfo.isValid,
            is64Bit: cInfo.is64Bit,
            isArm64e: cInfo.isArm64e,
            architectureCount: Int(cInfo.architectureCount),
            architectures: archStr,
            hasEncryption: cInfo.hasEncryption,
            isPIE: cInfo.isPIE,
            numberOfLoadCommands: Int(cInfo.numberOfLoadCommands)
        )
    }
    
    /// Scan directory for files
    static func scanDirectory(at path: String, recursive: Bool = false) -> [FileInformation]? {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return nil }
        
        var count: Int32 = 0
        guard let cArray = __ObjC.scanDirectory(cStr, recursive, &count) else {
            return nil
        }
        
        defer { __ObjC.freeFileInfoArray(cArray) }
        
        var results: [FileInformation] = []
        for i in 0..<Int(count) {
            var cInfo = cArray[i]
            
            let pathStr = withUnsafeBytes(of: &cInfo.path) { ptr in
                String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            
            let nameStr = withUnsafeBytes(of: &cInfo.name) { ptr in
                String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            
            let magicStr = withUnsafeBytes(of: &cInfo.magicSignature) { ptr in
                String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            
            let info = FileInformation(
                path: pathStr,
                name: nameStr,
                type: FileType(rawValue: cInfo.type) ?? .unknown,
                size: cInfo.size,
                magicSignature: magicStr,
                isDirectory: cInfo.isDirectory,
                isExecutable: cInfo.isExecutable,
                isSigned: cInfo.isSigned
            )
            results.append(info)
        }
        
        return results
    }
    
    /// Bulk delete files
    static func bulkDelete(paths: [String]) -> Int {
        let cPaths = paths.map { ($0 as NSString).utf8String! }
        let cPathArray = cPaths.map { UnsafePointer<Int8>($0) }
        
        return Int(__ObjC.bulkDelete(cPathArray, Int32(cPathArray.count)))
    }
    
    /// Bulk copy files
    static func bulkCopy(sourcePaths: [String], to destDir: String) -> Int {
        let cPaths = sourcePaths.map { ($0 as NSString).utf8String! }
        let cPathArray = cPaths.map { UnsafePointer<Int8>($0) }
        let cDestDir = (destDir as NSString).utf8String!
        
        return Int(__ObjC.bulkCopy(cPathArray, cDestDir, Int32(cPathArray.count)))
    }
    
    /// Bulk move files
    static func bulkMove(sourcePaths: [String], to destDir: String) -> Int {
        let cPaths = sourcePaths.map { ($0 as NSString).utf8String! }
        let cPathArray = cPaths.map { UnsafePointer<Int8>($0) }
        let cDestDir = (destDir as NSString).utf8String!
        
        return Int(__ObjC.bulkMove(cPathArray, cDestDir, Int32(cPathArray.count)))
    }
    
    /// Validate archive integrity
    static func validateArchive(at path: String) -> Bool {
        let cPath = (path as NSString).utf8String
        guard let cStr = cPath else { return false }
        
        return __ObjC.validateArchive(cStr)
    }
    
    /// Compare two files
    static func compareFiles(_ file1: String, _ file2: String) -> (identical: Bool, diffSize: UInt64) {
        let cPath1 = (file1 as NSString).utf8String
        let cPath2 = (file2 as NSString).utf8String
        guard let cStr1 = cPath1, let cStr2 = cPath2 else {
            return (false, 0)
        }
        
        var diffSize: UInt64 = 0
        let identical = __ObjC.compareFiles(cStr1, cStr2, &diffSize)
        
        return (identical, diffSize)
    }
    
    /// Check file integrity against expected hash
    static func checkIntegrity(at path: String, expectedHash: String) -> Bool {
        let cPath = (path as NSString).utf8String
        let cHash = (expectedHash as NSString).utf8String
        guard let cStr = cPath, let cHashStr = cHash else { return false }
        
        return __ObjC.checkIntegrity(cStr, cHashStr)
    }
    
    /// Get last error message
    static func getLastError() -> String? {
        guard let cError = __ObjC.getLastError() else { return nil }
        return String(cString: cError)
    }
}
