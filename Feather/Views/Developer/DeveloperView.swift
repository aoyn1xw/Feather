import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin

// MARK: - Developer View
struct DeveloperView: View {
    @AppStorage("debugModeEnabled") private var debugModeEnabled = false
    @AppStorage("showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("slowAnimations") private var slowAnimations = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        NBNavigationView("Developer") {
            List {
                Section {
                    NavigationLink(destination: AppLogsView()) {
                        Label("App Logs", systemImage: "terminal")
                    }
                    NavigationLink(destination: NetworkInspectorView()) {
                        Label("Network Inspector", systemImage: "network")
                    }
                    NavigationLink(destination: PerformanceMonitorView()) {
                        Label("Performance Monitor", systemImage: "speedometer")
                    }
                    Toggle("Debug Mode", isOn: $debugModeEnabled)
                        .onChange(of: debugModeEnabled) { newValue in
                            // Enable verbose logging
                        }
                    Toggle("Verbose Logging", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "verboseLogging") },
                        set: { UserDefaults.standard.set($0, forKey: "verboseLogging") }
                    ))
                } header: {
                    Text("Diagnostics")
                }
                
                Section {
                    NavigationLink(destination: IPAInspectorView()) {
                        Label("IPA Inspector", systemImage: "doc.zipper")
                    }
                    NavigationLink(destination: IPAIntegrityCheckerView()) {
                        Label("Integrity Checker", systemImage: "checkmark.shield")
                    }
                    NavigationLink(destination: FileSystemBrowserView()) {
                        Label("File System", systemImage: "folder")
                    }
                } header: {
                    Text("Analysis")
                }
                
                Section {
                    NavigationLink(destination: SourceDataView()) {
                        Label("Source Data", systemImage: "server.rack")
                    }
                    NavigationLink(destination: AppStateView()) {
                        Label("App State & Storage", systemImage: "memorychip")
                    }
                    NavigationLink(destination: UserDefaultsEditorView()) {
                        Label("UserDefaults Editor", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: CoreDataInspectorView()) {
                        Label("CoreData Inspector", systemImage: "cylinder.split.1x2")
                    }
                } header: {
                    Text("Data")
                }
                
                Section {
                    Toggle("Show Layout Boundaries", isOn: $showLayoutBoundaries)
                        .onChange(of: showLayoutBoundaries) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "_UIConstraintBasedLayoutPlayground")
                        }
                    
                    Toggle("Slow Animations", isOn: $slowAnimations)
                        .onChange(of: slowAnimations) { newValue in
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.first?.layer.speed = newValue ? 0.1 : 1.0
                            }
                        }
                } header: {
                    Text("UI Debugging")
                }
                
                Section {
                    NavigationLink(destination: FeatureFlagsView()) {
                        Label("Feature Flags", systemImage: "flag")
                    }
                } header: {
                    Text("Experiments")
                }
                
                Section {
                    Button(role: .destructive) {
                        resetAppState()
                    } label: {
                        Label("Reset App State", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        resetSettings()
                    } label: {
                        Label("Reset Settings", systemImage: "gear.badge.xmark")
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "exclamationmark.triangle.fill")
                    }
                } header: {
                    Text("Danger Zone")
                }
                
                Section {
                    Button("Lock Developer Mode") {
                        UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all sources, apps, settings, and certificates. This action cannot be undone.")
        }
    }
    
    private func resetAppState() {
        // Implementation to clear cache, etc.
    }
    
    private func resetSettings() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    private func resetAllData() {
        resetAppState()
        resetSettings()
        // Add more reset logic here (e.g. delete CoreData store)
    }
}

// MARK: - Subviews

struct NetworkInspectorView: View {
    var body: some View {
        List {
            Text("No active requests")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Network Inspector")
    }
}

struct FileSystemBrowserView: View {
    var body: some View {
        List {
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                Text(documentsPath.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Documents")
            Text("Library")
            Text("tmp")
        }
        .navigationTitle("File System")
    }
}

struct UserDefaultsEditorView: View {
    var body: some View {
        List {
            ForEach(Array(UserDefaults.standard.dictionaryRepresentation().keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption.monospaced())
                    Spacer()
                    Text("\(String(describing: UserDefaults.standard.object(forKey: key) ?? "nil"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .navigationTitle("UserDefaults")
    }
}

struct AppLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var selectedCategory: String?
    @State private var showFilters = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var autoScroll = true
    
    var filteredLogs: [LogEntry] {
        logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All logs
                        FilterPill(
                            title: "All",
                            isSelected: selectedLevel == nil,
                            count: logManager.logs.count
                        ) {
                            selectedLevel = nil
                        }
                        
                        // Level filters
                        ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                            let count = logManager.logs.filter { $0.level == level }.count
                            if count > 0 {
                                FilterPill(
                                    title: level.rawValue,
                                    icon: level.icon,
                                    isSelected: selectedLevel == level,
                                    count: count
                                ) {
                                    selectedLevel = selectedLevel == level ? nil : level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
            
            Divider()
            
            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text(logManager.logs.isEmpty ? "No logs yet" : "No matching logs")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if !logManager.logs.isEmpty {
                        Text("Try adjusting your search or filters")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredLogs) { log in
                                LogEntryRow(entry: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: filteredLogs.count) { _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Auto-scroll toggle
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                
                // Clear logs
                Button(role: .destructive, action: {
                    logManager.clearLogs()
                }) {
                    Image(systemName: "trash")
                }
                
                // Share menu
                Menu {
                    Button(action: shareAsText) {
                        Label("Share as Text", systemImage: "doc.text")
                    }
                    
                    Button(action: shareAsJSON) {
                        Label("Share as JSON", systemImage: "doc.badge.gearshape")
                    }
                    
                    Button(action: copyToClipboard) {
                        Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [shareText])
        }
        .onAppear {
            // Add initial log
            if logManager.logs.isEmpty {
                logManager.info("App Logs view initialized", category: "Developer")
            }
        }
    }
    
    private func shareAsText() {
        shareText = logManager.exportLogs()
        showShareSheet = true
    }
    
    private func shareAsJSON() {
        if let jsonData = logManager.exportLogsAsJSON(),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            shareText = jsonString
            showShareSheet = true
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = logManager.exportLogs()
        logManager.success("Logs copied to clipboard", category: "Developer")
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                }
                Text(title)
                    .font(.caption.bold())
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // Level indicator
                Text(entry.level.icon)
                    .font(.system(size: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    // Main message
                    HStack {
                        Text(entry.formattedTimestamp)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        
                        Text("[\(entry.category)]")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                    
                    Text(entry.message)
                        .font(.caption.monospaced())
                        .foregroundStyle(levelColor(entry.level))
                    
                    // Expanded details
                    if isExpanded {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            DetailRow(label: "Level", value: entry.level.rawValue)
                            DetailRow(label: "Category", value: entry.category)
                            DetailRow(label: "File", value: entry.file)
                            DetailRow(label: "Function", value: entry.function)
                            DetailRow(label: "Line", value: "\(entry.line)")
                        }
                        .font(.caption2.monospaced())
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(levelBackgroundColor(entry.level))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(levelBorderColor(entry.level), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    private func levelColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    private func levelBackgroundColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.05)
    }
    
    private func levelBorderColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.2)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct IPAInspectorView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    
    var body: some View {
        List {
            Button("Select IPA File") {
                isImporting = true
            }
            
            if let file = selectedFile {
                Section("Metadata") {
                    Text("File: \(file.lastPathComponent)")
                    // Add more metadata extraction logic here
                }
            }
        }
        .navigationTitle("IPA Inspector")
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item]) { result in
            if let url = try? result.get() {
                selectedFile = url
            }
        }
    }
}

struct IPAIntegrityCheckerView: View {
    var body: some View {
        Text("Integrity Checker Placeholder")
            .navigationTitle("Integrity Checker")
    }
}

struct SourceDataView: View {
    var body: some View {
        List {
            ForEach(Storage.shared.getSources(), id: \.self) { source in
                NavigationLink(destination: JSONViewer(json: source.description)) {
                    Text(source.name ?? "Unknown")
                }
            }
        }
        .navigationTitle("Source Data")
    }
}

struct JSONViewer: View {
    let json: String
    var body: some View {
        ScrollView {
            Text(json)
                .font(.caption.monospaced())
                .padding()
        }
        .navigationTitle("JSON")
    }
}

struct AppStateView: View {
    var body: some View {
        List {
            Section("Storage") {
                Text("Documents: \(getDocumentsSize())")
                Text("Cache: \(getCacheSize())")
            }
        }
        .navigationTitle("App State")
    }
    
    func getDocumentsSize() -> String {
        // Calculate size
        return "12.5 MB"
    }
    
    func getCacheSize() -> String {
        return "4.2 MB"
    }
}

struct FeatureFlagsView: View {
    @AppStorage("feature_newUI") var newUI = false
    @AppStorage("feature_enhancedAnimations") var enhancedAnimations = false
    @AppStorage("feature_advancedSigning") var advancedSigning = false
    
    var body: some View {
        List {
            Toggle("Experimental UI", isOn: $newUI)
            Toggle("Enhanced Animations", isOn: $enhancedAnimations)
            Toggle("Advanced Signing Options", isOn: $advancedSigning)
        }
        .navigationTitle("Feature Flags")
    }
}

struct PerformanceMonitorView: View {
    @State private var cpuUsage: Double = 0.0
    @State private var memoryUsage: String = "0 MB"
    @State private var diskSpace: String = "0 GB"
    @State private var timer: Timer?
    
    var body: some View {
        List {
            Section("System Resources") {
                HStack {
                    Label("CPU Usage", systemImage: "cpu")
                    Spacer()
                    Text("\(Int(cpuUsage))%")
                        .foregroundStyle(cpuUsage > 80 ? .red : cpuUsage > 50 ? .orange : .green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Memory", systemImage: "memorychip")
                    Spacer()
                    Text(memoryUsage)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("Disk Space", systemImage: "internaldrive")
                    Spacer()
                    Text(diskSpace)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("App Performance") {
                HStack {
                    Label("Frame Rate", systemImage: "waveform.path.ecg")
                    Spacer()
                    Text("60 FPS")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Launch Time", systemImage: "timer")
                    Spacer()
                    Text("0.8s")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Performance Monitor")
        .onAppear {
            updateMetrics()
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                updateMetrics()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateMetrics() {
        // Get CPU usage - using host_processor_info
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var usage: Double = 0.0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo)
        
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            let cpuLoadInfo = cpuInfo.withMemoryRebound(to: processor_cpu_load_info_t.self, capacity: Int(numCPUs)) { $0 }
            
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            var totalNice: UInt32 = 0
            
            for i in 0..<Int(numCPUs) {
                let cpuLoad = cpuLoadInfo[i]
                // CPU_STATE_USER = 0, CPU_STATE_SYSTEM = 1, CPU_STATE_IDLE = 2, CPU_STATE_NICE = 3
                totalUser += cpuLoad.pointee.cpu_ticks.0    // CPU_STATE_USER
                totalSystem += cpuLoad.pointee.cpu_ticks.1  // CPU_STATE_SYSTEM
                totalIdle += cpuLoad.pointee.cpu_ticks.2    // CPU_STATE_IDLE
                totalNice += cpuLoad.pointee.cpu_ticks.3    // CPU_STATE_NICE
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle + totalNice
            if totalTicks > 0 {
                let usedTicks = totalUser + totalSystem + totalNice
                usage = Double(usedTicks) / Double(totalTicks) * 100.0
            }
            
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.stride))
        }
        
        cpuUsage = min(usage, 100.0)
        
        // Get memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            memoryUsage = String(format: "%.1f MB", usedMB)
        }
        
        // Get disk space
        if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
            let freeGB = Double(truncating: freeSpace) / 1024.0 / 1024.0 / 1024.0
            diskSpace = String(format: "%.1f GB free", freeGB)
        }
    }
}

struct CoreDataInspectorView: View {
    var body: some View {
        List {
            Section("Entities") {
                NavigationLink("Certificates") {
                    EntityDetailView(entityName: "Certificate")
                }
                NavigationLink("Sources") {
                    EntityDetailView(entityName: "AltSource")
                }
                NavigationLink("Signed Apps") {
                    EntityDetailView(entityName: "Signed")
                }
                NavigationLink("Imported Apps") {
                    EntityDetailView(entityName: "Imported")
                }
            }
            
            Section("Statistics") {
                HStack {
                    Text("Total Certificates")
                    Spacer()
                    Text("\(Storage.shared.getCertificates().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Sources")
                    Spacer()
                    Text("\(Storage.shared.getSources().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Signed Apps")
                    Spacer()
                    Text("\(Storage.shared.getSignedApps().count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("CoreData Inspector")
    }
}

struct EntityDetailView: View {
    let entityName: String
    
    var body: some View {
        List {
            Text("Entity: \(entityName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // Add more detailed entity inspection here
        }
        .navigationTitle(entityName)
    }
}
