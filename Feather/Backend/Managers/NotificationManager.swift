import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if let error = error {
                    AppLogManager.shared.error("Failed to request notification authorization: \(error.localizedDescription)", category: "Notifications")
                } else if granted {
                    AppLogManager.shared.success("Notification authorization granted", category: "Notifications")
                } else {
                    AppLogManager.shared.warning("Notification authorization denied", category: "Notifications")
                }
                
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Send Notifications
    
    func sendAppSignedNotification(appName: String) {
        // Check authorization before sending
        checkAuthorizationStatus()
        
        guard UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") else {
            AppLogManager.shared.warning("Notifications are disabled in settings", category: "Notifications")
            return
        }
        
        guard isAuthorized else {
            AppLogManager.shared.warning("Cannot send notification: not authorized", category: "Notifications")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Downloaded App"
        content.body = "\(appName) was downloaded successfully. Check the Library tab to sign the app"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "APP_SIGNED"
        
        // Use a very short trigger to send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogManager.shared.error("Failed to send notification: \(error.localizedDescription)", category: "Notifications")
            } else {
                AppLogManager.shared.success("Notification sent for app: \(appName)", category: "Notifications")
            }
        }
    }
    
    func sendAppReadyNotification(appName: String) {
        // Check authorization before sending
        checkAuthorizationStatus()
        
        guard UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") else {
            return
        }
        
        guard isAuthorized else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "App Ready to Install"
        content.body = "\(appName) has been signed successfully and is ready to install."
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "APP_READY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogManager.shared.error("Failed to send notification: \(error.localizedDescription)", category: "Notifications")
            } else {
                AppLogManager.shared.success("Notification sent for app ready: \(appName)", category: "Notifications")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
