import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let userDefaults = UserDefaults.standard
    private let lastAppOpenKey = "lastAppOpenDate"
    
    override init() {
        super.init()
        setupNotificationCenter()
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Запрос разрешения на уведомления
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleInactivityNotification()
                } else {
                    print("❌ Notification permission denied")
                }
            }
        }
    }
    
    // Обновление времени последнего открытия приложения
    func updateLastAppOpenDate() {
        userDefaults.set(Date(), forKey: lastAppOpenKey)
        
        // Отменяем предыдущие уведомления и планируем новые
        cancelInactivityNotifications()
        scheduleInactivityNotification()
    }
    
    // Планирование уведомления о неактивности (через 3 дня)
    private func scheduleInactivityNotification() {
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = LocalizationManager.shared.localizedString("Push Notification Title")
            content.body = LocalizationManager.shared.localizedString("Push Notification Body")
            content.sound = .default
            content.badge = 1
            
            // Уведомление через 3 дня (259200 секунд)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "inactivity_reminder",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification: \(error)")
                } else {
                    print("✅ Inactivity notification scheduled for 3 days")
                }
            }
        }
    }
    
    // Отмена уведомлений о неактивности
    private func cancelInactivityNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["inactivity_reminder"])
    }
    
    /// Push: «Вам бросил вызов на дуэль [challengerName]»
    @MainActor
    func scheduleDuelChallengeNotification(from challengerName: String) {
        let template = LocalizationManager.shared.localizedString("Duel challenge from %@")
        let body = String(format: template, challengerName)
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString("Duel")
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "duel_challenge_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    /// Push: «Вы победили в дуэли»
    @MainActor
    func scheduleDuelWonNotification() {
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString("Duel")
        content.body = LocalizationManager.shared.localizedString("You won the duel!")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "duel_won_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // Проверка статуса разрешений
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.scheduleInactivityNotification()
                case .denied:
                    print("❌ Notifications are denied")
                case .notDetermined:
                    self.requestNotificationPermission()
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Обработка уведомлений когда приложение на переднем плане
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Обработка нажатия на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.identifier == "inactivity_reminder" {
            // Пользователь нажал на уведомление - открываем приложение
            updateLastAppOpenDate()
        }
        
        completionHandler()
    }
} 