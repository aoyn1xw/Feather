import SwiftUI
import NimbleViews

// MARK: - View
struct AppIconView: View {
	@Binding var currentIcon: String?
	
	// MARK: Body
	var body: some View {
		NBList(.localized("App Icon")) {
			Section {
				VStack(spacing: 16) {
					Image(systemName: "app.dashed")
						.font(.system(size: 60))
						.foregroundColor(.secondary)
					
					Text("App Icons Soon")
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundColor(.primary)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 40)
			}
		}
	}
}
