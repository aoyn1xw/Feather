import SwiftUI
import NimbleViews

// MARK: - FileInfoView
struct FileInfoView: View {
    let file: FileItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NBNavigationView(.localized("File Info"), displayMode: .inline) {
            Form {
                // File icon and name header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(file.iconColor.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: file.icon)
                                    .font(.system(size: 36))
                                    .foregroundStyle(file.iconColor)
                            }
                            
                            Text(file.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
                
                Section {
                    InfoRow(label: .localized("Name"), value: file.name)
                    InfoRow(label: .localized("Type"), value: file.isDirectory ? .localized("Folder") : file.url.pathExtension.uppercased())
                    if let size = file.size {
                        InfoRow(label: .localized("Size"), value: size)
                    }
                } header: {
                    Text(.localized("General"))
                }
                
                Section {
                    InfoRow(label: .localized("Path"), value: file.url.path)
                    if let modDate = file.modificationDate {
                        InfoRow(label: .localized("Modified"), value: formatDate(modDate))
                    }
                } header: {
                    Text(.localized("Details"))
                }
                
                Section {
                    Button {
                        UIPasteboard.general.string = file.url.path
                        HapticsManager.shared.success()
                    } label: {
                        Label(.localized("Copy Path"), systemImage: "doc.on.doc")
                    }
                } header: {
                    Text(.localized("Actions"))
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
    }
}
