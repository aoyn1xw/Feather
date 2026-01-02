import SwiftUI
import NimbleViews

// MARK: - TabBarCustomizationView
struct TabBarCustomizationView: View {
    @AppStorage("Feather.tabBar.home") private var showHome = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = true
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "home,library,files,guides,settings"
    // Settings cannot be disabled
    
    @State private var showMinimumWarning = false
    @State private var editMode: EditMode = .inactive
    @State private var orderedTabs: [String] = []
    
    var body: some View {
        NBList(.localized("Tab Bar")) {
            Section {
                ForEach(orderedTabs, id: \.self) { tabId in
                    tabRow(for: tabId)
                }
                .onMove(perform: moveTabs)
            } header: {
                Text(.localized("Visible Tabs"))
            } footer: {
                Text(.localized("Choose which tabs appear in the tab bar. You can also reorder tabs by tapping Edit and dragging them. Settings cannot be hidden and at least 2 tabs must be visible."))
            }
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .inactive ? .localized("Edit") : .localized("Done")) {
                    withAnimation {
                        if editMode == .inactive {
                            editMode = .active
                        } else {
                            editMode = .inactive
                        }
                    }
                }
            }
        }
        .onAppear {
            loadTabOrder()
        }
        .alert(.localized("Minimum Tabs Required"), isPresented: $showMinimumWarning) {
            Button(.localized("OK")) {
                showMinimumWarning = false
            }
        } message: {
            Text(.localized("At least 2 tabs must be visible (including Settings)."))
        }
    }
    
    @ViewBuilder
    private func tabRow(for tabId: String) -> some View {
        switch tabId {
        case "home":
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
            
        case "library":
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
            
        case "files":
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
            
        case "guides":
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
            
        case "settings":
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
            
        default:
            EmptyView()
        }
    }
    
    private func loadTabOrder() {
        let tabs = tabOrder.split(separator: ",").map(String.init)
        orderedTabs = tabs.isEmpty ? ["home", "library", "files", "guides", "settings"] : tabs
    }
    
    private func moveTabs(from source: IndexSet, to destination: Int) {
        orderedTabs.move(fromOffsets: source, toOffset: destination)
        tabOrder = orderedTabs.joined(separator: ",")
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
