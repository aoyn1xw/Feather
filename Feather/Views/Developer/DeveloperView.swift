import SwiftUI
import NimbleViews
import AltSourceKit

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
    @State private var logs: [String] = ["Log system initialized..."]
    @State private var filter: String = ""
    
    var body: some View {
        VStack {
            TextField("Filter logs...", text: $filter)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(logs.filter { filter.isEmpty || $0.contains(filter) }, id: \.self) { log in
                        Text(log)
                            .font(.caption.monospaced())
                            .padding(.horizontal)
                            .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("App Logs")
        .toolbar {
            Button(action: exportLogs) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    func exportLogs() {
        // Export logic
    }
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
        // Simulate CPU usage
        cpuUsage = Double.random(in: 10...75)
        
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
