import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
// dear god help me
struct AppearanceView: View {
	@AppStorage("Feather.userInterfaceStyle")
	private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
	
	@AppStorage("Feather.storeCellAppearance")
	private var _storeCellAppearance: Int = 0
	private let _storeCellAppearanceMethods: [(name: String, desc: String)] = [
		(.localized("Standard"), .localized("Default style for the app, only includes subtitle.")),
		(.localized("Big Description"), .localized("Adds the localized description of the app."))
	]
	
	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false
	
	@AppStorage("Feather.showNews")
	private var _showNews: Bool = true
	
	@AppStorage("Feather.useGradients")
	private var _useGradients: Bool = true
	
	@AppStorage("Feather.showIconsInAppearance")
	private var _showIconsInAppearance: Bool = true
	
	@AppStorage("Feather.animationSpeed")
	private var _animationSpeed: Double = 0.35
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Appearance")) {
			Section {
				Picker(.localized("Appearance"), selection: $_userIntefacerStyle) {
					ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
						Label {
							Text(style.label)
						} icon: {
							if _showIconsInAppearance {
								Image(systemName: style.iconName)
							}
						}
						.tag(style.rawValue)
					}
				}
				.pickerStyle(.segmented)
			} footer: {
				Text(.localized("Choose between Light, Dark, or Automatic appearance mode"))
			}
			
			NBSection(.localized("Theme")) {
				AppearanceTintColorView()
					.listRowInsets(EdgeInsets())
					.listRowBackground(EmptyView())
			} footer: {
				Text(.localized("Select your preferred accent color theme"))
			}
			
			NBSection(.localized("Visual Effects")) {
				Toggle(isOn: $_useGradients) {
					Label(.localized("Use Gradients"), systemImage: _showIconsInAppearance ? "paintbrush.fill" : "")
				}
				
				Toggle(isOn: $_showIconsInAppearance) {
					Label(.localized("Show Icons in Settings"), systemImage: _showIconsInAppearance ? "square.grid.2x2.fill" : "")
				}
				
				VStack(alignment: .leading, spacing: 8) {
					Label {
						Text(.localized("Animation Speed"))
					} icon: {
						if _showIconsInAppearance {
							Image(systemName: "hare.fill")
						}
					}
					
					HStack {
						Text(.localized("Slow"))
							.font(.caption)
							.foregroundStyle(.secondary)
						Slider(value: $_animationSpeed, in: 0.1...1.0, step: 0.05)
						Text(.localized("Fast"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			} footer: {
				Text(.localized("Customize visual effects like gradients and animation speeds"))
			}
			
			NBSection(.localized("Sources")) {
				Picker(.localized("Store Cell Appearance"), selection: $_storeCellAppearance) {
					ForEach(0..<_storeCellAppearanceMethods.count, id: \.self) { index in
						let method = _storeCellAppearanceMethods[index]
						Label {
							NBTitleWithSubtitleView(
								title: method.name,
								subtitle: method.desc
							)
						} icon: {
							if _showIconsInAppearance {
								Image(systemName: index == 0 ? "list.bullet" : "text.alignleft")
							}
						}
						.tag(index)
					}

				}
				.labelsHidden()
				.pickerStyle(.inline)
				
				Toggle(isOn: $_showNews) {
					Label(.localized("Show News"), systemImage: _showIconsInAppearance ? "newspaper.fill" : "")
				}
			} footer: {
				Text(.localized("When disabled, news from sources will not be displayed in the app."))
			}
			
			NBSection(.localized("Status Bar")) {
				NavigationLink(destination: StatusBarCustomizationView()) {
					Label(.localized("Status Bar Customization"), systemImage: "rectangle.inset.topright.filled")
				}
			} footer: {
				Text(.localized("Customize status bar with SF Symbols, text, colors, and more"))
			}
			
			NBSection(.localized("Tab Bar")) {
				NavigationLink(destination: TabBarCustomizationView()) {
					Label(.localized("Tab Bar Customization"), systemImage: "square.split.bottomrightquarter")
				}
			} footer: {
				Text(.localized("Show or hide tabs from the tab bar. Settings cannot be hidden."))
			}
			
			if #available(iOS 19.0, *) {
				NBSection(.localized("Experiments")) {
					Toggle(.localized("Enable Liquid Glass"), isOn: $_ignoreSolariumLinkedOnCheck)
				} footer: {
					Text(.localized("This enables liquid glass for this app, this requires a restart of the app to take effect."))
				}
			}
		}
		.onChange(of: _userIntefacerStyle) { value in
			if let style = UIUserInterfaceStyle(rawValue: value) {
				UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
			}
		}
		.onChange(of: _ignoreSolariumLinkedOnCheck) { _ in
			UIApplication.shared.suspendAndReopen()
		}
    }
}
