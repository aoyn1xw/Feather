import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var showDeveloperConfirmation = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // CoreSign Header at top
                Section {
                    CoreSignHeaderView(hideAboutButton: true)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            handleDeveloperModeTap()
                        }
                }
                
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
                    NavigationLink(destination: HapticsView()) {
                        Label(.localized("Haptics"), systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                
                NBSection(.localized("Features")) {
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Certificates"), systemImage: "checkmark.seal")
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "signature")
                    }
                    NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Compression"), systemImage: "archivebox")
                    }
                    NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "arrow.down.circle")
                    }
                    NavigationLink(destination: BackupRestoreView()) {
                        Label(.localized("Backup & Restore"), systemImage: "externaldrive")
                    }
                    NavigationLink(destination: NotificationsView()) {
                        Label(.localized("Notifications"), systemImage: "bell.badge.fill")
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, custom modifications to apps, and enable experimental features."))
                }
                
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
                    }
                } footer: {
                    Text(.localized("Reset the applications sources, certificates, apps, and general contents."))
                }
                
                if isDeveloperModeEnabled {
                    NBSection("Developer") {
                        NavigationLink(destination: DeveloperView()) {
                            Label("Developer Tools", systemImage: "hammer.fill")
                        }
                    }
                }
            }
        }
        .alert("Enable Developer Mode", isPresented: $showDeveloperConfirmation) {
            Button("Cancel", role: .cancel) {
                developerTapCount = 0
            }
            Button("Enable", role: .none) {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
                AppLogManager.shared.info("Developer mode enabled", category: "Settings")
            }
        } message: {
            Text("Developer mode provides advanced tools and diagnostics. This is intended for developers and advanced users only. Are you sure you want to enable it?")
        }
    }
    
    private func handleDeveloperModeTap() {
        let now = Date()
        
        // Reset counter if too much time has passed (5 seconds)
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 5.0 {
            developerTapCount = 0
        }
        
        lastTapTime = now
        developerTapCount += 1
        
        // Provide subtle feedback
        if developerTapCount >= 5 && developerTapCount < 10 {
            HapticsManager.shared.softImpact()
        }
        
        // Require 10 taps to show confirmation dialog
        if developerTapCount >= 10 {
            showDeveloperConfirmation = true
        }
    }
}

// MARK: - Extension: View
extension SettingsView {
}
