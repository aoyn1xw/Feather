//  feather
import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
	case home
	case library
	case settings
	case certificates
	case files
	
	var title: String {
		switch self {
		case .home:     	return .localized("Home")
		case .library: 		return .localized("Library")
		case .settings: 	return .localized("Settings")
		case .certificates:	return .localized("Certificates")
		case .files:		return .localized("Files")
		}
	}
	
	var icon: String {
		switch self {
		case .home: 		return "globe.desk"
		case .library: 		return "square.grid.2x2"
		case .settings: 	return "gearshape.2"
		case .certificates: return "person.text.rectangle"
		case .files:		return "folder.fill"
		}
	}
	
	@ViewBuilder
	static func view(for tab: TabEnum) -> some View {
		switch tab {
		case .home: SourcesView()
		case .library: LibraryView()
		case .settings: SettingsView()
		case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
		case .files: FilesView()
		}
	}
	
	static var defaultTabs: [TabEnum] {
		return [
			.home,
			.library,
			.settings
		]
	}
	
	static var customizableTabs: [TabEnum] {
		var tabs = [TabEnum.certificates]
		if UserDefaults.standard.bool(forKey: "Feather.filesTabEnabled") {
			tabs.append(.files)
		}
		return tabs
	}
}
