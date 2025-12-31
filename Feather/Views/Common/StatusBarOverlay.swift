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
    
    // New Options
    @AppStorage("statusBar.fontSize") private var fontSize: Double = 12
    @AppStorage("statusBar.fontDesign") private var fontDesign: String = "default" // default, monospaced, rounded, serif
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
            VStack {
                ZStack {
                    HStack(spacing: 8) {
                        if showCustomText && !customText.isEmpty {
                            Text(customText)
                                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                        }
                        
                        if showSFSymbol && !sfSymbol.isEmpty {
                            Image(systemName: sfSymbol)
                                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(SwiftUI.Color(hex: backgroundColorHex).opacity(showBackground ? backgroundOpacity : 0))
                    )
                    .padding(.leading, leftPadding)
                    .padding(.trailing, rightPadding)
                    .padding(.top, topPadding)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44) // Standard status bar height
                .background(Color.clear)
                
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false) // Pass touches through
            .zIndex(9999) // Ensure it's on top
        }
    }
}
