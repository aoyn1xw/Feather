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
		
		HStack {
			FRIconCellView(
				title: source.name ?? .localized("Unknown"),
				subtitle: source.sourceURL?.absoluteString ?? "",
				iconUrl: source.iconURL,
				onColorExtracted: { color in
					dominantColor = color
				}
			)
			
			if isPinned {
				Image(systemName: "pin.fill")
					.font(.caption)
					.foregroundStyle(.secondary)
					.rotationEffect(.degrees(45))
					.padding(.trailing, 8)
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 18, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							dominantColor.opacity(0.15),
							dominantColor.opacity(0.05)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 18, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [
							dominantColor.opacity(0.3),
							Color.clear
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
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
