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
							.padding(.vertical, 4)
					}
				}
			} header: {
				HStack {
					Image(systemName: "key.fill")
						.foregroundStyle(.accent)
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
