import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
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
            }
        }
    }
}

// MARK: - Extension: View
extension SettingsView {
}
