import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#if !NIGHTLY && !DEBUG
	@AppStorage("Feather.shouldStar") private var _shouldStar: Int = 0
	#endif
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _searchText = ""
	
	private var _filteredSources: [AltSource] {
		let filtered = _sources.filter { _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) }
		return filtered.sorted { s1, s2 in
			let p1 = viewModel.isPinned(s1)
			let p2 = viewModel.isPinned(s2)
			if p1 && !p2 { return true }
			if !p1 && p2 { return false }
			return (s1.name ?? "") < (s2.name ?? "")
		}
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Home")) {
			NBListAdaptable {
				if !_filteredSources.isEmpty {
					Section {
						NavigationLink {
							SourceAppsView(object: Array(_sources), viewModel: viewModel)
						} label: {
							let isRegular = horizontalSizeClass != .compact
							let totalApps = _sources.reduce(0) { count, source in
								count + (viewModel.sources[source]?.apps.count ?? 0)
							}
							
							HStack(spacing: 18) {
								ZStack {
									Circle()
										.fill(
											LinearGradient(
												colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
										.frame(width: 60, height: 60)
									
									Image(systemName: "app.badge.fill")
										.font(.system(size: 28))
										.foregroundStyle(.white)
								}
								
								VStack(alignment: .leading, spacing: 4) {
									Text(.localized("All Apps"))
										.font(.headline)
										.foregroundStyle(.primary)
									Text(.localized("See all apps from your sources"))
										.font(.subheadline)
										.foregroundStyle(.secondary)
								}
								
								Spacer()
								
								Text("\(totalApps) Apps")
									.font(.subheadline)
									.fontWeight(.semibold)
									.foregroundStyle(.white)
									.padding(.horizontal, 12)
									.padding(.vertical, 6)
									.background(
										Capsule()
											.fill(
												LinearGradient(
													colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.6)],
													startPoint: .leading,
													endPoint: .trailing
												)
											)
									)
							}
							.padding(isRegular ? 16 : 12)
							.background(
								RoundedRectangle(cornerRadius: 20, style: .continuous)
									.fill(
										Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8)
									)
									.background(
										RoundedRectangle(cornerRadius: 20, style: .continuous)
											.fill(
												LinearGradient(
													colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
											)
											.blur(radius: 10)
									)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 20, style: .continuous)
									.stroke(
										LinearGradient(
											colors: [Color.white.opacity(0.3), Color.clear],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										),
										lineWidth: 1
									)
							)
							.shadow(color: Color.accentColor.opacity(0.2), radius: 15, x: 0, y: 5)
						}
						.buttonStyle(.plain)
					}
					.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
					.listRowBackground(Color.clear)
					
					NBSection(
						.localized("Repositories"),
						secondary: _filteredSources.count.description
					) {
						ForEach(_filteredSources) { source in
							NavigationLink {
								SourceDetailsView(source: source, viewModel: viewModel)
							} label: {
								SourcesCellView(source: source)
							}
							.buttonStyle(.plain)
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
			.overlay {
				if _filteredSources.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
						} description: {
							Text(.localized("Get started by adding your first repository."))
						} actions: {
							Button {
								_isAddingPresenting = true
							} label: {
								NBButton(.localized("Add Source"), style: .text)
							}
						}
					}
				}
			}
			.toolbar {
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing,
					isDisabled: _addingSourceLoading
				) {
					_isAddingPresenting = true
				}
			}
			.refreshable {
				await viewModel.fetchSources(_sources, refresh: true)
			}
			.sheet(isPresented: $_isAddingPresenting) {
				SourcesAddView()
					.presentationDetents([.medium, .large])
					.presentationDragIndicator(.visible)
			}
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
		#if !NIGHTLY && !DEBUG
		.onAppear {
			guard _shouldStar < 6 else { return }; _shouldStar += 1
			guard _shouldStar == 6 else { return }
			
			let github = UIAlertAction(title: "GitHub", style: .default) { _ in
				UIApplication.open("https://github.com/khcrysalis/Feather")
			}
			
			let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
			
			UIAlertController.showAlert(
				title: .localized("Enjoying %@?", arguments: Bundle.main.name),
				message: .localized("Go to our GitHub and give us a star!"),
				actions: [github, cancel]
			)
		}
		#endif
	}
}
