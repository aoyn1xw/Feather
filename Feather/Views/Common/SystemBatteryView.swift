import SwiftUI
import UIKit

/// A view that displays the system battery level and charging state
struct SystemBatteryView: View {
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            // Battery icon
            Image(systemName: batteryIconName)
                .font(.system(size: 14))
            
            // Battery percentage
            Text("\(Int(batteryLevel * 100))%")
                .font(.system(size: 12, weight: .regular))
        }
        .onAppear {
            enableBatteryMonitoring()
            updateBatteryInfo()
        }
        .onDisappear {
            disableBatteryMonitoring()
        }
        .onReceive(timer) { _ in
            updateBatteryInfo()
        }
    }
    
    private var batteryIconName: String {
        switch batteryState {
        case .charging, .full:
            return "battery.100.bolt"
        case .unplugged:
            if batteryLevel >= 0.75 {
                return "battery.100"
            } else if batteryLevel >= 0.50 {
                return "battery.75"
            } else if batteryLevel >= 0.25 {
                return "battery.50"
            } else {
                return "battery.25"
            }
        default:
            return "battery.0"
        }
    }
    
    private func enableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    private func disableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }
}
