import Foundation
import Combine
import IDeviceSwift

class InstallerStatusViewModel: ObservableObject {
    enum InstallerStatus: Equatable {
        case none
        case preparing
        case connecting
        case ready
        case sendingManifest
        case sendingPayload
        case installing
        case completed
        case broken
    }

    @Published var status: InstallerStatus = .none
    @Published var overallProgress: Double = 0.0
    
    var isCompleted: Bool {
        status == .completed
    }
    
    private var isIdevice: Bool
    
    init(isIdevice: Bool = false) {
        self.isIdevice = isIdevice
    }
}

extension InstallerStatusViewModel {
var statusImage: String {
switch status {
case .none: return "archivebox.fill"
case .preparing: return "doc.badge.gearshape"
case .connecting: return "network"
case .ready: return "app.gift"
case .sendingManifest, .sendingPayload: return "paperplane.fill"
case .installing: return "square.and.arrow.down"
case .completed: return "app.badge.checkmark"
case .broken: return "exclamationmark.triangle.fill"
}
}

var statusLabel: String {
switch status {
case .none: return .localized("Packaging")
case .preparing: return .localized("Preparing")
case .connecting: return .localized("Connecting")
case .ready: return .localized("Ready")
case .sendingManifest: return .localized("Sending Manifest")
case .sendingPayload: return .localized("Sending Payload")
case .installing: return .localized("Installing")
case .completed: return .localized("Completed")
case .broken: return .localized("Error")
}
}
}
