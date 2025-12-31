//
//  SourcesCellView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//

import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@State private var dominantColor: Color = .accentColor
	
	var source: AltSource
	
	// MARK: Body
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		
		FRIconCellView(
			title: source.name ?? .localized("Unknown"),
			subtitle: source.sourceURL?.absoluteString ?? "",
			iconUrl: source.iconURL,
			onColorExtracted: { color in
				dominantColor = color
			}
		)
		.padding(isRegular ? 16 : 0)
		.background(
			isRegular
			? RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							dominantColor.opacity(0.25),
							dominantColor.opacity(0.08)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 20, style: .continuous)
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
				.shadow(color: dominantColor.opacity(0.2), radius: 10, x: 0, y: 4)
			: nil
		)
		.swipeActions {
			_actions(for: source)
			_contextActions(for: source)
		}
		.contextMenu {
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
