import SwiftUI

struct StatusBarOverlay: View {
    // Legacy custom text/symbol settings
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
    
    // Time display settings
    @AppStorage("statusBar.showTime") private var showTime: Bool = false
    @AppStorage("statusBar.showSeconds") private var showSeconds: Bool = false
    @AppStorage("statusBar.animateTime") private var animateTime: Bool = true
    @AppStorage("statusBar.timeAccentColored") private var timeAccentColored: Bool = false
    @AppStorage("statusBar.timeColor") private var timeColorHex: String = "#FFFFFF"
    
    // Widget settings
    @AppStorage("statusBar.widgetType") private var widgetTypeRaw: String = "none"
    @AppStorage("statusBar.widgetAccentColored") private var widgetAccentColored: Bool = false
    @AppStorage("statusBar.batteryColor") private var batteryColorHex: String = "#FFFFFF"
    
    @State private var isVisible = false
    @State private var currentTime = Date()
    
    // Timer for updating time
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Nearly transparent but still blocks the status bar area
    private let nearlyTransparentOpacity: Double = 0.00001
    
    private var widgetType: StatusBarWidgetType {
        StatusBarWidgetType(rawValue: widgetTypeRaw) ?? .none
    }

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
    
    private var timeAnimation: Animation? {
        animateTime ? .easeInOut(duration: 0.3) : nil
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        return formatter.string(from: currentTime)
    }
    
    private var hasContent: Bool {
        showCustomText || showSFSymbol || showTime || widgetType != .none
    }

    var body: some View {
        if hasContent {
            ZStack {
                // Always overlay to hide default status bar area
                Color.black
                    .opacity(nearlyTransparentOpacity)
                    .frame(height: 50) // Cover status bar area
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        // Left side: Time display
                        if showTime {
                            Text(timeString)
                                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                .foregroundStyle(timeAccentColored ? SwiftUI.Color(hex: colorHex) : SwiftUI.Color(hex: timeColorHex))
                                .lineLimit(1)
                                .animation(timeAnimation, value: timeString)
                        }
                        
                        Spacer()
                        
                        // Center: Legacy custom text/symbol (for backward compatibility)
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
                        
                        Spacer()
                        
                        // Right side: Widget display
                        buildWidget()
                    }
                    .padding(.horizontal, 12)
                    .padding(.leading, leftPadding)
                    .padding(.trailing, rightPadding)
                    .padding(.top, topPadding + 8) // Add 8pt to account for notch/status bar
                    .padding(.bottom, bottomPadding)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : (animationType == "scale" ? 0.8 : 1))
                    .offset(y: isVisible ? 0 : (animationType == "slide" ? -20 : 0))
                    
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .zIndex(10000)
            .onAppear {
                currentTime = Date()
                if enableAnimation {
                    withAnimation(contentAnimation) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
            .onReceive(timer) { time in
                currentTime = time
            }
        }
    }
    
    @ViewBuilder
    private func buildWidget() -> some View {
        let widgetColor = widgetAccentColored ? SwiftUI.Color(hex: colorHex) : SwiftUI.Color(hex: batteryColorHex)
        
        switch widgetType {
        case .none:
            EmptyView()
        case .text:
            if !customText.isEmpty {
                Text(customText)
                    .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                    .foregroundStyle(widgetColor)
                    .lineLimit(1)
            }
        case .sfSymbol:
            if !sfSymbol.isEmpty {
                Image(systemName: sfSymbol)
                    .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                    .foregroundStyle(widgetColor)
            }
        case .battery:
            SystemBatteryView()
                .foregroundStyle(widgetColor)
                .frame(width: 60)
        }
    }
}
