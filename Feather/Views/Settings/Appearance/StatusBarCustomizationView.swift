import UIKit
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
    
    // New Options
    @AppStorage("statusBar.fontSize") private var fontSize: Double = 12
    @AppStorage("statusBar.fontDesign") private var fontDesign: String = "default"
    @AppStorage("statusBar.showBackground") private var showBackground: Bool = false
    @AppStorage("statusBar.backgroundColor") private var backgroundColorHex: String = "#000000"
    @AppStorage("statusBar.backgroundOpacity") private var backgroundOpacity: Double = 0.2
    @AppStorage("statusBar.alignment") private var alignment: String = "center"
    @AppStorage("statusBar.cornerRadius") private var cornerRadius: Double = 12
    @AppStorage("statusBar.enableAnimation") private var enableAnimation: Bool = false
    @AppStorage("statusBar.animationType") private var animationType: String = "bounce"
    @AppStorage("statusBar.hideDefaultStatusBar") private var hideDefaultStatusBar: Bool = true
    @AppStorage("statusBar.blurBackground") private var blurBackground: Bool = false
    @AppStorage("statusBar.shadowEnabled") private var shadowEnabled: Bool = false
    @AppStorage("statusBar.shadowColor") private var shadowColorHex: String = "#000000"
    @AppStorage("statusBar.shadowRadius") private var shadowRadius: Double = 4
    @AppStorage("statusBar.borderWidth") private var borderWidth: Double = 0
    @AppStorage("statusBar.borderColor") private var borderColorHex: String = "#007AFF"

@State private var selectedColor: Color = .blue
    @State private var selectedBackgroundColor: Color = .black
    @State private var selectedShadowColor: Color = .black
    @State private var selectedBorderColor: Color = .blue
@State private var showColorPicker = false
    @State private var showBackgroundColorPicker = false
    @State private var showShadowColorPicker = false
    @State private var showBorderColorPicker = false
@State private var searchSymbol = ""

// Popular SF Symbols for quick access
private let popularSymbols = [
"circle.fill", "star.fill", "heart.fill", "bolt.fill", 
"sparkles", "flame.fill", "moon.fill", "sun.max.fill",
"cloud.fill", "wind", "snowflake", "drop.fill",
"bell.fill", "tag.fill", "flag.fill", "shield.fill"
]
    
    private let fontDesigns = ["default", "monospaced", "rounded", "serif"]
    private let alignments = ["leading", "center", "trailing"]
    private let animationTypes = ["none", "bounce", "fade", "slide", "scale"]

var body: some View {
NBList(.localized("Status Bar Customization")) {
// Custom Text Section
NBSection(.localized("Custom Text")) {
Toggle(String.localized("Show Custom Text"), isOn: $showCustomText)

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
.foregroundStyle(SwiftUI.Color(hex: colorHex))
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
Toggle(String.localized("Show SF Symbol"), isOn: $showSFSymbol)

if showSFSymbol {
VStack(alignment: .leading, spacing: 12) {
TextField(.localized("Search symbols..."), text: $searchSymbol)
.textFieldStyle(.roundedBorder)

Text(.localized("Popular Symbols"))
.font(.caption)
.foregroundStyle(.secondary)

LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
ForEach(popularSymbols.filter { searchSymbol.isEmpty || $0.lowercased().contains(searchSymbol.lowercased()) }, id: \.self) { symbol in
Button {
sfSymbol = symbol
} label: {
VStack(spacing: 4) {
Image(systemName: symbol)
.font(.title2)
.foregroundStyle(sfSymbol == symbol ? SwiftUI.Color(hex: colorHex) : .secondary)
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
.foregroundStyle(SwiftUI.Color(hex: colorHex))
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
Toggle(String.localized("Bold"), isOn: $isBold)
                
                Picker(String.localized("Font Design"), selection: $fontDesign) {
                    ForEach(fontDesigns, id: \.self) { design in
                        Text(design.capitalized).tag(design)
                    }
                }
                
                HStack {
                    Text(.localized("Font Size"))
                    Spacer()
                    Text("\(Int(fontSize)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fontSize, in: 8...24, step: 1)

Button {
showColorPicker = true
} label: {
HStack {
Text(.localized("Text Color"))
Spacer()
Circle()
.fill(SwiftUI.Color(hex: colorHex))
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
            
            // Background Section
            NBSection(.localized("Background")) {
                Toggle(String.localized("Show Background"), isOn: $showBackground)
                
                if showBackground {
                    Toggle(String.localized("Blur Background"), isOn: $blurBackground)
                    
                    Button {
                        showBackgroundColorPicker = true
                    } label: {
                        HStack {
                            Text(.localized("Background Color"))
                            Spacer()
                            Circle()
                                .fill(SwiftUI.Color(hex: backgroundColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text(.localized("Opacity"))
                        Spacer()
                        Text("\(Int(backgroundOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $backgroundOpacity, in: 0...1, step: 0.1)
                    
                    HStack {
                        Text(.localized("Corner Radius"))
                        Spacer()
                        Text("\(Int(cornerRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $cornerRadius, in: 0...30, step: 1)
                    
                    HStack {
                        Text(.localized("Border Width"))
                        Spacer()
                        Text("\(Int(borderWidth)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $borderWidth, in: 0...5, step: 0.5)
                    
                    if borderWidth > 0 {
                        Button {
                            showBorderColorPicker = true
                        } label: {
                            HStack {
                                Text(.localized("Border Color"))
                                Spacer()
                                Circle()
                                    .fill(SwiftUI.Color(hex: borderColorHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            } footer: {
                Text(.localized("Customize the background appearance of the status bar"))
            }
            
            // Shadow Section
            NBSection(.localized("Shadow")) {
                Toggle(String.localized("Enable Shadow"), isOn: $shadowEnabled)
                
                if shadowEnabled {
                    Button {
                        showShadowColorPicker = true
                    } label: {
                        HStack {
                            Text(.localized("Shadow Color"))
                            Spacer()
                            Circle()
                                .fill(SwiftUI.Color(hex: shadowColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                        }
                    }
                    
                    HStack {
                        Text(.localized("Shadow Radius"))
                        Spacer()
                        Text("\(Int(shadowRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $shadowRadius, in: 0...20, step: 1)
                }
            } footer: {
                Text(.localized("Add shadow effects to the status bar elements"))
            }
            
            // Layout Section
            NBSection(.localized("Layout")) {
                Picker(String.localized("Alignment"), selection: $alignment) {
                    ForEach(alignments, id: \.self) { align in
                        Text(align.capitalized).tag(align)
                    }
                }
            } footer: {
                Text(.localized("Set the horizontal alignment of status bar content"))
            }
            
            // Animation Section
            NBSection(.localized("Animation")) {
                Toggle(String.localized("Enable Animation"), isOn: $enableAnimation)
                
                if enableAnimation {
                    Picker(String.localized("Animation Type"), selection: $animationType) {
                        ForEach(animationTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }
            } footer: {
                Text(.localized("Add entrance animations to status bar elements"))
            }
            
            // System Integration Section
            NBSection(.localized("System Integration")) {
                Toggle(String.localized("Hide Default Status Bar"), isOn: $hideDefaultStatusBar)
            } footer: {
                Text(.localized("When enabled, the custom status bar fully replaces the system status bar. Note: System status bar (battery, signal, time) will still be visible in the notch/Dynamic Island area."))
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
        .sheet(isPresented: $showBackgroundColorPicker) {
            ColorPickerSheet(selectedColor: $selectedBackgroundColor, colorHex: $backgroundColorHex)
        }
        .sheet(isPresented: $showShadowColorPicker) {
            ColorPickerSheet(selectedColor: $selectedShadowColor, colorHex: $shadowColorHex)
        }
        .sheet(isPresented: $showBorderColorPicker) {
            ColorPickerSheet(selectedColor: $selectedBorderColor, colorHex: $borderColorHex)
        }
.onAppear {
selectedColor = SwiftUI.Color(hex: colorHex)
            selectedBackgroundColor = SwiftUI.Color(hex: backgroundColorHex)
            selectedShadowColor = SwiftUI.Color(hex: shadowColorHex)
            selectedBorderColor = SwiftUI.Color(hex: borderColorHex)
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
        
        fontSize = 12
        fontDesign = "default"
        showBackground = false
        backgroundColorHex = "#000000"
        backgroundOpacity = 0.2
        selectedBackgroundColor = .black
        alignment = "center"
        cornerRadius = 12
        enableAnimation = false
        animationType = "bounce"
        hideDefaultStatusBar = true
        blurBackground = false
        shadowEnabled = false
        shadowColorHex = "#000000"
        shadowRadius = 4
        selectedShadowColor = .black
        borderWidth = 0
        borderColorHex = "#007AFF"
        selectedBorderColor = .blue
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
ColorPicker(String.localized("Select Color"), selection: $tempColor, supportsOpacity: false)
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
.stroke((tempColor.toHex() ?? "") == (presetColors[index].toHex() ?? "") ? Color.primary : Color.clear, lineWidth: 3)
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
colorHex = tempColor.toHex() ?? "#000000"
dismiss()
}
}
}
}
}
}
