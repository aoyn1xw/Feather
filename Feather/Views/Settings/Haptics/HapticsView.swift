import SwiftUI
import NimbleViews

// MARK: - HapticsView
struct HapticsView: View {
    @StateObject private var hapticsManager = HapticsManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $hapticsManager.isEnabled) {
                    Label(.localized("Enable Haptics"), systemImage: "iphone.radiowaves.left.and.right")
                }
                .onChange(of: hapticsManager.isEnabled) { newValue in
                    if newValue {
                        HapticsManager.shared.impact()
                    }
                }
            } footer: {
                Text(.localized("Enable haptic feedback throughout the app for actions, errors, and success states."))
            }
            
            if hapticsManager.isEnabled {
                Section {
                    ForEach(HapticsManager.HapticIntensity.allCases, id: \.self) { intensity in
                        Button {
                            hapticsManager.intensity = intensity
                            HapticsManager.shared.impact()
                        } label: {
                            HStack {
                                Text(intensity.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if hapticsManager.intensity == intensity {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text(.localized("Intensity"))
                } footer: {
                    Text(.localized("Choose the intensity of haptic feedback. Tap each option to feel the difference."))
                }
            }
        }
        .navigationTitle(.localized("Haptics"))
        .navigationBarTitleDisplayMode(.large)
    }
}
