import SwiftUI
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - View
struct SourceDetailsView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@AppStorage("Feather.showNews") private var _showNews: Bool = true
	@State private var dominantColor: Color = .accentColor
	@State private var _searchText = ""
	@State private var _selectedNewsPresenting: ASRepository.News?
	@State private var _selectedRoute: SourceAppRoute?
	
	var source: AltSource
	@ObservedObject var viewModel: SourcesViewModel
	@State private var repository: ASRepository?
	
	private var filteredApps: [ASRepository.App] {
		guard let repo = repository else { return [] }
		let apps = repo.apps
		if _searchText.isEmpty {
			return apps
		}
		return apps.filter { app in
			(app.name?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
			(app.localizedDescription?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var filteredNews: [ASRepository.News] {
		guard let repo = repository, let news = repo.news else { return [] }
		if _searchText.isEmpty {
			return news
		}
		return news.filter { newsItem in
			newsItem.title.localizedCaseInsensitiveContains(_searchText) ||
			newsItem.caption.localizedCaseInsensitiveContains(_searchText)
		}
	}
	
	// MARK: Body
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				// Source Header Card
				_sourceHeader()
					.padding(.horizontal)
					.padding(.top, 8)
				
				// Search Bar
				_searchBar()
					.padding(.horizontal)
				
				// News Section - Only show if enabled in settings
				if _showNews, let news = repository?.news, !news.isEmpty {
					_newsSection(news: filteredNews.isEmpty && !_searchText.isEmpty ? [] : (filteredNews.isEmpty ? news : filteredNews))
				}
				
				// Apps Section
				if let apps = repository?.apps, !apps.isEmpty {
					_appsSection(apps: filteredApps.isEmpty && !_searchText.isEmpty ? [] : filteredApps)
				}
			}
			.padding(.bottom, 20)
		}
		.navigationTitle("Source Details")
		.navigationBarTitleDisplayMode(.inline)
		.background(
			ZStack {
				LinearGradient(
					colors: [
						dominantColor.opacity(0.3),
						dominantColor.opacity(0.15),
						dominantColor.opacity(0.05),
						Color(UIColor.systemBackground)
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
				
				// Add radial gradient overlay for more depth
				RadialGradient(
					colors: [
						dominantColor.opacity(0.2),
						dominantColor.opacity(0.05),
						Color.clear
					],
					center: .top,
					startRadius: 50,
					endRadius: 400
				)
				.ignoresSafeArea()
			}
		)
		.onAppear {
			if let repo = viewModel.sources[source] {
				repository = repo
			}
		}
		.fullScreenCover(item: $_selectedNewsPresenting) { news in
			SourceNewsCardInfoView(new: news)
		}
		.navigationDestinationIfAvailable(item: $_selectedRoute) { route in
			SourceAppsDetailView(source: route.source, app: route.app)
		}
	}
	
	// MARK: - Source Header
	@ViewBuilder
	private func _sourceHeader() -> some View {
		HStack(spacing: 16) {
			// Repository Icon
			if let iconURL = source.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} else {
						RoundedRectangle(cornerRadius: 16, style: .continuous)
							.fill(Color.gray.opacity(0.2))
					}
				}
				.frame(width: 80, height: 80)
				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				.onAppear {
					extractDominantColor(from: iconURL)
				}
			} else {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(Color.gray.opacity(0.2))
					.frame(width: 80, height: 80)
			}
			
			VStack(alignment: .leading, spacing: 6) {
				Text(source.name ?? .localized("Unknown"))
					.font(.title2)
					.fontWeight(.bold)
					.foregroundStyle(.primary)
			}
			
			Spacer()
		}
		.padding(20)
		.background(
			ZStack {
				// Base gradient with stronger colors
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.4),
								dominantColor.opacity(0.25),
								dominantColor.opacity(0.15)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				
				// Glass effect overlay
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(.ultraThinMaterial)
					.opacity(0.5)
				
				// Border gradient
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.6),
								dominantColor.opacity(0.3),
								Color.clear
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 2
					)
			}
			.shadow(color: dominantColor.opacity(0.4), radius: 20, x: 0, y: 10)
			.shadow(color: dominantColor.opacity(0.2), radius: 5, x: 0, y: 3)
		)
	}
	
	// MARK: - Search Bar
	@ViewBuilder
	private func _searchBar() -> some View {
		HStack(spacing: 12) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(dominantColor)
				.font(.body)
			
			TextField("Search \((repository?.apps ?? []).count) Apps", text: $_searchText)
				.textFieldStyle(.plain)
			
			if !_searchText.isEmpty {
				Button {
					_searchText = ""
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color(UIColor.secondarySystemBackground))
		)
	}
	
	// MARK: - News Section
	@ViewBuilder
	private func _newsSection(news: [ASRepository.News]) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("News")
					.font(.title3)
					.fontWeight(.bold)
				
				Spacer()
				
				if let fullNews = repository?.news, fullNews.count > 3 {
					NavigationLink {
						SourceNewsListView(news: fullNews, dominantColor: dominantColor)
					} label: {
						HStack(spacing: 4) {
							Text("See All")
								.font(.subheadline)
							Image(systemName: "chevron.right")
								.font(.caption)
						}
						.foregroundStyle(dominantColor)
					}
				}
			}
			.padding(.horizontal)
			
			if news.isEmpty {
				Text("No news found")
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 20)
			} else {
				ScrollView(.horizontal, showsIndicators: false) {
					LazyHStack(spacing: 12) {
						ForEach(Array(news.prefix(5)), id: \.id) { newsItem in
							Button {
								_selectedNewsPresenting = newsItem
							} label: {
								_newsCard(newsItem)
							}
						}
					}
					.padding(.horizontal)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _newsCard(_ newsItem: ASRepository.News) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Thumbnail
			if let imageURL = newsItem.imageURL {
				LazyImage(url: imageURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} else {
						Rectangle()
							.fill(Color.gray.opacity(0.2))
					}
				}
				.frame(width: 280, height: 160)
				.clipped()
			} else {
				Rectangle()
					.fill(dominantColor.opacity(0.2))
					.frame(width: 280, height: 160)
			}
			
			// Content
			VStack(alignment: .leading, spacing: 8) {
				Text(newsItem.title)
					.font(.headline)
					.foregroundStyle(.primary)
					.lineLimit(2)
				
				Text(newsItem.caption)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(2)
			}
			.padding(12)
			.frame(width: 280, alignment: .leading)
		}
		.background(Color(UIColor.secondarySystemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
		.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
	}
	
	// MARK: - Apps Section
	@ViewBuilder
	private func _appsSection(apps: [ASRepository.App]) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("Recently Updated")
					.font(.title3)
					.fontWeight(.bold)
				
				Spacer()
				
				if let fullApps = repository?.apps, fullApps.count > 10 {
					NavigationLink {
						if let repo = repository {
							SourceAppsListView(repository: repo, dominantColor: dominantColor)
						}
					} label: {
						HStack(spacing: 4) {
							Text("See All")
								.font(.subheadline)
							Image(systemName: "chevron.right")
								.font(.caption)
						}
						.foregroundStyle(dominantColor)
					}
				}
			}
			.padding(.horizontal)
			
			if apps.isEmpty {
				// Modern empty state
				VStack(spacing: 16) {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [dominantColor.opacity(0.2), dominantColor.opacity(0.1)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 80, height: 80)
						
						Image(systemName: "app.badge.questionmark")
							.font(.system(size: 36, weight: .medium))
							.foregroundStyle(
								LinearGradient(
									colors: [dominantColor, dominantColor.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					}
					.shadow(color: dominantColor.opacity(0.3), radius: 10, x: 0, y: 5)
					
					VStack(spacing: 8) {
						Text("No Apps Found")
							.font(.title3)
							.fontWeight(.bold)
							.foregroundStyle(.primary)
						
						Text(_searchText.isEmpty ? "This source doesn't have any apps yet" : "Try adjusting your search terms")
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 40)
				.padding(.horizontal, 20)
			} else {
				// Get the 10 most recently updated apps
				let recentApps = apps.sorted { app1, app2 in
					let date1 = app1.currentDate?.date ?? .distantPast
					let date2 = app2.currentDate?.date ?? .distantPast
					return date1 > date2
				}.prefix(10)
				
				VStack(spacing: 0) {
					ForEach(Array(recentApps.enumerated()), id: \.element.id) { index, app in
						Button {
							if let repo = repository {
								_selectedRoute = SourceAppRoute(source: repo, app: app)
							}
						} label: {
							_appRow(app)
						}
						.buttonStyle(.plain)
						
						if index < recentApps.count - 1 {
							Divider()
								.padding(.leading, 76)
						}
					}
				}
				.padding(.horizontal)
			}
		}
	}
	
	@ViewBuilder
	private func _appRow(_ app: ASRepository.App) -> some View {
		HStack(spacing: 12) {
			// App Icon
			if let iconURL = app.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} else {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(Color.gray.opacity(0.2))
					}
				}
				.frame(width: 52, height: 52)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			} else {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(Color.gray.opacity(0.2))
					.frame(width: 52, height: 52)
			}
			
			VStack(alignment: .leading, spacing: 4) {
				Text(app.name ?? "Unknown")
					.font(.body)
					.fontWeight(.medium)
					.foregroundStyle(.primary)
				
				if let subtitle = app.subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			
			Spacer()
			
			Image(systemName: "chevron.right")
				.font(.caption)
				.foregroundStyle(.tertiary)
		}
		.padding(.vertical, 8)
	}
	
	// MARK: - Color Extraction
	private func extractDominantColor(from url: URL) {
		Task {
			guard let data = try? Data(contentsOf: url),
				  let uiImage = UIImage(data: data),
				  let cgImage = uiImage.cgImage else { return }
			
			let ciImage = CIImage(cgImage: cgImage)
			let filter = CIFilter(name: "CIAreaAverage")
			filter?.setValue(ciImage, forKey: kCIInputImageKey)
			filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
			
			guard let outputImage = filter?.outputImage else { return }
			
			var pixel = [UInt8](repeating: 0, count: 4)
			CIContext().render(
				outputImage,
				toBitmap: &pixel,
				rowBytes: 4,
				bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
				format: .RGBA8,
				colorSpace: nil
			)
			
			let r = Double(pixel[0]) / 255.0
			let g = Double(pixel[1]) / 255.0
			let b = Double(pixel[2]) / 255.0
			
			await MainActor.run {
				dominantColor = Color(red: r, green: g, blue: b)
			}
		}
	}
	
	struct SourceAppRoute: Identifiable, Hashable {
		let source: ASRepository
		let app: ASRepository.App
		let id: String = UUID().uuidString
	}
}

// MARK: - News List View
struct SourceNewsListView: View {
	let news: [ASRepository.News]
	let dominantColor: Color
	@State private var _selectedNewsPresenting: ASRepository.News?
	
	var body: some View {
		NBList("News") {
			ForEach(news, id: \.id) { newsItem in
				Button {
					_selectedNewsPresenting = newsItem
				} label: {
					HStack(spacing: 12) {
						if let imageURL = newsItem.imageURL {
							LazyImage(url: imageURL) { state in
								if let image = state.image {
									image
										.resizable()
										.aspectRatio(contentMode: .fill)
								} else {
									Rectangle()
										.fill(Color.gray.opacity(0.2))
								}
							}
							.frame(width: 60, height: 60)
							.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text(newsItem.title)
								.font(.headline)
								.foregroundStyle(.primary)
							
							Text(newsItem.caption)
								.font(.caption)
								.foregroundStyle(.secondary)
								.lineLimit(2)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
				}
				.buttonStyle(.plain)
			}
		}
		.fullScreenCover(item: $_selectedNewsPresenting) { news in
			SourceNewsCardInfoView(new: news)
		}
	}
}

// MARK: - Apps List View
struct SourceAppsListView: View {
	let repository: ASRepository
	let dominantColor: Color
	@State private var _selectedRoute: SourceAppRoute?
	
	var body: some View {
		NBList("Apps") {
			ForEach(repository.apps, id: \.id) { app in
				Button {
					_selectedRoute = SourceAppRoute(source: repository, app: app)
				} label: {
					HStack(spacing: 12) {
						if let iconURL = app.iconURL {
							LazyImage(url: iconURL) { state in
								if let image = state.image {
									image
										.resizable()
										.aspectRatio(contentMode: .fill)
								} else {
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.fill(Color.gray.opacity(0.2))
								}
							}
							.frame(width: 52, height: 52)
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text(app.name ?? "Unknown")
								.font(.body)
								.fontWeight(.medium)
								.foregroundStyle(.primary)
							
							if let subtitle = app.subtitle {
								Text(subtitle)
									.font(.caption)
									.foregroundStyle(.secondary)
									.lineLimit(1)
							}
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
				}
				.buttonStyle(.plain)
			}
		}
		.navigationDestinationIfAvailable(item: $_selectedRoute) { route in
			SourceAppsDetailView(source: route.source, app: route.app)
		}
	}
	
	struct SourceAppRoute: Identifiable, Hashable {
		let source: ASRepository
		let app: ASRepository.App
		let id: String = UUID().uuidString
	}
}
