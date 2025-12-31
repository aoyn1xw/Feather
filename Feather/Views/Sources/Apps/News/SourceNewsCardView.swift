import SwiftUI
import AltSourceKit
import NukeUI
import NimbleViews

// MARK: - View
struct SourceNewsCardView: View {
	var new: ASRepository.News
	
	// MARK: Body
	var body: some View {
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
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 250, height: 150)
							.clipped()
					} else {
						placeholderView
					}
				}
			} else {
				placeholderView
			}
			
			LinearGradient(
				gradient: Gradient(colors: [
					.black.opacity(0.9),
					.black.opacity(0.6),
					.clear
				]),
				startPoint: .bottom,
				endPoint: .top
			)
			.frame(height: 80)
			.frame(maxWidth: .infinity, alignment: .bottom)
			.overlay(
				NBVariableBlurView()
					.rotationEffect(.degrees(180))
					.frame(height: 60)
					.frame(maxHeight: .infinity, alignment: .bottom)
			)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			
			Text(new.title)
				.font(.headline)
				.fontWeight(.semibold)
				.foregroundColor(.white)
				.lineLimit(2)
				.multilineTextAlignment(.leading)
				.padding()
		}
		.frame(width: 250, height: 150)
		.background(
			LinearGradient(
				colors: [
					(new.tintColor ?? Color.accentColor).opacity(0.8),
					(new.tintColor ?? Color.accentColor).opacity(0.4)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		)
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
		.overlay(
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.strokeBorder(
					LinearGradient(
						colors: [
							Color.white.opacity(0.3),
							Color.clear
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1.5
				)
		)
		.shadow(color: (new.tintColor ?? Color.accentColor).opacity(0.3), radius: 10, x: 0, y: 5)
	}
}

