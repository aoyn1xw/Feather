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
			List {
				ForEach(Array(sources.enumerated()), id: \.element.objectID) { index, source in
					HStack(spacing: 12) {
						// Icon
						if let iconURL = source.iconURL {
							AsyncImage(url: iconURL) { image in
								image
									.resizable()
									.aspectRatio(contentMode: .fill)
							} placeholder: {
								RoundedRectangle(cornerRadius: 12, style: .continuous)
									.fill(Color.gray.opacity(0.2))
							}
							.frame(width: 50, height: 50)
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						} else {
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(Color.gray.opacity(0.2))
								.frame(width: 50, height: 50)
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
				.onDelete(perform: deleteSource)
				.onMove(perform: moveSource)
			}
			.navigationTitle(.localized("Edit Sources"))
			.navigationBarTitleDisplayMode(.inline)
			.environment(\.editMode, $editMode)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
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
	
	// MARK: - Actions
	private func deleteSource(at offsets: IndexSet) {
		for index in offsets {
			let source = sources[index]
			sourceToDelete = source
			showDeleteAlert = true
		}
	}
	
	private func moveSource(from source: IndexSet, to destination: Int) {
		// Note: SwiftUI's List with CoreData FetchedResults doesn't support reordering out of the box
		// without modifying the Core Data model to include an order attribute.
		// For now, we'll keep this method as a placeholder.
		// A full implementation would require adding an "order" property to the AltSource entity.
	}
}
