import SwiftUI
import NimbleViews

struct PlistEditorView: View {
    @Environment(\.dismiss) var dismiss
    let fileURL: URL
    
    @State private var plistContent: String = ""
    @State private var isEditing: Bool = false
    @State private var showFormatPicker: Bool = false
    @State private var selectedFormat: PlistFormat = .xml
    @State private var validationError: String?
    
    enum PlistFormat: String, CaseIterable {
        case xml = "XML"
        case binary = "Binary"
    }
    
    enum ViewMode {
        case raw
        case formatted
    }
    
    var body: some View {
        NBNavigationView(.localized("Plist Editor"), displayMode: .inline) {
            VStack(spacing: 0) {
                if let error = validationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                }
                
                if isEditing {
                    TextEditor(text: $plistContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .onChange(of: plistContent) { _ in
                            validatePlist()
                        }
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
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button {
                            showFormatPicker = true
                        } label: {
                            Label(.localized("Convert Format"), systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button {
                            formatPlistContent()
                        } label: {
                            Label(.localized("Format XML"), systemImage: "text.alignleft")
                        }
                        .disabled(selectedFormat != .xml)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button(isEditing ? .localized("Save") : .localized("Edit")) {
                        if isEditing {
                            saveContent()
                        } else {
                            isEditing = true
                        }
                    }
                    .disabled(isEditing && validationError != nil)
                }
            }
            .sheet(isPresented: $showFormatPicker) {
                formatConversionSheet
            }
        }
        .onAppear {
            loadContent()
        }
    }
    
    private var formatConversionSheet: some View {
        NBNavigationView(.localized("Convert Format"), displayMode: .inline) {
            Form {
                Section {
                    Picker(.localized("Target Format"), selection: $selectedFormat) {
                        ForEach(PlistFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(.localized("Format"))
                } footer: {
                    Text(.localized("Convert the plist to the selected format"))
                }
                
                Section {
                    Button {
                        convertFormat()
                        showFormatPicker = false
                    } label: {
                        Text(.localized("Convert"))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showFormatPicker = false
                    }
                }
            }
        }
    }
    
    private func loadContent() {
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Try to detect format
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                // Successfully parsed, now determine format
                var format: PropertyListSerialization.PropertyListFormat = .xml
                _ = try? PropertyListSerialization.propertyList(from: data, options: [], format: &format)
                selectedFormat = format == .binary ? .binary : .xml
                
                // Convert to XML string for display
                if format == .binary {
                    let xmlData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                    plistContent = String(data: xmlData, encoding: .utf8) ?? ""
                } else {
                    plistContent = String(data: data, encoding: .utf8) ?? ""
                }
            } else {
                plistContent = String(data: data, encoding: .utf8) ?? ""
            }
            
            validatePlist()
        } catch {
            plistContent = "Error loading file: \(error.localizedDescription)"
            validationError = error.localizedDescription
            AppLogManager.shared.error("Failed to load plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func validatePlist() {
        guard let data = plistContent.data(using: .utf8) else {
            validationError = "Invalid string encoding"
            return
        }
        
        do {
            _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            validationError = nil
        } catch {
            validationError = "Invalid plist: \(error.localizedDescription)"
        }
    }
    
    private func saveContent() {
        guard validationError == nil else {
            HapticsManager.shared.error()
            return
        }
        
        do {
            guard let data = plistContent.data(using: .utf8) else {
                throw NSError(domain: "PlistEditor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"])
            }
            
            // Validate and reserialize
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let outputData = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
            
            try outputData.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            isEditing = false
            loadContent() // Reload to show formatted version
        } catch {
            HapticsManager.shared.error()
            validationError = "Save failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to save plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func formatPlistContent() {
        guard selectedFormat == .xml else { return }
        
        do {
            guard let data = plistContent.data(using: .utf8) else { return }
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let formattedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            plistContent = String(data: formattedData, encoding: .utf8) ?? plistContent
            HapticsManager.shared.success()
        } catch {
            HapticsManager.shared.error()
        }
    }
    
    private func convertFormat() {
        do {
            guard let data = plistContent.data(using: .utf8) else { return }
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let convertedData = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
            
            try convertedData.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            loadContent()
        } catch {
            HapticsManager.shared.error()
            validationError = "Conversion failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to convert plist: \(error.localizedDescription)", category: "Files")
        }
    }
}
