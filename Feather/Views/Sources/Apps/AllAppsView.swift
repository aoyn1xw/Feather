import SwiftUI
import AltSourceKit
import NimbleViews

// MARK: - All Apps View
struct AllAppsView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	
	@State private var _searchText = ""
	@State private var _showSearchSheet = false
	@State private var _selectedRoute: SourceAppRoute?
	
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
	
	// Filtered apps based on search
	private var _filteredApps: [(source: ASRepository, app: ASRepository.App)] {
		if _searchText.isEmpty {
			return _allAppsWithSource
		}
		
		return _allAppsWithSource.filter { entry in
			(entry.app.name?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.description?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.subtitle?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(entry.app.localizedDescription?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _totalAppCount: Int {
		_allAppsWithSource.count
	}
	
	// MARK: Body
	var body: some View {
		ZStack {
			// Background
			Color(uiColor: .systemBackground)
				.ignoresSafeArea()
			
			if let _sources, !_sources.isEmpty {
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						// Header with title and search button
						HStack {
							Text("All Apps")
								.font(.largeTitle)
								.fontWeight(.bold)
								.foregroundStyle(.primary)
								.frame(maxWidth: .infinity, alignment: .center)
							
							Button {
								_showSearchSheet = true
							} label: {
								ZStack {
									Circle()
										.fill(Color.primary.opacity(0.15))
										.frame(width: 40, height: 40)
									
									Image(systemName: "magnifyingglass")
										.font(.system(size: 18, weight: .semibold))
										.foregroundStyle(.primary)
								}
							}
						}
						.padding(.horizontal, 20)
						.padding(.top, 10)
						
						// Section label with count
						HStack {
							Text("Apps")
								.font(.subheadline)
								.foregroundStyle(.secondary)
							
							Spacer()
							
							Text("\(_filteredApps.count)")
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}
						.padding(.horizontal, 20)
						
						// Apps list container
						VStack(spacing: 0) {
							ForEach(Array(_filteredApps.enumerated()), id: \.element.app.currentUniqueId) { index, entry in
								AllAppsRowView(
									source: entry.source,
									app: entry.app,
									onTap: {
										_selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
									}
								)
								
								// Add separator between rows (not after last row)
								if index < _filteredApps.count - 1 {
									Divider()
										.padding(.leading, 72)
								}
							}
						}
						.padding(.horizontal, 20)
						.padding(.vertical, 12)
						.background(
							RoundedRectangle(cornerRadius: 16, style: .continuous)
								.fill(Color(uiColor: .secondarySystemGroupedBackground))
						)
						.padding(.horizontal, 20)
						
						Spacer(minLength: 20)
					}
				}
			} else {
				ProgressView()
			}
		}
		.navigationBarHidden(true)
		.sheet(isPresented: $_showSearchSheet) {
			SearchSheetView(searchText: $_searchText)
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
		}
		.onAppear {
			if viewModel.isFinished {
				_load()
			}
		}
		.onChange(of: viewModel.isFinished) { _ in
			_load()
		}
		.navigationDestinationIfAvailable(item: $_selectedRoute) { route in
			SourceAppsDetailView(source: route.source, app: route.app)
		}
	}
	
	private func _load() {
		Task {
			let loadedSources = object.compactMap { viewModel.sources[$0] }
			_sources = loadedSources
		}
	}
	
	struct SourceAppRoute: Identifiable, Hashable {
		let source: ASRepository
		let app: ASRepository.App
		let id: String = UUID().uuidString
	}
}

// MARK: - All Apps Row View
struct AllAppsRowView: View {
	let source: ASRepository
	let app: ASRepository.App
	let onTap: () -> Void
	
	@ObservedObject private var downloadManager = DownloadManager.shared
	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?
	
	private var currentDownload: Download? {
		downloadManager.getDownload(by: app.currentUniqueId)
	}
	
	private var isDownloading: Bool {
		currentDownload != nil
	}
	
	private var fileSize: String {
		if let size = app.size {
			return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
		}
		return ""
	}
	
	private var statusText: String {
		// Check if app is injected or modified based on version info or other metadata
		if app.beta ?? false {
			return "Beta"
		} else if let _ = app.developerName {
			return "Official"
		}
		return ""
	}
	
	var body: some View {
		Button(action: onTap) {
			VStack(spacing: 8) {
				HStack(spacing: 12) {
					// App Icon
					appIcon
						.frame(width: 50, height: 50)
					
					// Center column with app info
					VStack(alignment: .leading, spacing: 4) {
						// App name
						Text(app.currentName)
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(.primary)
							.lineLimit(1)
						
						// Subtitle (status)
						if !statusText.isEmpty {
							Text(statusText)
								.font(.system(size: 13))
								.foregroundStyle(.secondary)
								.lineLimit(1)
						}
						
						// Version and file size
						HStack(spacing: 6) {
							if let version = app.currentVersion {
								Text("v\(version)")
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
							}
							
							if !fileSize.isEmpty {
								Text("•")
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
								
								Text(fileSize)
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
							}
						}
					}
					
					Spacer()
					
					// Action button
					actionButton
						.frame(width: 40, height: 40)
				}
				
				// Progress bar when downloading
				if isDownloading {
					VStack(spacing: 4) {
						GeometryReader { geometry in
							ZStack(alignment: .leading) {
								// Background
								Capsule()
									.fill(Color.primary.opacity(0.1))
									.frame(height: 4)
								
								// Progress
								Capsule()
									.fill(Color.accentColor)
									.frame(width: geometry.size.width * downloadProgress, height: 4)
							}
						}
						.frame(height: 4)
						
						// Progress percentage
						HStack {
							Spacer()
							Text("\(Int(downloadProgress * 100))%")
								.font(.system(size: 11, weight: .medium))
								.foregroundStyle(.secondary)
						}
					}
					.transition(.opacity.combined(with: .scale(scale: 0.9)))
				}
			}
			.padding(.vertical, 8)
		}
		.buttonStyle(.plain)
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDownloading)
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
						.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: 22))
					.foregroundStyle(.secondary)
			)
	}
	
	@ViewBuilder
	private var actionButton: some View {
		if isDownloading {
			// Download in progress - show progress circle with cancel
			Button {
				if let download = currentDownload {
					downloadManager.cancelDownload(download)
				}
			} label: {
				ZStack {
					// Background circle
					Circle()
						.stroke(Color.primary.opacity(0.15), lineWidth: 2.5)
					
					// Progress circle
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
						.rotationEffect(.degrees(-90))
						.animation(.linear(duration: 0.2), value: downloadProgress)
					
					// Cancel icon
					Image(systemName: "xmark")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(Color.accentColor)
				}
			}
		} else {
			// Idle state - show download icon
			Button {
				if let url = app.currentDownloadUrl {
					_ = downloadManager.startDownload(from: url, id: app.currentUniqueId)
				}
			} label: {
				ZStack {
					Circle()
						.fill(Color.accentColor.opacity(0.15))
					
					Image(systemName: "arrow.down.circle.fill")
						.font(.system(size: 28))
						.foregroundStyle(Color.accentColor)
				}
			}
		}
	}
	
	private func setupObserver() {
		cancellable?.cancel()
		guard let download = currentDownload else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress
		
		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)
		
		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
}

// MARK: - Search Sheet View
struct SearchSheetView: View {
	@Binding var searchText: String
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			VStack(spacing: 16) {
				// Search bar
				HStack(spacing: 12) {
					Image(systemName: "magnifyingglass")
						.foregroundStyle(.secondary)
						.font(.system(size: 16))
					
					TextField("Search apps", text: $searchText)
						.foregroundStyle(.primary)
						.autocorrectionDisabled()
						.textInputAutocapitalization(.never)
					
					if !searchText.isEmpty {
						Button {
							searchText = ""
						} label: {
							Image(systemName: "xmark.circle.fill")
								.foregroundStyle(.secondary)
						}
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(
					Capsule()
						.fill(Color.secondary.opacity(0.15))
				)
				.padding(.horizontal, 20)
				.padding(.top, 10)
				
				Spacer()
			}
			.navigationTitle("Search")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
	}
}

// MARK: - Import Combine for Publishers
import Combine
