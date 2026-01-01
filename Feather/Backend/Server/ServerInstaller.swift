//  feather
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import Foundation
import Vapor
import NIOSSL
import NIOTLS
import SwiftUI
import IDeviceSwift

// MARK: - Class
class ServerInstaller: Identifiable, ObservableObject {
	let id = UUID()
	let port = Int.random(in: 4000...8000)
	private var _needsShutdown = false
	
	var packageUrl: URL?
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	private var _server: Application?

	init(app: AppInfoPresentable, viewModel: InstallerStatusViewModel) throws {
		self.app = app
		self.viewModel = viewModel
		
		AppLogManager.shared.info("Initializing ServerInstaller for \(app.name ?? "Unknown") on port \(port)", category: "Installation")
		
		do {
			try _setup()
			AppLogManager.shared.debug("ServerInstaller setup completed", category: "Installation")
			
			try _configureRoutes()
			AppLogManager.shared.debug("ServerInstaller routes configured", category: "Installation")
			
			try _server?.server.start()
			AppLogManager.shared.success("ServerInstaller server started successfully", category: "Installation")
			
			_needsShutdown = true
		} catch {
			AppLogManager.shared.error("ServerInstaller initialization failed: \(error.localizedDescription)", category: "Installation")
			throw error
		}
	}
	
	deinit {
		_shutdownServer()
	}
	
	private func _setup() throws {
		guard let server = try? setupApp(port: port) else {
			AppLogManager.shared.error("Failed to setup server application on port \(port)", category: "Installation")
			throw NSError(domain: "ServerInstaller", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to setup server on port \(port)"])
		}
		self._server = server
		AppLogManager.shared.debug("Server application setup completed on port \(port)", category: "Installation")
	}
		
	private func _configureRoutes() throws {
		guard let server = _server else {
			AppLogManager.shared.error("Cannot configure routes: server is nil", category: "Installation")
			throw NSError(domain: "ServerInstaller", code: -2, userInfo: [NSLocalizedDescriptionKey: "Server not initialized"])
		}
		
		server.get("*") { [weak self] req in
			guard let self else { return Response(status: .badGateway) }
			switch req.url.path {
			case plistEndpoint.path:
				self._updateStatus(.sendingManifest)
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "text/xml",
				], body: .init(data: installManifestData))
			case displayImageSmallEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageSmallData))
			case displayImageLargeEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageLargeData))
			case payloadEndpoint.path:
				guard let packageUrl = packageUrl else {
					return Response(status: .notFound)
				}
				
				self._updateStatus(.sendingPayload)
				
				return req.fileio.streamFile(
					at: packageUrl.path
				) { result in
					self._updateStatus(.completed)
				}
			case "/install":
				var headers = HTTPHeaders()
				headers.add(name: .contentType, value: "text/html")
				return Response(status: .ok, headers: headers, body: .init(string: self.html))
			default:
				return Response(status: .notFound)
			}
		}
	}
	
	private func _shutdownServer() {
		guard _needsShutdown else { return }
		
		_needsShutdown = false
		_server?.server.shutdown()
		_server?.shutdown()
	}
	
	private func _updateStatus(_ newStatus: InstallerStatusViewModel.InstallerStatus) {
		DispatchQueue.main.async {
			self.viewModel.status = newStatus
		}
	}
		
	func getServerMethod() -> Int {
		UserDefaults.standard.integer(forKey: "Feather.serverMethod")
	}
	
	func getIPFix() -> Bool {
		UserDefaults.standard.bool(forKey: "Feather.ipFix")
	}

	func install() async throws {
		_updateStatus(.preparing)

		// Sign the app
		let signingHandler = SigningHandler(app: app)
		let signedAppURL = try await signingHandler.sign()

		// Set package URL for the server to serve
		self.packageUrl = signedAppURL

		// Check installation method
		let installationMethod = UserDefaults.standard.integer(forKey: "Feather.installationMethod")

		if installationMethod == 1 {
			// IDevice installation
			_updateStatus(.connecting)
			try await _installViaIDevice(signedAppURL)
		} else {
			// Server-based installation
			_updateStatus(.ready)
		}
	}

	func export() async throws {
		_updateStatus(.preparing)

		// Sign the app
		let signingHandler = SigningHandler(app: app)
		let signedAppURL = try await signingHandler.sign()

		// Export via share sheet
		await MainActor.run {
			let shareSheet = UIActivityViewController(
				activityItems: [signedAppURL],
				applicationActivities: nil
			)

			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let viewController = windowScene.windows.first?.rootViewController {
				viewController.present(shareSheet, animated: true)
			}
		}

		_updateStatus(.completed)
	}

	private func _installViaIDevice(_ ipaURL: URL) async throws {
		_updateStatus(.installing)

		// Create a temporary viewModel for IDeviceSwift's InstallationProxy
		let ideviceViewModel = IDeviceSwift.InstallerStatusViewModel(status: .none, isIdevice: true)
		
		// Create InstallationProxy to install via IDevice
		let installationProxy = InstallationProxy(viewModel: ideviceViewModel)
		
		// Install the app
		try await installationProxy.install(at: ipaURL)

		_updateStatus(.completed)
	}
}
