import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog

// MARK: - View
struct SourcesAddView: View {
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	@Environment(\.dismiss) var dismiss

	private let _dataService = NBFetchService()
	
	@State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
	private func _refreshFilteredRecommendedSourcesData() {
		let filtered = recommendedSourcesData
			.filter { (url, data) in
				let id = data.id ?? url.absoluteString
				return !Storage.shared.sourceExists(id)
			}
			.sorted { lhs, rhs in
				let lhsName = lhs.data.name ?? ""
				let rhsName = rhs.data.name ?? ""
				return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
			}
		_filteredRecommendedSourcesData = filtered
	}
	
	@State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
	let recommendedSources: [URL] = [
		"https://raw.githubusercontent.com/khcrysalis/Feather/refs/heads/main/app-repo.json",
		"https://raw.githubusercontent.com/Aidoku/Aidoku/altstore/apps.json",
		"https://flyinghead.github.io/flycast-builds/altstore.json",
		"https://xitrix.github.io/iTorrent/AltStore.json",
		"https://altstore.oatmealdome.me/",
		"https://raw.githubusercontent.com/LiveContainer/LiveContainer/refs/heads/main/apps.json",
		"https://alt.crystall1ne.dev/",
		"https://pokemmo.com/altstore/",
		"https://provenance-emu.com/apps.json",
		"https://community-apps.sidestore.io/sidecommunity.json",
		"https://alt.getutm.app"
	].map { URL(string: $0)! }
	
	@State private var _isImporting = false
	@State private var _sourceURL = ""
	@State private var _isFetchingRecommended = true
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Add Source"), displayMode: .inline) {
			Form {
				NBSection(.localized("Source URL")) {
					HStack(spacing: 12) {
						Image(systemName: "link.circle.fill")
							.font(.title2)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						
						TextField(.localized("Enter Source URL"), text: $_sourceURL)
							.keyboardType(.URL)
							.textInputAutocapitalization(.never)
							.font(.body)
					}
					.padding(.vertical, 6)
				} footer: {
					VStack(alignment: .leading, spacing: 8) {
						Text(.localized("The only supported repositories are AltStore repositories."))
						Text(verbatim: "[\(String.localized("Learn more about how to setup a repository..."))](https://faq.altstore.io/developers/make-a-source)")
					}
				}
				
				Section {
					Button {
						_isImporting = true
						_fetchImportedRepositories(UIPasteboard.general.string) {
							dismiss()
						}
					} label: {
						HStack(spacing: 16) {
							ZStack {
								Circle()
									.fill(Color.blue.opacity(0.15))
									.frame(width: 44, height: 44)
									.blur(radius: 2)
									.offset(y: 2)
								
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.blue, Color.blue.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 44, height: 44)
								
								Image(systemName: "square.and.arrow.down")
									.font(.title3)
									.foregroundStyle(.white)
							}
							.shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
							
							Text(.localized("Import"))
								.fontWeight(.semibold)
								.foregroundStyle(.primary)
							Spacer()
							Image(systemName: "chevron.right")
								.font(.caption)
								.foregroundStyle(.tertiary)
						}
						.padding(.vertical, 4)
					}
					
				Button {
					let sources = Storage.shared.getSources()
					guard !sources.isEmpty else {
						UIAlertController.showAlertWithOk(
							title: .localized("Error"),
							message: .localized("No sources to export")
						)
						return
					}
					UIPasteboard.general.string = sources.map {
						$0.sourceURL!.absoluteString
					}.joined(separator: "\n")
					UIAlertController.showAlertWithOk(
						title: .localized("Success"),
						message: .localized("Sources copied to clipboard")
					) {
						dismiss()
					}
				} label: {
					HStack(spacing: 16) {
						// Enhanced icon with glass effect
						ZStack {
							Circle()
								.fill(Color.green.opacity(0.15))
								.frame(width: 44, height: 44)
								.blur(radius: 2)
								.offset(y: 2)
							
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.green, Color.green.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
							
							Image(systemName: "doc.on.doc")
								.font(.title3)
								.foregroundStyle(.white)
						}
						.shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
						
						Text(.localized("Export"))
							.fontWeight(.semibold)
							.foregroundStyle(.primary)
						Spacer()
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
					.padding(.vertical, 4)
				}
				} footer: {
					Text(.localized("Supports importing from KravaShit/MapleSign and ESign."))
				}
				
				if _isFetchingRecommended {
					NBSection(.localized("Featured")) {
						HStack {
							Spacer()
							VStack(spacing: 12) {
								ProgressView()
									.scaleEffect(1.2)
								Text(.localized("Loading featured sources..."))
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
							.padding(.vertical, 20)
							Spacer()
						}
					}
				} else if !_filteredRecommendedSourcesData.isEmpty {
					NBSection(.localized("Featured")) {
						ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
							HStack(spacing: 16) {
								FRIconCellView(
									title: source.name ?? .localized("Unknown"),
									subtitle: url.absoluteString,
									iconUrl: source.currentIconURL
								)
								
								Spacer()
								
								Button {
									Storage.shared.addSource(url, repository: source) { _ in
										_refreshFilteredRecommendedSourcesData()
									}
								} label: {
									Text(.localized("Add"))
										.font(.subheadline.bold())
										.foregroundStyle(.white)
										.padding(.horizontal, 24)
										.padding(.vertical, 10)
										.background(
											ZStack {
												// Shadow layer
												Capsule()
													.fill(Color.accentColor.opacity(0.3))
													.blur(radius: 4)
													.offset(y: 3)
												
												// Main gradient
												Capsule()
													.fill(
														LinearGradient(
															colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
															startPoint: .topLeading,
															endPoint: .bottomTrailing
														)
													)
											}
										)
										.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
								}
								.buttonStyle(.borderless)
							}
							.padding(.vertical, 4)
						}
					} footer: {
						Text(.localized("Open an [issue](https://github.com/khcrysalis/Feather/issues) on GitHub if you want your source to be featured."))
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				if !_isImporting {
					NBToolbarButton(
						.localized("Save"),
						style: .text,
						placement: .confirmationAction,
						isDisabled: _sourceURL.isEmpty
					) {
						FR.handleSource(_sourceURL) {
							dismiss()
						}
					}
				} else {
					ToolbarItem(placement: .confirmationAction) {
						ProgressView()
					}
				}
			}
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
		}
	}
	
	private func _fetchRecommendedRepositories() async {
		await MainActor.run { _isFetchingRecommended = true }
		let fetched = await _concurrentFetchRepositories(from: recommendedSources)
		await MainActor.run {
			withAnimation {
				recommendedSourcesData = fetched
				_refreshFilteredRecommendedSourcesData()
				_isFetchingRecommended = false
			}
		}
	}
	
	private func _fetchImportedRepositories(
		_ code: String?,
		competion: @escaping () -> Void
	) {
		guard let code else { return }
		
		let handler = ASDeobfuscator(with: code)
		let repoUrls = handler.decode().compactMap { URL(string: $0) }
		guard !repoUrls.isEmpty else { return }
		
		Task {
			let fetched = await _concurrentFetchRepositories(from: repoUrls)
			
			let dict = Dictionary(fetched, uniquingKeysWith: { first, _ in first })

			await MainActor.run {
				Storage.shared.addSources(repos: dict) { _ in
					competion()
				}
			}
		}
	}
	
	private func _concurrentFetchRepositories(
		from urls: [URL]
	) async -> [(url: URL, data: ASRepository)] {
		var results: [(url: URL, data: ASRepository)] = []
		
		let dataService = _dataService
		
		await withTaskGroup(of: Void.self) { group in
			for url in urls {
				group.addTask {
					await withCheckedContinuation { continuation in
						dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
							switch result {
							case .success(let repo):
								Task { @MainActor in
									results.append((url: url, data: repo))
								}
							case .failure(let error):
								Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
							}
							continuation.resume()
						}
					}
				}
			}
			await group.waitForAll()
		}
		
		return results
	}

}
