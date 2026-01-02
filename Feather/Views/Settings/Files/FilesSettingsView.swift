import SwiftUI
import NimbleViews

// MARK: - FilesSettingsView
struct FilesSettingsView: View {
    @AppStorage("files_viewStyle") private var viewStyle: String = "list"
    @AppStorage("files_sortOption") private var sortOption: String = "name"
    @AppStorage("files_showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("files_showFileExtensions") private var showFileExtensions = true
    @AppStorage("files_showFileSize") private var showFileSize = true
    @AppStorage("files_showModificationDate") private var showModificationDate = true
    @AppStorage("files_showMagicBytes") private var showMagicBytes = false
    @AppStorage("files_enableQuickInspect") private var enableQuickInspect = true
    @AppStorage("files_enableOpenInSigner") private var enableOpenInSigner = true
    @AppStorage("files_enableFixStructure") private var enableFixStructure = true
    @AppStorage("files_enableAutoIndexing") private var enableAutoIndexing = true
    @AppStorage("files_indexingDepth") private var indexingDepth = 2.0
    @AppStorage("files_cacheFileInfo") private var cacheFileInfo = true
    @AppStorage("files_enableFastScanning") private var enableFastScanning = true
    @AppStorage("files_thumbnailQuality") private var thumbnailQuality = 1.0
    
    var body: some View {
        NBNavigationView(.localized("Files Settings"), displayMode: .inline) {
            Form {
                // MARK: - View Style Section
                NBSection(.localized("View Style")) {
                    Picker(selection: $viewStyle) {
                        Label(.localized("List View"), systemImage: "list.bullet")
                            .tag("list")
                        Label(.localized("Grid View"), systemImage: "square.grid.2x2")
                            .tag("grid")
                    } label: {
                        ConditionalLabel(title: .localized("Default View"), systemImage: "square.grid.2x2")
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text(.localized("Choose the default view style for the Files tab."))
                }
                
                // MARK: - Sorting Section
                NBSection(.localized("Sorting")) {
                    Picker(selection: $sortOption) {
                        Text(.localized("Name")).tag("name")
                        Text(.localized("Date Modified")).tag("date")
                        Text(.localized("Size")).tag("size")
                        Text(.localized("Type")).tag("type")
                    } label: {
                        ConditionalLabel(title: .localized("Sort By"), systemImage: "arrow.up.arrow.down")
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text(.localized("Default sorting option for files and folders."))
                }
                
                // MARK: - File Metadata Section
                NBSection(.localized("File Metadata")) {
                    Toggle(isOn: $showHiddenFiles) {
                        ConditionalLabel(title: .localized("Show Hidden Files"), systemImage: "eye.slash")
                    }
                    
                    Toggle(isOn: $showFileExtensions) {
                        ConditionalLabel(title: .localized("Show File Extensions"), systemImage: "doc.text")
                    }
                    
                    Toggle(isOn: $showFileSize) {
                        ConditionalLabel(title: .localized("Show File Size"), systemImage: "doc")
                    }
                    
                    Toggle(isOn: $showModificationDate) {
                        ConditionalLabel(title: .localized("Show Modification Date"), systemImage: "clock")
                    }
                    
                    Toggle(isOn: $showMagicBytes) {
                        ConditionalLabel(title: .localized("Show Magic Bytes"), systemImage: "number.square")
                    }
                } footer: {
                    Text(.localized("Control which file metadata is displayed in the Files tab."))
                }
                
                // MARK: - Smart Actions Section
                NBSection(.localized("Smart Actions")) {
                    Toggle(isOn: $enableQuickInspect) {
                        ConditionalLabel(title: .localized("Quick Inspect"), systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Toggle(isOn: $enableOpenInSigner) {
                        ConditionalLabel(title: .localized("Open in Signer"), systemImage: "signature")
                    }
                    
                    Toggle(isOn: $enableFixStructure) {
                        ConditionalLabel(title: .localized("Fix Structure"), systemImage: "wrench.and.screwdriver")
                    }
                } footer: {
                    Text(.localized("Enable or disable smart context actions in the Files tab. Quick Inspect shows detailed file information, Open in Signer opens IPA files in the signer, and Fix Structure attempts to repair corrupted file structures."))
                }
                
                // MARK: - Indexing Section
                NBSection(.localized("Indexing")) {
                    Toggle(isOn: $enableAutoIndexing) {
                        ConditionalLabel(title: .localized("Auto-Index Files"), systemImage: "folder.badge.gearshape")
                    }
                    
                    if enableAutoIndexing {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(.localized("Indexing Depth"))
                                    .font(.body)
                                Spacer()
                                Text("\(Int(indexingDepth)) levels")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $indexingDepth, in: 1...5, step: 1)
                                .tint(.accentColor)
                        }
                    }
                } footer: {
                    Text(.localized("Auto-indexing scans directories in the background to provide faster file access. Higher depth levels scan more subdirectories but may impact performance."))
                }
                
                // MARK: - Performance Section
                NBSection(.localized("Performance")) {
                    Toggle(isOn: $cacheFileInfo) {
                        ConditionalLabel(title: .localized("Cache File Info"), systemImage: "square.stack.3d.down.right")
                    }
                    
                    Toggle(isOn: $enableFastScanning) {
                        ConditionalLabel(title: .localized("Fast Scanning (C++)"), systemImage: "bolt.fill")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(.localized("Thumbnail Quality"))
                                .font(.body)
                            Spacer()
                            Text(thumbnailQualityText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $thumbnailQuality, in: 0...2, step: 1)
                            .tint(.accentColor)
                    }
                } footer: {
                    Text(.localized("Caching file information and using fast C++ scanning improves performance. Lower thumbnail quality uses less memory and loads faster."))
                }
                
                // MARK: - Reset Section
                NBSection(.localized("Reset")) {
                    Button {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text(.localized("Reset to Defaults"))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                } footer: {
                    Text(.localized("Reset all Files settings to their default values."))
                }
            }
        }
    }
    
    private var thumbnailQualityText: String {
        switch Int(thumbnailQuality) {
        case 0: return .localized("Low")
        case 1: return .localized("Medium")
        case 2: return .localized("High")
        default: return .localized("Medium")
        }
    }
    
    private func resetToDefaults() {
        viewStyle = "list"
        sortOption = "name"
        showHiddenFiles = false
        showFileExtensions = true
        showFileSize = true
        showModificationDate = true
        showMagicBytes = false
        enableQuickInspect = true
        enableOpenInSigner = true
        enableFixStructure = true
        enableAutoIndexing = true
        indexingDepth = 2.0
        cacheFileInfo = true
        enableFastScanning = true
        thumbnailQuality = 1.0
        
        HapticsManager.shared.success()
    }
}

// MARK: - Preview
struct FilesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        FilesSettingsView()
    }
}
