//  feather
import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
	case home
	case library
	case settings
	case certificates
	case developer
	
	var title: String {
		switch self {
		case .home:     	return .localized("Home")
		case .library: 		return .localized("Library")
		case .settings: 	return .localized("Settings")
		case .certificates:	return .localized("Certificates")
		case .developer:    return .localized("Developer")
		}
	}
	
	var icon: String {
		switch self {
		case .home: 		return "globe.desk"
		case .library: 		return "square.grid.2x2"
		case .settings: 	return "gearshape.2"
		case .certificates: return "person.text.rectangle"
		case .developer:    return "hammer.fill"
		}
	}
	
	@ViewBuilder
	static func view(for tab: TabEnum) -> some View {
		switch tab {
		case .home: SourcesView()
		case .library: LibraryView()
		case .settings: SettingsView()
		case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
		case .developer: DeveloperView()
		}
	}
	
	static var defaultTabs: [TabEnum] {
		var tabs: [TabEnum] = [
			.home,
			.library,
			.settings
		]
        if UserDefaults.standard.bool(forKey: "isDeveloperModeEnabled") {
            tabs.append(.developer)
        }
        return tabs
	}
	
	static var customizableTabs: [TabEnum] {
		return [
			.certificates
		]
	}
}
