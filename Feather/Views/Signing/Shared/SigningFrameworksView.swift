import SwiftUI
import NimbleViews

// MARK: - View
struct SigningFrameworksView: View {
	@State private var _frameworks: [String] = []
	@State private var _plugins: [String] = []
	
	private let _frameworksPath: String = .localized("Frameworks")
	private let _pluginsPath: String = .localized("PlugIns")
	
	var app: AppInfoPresentable
	@Binding var options: Options?
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Frameworks & PlugIns")) {
			Group {
				if !_frameworks.isEmpty {
					Section {
						ForEach(_frameworks, id: \.self) { framework in
							SigningToggleCellView(
								title: "\(self._frameworksPath)/\(framework)",
								options: $options,
								arrayKeyPath: \.removeFiles
							)
							.padding(.vertical, 2)
						}
					} header: {
						HStack {
							Image(systemName: "cube.box.fill")
								.foregroundStyle(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(_frameworksPath)
								.font(.subheadline)
								.fontWeight(.semibold)
						}
						.textCase(.none)
						.foregroundStyle(.primary)
					}
				}
				
				if !_plugins.isEmpty {
					Section {
						ForEach(_plugins, id: \.self) { plugin in
							SigningToggleCellView(
								title: "\(self._pluginsPath)/\(plugin)",
								options: $options,
								arrayKeyPath: \.removeFiles
							)
							.padding(.vertical, 2)
						}
					} header: {
						HStack {
							Image(systemName: "puzzlepiece.extension.fill")
								.foregroundStyle(
									LinearGradient(
										colors: [Color.purple, Color.purple.opacity(0.6)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(_pluginsPath)
								.font(.subheadline)
								.fontWeight(.semibold)
						}
						.textCase(.none)
						.foregroundStyle(.primary)
					}
				}
				
				if
					_frameworks.isEmpty,
					_plugins.isEmpty
				{
					HStack {
						Spacer()
						VStack(spacing: 12) {
							Image(systemName: "cube.transparent")
								.font(.system(size: 40))
								.foregroundColor(.secondary.opacity(0.6))
							
							Text(.localized("No Frameworks or PlugIns Found."))
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 20)
						Spacer()
					}
				}
			}
			.disabled(options == nil)
		}
		.onAppear(perform: _listFrameworksAndPlugins)
	}
}

// MARK: - Extension: View
extension SigningFrameworksView {
	private func _listFrameworksAndPlugins() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { return }
		
		_frameworks = _listFiles(at: path.appendingPathComponent(_frameworksPath))
		_plugins = _listFiles(at: path.appendingPathComponent(_pluginsPath))
	}
	
	private func _listFiles(at path: URL) -> [String] {
		(try? FileManager.default.contentsOfDirectory(atPath: path.path)) ?? []
	}
}
