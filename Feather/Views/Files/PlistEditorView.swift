import SwiftUI
import NimbleViews

struct PlistEditorView: View {
    @Environment(\.dismiss) var dismiss
    let fileURL: URL
    
    @State private var plistContent: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        NBNavigationView(.localized("Plist Editor"), displayMode: .inline) {
            VStack(spacing: 0) {
                if isEditing {
                    TextEditor(text: $plistContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                } else {
                    ScrollView {
                        Text(plistContent)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? .localized("Save") : .localized("Edit")) {
                        if isEditing {
                            saveContent()
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .onAppear {
            loadContent()
        }
    }
    
    private func loadContent() {
        do {
            plistContent = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            plistContent = "Error loading file: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to load plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func saveContent() {
        do {
            try plistContent.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticsManager.shared.success()
            isEditing = false
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to save plist: \(error.localizedDescription)", category: "Files")
        }
    }
}
