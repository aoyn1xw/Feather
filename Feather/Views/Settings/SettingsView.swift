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
                        ConditionalLabel(title: .localized("Appearance"), systemImage: "paintbrush")
                    }
                    NavigationLink(destination: HapticsView()) {
                        ConditionalLabel(title: .localized("Haptics"), systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                
                NBSection(.localized("Features")) {
                    NavigationLink(destination: FilesSettingsView()) {
                        ConditionalLabel(title: .localized("Files"), systemImage: "folder")
                    }
                    NavigationLink(destination: CertificatesView()) {
                        ConditionalLabel(title: .localized("Certificates"), systemImage: "checkmark.seal")
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        ConditionalLabel(title: .localized("Signing Options"), systemImage: "signature")
                    }
                    NavigationLink(destination: ArchiveView()) {
                        ConditionalLabel(title: .localized("Archive & Compression"), systemImage: "archivebox")
                    }
                    NavigationLink(destination: InstallationView()) {
                        ConditionalLabel(title: .localized("Installation"), systemImage: "arrow.down.circle")
                    }
                    NavigationLink(destination: BackupRestoreView()) {
                        ConditionalLabel(title: .localized("Backup & Restore"), systemImage: "externaldrive")
                    }
                    NavigationLink(destination: NotificationsView()) {
                        ConditionalLabel(title: .localized("Notifications"), systemImage: "bell.badge.fill")
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, custom modifications to apps, and enable experimental features."))
                }
                
                Section {
                    NavigationLink(destination: ManageStorageView()) {
                        ConditionalLabel(title: .localized("Manage Storage"), systemImage: "internaldrive")
                    }
                } footer: {
                    Text(.localized("View storage usage breakdown and clean up cached files."))
                }
                
                if isDeveloperModeEnabled {
                    NBSection("Developer") {
                        NavigationLink(destination: DeveloperView()) {
                            ConditionalLabelString(title: "Developer Tools", systemImage: "hammer.fill")
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
