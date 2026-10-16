import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    // Retained across cold launch until the main view has loaded the requested duel.
    @Published var pendingDuelID: String?
    @Published var pendingLeague = false
    var pendingDuelIsResult = false
    
    private let userDefaults = UserDefaults.standard
    private let lastAppOpenKey = "lastAppOpenDate"
    
    override init() {
        super.init()
        setupNotificationCenter()
    }
    
    static func savedReminderTime(defaults: UserDefaults = .standard, now: Date = Date()) -> Date {
        (defaults.object(forKey: "reminderTime") as? Date)
            ?? Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: now)!
    }

    @MainActor
    func scheduleLeagueReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["league_weekly"])
        guard userDefaults.object(forKey: "notificationsEnabled") as? Bool != false,
              userDefaults.object(forKey: "leagueNotifications") as? Bool != false else { return }
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString("Лиги")
        content.body = LocalizationManager.shared.localizedString("league.weekly_result.title.week_finished")
        content.sound = .default
        content.userInfo = ["type": "league_weekly"]
        var time = Calendar.current.dateComponents([.hour, .minute], from: Self.savedReminderTime())
        time.weekday = 2
        center.add(UNNotificationRequest(identifier: "league_weekly", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true)))
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
                    #if os(iOS)
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                    self.scheduleInactivityNotification()
                } else {
                    print("❌ Notification permission denied")
                }
            }
        }
    }
    
    private struct RemoteInbox: Decodable {
        struct Item: Decodable {
            let id: String; let title: String; let body: String
            let createdAt: Double; let readAt: Double?
        }
        let items: [Item]
        let unread: Int
    }

    private func remoteInbox(markRead: Bool = false) async -> RemoteInbox? {
        guard let token = await MainActor.run(body: { AuthService.shared.authToken }) else { return nil }
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/notifications" + (markRead ? "/read" : ""))!)
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.httpMethod = markRead ? "POST" : "GET"
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(RemoteInbox.self, from: data)
    }

    func refreshBadge() {
        Task {
            let remote = await remoteInbox()
            let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
            let visible = delivered.filter { !$0.request.identifier.contains("reminder") && $0.request.identifier != "dailyReminder" }
            let remoteIDs = Set(remote?.items.map(\.id) ?? [])
            let localCount = visible.filter { item in
                guard let id = item.request.content.userInfo["notificationId"] as? String else { return true }
                return !remoteIDs.contains(id)
            }.count
            let count = localCount + (remote?.unread ?? 0)
            if #available(iOS 16.0, *) {
                try? await UNUserNotificationCenter.current().setBadgeCount(count)
            } else {
                await MainActor.run {
                    #if os(iOS)
                    UIApplication.shared.applicationIconBadgeNumber = count
                    #endif
                }
            }
        }
    }

    func markNotificationsRead() {
        Task {
            _ = await remoteInbox(markRead: true)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            refreshBadge()
        }
    }

    @MainActor
    func notifyProgress(id: String, title: String, body: String, preference: String) {
        guard userDefaults.object(forKey: "notificationsEnabled") as? Bool != false,
              userDefaults.object(forKey: preference) as? Bool != false else { return }
        logInAppNotification(id: id, title: title, body: body, source: "progress")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
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
        guard userDefaults.object(forKey: "notificationsEnabled") as? Bool != false,
              userDefaults.object(forKey: "streakReminders") as? Bool != false else { return }
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = LocalizationManager.shared.localizedString("Push Notification Title")
            content.body = LocalizationManager.shared.localizedString("Push Notification Body")
            content.sound = .default
            // A reminder is not an unread message; it must not set a badge.
            
            // Уведомление через 3 дня (259200 секунд)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "inactivity_reminder",
                content: content,
                trigger: trigger
            )
            
            Task {
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    print("✅ Inactivity notification scheduled for 3 days")
                } catch {
                    print("❌ Error scheduling notification: \(error)")
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
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let toRemove = requests.filter { $0.identifier.hasPrefix(Self.birthdayFriendPrefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)
            var scheduled: [(Friend, Date)] = []
            for friend in friends {
                guard let bday = friend.birthday else { continue }
                var comps = DateComponents()
                comps.month = cal.component(.month, from: bday)
                comps.day = cal.component(.day, from: bday)
                comps.hour = 9
                comps.minute = 0
                comps.year = year
                if let nextDate = cal.date(from: comps), nextDate >= now {
                    scheduled.append((friend, nextDate))
                } else {
                    comps.year = year + 1
                    if let nextYear = cal.date(from: comps) {
                        scheduled.append((friend, nextYear))
                    }
                }
            }
            Task { @MainActor in
                for (friend, triggerDate) in scheduled {
                    NotificationService.shared.addBirthdayNotification(friend: friend, triggerDate: triggerDate)
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
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// Push c результатом дуэли и мотивационным текстом.
    @MainActor
    func scheduleDuelResultNotification(challengerName: String, challengerScore: Int, myScore: Int, iWon: Bool, challengeId: String? = nil) {
        guard (userDefaults.object(forKey: "duelResultsNotifications") as? Bool) ?? true else { return }
        // Online duels are delivered by the server even when this device is closed.
        // Do not also schedule a duplicate local alert after submitting a result.
        if challengeId != nil { return }
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
                case .authorized, .provisional, .ephemeral:
                    #if os(iOS)
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
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

struct AppNotificationLogItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let date: Date?
    let source: String
}

extension NotificationService {
    private static let inAppLogKey = "notifications.inapp.log.v1"
    private static let inAppDuelLoggedIdsKey = "notifications.inapp.duel.ids.v1"

    private struct StoredInAppNotificationLogItem: Codable {
        let id: String
        let title: String
        let body: String
        let date: Date
        let source: String
    }

    @MainActor
    func logInAppNotification(id: String = UUID().uuidString, title: String, body: String, source: String = "in-app") {
        var items = loadInAppNotificationItems()
        if items.contains(where: { $0.id == id }) { return }
        items.append(.init(id: id, title: title, body: body, date: Date(), source: source))
        if items.count > 200 {
            items = Array(items.suffix(200))
        }
        saveInAppNotificationItems(items)
    }

    @MainActor
    func logDuelChallengeNotificationIfNeeded(challengeId: String, challengerName: String) {
        var logged = Set(userDefaults.stringArray(forKey: Self.inAppDuelLoggedIdsKey) ?? [])
        guard !logged.contains(challengeId) else { return }
        logged.insert(challengeId)
        userDefaults.set(Array(logged.suffix(500)), forKey: Self.inAppDuelLoggedIdsKey)

        let title = LocalizationManager.shared.localizedString("Duel")
        let template = LocalizationManager.shared.localizedString("Duel challenge from %@")
        let body = String(format: template, challengerName)
        logInAppNotification(id: "duel_challenge_\(challengeId)", title: title, body: body, source: "duel")
    }

    private func loadInAppNotificationItems() -> [StoredInAppNotificationLogItem] {
        guard let data = userDefaults.data(forKey: Self.inAppLogKey) else { return [] }
        return (try? JSONDecoder().decode([StoredInAppNotificationLogItem].self, from: data)) ?? []
    }

    private func saveInAppNotificationItems(_ items: [StoredInAppNotificationLogItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: Self.inAppLogKey)
    }

    func fetchMyNotifications() async -> [AppNotificationLogItem] {
        let remote = await remoteInbox()
        let remoteItems = remote?.items.map {
            AppNotificationLogItem(id: $0.id, title: $0.title, body: $0.body, date: Date(timeIntervalSince1970: $0.createdAt / 1000), source: "server")
        } ?? []
        let inAppItems: [AppNotificationLogItem] = remoteItems + loadInAppNotificationItems().map {
            AppNotificationLogItem(
                id: $0.id,
                title: $0.title,
                body: $0.body,
                date: $0.date,
                source: $0.source
            )
        }
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
                UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                    let deliveredItems = delivered.map { n in
                        AppNotificationLogItem(
                            id: n.request.identifier,
                            title: n.request.content.title,
                            body: n.request.content.body,
                            date: n.date,
                            source: "delivered"
                        )
                    }
                    let pendingItems = pending.map { r in
                        AppNotificationLogItem(
                            id: r.identifier,
                            title: r.content.title,
                            body: r.content.body,
                            date: nil,
                            source: "pending"
                        )
                    }
                    let combined = (deliveredItems + pendingItems + inAppItems)
                        .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                    continuation.resume(returning: combined)
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Обработка уведомлений когда приложение на переднем плане
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        refreshBadge()
        let duelType = notification.request.content.userInfo["type"] as? String
        if duelType == "duel_challenge" {
            // Системный баннер и в foreground (плюс in-app popup по опросу /incoming).
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .list, .sound])
            } else {
                completionHandler([.alert, .badge, .sound])
            }
            return
        }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    // Обработка нажатия на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let payload = response.notification.request.content.userInfo
        if payload["type"] as? String == "league_weekly" {
            Task { @MainActor in self.pendingLeague = true }
        }
        if let type = payload["type"] as? String, type == "duel_challenge" || type == "duel_result" {
            Task { @MainActor in
                self.pendingDuelIsResult = type == "duel_result"
                self.pendingDuelID = payload["challengeId"] as? String ?? "inbox"
            }
        }
        if response.notification.request.content.userInfo["type"] as? String == "friend_request" {
            Task { @MainActor in
                FriendRequestsInbox.shared.showInbox = true
                await FriendRequestsInbox.shared.refresh()
            }
        }
        if response.notification.request.identifier == "inactivity_reminder" {
            // Пользователь нажал на уведомление - открываем приложение
            updateLastAppOpenDate()
        }
        
        refreshBadge()
        completionHandler()
    }
} 