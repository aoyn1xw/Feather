import SwiftUI

extension SearchFieldPlacement {
	@MainActor public static func platform() -> SearchFieldPlacement {
		UIDevice.current.userInterfaceIdiom == .pad ? .automatic : .navigationBarDrawer(displayMode: .always)
	}
}
