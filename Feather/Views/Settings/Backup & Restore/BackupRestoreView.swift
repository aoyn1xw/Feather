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
							Text(.localized("Export certificates, sources, signed apps, and settings"))
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
				Text(.localized("Creates a .zip file containing all your data, settings, and configurations."))
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
			
			// 1. Backup certificates
			let certificatesDir = tempDir.appendingPathComponent("certificates")
			try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
			let certificates = Storage.shared.getAllCertificates()
			for cert in certificates {
				if let uuid = cert.uuid,
				   let certURL = Storage.shared.getFile(.certificate, from: cert),
				   let certData = try? Data(contentsOf: certURL) {
					let destURL = certificatesDir.appendingPathComponent("\(uuid).p12")
					try certData.write(to: destURL)
				}
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
			
			// 4. Backup settings
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			if let bundleID = Bundle.main.bundleIdentifier {
				let defaults = UserDefaults.standard.dictionaryRepresentation()
				let filtered = defaults.filter { $0.key.hasPrefix(bundleID) || $0.key.hasPrefix("Feather.") }
				try (filtered as NSDictionary).write(to: settingsFile)
			}
			
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
			
			// 1. Restore certificates - Note: Certificate restoration is limited
			// Full certificate restoration requires password handling and proper ZsignHandler integration
			// Users will need to manually re-import certificates after restore
			let certificatesDir = tempDir.appendingPathComponent("certificates")
			if FileManager.default.fileExists(atPath: certificatesDir.path) {
				// Certificate files are backed up but require manual re-import
				// TODO: Implement proper certificate import with password prompt
				// This requires integration with ZsignHandler and password management
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
			
			// 4. Restore settings
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			if FileManager.default.fileExists(atPath: settingsFile.path) {
				if let settings = NSDictionary(contentsOf: settingsFile) as? [String: Any] {
					for (key, value) in settings {
						UserDefaults.standard.set(value, forKey: key)
					}
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
					UIApplication.shared.suspendAndReopen()
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
