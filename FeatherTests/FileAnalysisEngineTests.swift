import XCTest
@testable import Feather

class FileAnalysisEngineTests: XCTestCase {
    
    var testDirectory: URL!
    
    override func setUp() {
        super.setUp()
        // Create a temporary test directory
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAnalysisEngineTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        // Clean up test directory
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }
    
    // MARK: - File Type Detection Tests
    
    func testDetectTextFile() {
        let testFile = testDirectory.appendingPathComponent("test.txt")
        let content = "Hello, World!"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        let fileType = FileAnalysisEngine.detectFileType(at: testFile.path)
        XCTAssertEqual(fileType, .text, "Should detect text file")
    }
    
    func testDetectJSONFile() {
        let testFile = testDirectory.appendingPathComponent("test.json")
        let content = "{\"key\": \"value\"}"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        let fileType = FileAnalysisEngine.detectFileType(at: testFile.path)
        XCTAssertEqual(fileType, .json, "Should detect JSON file")
    }
    
    func testDetectPlistByExtension() {
        let testFile = testDirectory.appendingPathComponent("test.plist")
        let content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        let fileType = FileAnalysisEngine.detectFileType(at: testFile.path)
        XCTAssertTrue(fileType == .plist || fileType == .xml, "Should detect plist or XML file")
    }
    
    // MARK: - File Information Tests
    
    func testGetFileInformation() {
        let testFile = testDirectory.appendingPathComponent("info_test.txt")
        let content = "Test content for file info"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        guard let fileInfo = FileAnalysisEngine.getFileInformation(at: testFile.path) else {
            XCTFail("Should return file information")
            return
        }
        
        XCTAssertEqual(fileInfo.name, "info_test.txt", "Should have correct file name")
        XCTAssertEqual(fileInfo.path, testFile.path, "Should have correct path")
        XCTAssertFalse(fileInfo.isDirectory, "Should not be a directory")
        XCTAssertGreaterThan(fileInfo.size, 0, "Should have size greater than 0")
    }
    
    func testGetDirectoryInformation() {
        let testDir = testDirectory.appendingPathComponent("test_subdir")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        guard let dirInfo = FileAnalysisEngine.getFileInformation(at: testDir.path) else {
            XCTFail("Should return directory information")
            return
        }
        
        XCTAssertTrue(dirInfo.isDirectory, "Should be a directory")
        XCTAssertEqual(dirInfo.name, "test_subdir", "Should have correct directory name")
    }
    
    // MARK: - Hash Calculation Tests
    
    func testComputeHashes() {
        let testFile = testDirectory.appendingPathComponent("hash_test.txt")
        let content = "Test content for hashing"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        guard let hashInfo = FileAnalysisEngine.computeHashes(for: testFile.path) else {
            XCTFail("Should return hash information")
            return
        }
        
        XCTAssertFalse(hashInfo.md5.isEmpty, "MD5 hash should not be empty")
        XCTAssertFalse(hashInfo.sha1.isEmpty, "SHA1 hash should not be empty")
        XCTAssertFalse(hashInfo.sha256.isEmpty, "SHA256 hash should not be empty")
        
        XCTAssertEqual(hashInfo.md5.count, 32, "MD5 hash should be 32 characters")
        XCTAssertEqual(hashInfo.sha1.count, 40, "SHA1 hash should be 40 characters")
        XCTAssertEqual(hashInfo.sha256.count, 64, "SHA256 hash should be 64 characters")
    }
    
    func testHashConsistency() {
        let testFile = testDirectory.appendingPathComponent("consistency_test.txt")
        let content = "Consistent content"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        guard let hash1 = FileAnalysisEngine.computeHashes(for: testFile.path),
              let hash2 = FileAnalysisEngine.computeHashes(for: testFile.path) else {
            XCTFail("Should return hash information")
            return
        }
        
        XCTAssertEqual(hash1.md5, hash2.md5, "MD5 hashes should be consistent")
        XCTAssertEqual(hash1.sha1, hash2.sha1, "SHA1 hashes should be consistent")
        XCTAssertEqual(hash1.sha256, hash2.sha256, "SHA256 hashes should be consistent")
    }
    
    // MARK: - Directory Scanning Tests
    
    func testScanDirectory() {
        // Create test files
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let file2 = testDirectory.appendingPathComponent("file2.json")
        let subDir = testDirectory.appendingPathComponent("subdir")
        
        try? "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try? "Content 2".write(to: file2, atomically: true, encoding: .utf8)
        try? FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        let files = FileAnalysisEngine.scanDirectory(at: testDirectory.path, recursive: false)
        
        XCTAssertGreaterThanOrEqual(files.count, 3, "Should find at least 3 items")
        
        let fileNames = files.map { $0.name }
        XCTAssertTrue(fileNames.contains("file1.txt"), "Should find file1.txt")
        XCTAssertTrue(fileNames.contains("file2.json"), "Should find file2.json")
        XCTAssertTrue(fileNames.contains("subdir"), "Should find subdir")
    }
    
    func testScanDirectoryRecursive() {
        // Create nested structure
        let subDir = testDirectory.appendingPathComponent("subdir")
        try? FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        let file1 = testDirectory.appendingPathComponent("root.txt")
        let file2 = subDir.appendingPathComponent("nested.txt")
        
        try? "Root content".write(to: file1, atomically: true, encoding: .utf8)
        try? "Nested content".write(to: file2, atomically: true, encoding: .utf8)
        
        let files = FileAnalysisEngine.scanDirectory(at: testDirectory.path, recursive: true)
        
        let fileNames = files.map { $0.name }
        XCTAssertTrue(fileNames.contains("root.txt"), "Should find root file")
        XCTAssertTrue(fileNames.contains("nested.txt"), "Should find nested file")
    }
    
    // MARK: - File Comparison Tests
    
    func testCompareIdenticalFiles() {
        let file1 = testDirectory.appendingPathComponent("identical1.txt")
        let file2 = testDirectory.appendingPathComponent("identical2.txt")
        let content = "Same content in both files"
        
        try? content.write(to: file1, atomically: true, encoding: .utf8)
        try? content.write(to: file2, atomically: true, encoding: .utf8)
        
        let result = FileAnalysisEngine.compareFiles(file1.path, file2.path)
        
        XCTAssertTrue(result.identical, "Files should be identical")
        XCTAssertEqual(result.diffSize, 0, "Diff size should be 0")
    }
    
    func testCompareDifferentFiles() {
        let file1 = testDirectory.appendingPathComponent("different1.txt")
        let file2 = testDirectory.appendingPathComponent("different2.txt")
        
        try? "Content A".write(to: file1, atomically: true, encoding: .utf8)
        try? "Content B".write(to: file2, atomically: true, encoding: .utf8)
        
        let result = FileAnalysisEngine.compareFiles(file1.path, file2.path)
        
        XCTAssertFalse(result.identical, "Files should be different")
        XCTAssertGreaterThan(result.diffSize, 0, "Diff size should be greater than 0")
    }
    
    func testCompareDifferentSizeFiles() {
        let file1 = testDirectory.appendingPathComponent("short.txt")
        let file2 = testDirectory.appendingPathComponent("long.txt")
        
        try? "Short".write(to: file1, atomically: true, encoding: .utf8)
        try? "This is much longer content".write(to: file2, atomically: true, encoding: .utf8)
        
        let result = FileAnalysisEngine.compareFiles(file1.path, file2.path)
        
        XCTAssertFalse(result.identical, "Files of different sizes should not be identical")
        XCTAssertGreaterThan(result.diffSize, 0, "Diff size should reflect size difference")
    }
    
    // MARK: - Integrity Check Tests
    
    func testVerifyFileIntegrity() {
        let testFile = testDirectory.appendingPathComponent("integrity_test.txt")
        let content = "Content for integrity check"
        try? content.write(to: testFile, atomically: true, encoding: .utf8)
        
        // Get the actual hash
        guard let hashes = FileAnalysisEngine.computeHashes(for: testFile.path) else {
            XCTFail("Should compute hashes")
            return
        }
        
        // Verify with correct hash
        let isValid = FileAnalysisEngine.verifyFileIntegrity(at: testFile.path, expectedHash: hashes.sha256)
        XCTAssertTrue(isValid, "Should verify with correct hash")
        
        // Verify with incorrect hash
        let isInvalid = FileAnalysisEngine.verifyFileIntegrity(at: testFile.path, expectedHash: "wronghash123")
        XCTAssertFalse(isInvalid, "Should fail with incorrect hash")
    }
}
