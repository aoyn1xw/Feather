import SwiftUI
import NimbleViews
import AltSourceKit

// MARK: - Developer View
struct DeveloperView: View {
    @AppStorage("debugModeEnabled") private var debugModeEnabled = false
    @AppStorage("showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("slowAnimations") private var slowAnimations = false
    
    var body: some View {
        NBNavigationView("Developer") {
            List {
                Section {
                    NavigationLink(destination: AppLogsView()) {
                        Label("App Logs", systemImage: "terminal")
                    }
                    Toggle("Debug Mode", isOn: $debugModeEnabled)
                        .onChange(of: debugModeEnabled) { newValue in
                            // Enable verbose logging
                        }
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
                            UIApplication.shared.windows.first?.layer.speed = newValue ? 0.1 : 1.0
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
    }
    
    private func resetAppState() {
        // Implementation to clear cache, etc.
    }
    
    private func resetSettings() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - Subviews

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
    
    var body: some View {
        List {
            Toggle("Experimental UI", isOn: $newUI)
        }
        .navigationTitle("Feature Flags")
    }
}
