import SwiftUI

// MARK: - View
struct AppearanceTintColorView: View {
	@AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#B496DC"
	@AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#B496DC"
	@AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
	
	@State private var isCustomSheetPresented = false
	@State private var isGradientTextSheetPresented = false
	
	private let tintOptions: [(name: String, hex: String)] = [
		("Default", 		"#B496DC"),
		("Classic", 		"#848ef9"),
		("Berry",   		"#ff7a83"),
		("Cool Blue", 		"#4161F1"),
		("Fuchsia", 		"#FF00FF"),
		("Protokolle", 		"#4CD964"),
		("Aidoku", 			"#FF2D55"),
		("Clock", 			"#FF9500"),
		("Peculiar", 		"#4860e8"),
		("Very Peculiar", 	"#5394F7"),
		("Emily",			"#e18aab"),
		("Mint Fresh",		"#00E5C3"),
		("Sunset Orange",	"#FF6B35"),
		("Ocean Blue",		"#0077BE"),
		("Royal Purple",	"#7B2CBF"),
		("Forest Green",	"#2D6A4F"),
		("Ruby Red",		"#D62828"),
		("Golden Hour",		"#FFB703"),
		("Lavender",		"#9D4EDD"),
		("Coral",			"#FF006E"),
		("Teal Dream",		"#06FFF0"),
		("Crimson",			"#DC2F02"),
		("Sky Blue",		"#48CAE4"),
		("Emerald",			"#52B788"),
		("Hot Pink",		"#FF69B4")
	]

	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false

	// MARK: Helper Methods
	private func updateTintColor() {
		if colorType == "gradient" {
			let startColor: SwiftUI.Color = SwiftUI.Color(hex: gradientStartHex)
			UIApplication.topViewController()?.view.window?.tintColor = UIColor(startColor)
		} else {
			UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: selectedColorHex))
		}
	}

	// MARK: Body
	var body: some View {
		VStack(spacing: 20) {
			// Gradient Text Configuration Button
			Button {
				isGradientTextSheetPresented = true
			} label: {
				HStack(spacing: 16) {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 44, height: 44)
						
						Image(systemName: "textformat.size")
							.font(.title3)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.purple, Color.blue],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					}
					.shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
					
					VStack(alignment: .leading, spacing: 4) {
						Text("Gradient Text")
							.font(.headline)
							.fontWeight(.semibold)
							.foregroundStyle(.primary)
						
						Text("Configure gradient text rendering")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					Image(systemName: "chevron.right")
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
				.padding(16)
				.background(
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.fill(Color(UIColor.secondarySystemGroupedBackground))
						.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
				)
			}
			.buttonStyle(.plain)
			
			// Tint Color Selection
			ScrollView(.horizontal, showsIndicators: false) {
			LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 12) {
				// Custom option
				let cornerRadius = _ignoreSolariumLinkedOnCheck ? 28.0 : 10.5
				VStack(spacing: 8) {
					ZStack {
						if colorType == "gradient" {
							LinearGradient(
								colors: [SwiftUI.Color(hex: gradientStartHex), SwiftUI.Color(hex: gradientEndHex)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
							.frame(width: 30, height: 30)
							.clipShape(Circle())
						} else {
							Circle()
								.fill(SwiftUI.Color(hex: selectedColorHex))
								.frame(width: 30, height: 30)
						}
						Circle()
							.strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
							.frame(width: 30, height: 30)
					}
					
					Text("Custom")
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				.frame(width: 120, height: 100)
				.background(Color(uiColor: .secondarySystemGroupedBackground))
				.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
						.strokeBorder(selectedColorHex == "custom" ? Color.accentColor : .clear, lineWidth: 2)
				)
				.onTapGesture {
					isCustomSheetPresented = true
				}
				
				ForEach(tintOptions, id: \.hex) { option in
					let color: SwiftUI.Color = SwiftUI.Color(hex: option.hex)
					VStack(spacing: 8) {
						Circle()
							.fill(color)
							.frame(width: 30, height: 30)
							.overlay(
								Circle()
									.strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
							)

						Text(option.name)
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					.frame(width: 120, height: 100)
					.background(Color(uiColor: .secondarySystemGroupedBackground))
					.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
							.strokeBorder(selectedColorHex == option.hex && colorType == "solid" ? color : .clear, lineWidth: 2)
					)
					.onTapGesture {
						colorType = "solid"
						selectedColorHex = option.hex
					}
					.accessibilityLabel(Text(option.name))
				}
			}
		}
		.onChange(of: selectedColorHex) { _ in
			updateTintColor()
		}
		.onChange(of: colorType) { _ in
			updateTintColor()
		}
		.onChange(of: gradientStartHex) { _ in
			updateTintColor()
		}
		.onChange(of: gradientEndHex) { _ in
			updateTintColor()
		}
		.sheet(isPresented: $isCustomSheetPresented) {
			CustomColorPickerView(
				colorType: $colorType,
				selectedColorHex: $selectedColorHex,
				gradientStartHex: $gradientStartHex,
				gradientEndHex: $gradientEndHex
			)
		}
		.sheet(isPresented: $isGradientTextSheetPresented) {
			GradientTextConfigView()
		}
	}
}

// MARK: - Custom Color Picker View
struct CustomColorPickerView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var colorType: String
	@Binding var selectedColorHex: String
	@Binding var gradientStartHex: String
	@Binding var gradientEndHex: String

	@State private var solidColor: Color = .accentColor
	@State private var gradientStart: Color = .purple
	@State private var gradientEnd: Color = .blue

	// Gradient Presets
	private let gradientPresets: [(name: String, start: String, end: String)] = [
		("Sunset", "#FF6B35", "#F7931E"),
		("Ocean", "#00B4DB", "#0083B0"),
		("Purple Dream", "#B490CA", "#5E4FA2"),
		("Forest", "#2D6A4F", "#52B788"),
		("Fire", "#FF0844", "#FFB199"),
		("Cotton Candy", "#FFC0CB", "#FFE5B4"),
		("Northern Lights", "#00FFA3", "#03E1FF"),
		("Twilight", "#4E54C8", "#8F94FB"),
		("Peachy", "#ED4264", "#FFEDBC"),
		("Cool Breeze", "#2BC0E4", "#EAECC6"),
		("Royal", "#141E30", "#243B55"),
		("Emerald", "#348F50", "#56B4D3")
	]

	var body: some View {
		NavigationView {
			Form {
				Section {
					Picker("Type", selection: $colorType) {
						Text("Solid Color").tag("solid")
						Text("Gradient").tag("gradient")
					}
					.pickerStyle(.segmented)
				}

				if colorType == "solid" {
					Section("Solid Color") {
						ColorPicker("Color", selection: $solidColor, supportsOpacity: false)
					}
				} else {
					Section("Custom Gradient") {
						ColorPicker("Start Color", selection: $gradientStart, supportsOpacity: false)
						ColorPicker("End Color", selection: $gradientEnd, supportsOpacity: false)
					}

					Section("Gradient Presets") {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 16) {
								ForEach(gradientPresets, id: \.name) { preset in
									VStack(spacing: 8) {
										Circle()
											.fill(
												LinearGradient(
													colors: [SwiftUI.Color(hex: preset.start), SwiftUI.Color(hex: preset.end)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
											)
											.frame(width: 60, height: 60)
											.overlay(
												Circle()
													.stroke(
														gradientStartHex == preset.start && gradientEndHex == preset.end
															? Color.accentColor
															: Color.clear,
														lineWidth: 3
													)
											)
											.onTapGesture {
												gradientStart = SwiftUI.Color(hex: preset.start)
												gradientEnd = SwiftUI.Color(hex: preset.end)
											}

										Text(preset.name)
											.font(.caption2)
											.foregroundStyle(.secondary)
											.lineLimit(1)
									}
									.frame(width: 80)
								}
							}
							.padding(.vertical, 8)
						}
						.listRowInsets(EdgeInsets())
					}
				}

				Section("Preview") {
					HStack {
						Spacer()
						if colorType == "solid" {
							Circle()
								.fill(solidColor)
								.frame(width: 100, height: 100)
								.shadow(color: solidColor.opacity(0.4), radius: 10, x: 0, y: 5)
						} else {
							Circle()
								.fill(
									LinearGradient(
										colors: [gradientStart, gradientEnd],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 100, height: 100)
								.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
						}
						Spacer()
					}
					.padding()
				}
			}
			.navigationTitle("Custom Color")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						if colorType == "solid" {
							selectedColorHex = solidColor.toHex() ?? "#B496DC"
							UIApplication.topViewController()?.view.window?.tintColor = UIColor(solidColor)
						} else {
							gradientStartHex = gradientStart.toHex() ?? "#B496DC"
							gradientEndHex = gradientEnd.toHex() ?? "#848ef9"
						}
						dismiss()
					}
				}
			}
		}
		.presentationDetents([.large])
		.onAppear {
			solidColor = SwiftUI.Color(hex: selectedColorHex)
			gradientStart = SwiftUI.Color(hex: gradientStartHex)
			gradientEnd = SwiftUI.Color(hex: gradientEndHex)
		}
	}
}

// MARK: - Gradient Text Configuration View
struct GradientTextConfigView: View {
@Environment(\.dismiss) var dismiss
@ObservedObject private var manager = GradientTextManager.shared

@State private var startColor: Color = .purple
@State private var endColor: Color = .blue

private let directionOptions: [(name: String, value: String, icon: String)] = [
("Horizontal", "horizontal", "arrow.left.and.right"),
("Vertical", "vertical", "arrow.up.and.down"),
("Diagonal", "diagonal", "arrow.up.left.and.arrow.down.right")
]

var body: some View {
NavigationView {
Form {
// Enable/Disable Toggle
Section {
Toggle(isOn: $manager.isGradientTextEnabled) {
VStack(alignment: .leading, spacing: 4) {
Text("Enable Gradient Text")
.font(.headline)
Text("Apply gradients to text throughout the app")
.font(.caption)
.foregroundStyle(.secondary)
}
}
.tint(.accentColor)
} header: {
HStack {
Image(systemName: "textformat.size")
.foregroundStyle(.accentColor)
Text("Gradient Text")
.font(.subheadline)
.fontWeight(.semibold)
}
}

if manager.isGradientTextEnabled {
// Color Selection
Section("Colors") {
ColorPicker("Start Color", selection: $startColor, supportsOpacity: false)
.onChange(of: startColor) { newValue in
manager.gradientStartColorHex = newValue.toHex() ?? "#B496DC"
notifySettingsChanged()
}

ColorPicker("End Color", selection: $endColor, supportsOpacity: false)
.onChange(of: endColor) { newValue in
manager.gradientEndColorHex = newValue.toHex() ?? "#848ef9"
notifySettingsChanged()
}
}

// Direction Selection
Section("Direction") {
ForEach(directionOptions, id: \.value) { option in
Button {
manager.gradientDirection = option.value
notifySettingsChanged()
} label: {
HStack(spacing: 16) {
ZStack {
Circle()
.fill(
manager.gradientDirection == option.value
? Color.accentColor.opacity(0.15)
: Color.clear
)
.frame(width: 40, height: 40)

Image(systemName: option.icon)
.font(.title3)
.foregroundStyle(
manager.gradientDirection == option.value
? Color.accentColor
: Color.secondary
)
}

Text(option.name)
.foregroundStyle(.primary)

Spacer()

if manager.gradientDirection == option.value {
Image(systemName: "checkmark")
.foregroundStyle(.accentColor)
.font(.headline)
}
}
.padding(.vertical, 8)
}
.buttonStyle(.plain)
}
}

// Preview
Section("Preview") {
VStack(spacing: 16) {
Text("Sample Gradient Text")
.font(.title2)
.fontWeight(.bold)
.foregroundStyle(
LinearGradient(
colors: [startColor, endColor],
startPoint: manager.gradientStartPoint,
endPoint: manager.gradientEndPoint
)
)

Text("This is how text will appear with gradient enabled")
.font(.body)
.foregroundStyle(
LinearGradient(
colors: [startColor, endColor],
startPoint: manager.gradientStartPoint,
endPoint: manager.gradientEndPoint
)
)
.multilineTextAlignment(.center)

Text("Small text preview")
.font(.caption)
.foregroundStyle(
LinearGradient(
colors: [startColor, endColor],
startPoint: manager.gradientStartPoint,
endPoint: manager.gradientEndPoint
)
)
}
.frame(maxWidth: .infinity)
.padding(.vertical, 20)
}

// Accessibility
Section {
Toggle(isOn: $manager.useAccessibilityFallback) {
VStack(alignment: .leading, spacing: 4) {
Text("Accessibility Fallback")
.font(.headline)
Text("Use solid colors for better readability")
.font(.caption)
.foregroundStyle(.secondary)
}
}
.tint(.accentColor)
.onChange(of: manager.useAccessibilityFallback) { _ in
notifySettingsChanged()
}
} header: {
HStack {
Image(systemName: "accessibility")
.foregroundStyle(.green)
Text("Accessibility")
}
} footer: {
Text("When enabled, gradient text will be replaced with solid colors for better contrast and readability.")
}
}
}
.navigationTitle("Gradient Text")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .confirmationAction) {
Button("Done") {
dismiss()
}
}
}
}
.onAppear {
startColor = Color(hex: manager.gradientStartColorHex)
endColor = Color(hex: manager.gradientEndColorHex)
}
}

private func notifySettingsChanged() {
NotificationCenter.default.post(name: .gradientTextSettingsChanged, object: nil)
}
}

// MARK: - Gradient Text Configuration View
struct GradientTextConfigView: View {
	@Environment(\.dismiss) var dismiss
	@ObservedObject private var manager = GradientTextManager.shared
	
	@State private var startColor: Color = .purple
	@State private var endColor: Color = .blue
	
	private let directionOptions: [(name: String, value: String, icon: String)] = [
		("Horizontal", "horizontal", "arrow.left.and.right"),
		("Vertical", "vertical", "arrow.up.and.down"),
		("Diagonal", "diagonal", "arrow.up.left.and.arrow.down.right")
	]
	
	var body: some View {
		NavigationView {
			Form {
				// Enable/Disable Toggle
				Section {
					Toggle(isOn: $manager.isGradientTextEnabled) {
						VStack(alignment: .leading, spacing: 4) {
							Text("Enable Gradient Text")
								.font(.headline)
							Text("Apply gradients to text throughout the app")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.tint(.accentColor)
				} header: {
					HStack {
						Image(systemName: "textformat.size")
							.foregroundStyle(.accentColor)
						Text("Gradient Text")
							.font(.subheadline)
							.fontWeight(.semibold)
					}
				}
				
				if manager.isGradientTextEnabled {
					// Color Selection
					Section("Colors") {
						ColorPicker("Start Color", selection: $startColor, supportsOpacity: false)
							.onChange(of: startColor) { newValue in
								manager.gradientStartColorHex = newValue.toHex() ?? "#B496DC"
								notifySettingsChanged()
							}
						
						ColorPicker("End Color", selection: $endColor, supportsOpacity: false)
							.onChange(of: endColor) { newValue in
								manager.gradientEndColorHex = newValue.toHex() ?? "#848ef9"
								notifySettingsChanged()
							}
					}
					
					// Direction Selection
					Section("Direction") {
						ForEach(directionOptions, id: \.value) { option in
							Button {
								manager.gradientDirection = option.value
								notifySettingsChanged()
							} label: {
								HStack(spacing: 16) {
									ZStack {
										Circle()
											.fill(
												manager.gradientDirection == option.value
													? Color.accentColor.opacity(0.15)
													: Color.clear
											)
											.frame(width: 40, height: 40)
										
										Image(systemName: option.icon)
											.font(.title3)
											.foregroundStyle(
												manager.gradientDirection == option.value
													? Color.accentColor
													: Color.secondary
											)
									}
									
									Text(option.name)
										.foregroundStyle(.primary)
									
									Spacer()
									
									if manager.gradientDirection == option.value {
										Image(systemName: "checkmark")
											.foregroundStyle(.accentColor)
											.font(.headline)
									}
								}
								.padding(.vertical, 8)
							}
							.buttonStyle(.plain)
						}
					}
					
					// Preview
					Section("Preview") {
						VStack(spacing: 16) {
							Text("Sample Gradient Text")
								.font(.title2)
								.fontWeight(.bold)
								.foregroundStyle(
									LinearGradient(
										colors: [startColor, endColor],
										startPoint: manager.gradientStartPoint,
										endPoint: manager.gradientEndPoint
									)
								)
							
							Text("This is how text will appear with gradient enabled")
								.font(.body)
								.foregroundStyle(
									LinearGradient(
										colors: [startColor, endColor],
										startPoint: manager.gradientStartPoint,
										endPoint: manager.gradientEndPoint
									)
								)
								.multilineTextAlignment(.center)
							
							Text("Small text preview")
								.font(.caption)
								.foregroundStyle(
									LinearGradient(
										colors: [startColor, endColor],
										startPoint: manager.gradientStartPoint,
										endPoint: manager.gradientEndPoint
									)
								)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 20)
					}
					
					// Accessibility
					Section {
						Toggle(isOn: $manager.useAccessibilityFallback) {
							VStack(alignment: .leading, spacing: 4) {
								Text("Accessibility Fallback")
									.font(.headline)
								Text("Use solid colors for better readability")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						.tint(.accentColor)
						.onChange(of: manager.useAccessibilityFallback) { _ in
							notifySettingsChanged()
						}
					} header: {
						HStack {
							Image(systemName: "accessibility")
								.foregroundStyle(.green)
							Text("Accessibility")
						}
					} footer: {
						Text("When enabled, gradient text will be replaced with solid colors for better contrast and readability.")
					}
				}
			}
			.navigationTitle("Gradient Text")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
		.onAppear {
			startColor = Color(hex: manager.gradientStartColorHex)
			endColor = Color(hex: manager.gradientEndColorHex)
		}
	}
	
	private func notifySettingsChanged() {
		NotificationCenter.default.post(name: .gradientTextSettingsChanged, object: nil)
	}
}
