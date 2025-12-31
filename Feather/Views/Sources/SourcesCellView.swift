import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var dominantColor: Color = .accentColor
	
	var source: AltSource
	
	// MARK: Body
	var body: some View {
		let isPinned = viewModel.isPinned(source)
		
		HStack(spacing: 16) {
			// Centered layout with enhanced gradients
			Spacer()
			
			VStack(spacing: 12) {
				FRIconCellView(
					title: source.name ?? .localized("Unknown"),
					subtitle: source.sourceURL?.absoluteString ?? "",
					iconUrl: source.iconURL,
					onColorExtracted: { color in
						dominantColor = color
					}
				)
				
				if isPinned {
					HStack(spacing: 6) {
						Image(systemName: "pin.fill")
							.font(.caption2)
							.foregroundStyle(.white)
						Text("Pinned")
							.font(.caption2)
							.fontWeight(.semibold)
							.foregroundStyle(.white)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 4)
					.background(
						Capsule()
							.fill(
								LinearGradient(
									colors: [Color.orange, Color.orange.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
					)
					.shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
				}
			}
			
			Spacer()
		}
		.padding(16)
		.background(
			ZStack {
				// Stronger gradient background
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.3),
								dominantColor.opacity(0.15),
								dominantColor.opacity(0.05)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				
				// Glass morphism effect
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(.ultraThinMaterial)
					.opacity(0.3)
				
				// Enhanced border
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.5),
								dominantColor.opacity(0.2),
								Color.clear
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 1.5
					)
			}
			.shadow(color: dominantColor.opacity(0.3), radius: 12, x: 0, y: 6)
			.shadow(color: dominantColor.opacity(0.15), radius: 4, x: 0, y: 2)
		)
		.swipeActions(edge: .leading) {
			Button {
				viewModel.togglePin(for: source)
			} label: {
				Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
			}
			.tint(.orange)
		}
		.swipeActions(edge: .trailing) {
			_actions(for: source)
			_contextActions(for: source)
		}
		.contextMenu {
			Button {
				viewModel.togglePin(for: source)
			} label: {
				Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
			}
			
			_contextActions(for: source)
			Divider()
			_actions(for: source)
		}
	}
}

// MARK: - Extension: View
extension SourcesCellView {
	@ViewBuilder
	private func _actions(for source: AltSource) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteSource(for: source)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for source: AltSource) -> some View {
		Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = source.sourceURL?.absoluteString
		}
	}
}
