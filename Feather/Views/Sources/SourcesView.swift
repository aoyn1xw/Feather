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
		animation: .easeInOut(duration: 0.35)
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
							AllAppsCardView(
								horizontalSizeClass: horizontalSizeClass,
								totalApps: _sources.reduce(0) { count, source in
									count + (viewModel.sources[source]?.apps.count ?? 0)
								}
							)
						}
						.buttonStyle(.plain)
					}
					.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
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

// MARK: - AllAppsCardView
private struct AllAppsCardView: View {
	let horizontalSizeClass: UserInterfaceSizeClass?
	let totalApps: Int
	
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		
		VStack(spacing: 0) {
			// Top gradient banner
			gradientBanner
			
			// Content
			contentSection(isRegular: isRegular)
		}
		.background(cardBackground)
		.overlay(cardStroke)
		.shadow(color: Color.accentColor.opacity(0.15), radius: 20, x: 0, y: 8)
		.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
	}
	
	private var gradientBanner: some View {
		ZStack(alignment: .topTrailing) {
			LinearGradient(
				colors: [
					Color.accentColor.opacity(0.9),
					Color.accentColor.opacity(0.7),
					Color.accentColor.opacity(0.5)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.frame(height: 80)
			
			// Decorative circles
			Circle()
				.fill(Color.white.opacity(0.1))
				.frame(width: 60, height: 60)
				.offset(x: 20, y: -20)
			
			Circle()
				.fill(Color.white.opacity(0.05))
				.frame(width: 90, height: 90)
				.offset(x: -30, y: 40)
		}
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
	}
	
	private func contentSection(isRegular: Bool) -> some View {
		HStack(spacing: 14) {
			iconView
			
			textContent
			
			Spacer()
			
			chevronIcon
		}
		.padding(.horizontal, isRegular ? 16 : 14)
		.padding(.bottom, isRegular ? 16 : 14)
		.padding(.top, 6)
	}
	
	private var iconView: some View {
		ZStack {
			Circle()
				.fill(Color.white)
				.frame(width: 56, height: 56)
				.shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
			
			Image(systemName: "app.badge.fill")
				.font(.system(size: 26))
				.foregroundStyle(
					LinearGradient(
						colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		}
		.offset(y: -28)
	}
	
	private var textContent: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(.localized("All Apps"))
				.font(.title3.bold())
				.foregroundStyle(.primary)
			Text(.localized("Browse your complete app collection"))
				.font(.caption)
				.foregroundStyle(.secondary)
			
			appsBadge
		}
		.padding(.top, 6)
	}
	
	private var appsBadge: some View {
		HStack(spacing: 4) {
			Image(systemName: "square.stack.3d.up.fill")
				.font(.system(size: 9))
			Text("\(totalApps) Apps Available")
				.font(.system(size: 10, weight: .bold))
		}
		.foregroundStyle(Color.accentColor)
		.padding(.horizontal, 8)
		.padding(.vertical, 3)
		.background(
			Capsule()
				.fill(Color.accentColor.opacity(0.1))
		)
	}
	
	private var chevronIcon: some View {
		Image(systemName: "chevron.right")
			.font(.body.bold())
			.foregroundStyle(.secondary)
			.padding(.top, 6)
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 16, style: .continuous)
			.fill(Color(uiColor: .secondarySystemGroupedBackground))
	}
	
	private var cardStroke: some View {
		RoundedRectangle(cornerRadius: 16, style: .continuous)
			.stroke(
				LinearGradient(
					colors: [Color.white.opacity(0.5), Color.clear],
					startPoint: .top,
					endPoint: .bottom
				),
				lineWidth: 1
			)
	}
}
