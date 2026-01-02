import SwiftUI
import NimbleViews
import ZsignSwift

// MARK: - View
struct CertificatesInfoView: View {
	@Environment(\.dismiss) var dismiss
	@State var data: Certificate?
	
	var cert: CertificatePair
	
	// MARK: Body
    var body: some View {
		NBNavigationView(cert.nickname ?? "", displayMode: .inline) {
			Form {
				Section {} header: {
					VStack(spacing: 20) {
						// Enhanced certificate image with modern depth
						ZStack {
							// Outer glow
							Circle()
								.fill(
									RadialGradient(
										colors: [
											Color.accentColor.opacity(0.15),
											Color.accentColor.opacity(0.05),
											Color.clear
										],
										center: .center,
										startRadius: 60,
										endRadius: 120
									)
								)
								.frame(width: 160, height: 160)
							
							// Certificate image container
							ZStack {
								// Background circle
								Circle()
									.fill(Color(UIColor.secondarySystemGroupedBackground))
									.frame(width: 120, height: 120)
								
								// Main image
								Image("Cert")
									.resizable()
									.scaledToFit()
									.frame(width: 100, height: 100)
							}
							.shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
						}
						.frame(maxWidth: .infinity, alignment: .center)
						
						VStack(spacing: 8) {
							Text(cert.nickname ?? "Certificate")
								.font(.title3)
								.fontWeight(.bold)
								.foregroundStyle(.primary)
							
							if let data = data {
								VStack(spacing: 4) {
									Text(data.TeamName)
										.font(.subheadline)
										.foregroundStyle(.secondary)
									
									// Status indicator
									HStack(spacing: 6) {
										Circle()
											.fill(cert.revoked ? Color.red : Color.green)
											.frame(width: 8, height: 8)
										Text(cert.revoked ? "Revoked" : "Active")
											.font(.caption)
											.foregroundStyle(cert.revoked ? .red : .green)
											.fontWeight(.semibold)
									}
									.padding(.horizontal, 12)
									.padding(.vertical, 6)
									.background(
										Capsule()
											.fill((cert.revoked ? Color.red : Color.green).opacity(0.12))
									)
									.padding(.top, 4)
								}
							}
						}
					}
					.padding(.vertical, 12)
				}
				
				if let data {
					_infoSection(data: data)
					_entitlementsSection(data: data)
					_miscSection(data: data)
				}
				
				Section {
					Button(.localized("Open in Files"), systemImage: "folder") {
						UIApplication.open(Storage.shared.getUuidDirectory(for: cert)!.toSharedDocumentsURL()!)
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
		.onAppear {
			data = Storage.shared.getProvisionFileDecoded(for: cert)
		}
    }
}

// MARK: - Extension: View
extension CertificatesInfoView {
	@ViewBuilder
	private func _infoSection(data: Certificate) -> some View {
		NBSection(.localized("Info")) {
			_info(.localized("Name"), description: data.Name)
			_info(.localized("AppID Name"), description: data.AppIDName)
			_info(.localized("Team Name"), description: data.TeamName)
		}
		
		Section {
			_info(.localized("Expires"), description: data.ExpirationDate.expirationInfo().formatted)
				.foregroundStyle(data.ExpirationDate.expirationInfo().color)
			
			_info(.localized("Revoked"), description: cert.revoked ? "✓" : "✗")
			
			if let ppq = data.PPQCheck {
				_info(.localized("PPQCheck"), description: ppq ? "✓" : "✗")
			}
		}
	}
	
	@ViewBuilder
	private func _entitlementsSection(data: Certificate) -> some View {
		if let entitlements = data.Entitlements {
			Section {
				NavigationLink(.localized("View Entitlements")) {
					CertificatesInfoEntitlementView(entitlements: entitlements)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _miscSection(data: Certificate) -> some View {
		NBSection(.localized("Misc")) {
			_disclosure(.localized("Platform"), keys: data.Platform)
			
			if let all = data.ProvisionsAllDevices {
				_info(.localized("Provision All Devices"), description: all.description)
			}
			
			if let devices = data.ProvisionedDevices {
				_disclosure(.localized("Provisioned Devices"), keys: devices)
			}
			
			_disclosure(.localized("Team Identifiers"), keys: data.TeamIdentifier)
			
			if let prefix = data.ApplicationIdentifierPrefix{
				_disclosure(.localized("Identifier Prefix"), keys: prefix)
			}
		}
	}
	
	@ViewBuilder
	private func _info(_ title: String, description: String) -> some View {
		LabeledContent(title) {
			Text(description)
		}
		.copyableText(description)
	}
	
	@ViewBuilder
	private func _disclosure(_ title: String, keys: [String]) -> some View {
		DisclosureGroup(title) {
			ForEach(keys, id: \.self) { key in
				Text(key)
					.foregroundStyle(.secondary)
					.copyableText(key)
			}
		}
	}
}
