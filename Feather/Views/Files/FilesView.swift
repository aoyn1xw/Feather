import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - FilesView
struct FilesView: View {
    @StateObject private var fileManager = FileManagerService.shared
    @State private var showCreateMenu = false
    @State private var showCreateFolder = false
    @State private var showCreateTextFile = false
    @State private var showZipOptions = false
    @State private var showUnzipOptions = false
    @State private var showPlistEditor = false
    @State private var showHexEditor = false
    @State private var showFolderCustomization = false
    @State private var newFileName = ""
    @State private var newFolderName = ""
    @State private var selectedFile: FileItem?
    
    var body: some View {
        NBNavigationView(.localized("Files")) {
            ZStack {
                if fileManager.currentFiles.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        createMenuItems
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showCreateTextFile) {
                CreateTextFileView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(item: $selectedFile) { file in
                if file.isDirectory {
                    FolderCustomizationView(folderURL: file.url)
                } else if file.url.pathExtension == "plist" {
                    PlistEditorView(fileURL: file.url)
                } else {
                    HexEditorView(fileURL: file.url)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(.localized("No Files"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(.localized("Create files, folders, and manage your content"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Menu {
                createMenuItems
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(.localized("Create"))
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
        List {
            ForEach(fileManager.currentFiles) { file in
                FileRowView(file: file)
                    .onTapGesture {
                        HapticsManager.shared.impact()
                        if file.isDirectory {
                            fileManager.navigateToDirectory(file.url)
                        } else {
                            selectedFile = file
                        }
                    }
                    .contextMenu {
                        fileContextMenu(for: file)
                    }
            }
            .onDelete { indexSet in
                deleteFiles(at: indexSet)
            }
        }
    }
    
    @ViewBuilder
    private var createMenuItems: some View {
        Button {
            HapticsManager.shared.impact()
            showCreateTextFile = true
        } label: {
            Label(.localized("Text File"), systemImage: "doc.text")
        }
        
        Button {
            HapticsManager.shared.impact()
            showCreateFolder = true
        } label: {
            Label(.localized("Folder"), systemImage: "folder.badge.plus")
        }
        
        Divider()
        
        Button {
            HapticsManager.shared.impact()
            // Zip action
        } label: {
            Label(.localized("Zip Files"), systemImage: "doc.zipper")
        }
        
        Button {
            HapticsManager.shared.impact()
            // Unzip action
        } label: {
            Label(.localized("Unzip File"), systemImage: "arrow.up.doc")
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
        } else if file.url.pathExtension == "plist" {
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
                Label(.localized("Hex Editor"), systemImage: "number")
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
    
    private func deleteFiles(at indexSet: IndexSet) {
        HapticsManager.shared.warning()
        for index in indexSet {
            let file = fileManager.currentFiles[index]
            fileManager.deleteFile(file)
        }
    }
}

// MARK: - FileRowView
struct FileRowView: View {
    let file: FileItem
    
    var body: some View {
        HStack(spacing: 12) {
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

// MARK: - FileItem
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: String?
    let customIcon: String?
    
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
    
    private let documentsDirectory: URL
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.currentDirectory = documentsDirectory.appendingPathComponent("FeatherFiles", isDirectory: true)
        
        // Create base directory if needed
        try? FileManager.default.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        
        loadFiles()
    }
    
    func loadFiles() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey])
                
                let files = contents.compactMap { url -> FileItem? in
                    let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                    let isDirectory = resourceValues?.isDirectory ?? false
                    let fileSize = resourceValues?.fileSize
                    
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
    
    func deleteFile(_ file: FileItem) {
        do {
            try FileManager.default.removeItem(at: file.url)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
        }
    }
}
