import SwiftUI
import NimbleViews

struct HexEditorView: View {
    @Environment(\.dismiss) var dismiss
    let fileURL: URL
    
    @State private var hexContent: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        NBNavigationView(.localized("Hex Editor"), displayMode: .inline) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading file...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // File info header
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(fileURL.lastPathComponent)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(hexContent.split(separator: "\n").count) lines")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                
                                // Hex content
                                Text(hexContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadHexContent()
        }
    }
    
    private func loadHexContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let hex = formatHexDump(data: data)
                
                DispatchQueue.main.async {
                    self.hexContent = hex
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.hexContent = "Error loading file: \(error.localizedDescription)"
                    self.isLoading = false
                }
                AppLogManager.shared.error("Failed to load file for hex editor: \(error.localizedDescription)", category: "Files")
            }
        }
    }
    
    private func formatHexDump(data: Data) -> String {
        var result = ""
        let bytesPerLine = 16
        
        for offset in stride(from: 0, to: data.count, by: bytesPerLine) {
            // Offset
            result += String(format: "%08X  ", offset)
            
            // Hex bytes
            for i in 0..<bytesPerLine {
                let index = offset + i
                if index < data.count {
                    result += String(format: "%02X ", data[index])
                } else {
                    result += "   "
                }
                
                if i == 7 {
                    result += " "
                }
            }
            
            result += " |"
            
            // ASCII representation
            for i in 0..<bytesPerLine {
                let index = offset + i
                if index < data.count {
                    let byte = data[index]
                    if byte >= 32 && byte <= 126 {
                        result += String(format: "%c", byte)
                    } else {
                        result += "."
                    }
                } else {
                    result += " "
                }
            }
            
            result += "|\n"
        }
        
        return result
    }
}
