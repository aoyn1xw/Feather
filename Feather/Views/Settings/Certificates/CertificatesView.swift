import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	
	@State private var _isAddingPresenting = false
	@State private var _isSelectedInfoPresenting: CertificatePair?

	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var _certificates: FetchedResults<CertificatePair>
	
	//
	private var _bindingSelectedCert: Binding<Int>?
	private var _selectedCertBinding: Binding<Int> {
		_bindingSelectedCert ?? $_storedSelectedCert
	}
	
	init(selectedCert: Binding<Int>? = nil) {
		self._bindingSelectedCert = selectedCert
	}
	
	// MARK: Body
	var body: some View {
		NBGrid {
			ForEach(Array(_certificates.enumerated()), id: \.element.uuid) { index, cert in
				_cellButton(for: cert, at: index)
			}
		}
		.navigationTitle(.localized("Certificates"))
		.overlay {
			if _certificates.isEmpty {
				if #available(iOS 17, *) {
					ContentUnavailableView {
						ConditionalLabel(title: .localized("No Certificates"), systemImage: "questionmark.folder.fill")
					} description: {
						Text(.localized("Get started signing by importing your first certificate."))
					} actions: {
						Button {
							_isAddingPresenting = true
						} label: {
							NBButton(.localized("Import"), style: .text)
						}
					}
				}
			}
		}
		.toolbar {
			if _bindingSelectedCert == nil {
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing
				) {
					_isAddingPresenting = true
				}
			}
		}
		.sheet(item: $_isSelectedInfoPresenting) { cert in
			CertificatesInfoView(cert: cert)
		}
		.sheet(isPresented: $_isAddingPresenting) {
			CertificatesAddView()
				.presentationDetents([.medium])
		}
	}
}

// MARK: - View extension
extension CertificatesView {
	@ViewBuilder
	private func _cellButton(for cert: CertificatePair, at index: Int) -> some View {
		Button {
			_selectedCertBinding.wrappedValue = index
		} label: {
			CertificatesCellView(
				cert: cert
			)
			.padding(18)
			.background(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.fill(
						_selectedCertBinding.wrappedValue == index 
							? LinearGradient(
								colors: [
									Color.accentColor.opacity(0.2),
									Color.accentColor.opacity(0.1),
									Color.accentColor.opacity(0.05)
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
							: LinearGradient(
								colors: [
									Color(UIColor.secondarySystemGroupedBackground),
									Color(UIColor.secondarySystemGroupedBackground).opacity(0.7),
									Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5)
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
					)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.stroke(
						_selectedCertBinding.wrappedValue == index 
							? LinearGradient(
								colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
							: LinearGradient(
								colors: [Color(UIColor.separator).opacity(0.3), Color(UIColor.separator).opacity(0.1)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
						lineWidth: _selectedCertBinding.wrappedValue == index ? 2 : 1
					)
			)
			.shadow(
				color: _selectedCertBinding.wrappedValue == index 
					? Color.accentColor.opacity(0.35) 
					: Color.black.opacity(0.08),
				radius: _selectedCertBinding.wrappedValue == index ? 12 : 8,
				x: 0,
				y: _selectedCertBinding.wrappedValue == index ? 6 : 3
			)
			.overlay(alignment: .topTrailing) {
				if _selectedCertBinding.wrappedValue == index {
					ZStack {
						Circle()
							.fill(Color.accentColor)
							.frame(width: 28, height: 28)
						Image(systemName: "checkmark")
							.font(.system(size: 12, weight: .bold))
							.foregroundStyle(.white)
					}
					.offset(x: 8, y: -8)
					.shadow(color: .accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
				}
			}
			.contextMenu {
				_contextActions(for: cert)
				if cert.isDefault != true {
					Divider()
					_actions(for: cert)
				}
			}
			.transaction {
				$0.animation = nil
			}
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	private func _actions(for cert: CertificatePair) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteCertificate(for: cert)
		}
	}
	
	private func _exportEntitlements(for cert: CertificatePair) {
		guard let data = Storage.shared.getProvisionFileDecoded(for: cert),
			  let entitlements = data.Entitlements else {
			return
		}
		
		// Format entitlements as text
		var text = "Certificate: \(cert.nickname ?? "Unknown")\n"
		text += "Entitlements Export\n"
		text += String(repeating: "=", count: 50) + "\n\n"
		
		let sortedKeys = entitlements.keys.sorted()
		for key in sortedKeys {
			if let value = entitlements[key]?.value {
				text += "\(key):\n"
				text += _formatValue(value, indent: 1) + "\n\n"
			}
		}
		
		// Create temporary file with sanitized filename
		let tempDir = FileManager.default.temporaryDirectory
		let sanitizedName = (cert.nickname ?? "certificate")
			.replacingOccurrences(of: "/", with: "-")
			.replacingOccurrences(of: "\\", with: "-")
			.replacingOccurrences(of: ":", with: "-")
		let fileName = "\(sanitizedName)_entitlements.txt"
		let fileURL = tempDir.appendingPathComponent(fileName)
		
		do {
			try text.write(to: fileURL, atomically: true, encoding: .utf8)
			UIActivityViewController.show(activityItems: [fileURL])
		} catch {
			// Note: Consider showing an alert to user in production
			print("Error writing entitlements file: \(error)")
		}
	}
	
	private func _formatValue(_ value: Any, indent: Int) -> String {
		let indentStr = String(repeating: "  ", count: indent)
		
		if let dict = value as? [String: Any] {
			var result = "{\n"
			let sortedKeys = dict.keys.sorted()
			for key in sortedKeys {
				if let dictValue = dict[key] {
					result += "\(indentStr)\(key): \(_formatValue(dictValue, indent: indent + 1))\n"
				}
			}
			result += String(repeating: "  ", count: indent - 1) + "}"
			return result
		} else if let array = value as? [Any] {
			var result = "[\n"
			for (index, item) in array.enumerated() {
				result += "\(indentStr)[\(index)]: \(_formatValue(item, indent: indent + 1))\n"
			}
			result += String(repeating: "  ", count: indent - 1) + "]"
			return result
		} else if let bool = value as? Bool {
			return bool ? "true" : "false"
		} else {
			return String(describing: value)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for cert: CertificatePair) -> some View {
		Button(.localized("Get Info"), systemImage: "info.circle") {
			_isSelectedInfoPresenting = cert
		}
		Button(.localized("Export Entitlements"), systemImage: "square.and.arrow.up") {
			_exportEntitlements(for: cert)
		}
		Divider()
		Button(.localized("Check Revokage"), systemImage: "person.text.rectangle") {
			Storage.shared.revokagedCertificate(for: cert)
		}
	}
}
