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
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
					NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
						Label(.localized("App Icon"), systemImage: "app.badge")
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
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
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
                    
                    HStack {
                        Label("CoreSign", systemImage: "app.badge")
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .onTapGesture {
                                developerTapCount += 1
                                if developerTapCount >= 7 {
                                    isDeveloperModeEnabled = true
                                    developerTapCount = 0
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Extension: View
extension SettingsView {
}
