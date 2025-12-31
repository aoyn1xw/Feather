import UIKit
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

            // Centered Layout
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 8) {
                    FRAppIconView(app: app, size: 64)
                        .shadow(radius: 4)
                    
                    VStack(spacing: 4) {
                        Text(app.name ?? .localized("Unknown"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                        
                        Text(_desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                        
                        if let certInfo = certInfo {
                            Text("Expires: \(certInfo.formatted)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(certInfo.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(certInfo.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
            }

if !isEditing {
                Menu {
                    _buttonActions(for: app)
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
}
}
.padding(.vertical, 16)
        .padding(.horizontal, 12)
.background(
RoundedRectangle(cornerRadius: 24, style: .continuous)
.fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
)
        .padding(.vertical, 4)
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
                    Label(.localized("Install"), systemImage: "arrow.down.circle")
}
                
                Button {
                    selectedInfoAppPresenting = AnyApp(base: app)
                } label: {
                    Label(.localized("More Info"), systemImage: "info.circle")
                }
} else {
Button {
selectedSigningAppPresenting = AnyApp(base: app)
} label: {
                    Label(.localized("Sign App"), systemImage: "signature")
}
                
                Button {
                    selectedInfoAppPresenting = AnyApp(base: app)
                } label: {
                    Label(.localized("More Info"), systemImage: "info.circle")
                }
}
}
}
}
