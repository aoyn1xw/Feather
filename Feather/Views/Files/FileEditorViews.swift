import SwiftUI
import NimbleViews

// MARK: - CreateTextFileView
struct CreateTextFileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fileName = ""
    @State private var fileContent = ""
    let directoryURL: URL
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.localized("File Name"))
                } footer: {
                    Text(.localized(".txt extension will be added automatically"))
                }
                
                Section {
                    TextEditor(text: $fileContent)
                        .frame(minHeight: 200)
                } header: {
                    Text(.localized("Content"))
                }
            }
            .navigationTitle(.localized("New Text File"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createFile()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private func createFile() {
        let name = fileName.hasSuffix(".txt") ? fileName : "\(fileName).txt"
        let fileURL = directoryURL.appendingPathComponent(name)
        
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
        }
    }
}

// MARK: - CreateFolderView
struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var folderName = ""
    let directoryURL: URL
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(.localized("Folder Name"), text: $folderName)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.localized("Folder Name"))
                }
            }
            .navigationTitle(.localized("New Folder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createFolder()
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
    
    private func createFolder() {
        let folderURL = directoryURL.appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
        }
    }
}

// MARK: - PlistEditorView
struct PlistEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var plistContent = ""
    let fileURL: URL
    
    var body: some View {
        NavigationView {
            ScrollView {
                TextEditor(text: $plistContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle(.localized("Plist Editor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Save")) {
                        savePlist()
                    }
                }
            }
        }
        .onAppear {
            loadPlist()
        }
    }
    
    private func loadPlist() {
        do {
            let data = try Data(contentsOf: fileURL)
            if let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: plist, options: .prettyPrinted)
                plistContent = String(data: jsonData, encoding: .utf8) ?? ""
            }
        } catch {
            plistContent = "Error loading plist: \(error.localizedDescription)"
        }
    }
    
    private func savePlist() {
        do {
            let data = plistContent.data(using: .utf8) ?? Data()
            let json = try JSONSerialization.jsonObject(with: data)
            let plistData = try PropertyListSerialization.data(fromPropertyList: json, format: .xml, options: 0)
            try plistData.write(to: fileURL)
            HapticsManager.shared.success()
            dismiss()
        } catch {
            HapticsManager.shared.error()
        }
    }
}

// MARK: - HexEditorView
struct HexEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hexContent = ""
    let fileURL: URL
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(hexContent)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle(.localized("Hex Editor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadHex()
        }
    }
    
    private func loadHex() {
        do {
            let data = try Data(contentsOf: fileURL)
            hexContent = data.map { String(format: "%02X ", $0) }
                .enumerated()
                .reduce("") { result, item in
                    let (index, hex) = item
                    return result + hex + ((index + 1) % 16 == 0 ? "\n" : "")
                }
        } catch {
            hexContent = "Error loading file: \(error.localizedDescription)"
        }
    }
}

// MARK: - FolderCustomizationView
struct FolderCustomizationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedIcon = "folder.fill"
    let folderURL: URL
    
    let availableIcons = [
        "folder.fill", "folder.badge.plus", "folder.badge.gearshape",
        "folder.badge.person.crop", "music.note", "film.fill",
        "photo.fill", "doc.fill", "book.fill", "gamecontroller.fill",
        "paintbrush.fill", "hammer.fill", "wrench.fill", "gear",
        "star.fill", "heart.fill", "flag.fill", "bookmark.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text(.localized("Choose an icon for this folder"))
                        .font(.headline)
                        .padding(.top)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            iconButton(for: icon)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(.localized("Customize Folder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Save")) {
                        saveCustomization()
                    }
                }
            }
        }
    }
    
    private func iconButton(for icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let foregroundColor: Color = isSelected ? .accentColor : .secondary
        let backgroundColor = isSelected ? Color.accentColor.opacity(0.1) : Color.clear
        let strokeColor = isSelected ? Color.accentColor : Color.clear
        
        return Button {
            HapticsManager.shared.selection()
            selectedIcon = icon
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(strokeColor, lineWidth: 2)
                    )
            }
        }
    }
    
    private func saveCustomization() {
        // Save icon preference using the full path to avoid conflicts
        UserDefaults.standard.set(selectedIcon, forKey: "folder_icon_\(folderURL.path)")
        HapticsManager.shared.success()
        dismiss()
    }
}
