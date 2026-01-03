import SwiftUI
import NimbleViews

// MARK: - ManageStorageView
struct ManageStorageView: View {
    @State private var cleanupPeriod: CleanupPeriod = .thirtyDays
    @State private var isCalculating = false
    
    // Storage data
    @State private var usedSpace: Int64 = 0
    @State private var totalSpace: Int64 = 0
    @State private var availableSpace: Int64 = 0
    
    // Breakdown data
    @State private var signedAppsSize: Int64 = 0
    @State private var importedAppsSize: Int64 = 0
    @State private var certificatesSize: Int64 = 0
    @State private var cacheSize: Int64 = 0
    @State private var archivesSize: Int64 = 0
    
    // Cleanup data
    @State private var reclaimableSpace: Int64 = 0
    
    var body: some View {
        NBNavigationView(.localized("Manage Storage"), displayMode: .inline) {
            Form {
                storageOverviewSection
                storageBreakdownSection
                storageCleanupSection
            }
            .onAppear {
                calculateStorageData()
            }
        }
    }
    
    // MARK: - Storage Overview Section
    private var storageOverviewSection: some View {
        Section {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    // Used column
                    VStack(spacing: 4) {
                        Text(.localized("Used"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(usedSpace))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Total column
                    VStack(spacing: 4) {
                        Text(.localized("Total"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(totalSpace))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Available column
                    VStack(spacing: 4) {
                        Text(.localized("Available"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(availableSpace))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Progress bar or visual representation
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        if totalSpace > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(usedSpace) / CGFloat(totalSpace), height: 8)
                        }
                    }
                }
                .frame(height: 8)
                .padding(.bottom, 8)
            }
        } footer: {
            Text(.localized("Shows storage used by Feather on this device"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Storage Breakdown Section
    private var storageBreakdownSection: some View {
        Section {
            VStack(spacing: 0) {
                storageBreakdownRow(label: .localized("Signed Apps"), size: signedAppsSize)
                Divider()
                storageBreakdownRow(label: .localized("Imported Apps"), size: importedAppsSize)
                Divider()
                storageBreakdownRow(label: .localized("Certificates"), size: certificatesSize)
                Divider()
                storageBreakdownRow(label: .localized("Cache"), size: cacheSize)
                Divider()
                storageBreakdownRow(label: .localized("Archives"), size: archivesSize)
                Divider()
                    .padding(.vertical, 8)
                
                // Total row - emphasized
                HStack {
                    Text(.localized("Total"))
                        .font(.system(.body, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formatBytes(totalFeatherStorage))
                        .font(.system(.body, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(.localized("STORAGE BREAKDOWN"))
        } footer: {
            Text(.localized("Detailed breakdown of storage used by Feather categories"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Storage Cleanup Section
    private var storageCleanupSection: some View {
        Section {
            VStack(spacing: 0) {
                // Cleanup period selector
                HStack {
                    Text(.localized("Remove items older than"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Menu {
                        ForEach(CleanupPeriod.allCases, id: \.self) { period in
                            Button(period.displayName) {
                                cleanupPeriod = period
                                calculateReclaimableSpace()
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(cleanupPeriod.displayName)
                                .foregroundStyle(.blue)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Description
                Text(.localized("This will remove temporary files, cached data, and old work files that are no longer needed."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                
                // Reclaimable space highlight
                Text("\(formatBytes(reclaimableSpace)) can be removed")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Cleanup button
                Button {
                    performCleanup()
                } label: {
                    HStack {
                        Spacer()
                        Text(.localized("Clean Up Storage"))
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(reclaimableSpace == 0 || isCalculating)
                .opacity(reclaimableSpace == 0 || isCalculating ? 0.5 : 1.0)
            }
            .padding(.vertical, 4)
        } header: {
            Text(.localized("STORAGE CLEANUP"))
        } footer: {
            Text(.localized("Signed apps, imported apps, and certificates are never deleted during cleanup."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helper Views
    private func storageBreakdownRow(label: LocalizedStringKey, size: Int64) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(formatBytes(size))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    private var totalFeatherStorage: Int64 {
        signedAppsSize + importedAppsSize + certificatesSize + cacheSize + archivesSize
    }
    
    // MARK: - Storage Calculation Methods
    private func calculateStorageData() {
        isCalculating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Calculate device storage
            let fileSystemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let totalSpaceValue = (fileSystemAttributes?[.systemSize] as? NSNumber)?.int64Value ?? 0
            let freeSpaceValue = (fileSystemAttributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            
            // Calculate category sizes
            let signedSize = calculateDirectorySize(at: FileManager.default.signed)
            let importedSize = calculateDirectorySize(at: FileManager.default.unsigned)
            let certificatesSize = calculateDirectorySize(at: FileManager.default.certificates)
            let archivesSize = calculateDirectorySize(at: FileManager.default.archives)
            let cacheSize = calculateCacheSize()
            
            DispatchQueue.main.async {
                self.totalSpace = totalSpaceValue
                self.availableSpace = freeSpaceValue
                self.usedSpace = totalSpaceValue - freeSpaceValue
                
                self.signedAppsSize = signedSize
                self.importedAppsSize = importedSize
                self.certificatesSize = certificatesSize
                self.archivesSize = archivesSize
                self.cacheSize = cacheSize
                
                self.calculateReclaimableSpace()
                self.isCalculating = false
            }
        }
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
    
    private func calculateCacheSize() -> Int64 {
        var totalCacheSize = Int64(URLCache.shared.currentDiskUsage)
        
        // Add temporary directory size
        let tmpDirectory = FileManager.default.temporaryDirectory
        totalCacheSize += calculateDirectorySize(at: tmpDirectory)
        
        return totalCacheSize
    }
    
    private func calculateReclaimableSpace() {
        DispatchQueue.global(qos: .userInitiated).async {
            let reclaimable = self.calculateOldCacheSize(olderThan: self.cleanupPeriod.days)
            
            DispatchQueue.main.async {
                self.reclaimableSpace = reclaimable
            }
        }
    }
    
    private func calculateOldCacheSize(olderThan days: Int) -> Int64 {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var oldCacheSize: Int64 = 0
        
        let tmpDirectory = FileManager.default.temporaryDirectory
        
        if let enumerator = FileManager.default.enumerator(at: tmpDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                   let modificationDate = resourceValues.contentModificationDate,
                   let fileSize = resourceValues.fileSize,
                   modificationDate < cutoffDate {
                    oldCacheSize += Int64(fileSize)
                }
            }
        }
        
        return oldCacheSize
    }
    
    // MARK: - Cleanup Action
    private func performCleanup() {
        isCalculating = true
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -cleanupPeriod.days, to: Date()) ?? Date()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tmpDirectory = FileManager.default.temporaryDirectory
            
            if let enumerator = FileManager.default.enumerator(at: tmpDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if let modificationDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                       modificationDate < cutoffDate {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
            }
            
            // Clear network cache
            URLCache.shared.removeAllCachedResponses()
            
            DispatchQueue.main.async {
                HapticsManager.shared.success()
                self.calculateStorageData()
            }
        }
    }
    
    // MARK: - Formatting
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - CleanupPeriod Enum
enum CleanupPeriod: CaseIterable {
    case sevenDays
    case thirtyDays
    case ninetyDays
    case oneYear
    
    var displayName: String {
        switch self {
        case .sevenDays: return .localized("7 Days")
        case .thirtyDays: return .localized("30 Days")
        case .ninetyDays: return .localized("90 Days")
        case .oneYear: return .localized("1 Year")
        }
    }
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneYear: return 365
        }
    }
}

// MARK: - Preview
struct ManageStorageView_Previews: PreviewProvider {
    static var previews: some View {
        ManageStorageView()
    }
}
