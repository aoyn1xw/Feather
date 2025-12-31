import SwiftUI

struct StatusBarOverlay: View {
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

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }

    var body: some View {
        if showCustomText || showSFSymbol {
            VStack(spacing: 0) {
                ZStack {
                    // Background with shadow for better visibility
                    if showBackground {
                        Capsule()
                            .fill(SwiftUI.Color(hex: backgroundColorHex).opacity(backgroundOpacity))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }

                    HStack(spacing: 8) {
                        if showCustomText && !customText.isEmpty {
                            Text(customText)
                                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                                .lineLimit(1)
                        }

                        if showSFSymbol && !sfSymbol.isEmpty {
                            Image(systemName: sfSymbol)
                                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                        }
                    }
                    .padding(.horizontal, showBackground ? 12 : 0)
                    .padding(.vertical, showBackground ? 6 : 0)
                }
                .padding(.leading, leftPadding)
                .padding(.trailing, rightPadding)
                .padding(.top, topPadding + 8) // Add 8pt to account for notch/status bar
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .zIndex(9999)
        }
    }
}
