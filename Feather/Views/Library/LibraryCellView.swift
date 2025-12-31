import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.editMode) private var editMode

	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	var certRevoked: Bool {
		Storage.shared.getCertificate(from: app)?.revoked == true
	}
	
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppUUIDs: Set<String>
	
	// MARK: Selections
	private var _isSelected: Bool {
		guard let uuid = app.uuid else { return false }
		return selectedAppUUIDs.contains(uuid)
	}
	
	private func _toggleSelection() {
		guard let uuid = app.uuid else { return }
		if selectedAppUUIDs.contains(uuid) {
			selectedAppUUIDs.remove(uuid)
		} else {
			selectedAppUUIDs.insert(uuid)
		}
	}
	
	// MARK: Body
	var body: some View {
		let isEditing = editMode?.wrappedValue == .active
		
		HStack(spacing: 16) {
			if isEditing {
				Button {
					_toggleSelection()
				} label: {
					Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
						.foregroundColor(_isSelected ? .accentColor : .secondary)
						.font(.title2)
				}
				.buttonStyle(.borderless)
			}
			
			FRAppIconView(app: app, size: 57)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(app.name ?? .localized("Unknown"))
					.font(.headline)
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				Text(_desc)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(1)
				
				if let certInfo = certInfo {
					Text("Expires On: \(certInfo.formatted)")
						.font(.caption2)
						.foregroundStyle(certInfo.color)
						.padding(.top, 2)
				}
			}
			
			Spacer()
			
			if !isEditing {
				_buttonActions(for: app)
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 18, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color.accentColor.opacity(0.15),
							Color.accentColor.opacity(0.05)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 18, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [
							Color.accentColor.opacity(0.3),
							Color.clear
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
		.contentShape(Rectangle())
		.onTapGesture {
			if isEditing {
				_toggleSelection()
			}
		}
		.swipeActions {
			if !isEditing {
				_actions(for: app)
			}
		}
		.contextMenu {
			if !isEditing {
				_contextActions(for: app)
				Divider()
				_contextActionsExtra(for: app)
				Divider()
				_actions(for: app)
			}
		}
	}
	
	private var _desc: String {
		if let version = app.version, let id = app.identifier {
			return "\(version) • \(id)"
		} else {
			return .localized("Unknown")
		}
	}
}


// MARK: - Extension: View
extension LibraryCellView {
	@ViewBuilder
	private func _actions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteApp(for: app)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Get Info"), systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	@ViewBuilder
	private func _contextActionsExtra(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			if let id = app.identifier {
				Button(.localized("Open"), systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Re-sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
		} else {
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
		}
	}
	
	@ViewBuilder
	private func _buttonActions(for app: AppInfoPresentable) -> some View {
		Group {
			if app.isSigned {
				Button {
					selectedInstallAppPresenting = AnyApp(base: app)
				} label: {
					HStack(spacing: 6) {
						if let info = certInfo {
							Image(systemName: info.icon)
								.font(.caption)
								.foregroundStyle(certRevoked ? .red : info.color)
						}
						Image(systemName: "arrow.down.circle.fill")
							.font(.title3)
							.foregroundStyle(.white)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(
						Capsule()
							.fill(certRevoked ? Color.red : (certInfo?.color ?? .green))
					)
				}
			} else {
				Button {
					selectedSigningAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Sign"),
						revoked: false,
						expiration: nil
					)
				}
			}
		}
		.buttonStyle(.borderless)
	}
}
