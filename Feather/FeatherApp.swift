import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	let heartbeat = HeartbeatManager.shared

	@StateObject var downloadManager = DownloadManager.shared
	let storage = Storage.shared

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var hasDylibsDetected: Bool = false

	var body: some Scene {
		WindowGroup(content: {
			Group {
				// CRITICAL: Check for .dylib files first - blocks all navigation if found
				if hasDylibsDetected {
					DylibBlockerView()
						.onAppear {
							// Prevent any navigation or state changes
							UIApplication.shared.isIdleTimerDisabled = false
						}
				} else if !hasCompletedOnboarding {
					if #available(iOS 17.0, *) {
						OnboardingView()
							.onAppear {
								_setupTheme()
							}
					} else {
						// Fallback for iOS 16
						OnboardingViewLegacy()
							.onAppear {
								_setupTheme()
							}
					}
				} else {
					VStack {
						DownloadHeaderView(downloadManager: downloadManager)
							.transition(.move(edge: .top).combined(with: .opacity))
						VariedTabbarView()
							.environment(\.managedObjectContext, storage.context)
							.onOpenURL(perform: _handleURL)
							.transition(.move(edge: .top).combined(with: .opacity))
					}
					.animation(animationForPlatform(), value: downloadManager.manualDownloads.description)
					.onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
						DispatchQueue.main.async {
							UIAlertController.showAlertWithOk(
								title: "InvalidHostID",
								message: .localized("Your pairing file is invalid and is incompatible with your device, please import a valid pairing file.")
							)
						}
					}
					// dear god help me
					.onAppear {
						_setupTheme()
					}
					.overlay(StatusBarOverlay())
				}
			}
			.handleStatusBarHiding()
			.onAppear {
				// Scan for dylibs at launch
				_checkForDylibs()
			}
		})
	}
    
    private func _checkForDylibs() {
        // Perform dylib scan on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let detector = DylibDetector.shared
            let dylibsFound = detector.hasDylibs()

            DispatchQueue.main.async {
                if dylibsFound {
                    Logger.misc.error("🚫 .dylib files detected in app bundle - blocking navigation")
                    hasDylibsDetected = true
                } else {
                    Logger.misc.info("✅ No .dylib files detected")
                }
            }
        }
    }

    private func _setupTheme() {
        if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
            UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
        }

        let colorType = UserDefaults.standard.string(forKey: "Feather.userTintColorType") ?? "solid"
        if colorType == "gradient" {
            // For gradient, use the start color as the tint
            let gradientStartHex = UserDefaults.standard.string(forKey: "Feather.userTintGradientStart") ?? "#0077BE"
            UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: gradientStartHex))
        } else {
            UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#0077BE"))
        }
    }
    
    private func animationForPlatform() -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.35)
        }
    }
	
	private func _handleURL(_ url: URL) {
		if url.scheme == "feather" {
			/// feather://import-certificate?p12=<base64>&mobileprovision=<base64>&password=<base64>
			if url.host == "import-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
					let queryItems = components.queryItems
				else {
					return
				}
				
				func queryValue(_ name: String) -> String? {
					queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
				}
				
				guard
					let p12Base64 = queryValue("p12"),
					let provisionBase64 = queryValue("mobileprovision"),
					let passwordBase64 = queryValue("password"),
					let passwordData = Data(base64Encoded: passwordBase64),
					let password = String(data: passwordData, encoding: .utf8)
				else {
					return
				}
				
				guard
					let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
					let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
					FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
				else {
					HapticsManager.shared.error()
					return
				}
				
				FR.handleCertificateFiles(
					p12URL: p12URL,
					provisionURL: provisionURL,
					p12Password: password
				) { error in
					if let error = error {
						UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
					} else {
						HapticsManager.shared.success()
					}
				}
				
				return
			}
			/// feather://export-certificate?callback_template=<template>
			/// ?callback_template=: This is how we callback to the application requesting the certificate, this will be a url scheme
			/// 	example: livecontainer%3A%2F%2Fcertificate%3Fcert%3D%24%28BASE64_CERT%29%26password%3D%24%28PASSWORD%29
			/// 	decoded: livecontainer://certificate?cert=$(BASE64_CERT)&password=$(PASSWORD)
			/// $(BASE64_CERT) and $(PASSWORD) must be presenting in the callback template so we can replace them with the proper content
			if url.host == "export-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
				else {
					return
				}
				
				let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
				guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
				
				FR.exportCertificateAndOpenUrl(using: callbackTemplate)
			}
			/// feather://source/<url>
			if let fullPath = url.validatedScheme(after: "/source/") {
				FR.handleSource(fullPath) { }
			}
			/// feather://install/<url.ipa>
			if
				let fullPath = url.validatedScheme(after: "/install/"),
				let downloadURL = URL(string: fullPath)
			{
				_ = DownloadManager.shared.startDownload(from: downloadURL)
			}
		} else {
			if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
				if FileManager.default.isFileFromFileProvider(at: url) {
					guard url.startAccessingSecurityScopedResource() else { return }
					FR.handlePackageFile(url) { _ in }
				} else {
					FR.handlePackageFile(url) { _ in }
				}
				
				return
			}
		}
	}
}

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		_setupCrashHandler()
		_createPipeline()
		_createDocumentsDirectories()
		ResetView.clearWorkCache()
		_addDefaultCertificates()
		
		// Initialize source ordering (one-time migration)
		Storage.shared.initializeSourceOrders()
		
		// Log app launch
		AppLogManager.shared.info("Application launched successfully", category: "Lifecycle")
		
		return true
	}
	
	private func _setupCrashHandler() {
		// Set up NSException handler for crash logging
		NSSetUncaughtExceptionHandler { exception in
			let crashInfo = """
			CRASH DETECTED:
			Name: \(exception.name.rawValue)
			Reason: \(exception.reason ?? "Unknown")
			Call Stack: \(exception.callStackSymbols.joined(separator: "\n"))
			"""
			
			AppLogManager.shared.critical(crashInfo, category: "Crash")
			
			// Force persist logs immediately
			if let data = try? JSONEncoder().encode(AppLogManager.shared.logs.suffix(1000)) {
				UserDefaults.standard.set(data, forKey: "Feather.AppLogs")
				UserDefaults.standard.synchronize()
			}
		}
		
		// Set up signal handler for crashes
		signal(SIGABRT) { signal in
			AppLogManager.shared.critical("App crashed with SIGABRT signal", category: "Crash")
		}
		signal(SIGILL) { signal in
			AppLogManager.shared.critical("App crashed with SIGILL signal", category: "Crash")
		}
		signal(SIGSEGV) { signal in
			AppLogManager.shared.critical("App crashed with SIGSEGV signal", category: "Crash")
		}
		signal(SIGFPE) { signal in
			AppLogManager.shared.critical("App crashed with SIGFPE signal", category: "Crash")
		}
		signal(SIGBUS) { signal in
			AppLogManager.shared.critical("App crashed with SIGBUS signal", category: "Crash")
		}
		signal(SIGPIPE) { signal in
			AppLogManager.shared.critical("App crashed with SIGPIPE signal", category: "Crash")
		}
	}
	
	private func _createPipeline() {
		DataLoader.sharedUrlCache.diskCapacity = 0
		
		let pipeline = ImagePipeline {
			let dataLoader: DataLoader = {
				let config = URLSessionConfiguration.default
				config.urlCache = nil
				return DataLoader(configuration: config)
			}()
			let dataCache = try? DataCache(name: "ayon1xw.Feather.datacache") // disk cache
			let imageCache = Nuke.ImageCache() // memory cache
			dataCache?.sizeLimit = 500 * 1024 * 1024
			imageCache.costLimit = 100 * 1024 * 1024
			$0.dataCache = dataCache
			$0.imageCache = imageCache
			$0.dataLoader = dataLoader
			$0.dataCachePolicy = .automatic
			$0.isStoringPreviewsInMemoryCache = false
		}
		
		ImagePipeline.shared = pipeline
	}
	
	private func _createDocumentsDirectories() {
		let fileManager = FileManager.default

		let directories: [URL] = [
			fileManager.archives,
			fileManager.certificates,
			fileManager.signed,
			fileManager.unsigned
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
	
	private func _addDefaultCertificates() {
		guard
			UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
			let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil)
		else {
			return
		}
		
		do {
			let folderContents = try FileManager.default.contentsOfDirectory(
				at: signingAssetsURL,
				includingPropertiesForKeys: nil,
				options: .skipsHiddenFiles
			)
			
			for folderURL in folderContents {
				guard folderURL.hasDirectoryPath else { continue }
				
				let certName = folderURL.lastPathComponent
				
				let p12Url = folderURL.appendingPathComponent("cert.p12")
				let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
				let passwordUrl = folderURL.appendingPathComponent("cert.txt")
				
				guard
					FileManager.default.fileExists(atPath: p12Url.path),
					FileManager.default.fileExists(atPath: provisionUrl.path),
					FileManager.default.fileExists(atPath: passwordUrl.path)
				else {
					Logger.misc.warning("Skipping \(certName): missing required files")
					continue
				}
				
				let password = try String(contentsOf: passwordUrl, encoding: .utf8)
				
				FR.handleCertificateFiles(
					p12URL: p12Url,
					provisionURL: provisionUrl,
					p12Password: password,
					certificateName: certName,
					isDefault: true
				) { _ in
					
				}
			}
			UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
		} catch {
			Logger.misc.error("Failed to list signing-assets: \(error)")
		}
	}

}
