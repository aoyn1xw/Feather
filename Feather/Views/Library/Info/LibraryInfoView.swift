import SwiftUI
import NimbleViews
import Zsign

// MARK: - View
struct LibraryInfoView: View {
	var app: AppInfoPresentable
	
	// MARK: Body
    var body: some View {
		NBNavigationView(app.name ?? "", displayMode: .inline) {
			List {
				Section {} header: {
					VStack(spacing: 16) {
						FRAppIconView(app: app, size: 100)
						
						VStack(spacing: 4) {
							Text(app.name ?? .localized("Unknown"))
								.font(.title2)
								.fontWeight(.bold)
							
							if let version = app.version, let identifier = app.identifier {
								Text("\(version) • \(identifier)")
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
						}
						
						if let date = app.date {
							Text("Added \(date.formatted(date: .abbreviated, time: .omitted))")
								.font(.caption)
								.foregroundStyle(.tertiary)
						}
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 20)
				}
				
				_detailsSection(for: app)
				_certSection(for: app)
				_bundleSection(for: app)
				_executableSection(for: app)
				
				Section {
					Button(.localized("Open in Files"), systemImage: "folder") {
						UIApplication.open(Storage.shared.getUuidDirectory(for: app)!.toSharedDocumentsURL()!)
					}
				}
			}
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
    }
}

// MARK: - Extension: View
extension LibraryInfoView {
	@ViewBuilder
	private func _detailsSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Details")) {
			if let name = app.name {
				_detailRow(icon: "textformat", title: .localized("Name"), value: name, color: .blue)
			}
			
			if let ver = app.version {
				_detailRow(icon: "number", title: .localized("Version"), value: ver, color: .green)
			}
			
			if let id = app.identifier {
				_detailRow(icon: "tag", title: .localized("Bundle ID"), value: id, color: .purple)
			}
			
			if app.isSigned {
				_detailRow(icon: "checkmark.seal.fill", title: .localized("Status"), value: .localized("Signed"), color: .green)
			} else {
				_detailRow(icon: "xmark.seal.fill", title: .localized("Status"), value: .localized("Unsigned"), color: .orange)
			}
		}
	}
	
	@ViewBuilder
	private func _detailRow(icon: String, title: String, value: String, color: Color) -> some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.title3)
				.foregroundStyle(color)
				.frame(width: 32, height: 32)
				.background(color.opacity(0.15))
				.clipShape(RoundedRectangle(cornerRadius: 8))
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(value)
					.font(.body)
					.fontWeight(.medium)
			}
			
			Spacer()
		}
		.copyableText(value)
	}
	
	@ViewBuilder
	private func _certSection(for app: AppInfoPresentable) -> some View {
		if let cert = Storage.shared.getCertificate(from: app) {
			NBSection(.localized("Certificate")) {
				CertificatesCellView(
					cert: cert
				)
			}
		}
	}
	
	@ViewBuilder
	private func _bundleSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Bundle")) {
			NavigationLink(.localized("Alternative Icons")) {
				SigningAlternativeIconView(app: app, appIcon: .constant(nil), isModifing: .constant(false))
			}
			NavigationLink(.localized("Frameworks & PlugIns")) {
				SigningFrameworksView(app: app, options: .constant(nil))
			}
		}
	}
	
	@ViewBuilder
	private func _executableSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Executable")) {
			NavigationLink(.localized("Dylibs")) {
				SigningDylibView(app: app, options: .constant(nil))
			}
		}
	}
}
