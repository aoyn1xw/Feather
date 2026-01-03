import SwiftUI
import NimbleViews
import ZsignSwift

// MARK: - Entitlement Mapping Helper
struct EntitlementMapping {
	static func humanReadableName(for entitlement: String) -> String {
		let mappings: [String: String] = [
			"com.apple.developer.applesignin": "Sign in with Apple",
			"com.apple.developer.associated-domains": "Associated Domains",
			"com.apple.developer.authentication-services.autofill-credential-provider": "AutoFill Credential Provider",
			"com.apple.developer.default-data-protection": "Default Data Protection",
			"com.apple.developer.healthkit": "HealthKit",
			"com.apple.developer.homekit": "HomeKit",
			"com.apple.developer.icloud-container-identifiers": "iCloud Container Identifiers",
			"com.apple.developer.icloud-services": "iCloud Services",
			"com.apple.developer.in-app-payments": "In-App Payments",
			"com.apple.developer.networking.wifi-info": "Wi-Fi Information",
			"com.apple.developer.networking.networkextension": "Network Extension",
			"com.apple.developer.networking.vpn.api": "VPN API",
			"com.apple.developer.nfc.readersession.formats": "NFC Reader Session",
			"com.apple.developer.pass-type-identifiers": "Pass Type Identifiers",
			"com.apple.developer.siri": "Siri",
			"com.apple.developer.usernotifications.filtering": "User Notifications Filtering",
			"com.apple.developer.usernotifications.time-sensitive": "Time-Sensitive Notifications",
			"com.apple.external-accessory.wireless-configuration": "External Accessory Wireless Configuration",
			"com.apple.security.application-groups": "App Groups",
			"keychain-access-groups": "Keychain Access Groups",
			"aps-environment": "Push Notifications",
			"com.apple.developer.game-center": "Game Center",
			"com.apple.developer.maps": "Maps",
			"com.apple.developer.ClassKit-environment": "ClassKit",
			"com.apple.developer.devicecheck.appattest-environment": "App Attest",
			"com.apple.developer.kernel.extended-virtual-addressing": "Extended Virtual Addressing",
			"com.apple.developer.networking.multipath": "Multipath Networking",
			"com.apple.developer.associated-domains.mdm-managed": "MDM Managed Associated Domains",
			"com.apple.developer.automatic-assessment-configuration": "Automatic Assessment Configuration",
			"com.apple.developer.group-session": "Group Activities",
			"com.apple.developer.contacts.notes": "Contacts Notes",
			"com.apple.developer.shared-with-you": "Shared with You",
			"com.apple.developer.family-controls": "Family Controls",
			"com.apple.developer.proximity-reader.payment.acceptance": "Tap to Pay on iPhone",
			"inter-app-audio": "Inter-App Audio",
			"com.apple.developer.carplay-audio": "CarPlay Audio",
			"com.apple.developer.carplay-communication": "CarPlay Communication",
			"com.apple.developer.carplay-messaging": "CarPlay Messaging",
			"com.apple.developer.carplay-navigation": "CarPlay Navigation",
			"com.apple.developer.carplay-parking": "CarPlay Parking",
			"com.apple.developer.carplay-playback": "CarPlay Playback",
			"com.apple.developer.coremedia.hls.low-latency": "Low-Latency HLS",
			"com.apple.developer.weatherkit": "WeatherKit"
		]
		return mappings[entitlement] ?? entitlement
	}
}

// MARK: - View
struct CertificatesInfoView: View {
	@Environment(\.dismiss) var dismiss
	@State var data: Certificate?
	@State private var showPPQInfo = false
	@State private var isEntitlementsExpanded = false
	
	var cert: CertificatePair
	
	// MARK: Body
	var body: some View {
		NBNavigationView("", displayMode: .inline) {
			ScrollView {
				VStack(spacing: 16) {
					// Centered Header Title (smaller for native sheet look)
					Text(cert.nickname ?? "Certificate")
						.font(.title3)
						.fontWeight(.semibold)
						.foregroundStyle(.primary)
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.top, 8)
					
					if let data = data {
						// Main Certificate Identifier Card
						mainIdentifierCard(data: data)
						
						// Status Card
						statusCard(data: data)
						
						// Team Information Card
						teamInformationCard(data: data)
						
						// Validity Card
						validityCard(data: data)
						
						// Platform Card
						platformCard(data: data)
						
						// Provisioned Devices Card
						if let devices = data.ProvisionedDevices, !devices.isEmpty {
							provisionedDevicesCard(devices: devices)
						}
						
						// Developer Certificates Card
						developerCertificatesCard()
						
						// Entitlements Card
						if let entitlements = data.Entitlements {
							entitlementsCard(entitlements: entitlements)
						}
						
						// Open in Files Section
						openInFilesCard()
					}
				}
				.padding(.horizontal, 16)
				.padding(.bottom, 20)
			}
			.background(Color(UIColor.systemGroupedBackground))
		}
		.toolbar {
			NBToolbarButton(role: .close)
		}
		.alert(.localized("What is PPQ?"), isPresented: $showPPQInfo) {
			Button(.localized("OK"), role: .cancel) {}
		} message: {
			Text(.localized("PPQ is a check Apple has added to certificates. If you have this check, change your Bundle IDs when signing apps to avoid Apple revoking your certificates."))
		}
		.onAppear {
			data = Storage.shared.getProvisionFileDecoded(for: cert)
		}
	}
	
	// MARK: - Main Certificate Identifier Card
	@ViewBuilder
	private func mainIdentifierCard(data: Certificate) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			// Main certificate identifier - large bold multiline
			Text(data.Name)
				.font(.title2)
				.fontWeight(.bold)
				.foregroundStyle(
					LinearGradient(
						colors: [Color.primary, Color.primary.opacity(0.8)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
				.fixedSize(horizontal: false, vertical: true)
			
			Divider()
			
			// App ID row
			HStack {
				HStack(spacing: 6) {
					Image(systemName: "app.badge.fill")
						.font(.caption)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("App ID"))
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
				Text(data.AppIDName)
					.font(.subheadline)
					.foregroundStyle(.primary)
					.multilineTextAlignment(.trailing)
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
	}
	
	// MARK: - Status Card
	@ViewBuilder
	private func statusCard(data: Certificate) -> some View {
		VStack(spacing: 0) {
			// Active/Revoked status
			HStack {
				HStack(spacing: 6) {
					Image(systemName: cert.revoked ? "xmark.circle.fill" : "checkmark.circle.fill")
						.font(.caption)
						.foregroundStyle(
							LinearGradient(
								colors: cert.revoked ? [Color.red, Color.red.opacity(0.7)] : [Color.green, Color.green.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Status"))
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
				HStack(spacing: 6) {
					Circle()
						.fill(
							LinearGradient(
								colors: cert.revoked ? [Color.red, Color.red.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 8, height: 8)
					Text(cert.revoked ? "Revoked" : "Active")
						.font(.subheadline)
						.foregroundStyle(
							LinearGradient(
								colors: cert.revoked ? [Color.red, Color.red.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.fontWeight(.medium)
				}
			}
			.padding(12)
			
			Divider()
				.padding(.leading, 12)
			
			// PPQ Check status
			if let ppq = data.PPQCheck {
				HStack {
					HStack(spacing: 6) {
						Image(systemName: ppq ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
							.font(.caption)
							.foregroundStyle(
								LinearGradient(
									colors: ppq ? [Color.orange, Color.orange.opacity(0.7)] : [Color.green, Color.green.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						Text(.localized("PPQ Check"))
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					Spacer()
					HStack(spacing: 6) {
						Image(systemName: ppq ? "checkmark.circle.fill" : "xmark.circle.fill")
							.foregroundStyle(
								LinearGradient(
									colors: ppq ? [Color.orange, Color.orange.opacity(0.7)] : [Color.green, Color.green.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.font(.caption)
						Text(ppq ? "Yes" : "No")
							.font(.subheadline)
							.foregroundStyle(
								LinearGradient(
									colors: ppq ? [Color.orange, Color.orange.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.fontWeight(.medium)
					}
				}
				.padding(12)
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
	}
	
	// MARK: - Team Information Card
	@ViewBuilder
	private func teamInformationCard(data: Certificate) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Team Name
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 6) {
					Image(systemName: "person.3.fill")
						.font(.caption2)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.blue, Color.blue.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Team Name"))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				Text(data.TeamName)
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.primary, Color.primary.opacity(0.8)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
			}
			.padding(12)
			
			Divider()
				.padding(.leading, 12)
			
			// Team Identifier
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 6) {
					Image(systemName: "tag.fill")
						.font(.caption2)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.purple, Color.purple.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Team Identifier"))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				Text(data.TeamIdentifier.joined(separator: ", "))
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.primary, Color.primary.opacity(0.8)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
			}
			.padding(12)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
	}
	
	// MARK: - Validity Card
	@ViewBuilder
	private func validityCard(data: Certificate) -> some View {
		VStack(spacing: 12) {
			// Created and Expires on one row
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					HStack(spacing: 4) {
						Image(systemName: "calendar.badge.plus")
							.font(.caption2)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.green, Color.green.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						Text(.localized("Created"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					Text(data.CreationDate.formatted(date: .abbreviated, time: .omitted))
						.font(.subheadline)
						.foregroundStyle(.primary)
				}
				
				Spacer()
				
				VStack(alignment: .trailing, spacing: 4) {
					HStack(spacing: 4) {
						Image(systemName: "calendar.badge.exclamationmark")
							.font(.caption2)
							.foregroundStyle(
								LinearGradient(
									colors: [data.ExpirationDate.expirationInfo().color, data.ExpirationDate.expirationInfo().color.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						Text(.localized("Expires"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					Text(data.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
						.font(.subheadline)
						.foregroundStyle(
							LinearGradient(
								colors: [data.ExpirationDate.expirationInfo().color, data.ExpirationDate.expirationInfo().color.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				}
			}
			
			// Progress bar
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					RoundedRectangle(cornerRadius: 4)
						.fill(
							LinearGradient(
								colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.15)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.frame(height: 6)
					
					let progress = calculateProgress(created: data.CreationDate, expires: data.ExpirationDate)
					RoundedRectangle(cornerRadius: 4)
						.fill(
							LinearGradient(
								colors: [progressColor(for: progress), progressColor(for: progress).opacity(0.7)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.frame(width: geometry.size.width * CGFloat(progress), height: 6)
				}
			}
			.frame(height: 6)
			
			// Remaining days and total days
			HStack {
				Text(data.ExpirationDate.expirationInfo().formatted)
					.font(.caption)
					.foregroundStyle(
						LinearGradient(
							colors: [data.ExpirationDate.expirationInfo().color, data.ExpirationDate.expirationInfo().color.opacity(0.8)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
				
				Spacer()
				
				let totalDays = Calendar.current.dateComponents([.day], from: data.CreationDate, to: data.ExpirationDate).day ?? 0
				Text("\(totalDays) days total")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [Color.green.opacity(0.15), Color.orange.opacity(0.15)],
						startPoint: .leading,
						endPoint: .trailing
					),
					lineWidth: 1
				)
		)
	}
	
	// MARK: - Platform Card
	@ViewBuilder
	private func platformCard(data: Certificate) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 6) {
				Image(systemName: "square.stack.3d.up.fill")
					.font(.caption)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Platform"))
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.primary, Color.primary.opacity(0.8)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
			}
			
			// Platform pills with icons
			FlowLayout(spacing: 8) {
				ForEach(data.Platform, id: \.self) { platform in
					HStack(spacing: 6) {
						Image(systemName: platformIcon(for: platform))
							.font(.caption)
							.foregroundStyle(.white)
						Text(platform)
							.font(.caption)
							.fontWeight(.medium)
							.foregroundStyle(.white)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(
						Capsule()
							.fill(
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
					)
					.shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
				}
			}
		}
		.padding(12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
	}
	
	// MARK: - Helper for Platform Icons
	private func platformIcon(for platform: String) -> String {
		let lowercased = platform.lowercased()
		if lowercased.contains("ios") {
			return "iphone"
		} else if lowercased.contains("visionos") || lowercased.contains("vision") {
			return "visionpro"
		} else if lowercased.contains("macos") || lowercased.contains("mac") {
			return "desktopcomputer"
		} else if lowercased.contains("tvos") || lowercased.contains("tv") {
			return "appletv"
		} else if lowercased.contains("watchos") || lowercased.contains("watch") {
			return "applewatch"
		} else if lowercased.contains("ipados") || lowercased.contains("ipad") {
			return "ipad"
		} else {
			return "app.badge"
		}
	}
	
	// MARK: - Provisioned Devices Card
	@ViewBuilder
	private func provisionedDevicesCard(devices: [String]) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			HStack {
				Text(.localized("Provisioned Devices"))
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.primary)
				Spacer()
				Text("\(devices.count)")
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.tint)
			}
			.padding(12)
			
			Divider()
			
			// Device list
			ForEach(Array(devices.enumerated()), id: \.offset) { index, device in
				HStack {
					Text("\(index + 1)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(width: 30, alignment: .leading)
					Text(device)
						.font(.subheadline)
						.foregroundStyle(.primary)
					Spacer()
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
				
				if index < devices.count - 1 {
					Divider()
						.padding(.leading, 42)
				}
			}
		}
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Developer Certificates Card
	@ViewBuilder
	private func developerCertificatesCard() -> some View {
		if let data = data, let certs = data.DeveloperCertificates {
			HStack {
				Text(.localized("Developer Certificates"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
				Spacer()
				Text("\(certs.count)")
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.tint)
			}
			.padding(12)
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
	}
	
	// MARK: - Entitlements Card
	@ViewBuilder
	private func entitlementsCard(entitlements: [String: AnyCodable]) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header with expand/collapse button
			Button {
				withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
					isEntitlementsExpanded.toggle()
				}
			} label: {
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						Text(.localized("Entitlements"))
							.font(.subheadline)
							.fontWeight(.semibold)
							.foregroundStyle(.primary)
						Text("Security Capabilities")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					HStack(spacing: 8) {
						Text("\(entitlements.count)")
							.font(.subheadline)
							.fontWeight(.semibold)
							.foregroundStyle(.tint)
						
						Image(systemName: isEntitlementsExpanded ? "chevron.up" : "chevron.down")
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundStyle(.secondary)
					}
				}
				.padding(12)
			}
			.buttonStyle(.plain)
			
			if isEntitlementsExpanded {
				Divider()
				
				// Entitlements list
				ForEach(Array(entitlements.keys.sorted().enumerated()), id: \.offset) { index, key in
					if let value = entitlements[key]?.value {
						VStack(alignment: .leading, spacing: 4) {
							Text(EntitlementMapping.humanReadableName(for: key))
								.font(.subheadline)
								.fontWeight(.medium)
								.foregroundStyle(.primary)
							Text(key)
								.font(.caption2)
								.foregroundStyle(.secondary)
							Text(String(describing: value))
								.font(.caption)
								.foregroundStyle(.secondary.opacity(0.8))
								.lineLimit(3)
						}
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.transition(.opacity.combined(with: .move(edge: .top)))
						
						if index < entitlements.count - 1 {
							Divider()
								.padding(.leading, 12)
						}
					}
				}
			}
		}
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Open in Files Card
	@ViewBuilder
	private func openInFilesCard() -> some View {
		Button {
			UIApplication.open(Storage.shared.getUuidDirectory(for: cert)!.toSharedDocumentsURL()!)
		} label: {
			HStack {
				Image(systemName: "folder.fill")
					.foregroundStyle(.tint)
					.font(.title3)
				Text(.localized("Open in Files"))
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundStyle(.primary)
				Spacer()
				Image(systemName: "arrow.up.right")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.padding(12)
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
		.buttonStyle(.plain)
	}
	
	// MARK: - Helper Functions
	private func calculateProgress(created: Date, expires: Date) -> Double {
		let total = expires.timeIntervalSince(created)
		let elapsed = Date().timeIntervalSince(created)
		return min(max(elapsed / total, 0), 1)
	}
	
	private func progressColor(for progress: Double) -> Color {
		if progress > 0.75 {
			return .red
		} else if progress > 0.5 {
			return .orange
		} else {
			return .green
		}
	}
}

// MARK: - FlowLayout (for platform pills)
struct FlowLayout: Layout {
	var spacing: CGFloat = 8
	
	// Default max width for unlimited width scenarios
	private static let defaultMaxWidth: CGFloat = 1000
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
		var totalHeight: CGFloat = 0
		var totalWidth: CGFloat = 0
		var lineWidth: CGFloat = 0
		var lineHeight: CGFloat = 0
		
		// Use a reasonable default width if proposal.width is nil (unlimited)
		let maxWidth = proposal.width ?? Self.defaultMaxWidth
		
		for size in sizes {
			if lineWidth + size.width > maxWidth {
				totalHeight += lineHeight + spacing
				lineWidth = size.width
				lineHeight = size.height
			} else {
				lineWidth += size.width + spacing
				lineHeight = max(lineHeight, size.height)
			}
			totalWidth = max(totalWidth, lineWidth)
		}
		totalHeight += lineHeight
		
		return CGSize(width: totalWidth, height: totalHeight)
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		var lineX = bounds.minX
		var lineY = bounds.minY
		var lineHeight: CGFloat = 0
		
		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			
			if lineX + size.width > bounds.maxX && lineX > bounds.minX {
				lineY += lineHeight + spacing
				lineHeight = 0
				lineX = bounds.minX
			}
			
			subview.place(
				at: CGPoint(x: lineX, y: lineY),
				proposal: ProposedViewSize(size)
			)
			
			lineHeight = max(lineHeight, size.height)
			lineX += size.width + spacing
		}
	}
}
