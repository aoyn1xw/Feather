import SwiftUI
import AltSourceKit
import NukeUI
import NimbleViews

// MARK: - View
struct SourceNewsCardInfoView: View {
	var new: ASRepository.News
	
	// MARK: Body
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					// Modern image header
					ZStack(alignment: .bottomLeading) {
						let placeholderView = {
							LinearGradient(
								colors: [
									Color.accentColor.opacity(0.3),
									Color.accentColor.opacity(0.1)
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						}()
						
						if let iconURL = new.imageURL {
							LazyImage(url: iconURL) { state in
								if let image = state.image {
									Color.clear.overlay(
									image
										.resizable()
										.aspectRatio(contentMode: .fill)
									)
								} else {
									placeholderView
								}
							}
						} else {
							placeholderView
						}
					}
					.frame(height: 260)
					.frame(maxWidth: .infinity)
					.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
					.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
					
					// Content section
					VStack(alignment: .leading, spacing: 16) {
						// Title
						Text(new.title)
							.font(.system(size: 28, weight: .bold))
							.foregroundStyle(.primary)
							.multilineTextAlignment(.leading)
						
						// Date
						if let date = new.date?.date {
							HStack(spacing: 6) {
								Image(systemName: "calendar")
									.font(.caption)
									.foregroundStyle(.secondary)
								Text(date.formatted(date: .long, time: .omitted))
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
							.padding(.vertical, 6)
							.padding(.horizontal, 12)
							.background(
								Capsule()
									.fill(Color.secondary.opacity(0.15))
							)
						}
						
						// Caption
						if !new.caption.isEmpty {
							Text(new.caption)
								.font(.body)
								.foregroundStyle(.primary)
								.multilineTextAlignment(.leading)
								.lineSpacing(4)
						}
						
						// Open button
						if let url = new.url {
							Button {
								UIApplication.shared.open(url)
							} label: {
								HStack {
									Text(.localized("Read More"))
										.font(.system(size: 16, weight: .semibold))
									Image(systemName: "arrow.up.right")
										.font(.system(size: 14, weight: .semibold))
								}
								.foregroundStyle(.white)
								.padding(.horizontal, 24)
								.padding(.vertical, 14)
								.background(
									Capsule()
										.fill(Color.accentColor)
								)
								.shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
							}
							.buttonStyle(.plain)
							.padding(.top, 8)
						}
					}
				}
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					minHeight: 0,
					maxHeight: .infinity,
					alignment: .topLeading
				)
				.padding()
			}
			.background(Color(uiColor: .systemBackground))
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
	}
}
