import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var developerTapCount = 0
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
                            developerTapCount += 1
                            if developerTapCount >= 7 {
                                isDeveloperModeEnabled = true
                                developerTapCount = 0
                                HapticsManager.shared.success()
                            }
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
                
                NBSection("About") {
                    NavigationLink(destination: CreditsView()) {
                        Label(.localized("Credits"), systemImage: "person.3.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Extension: View
extension SettingsView {
}
