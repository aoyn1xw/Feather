import SwiftUI
import AltSourceKit
import NimbleViews
import CoreData

// MARK: - View
struct EditSourcesView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var editMode: EditMode = .active
	@State private var sourceToDelete: AltSource?
	@State private var showDeleteAlert = false
	
	var sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NavigationView {
			NBList(.localized("Edit Sources")) {
				ForEach(Array(sources), id: \.objectID) { source in
					sourceRow(source)
				}
				.onDelete(perform: deleteSource)
				.onMove(perform: moveSource)
				
				if sources.isEmpty {
					emptyStateView
				}
			}
			.environment(\.editMode, $editMode)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						dismiss()
					} label: {
						Text(.localized("Done"))
							.fontWeight(.semibold)
					}
				}
			}
			.alert(.localized("Delete Source"), isPresented: $showDeleteAlert) {
				Button(.localized("Cancel"), role: .cancel) {}
				Button(.localized("Delete"), role: .destructive) {
					if let source = sourceToDelete {
						Storage.shared.deleteSource(for: source)
					}
				}
			} message: {
				Text(.localized("Are you sure you want to delete this source? This action cannot be undone."))
			}
		}
	}
	
	// MARK: - Source Row
	@ViewBuilder
	private func sourceRow(_ source: AltSource) -> some View {
		HStack(spacing: 12) {
			// Icon
			if let iconURL = source.iconURL {
				AsyncImage(url: iconURL) { phase in
					switch phase {
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					case .empty, .failure:
						placeholderIcon
					@unknown default:
						placeholderIcon
					}
				}
				.frame(width: 50, height: 50)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			} else {
				placeholderIcon
			}
			
			// Name and URL
			VStack(alignment: .leading, spacing: 4) {
				Text(source.name ?? .localized("Unknown"))
					.font(.headline)
					.foregroundStyle(.primary)
				
				if let url = source.sourceURL?.absoluteString {
					Text(url)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			
			Spacer()
		}
	}
	
	private var placeholderIcon: some View {
		RoundedRectangle(cornerRadius: 12, style: .continuous)
			.fill(Color.gray.opacity(0.2))
			.frame(width: 50, height: 50)
			.overlay(
				Image(systemName: "globe")
					.foregroundStyle(.secondary)
			)
	}
	
	// MARK: - Empty State
	@ViewBuilder
	private var emptyStateView: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				ConditionalLabel(title: .localized("No Sources"), systemImage: "globe.desk.fill")
			} description: {
				Text(.localized("Add sources from the home screen to get started."))
			}
		} else {
			VStack(spacing: 12) {
				Image(systemName: "globe.desk.fill")
					.font(.system(size: 48))
					.foregroundStyle(.secondary)
				Text(.localized("No Sources"))
					.font(.headline)
				Text(.localized("Add sources from the home screen to get started."))
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
			.padding()
		}
	}
	
	// MARK: - Actions
	private func deleteSource(at offsets: IndexSet) {
		// Only handle single deletion - for multiple items, show alert for first one
		guard let firstIndex = offsets.first else { return }
		let source = sources[firstIndex]
		sourceToDelete = source
		showDeleteAlert = true
	}
	
	private func moveSource(from source: IndexSet, to destination: Int) {
		var sourcesArray = Array(sources)
		sourcesArray.move(fromOffsets: source, toOffset: destination)
		Storage.shared.reorderSources(sourcesArray)
	}
}
