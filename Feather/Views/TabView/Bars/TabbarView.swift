//  feather
import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .home
	@AppStorage("Feather.tabBar.home") private var showHome = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = true
	@AppStorage("Feather.tabBar.guides") private var showGuides = true
	
	var visibleTabs: [TabEnum] {
		var tabs: [TabEnum] = []
		if showHome { tabs.append(.home) }
		if showLibrary { tabs.append(.library) }
		if showFiles { tabs.append(.files) }
		if showGuides { tabs.append(.guides) }
		tabs.append(.settings) // Always show settings
		return tabs
	}

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(visibleTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
	}
}
