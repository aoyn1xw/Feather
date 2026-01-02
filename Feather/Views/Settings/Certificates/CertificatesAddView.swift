import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - View
struct CertificatesAddView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var _p12URL: URL? = nil
	@State private var _provisionURL: URL? = nil
	@State private var _p12Password: String = ""
	@State private var _certificateName: String = ""
	
	@State private var _isImportingP12Presenting = false
	@State private var _isImportingMobileProvisionPresenting = false
	
	var saveButtonDisabled: Bool {
		_p12URL == nil || _provisionURL == nil
	}
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("New Certificate"), displayMode: .inline) {
			ZStack {
				// Background gradient
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.03),
						Color.clear
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
				
				SwiftUI.Form {
					NBSection {
						_importButton(.localized("Import Certificate File"), file: _p12URL, iconName: "doc.badge.key.fill") {
							_isImportingP12Presenting = true
						}
						_importButton(.localized("Import Provisioning File"), file: _provisionURL, iconName: "doc.fill.badge.gearshape") {
							_isImportingMobileProvisionPresenting = true
						}
					} header: {
						HStack(spacing: 8) {
							Image(systemName: "folder.fill.badge.plus")
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(.localized("Files"))
								.fontWeight(.semibold)
						}
						.textCase(.none)
					}
					NBSection {
						HStack(spacing: 12) {
							Image(systemName: "lock.shield.fill")
								.foregroundStyle(Color.accentColor)
							SecureField(.localized("Enter Password"), text: $_p12Password)
						}
					} header: {
						HStack(spacing: 8) {
							Image(systemName: "key.fill")
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.orange, Color.orange.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(.localized("Password"))
								.fontWeight(.semibold)
						}
						.textCase(.none)
					} footer: {
						Text(.localized("Enter the password associated with the private key. Leave it blank if theres no password required."))
					}
					
					Section {
						HStack(spacing: 12) {
							Image(systemName: "tag.fill")
								.foregroundStyle(Color.accentColor)
							TextField(.localized("Nickname (Optional)"), text: $_certificateName)
						}
					} header: {
						HStack(spacing: 8) {
							Image(systemName: "textformat")
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(.localized("Name"))
								.fontWeight(.semibold)
						}
						.textCase(.none)
					}
				}
				.scrollContentBackground(.hidden)
			}
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				NBToolbarButton(
					.localized("Save"),
					style: .text,
					placement: .confirmationAction,
					isDisabled: saveButtonDisabled
				) {
					_saveCertificate()
				}
			}
			.sheet(isPresented: $_isImportingP12Presenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.p12],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._p12URL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isImportingMobileProvisionPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.mobileProvision],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._provisionURL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
		}
	}
}

// MARK: - Extension: View
extension CertificatesAddView {
	@ViewBuilder
	private func _importButton(
		_ title: String,
		file: URL?,
		iconName: String = "square.and.arrow.down.fill",
		action: @escaping () -> Void
	) -> some View {
		Button {
			action()
		} label: {
			HStack(spacing: 12) {
				ZStack {
					Circle()
						.fill(
							file == nil
								? LinearGradient(
									colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
								: LinearGradient(
									colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
						)
						.frame(width: 36, height: 36)
					
					Image(systemName: file == nil ? iconName : "checkmark.circle.fill")
						.font(.system(size: 16))
						.foregroundStyle(file == nil ? Color.accentColor : Color.green)
				}
				
				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.body)
						.fontWeight(.medium)
						.foregroundStyle(file == nil ? .primary : .secondary)
					
					if let file = file {
						Text(file.lastPathComponent)
							.font(.caption)
							.foregroundStyle(.secondary)
							.lineLimit(1)
					} else {
						Text(.localized("Tap to select"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				
				Spacer()
				
				if file == nil {
					Image(systemName: "chevron.right")
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
			}
			.padding(.vertical, 4)
		}
		.disabled(file != nil)
		.animation(.easeInOut(duration: 0.3), value: file != nil)
	}
}

// MARK: - Extension: View (import)
extension CertificatesAddView {
	private func _saveCertificate() {
		guard
			let p12URL = _p12URL,
			let provisionURL = _provisionURL,
			FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
		else {
			UIAlertController.showAlertWithOk(
				title: .localized("Bad Password"),
				message: .localized("Please check the password and try again.")
			)
			return
		}
		
		FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: _p12Password,
			certificateName: _certificateName
		) { _ in
			dismiss()
		}
	}
}

