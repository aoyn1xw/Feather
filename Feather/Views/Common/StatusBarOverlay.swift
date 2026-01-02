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
    
    @State private var isVisible = false

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }
    
    private var selectedAlignment: Alignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private var contentAnimation: Animation? {
        guard enableAnimation else { return nil }
        
        switch animationType {
        case "bounce": return .spring(response: 0.6, dampingFraction: 0.6)
        case "fade": return .easeInOut(duration: 0.5)
        case "slide": return .easeOut(duration: 0.4)
        case "scale": return .spring(response: 0.5, dampingFraction: 0.7)
        default: return nil
        }
    }

    var body: some View {
        if showCustomText || showSFSymbol {
            ZStack {
                // Overlay to hide default status bar area when option is enabled
                if hideDefaultStatusBar {
                    Color.black
                        .opacity(0.00001) // Nearly transparent but still blocks the area
                        .frame(height: 50) // Cover status bar area
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 0) {
                    ZStack(alignment: selectedAlignment) {
                        // Background with shadow for better visibility
                        if showBackground {
                            Group {
                                if blurBackground {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .fill(SwiftUI.Color(hex: backgroundColorHex).opacity(backgroundOpacity))
                                        )
                                } else {
                                    Capsule()
                                        .fill(SwiftUI.Color(hex: backgroundColorHex).opacity(backgroundOpacity))
                                }
                            }
                            .cornerRadius(cornerRadius)
                            .overlay(
                                Capsule()
                                    .stroke(SwiftUI.Color(hex: borderColorHex), lineWidth: borderWidth)
                                    .cornerRadius(cornerRadius)
                            )
                            .shadow(
                                color: shadowEnabled ? SwiftUI.Color(hex: shadowColorHex).opacity(0.3) : .clear,
                                radius: shadowEnabled ? shadowRadius : 0,
                                x: 0,
                                y: shadowEnabled ? 2 : 0
                            )
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
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1 : (animationType == "scale" ? 0.8 : 1))
                        .offset(y: isVisible ? 0 : (animationType == "slide" ? -20 : 0))
                    }
                    .padding(.leading, leftPadding)
                    .padding(.trailing, rightPadding)
                    .padding(.top, topPadding + 8) // Add 8pt to account for notch/status bar
                    .padding(.bottom, bottomPadding)
                    .frame(maxWidth: .infinity, alignment: selectedAlignment)

                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .zIndex(hideDefaultStatusBar ? 10000 : 9999)
            .onAppear {
                if enableAnimation {
                    withAnimation(contentAnimation) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
        }
    }
}
