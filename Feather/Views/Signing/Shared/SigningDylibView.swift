import SwiftUI
import NimbleViews
import ZsignSwift

// MARK: - View
struct SigningDylibView: View {
	@State private var _dylibs: [String] = []
	@State private var _hiddenDylibCount: Int = 0
	
	var app: AppInfoPresentable
	@Binding var options: Options?
	
	var body: some View {
		NBList(.localized("Dylibs"), type: .list) {
			Section {
				ForEach(_dylibs, id: \.self) { dylib in
					SigningToggleCellView(
						title: dylib,
						options: $options,
						arrayKeyPath: \.disInjectionFiles
					)
					.padding(.vertical, 2)
				}
			} header: {
				HStack {
					Image(systemName: "puzzlepiece.fill")
						.foregroundStyle(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Dynamic Libraries"))
						.font(.subheadline)
						.fontWeight(.semibold)
				}
				.textCase(.none)
				.foregroundStyle(.primary)
			}
			.disabled(options == nil)
			
			NBSection {
				HStack {
					Image(systemName: "eye.slash.fill")
						.foregroundStyle(.secondary)
					
					Text(verbatim: .localized("%lld required system dylibs not shown.", arguments: _hiddenDylibCount))
						.font(.footnote)
						.foregroundColor(.secondary)
				}
			} header: {
				Text(.localized("Hidden"))
					.font(.subheadline)
					.fontWeight(.semibold)
					.textCase(.none)
					.foregroundStyle(.primary)
			}
		}
		.onAppear(perform: _loadDylibs)
	}
}

// MARK: - Extension: View
extension SigningDylibView {
	private func _loadDylibs() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { return }
		
		let bundle = Bundle(url: path)
		let execPath = path.appendingPathComponent(bundle?.exec ?? "").relativePath
		
		let allDylibs = Zsign.listDylibs(appExecutable: execPath).map { $0 as String }
		
		_dylibs = allDylibs.filter { $0.hasPrefix("@rpath") || $0.hasPrefix("@executable_path") }
		_hiddenDylibCount = allDylibs.count - _dylibs.count
	}
}
