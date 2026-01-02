import SwiftUI
import NimbleViews

struct CreatePlistView: View {
    @Environment(\.dismiss) var dismiss
    let directoryURL: URL
    
    @State private var fileName: String = ""
    @State private var selectedFormat: PlistFormat = .xml
    
    enum PlistFormat: String, CaseIterable {
        case xml = "XML"
        case binary = "Binary"
    }
    
    var body: some View {
        NBNavigationView(.localized("Create Plist File"), displayMode: .inline) {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("Name"))
                } footer: {
                    Text(.localized("Enter a name for the plist file (without .plist extension)"))
                }
                
                Section {
                    Picker(.localized("Format"), selection: $selectedFormat) {
                        ForEach(PlistFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(.localized("Plist Format"))
                } footer: {
                    Text(.localized("XML format is human-readable, Binary format is more compact"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createPlist()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private func createPlist() {
        let fileURL = directoryURL.appendingPathComponent(fileName + ".plist")
        
        // Create an empty dictionary for the plist
        let emptyDict: [String: Any] = [:]
        
        do {
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let data = try PropertyListSerialization.data(fromPropertyList: emptyDict, format: format, options: 0)
            try data.write(to: fileURL)
            
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to create plist file: \(error.localizedDescription)", category: "Files")
        }
    }
}
