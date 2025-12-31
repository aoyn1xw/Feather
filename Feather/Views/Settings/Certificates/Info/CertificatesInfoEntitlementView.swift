import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesInfoEntitlementView: View {
	let entitlements: [String: AnyCodable]
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Entitlements")) {
			Section {
				ForEach(entitlements.keys.sorted(), id: \.self) { key in
					if let value = entitlements[key]?.value {
						CertificatesInfoEntitlementCellView(key: key, value: value)
							.padding(.vertical, 6)
					}
				}
			} header: {
				HStack {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 32, height: 32)
						
						Image(systemName: "key.fill")
							.font(.system(size: 14))
							.foregroundStyle(Color.accentColor)
					}
					
					Text("\(entitlements.count) Entitlements")
						.font(.subheadline)
						.fontWeight(.semibold)
				}
				.textCase(.none)
				.foregroundStyle(.primary)
			}
		}
		.listStyle(.insetGrouped)
	}
}
