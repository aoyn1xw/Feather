import SwiftUI
import NimbleViews

// MARK: - Modern Install/Modify Dialog
struct InstallModifyDialogView: View {
	@Environment(\.dismiss) var dismiss
	let app: AppInfoPresentable
	
	@State private var showInstallPreview = false
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// Success icon and message
				VStack(spacing: 20) {
					// Animated success icon
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 100, height: 100)
						
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: 60, weight: .medium))
							.foregroundStyle(
								LinearGradient(
									colors: [Color.green, Color.green.opacity(0.8)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					}
					.shadow(color: Color.green.opacity(0.3), radius: 15, x: 0, y: 5)
					
					VStack(spacing: 8) {
						Text("App Downloaded Successfully")
							.font(.title2)
							.fontWeight(.bold)
							.foregroundStyle(.primary)
						
						Text("What would you like to do with \(app.name ?? "this app")?")
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 20)
					}
				}
				.padding(.top, 40)
				.padding(.bottom, 30)
				
				// App info card
				appInfoCard
					.padding(.horizontal, 20)
					.padding(.bottom, 30)
				
				// Action buttons
				VStack(spacing: 12) {
					// Sign & Install button
					Button {
						dismiss()
						// Trigger signing and installation
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							showInstallPreview = true
						}
					} label: {
						HStack(spacing: 10) {
							Image(systemName: "checkmark.seal.fill")
								.font(.system(size: 16, weight: .semibold))
							Text("Sign & Install")
								.font(.system(size: 17, weight: .semibold))
						}
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							LinearGradient(
								colors: [Color.green, Color.green.opacity(0.9)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
						.shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
					}
					
					// Modify button
					Button {
						dismiss()
						// Open signing view for modification
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							NotificationCenter.default.post(
								name: Notification.Name("Feather.openSigningView"),
								object: app
							)
						}
					} label: {
						HStack(spacing: 10) {
							Image(systemName: "slider.horizontal.3")
								.font(.system(size: 16, weight: .semibold))
							Text("Modify")
								.font(.system(size: 17, weight: .semibold))
						}
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
						.shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
					}
					
					// Cancel button
					Button {
						dismiss()
					} label: {
						Text("Cancel")
							.font(.system(size: 17, weight: .medium))
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 16)
							.background(
								RoundedRectangle(cornerRadius: 14, style: .continuous)
									.fill(Color(UIColor.tertiarySystemBackground))
							)
					}
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 20)
				
				Spacer()
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text("Download Complete")
						.font(.headline)
				}
			}
		}
		.sheet(isPresented: $showInstallPreview) {
			InstallPreviewView(app: app, isSharing: false, fromLibraryTab: false)
		}
	}
	
	// MARK: - App Info Card
	@ViewBuilder
	private var appInfoCard: some View {
		HStack(spacing: 12) {
			// App icon
			if let iconURL = (app as? Signed)?.iconURL ?? (app as? Imported)?.iconURL {
				AsyncImage(url: iconURL) { phase in
					switch phase {
					case .empty:
						iconPlaceholder
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 50, height: 50)
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					case .failure:
						iconPlaceholder
					@unknown default:
						iconPlaceholder
					}
				}
			} else {
				iconPlaceholder
			}
			
			// App info
			VStack(alignment: .leading, spacing: 4) {
				Text(app.name ?? "Unknown")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.primary)
				
				if let version = app.version {
					Text("Version \(version)")
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
				}
				
				if let identifier = app.identifier {
					Text(identifier)
						.font(.system(size: 11))
						.foregroundStyle(.tertiary)
						.lineLimit(1)
				}
			}
			
			Spacer()
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.stroke(Color.primary.opacity(0.1), lineWidth: 1)
		)
	}
	
	private var iconPlaceholder: some View {
		RoundedRectangle(cornerRadius: 12, style: .continuous)
			.fill(Color.secondary.opacity(0.2))
			.frame(width: 50, height: 50)
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: 22))
					.foregroundStyle(.secondary)
			)
	}
}
