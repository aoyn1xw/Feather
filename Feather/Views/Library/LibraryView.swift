import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	
	@StateObject var downloadManager = DownloadManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _showImportAnimation = false
	@State private var _importStatus: ImportStatus = .loading
	@State private var _importedAppName: String = ""
	
	enum ImportStatus {
		case loading
		case success
		case failed
	}
	
	@State private var _searchText = ""
	@State private var _viewMode: ViewMode = .list
	
	enum ViewMode {
		case list
		case grid
	}
	
	@Namespace private var _namespace
	
	// horror
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
			(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	private var _allApps: [AppInfoPresentable] {
		var all: [AppInfoPresentable] = []
		all.append(contentsOf: _filteredSignedApps)
		all.append(contentsOf: _filteredImportedApps)
		return all
	}
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var _importedApps: FetchedResults<Imported>
	
	// MARK: Body
	var body: some View {
		NavigationView {
			ZStack {
				// Enhanced gradient background based on signing status
				if _useGradients {
					let hasSignedApps = !_filteredSignedApps.isEmpty
					let statusColor: Color = hasSignedApps ? .green : .accentColor
					
					LinearGradient(
						colors: [
							statusColor.opacity(0.12),
							Color(uiColor: .systemBackground),
							statusColor.opacity(0.08),
							Color(uiColor: .systemBackground),
							statusColor.opacity(0.05)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
					.ignoresSafeArea()
				} else {
					Color(uiColor: .systemBackground).ignoresSafeArea()
				}
				
				ScrollView {
					VStack(alignment: .leading, spacing: 20) {
						// Header with Title and Icons
						VStack(alignment: .leading, spacing: 16) {
							HStack {
								Text("Library")
									.font(.largeTitle)
									.fontWeight(.bold)
									.foregroundStyle(.primary)
								
								Spacer()
								
								// Top right buttons
								HStack(spacing: 12) {
									// View mode toggle button
									Button {
										withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
											_viewMode = _viewMode == .list ? .grid : .list
										}
									} label: {
										ZStack {
											Circle()
												.fill(Color.primary.opacity(0.15))
												.frame(width: 40, height: 40)
											
											Image(systemName: _viewMode == .list ? "square.grid.2x2" : "list.bullet")
												.font(.system(size: 18, weight: .semibold))
												.foregroundStyle(.primary)
										}
									}
									
									// Scan/Selection button
									Menu {
										_importActions()
									} label: {
										ZStack {
											Circle()
												.fill(Color.primary.opacity(0.15))
												.frame(width: 40, height: 40)
											
											Image(systemName: "plus.square.on.square")
												.font(.system(size: 18, weight: .semibold))
												.foregroundStyle(.primary)
										}
									}
								}
							}
							.padding(.horizontal, 20)
							.padding(.top, 10)
							
							// Search Bar
							HStack(spacing: 12) {
								Image(systemName: "magnifyingglass")
									.foregroundStyle(.secondary)
									.font(.system(size: 16))
								
								TextField("Search", text: $_searchText)
									.foregroundStyle(.primary)
									.autocorrectionDisabled()
									.textInputAutocapitalization(.never)
							}
							.padding(.horizontal, 16)
							.padding(.vertical, 12)
							.background(
								Capsule()
									.fill(Color.secondary.opacity(0.15))
							)
							.padding(.horizontal, 20)
						}
						
						// Apps List or Grid
						if _allApps.isEmpty {
							VStack(spacing: 20) {
								Spacer()
								Image(systemName: "questionmark.app.fill")
									.font(.system(size: 60))
									.foregroundStyle(.secondary)
								Text("No Apps")
									.font(.title2)
									.fontWeight(.bold)
									.foregroundStyle(.primary)
								Text("Get started by importing your first IPA file.")
									.font(.subheadline)
									.foregroundStyle(.secondary)
									.multilineTextAlignment(.center)
								
								Menu {
									_importActions()
								} label: {
									Text("Import")
										.fontWeight(.semibold)
										.foregroundStyle(.white)
										.padding(.horizontal, 24)
										.padding(.vertical, 12)
										.background(
											Capsule()
												.fill(Color.accentColor)
										)
								}
								Spacer()
							}
							.frame(maxWidth: .infinity)
							.padding()
						} else {
							if _viewMode == .list {
								// List View
								LazyVStack(spacing: 12) {
									ForEach(_allApps, id: \.uuid) { app in
										LibraryCardView(
											app: app,
											selectedInfoAppPresenting: $_selectedInfoAppPresenting,
											selectedSigningAppPresenting: $_selectedSigningAppPresenting,
											selectedInstallAppPresenting: $_selectedInstallAppPresenting
										)
										.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
									}
								}
								.padding(.horizontal, 20)
							} else {
								// Grid View
								let columns = [
									GridItem(.flexible(), spacing: 12),
									GridItem(.flexible(), spacing: 12)
								]
								
								LazyVGrid(columns: columns, spacing: 12) {
									ForEach(_allApps, id: \.uuid) { app in
										LibraryGridCardView(
											app: app,
											selectedInfoAppPresenting: $_selectedInfoAppPresenting,
											selectedSigningAppPresenting: $_selectedSigningAppPresenting,
											selectedInstallAppPresenting: $_selectedInstallAppPresenting
										)
										.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
									}
								}
								.padding(.horizontal, 20)
							}
						}
						
						Spacer(minLength: 20)
					}
				}
			}
			.navigationBarHidden(true)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.height(200)])
					.presentationDragIndicator(.visible)
					.compatPresentationRadius(21)
			}
			.sheet(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base)
					.presentationDetents([.medium, .large])
					.presentationDragIndicator(.visible)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for url in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: url, id: id)
							
							// Show loading animation
							_importedAppName = url.deletingPathExtension().lastPathComponent
							_importStatus = .loading
							withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
								_showImportAnimation = true
							}
							
							do {
								try downloadManager.handlePachageFile(url: url, dl: dl)
								
								// Show success after short delay
								DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
									withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
										_importStatus = .success
									}
									
									// Auto-dismiss after 1.5 seconds
									DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
										withAnimation(.easeOut(duration: 0.3)) {
											_showImportAnimation = false
										}
									}
								}
							} catch {
								// Show failed state
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
									withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
										_importStatus = .failed
									}
									
									// Auto-dismiss after 2 seconds
									DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
										withAnimation(.easeOut(duration: 0.3)) {
											_showImportAnimation = false
										}
									}
								}
							}
						}
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isDownloadingPresenting) {
				ModernImportURLView { url in
					// Show loading animation for URL import
					_importedAppName = url.lastPathComponent
					_importStatus = .loading
					withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
						_showImportAnimation = true
					}
					
					let downloadId = "FeatherManualDownload_\(UUID().uuidString)"
					_ = downloadManager.startDownload(from: url, id: downloadId)
					
					// Monitor download completion - dismiss loading after showing it
					// The actual success/failure will be handled by the download manager
					// For now, just show the loading state briefly and dismiss
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
						withAnimation(.easeOut(duration: 0.3)) {
							_showImportAnimation = false
						}
					}
				}
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
				if let latest = _signedApps.first {
					_selectedInstallAppPresenting = AnyApp(base: latest)
				}
			}
			.overlay {
				if _showImportAnimation {
					ZStack {
						Color.black.opacity(0.5)
							.ignoresSafeArea()
							.transition(.opacity)
						
						VStack(spacing: 20) {
							ZStack {
								Circle()
									.fill(
										_useGradients ?
											(_importStatus == .success 
												? LinearGradient(
													colors: [Color.green.opacity(0.8), Color.green.opacity(0.4)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
												: _importStatus == .failed
												? LinearGradient(
													colors: [Color.red.opacity(0.8), Color.red.opacity(0.4)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
												: LinearGradient(
													colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												))
											:
											(_importStatus == .success
												? LinearGradient(
													colors: [Color.green, Color.green],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
												: _importStatus == .failed
												? LinearGradient(
													colors: [Color.red, Color.red],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
												: LinearGradient(
													colors: [Color.blue, Color.blue],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												))
									)
									.frame(width: 100, height: 100)
									.scaleEffect(_showImportAnimation ? 1.0 : 0.5)
									.animation(.spring(response: 0.6, dampingFraction: 0.6), value: _showImportAnimation)
								
								Group {
									if _importStatus == .loading {
										ProgressView()
											.progressViewStyle(CircularProgressViewStyle(tint: .white))
											.scaleEffect(1.5)
									} else if _importStatus == .success {
										Image(systemName: "checkmark")
											.font(.system(size: 50, weight: .bold))
											.foregroundStyle(.white)
									} else {
										Image(systemName: "xmark")
											.font(.system(size: 50, weight: .bold))
											.foregroundStyle(.white)
									}
								}
								.scaleEffect(_showImportAnimation && _importStatus != .loading ? 1.0 : 0.3)
								.animation(.spring(response: 0.6, dampingFraction: 0.6).delay(_importStatus == .loading ? 0 : 0.1), value: _importStatus)
							}
							
							VStack(spacing: 8) {
								Text(
									_importStatus == .success 
										? .localized("Import Successful!")
										: _importStatus == .failed
										? .localized("Import Failed")
										: .localized("Importing...")
								)
								.font(.title2)
								.fontWeight(.bold)
								.foregroundStyle(.white)
								
								Text(_importedAppName)
									.font(.subheadline)
									.foregroundStyle(.white.opacity(0.8))
									.lineLimit(2)
									.multilineTextAlignment(.center)
									.padding(.horizontal, 40)
							}
							.opacity(_showImportAnimation ? 1.0 : 0.0)
							.offset(y: _showImportAnimation ? 0 : 20)
							.animation(.easeOut(duration: 0.4).delay(0.2), value: _showImportAnimation)
						}
						.padding(40)
						.background(
							RoundedRectangle(cornerRadius: 30, style: .continuous)
								.fill(
									_useGradients ?
										LinearGradient(
											colors: [
												Color(uiColor: .systemBackground),
												Color(uiColor: .secondarySystemBackground)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
										:
										LinearGradient(
											colors: [
												Color(uiColor: .systemBackground),
												Color(uiColor: .systemBackground)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
								)
								.shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
						)
						.scaleEffect(_showImportAnimation ? 1.0 : 0.8)
						.animation(.spring(response: 0.6, dampingFraction: 0.7), value: _showImportAnimation)
					}
				}
			}
		}
	}
}

// MARK: - Extension: View
extension LibraryView {
	@ViewBuilder
	private func _importActions() -> some View {
		Button(.localized("Import from Files"), systemImage: "folder") {
			_isImportingPresenting = true
		}
		Button(.localized("Import from URL"), systemImage: "globe") {
			_isDownloadingPresenting = true
		}
	}
}

// MARK: - Library Card View (List)
struct LibraryCardView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	
	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	var body: some View {
		HStack(spacing: 12) {
			// Left: App Icon (smaller) - tappable with modern menu
			Menu {
				Button {
					selectedInfoAppPresenting = AnyApp(base: app)
				} label: {
					Label(.localized("Get Info"), systemImage: "info.circle.fill")
				}
				
				if app.isSigned {
					Button {
						selectedInstallAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Install"), systemImage: "arrow.down.circle.fill")
					}
					Button {
						selectedSigningAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Re-sign"), systemImage: "signature")
					}
				} else {
					Button {
						selectedSigningAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Sign"), systemImage: "signature")
					}
				}
				
				Divider()
				
				Button(role: .destructive) {
					Storage.shared.deleteApp(for: app)
				} label: {
					Label(.localized("Delete"), systemImage: "trash.fill")
				}
			} label: {
				FRAppIconView(app: app, size: 50)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					.shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
			}
			.buttonStyle(.plain)
			
			// Middle: Text Stack
			VStack(alignment: .leading, spacing: 3) {
				Text(app.name ?? .localized("Unknown"))
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				if let identifier = app.identifier {
					Text(identifier)
						.font(.system(size: 12))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
				
				HStack(spacing: 8) {
					if let version = app.version {
						Text("v\(version)")
							.font(.system(size: 11))
							.foregroundStyle(.secondary)
							.lineLimit(1)
					}
					
					if app.isSigned {
						Text("Signed")
							.font(.system(size: 11, weight: .medium))
							.foregroundStyle(.green)
					}
				}
			}
			
			Spacer()
			
			// Right: Action Button (smaller)
			Button {
				if app.isSigned {
					selectedInstallAppPresenting = AnyApp(base: app)
				} else {
					selectedSigningAppPresenting = AnyApp(base: app)
				}
			} label: {
				Text(app.isSigned ? "Install" : "Sign")
					.font(.system(size: 13, weight: .semibold))
					.foregroundStyle(.white)
					.padding(.horizontal, 16)
					.padding(.vertical, 8)
					.background(
						Capsule()
							.fill(
								_useGradients ?
									LinearGradient(
										colors: app.isSigned 
											? [Color.green, Color.green.opacity(0.8)]
											: [Color.accentColor, Color.accentColor.opacity(0.8)],
										startPoint: .leading,
										endPoint: .trailing
									)
									:
									LinearGradient(
										colors: app.isSigned 
											? [Color.green, Color.green]
											: [Color.accentColor, Color.accentColor],
										startPoint: .leading,
										endPoint: .trailing
									)
							)
					)
			}
			.buttonStyle(.plain)
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.fill(
					_useGradients ?
						LinearGradient(
							colors: [
								Color.secondary.opacity(0.12),
								Color.secondary.opacity(0.08)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
						:
						LinearGradient(
							colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.15)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
				)
		)
	}
}

// MARK: - Library Grid Card View
struct LibraryGridCardView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	
	var body: some View {
		VStack(spacing: 10) {
			// App Icon (smaller) - tappable with modern menu
			Menu {
				Button {
					selectedInfoAppPresenting = AnyApp(base: app)
				} label: {
					Label(.localized("Get Info"), systemImage: "info.circle.fill")
				}
				
				if app.isSigned {
					Button {
						selectedInstallAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Install"), systemImage: "arrow.down.circle.fill")
					}
					Button {
						selectedSigningAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Re-sign"), systemImage: "signature")
					}
				} else {
					Button {
						selectedSigningAppPresenting = AnyApp(base: app)
					} label: {
						Label(.localized("Sign"), systemImage: "signature")
					}
				}
				
				Divider()
				
				Button(role: .destructive) {
					Storage.shared.deleteApp(for: app)
				} label: {
					Label(.localized("Delete"), systemImage: "trash.fill")
				}
			} label: {
				FRAppIconView(app: app, size: 65)
					.clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
					.shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
			}
			.buttonStyle(.plain)
			
			// Text Stack
			VStack(spacing: 3) {
				Text(app.name ?? .localized("Unknown"))
					.font(.system(size: 13, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
					.multilineTextAlignment(.center)
				
				if let version = app.version {
					Text("v\(version)")
						.font(.system(size: 10))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
				
				if app.isSigned {
					Text("Signed")
						.font(.system(size: 9, weight: .medium))
						.foregroundStyle(.green)
				}
			}
			
			// Action Button (smaller)
			Text(app.isSigned ? "Install" : "Sign")
				.font(.system(size: 12, weight: .semibold))
				.foregroundStyle(.white)
				.padding(.horizontal, 14)
				.padding(.vertical, 6)
				.background(
					Capsule()
						.fill(
							_useGradients ?
								LinearGradient(
									colors: app.isSigned 
										? [Color.green, Color.green.opacity(0.8)]
										: [Color.accentColor, Color.accentColor.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
								:
								LinearGradient(
									colors: app.isSigned 
										? [Color.green, Color.green]
										: [Color.accentColor, Color.accentColor],
									startPoint: .leading,
									endPoint: .trailing
								)
						)
				)
				.onTapGesture {
					if app.isSigned {
						selectedInstallAppPresenting = AnyApp(base: app)
					} else {
						selectedSigningAppPresenting = AnyApp(base: app)
					}
				}
		}
		.frame(maxWidth: .infinity)
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.fill(
					_useGradients ?
						LinearGradient(
							colors: [
								Color.secondary.opacity(0.12),
								Color.secondary.opacity(0.08)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
						:
						LinearGradient(
							colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.15)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
				)
		)
	}
}
