import SwiftUI
import NimbleViews

// MARK: - FilesTabSettingsView
struct FilesTabSettingsView: View {
    @AppStorage("Feather.filesTabEnabled") private var filesTabEnabled = false
    @State private var showRestartAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $filesTabEnabled) {
                    Label(.localized("Enable Files Tab"), systemImage: "folder.fill")
                }
                .onChange(of: filesTabEnabled) { _ in
                    HapticsManager.shared.impact()
                    showRestartAlert = true
                }
            } header: {
                Text(.localized("Files Tab"))
            } footer: {
                Text(.localized("Enable the Files tab to manage your files. You can create .txt files, zip/unzip files, edit .plist files, use a HEX editor, and customize folders with SF Symbols."))
            }
            
            if filesTabEnabled {
                Section {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.orange)
                        Text(.localized("Text File Creation"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Image(systemName: "doc.zipper")
                            .foregroundStyle(.green)
                        Text(.localized("Zip/Unzip Files"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Image(systemName: "doc.badge.gearshape.fill")
                            .foregroundStyle(.purple)
                        Text(.localized("Plist Editor"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.blue)
                        Text(.localized("HEX Editor"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(.blue)
                        Text(.localized("Folder Creation & Customization"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text(.localized("Features"))
                }
            }
        }
        .navigationTitle(.localized("Files Tab"))
        .navigationBarTitleDisplayMode(.large)
        .alert(.localized("Restart Required"), isPresented: $showRestartAlert) {
            Button(.localized("OK")) {
                showRestartAlert = false
            }
        } message: {
            Text(.localized("Please restart the app to see the changes in your tabs."))
        }
    }
}
