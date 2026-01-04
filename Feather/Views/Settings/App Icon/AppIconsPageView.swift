import SwiftUI
import NimbleViews

// MARK: - View
struct AppIconsPageView: View {
	@Binding var currentIcon: String?
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("App Icons")) {
			Form {
				Section {
					VStack(spacing: 16) {
						Image(systemName: "app.dashed")
							.font(.system(size: 60))
							.foregroundColor(.secondary)
						
						Text("App Icons Soon")
							.font(.title2)
							.fontWeight(.semibold)
							.foregroundColor(.primary)
						
						Text("Customize your app icon. Coming soon!")
							.font(.subheadline)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 40)
				}
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets())
			}
		}
	}
}
