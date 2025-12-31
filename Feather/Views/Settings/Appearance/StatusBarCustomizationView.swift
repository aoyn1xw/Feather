import SwiftUI
import NimbleViews

// MARK: - View
struct StatusBarCustomizationView: View {
	@AppStorage("statusBar.customText") private var customText: String = ""
	@AppStorage("statusBar.showCustomText") private var showCustomText: Bool = false
	@AppStorage("statusBar.sfSymbol") private var sfSymbol: String = "circle.fill"
	@AppStorage("statusBar.showSFSymbol") private var showSFSymbol: Bool = false
	@AppStorage("statusBar.bold") private var isBold: Bool = false
	@AppStorage("statusBar.color") private var colorHex: String = "#007AFF"
	@AppStorage("statusBar.leftPadding") private var leftPadding: Double = 0
	@AppStorage("statusBar.rightPadding") private var rightPadding: Double = 0
	@AppStorage("statusBar.topPadding") private var topPadding: Double = 0
	@AppStorage("statusBar.bottomPadding") private var bottomPadding: Double = 0
	
	@State private var selectedColor: Color = .blue
	@State private var showColorPicker = false
	@State private var searchSymbol = ""
	
	// Popular SF Symbols for quick access
	private let popularSymbols = [
		"circle.fill", "star.fill", "heart.fill", "bolt.fill", 
		"sparkles", "flame.fill", "moon.fill", "sun.max.fill",
		"cloud.fill", "wind", "snowflake", "drop.fill",
		"bell.fill", "tag.fill", "flag.fill", "shield.fill"
	]
	
	var body: some View {
		NBList(.localized("Status Bar Customization")) {
			// Custom Text Section
			NBSection(.localized("Custom Text")) {
				Toggle(.localized("Show Custom Text"), isOn: $showCustomText)
				
				if showCustomText {
					VStack(alignment: .leading, spacing: 8) {
						TextField(.localized("Enter custom text"), text: $customText)
							.textFieldStyle(.roundedBorder)
							.font(isBold ? .body.bold() : .body)
						
						Text(.localized("Preview"))
							.font(.caption)
							.foregroundStyle(.secondary)
						
						HStack {
							Spacer()
							Text(customText.isEmpty ? "Sample Text" : customText)
								.font(isBold ? .body.bold() : .body)
								.foregroundStyle(Color(hex: colorHex))
								.padding(.horizontal, leftPadding)
								.padding(.vertical, topPadding)
							Spacer()
						}
						.padding(12)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(Color(uiColor: .secondarySystemGroupedBackground))
						)
					}
					.padding(.vertical, 4)
				}
			} footer: {
				Text(.localized("Add custom text to the status bar"))
			}
			
			// SF Symbol Section
			NBSection(.localized("SF Symbol")) {
				Toggle(.localized("Show SF Symbol"), isOn: $showSFSymbol)
				
				if showSFSymbol {
					VStack(alignment: .leading, spacing: 12) {
						TextField(.localized("Search symbols..."), text: $searchSymbol)
							.textFieldStyle(.roundedBorder)
						
						Text(.localized("Popular Symbols"))
							.font(.caption)
							.foregroundStyle(.secondary)
						
						LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
							ForEach(popularSymbols.filter { searchSymbol.isEmpty || $0.contains(searchSymbol.lowercased()) }, id: \.self) { symbol in
								Button {
									sfSymbol = symbol
								} label: {
									VStack(spacing: 4) {
										Image(systemName: symbol)
											.font(.title2)
											.foregroundStyle(sfSymbol == symbol ? Color(hex: colorHex) : .secondary)
											.frame(width: 50, height: 50)
											.background(
												RoundedRectangle(cornerRadius: 10)
													.fill(sfSymbol == symbol ? Color.accentColor.opacity(0.1) : Color.clear)
											)
											.overlay(
												RoundedRectangle(cornerRadius: 10)
													.stroke(sfSymbol == symbol ? Color.accentColor : Color.clear, lineWidth: 2)
											)
										
										Text(symbol.split(separator: ".").first?.capitalized ?? symbol)
											.font(.caption2)
											.foregroundStyle(.secondary)
											.lineLimit(1)
											.minimumScaleFactor(0.7)
									}
								}
								.buttonStyle(.plain)
							}
						}
						
						Text(.localized("Selected: \(sfSymbol)"))
							.font(.caption)
							.foregroundStyle(.secondary)
						
						HStack {
							Spacer()
							Image(systemName: sfSymbol)
								.font(isBold ? .title2.bold() : .title2)
								.foregroundStyle(Color(hex: colorHex))
								.padding(.horizontal, leftPadding)
								.padding(.vertical, topPadding)
							Spacer()
						}
						.padding(12)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(Color(uiColor: .secondarySystemGroupedBackground))
						)
					}
					.padding(.vertical, 4)
				}
			} footer: {
				Text(.localized("Add an SF Symbol to the status bar"))
			}
			
			// Styling Section
			NBSection(.localized("Styling")) {
				Toggle(.localized("Bold"), isOn: $isBold)
				
				Button {
					showColorPicker = true
				} label: {
					HStack {
						Text(.localized("Color"))
						Spacer()
						Circle()
							.fill(Color(hex: colorHex))
							.frame(width: 30, height: 30)
							.overlay(
								Circle()
									.stroke(Color.primary.opacity(0.2), lineWidth: 1)
							)
					}
				}
			} footer: {
				Text(.localized("Customize the appearance of status bar elements"))
			}
			
			// Padding Section
			NBSection(.localized("Padding")) {
				VStack(alignment: .leading, spacing: 16) {
					HStack {
						Text(.localized("Left"))
							.frame(width: 80, alignment: .leading)
						Slider(value: $leftPadding, in: 0...50, step: 1)
						Text("\(Int(leftPadding))px")
							.frame(width: 50, alignment: .trailing)
							.foregroundStyle(.secondary)
					}
					
					HStack {
						Text(.localized("Right"))
							.frame(width: 80, alignment: .leading)
						Slider(value: $rightPadding, in: 0...50, step: 1)
						Text("\(Int(rightPadding))px")
							.frame(width: 50, alignment: .trailing)
							.foregroundStyle(.secondary)
					}
					
					HStack {
						Text(.localized("Top"))
							.frame(width: 80, alignment: .leading)
						Slider(value: $topPadding, in: 0...50, step: 1)
						Text("\(Int(topPadding))px")
							.frame(width: 50, alignment: .trailing)
							.foregroundStyle(.secondary)
					}
					
					HStack {
						Text(.localized("Bottom"))
							.frame(width: 80, alignment: .leading)
						Slider(value: $bottomPadding, in: 0...50, step: 1)
						Text("\(Int(bottomPadding))px")
							.frame(width: 50, alignment: .trailing)
							.foregroundStyle(.secondary)
					}
				}
				.padding(.vertical, 4)
			} footer: {
				Text(.localized("Adjust spacing around status bar elements"))
			}
			
			// Reset Section
			Section {
				Button(role: .destructive) {
					resetToDefaults()
				} label: {
					HStack {
						Spacer()
						Text(.localized("Reset to Defaults"))
						Spacer()
					}
				}
			}
		}
		.sheet(isPresented: $showColorPicker) {
			ColorPickerSheet(selectedColor: $selectedColor, colorHex: $colorHex)
		}
		.onAppear {
			selectedColor = Color(hex: colorHex)
		}
	}
	
	private func resetToDefaults() {
		customText = ""
		showCustomText = false
		sfSymbol = "circle.fill"
		showSFSymbol = false
		isBold = false
		colorHex = "#007AFF"
		leftPadding = 0
		rightPadding = 0
		topPadding = 0
		bottomPadding = 0
		selectedColor = .blue
	}
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
	@Environment(\.dismiss) var dismiss
	@Binding var selectedColor: Color
	@Binding var colorHex: String
	
	@State private var tempColor: Color
	
	init(selectedColor: Binding<Color>, colorHex: Binding<String>) {
		self._selectedColor = selectedColor
		self._colorHex = colorHex
		self._tempColor = State(initialValue: selectedColor.wrappedValue)
	}
	
	// Preset colors
	private let presetColors: [Color] = [
		.red, .orange, .yellow, .green, .mint, .teal,
		.cyan, .blue, .indigo, .purple, .pink, .brown,
		.gray, .black, .white
	]
	
	var body: some View {
		NavigationView {
			Form {
				Section {
					ColorPicker(.localized("Select Color"), selection: $tempColor, supportsOpacity: false)
				}
				
				Section(.localized("Presets")) {
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
						ForEach(presetColors.indices, id: \.self) { index in
							Button {
								tempColor = presetColors[index]
							} label: {
								Circle()
									.fill(presetColors[index])
									.frame(width: 50, height: 50)
									.overlay(
										Circle()
											.stroke(tempColor.toHex() == presetColors[index].toHex() ? Color.primary : Color.clear, lineWidth: 3)
									)
							}
							.buttonStyle(.plain)
						}
					}
					.padding(.vertical, 8)
				}
			}
			.navigationTitle(.localized("Choose Color"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Cancel")) {
						dismiss()
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(.localized("Done")) {
						selectedColor = tempColor
						colorHex = tempColor.toHex()
						dismiss()
					}
				}
			}
		}
	}
}

// MARK: - Color Extension
extension Color {
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (255, 0, 0, 0)
		}
		self.init(
			.sRGB,
			red: Double(r) / 255,
			green: Double(g) / 255,
			blue: Double(b) / 255,
			opacity: Double(a) / 255
		)
	}
	
	func toHex() -> String {
		guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
			return "#000000"
		}
		let r = Float(components[0])
		let g = Float(components[1])
		let b = Float(components[2])
		return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
	}
}
