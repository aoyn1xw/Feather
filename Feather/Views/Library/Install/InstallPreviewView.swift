import UIKit
import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - View
struct InstallPreviewView: View {
@Environment(\.dismiss) var dismiss

@AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
@State private var _isWebviewPresenting = false

var app: AppInfoPresentable
@StateObject var viewModel: InstallerStatusViewModel
@StateObject var installer: ServerInstaller

@State var isSharing: Bool

init(app: AppInfoPresentable, isSharing: Bool = false) {
self.app = app
self.isSharing = isSharing
let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
self._viewModel = StateObject(wrappedValue: viewModel)
self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
}

// MARK: Body
var body: some View {
VStack(spacing: 20) {
            // Icon & Progress
InstallProgressView(app: app, viewModel: viewModel)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            // Status Text
            VStack(spacing: 8) {
                Text(viewModel.statusLabel)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                
                if viewModel.status == .broken {
                    Text(.localized("An error occurred during installation."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .animation(.snappy, value: viewModel.statusLabel)

            // Action Button
if viewModel.isCompleted {
Button {
UIApplication.openApp(with: app.identifier ?? "")
} label: {
                    HStack {
                        Text(.localized("Open App"))
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.up.right.circle.fill")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
}
.transition(.scale.combined(with: .opacity))
}
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
.sheet(isPresented: $_isWebviewPresenting) {
SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
}
.onReceive(viewModel.$status) { newStatus in
if _installationMethod == 0 {
if case .ready = newStatus {
if _serverMethod == 0 {
UIApplication.shared.open(URL(string: installer.iTunesLink)!)
} else if _serverMethod == 1 {
_isWebviewPresenting = true
}
}

if case .sendingPayload = newStatus, _serverMethod == 1 {
_isWebviewPresenting = false
}
                
                if case .completed = newStatus {
                    BackgroundAudioManager.shared.stop()
                }
}
}
.onAppear(perform: _install)
        .onAppear {
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            BackgroundAudioManager.shared.stop()
        }
}

private func _install() {
guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
UIAlertController.showAlertWithOk(
title: .localized("Install"),
message: .localized("You cannot update ‘%@‘ with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
)
dismiss()
return
}

Task {
do {
if isSharing {
try await installer.export()
} else {
try await installer.install()
}
} catch {
await MainActor.run {
UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
dismiss()
}
}
}
}
}
