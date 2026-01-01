import Foundation
import ZsignSwift
import UIKit

final class ZsignHandler {
	private var _appUrl: URL
	private var _options: Options
	private var _certificate: CertificatePair?
	
	init(
		appUrl: URL,
		options: Options = OptionsManager.shared.options,
		cert: CertificatePair? = nil
	) {
		self._appUrl = appUrl
		self._options = options
		self._certificate = cert
	}
	
	func disinject() async throws {
		guard !_options.disInjectionFiles.isEmpty else {
			return
		}
		
		let bundle = Bundle(url: _appUrl)
		let execPath = _appUrl.appendingPathComponent(bundle?.exec ?? "").relativePath
		
		if !Zsign.removeDylibs(appExecutable: execPath, using: _options.disInjectionFiles) {
			throw SigningFileHandlerError.disinjectFailed
		}
	}
	
	func sign() async throws {
		guard let cert = _certificate else {
			throw SigningFileHandlerError.missingCertifcate
		}

		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			Zsign.sign(
				appPath: _appUrl.relativePath,
				provisionPath: Storage.shared.getFile(.provision, from: cert)?.path ?? "",
				p12Path: Storage.shared.getFile(.certificate, from: cert)?.path ?? "",
				p12Password: cert.password ?? "",
				entitlementsPath: _options.appEntitlementsFile?.path ?? "",
				removeProvision: !_options.removeProvisioning,
				completion: { success, error in
					if let error {
						continuation.resume(throwing: error)
					} else if !success {
						continuation.resume(throwing: SigningFileHandlerError.signFailed)
					} else {
						continuation.resume()
					}
				}
			)
		}
	}
	
	func adhocSign() async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			Zsign.sign(
				appPath: _appUrl.relativePath,
				entitlementsPath: _options.appEntitlementsFile?.path ?? "",
				adhoc: true,
				removeProvision: !_options.removeProvisioning,
				completion: { success, error in
					if let error {
						continuation.resume(throwing: error)
					} else if !success {
						continuation.resume(throwing: SigningFileHandlerError.signFailed)
					} else {
						continuation.resume()
					}
				}
			)
		}
	}
}
