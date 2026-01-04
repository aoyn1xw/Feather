//  feather
import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .home
	@AppStorage("Feather.tabBar.home") private var showHome = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = true
	@AppStorage("Feather.tabBar.guides") private var showGuides = true
	@AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
	@AppStorage("forceShowGuides") private var forceShowGuides = false
	
	@State private var showInstallModifySheet = false
	@State private var appToInstall: (any AppInfoPresentable)?
	
	var visibleTabs: [TabEnum] {
		var tabs: [TabEnum] = []
		if showHome { tabs.append(.home) }
		if showLibrary { tabs.append(.library) }
		if showFiles { tabs.append(.files) }
		
		// Only show Guides if:
		// 1. forceShowGuides is enabled (set by Enterprise certificate)
		// 2. OR certificate experience is Enterprise
		if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
			tabs.append(.guides)
		}
		
		tabs.append(.settings) // Always show settings
		return tabs
	}

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(visibleTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						ConditionalLabel(title: LocalizedStringKey(tab.title), systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
		.sheet(isPresented: $showInstallModifySheet) {
			if let app = appToInstall {
				InstallPreviewView(app: app, isSharing: false, fromLibraryTab: false)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.showInstallModifyPopup"))) { notification in
			// Get the downloaded app from the Library
			if let url = notification.object as? URL {
				// Find the app in library by checking the file name
				let fileName = url.deletingPathExtension().lastPathComponent
				
				// Check both Signed and Imported apps
				let signedRequest = Signed.fetchRequest()
				let importedRequest = Imported.fetchRequest()
				
				if let signed = try? Storage.shared.context.fetch(signedRequest).first(where: { 
					$0.name?.contains(fileName) == true || $0.identifier?.contains(fileName) == true
				}) {
					appToInstall = signed
					showInstallModifySheet = true
				} else if let imported = try? Storage.shared.context.fetch(importedRequest).first(where: { 
					$0.name?.contains(fileName) == true || $0.identifier?.contains(fileName) == true
				}) {
					appToInstall = imported
					showInstallModifySheet = true
				}
			}
		}
	}
}
