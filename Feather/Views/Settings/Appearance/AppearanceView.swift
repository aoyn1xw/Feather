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
						if _showIconsInAppearance {
							Label {
								Text(style.label)
							} icon: {
								Image(systemName: style.iconName)
							}
							.tag(style.rawValue)
						} else {
							Text(style.label).tag(style.rawValue)
						}
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
					if _showIconsInAppearance {
						Label(.localized("Use Gradients"), systemImage: "paintbrush.fill")
					} else {
						Text(.localized("Use Gradients"))
					}
				}
				
				Toggle(isOn: $_showIconsInAppearance) {
					if _showIconsInAppearance {
						Label(.localized("Show Icons in Settings"), systemImage: "square.grid.2x2.fill")
					} else {
						Text(.localized("Show Icons in Settings"))
					}
				}
				
				VStack(alignment: .leading, spacing: 8) {
					if _showIconsInAppearance {
						Label(.localized("Animation Speed"), systemImage: "hare.fill")
					} else {
						Text(.localized("Animation Speed"))
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
						if _showIconsInAppearance {
							Label {
								NBTitleWithSubtitleView(
									title: method.name,
									subtitle: method.desc
								)
							} icon: {
								Image(systemName: index == 0 ? "list.bullet" : "text.alignleft")
							}
							.tag(index)
						} else {
							NBTitleWithSubtitleView(
								title: method.name,
								subtitle: method.desc
							)
							.tag(index)
						}
					}

				}
				.labelsHidden()
				.pickerStyle(.inline)
				
				Toggle(isOn: $_showNews) {
					if _showIconsInAppearance {
						Label(.localized("Show News"), systemImage: "newspaper.fill")
					} else {
						Text(.localized("Show News"))
					}
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
