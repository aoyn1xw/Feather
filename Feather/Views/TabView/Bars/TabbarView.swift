//  feather
import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .home
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
	}
}
