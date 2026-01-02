import SwiftUI
import NimbleViews
import Zip

// MARK: - ZipOperationView
struct ZipOperationView: View {
    let files: [FileItem]
    let operation: Operation
    let directoryURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var zipName: String = ""
    @State private var targetDirectory: URL?
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var errorMessage: String?
    @State private var conflictResolution: ConflictResolution = .rename
    
    enum Operation {
        case zip
        case unzip
    }
    
    enum ConflictResolution: String, CaseIterable {
        case rename = "Rename"
        case replace = "Replace"
        case skip = "Skip"
    }
    
    var body: some View {
        NBNavigationView(operation == .zip ? .localized("Create Zip") : .localized("Unzip File"), displayMode: .inline) {
            Form {
                if operation == .zip {
                    zipConfigSection
                } else {
                    unzipConfigSection
                }
                
                if isProcessing {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: progress, total: 1.0)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text(.localized("Progress"))
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    } header: {
                        Text(.localized("Error"))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(operation == .zip ? .localized("Zip") : .localized("Unzip")) {
                        performOperation()
                    }
                    .disabled(isProcessing || (operation == .zip && zipName.isEmpty))
                }
            }
        }
        .onAppear {
            targetDirectory = directoryURL
            if operation == .zip {
                zipName = "Archive"
            }
        }
    }
    
    @ViewBuilder
    private var zipConfigSection: some View {
        Section {
            TextField(.localized("Archive Name"), text: $zipName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text(.localized("Archive Name"))
        } footer: {
            Text(.localized("Name for the zip archive (without .zip extension)"))
        }
        
        Section {
            ForEach(files) { file in
                HStack {
                    Image(systemName: file.icon)
                        .foregroundStyle(file.iconColor)
                    Text(file.name)
                }
            }
        } header: {
            Text(.localized("Files to Zip"))
        }
    }
    
    @ViewBuilder
    private var unzipConfigSection: some View {
        Section {
            if let zipFile = files.first {
                HStack {
                    Image(systemName: zipFile.icon)
                        .foregroundStyle(zipFile.iconColor)
                    Text(zipFile.name)
                }
            }
        } header: {
            Text(.localized("Archive"))
        }
        
        Section {
            Picker(.localized("If File Exists"), selection: $conflictResolution) {
                ForEach(ConflictResolution.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } header: {
            Text(.localized("Conflict Resolution"))
        } footer: {
            Text(.localized("Choose what to do if files already exist"))
        }
    }
    
    private func performOperation() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                if operation == .zip {
                    try await performZip()
                } else {
                    try await performUnzip()
                }
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    FileManagerService.shared.loadFiles()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    HapticsManager.shared.error()
                    isProcessing = false
                }
            }
        }
    }
    
    private func performZip() async throws {
        let zipURL = directoryURL.appendingPathComponent(zipName + ".zip")
        let filePaths = files.map { $0.url }
        
        try await Task.detached(priority: .userInitiated) { [self] in
            try Zip.zipFiles(
                paths: filePaths,
                zipFilePath: zipURL,
                password: nil,
                compression: .DefaultCompression,
                progress: { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                    }
                }
            )
        }.value
    }
    
    private func performUnzip() async throws {
        guard let zipFile = files.first else { return }
        let destinationURL = directoryURL
        
        try await Task.detached(priority: .userInitiated) { [self] in
            try await Zip.unzipFile(
                zipFile.url,
                destination: destinationURL,
                overwrite: conflictResolution == .replace,
                password: nil,
                progress: { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                    }
                }
            )
        }.value
    }
}
