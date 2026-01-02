//
//  ExperimentalTabbarView.swift
//  Feather
//
//  Experimental UI redesigned tabbar
//

import SwiftUI

struct ExperimentalTabbarView: View {
    @State private var selectedTab: TabEnum = .home
    @AppStorage("Feather.tabBar.home") private var showHome = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = true
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @Namespace private var animation
    
    var visibleTabs: [TabEnum] {
        var tabs: [TabEnum] = []
        if showHome { tabs.append(.home) }
        if showLibrary { tabs.append(.library) }
        if showFiles { tabs.append(.files) }
        if showGuides { tabs.append(.guides) }
        tabs.append(.settings)
        return tabs
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content with gradient background
            TabView(selection: $selectedTab) {
                ForEach(visibleTabs, id: \.hashValue) { tab in
                    ExperimentalTabContent(for: tab)
                        .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom floating tab bar
            ExperimentalCustomTabBar(
                selectedTab: $selectedTab,
                tabs: visibleTabs,
                namespace: animation
            )
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            .padding(.bottom, ExperimentalUITheme.Spacing.sm)
        }
        .experimentalGradientBackground()
    }
}

// MARK: - Experimental Tab Content
struct ExperimentalTabContent: View {
    let tab: TabEnum
    
    init(for tab: TabEnum) {
        self.tab = tab
    }
    
    var body: some View {
        Group {
            switch tab {
            case .home:
                ExperimentalSourcesView()
            case .library:
                ExperimentalLibraryView()
            case .settings:
                ExperimentalSettingsView()
            case .files:
                ExperimentalFilesView()
            case .guides:
                ExperimentalGuidesView()
            default:
                Text("Coming Soon")
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct ExperimentalCustomTabBar: View {
    @Binding var selectedTab: TabEnum
    let tabs: [TabEnum]
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.hashValue) { tab in
                ExperimentalTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                        HapticsManager.shared.softImpact()
                    }
                }
            }
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.sm)
        .padding(.vertical, ExperimentalUITheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: ExperimentalUITheme.Shadow.lg.color,
                    radius: ExperimentalUITheme.Shadow.lg.radius,
                    x: ExperimentalUITheme.Shadow.lg.x,
                    y: ExperimentalUITheme.Shadow.lg.y
                )
        )
    }
}

// MARK: - Tab Bar Item
struct ExperimentalTabBarItem: View {
    let tab: TabEnum
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                            .fill(ExperimentalUITheme.Gradients.primary)
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                            .frame(width: 50, height: 50)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : ExperimentalUITheme.Colors.textSecondary)
                        .frame(width: 50, height: 50)
                }
                
                if isSelected {
                    Text(tab.title)
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
