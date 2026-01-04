import SwiftUI
import Combine

// MARK: - View Model
class StatusBarViewModel: ObservableObject {
    // Custom Text
    @AppStorage("statusBar.customText") var customText: String = ""
    @AppStorage("statusBar.showCustomText") var showCustomText: Bool = false
    
    // SF Symbol
    @AppStorage("statusBar.sfSymbol") var sfSymbol: String = "circle.fill"
    @AppStorage("statusBar.showSFSymbol") var showSFSymbol: Bool = false
    
    // Styling
    @AppStorage("statusBar.bold") var isBold: Bool = false
    @AppStorage("statusBar.color") var colorHex: String = "#007AFF"
    @AppStorage("statusBar.fontSize") var fontSize: Double = 12
    @AppStorage("statusBar.fontDesign") var fontDesign: String = "default"
    
    // Background
    @AppStorage("statusBar.showBackground") var showBackground: Bool = false
    @AppStorage("statusBar.backgroundColor") var backgroundColorHex: String = "#000000"
    @AppStorage("statusBar.backgroundOpacity") var backgroundOpacity: Double = 0.2
    @AppStorage("statusBar.blurBackground") var blurBackground: Bool = false
    @AppStorage("statusBar.cornerRadius") var cornerRadius: Double = 12
    @AppStorage("statusBar.borderWidth") var borderWidth: Double = 0
    @AppStorage("statusBar.borderColor") var borderColorHex: String = "#007AFF"
    
    // Shadow
    @AppStorage("statusBar.shadowEnabled") var shadowEnabled: Bool = false
    @AppStorage("statusBar.shadowColor") var shadowColorHex: String = "#000000"
    @AppStorage("statusBar.shadowRadius") var shadowRadius: Double = 4
    
    // Layout
    @AppStorage("statusBar.alignment") var alignment: String = "center"
    @AppStorage("statusBar.leftPadding") var leftPadding: Double = 0
    @AppStorage("statusBar.rightPadding") var rightPadding: Double = 0
    @AppStorage("statusBar.topPadding") var topPadding: Double = 0
    @AppStorage("statusBar.bottomPadding") var bottomPadding: Double = 0
    
    // Text Layout
    @AppStorage("statusBar.textAlignment") var textAlignment: String = "center"
    @AppStorage("statusBar.textLeftPadding") var textLeftPadding: Double = 0
    @AppStorage("statusBar.textRightPadding") var textRightPadding: Double = 0
    @AppStorage("statusBar.textTopPadding") var textTopPadding: Double = 0
    @AppStorage("statusBar.textBottomPadding") var textBottomPadding: Double = 0
    
    // Animation
    @AppStorage("statusBar.enableAnimation") var enableAnimation: Bool = false
    @AppStorage("statusBar.animationType") var animationType: String = "bounce"
    
    // System Integration
    @AppStorage("statusBar.hideDefaultStatusBar") var hideDefaultStatusBar: Bool = true
    
    // Time and Battery
    @AppStorage("statusBar.showTime") var showTime: Bool = false
    @AppStorage("statusBar.showSeconds") var showSeconds: Bool = false
    @AppStorage("statusBar.timeColor") var timeColorHex: String = "#FFFFFF"
    @AppStorage("statusBar.showBattery") var showBattery: Bool = false
    @AppStorage("statusBar.batteryColor") var batteryColorHex: String = "#FFFFFF"
    @AppStorage("statusBar.batteryStyle") var batteryStyle: String = "icon" // "icon", "percentage", "both"
    
    // SF Symbols Picker State
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var recentSymbols: [String] = []
    @Published var favoriteSymbols: [String] = []
    @Published var selectedWeight: String = "regular"
    @Published var selectedScale: String = "medium"
    @Published var selectedRenderingMode: String = "monochrome"
    
    // Color picker states
    @Published var selectedColor: Color = .blue
    @Published var selectedBackgroundColor: Color = .black
    @Published var selectedShadowColor: Color = .black
    @Published var selectedBorderColor: Color = .blue
    @Published var selectedTimeColor: Color = .white
    @Published var selectedBatteryColor: Color = .white
    
    init() {
        selectedColor = Color(hex: colorHex)
        selectedBackgroundColor = Color(hex: backgroundColorHex)
        selectedShadowColor = Color(hex: shadowColorHex)
        selectedBorderColor = Color(hex: borderColorHex)
        selectedTimeColor = Color(hex: timeColorHex)
        selectedBatteryColor = Color(hex: batteryColorHex)
        
        // Load recent and favorite symbols from UserDefaults
        if let recents = UserDefaults.standard.stringArray(forKey: "statusBar.recentSymbols") {
            recentSymbols = recents
        }
        if let favorites = UserDefaults.standard.stringArray(forKey: "statusBar.favoriteSymbols") {
            favoriteSymbols = favorites
        }
    }
    
    // MARK: - Methods
    
    func selectSymbol(_ symbol: String) {
        sfSymbol = symbol
        addToRecents(symbol)
    }
    
    func addToRecents(_ symbol: String) {
        recentSymbols.removeAll { $0 == symbol }
        recentSymbols.insert(symbol, at: 0)
        if recentSymbols.count > 20 {
            recentSymbols.removeLast()
        }
        UserDefaults.standard.set(recentSymbols, forKey: "statusBar.recentSymbols")
    }
    
    func toggleFavorite(_ symbol: String) {
        if favoriteSymbols.contains(symbol) {
            favoriteSymbols.removeAll { $0 == symbol }
        } else {
            favoriteSymbols.append(symbol)
        }
        UserDefaults.standard.set(favoriteSymbols, forKey: "statusBar.favoriteSymbols")
    }
    
    func isFavorite(_ symbol: String) -> Bool {
        favoriteSymbols.contains(symbol)
    }
    
    func handleHideDefaultStatusBarChange(_ newValue: Bool) {
        // If user is trying to disable (show default status bar) and there are custom changes
        if !newValue && hasCustomChanges() {
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Show Default Status Bar?",
                message: "If you disable this, you won't see the custom Status Bar changes anymore. Are you sure?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                // Revert the toggle
                DispatchQueue.main.async {
                    self?.hideDefaultStatusBar = true
                }
            })
            
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
                // Clear custom changes
                self?.clearCustomChanges()
                // Post notification
                NotificationCenter.default.post(name: NSNotification.Name("StatusBarHidingPreferenceChanged"), object: nil)
            })
            
            // Present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                topController.present(alert, animated: true)
            }
        } else {
            // No custom changes or enabling hide, just post notification
            NotificationCenter.default.post(name: NSNotification.Name("StatusBarHidingPreferenceChanged"), object: nil)
        }
    }
    
    func hasCustomChanges() -> Bool {
        return showCustomText || showSFSymbol || showBackground || showTime || showBattery
    }
    
    func clearCustomChanges() {
        showCustomText = false
        showSFSymbol = false
        showBackground = false
        showTime = false
        showBattery = false
    }
    
    func resetToDefaults() {
        customText = ""
        showCustomText = false
        sfSymbol = "circle.fill"
        showSFSymbol = false
        isBold = false
        colorHex = "#007AFF"
        fontSize = 12
        fontDesign = "default"
        showBackground = false
        backgroundColorHex = "#000000"
        backgroundOpacity = 0.2
        blurBackground = false
        cornerRadius = 12
        borderWidth = 0
        borderColorHex = "#007AFF"
        shadowEnabled = false
        shadowColorHex = "#000000"
        shadowRadius = 4
        alignment = "center"
        leftPadding = 0
        rightPadding = 0
        topPadding = 0
        bottomPadding = 0
        textAlignment = "center"
        textLeftPadding = 0
        textRightPadding = 0
        textTopPadding = 0
        textBottomPadding = 0
        enableAnimation = false
        animationType = "bounce"
        hideDefaultStatusBar = true
        showTime = false
        showSeconds = false
        timeColorHex = "#FFFFFF"
        showBattery = false
        batteryColorHex = "#FFFFFF"
        batteryStyle = "icon"
        
        selectedColor = .blue
        selectedBackgroundColor = .black
        selectedShadowColor = .black
        selectedBorderColor = .blue
        selectedTimeColor = .white
        selectedBatteryColor = .white
    }
}
