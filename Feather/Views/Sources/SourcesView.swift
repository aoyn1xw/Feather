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
	@State private var _showFilterSheet = false
	@State private var _sortOrder: SortOrder = .alphabetical
	@State private var _filterByPinned: FilterOption = .all
	
	enum SortOrder: String, CaseIterable {
		case alphabetical = "A-Z"
		case recentlyAdded = "Recently Added"
		case appCount = "Most Apps"
	}
	
	enum FilterOption: String, CaseIterable {
		case all = "All"
		case pinned = "Pinned Only"
		case unpinned = "Unpinned Only"
	}
	
	private var _filteredSources: [AltSource] {
		// Apply search filter
		var filtered = _sources.filter { 
			_searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) 
		}
		
		// Apply pinned filter
		switch _filterByPinned {
		case .pinned:
			filtered = filtered.filter { viewModel.isPinned($0) }
		case .unpinned:
			filtered = filtered.filter { !viewModel.isPinned($0) }
		case .all:
			break
		}
		
		// Apply sorting
		return filtered.sorted { s1, s2 in
			switch _sortOrder {
			case .alphabetical:
				let p1 = viewModel.isPinned(s1)
				let p2 = viewModel.isPinned(s2)
				if p1 && !p2 { return true }
				if !p1 && p2 { return false }
				return (s1.name ?? "") < (s2.name ?? "")
			case .recentlyAdded:
				// Assuming newer sources have later object IDs or we can use a timestamp if available
				// For now, sort by name descending as a proxy for "recently added"
				return (s1.name ?? "") > (s2.name ?? "")
			case .appCount:
				let count1 = viewModel.sources[s1]?.apps.count ?? 0
				let count2 = viewModel.sources[s2]?.apps.count ?? 0
				if count1 != count2 { return count1 > count2 }
				return (s1.name ?? "") < (s2.name ?? "")
			}
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
			contentList
				.searchable(text: $_searchText, placement: .platform())
				.overlay {
					emptyStateView
				}
				.toolbar {
					toolbarContent
				}
				.refreshable {
					await viewModel.fetchSources(_sources, refresh: true)
				}
				.sheet(isPresented: $_isAddingPresenting) {
					addSourceSheet
				}
				.sheet(isPresented: $_showFilterSheet) {
					filterSheet
				}
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
		#if !NIGHTLY && !DEBUG
		.onAppear {
			showStarPromptIfNeeded()
		}
		#endif
	}
	
	// MARK: - View Components
	
	private var contentList: some View {
		NBListAdaptable {
			if !_filteredSources.isEmpty {
				allAppsSection
				repositoriesSection
			}
		}
	}
	
	private var allAppsSection: some View {
		Section {
			NavigationLink {
				AllAppsWrapperView(object: Array(_sources), viewModel: viewModel)
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
	}
	
	private var repositoriesSection: some View {
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
	
	@ViewBuilder
	private var emptyStateView: some View {
		if _filteredSources.isEmpty {
			if #available(iOS 17, *) {
				ContentUnavailableView {
					ConditionalLabel(title: .localized("No Repositories"), systemImage: "globe.desk.fill")
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
	
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		NBToolbarButton(
			systemImage: "line.3.horizontal.decrease.circle",
			style: .icon,
			placement: .topBarLeading,
			isDisabled: false
		) {
			_showFilterSheet = true
		}
		
		NBToolbarButton(
			systemImage: "plus",
			style: .icon,
			placement: .topBarTrailing,
			isDisabled: _addingSourceLoading
		) {
			_isAddingPresenting = true
		}
	}
	
	private var addSourceSheet: some View {
		SourcesAddView()
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
	}
	
	private var filterSheet: some View {
		NavigationView {
			List {
				sortSection
				filterSection
				resetSection
			}
			.navigationTitle(.localized("Filter & Sort"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
		.presentationDetents([.medium, .large])
		.presentationDragIndicator(.visible)
	}
	
	private var sortSection: some View {
		NBSection(.localized("Sort By")) {
			ForEach(SourcesView.SortOrder.allCases, id: \.self) { (order: SourcesView.SortOrder) in
				Button {
					_sortOrder = order
				} label: {
					HStack {
						Text(order.rawValue)
							.foregroundStyle(.primary)
						Spacer()
						if _sortOrder == order {
							Image(systemName: "checkmark")
								.foregroundStyle(.tint)
						}
					}
				}
			}
		}
	}
	
	private var filterSection: some View {
		NBSection(.localized("Filter")) {
			ForEach(SourcesView.FilterOption.allCases, id: \.self) { (option: SourcesView.FilterOption) in
				Button {
					_filterByPinned = option
				} label: {
					HStack {
						Text(option.rawValue)
							.foregroundStyle(.primary)
						Spacer()
						if _filterByPinned == option {
							Image(systemName: "checkmark")
								.foregroundStyle(.tint)
						}
					}
				}
			}
		}
	}
	
	private var resetSection: some View {
		NBSection("") {
			Button {
				_sortOrder = .alphabetical
				_filterByPinned = .all
				_searchText = ""
			} label: {
				HStack {
					Spacer()
					Text(.localized("Reset All Filters"))
						.foregroundStyle(.red)
					Spacer()
				}
			}
		}
	}
	
	#if !NIGHTLY && !DEBUG
	private func showStarPromptIfNeeded() {
		guard _shouldStar < 6 else { return }
		_shouldStar += 1
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

// MARK: - AllAppsCardView
private struct AllAppsCardView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	
	let horizontalSizeClass: UserInterfaceSizeClass?
	let totalApps: Int
	
	// Get app icon for the gradient - use the system's app icon
	@State private var appIconColor: Color = .accentColor
	
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		
		VStack(spacing: 0) {
			// Content only - no gradient banner
			contentSection(isRegular: isRegular)
		}
		.background(cardBackground)
		.overlay(cardStroke)
		.shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
		.shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
		.onAppear {
			extractAppIconColor()
		}
	}
	
	// Extract color from app icon
	private func extractAppIconColor() {
		guard let iconName = Bundle.main.iconFileName,
			  let appIcon = UIImage(named: iconName) else {
			appIconColor = .accentColor
			return
		}
		
		guard let inputImage = CIImage(image: appIcon) else {
			appIconColor = .accentColor
			return
		}
		
		let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
		
		guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
			appIconColor = .accentColor
			return
		}
		guard let outputImage = filter.outputImage else {
			appIconColor = .accentColor
			return
		}
		
		var bitmap = [UInt8](repeating: 0, count: 4)
		// Use a shared context for better performance
		let context = Self.sharedCIContext
		context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
		
		appIconColor = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)
	}
	
	// Shared CIContext for performance
	private static let sharedCIContext = CIContext(options: [.workingColorSpace: kCFNull as Any])
	
	private func contentSection(isRegular: Bool) -> some View {
		HStack(spacing: 12) {
			iconView
			
			textContent
			
			Spacer()
			
			chevronIcon
		}
		.padding(.horizontal, isRegular ? 12 : 10)
		.padding(.vertical, isRegular ? 10 : 8)
	}
	
	private var iconView: some View {
		ZStack {
			Circle()
				.fill(Color.white)
				.frame(width: 40, height: 40)
				.shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
			
			Image(systemName: "app.badge.fill")
				.font(.system(size: 18))
				.foregroundStyle(appIconColor)
		}
	}
	
	private var textContent: some View {
		VStack(alignment: .leading, spacing: 3) {
			Text(.localized("All Apps"))
				.font(.headline)
				.foregroundStyle(.primary)
			Text(.localized("Browse your complete app collection"))
				.font(.caption)
				.foregroundStyle(.secondary)
			
			appsBadge
		}
	}
	
	private var appsBadge: some View {
		HStack(spacing: 4) {
			Image(systemName: "square.stack.3d.up.fill")
				.font(.system(size: 8))
			Text("\(totalApps) Apps Available")
				.font(.system(size: 9, weight: .bold))
		}
		.foregroundStyle(appIconColor)
		.padding(.horizontal, 7)
		.padding(.vertical, 3)
		.background(
			Capsule()
				.fill(appIconColor.opacity(0.05))
		)
	}
	
	private var chevronIcon: some View {
		Image(systemName: "chevron.right")
			.font(.body.bold())
			.foregroundStyle(.secondary)
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 14, style: .continuous)
			.fill(Color(uiColor: .secondarySystemGroupedBackground))
	}
	
	private var cardStroke: some View {
		RoundedRectangle(cornerRadius: 14, style: .continuous)
			.stroke(Color.primary.opacity(0.1), lineWidth: 1)
	}
}
