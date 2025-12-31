import SwiftUI
import NimbleViews

// MARK: - View extension: Model
extension AppIconView {
	static func altImage(_ name: String?) -> UIImage {
		let path = Bundle.main.bundleURL.appendingPathComponent((name ?? "AppIcon60x60") + "@2x.png")
		return UIImage(contentsOfFile: path.path) ?? UIImage()
	}
}

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
