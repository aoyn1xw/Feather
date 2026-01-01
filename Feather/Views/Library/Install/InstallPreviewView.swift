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

	// Try to create the installer safely with detailed error handling
	var tempInstaller: ServerInstaller? = nil
	var error: String? = nil

	do {
		AppLogManager.shared.info("Attempting to initialize ServerInstaller for \(app.name ?? "Unknown")", category: "Installation")
		tempInstaller = try ServerInstaller(app: app, viewModel: viewModel)
		AppLogManager.shared.success("ServerInstaller initialized successfully for \(app.name ?? "Unknown")", category: "Installation")
	} catch let initError as NSError {
		let errorMessage = "Failed to initialize ServerInstaller: \(initError.localizedDescription)"
		AppLogManager.shared.error(errorMessage, category: "Installation")
		error = errorMessage
	} catch let otherError {
		let errorMessage = "Failed to initialize ServerInstaller: \(otherError.localizedDescription)"
		AppLogManager.shared.error(errorMessage, category: "Installation")
		error = errorMessage
	}

	self.installer = tempInstaller
	self._initializationError = State(wrappedValue: error)
}

// MARK: Body
var body: some View {
    // Check for initialization error first
    if let errorMessage = _initializationError {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.red.opacity(0.1))
                    .frame(height: 180)
                
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
            }
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
            // Simple Status Card
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        viewModel.isCompleted
                            ? Color.green.opacity(0.1)
                            : viewModel.status == .broken
                            ? Color.red.opacity(0.1)
                            : Color.accentColor.opacity(0.1)
                    )
                    .frame(height: 180)

                VStack(spacing: 16) {
                    // Icon & Progress
                    InstallProgressView(app: app, viewModel: viewModel)

                    // Status Text
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if !viewModel.isCompleted && viewModel.status != .broken {
                                ProgressView()
                                    .scaleEffect(0.8)
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
                        }

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
                }
            }
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
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
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
     AppLogManager.shared.info("Starting installation for: \(app.name ?? "Unknown")", category: "Installation")
     
     // Check if installer was initialized properly
     guard let installer = installer else {
         let errorMsg = _initializationError ?? "Unknown initialization error"
         AppLogManager.shared.error("Cannot install - installer initialization failed for \(app.name ?? "Unknown"): \(errorMsg)", category: "Installation")
         
         DispatchQueue.main.async {
             viewModel.status = .broken
             
             // Show error alert after a brief delay
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                 UIAlertController.showAlertWithOk(
                     title: .localized("Installation Error"),
                     message: .localized("Failed to initialize installer: \(errorMsg)")
                 )
                 dismiss()
             }
         }
         return
     }
     
     guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
         AppLogManager.shared.warning("Cannot install Feather over itself", category: "Installation")
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
                 AppLogManager.shared.info("Exporting app: \(app.name ?? "Unknown")", category: "Installation")
                 try await installer.export()
                 AppLogManager.shared.success("Successfully exported app: \(app.name ?? "Unknown")", category: "Installation")
             } else {
                 AppLogManager.shared.info("Installing app: \(app.name ?? "Unknown") via method \(_installationMethod)", category: "Installation")
                 try await installer.install()
                 AppLogManager.shared.success("Successfully installed app: \(app.name ?? "Unknown")", category: "Installation")
             }
         } catch {
             AppLogManager.shared.error("Installation failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "Installation")
             await MainActor.run {
                 viewModel.status = .broken
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
