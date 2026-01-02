import SwiftUI
import NimbleJSON
import NimbleViews

// MARK: - Extension: Model
extension ServerView {
	struct ServerPackModel: Decodable {
		var cert: String
		var ca: String
		var key: String
		var info: ServerPackInfo
		
		private enum CodingKeys: String, CodingKey {
			case cert, ca, key1, key2, info
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			cert = try container.decode(String.self, forKey: .cert)
			ca = try container.decode(String.self, forKey: .ca)
			let key1 = try container.decode(String.self, forKey: .key1)
			let key2 = try container.decode(String.self, forKey: .key2)
			key = key1 + key2
			info = try container.decode(ServerPackInfo.self, forKey: .info)
		}
		
		struct ServerPackInfo: Decodable {
			var issuer: Domains
			var domains: Domains
		}
		
		struct Domains: Decodable {
			var commonName: String
			
			private enum CodingKeys: String, CodingKey {
				case commonName = "commonName"
			}
		}
	}
}

// MARK: - View
struct ServerView: View {
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = false
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@AppStorage("Feather.customSigningAPI") private var _customSigningAPI: String = ""
	private let _serverMethods: [(name: String, description: String)] = [
		(.localized("Fully Local"), .localized("Signs and installs apps entirely on your device without external servers")),
		(.localized("Semi Local"), .localized("Signs locally but uses a local server for installation via Wi-Fi")),
		(.localized("Fully Remote"), .localized("Uses a remote server to sign and provides a direct installation link")),
		(.localized("Custom"), .localized("Use your own custom API endpoint for remote signing"))
	]
	
	private let _dataService = NBFetchService()
	private let _serverPackUrl = "https://backloop.dev/pack.json"
	
	@State private var _showSuccessAnimation = false
	
	// MARK: Body
	var body: some View {
		Group {
			Section {
				Picker(.localized("Server Type"), systemImage: "server.rack", selection: $_serverMethod) {
					ForEach(_serverMethods.indices, id: \.self) { index in
						VStack(alignment: .leading, spacing: 6) {
							HStack(spacing: 10) {
								ZStack {
									Circle()
										.fill(Color.accentColor.opacity(0.12))
										.frame(width: 32, height: 32)
									Image(systemName: serverIconForMethod(index))
										.foregroundStyle(Color.accentColor)
										.font(.system(size: 14, weight: .semibold))
								}
								Text(_serverMethods[index].name)
									.font(.body)
									.fontWeight(.medium)
							}
							Text(_serverMethods[index].description)
								.font(.caption)
								.foregroundStyle(.secondary)
								.padding(.leading, 42)
						}
						.padding(.vertical, 6)
						.tag(index)
					}
				}
				.pickerStyle(.inline)
				
				Toggle(.localized("Only use localhost address"), systemImage: "lifepreserver", isOn: $_ipFix)
					.disabled(_serverMethod != 1)
			} footer: {
				Text(_serverMethods[_serverMethod].description)
					.font(.caption)
			}
			
			// Custom API Section
			if _serverMethod == 3 {
				Section {
					VStack(alignment: .leading, spacing: 12) {
						HStack {
							Image(systemName: "link.circle.fill")
								.foregroundStyle(.accentColor)
								.font(.title3)
							Text(.localized("Custom Signing API URL"))
								.font(.subheadline)
								.fontWeight(.semibold)
						}
						
						TextField(.localized("https://your-api.com/sign"), text: $_customSigningAPI)
							.textInputAutocapitalization(.never)
							.autocorrectionDisabled()
							.keyboardType(.URL)
							.padding(12)
							.background(
								RoundedRectangle(cornerRadius: 10)
									.fill(Color(UIColor.tertiarySystemGroupedBackground))
							)
					}
					.padding(.vertical, 4)
				} header: {
					Label(.localized("Custom API Configuration"), systemImage: "gearshape.2.fill")
				} footer: {
					Text(.localized("Enter the URL of your custom signing API. The API should accept multipart/form-data with ipa, p12, mobileprovision files and return a JSON with 'directInstallLink' field."))
						.font(.caption)
				}
			}
			
			Section {
				Button(.localized("Update SSL Certificates"), systemImage: "arrow.down.doc") {
					FR.downloadSSLCertificates(from: _serverPackUrl) { success in
						DispatchQueue.main.async {
							if success {
								withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
									_showSuccessAnimation = true
								}
								DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
									withAnimation(.easeOut(duration: 0.3)) {
										_showSuccessAnimation = false
									}
								}
							} else {
								UIAlertController.showAlertWithOk(
									title: .localized("SSL Certificates"),
									message: .localized("Failed to download, check your internet connection and try again.")
								)
							}
						}
					}
				}
			} header: {
				Label(.localized("SSL Certificates"), systemImage: "lock.shield.fill")
			} footer: {
				Text(.localized("Download the latest SSL certificates for secure connections"))
					.font(.caption)
			}
			
			if _showSuccessAnimation {
				Section {
					HStack {
						Spacer()
						VStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(Color.green.opacity(0.15))
									.frame(width: 80, height: 80)
								
								Image(systemName: "checkmark.circle.fill")
									.font(.system(size: 50))
									.foregroundStyle(.green)
							}
							.scaleEffect(_showSuccessAnimation ? 1.0 : 0.5)
							.opacity(_showSuccessAnimation ? 1.0 : 0.0)
							.animation(.spring(response: 0.6, dampingFraction: 0.7), value: _showSuccessAnimation)
							
							Text(.localized("SSL certificates updated successfully!"))
								.font(.headline)
								.foregroundStyle(.green)
								.opacity(_showSuccessAnimation ? 1.0 : 0.0)
								.animation(.easeIn(duration: 0.3).delay(0.2), value: _showSuccessAnimation)
						}
						.padding(.vertical, 20)
						Spacer()
					}
				}
			}
		}
	}
	
	// Helper function to return appropriate icon for each server method
	private func serverIconForMethod(_ index: Int) -> String {
		switch index {
		case 0: return "iphone" // Fully Local
		case 1: return "wifi" // Semi Local
		case 2: return "cloud" // Fully Remote
		case 3: return "gearshape.2" // Custom
		default: return "server.rack"
		}
	}
}
