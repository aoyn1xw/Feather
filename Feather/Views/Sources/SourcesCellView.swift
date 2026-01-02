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
		
		HStack(spacing: 12) {
			// Icon and content
			FRIconCellView(
				title: source.name ?? .localized("Unknown"),
				subtitle: source.sourceURL?.absoluteString ?? "",
				iconUrl: source.iconURL,
				onColorExtracted: { color in
					dominantColor = color
				}
			)
			
			Spacer()
			
			if isPinned {
				HStack(spacing: 4) {
					Image(systemName: "pin.fill")
						.font(.caption2)
						.foregroundStyle(dominantColor)
					Text("Pinned")
						.font(.caption2)
						.fontWeight(.semibold)
						.foregroundStyle(dominantColor)
				}
				.padding(.horizontal, 10)
				.padding(.vertical, 4)
				.background(
					Capsule()
						.fill(dominantColor.opacity(0.12))
				)
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
		)
		.swipeActions(edge: .leading) {
			Button {
				viewModel.togglePin(for: source)
			} label: {
				Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
			}
			.tint(dominantColor)
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
