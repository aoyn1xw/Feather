import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Extension: View (Enil)
extension SourceAppsView {
	enum SortOption: String, CaseIterable {
		case `default` = "default"
		case name
		case date
		
		var displayName: String {
			switch self {
			case .default:  .localized("Default")
			case .name: 	.localized("Name")
			case .date: 	.localized("Date")
			}
		}
	}
}

// MARK: - View
struct SourceAppsView: View {
	@AppStorage("Feather.sortOptionRawValue") private var _sortOptionRawValue: String = SortOption.default.rawValue
	@AppStorage("Feather.sortAscending") private var _sortAscending: Bool = true
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	
	@State private var _sortOption: SortOption = .default
	@State private var _selectedRoute: SourceAppRoute?
	
	@State var isLoading = true
	@State var hasLoadedOnce = false
	@State private var _searchText = ""

	private var _navigationTitle: String {
		if object.count == 1 {
			object[0].name ?? .localized("Unknown")
		} else {
			.localized("%lld Sources", arguments: object.count)
		}
	}
	
	var object: [AltSource]
	@ObservedObject var viewModel: SourcesViewModel
	@State private var _sources: [ASRepository]?
	
	// Computed property for all apps with their sources
	private var _allAppsWithSource: [(source: ASRepository, app: ASRepository.App)] {
		guard let sources = _sources else { return [] }
		return sources.flatMap { source in 
			source.apps.map { (source: source, app: $0) }
		}
	}
	
	// Filtered and sorted apps
	private var _filteredApps: [(source: ASRepository, app: ASRepository.App)] {
		let filtered = _allAppsWithSource.filter { entry in
			_searchText.isEmpty ||
			(entry.app.name?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.description?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.subtitle?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.localizedDescription?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
		
		let sorted: [(source: ASRepository, app: ASRepository.App)]
		switch _sortOption {
		case .default:
			sorted = _sortAscending ? filtered : filtered.reversed()
		case .date:
			sorted = filtered.sorted {
				let d1 = $0.app.currentDate?.date ?? .distantPast
				let d2 = $1.app.currentDate?.date ?? .distantPast
				return _sortAscending ? (d1 < d2) : (d1 > d2)
			}
		case .name:
			sorted = filtered.sorted {
				let n1 = $0.app.name ?? ""
				let n2 = $1.app.name ?? ""
				let comparison = n1.localizedCaseInsensitiveCompare(n2) == .orderedAscending
				return _sortAscending ? comparison : !comparison
			}
		}
		
		return sorted
	}
	
	private var _totalAppCount: Int {
		_allAppsWithSource.count
	}
	
	// MARK: Body
	var body: some View {
		ZStack {
			if
				let _sources,
				!_sources.isEmpty
			{
				ScrollView {
					LazyVStack(spacing: 12) {
						ForEach(_filteredApps, id: \.app.currentUniqueId) { entry in
							SourceAppCardView(
								source: entry.source,
								app: entry.app,
								useGradients: _useGradients
							)
							.onTapGesture {
								_selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
							}
						}
					}
					.padding(.horizontal, 16)
					.padding(.vertical, 12)
				}
			} else {
				ProgressView()
			}
		}
		.navigationTitle(_navigationTitle)
		.searchable(
			text: $_searchText,
			placement: .navigationBarDrawer(displayMode: .always),
			prompt: _totalAppCount > 0 ? Text("Search \(_totalAppCount) Apps") : Text("Search Apps")
		)
		.toolbarTitleMenu {
			if
				let _sources,
				_sources.count == 1
			{
				if let url = _sources[0].website {
					Button(.localized("Visit Website"), systemImage: "globe") {
						UIApplication.open(url)
					}
				}
				
				if let url = _sources[0].patreonURL {
					Button(.localized("Visit Patreon"), systemImage: "dollarsign.circle") {
						UIApplication.open(url)
					}
				}
			}
			
			Divider()
			
			Button(.localized("Copy"), systemImage: "doc.on.doc") {
				guard !object.isEmpty else {
					UIAlertController.showAlertWithOk(
						title: .localized("Error"),
						message: .localized("No sources to copy")
					)
					return
				}
				UIPasteboard.general.string = object.map {
					$0.sourceURL!.absoluteString
				}.joined(separator: "\n")
				UIAlertController.showAlertWithOk(
					title: .localized("Success"),
					message: .localized("Sources copied to clipboard")
				)
			}
		}
		.toolbar {
			NBToolbarMenu(
				systemImage: "line.3.horizontal.decrease",
				style: .icon,
				placement: .topBarTrailing
			) {
				_sortActions()
			}
		}
		.onAppear {
			if !hasLoadedOnce, viewModel.isFinished {
				_load()
				hasLoadedOnce = true
			}
			_sortOption = SortOption(rawValue: _sortOptionRawValue) ?? .default
		}
		.onChange(of: viewModel.isFinished) { _ in
			_load()
		}
		.onChange(of: _sortOption) { newValue in
			_sortOptionRawValue = newValue.rawValue
		}
		.navigationDestinationIfAvailable(item: $_selectedRoute) { route in
			SourceAppsDetailView(source: route.source, app: route.app)
		}
	}
	
	private func _load() {
		isLoading = true
		
		Task {
			let loadedSources = object.compactMap { viewModel.sources[$0] }
			_sources = loadedSources
			withAnimation(.easeIn(duration: 0.2)) {
				isLoading = false
			}
		}
	}
	
	struct SourceAppRoute: Identifiable, Hashable {
		let source: ASRepository
		let app: ASRepository.App
		let id: String = UUID().uuidString
	}
}

// MARK: - Extension: View (Sort)
extension SourceAppsView {
	@ViewBuilder
	private func _sortActions() -> some View {
		Section(.localized("Filter by")) {
			ForEach(SortOption.allCases, id: \.displayName) { opt in
				_sortButton(for: opt)
			}
		}
	}
	
	private func _sortButton(for option: SortOption) -> some View {
		Button {
			if _sortOption == option {
				_sortAscending.toggle()
			} else {
				_sortOption = option
				_sortAscending = true
			}
		} label: {
			HStack {
				Text(option.displayName)
				Spacer()
				if _sortOption == option {
					Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
				}
			}
		}
	}
}

extension View {
	@ViewBuilder
	func navigationDestinationIfAvailable<Item: Identifiable & Hashable, Destination: View>(
		item: Binding<Item?>,
		@ViewBuilder destination: @escaping (Item) -> Destination
	) -> some View {
		if #available(iOS 17, *) {
			self.navigationDestination(item: item, destination: destination)
		} else {
			self
		}
	}
}

// MARK: - SourceAppCardView
struct SourceAppCardView: View {
	let source: ASRepository
	let app: ASRepository.App
	let useGradients: Bool
	
	@State private var isPressed = false
	
	var body: some View {
		HStack(spacing: 14) {
			// App Icon
			appIcon
			
			// App Info
			VStack(alignment: .leading, spacing: 4) {
				Text(app.currentName)
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				if let version = app.currentVersion {
					Text("v\(version)")
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
				
				if let desc = app.currentDescription ?? app.localizedDescription {
					Text(desc)
						.font(.system(size: 12))
						.foregroundStyle(.secondary)
						.lineLimit(2)
				}
			}
			
			Spacer(minLength: 8)
			
			// Chevron
			Image(systemName: "chevron.right")
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(.tertiary)
		}
		.padding(14)
		.background(cardBackground)
		.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
		.overlay(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.strokeBorder(
					Color.primary.opacity(0.08),
					lineWidth: 1
				)
		)
		.shadow(
			color: Color.black.opacity(useGradients ? 0.08 : 0.04),
			radius: useGradients ? 8 : 4,
			x: 0,
			y: useGradients ? 4 : 2
		)
		.scaleEffect(isPressed ? 0.97 : 1.0)
		.animation(.easeInOut(duration: 0.15), value: isPressed)
		.simultaneousGesture(
			DragGesture(minimumDistance: 0)
				.onChanged { _ in isPressed = true }
				.onEnded { _ in isPressed = false }
		)
	}
	
	@ViewBuilder
	private var appIcon: some View {
		if let iconURL = app.iconURL {
			AsyncImage(url: iconURL) { phase in
				switch phase {
				case .empty:
					iconPlaceholder
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 56, height: 56)
						.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						.overlay(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
						)
				case .failure:
					iconPlaceholder
				@unknown default:
					iconPlaceholder
				}
			}
		} else {
			iconPlaceholder
		}
	}
	
	private var iconPlaceholder: some View {
		RoundedRectangle(cornerRadius: 12, style: .continuous)
			.fill(Color.secondary.opacity(0.2))
			.frame(width: 56, height: 56)
			.overlay(
				Image(systemName: "app.fill")
					.foregroundStyle(.secondary)
			)
	}
	
	@ViewBuilder
	private var cardBackground: some View {
		if useGradients {
			// Subtle gradient background
			ZStack {
				Color(uiColor: .secondarySystemGroupedBackground)
				
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.03),
						Color.clear
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			}
		} else {
			// Flat color background
			Color(uiColor: .secondarySystemGroupedBackground)
		}
	}
}
