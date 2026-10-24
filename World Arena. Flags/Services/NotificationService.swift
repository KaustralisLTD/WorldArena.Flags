import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// The legacy journal had no account identifier. Claim it once for the signed-in
// account on this device; retain the original data as a recovery copy.
enum LegacyNotificationJournalMigration {
    static func migrate(defaults: UserDefaults, username: String?) {
        guard let username, !username.isEmpty else { return }
        let legacyKey = "notifications.inapp.log.v1"
        let ownerKey = legacyKey + ".migrationOwner.v2"
        guard defaults.string(forKey: ownerKey) == nil,
              let original = defaults.data(forKey: legacyKey),
              let legacy = try? JSONSerialization.jsonObject(with: original) as? [[String: Any]],
              legacy.allSatisfy({ $0["id"] is String && $0["title"] is String && $0["body"] is String && $0["date"] is NSNumber && $0["source"] is String }) else { return }
        let destination = legacyKey + "." + username
        var current = [[String: Any]]()
        if let data = defaults.data(forKey: destination) {
            guard let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
            current = decoded
        }
        var known = Set(current.compactMap { $0["id"] as? String })
        let inboxKey = "notifications.inbox.v2." + username
        var read = Set(defaults.stringArray(forKey: inboxKey + ".read") ?? [])
        for item in legacy {
            guard let id = item["id"] as? String, known.insert(id).inserted else { continue }
            current.append(item)
            // Old storage did not track read status. Import as history, without
            // turning past events into a new badge or replaying notifications.
            read.insert(id)
            if id.hasPrefix("duel_challenge_") {
                read.insert("duel_challenge:" + String(id.dropFirst(15)))
            } else if let kind = item["kind"] as? String, kind.hasPrefix("duel"), let target = item["target"] as? String {
                read.insert(kind + ":" + target)
            }
        }
        guard let merged = try? JSONSerialization.data(withJSONObject: current) else { return }
        defaults.set(merged, forKey: destination)
        defaults.set(Array(read), forKey: inboxKey + ".read")
        defaults.set(username, forKey: ownerKey)
    }
}

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    // Retained across cold launch until the main view has loaded the requested duel.
    @Published var pendingDuelID: String?
    @Published var pendingLeague = false
    @Published var pendingInbox = false
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
    
    @Published private(set) var inboxItems: [AppNotificationLogItem] = []
    @Published private(set) var unreadCount = 0
    @Published private(set) var inboxRefreshFailed = false
    private var inboxRefreshing = false
    private var loadedInboxAccount: String?
    private var supportsSelectiveRead = false

    private struct RemoteInbox: Decodable {
        struct Item: Decodable {
            let id: String; let title: String; let body: String
            let kind: String?; let target: String?
            let details: AppNotificationLogItem.Details?
            let createdAt: Double; let readAt: Double?
        }
        let items: [Item]
        let unread: Int
        let selectiveRead: Bool?
    }

    @MainActor private var accountKey: String {
        "notifications.inbox.v2." + (AuthService.shared.authUsername ?? "guest")
    }
    @MainActor var unreadDuelCount: Int { inboxItems.filter { $0.isUnread && $0.isDuel }.count }
    @MainActor func unreadForDuel(_ id: String) -> Bool {
        inboxItems.contains { $0.isUnread && $0.isDuel && $0.target == id }
    }
    @MainActor func markDuelRead(_ id: String) {
        markRead(ids: inboxItems.filter { $0.isDuel && $0.target == id }.map(\.id))
    }

    @MainActor private func remoteInbox(token: String) async -> RemoteInbox? {
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/notifications")!)
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(RemoteInbox.self, from: data)
    }

    @MainActor func refreshInbox() async {
        #if targetEnvironment(simulator)
        if CommandLine.arguments.contains("NotificationInboxQA") { return }
        #endif
        LegacyNotificationJournalMigration.migrate(defaults: userDefaults, username: AuthService.shared.authUsername)
        let account = accountKey
        if loadedInboxAccount != account {
            loadedInboxAccount = account; inboxRefreshing = false; supportsSelectiveRead = false
            inboxItems = (userDefaults.data(forKey: account).flatMap { try? JSONDecoder().decode([AppNotificationLogItem].self,from:$0) }) ?? []
            persistInbox()
        }
        guard !inboxRefreshing else { return }
        inboxRefreshing = true
        defer { if loadedInboxAccount == account { inboxRefreshing = false } }
        var cached = (userDefaults.data(forKey: account).flatMap { try? JSONDecoder().decode([AppNotificationLogItem].self, from: $0) }) ?? []
        let token = AuthService.shared.authToken
        let remote = token == nil ? nil : await remoteInbox(token: token!)
        guard account == accountKey else { return }
        inboxRefreshFailed = token != nil && remote == nil
        var readIDs = Set(userDefaults.stringArray(forKey: account + ".read") ?? [])
        if let remote {
            supportsSelectiveRead = remote.selectiveRead == true
            cached = remote.items.map { r in
                var target = r.target
                if target == nil && r.kind?.hasPrefix("duel_") == true { target = r.id.split(separator: ":").dropFirst().first.map(String.init) }
                if r.readAt != nil { readIDs.insert(r.id) }
                return AppNotificationLogItem(id:r.id,title:r.title,body:r.body,date:Date(timeIntervalSince1970:r.createdAt/1000),source:"server",kind:r.kind ?? "message",target:target,readAt:r.readAt.map { Date(timeIntervalSince1970:$0/1000) },details:r.details)
            } + cached.filter { $0.source != "server" }
        }
        // Scheduled reminders are future requests, not unread events.
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        guard account == accountKey else { return }
        var combined = cached + loadInAppNotificationItems().map {
            AppNotificationLogItem(id:$0.id,title:$0.title,body:$0.body,date:$0.date,source:$0.source,kind:$0.kind ?? ($0.source == "duel" ? "duel_challenge" : $0.source),target:$0.target ?? ($0.id.hasPrefix("duel_challenge_") ? String($0.id.dropFirst(15)) : nil),details:$0.details)
        }
        for n in delivered {
            let p=n.request.content.userInfo
            let type=p["type"] as? String ?? "message"
            if n.request.identifier.contains("reminder") || n.request.identifier == "dailyReminder" { continue }
            combined.append(AppNotificationLogItem(id:p["notificationId"] as? String ?? n.request.identifier,title:n.request.content.title,body:n.request.content.body,date:n.date,source:"delivered",kind:type,target:p["challengeId"] as? String))
        }
        readIDs.formUnion(userDefaults.stringArray(forKey:account + ".read") ?? [])
        var seen=Set<String>()
        inboxItems = combined.sorted {
            if ($0.source == "server") != ($1.source == "server") { return $0.source == "server" }
            return ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
        }.filter { item in
            let semantic=item.deduplicationKey
            return seen.insert(semantic).inserted
        }.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(200).map { item in
            var item=item
            let semantic=item.deduplicationKey
            if readIDs.contains(item.id) || readIDs.contains(semantic) { item.readAt = item.readAt ?? Date() }
            return item
        }
        userDefaults.set(Array(readIDs),forKey:account + ".read")
        persistInbox()
        var queue=Set(userDefaults.stringArray(forKey:account + ".readQueue") ?? [])
        for item in inboxItems where item.source == "server" && item.readAt != nil {
            if remote?.items.first(where: { $0.id == item.id })?.readAt == nil { queue.insert(item.id) }
        }
        userDefaults.set(Array(queue),forKey:account + ".readQueue")
        if let token { await flushReadQueue(account:account,token:token) }
    }

    @MainActor private func persistInbox() {
        if let data=try? JSONEncoder().encode(inboxItems) { userDefaults.set(data,forKey:accountKey) }
        unreadCount=inboxItems.filter(\.isUnread).count
        let count=unreadCount
        if #available(iOS 16.0, *) { Task { try? await UNUserNotificationCenter.current().setBadgeCount(count) } }
        else {
            #if os(iOS)
            UIApplication.shared.applicationIconBadgeNumber=count
            #endif
        }
    }

    @MainActor func markRead(ids: [String]) {
        guard !ids.isEmpty else { return }
        #if targetEnvironment(simulator)
        if CommandLine.arguments.contains("NotificationInboxQA") {
            for i in inboxItems.indices where ids.contains(inboxItems[i].id) { inboxItems[i].readAt=Date() }
            unreadCount=inboxItems.filter(\.isUnread).count
            return
        }
        #endif
        let ids=Set(ids), account=accountKey
        var reads=Set(userDefaults.stringArray(forKey:account + ".read") ?? [])
        reads.formUnion(ids)
        for item in inboxItems where ids.contains(item.id) {
            reads.insert(item.deduplicationKey)
        }
        userDefaults.set(Array(reads),forKey:account + ".read")
        let serverIDs=inboxItems.filter { ids.contains($0.id) && $0.source == "server" }.map(\.id)
        var queue=Set(userDefaults.stringArray(forKey:account + ".readQueue") ?? [])
        queue.formUnion(serverIDs);userDefaults.set(Array(queue),forKey:account + ".readQueue")
        for i in inboxItems.indices where ids.contains(inboxItems[i].id) { inboxItems[i].readAt=Date() }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers:Array(ids))
        persistInbox()
        if let token=AuthService.shared.authToken { Task { await flushReadQueue(account:account,token:token) } }
    }
    @MainActor private func flushReadQueue(account:String,token:String) async {
        guard supportsSelectiveRead else { return } // Older servers only support marking everything read.
        let ids=Array((userDefaults.stringArray(forKey:account + ".readQueue") ?? []).prefix(200))
        guard !ids.isEmpty else { return }
        var r=URLRequest(url:URL(string:"https://flags.worldarena.games/api/v1/notifications/read")!)
        r.httpMethod="POST";r.timeoutInterval=15
        r.setValue("Bearer " + token,forHTTPHeaderField:"Authorization")
        r.setValue("application/json",forHTTPHeaderField:"Content-Type")
        r.httpBody=try? JSONEncoder().encode(["ids":ids])
        guard let (_,response)=try? await URLSession.shared.data(for:r),(response as? HTTPURLResponse)?.statusCode==200 else { return }
        var pending=Set(userDefaults.stringArray(forKey:account + ".readQueue") ?? []);pending.subtract(ids)
        userDefaults.set(Array(pending),forKey:account + ".readQueue")
    }
    func refreshBadge() { Task { @MainActor in await self.refreshInbox() } }
    func markNotificationsRead() { Task { @MainActor in self.markRead(ids:self.inboxItems.map(\.id)) } }

    @MainActor
    func notifyProgress(id: String, title: String, body: String, preference: String, details: AppNotificationLogItem.Details? = nil) {
        logInAppNotification(id: id, title: title, body: body, source: "progress", kind: "progress", details: details)
        guard userDefaults.object(forKey: "notificationsEnabled") as? Bool != false,
              userDefaults.object(forKey: preference) as? Bool != false else { return }
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

struct AppNotificationLogItem: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let date: Date?
    let source: String
    var kind: String = "message"
    var target: String? = nil
    var readAt: Date? = nil
    struct Details: Codable { var opponentName: String?; var myScore: Int?; var opponentScore: Int?; var iWon: Bool?; var level: Int? = nil; var xp: Int? = nil; var rank: Int? = nil; var participants: Int? = nil; var league: String? = nil; var reward: Int? = nil; var achievementID: String? = nil; var week: String? = nil; var myTimeMs: Int? = nil; var opponentTimeMs: Int? = nil }
    var details: Details? = nil
    var deduplicationKey: String {
        if isDuel, let target { return kind + ":" + target }
        if let level = details?.level { return "level_" + String(level) }
        if let week = details?.week { return "league_" + week }
        if let achievement = details?.achievementID { return "achievement_" + achievement }
        return id
    }
    var isUnread: Bool { readAt == nil }
    @MainActor var displayTitle: String {
        let lm=LocalizationManager.shared
        if kind == "duel_result" { return lm.localizedString(details?.iWon == true ? "Victory" : details?.iWon == false ? "Defeat" : "Duel result") }
        if kind == "duel_challenge" { return lm.localizedString("Duel") }
        return title
    }
    @MainActor var displayBody: String {
        let lm=LocalizationManager.shared
        if kind == "duel_challenge", let name=details?.opponentName { return String(format:lm.localizedString("Duel challenge from %@"),name) }
        if kind == "duel_result", let d=details,let own=d.myScore,let other=d.opponentScore {
            return "\(lm.localizedString("You")): \(own) · \(d.opponentName ?? "—"): \(other)"
        }
        return body
    }
    var isDuel: Bool { kind.hasPrefix("duel") || source == "duel" }
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
        var kind: String? = nil
        var target: String? = nil
        var details: AppNotificationLogItem.Details? = nil
    }

    @MainActor
    func logInAppNotification(id: String = UUID().uuidString, title: String, body: String, source: String = "in-app", kind: String? = nil, target: String? = nil, details: AppNotificationLogItem.Details? = nil) {
        var items = loadInAppNotificationItems()
        if items.contains(where: { $0.id == id }) { return }
        items.append(.init(id: id, title: title, body: body, date: Date(), source: source, kind: kind, target: target, details: details))
        if items.count > 200 {
            items = Array(items.suffix(200))
        }
        saveInAppNotificationItems(items)
        refreshBadge()
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

    @MainActor
    private func loadInAppNotificationItems() -> [StoredInAppNotificationLogItem] {
        LegacyNotificationJournalMigration.migrate(defaults: userDefaults, username: AuthService.shared.authUsername)
        guard let data = userDefaults.data(forKey: Self.inAppLogKey + "." + (AuthService.shared.authUsername ?? "guest")) else { return [] }
        return (try? JSONDecoder().decode([StoredInAppNotificationLogItem].self, from: data)) ?? []
    }

    @MainActor
    private func saveInAppNotificationItems(_ items: [StoredInAppNotificationLogItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: Self.inAppLogKey + "." + (AuthService.shared.authUsername ?? "guest"))
    }

    @MainActor
    func fetchMyNotifications() async -> [AppNotificationLogItem] {
        await refreshInbox()
        return inboxItems
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
        let notificationType=payload["type"] as? String ?? "message"
        if !["duel_challenge","duel_result","league_weekly","friend_request"].contains(notificationType),
           !response.notification.request.identifier.contains("reminder"), response.notification.request.identifier != "dailyReminder" {
            Task { @MainActor in self.pendingInbox = true }
        }
        Task { @MainActor in
            await self.refreshInbox()
            if let id=payload["notificationId"] as? String { self.markRead(ids:[id]) }
        }
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
#if targetEnvironment(simulator)
extension NotificationService {
    @MainActor func seedInboxPreview() {
        inboxItems = [
            .init(id:"preview-duel",title:LocalizationManager.shared.localizedString("Victory"),body:"Sergii · 20 : 14 · Nadiia",date:Date(),source:"preview",kind:"duel_result",target:"preview-match",details:.init(opponentName:"Nadiia",myScore:15,opponentScore:15,iWon:true,myTimeMs:41230,opponentTimeMs:43780)),
            .init(id:"preview-achievement",title:LocalizationManager.shared.localizedString("Достижения"),body:LocalizationManager.shared.localizedString("Ранняя птица") + " · " + LocalizationManager.shared.localizedString("Достигните серии 5 дней"),date:Date().addingTimeInterval(-900),source:"preview",kind:"progress"),
            .init(id:"achievement_journey_streak_100",title:LocalizationManager.shared.localizedString("Достижения"),body:LocalizationManager.shared.localizedString("achievement.streak_100.title"),date:Date().addingTimeInterval(-1200),source:"preview",kind:"progress",readAt:Date(),details:.init(achievementID:"journey_streak_100")),
            .init(id:"level_100",title:LocalizationManager.shared.localizedString("Уровень") + " 100",body:LocalizationManager.shared.localizedString("achievement.level_100.title"),date:Date().addingTimeInterval(-1800),source:"preview",kind:"progress",readAt:Date(),details:.init(level:100,xp:99000)),
            .init(id:"league_preview",title:LocalizationManager.shared.localizedString("Лиги"),body:LocalizationManager.shared.localizedString("Золотая лига"),date:Date().addingTimeInterval(-2400),source:"preview",kind:"progress",readAt:Date(),details:.init(rank:2,participants:20,league:LocalizationManager.shared.localizedString("Золотая лига"))),
            .init(id:"preview-message",title:"World Arena",body:LocalizationManager.shared.localizedString("inbox.explanation"),date:Date().addingTimeInterval(-86400),source:"preview",kind:"message",readAt:Date())
        ]
        unreadCount=2
    }
}
#endif
