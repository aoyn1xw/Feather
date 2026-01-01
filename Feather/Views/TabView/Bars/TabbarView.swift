//  feather
import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .home
	@AppStorage("Feather.filesTabEnabled") private var filesTabEnabled = false

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
			
			ForEach(TabEnum.customizableTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
		.id(filesTabEnabled) // Force refresh when files tab setting changes
	}
}
