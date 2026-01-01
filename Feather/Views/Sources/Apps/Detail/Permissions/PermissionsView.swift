import SwiftUI
import AltSourceKit
import NimbleViews

// MARK: - PermissionsView
struct PermissionsView: View {
    var appPermissions: ASRepository.App.AppPermissions
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let entitlements = appPermissions.entitlements, !entitlements.isEmpty {
                    NBSection(.localized("Entitlements")) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(entitlements, id: \.name) { entitlement in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                    
                                    Text(entitlement.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.quaternarySystemFill))
                        )
                    }
                } else {
                    NBSection(.localized("Entitlements")) {
                        Text(.localized("No Entitlements listed."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.quaternarySystemFill))
                            )
                    }
                }
                
                if let privacyItems = appPermissions.privacy, !privacyItems.isEmpty {
                    NBSection(.localized("Privacy Permissions")) {
                        VStack(spacing: 12) {
                            ForEach(privacyItems, id: \.self) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundStyle(.orange)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            Text(item.usageDescription)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(.quaternarySystemFill))
                                )
                            }
                        }
                    }
                } else {
                    NBSection(.localized("Privacy Permissions")) {
                        Text(.localized("No Privacy Permissions listed."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.quaternarySystemFill))
                            )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(.localized("Permissions"))
        .navigationBarTitleDisplayMode(.large)
    }
}
