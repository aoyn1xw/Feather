import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import QuickLook

// MARK: - FilesView
struct FilesView: View {
    @StateObject private var fileManager = FileManagerService.shared
    @State private var showCreateMenu = false
    @State private var showCreateFolder = false
    @State private var showCreateTextFile = false
    @State private var showCreatePlist = false
    @State private var showDocumentPicker = false
    @State private var showZipSheet = false
    @State private var showUnzipSheet = false
    @State private var showSearch = false
    @State private var showFileInfo = false
    @State private var showMoveSheet = false
    @State private var showChecksumSheet = false
    @State private var showBatchRenameSheet = false
    @State private var showCompareSheet = false
    @State private var compareFile1: FileItem?
    @State private var compareFile2: FileItem?
    @State private var searchText = ""
    @State private var selectedFile: FileItem?
    @State private var selectedFiles: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var layoutMode: LayoutMode = .list
    @State private var sortOption: SortOption = .name
    @State private var showShareSheet = false
    @State private var shareURLs: [URL] = []
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var fileToRename: FileItem?
    @State private var showCertificateQuickAdd = false
    @State private var detectedP12: URL?
    @State private var detectedMobileprovision: URL?
    
    enum LayoutMode {
        case list, grid
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case date = "Date Modified"
        case size = "Size"
        case type = "Type"
    }
    
    var filteredFiles: [FileItem] {
        var files = fileManager.currentFiles
        
        if !searchText.isEmpty {
            files = files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOption {
        case .name:
            files.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date:
            files.sort { ($0.modificationDate ?? Date.distantPast) > ($1.modificationDate ?? Date.distantPast) }
        case .size:
            files.sort { ($0.sizeInBytes ?? 0) > ($1.sizeInBytes ?? 0) }
        case .type:
            files.sort { $0.url.pathExtension.localizedCaseInsensitiveCompare($1.url.pathExtension) == .orderedAscending }
        }
        
        return files
    }
    
    var hasCertificateFiles: Bool {
        let files = fileManager.currentFiles
        let hasP12 = files.contains(where: { $0.url.pathExtension.lowercased() == "p12" })
        let hasMobileprovision = files.contains(where: { $0.url.pathExtension.lowercased() == "mobileprovision" })
        return hasP12 && hasMobileprovision
    }
    
    var body: some View {
        NBNavigationView(.localized("Files")) {
            VStack(spacing: 0) {
                // Certificate Quick Add Banner
                if hasCertificateFiles {
                    certificateQuickAddBanner
                }
                
                ZStack {
                    if fileManager.currentFiles.isEmpty {
                        emptyStateView
                    } else {
                        if layoutMode == .list {
                            fileListView
                        } else {
                            fileGridView
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: .localized("Search Files"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if fileManager.currentDirectory != fileManager.documentsDirectory {
                        Button {
                            fileManager.navigateUp()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                    
                    if isSelectionMode {
                        Button(.localized("Cancel")) {
                            isSelectionMode = false
                            selectedFiles.removeAll()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            layoutMode = layoutMode == .list ? .grid : .list
                        } label: {
                            Label(layoutMode == .list ? .localized("Grid View") : .localized("List View"), 
                                  systemImage: layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                        }
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    if sortOption == option {
                                        Label(option.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Label(.localized("Sort By"), systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedFiles.removeAll()
                            }
                        } label: {
                            Label(.localized("Select"), systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Menu {
                        createMenuItems
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .sheet(isPresented: $showCreateTextFile) {
                CreateTextFileView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreatePlist) {
                CreatePlistView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showDocumentPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        for url in urls {
                            fileManager.importFile(from: url)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showZipSheet) {
                ZipOperationView(files: selectedFilesArray, operation: .zip, directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showUnzipSheet) {
                if let zipFile = selectedFilesArray.first(where: { $0.url.pathExtension == "zip" }) {
                    ZipOperationView(files: [zipFile], operation: .unzip, directoryURL: fileManager.currentDirectory)
                }
            }
            .sheet(item: $selectedFile) { file in
                fileDetailSheet(for: file)
            }
            .sheet(isPresented: $showFileInfo) {
                if let file = selectedFilesArray.first {
                    FileInfoView(file: file)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(urls: shareURLs)
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveFileView(files: selectedFilesArray, currentDirectory: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showChecksumSheet) {
                if let file = selectedFilesArray.first {
                    ChecksumCalculatorView(fileURL: file.url)
                }
            }
            .sheet(isPresented: $showBatchRenameSheet) {
                BatchRenameView(files: selectedFilesArray)
            }
            .sheet(isPresented: $showCompareSheet) {
                if let file1 = compareFile1, let file2 = compareFile2 {
                    FileCompareView(file1: file1, file2: file2)
                }
            }
            .sheet(isPresented: $showCertificateQuickAdd) {
                if let p12 = detectedP12, let provision = detectedMobileprovision {
                    CertificateQuickAddView(p12URL: p12, mobileprovisionURL: provision)
                }
            }
            .alert(.localized("Rename File"), isPresented: $showRenameAlert) {
                TextField(.localized("New Name"), text: $renameText)
                Button(.localized("Cancel"), role: .cancel) { }
                Button(.localized("Rename")) {
                    if let file = fileToRename {
                        fileManager.renameFile(file, to: renameText)
                    }
                }
            } message: {
                Text(.localized("Enter a new name for the file"))
            }
        }
    }
    
    private var certificateQuickAddBanner: some View {
        Button {
            detectCertificateFiles()
            showCertificateQuickAdd = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.key.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Certificate Files Detected"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(.localized("Tap to add certificate"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var selectedFilesArray: [FileItem] {
        fileManager.currentFiles.filter { selectedFiles.contains($0.id) }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(.localized("No Files"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(.localized("Import files or create new content"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text(.localized("Import Files"))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
        }
    }
    
    private var fileListView: some View {
        List(selection: isSelectionMode ? $selectedFiles : .constant(Set<UUID>())) {
            ForEach(filteredFiles) { file in
                FileRowView(file: file, isSelected: selectedFiles.contains(file.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleFileTap(file)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            HapticsManager.shared.warning()
                            fileManager.deleteFile(file)
                        } label: {
                            Label(.localized("Delete"), systemImage: "trash")
                        }
                        
                        Button {
                            shareURLs = [file.url]
                            showShareSheet = true
                        } label: {
                            Label(.localized("Share"), systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            fileToRename = file
                            renameText = file.name
                            showRenameAlert = true
                        } label: {
                            Label(.localized("Rename"), systemImage: "pencil")
                        }
                        .tint(.orange)
                        
                        Button {
                            fileManager.duplicateFile(file)
                        } label: {
                            Label(.localized("Duplicate"), systemImage: "doc.on.doc")
                        }
                        .tint(.green)
                    }
                    .contextMenu {
                        fileContextMenu(for: file)
                    }
            }
        }
        .environment(\.editMode, isSelectionMode ? .constant(.active) : .constant(.inactive))
        .toolbar {
            if isSelectionMode && !selectedFiles.isEmpty {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        shareURLs = selectedFilesArray.map { $0.url }
                        showShareSheet = true
                    } label: {
                        Label(.localized("Share"), systemImage: "square.and.arrow.up")
                    }
                    
                    Spacer()
                    
                    if selectedFiles.count > 1 {
                        Button {
                            showBatchRenameSheet = true
                        } label: {
                            Label(.localized("Rename"), systemImage: "pencil")
                        }
                        
                        Spacer()
                    }
                    
                    if selectedFiles.count == 2 {
                        Button {
                            let files = selectedFilesArray
                            if files.count == 2 {
                                compareFile1 = files[0]
                                compareFile2 = files[1]
                                showCompareSheet = true
                            }
                        } label: {
                            Label(.localized("Compare"), systemImage: "arrow.left.arrow.right")
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        showMoveSheet = true
                    } label: {
                        Label(.localized("Move"), systemImage: "folder")
                    }
                    
                    Spacer()
                    
                    Button {
                        showZipSheet = true
                    } label: {
                        Label(.localized("Zip"), systemImage: "doc.zipper")
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        for id in selectedFiles {
                            if let file = fileManager.currentFiles.first(where: { $0.id == id }) {
                                fileManager.deleteFile(file)
                            }
                        }
                        selectedFiles.removeAll()
                    } label: {
                        Label(.localized("Delete"), systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private var fileGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredFiles) { file in
                    FileGridItemView(file: file, isSelected: selectedFiles.contains(file.id))
                        .onTapGesture {
                            handleFileTap(file)
                        }
                        .contextMenu {
                            fileContextMenu(for: file)
                        }
                }
            }
            .padding()
        }
    }
    
    private func handleFileTap(_ file: FileItem) {
        HapticsManager.shared.impact()
        
        if isSelectionMode {
            if selectedFiles.contains(file.id) {
                selectedFiles.remove(file.id)
            } else {
                selectedFiles.insert(file.id)
            }
        } else {
            if file.isDirectory {
                fileManager.navigateToDirectory(file.url)
            } else {
                selectedFile = file
            }
        }
    }
    
    private func fileDetailSheet(for file: FileItem) -> some View {
        Group {
            if file.isDirectory {
                FolderCustomizationView(folderURL: file.url)
            } else if file.url.pathExtension.lowercased() == "plist" {
                PlistEditorView(fileURL: file.url)
            } else if file.url.pathExtension.lowercased() == "json" {
                JSONViewerView(fileURL: file.url)
            } else if ["txt", "text", "md", "log", "swift", "py", "js", "ts", "html", "css", "xml", "yml", "yaml"].contains(file.url.pathExtension.lowercased()) {
                TextViewerView(fileURL: file.url)
            } else {
                HexEditorView(fileURL: file.url)
            }
        }
    }
    
    @ViewBuilder
    private var createMenuItems: some View {
        Button {
            HapticsManager.shared.impact()
            showDocumentPicker = true
        } label: {
            Label(.localized("Import Files"), systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        Button {
            HapticsManager.shared.impact()
            showCreateTextFile = true
        } label: {
            Label(.localized("Text File"), systemImage: "doc.text")
        }
        
        Button {
            HapticsManager.shared.impact()
            showCreatePlist = true
        } label: {
            Label(.localized("Plist File"), systemImage: "doc.badge.gearshape")
        }
        
        Button {
            HapticsManager.shared.impact()
            showCreateFolder = true
        } label: {
            Label(.localized("Folder"), systemImage: "folder.badge.plus")
        }
        
        if !selectedFiles.isEmpty || fileManager.currentFiles.contains(where: { $0.url.pathExtension == "zip" }) {
            Divider()
            
            if !selectedFiles.isEmpty {
                Button {
                    HapticsManager.shared.impact()
                    showZipSheet = true
                } label: {
                    Label(.localized("Zip Selected"), systemImage: "doc.zipper")
                }
            }
            
            if fileManager.currentFiles.contains(where: { $0.url.pathExtension == "zip" }) {
                Button {
                    HapticsManager.shared.impact()
                    showUnzipSheet = true
                } label: {
                    Label(.localized("Unzip File"), systemImage: "arrow.up.doc")
                }
            }
        }
    }
    
    @ViewBuilder
    private func fileContextMenu(for file: FileItem) -> some View {
        if file.isDirectory {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("Customize Folder"), systemImage: "paintbrush")
            }
        } else if file.url.pathExtension.lowercased() == "plist" {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("Edit Plist"), systemImage: "doc.text.fill")
            }
        } else {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("View/Edit"), systemImage: "doc.text")
            }
        }
        
        Divider()
        
        Button {
            selectedFiles = [file.id]
            showFileInfo = true
        } label: {
            Label(.localized("Info"), systemImage: "info.circle")
        }
        
        Button {
            fileToRename = file
            renameText = file.name
            showRenameAlert = true
        } label: {
            Label(.localized("Rename"), systemImage: "pencil")
        }
        
        Button {
            fileManager.duplicateFile(file)
        } label: {
            Label(.localized("Duplicate"), systemImage: "doc.on.doc")
        }
        
        Button {
            selectedFiles = [file.id]
            showMoveSheet = true
        } label: {
            Label(.localized("Move"), systemImage: "folder")
        }
        
        Button {
            shareURLs = [file.url]
            showShareSheet = true
        } label: {
            Label(.localized("Share"), systemImage: "square.and.arrow.up")
        }
        
        if !file.isDirectory {
            Divider()
            
            Button {
                selectedFiles = [file.id]
                showChecksumSheet = true
            } label: {
                Label(.localized("Calculate Checksums"), systemImage: "number.square")
            }
        }
        
        if file.url.pathExtension.lowercased() == "zip" {
            Divider()
            
            Button {
                selectedFiles = [file.id]
                showUnzipSheet = true
            } label: {
                Label(.localized("Unzip"), systemImage: "arrow.up.doc")
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            HapticsManager.shared.warning()
            fileManager.deleteFile(file)
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }
    }
    
    private func detectCertificateFiles() {
        let files = fileManager.currentFiles
        detectedP12 = files.first(where: { $0.url.pathExtension.lowercased() == "p12" })?.url
        detectedMobileprovision = files.first(where: { $0.url.pathExtension.lowercased() == "mobileprovision" })?.url
        HapticsManager.shared.impact()
    }
}

// MARK: - FileRowView
struct FileRowView: View {
    let file: FileItem
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
            
            Image(systemName: file.icon)
                .font(.title2)
                .foregroundStyle(file.iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let size = file.size {
                    Text(size)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if file.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FileGridItemView
struct FileGridItemView: View {
    let file: FileItem
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: file.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(file.iconColor)
                    .frame(width: 100, height: 80)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                        .offset(x: 8, y: -8)
                }
            }
            
            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - FileItem
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: String?
    let sizeInBytes: Int?
    let modificationDate: Date?
    let customIcon: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var icon: String {
        if let customIcon = customIcon {
            return customIcon
        }
        if isDirectory {
            return "folder.fill"
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "text":
            return "doc.text.fill"
        case "plist":
            return "doc.badge.gearshape.fill"
        case "zip":
            return "doc.zipper"
        case "json":
            return "curlybraces"
        case "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "ipa":
            return "app.badge"
        default:
            return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if isDirectory {
            return .blue
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "text":
            return .orange
        case "plist":
            return .purple
        case "zip":
            return .green
        case "json":
            return .yellow
        case "xml":
            return .red
        case "ipa":
            return .cyan
        default:
            return .gray
        }
    }
}

// MARK: - FileManagerService
class FileManagerService: ObservableObject {
    static let shared = FileManagerService()
    
    @Published var currentDirectory: URL
    @Published var currentFiles: [FileItem] = []
    
    let documentsDirectory: URL
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.currentDirectory = documentsDirectory.appendingPathComponent("FeatherFiles", isDirectory: true)
        
        // Create base directory if needed
        try? FileManager.default.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        
        loadFiles()
    }
    
    func loadFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: self.currentDirectory, 
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
                )
                
                let files = contents.compactMap { url -> FileItem? in
                    let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDirectory = resourceValues?.isDirectory ?? false
                    let fileSize = resourceValues?.fileSize
                    let modDate = resourceValues?.contentModificationDate
                    
                    let sizeString: String? = {
                        if isDirectory {
                            return nil
                        }
                        guard let fileSize = fileSize else { return nil }
                        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                    }()
                    
                    // Get custom icon if exists
                    let customIcon = UserDefaults.standard.string(forKey: "folder_icon_\(url.path)")
                    
                    return FileItem(
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: isDirectory,
                        size: sizeString,
                        sizeInBytes: fileSize,
                        modificationDate: modDate,
                        customIcon: customIcon
                    )
                }.sorted { $0.isDirectory && !$1.isDirectory }
                
                DispatchQueue.main.async {
                    self.currentFiles = files
                }
            } catch {
                DispatchQueue.main.async {
                    self.currentFiles = []
                }
            }
        }
    }
    
    func navigateToDirectory(_ url: URL) {
        currentDirectory = url
        loadFiles()
    }
    
    func navigateUp() {
        let parent = currentDirectory.deletingLastPathComponent()
        if parent.path.starts(with: documentsDirectory.path) {
            currentDirectory = parent
            loadFiles()
        }
    }
    
    func deleteFile(_ file: FileItem) {
        do {
            try FileManager.default.removeItem(at: file.url)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to delete file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func renameFile(_ file: FileItem, to newName: String) {
        let newURL = file.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: file.url, to: newURL)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to rename file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func duplicateFile(_ file: FileItem) {
        let nameWithoutExt = file.url.deletingPathExtension().lastPathComponent
        let ext = file.url.pathExtension
        let baseName = ext.isEmpty ? nameWithoutExt : "\(nameWithoutExt).\(ext)"
        
        var counter = 1
        var newURL = file.url.deletingLastPathComponent().appendingPathComponent("Copy of \(baseName)")
        
        while FileManager.default.fileExists(atPath: newURL.path) {
            counter += 1
            newURL = file.url.deletingLastPathComponent().appendingPathComponent("Copy \(counter) of \(baseName)")
        }
        
        do {
            try FileManager.default.copyItem(at: file.url, to: newURL)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to duplicate file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func importFile(from sourceURL: URL) {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = currentDirectory.appendingPathComponent(fileName)
        
        do {
            // Copy file to destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                // Handle name conflict
                var counter = 1
                var newDestinationURL = currentDirectory.appendingPathComponent("\(counter)_\(fileName)")
                while FileManager.default.fileExists(atPath: newDestinationURL.path) {
                    counter += 1
                    newDestinationURL = currentDirectory.appendingPathComponent("\(counter)_\(fileName)")
                }
                try FileManager.default.copyItem(at: sourceURL, to: newDestinationURL)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            }
            
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to import file: \(error.localizedDescription)", category: "Files")
        }
    }
}
