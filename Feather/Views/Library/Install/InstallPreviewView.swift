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
@State private var _initializationError: String?

var app: AppInfoPresentable
@StateObject var viewModel: InstallerStatusViewModel
var installer: ServerInstaller?

@State var isSharing: Bool

init(app: AppInfoPresentable, isSharing: Bool = false) {
self.app = app
self.isSharing = isSharing
let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
self._viewModel = StateObject(wrappedValue: viewModel)

// Try to create the installer safely
do {
    self.installer = try ServerInstaller(app: app, viewModel: viewModel)
} catch {
    self.installer = nil
    self._initializationError = State(initialValue: error.localizedDescription)
}
}

// MARK: Body
var body: some View {
    // Check for initialization error first
    if let errorMessage = _initializationError {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.15), Color.red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    VStack(spacing: 8) {
                        Text("Installation Error")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(20)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            // Automatically dismiss after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    } else {
        // Normal installation flow
        VStack(spacing: 24) {
            // Modern Status Card
            ZStack {
                // Gradient Background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: viewModel.isCompleted
                                ? [Color.green.opacity(0.15), Color.green.opacity(0.05)]
                                : viewModel.status == .broken
                                ? [Color.red.opacity(0.15), Color.red.opacity(0.05)]
                                : [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: viewModel.isCompleted
                                        ? [Color.green.opacity(0.3), Color.green.opacity(0.1)]
                                        : viewModel.status == .broken
                                        ? [Color.red.opacity(0.3), Color.red.opacity(0.1)]
                                        : [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                VStack(spacing: 16) {
                    // Icon & Progress
                    InstallProgressView(app: app, viewModel: viewModel)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Modern Status Text with Icon
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if !viewModel.isCompleted && viewModel.status != .broken {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.accentColor)
                            } else if viewModel.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            } else if viewModel.status == .broken {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }

                            Text(viewModel.statusLabel)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        .modifier(ContentTransitionModifier())

                        if viewModel.status == .broken {
                            Text(.localized("An error occurred during installation."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else if !viewModel.isCompleted {
                            Text(getStatusSubtitle())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.statusLabel)
                }
                .padding(20)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)

            // Action Button
            if viewModel.isCompleted {
                Button {
                    UIApplication.openApp(with: app.identifier ?? "")
                } label: {
                    HStack(spacing: 8) {
                        Text(.localized("Open App"))
                            .fontWeight(.bold)
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $_isWebviewPresenting) {
            if let installer = installer {
                SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
            }
        }
        .onReceive(viewModel.$status) { newStatus in
            if _installationMethod == 0 {
                if case .ready = newStatus {
                    if _serverMethod == 0 {
                        if let installer = installer {
                            UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                        }
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
     } // Close else block
 }

 private func _install() {
     // Check if installer was initialized properly
     guard let installer = installer else {
         UIAlertController.showAlertWithOk(
             title: .localized("Error"),
             message: .localized("Failed to initialize installer. Please try again.")
         )
         dismiss()
         return
     }
     
     guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
         UIAlertController.showAlertWithOk(
             title: .localized("Install"),
             message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
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

    private func getStatusSubtitle() -> String {
        switch viewModel.status {
        case .sendingManifest:
            return "Preparing installation manifest..."
        case .sendingPayload:
            return "Transferring app payload..."
        case .installing:
            return "Installing application..."
        case .ready:
            return "Ready to install"
        default:
            return "Processing..."
        }
    }
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct ContentTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.symbolEffect)
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}
