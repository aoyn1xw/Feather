import SwiftUI
import NimbleViews
import ZsignSwift

// MARK: - View
struct CertificatesInfoView: View {
	@Environment(\.dismiss) var dismiss
	@State var data: Certificate?
	@State private var showPPQInfo = false
	
	var cert: CertificatePair
	
	// MARK: Body
	var body: some View {
		NBNavigationView("", displayMode: .inline) {
			ScrollView {
				VStack(spacing: 16) {
					// Centered Header Title (no actions)
					Text(cert.nickname ?? "Certificate")
						.font(.title)
						.fontWeight(.bold)
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
				.foregroundStyle(.primary)
				.fixedSize(horizontal: false, vertical: true)
			
			Divider()
			
			// App ID row
			HStack {
				Text(.localized("App ID"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
				Spacer()
				Text(data.AppIDName)
					.font(.subheadline)
					.foregroundStyle(.primary)
					.multilineTextAlignment(.trailing)
			}
		}
		.padding(16)
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Status Card
	@ViewBuilder
	private func statusCard(data: Certificate) -> some View {
		VStack(spacing: 0) {
			// Active/Revoked status
			HStack {
				Text(.localized("Status"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
				Spacer()
				HStack(spacing: 6) {
					Circle()
						.fill(cert.revoked ? Color.red : Color.green)
						.frame(width: 8, height: 8)
					Text(cert.revoked ? "Revoked" : "Active")
						.font(.subheadline)
						.foregroundStyle(cert.revoked ? .red : .green)
						.fontWeight(.medium)
				}
			}
			.padding(12)
			
			Divider()
				.padding(.leading, 12)
			
			// PPQ Check status
			if let ppq = data.PPQCheck {
				HStack {
					Text(.localized("PPQ Check"))
						.font(.subheadline)
						.foregroundStyle(.secondary)
					Spacer()
					HStack(spacing: 6) {
						Image(systemName: ppq ? "checkmark.circle.fill" : "xmark.circle.fill")
							.foregroundStyle(ppq ? .orange : .green)
							.font(.caption)
						Text(ppq ? "Yes" : "No")
							.font(.subheadline)
							.foregroundStyle(ppq ? .orange : .green)
							.fontWeight(.medium)
					}
				}
				.padding(12)
			}
		}
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Team Information Card
	@ViewBuilder
	private func teamInformationCard(data: Certificate) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			// Team Name
			VStack(alignment: .leading, spacing: 4) {
				Text(.localized("Team Name"))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(data.TeamName)
					.font(.subheadline)
					.foregroundStyle(.primary)
			}
			.padding(12)
			
			Divider()
				.padding(.leading, 12)
			
			// Team Identifier
			VStack(alignment: .leading, spacing: 4) {
				Text(.localized("Team Identifier"))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(data.TeamIdentifier.joined(separator: ", "))
					.font(.subheadline)
					.foregroundStyle(.primary)
			}
			.padding(12)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Validity Card
	@ViewBuilder
	private func validityCard(data: Certificate) -> some View {
		VStack(spacing: 12) {
			// Created and Expires on one row
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text(.localized("Created"))
						.font(.caption)
						.foregroundStyle(.secondary)
					Text(data.CreationDate.formatted(date: .abbreviated, time: .omitted))
						.font(.subheadline)
						.foregroundStyle(.primary)
				}
				
				Spacer()
				
				VStack(alignment: .trailing, spacing: 4) {
					Text(.localized("Expires"))
						.font(.caption)
						.foregroundStyle(.secondary)
					Text(data.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
						.font(.subheadline)
						.foregroundStyle(data.ExpirationDate.expirationInfo().color)
				}
			}
			
			// Progress bar
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					RoundedRectangle(cornerRadius: 4)
						.fill(Color.secondary.opacity(0.2))
						.frame(height: 6)
					
					let progress = calculateProgress(created: data.CreationDate, expires: data.ExpirationDate)
					RoundedRectangle(cornerRadius: 4)
						.fill(progressColor(for: progress))
						.frame(width: geometry.size.width * CGFloat(progress), height: 6)
				}
			}
			.frame(height: 6)
			
			// Remaining days and total days
			HStack {
				Text(data.ExpirationDate.expirationInfo().formatted)
					.font(.caption)
					.foregroundStyle(data.ExpirationDate.expirationInfo().color)
				
				Spacer()
				
				let totalDays = Calendar.current.dateComponents([.day], from: data.CreationDate, to: data.ExpirationDate).day ?? 0
				Text("\(totalDays) days total")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.padding(12)
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	// MARK: - Platform Card
	@ViewBuilder
	private func platformCard(data: Certificate) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(.localized("Platform"))
				.font(.subheadline)
				.fontWeight(.semibold)
				.foregroundStyle(.primary)
			
			// Platform pills
			FlowLayout(spacing: 8) {
				ForEach(data.Platform, id: \.self) { platform in
					Text(platform)
						.font(.caption)
						.fontWeight(.medium)
						.foregroundStyle(.white)
						.padding(.horizontal, 12)
						.padding(.vertical, 6)
						.background(
							Capsule()
								.fill(Color.accentColor)
						)
				}
			}
		}
		.padding(12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
					.foregroundStyle(.accentColor)
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
					.foregroundStyle(.accentColor)
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
			// Header
			HStack {
				Text(.localized("Entitlements"))
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.primary)
				Spacer()
				Text("\(entitlements.count)")
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.accentColor)
			}
			.padding(12)
			
			Divider()
			
			// Entitlements list
			ForEach(Array(entitlements.keys.sorted().enumerated()), id: \.offset) { index, key in
				if let value = entitlements[key]?.value {
					VStack(alignment: .leading, spacing: 4) {
						Text(key)
							.font(.subheadline)
							.fontWeight(.medium)
							.foregroundStyle(.primary)
						Text(String(describing: value))
							.font(.caption)
							.foregroundStyle(.secondary)
							.lineLimit(3)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					
					if index < entitlements.count - 1 {
						Divider()
							.padding(.leading, 12)
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
					.foregroundStyle(.accentColor)
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
