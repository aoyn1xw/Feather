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
			ZStack {
				// Background gradient
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.05),
						Color.clear,
						Color.accentColor.opacity(0.02)
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
				
				Form {
					Section {} header: {
						VStack(spacing: 20) {
							// Enhanced certificate image with modern depth
							ZStack {
								// Outer glow with pulsing effect
								Circle()
									.fill(
										RadialGradient(
											colors: [
												Color.accentColor.opacity(0.2),
												Color.accentColor.opacity(0.1),
												Color.accentColor.opacity(0.05),
												Color.clear
											],
											center: .center,
											startRadius: 40,
											endRadius: 100
										)
									)
									.frame(width: 180, height: 180)
								
								// Certificate image container with gradient
								ZStack {
									// Background circle with gradient
									Circle()
										.fill(
											LinearGradient(
												colors: [
													Color(UIColor.secondarySystemGroupedBackground),
													Color(UIColor.tertiarySystemGroupedBackground)
												],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
										.frame(width: 120, height: 120)
									
									// Main image
									Image("Cert")
										.resizable()
										.scaledToFit()
										.frame(width: 100, height: 100)
								}
								.shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
							}
							.frame(maxWidth: .infinity, alignment: .center)
							
							VStack(spacing: 8) {
								Text(cert.nickname ?? "Certificate")
									.font(.title2)
									.fontWeight(.bold)
									.foregroundStyle(.primary)
								
								if let data = data {
									VStack(spacing: 6) {
										Text(data.TeamName)
											.font(.subheadline)
											.foregroundStyle(.secondary)
										
										// Status indicator with enhanced gradient
										HStack(spacing: 8) {
											ZStack {
												Circle()
													.fill(
														cert.revoked
															? LinearGradient(
																colors: [Color.red.opacity(0.2), Color.red.opacity(0.1)],
																startPoint: .topLeading,
																endPoint: .bottomTrailing
															)
															: LinearGradient(
																colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
																startPoint: .topLeading,
																endPoint: .bottomTrailing
															)
													)
													.frame(width: 20, height: 20)
												
												Circle()
													.fill(cert.revoked ? Color.red : Color.green)
													.frame(width: 10, height: 10)
											}
											
											Text(cert.revoked ? "Revoked" : "Active")
												.font(.subheadline)
												.foregroundStyle(cert.revoked ? .red : .green)
												.fontWeight(.semibold)
										}
										.padding(.horizontal, 16)
										.padding(.vertical, 8)
										.background(
											Capsule()
												.fill(
													(cert.revoked ? Color.red : Color.green).opacity(0.08)
												)
												.overlay(
													Capsule()
														.stroke(
															(cert.revoked ? Color.red : Color.green).opacity(0.3),
															lineWidth: 1
														)
												)
										)
										.shadow(color: (cert.revoked ? Color.red : Color.green).opacity(0.15), radius: 6, x: 0, y: 3)
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
						Button {
							UIApplication.open(Storage.shared.getUuidDirectory(for: cert)!.toSharedDocumentsURL()!)
						} label: {
							HStack(spacing: 12) {
								Image(systemName: "folder.fill.badge.gearshape")
									.font(.title3)
									.foregroundStyle(
										LinearGradient(
											colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
								Text(.localized("Open in Files"))
									.fontWeight(.medium)
								Spacer()
								Image(systemName: "arrow.up.right")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}
				}
				.scrollContentBackground(.hidden)
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
