import SwiftUI

// MARK: - View
struct AppearanceTintColorView: View {
	@AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#B496DC"
	@AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#B496DC"
	@AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
	
	@State private var isCustomSheetPresented = false
	
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
		("Emily",			"#e18aab")
	]

	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false

	// MARK: Body
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 12) {
				// Custom option
				let cornerRadius = _ignoreSolariumLinkedOnCheck ? 28.0 : 10.5
				VStack(spacing: 8) {
					ZStack {
						if colorType == "gradient" {
							LinearGradient(
								colors: [Color(hex: gradientStartHex), Color(hex: gradientEndHex)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
							.frame(width: 30, height: 30)
							.clipShape(Circle())
						} else {
							Circle()
								.fill(Color(hex: selectedColorHex))
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
					let color = Color(hex: option.hex)
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
		.onChange(of: selectedColorHex) { value in
			if colorType == "solid" {
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: value))
			}
		}
		.onChange(of: colorType) { _ in
			if colorType == "gradient" {
				// For gradients, we need to update the tint color to a middle ground color
				let startColor = Color(hex: gradientStartHex)
				let endColor = Color(hex: gradientEndHex)
				// Use start color as the tint for system elements
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(startColor)
			}
		}
		.onChange(of: gradientStartHex) { _ in
			if colorType == "gradient" {
				let startColor = Color(hex: gradientStartHex)
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(startColor)
			}
		}
		.onChange(of: gradientEndHex) { _ in
			if colorType == "gradient" {
				let startColor = Color(hex: gradientStartHex)
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(startColor)
			}
		}
		.sheet(isPresented: $isCustomSheetPresented) {
			CustomColorPickerView(
				colorType: $colorType,
				selectedColorHex: $selectedColorHex,
				gradientStartHex: $gradientStartHex,
				gradientEndHex: $gradientEndHex
			)
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
					Section("Gradient") {
						ColorPicker("Start Color", selection: $gradientStart, supportsOpacity: false)
						ColorPicker("End Color", selection: $gradientEnd, supportsOpacity: false)
					}
				}
				
				Section("Preview") {
					HStack {
						Spacer()
						if colorType == "solid" {
							Circle()
								.fill(solidColor)
								.frame(width: 80, height: 80)
						} else {
							Circle()
								.fill(
									LinearGradient(
										colors: [gradientStart, gradientEnd],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 80, height: 80)
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
		.presentationDetents([.medium])
		.onAppear {
			solidColor = Color(hex: selectedColorHex)
			gradientStart = Color(hex: gradientStartHex)
			gradientEnd = Color(hex: gradientEndHex)
		}
	}
}

extension Color {
	func toHex() -> String? {
		guard let components = UIColor(self).cgColor.components else { return nil }
		let r = Float(components[0])
		let g = Float(components[1])
		let b = Float(components[2])
		return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
	}
}
