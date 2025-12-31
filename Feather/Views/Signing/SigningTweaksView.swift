import SwiftUI
import NimbleViews

// MARK: - View
struct SigningTweaksView: View {
	@State private var _isAddingPresenting = false
	
	@Binding var options: Options
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Tweaks")) {
			NBSection(.localized("Injection")) {
				SigningOptionsView.picker(
					.localized("Injection Path"),
					systemImage: "doc.badge.gearshape",
					selection: $options.injectPath,
					values: Options.InjectPath.allCases
				)
				.padding(.vertical, 4)
				
				SigningOptionsView.picker(
					.localized("Injection Folder"),
					systemImage: "folder.badge.gearshape",
					selection: $options.injectFolder,
					values: Options.InjectFolder.allCases
				)
				.padding(.vertical, 4)
			}
			
			NBSection(.localized("Tweaks"), systemName: "wrench.and.screwdriver.fill") {
				if !options.injectionFiles.isEmpty {
					ForEach(options.injectionFiles, id: \.absoluteString) { tweak in
						_file(tweak: tweak)
					}
				} else {
					HStack {
						Spacer()
						VStack(spacing: 12) {
							Image(systemName: "puzzlepiece.extension")
								.font(.system(size: 40))
								.foregroundColor(.secondary.opacity(0.6))
							
							Text(verbatim: .localized("No files chosen."))
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 20)
						Spacer()
					}
				}
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus",
				style: .icon,
				placement: .topBarTrailing
			) {
				_isAddingPresenting = true
			}
		}
		.sheet(isPresented: $_isAddingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes: [.dylib, .deb],
				allowsMultipleSelection: true,
				onDocumentsPicked: { urls in
					guard !urls.isEmpty else { return }
					
					for url in urls {
						FileManager.default.moveAndStore(url, with: "FeatherTweak") { url in
							options.injectionFiles.append(url)
						}
					}
				}
			)
			.ignoresSafeArea()
		}
		.animation(.spring(response: 0.5, dampingFraction: 0.8), value: options.injectionFiles)
	}
}

// MARK: - Extension: View
extension SigningTweaksView {
	@ViewBuilder
	private func _file(tweak: URL) -> some View {
		HStack(spacing: 12) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 40, height: 40)
				
				Image(systemName: "puzzlepiece.extension.fill")
					.font(.system(size: 18))
					.foregroundStyle(Color.accentColor)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(tweak.lastPathComponent)
					.font(.body)
					.lineLimit(1)
				
				Text(tweak.pathExtension.uppercased())
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
		}
		.padding(.vertical, 4)
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			_fileActions(tweak: tweak)
		}
		.contextMenu {
			_fileActions(tweak: tweak)
		}
	}
	
	@ViewBuilder
	private func _fileActions(tweak: URL) -> some View {
		Button(role: .destructive) {
			FileManager.default.deleteStored(tweak) { url in
				if let index = options.injectionFiles.firstIndex(where: { $0 == url }) {
					withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
						options.injectionFiles.remove(at: index)
					}
				}
			}
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
}
