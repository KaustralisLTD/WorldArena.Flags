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

    private static let birthdayFriendPrefix = "birthday_friend_"

    /// Планирует локальные пуши на 9:00 в день рождения каждого друга (если у друга указан birthday).
    @MainActor
    func scheduleFriendBirthdayNotificationsIfNeeded(friends: [Friend]) {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let toRemove = requests.filter { $0.identifier.hasPrefix(Self.birthdayFriendPrefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)
            for friend in friends {
                guard let bday = friend.birthday else { continue }
                var comps = DateComponents()
                comps.month = cal.component(.month, from: bday)
                comps.day = cal.component(.day, from: bday)
                comps.hour = 9
                comps.minute = 0
                comps.year = year
                if let nextDate = cal.date(from: comps), nextDate >= now {
                    self?.addBirthdayNotification(friend: friend, triggerDate: nextDate)
                } else {
                    comps.year = year + 1
                    if let nextYear = cal.date(from: comps) {
                        self?.addBirthdayNotification(friend: friend, triggerDate: nextYear)
                    }
                }
            }
        }
    }

    private func addBirthdayNotification(friend: Friend, triggerDate: Date) {
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = LocalizationManager.shared.localizedString("День рождения друга")
            let bodyTemplate = LocalizationManager.shared.localizedString("Friend birthday push body")
            content.body = String(format: bodyTemplate, friend.displayNameOrUsername)
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = Self.birthdayFriendPrefix + friend.username.filter { $0.isLetter || $0.isNumber }
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    /// Push c результатом дуэли и мотивационным текстом.
    @MainActor
    func scheduleDuelResultNotification(challengerName: String, challengerScore: Int, myScore: Int, iWon: Bool) {
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString("Duel result")
        let base = String(
            format: LocalizationManager.shared.localizedString("Duel result push format"),
            challengerName,
            challengerScore,
            myScore
        )
        let motivationKey = iWon ? "Duel motivation win" : "Duel motivation lose"
        content.body = "\(base) \(LocalizationManager.shared.localizedString(motivationKey))"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "duel_result_\(UUID().uuidString)", content: content, trigger: trigger)
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