import Foundation
import UIKit
import OSLog
import CoreData

enum RemoteSigningError: Error, LocalizedError {
    case appNotFound
    case missingCertificate
    case missingProvisioningProfile
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .appNotFound: return "Unable to locate app file."
        case .missingCertificate: return "Certificate file not found."
        case .missingProvisioningProfile: return "Provisioning profile not found."
        case .invalidResponse: return "Invalid response from server."
        case .serverError(let message): return "Server error: \(message)"
        }
    }
}

struct RemoteSigningResponse: Codable {
    let installLink: String
    let directInstallLink: String
}

final class RemoteSigningHandler: NSObject {
    private let _app: AppInfoPresentable
    private let _certificate: CertificatePair
    private let _options: Options
    
    init(app: AppInfoPresentable, certificate: CertificatePair, options: Options) {
        self._app = app
        self._certificate = certificate
        self._options = options
        super.init()
    }
    
    func sign() async throws -> RemoteSigningResponse {
        guard let appURL = Storage.shared.getAppDirectory(for: _app) else {
            throw RemoteSigningError.appNotFound
        }
        
        guard let p12URL = Storage.shared.getFile(.certificate, from: _certificate) else {
            throw RemoteSigningError.missingCertificate
        }
        
        guard let provisionURL = Storage.shared.getFile(.provision, from: _certificate) else {
            throw RemoteSigningError.missingProvisioningProfile
        }
        
        let url = URL(string: "https://sign.ayon1xw.me/sign")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // IPA File
        if let ipaData = try? Data(contentsOf: appURL) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"ipa\"; filename=\"\(appURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            data.append(ipaData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        // P12 File
        if let p12Data = try? Data(contentsOf: p12URL) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"p12\"; filename=\"cert.p12\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/x-pkcs12\r\n\r\n".data(using: .utf8)!)
            data.append(p12Data)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        // Mobile Provision
        if let provisionData = try? Data(contentsOf: provisionURL) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"mobileprovision\"; filename=\"profile.mobileprovision\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/x-apple-aspen-config\r\n\r\n".data(using: .utf8)!)
            data.append(provisionData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        // Password
        if let password = _certificate.password {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"p12_password\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(password)\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw RemoteSigningError.serverError(errorMessage)
        }
        
        return try JSONDecoder().decode(RemoteSigningResponse.self, from: responseData)
    }
}
