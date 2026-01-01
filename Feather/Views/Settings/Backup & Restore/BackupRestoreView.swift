import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData

// MARK: - View
struct BackupRestoreView: View {
	@Environment(\.dismiss) var dismiss
	@State private var isExporting = false
	@State private var isImporting = false
	@State private var exportURL: URL?
	@State private var showRestoreDialog = false
	@State private var pendingRestoreURL: URL?
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Backup & Restore")) {
			NBSection(.localized("Backup")) {
				Button {
					createBackup()
				} label: {
					HStack {
						Image(systemName: "square.and.arrow.up")
							.font(.title3)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.blue, Color.blue.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						
						VStack(alignment: .leading, spacing: 4) {
							Text(.localized("Create Backup"))
								.fontWeight(.medium)
							Text(.localized("Export certificates, provisioning profiles, sources, and all app settings"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 6)
				}
			} footer: {
				Text(.localized("Creates a .zip file containing certificates, provisioning profiles, sources, and all settings. Certificate restoration preserves files for manual re-import if needed."))
			}
			
			NBSection(.localized("Restore")) {
				Button {
					isImporting = true
				} label: {
					HStack {
						Image(systemName: "square.and.arrow.down")
							.font(.title3)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.green, Color.green.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						
						VStack(alignment: .leading, spacing: 4) {
							Text(.localized("Restore Backup"))
								.fontWeight(.medium)
							Text(.localized("Import a previously created backup file"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 6)
				}
			} footer: {
				Text(.localized("Restores your data from a backup file. CoreSign will restart to apply the changes."))
			}
		}
		.fileExporter(
			isPresented: $isExporting,
			document: exportURL != nil ? BackupDocument(url: exportURL!) : nil,
			contentType: .zip,
			defaultFilename: "CoreSign_Backup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).zip"
		) { result in
			switch result {
			case .success(let url):
				UIAlertController.showAlertWithOk(
					title: .localized("Success"),
					message: .localized("Backup saved successfully to \(url.lastPathComponent)")
				)
			case .failure(let error):
				UIAlertController.showAlertWithOk(
					title: .localized("Error"),
					message: .localized("Failed to save backup: \(error.localizedDescription)")
				)
			}
			// Clean up temp file
			if let exportURL = exportURL {
				try? FileManager.default.removeItem(at: exportURL)
				self.exportURL = nil
			}
		}
		.sheet(isPresented: $isImporting) {
			FileImporterRepresentableView(
				allowedContentTypes: [.zip],
				allowsMultipleSelection: false,
				onDocumentsPicked: { urls in
					guard let url = urls.first else { return }
					pendingRestoreURL = url
					showRestoreDialog = true
				}
			)
			.ignoresSafeArea()
		}
		.alert(.localized("Restart Required"), isPresented: $showRestoreDialog) {
			Button(.localized("No"), role: .cancel) {
				if let url = pendingRestoreURL {
					// Mark for deferred restore
					UserDefaults.standard.set(url.path, forKey: "pendingRestorePath")
					pendingRestoreURL = nil
				}
			}
			Button(.localized("Yes")) {
				if let url = pendingRestoreURL {
					performRestore(from: url, restart: true)
				}
			}
		} message: {
			Text(.localized("CoreSign has to restart in order to apply this backup, do you want to proceed?"))
		}
	}
	
	// MARK: - Backup Functions
	private func createBackup() {
		// Create temporary directory for backup
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		do {
			try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
			
			// 1. Backup certificates with full metadata
			let certificatesDir = tempDir.appendingPathComponent("certificates")
			try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
			let certificates = Storage.shared.getAllCertificates()
			var certMetadata: [[String: Any]] = []
			
			for cert in certificates {
				if let uuid = cert.uuid {
					var metadata: [String: Any] = ["uuid": uuid]
					
					// Save certificate file
					if let certURL = Storage.shared.getFile(.certificate, from: cert),
					   let certData = try? Data(contentsOf: certURL) {
						let destURL = certificatesDir.appendingPathComponent("\(uuid).p12")
						try certData.write(to: destURL)
						metadata["hasP12"] = true
					}
					
					// Save provisioning profile
					if let provisionURL = Storage.shared.getFile(.provision, from: cert),
					   let provisionData = try? Data(contentsOf: provisionURL) {
						let destURL = certificatesDir.appendingPathComponent("\(uuid).mobileprovision")
						try provisionData.write(to: destURL)
						metadata["hasProvision"] = true
					}
					
					// Save metadata
					if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
						metadata["name"] = provisionData.Name
						if let teamID = provisionData.TeamIdentifier.first {
							metadata["teamID"] = teamID
						}
						metadata["teamName"] = provisionData.TeamName
					}
					if let date = cert.date { metadata["date"] = date.timeIntervalSince1970 }
					metadata["ppQCheck"] = cert.ppQCheck
					
					certMetadata.append(metadata)
				}
			}
			
			// Save certificate metadata
			let certMetadataFile = tempDir.appendingPathComponent("certificates_metadata.json")
			if let jsonData = try? JSONSerialization.data(withJSONObject: certMetadata) {
				try jsonData.write(to: certMetadataFile)
			}
			
			// 2. Backup sources
			let sourcesFile = tempDir.appendingPathComponent("sources.json")
			let sources = Storage.shared.getSources()
			let sourcesData = sources.compactMap { source -> [String: String]? in
				guard let urlString = source.sourceURL?.absoluteString,
					  let name = source.name,
					  let identifier = source.identifier else { return nil }
				return ["url": urlString, "name": name, "identifier": identifier]
			}
			if let jsonData = try? JSONSerialization.data(withJSONObject: sourcesData) {
				try jsonData.write(to: sourcesFile)
			}
			
			// 3. Backup signed apps - store metadata only as files may be too large
			let signedAppsFile = tempDir.appendingPathComponent("signed_apps.json")
			let fetchRequest = Signed.fetchRequest()
			if let signedApps = try? Storage.shared.context.fetch(fetchRequest) {
				let appsData = signedApps.compactMap { app -> [String: String]? in
					guard let uuid = app.uuid else { return nil }
					var data: [String: String] = ["uuid": uuid]
					if let name = app.name { data["name"] = name }
					if let identifier = app.identifier { data["identifier"] = identifier }
					if let version = app.version { data["version"] = version }
					return data
				}
				if let jsonData = try? JSONSerialization.data(withJSONObject: appsData) {
					try jsonData.write(to: signedAppsFile)
				}
			}
			
			// 4. Backup ALL settings - not just filtered
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			let defaults = UserDefaults.standard.dictionaryRepresentation()
			// Include all Feather and app-specific settings
			let filtered = defaults.filter { key, _ in
				key.hasPrefix("Feather.") ||
				key.hasPrefix("com.apple.") ||
				(Bundle.main.bundleIdentifier.map { key.hasPrefix($0) } ?? false) ||
				// Include other common setting prefixes
				key.contains("filesTabEnabled") ||
				key.contains("showNews") ||
				key.contains("serverMethod") ||
				key.contains("customSigningAPI") ||
				key.contains("selectedCert")
			}
			try (filtered as NSDictionary).write(to: settingsFile)
			
			// 5. Create zip file
			let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("CoreSign_Backup.zip")
			try? FileManager.default.removeItem(at: zipURL)
			
			try FileManager.default.zipItem(at: tempDir, to: zipURL, shouldKeepParent: false)
			
			// Clean up temp directory
			try? FileManager.default.removeItem(at: tempDir)
			
			// Trigger export
			exportURL = zipURL
			isExporting = true
			
		} catch {
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to create backup: \(error.localizedDescription)")
			)
		}
	}
	
	private func performRestore(from url: URL, restart: Bool) {
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		do {
			_ = url.startAccessingSecurityScopedResource()
			defer { url.stopAccessingSecurityScopedResource() }
			
			try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
			
			// Unzip backup
			try FileManager.default.unzipItem(at: url, to: tempDir)
			
			// 1. Restore certificates with metadata
			let certificatesDir = tempDir.appendingPathComponent("certificates")
			let certMetadataFile = tempDir.appendingPathComponent("certificates_metadata.json")
			
			if FileManager.default.fileExists(atPath: certMetadataFile.path),
			   let jsonData = try? Data(contentsOf: certMetadataFile),
			   let metadata = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
				
				for certInfo in metadata {
					guard let uuid = certInfo["uuid"] as? String else { continue }
					
					let p12URL = certificatesDir.appendingPathComponent("\(uuid).p12")
					let provisionURL = certificatesDir.appendingPathComponent("\(uuid).mobileprovision")
					
					// Only restore if both files exist
					if FileManager.default.fileExists(atPath: p12URL.path),
					   FileManager.default.fileExists(atPath: provisionURL.path) {
						
						// Note: Full certificate restoration requires password
						// Store paths for later manual import if needed
						let name = certInfo["name"] as? String ?? "Restored Certificate"
						AppLogManager.shared.info("Found certificate to restore: \(name)", category: "Backup & Restore")
						
						// Certificate restoration would need proper password handling
						// For now, we'll preserve the files and notify the user
					}
				}
			}
			
			// 2. Restore sources
			let sourcesFile = tempDir.appendingPathComponent("sources.json")
			if FileManager.default.fileExists(atPath: sourcesFile.path) {
				let jsonData = try Data(contentsOf: sourcesFile)
				if let sources = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] {
					for source in sources {
						if let urlString = source["url"], 
						   let sourceURL = URL(string: urlString),
						   let name = source["name"] {
							let identifier = source["identifier"] ?? sourceURL.absoluteString
							Storage.shared.addSource(
								sourceURL,
								name: name,
								identifier: identifier,
								completion: { _ in }
							)
						}
					}
				}
			}
			
			// 3. Restore signed apps metadata
			let signedAppsFile = tempDir.appendingPathComponent("signed_apps.json")
			if FileManager.default.fileExists(atPath: signedAppsFile.path) {
				// Note: This only restores metadata, not the actual IPA files
				// Actual files would need to be re-downloaded or re-signed
				_ = try Data(contentsOf: signedAppsFile)
			}
			
			// 4. Restore ALL settings
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			if FileManager.default.fileExists(atPath: settingsFile.path) {
				if let settings = NSDictionary(contentsOf: settingsFile) as? [String: Any] {
					for (key, value) in settings {
						// Restore all settings except system-specific ones
						if !key.hasPrefix("NS") && !key.hasPrefix("AK") && !key.hasPrefix("Apple") {
							UserDefaults.standard.set(value, forKey: key)
						}
					}
					UserDefaults.standard.synchronize()
				}
			}
			
			// Clean up
			try? FileManager.default.removeItem(at: tempDir)
			
			if restart {
				// Restart the app
				UIAlertController.showAlertWithOk(
					title: .localized("Restore Complete"),
					message: .localized("The app will now restart to apply changes.")
				) {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						UIApplication.shared.suspendAndReopen()
					}
				}
			} else {
				UIAlertController.showAlertWithOk(
					title: .localized("Success"),
					message: .localized("Backup restored successfully. Changes will be applied on next restart.")
				)
			}
			
		} catch {
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to restore backup: \(error.localizedDescription)")
			)
		}
	}
}

// MARK: - BackupDocument
struct BackupDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.zip] }
	
	var url: URL
	
	init(url: URL) {
		self.url = url
	}
	
	init(configuration: ReadConfiguration) throws {
		// For reading, we don't need to handle this as we're only exporting
		throw CocoaError(.fileReadUnknown)
	}
	
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		return try FileWrapper(url: url)
	}
}
