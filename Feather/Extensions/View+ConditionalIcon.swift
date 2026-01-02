import SwiftUI

// MARK: - View Extension for Conditional Icons
extension View {
	/// Conditionally hide icons based on user preference
	@ViewBuilder
	func hideIconIfNeeded() -> some View {
		@AppStorage("Feather.showIconsInAppearance") var showIcons: Bool = true
		if showIcons {
			self
		} else {
			EmptyView()
		}
	}
}

// MARK: - Helper for Conditional Label Creation
struct ConditionalLabel: View {
	let title: LocalizedStringKey
	let systemImage: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Label(title, systemImage: systemImage)
		} else {
			Text(title)
		}
	}
}

struct ConditionalLabelString: View {
	let title: String
	let systemImage: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Label(title, systemImage: systemImage)
		} else {
			Text(title)
		}
	}
}

// MARK: - Helper for Conditional Image
struct ConditionalImage: View {
	let systemName: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Image(systemName: systemName)
		} else {
			EmptyView()
		}
	}
}
