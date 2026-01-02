import SwiftUI
import NimbleViews

// MARK: - TabBarCustomizationView
struct TabBarCustomizationView: View {
    @AppStorage("Feather.tabBar.home") private var showHome = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = true
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    // Settings cannot be disabled
    
    @State private var showMinimumWarning = false
    
    var body: some View {
        NBList(.localized("Tab Bar")) {
            Section {
                Toggle(isOn: $showHome) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text(.localized("Home"))
                    }
                }
                .disabled(!canDisable(.home))
                .onChange(of: showHome) { _ in validateMinimumTabs() }
                
                Toggle(isOn: $showLibrary) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        Text(.localized("Library"))
                    }
                }
                .disabled(!canDisable(.library))
                .onChange(of: showLibrary) { _ in validateMinimumTabs() }
                
                Toggle(isOn: $showFiles) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text(.localized("Files"))
                    }
                }
                .disabled(!canDisable(.files))
                .onChange(of: showFiles) { _ in validateMinimumTabs() }
                
                Toggle(isOn: $showGuides) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text(.localized("Guides"))
                    }
                }
                .disabled(!canDisable(.guides))
                .onChange(of: showGuides) { _ in validateMinimumTabs() }
                
                HStack {
                    Image(systemName: "gearshape.2")
                        .foregroundStyle(.gray)
                        .frame(width: 24)
                    Text(.localized("Settings"))
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } header: {
                Text(.localized("Visible Tabs"))
            } footer: {
                Text(.localized("Choose which tabs appear in the tab bar. Settings cannot be hidden and at least 2 tabs must be visible."))
            }
        }
        .alert(.localized("Minimum Tabs Required"), isPresented: $showMinimumWarning) {
            Button(.localized("OK")) {
                showMinimumWarning = false
            }
        } message: {
            Text(.localized("At least 2 tabs must be visible (including Settings)."))
        }
    }
    
    private func validateMinimumTabs() {
        let visibleCount = [showHome, showLibrary, showFiles, showGuides].filter { $0 }.count + 1 // +1 for Settings
        if visibleCount < 2 {
            showMinimumWarning = true
            // Revert the last change
            if !showHome && !showLibrary && !showFiles && !showGuides {
                // Need at least one non-settings tab
                showHome = true
            }
        }
    }
    
    private func canDisable(_ tab: TabEnum) -> Bool {
        let visibleCount = [showHome, showLibrary, showFiles, showGuides].filter { $0 }.count + 1
        if visibleCount <= 2 {
            // Check if this specific tab is currently enabled
            switch tab {
            case .home: return !showHome
            case .library: return !showLibrary
            case .files: return !showFiles
            case .guides: return !showGuides
            default: return false
            }
        }
        return true
    }
}
