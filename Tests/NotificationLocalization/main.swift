import Foundation

// Dependency fixtures keep the regression harness offline. The event model and
// localization helper below are extracted verbatim from production Swift files.
@MainActor final class LocalizationManager {
    static let shared = LocalizationManager()
    var currentBundleLanguageCode = "en"
    func localizedString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentBundleLanguageCode, ofType: "lproj"), let bundle = Bundle(path: path) else { fatalError("Missing test bundle: " + currentBundleLanguageCode) }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
struct AchievementDefinition { let titleKey: String }
enum League: String {
    case gold = "Золото"
    @MainActor var localizedFullName: String { LocalizationManager.shared.localizedString("Золотая лига") }
}
extension AppNotificationLogItem {
    @MainActor var achievementDefinition: AchievementDefinition? {
        details?.achievementID == "journey_streak_100" || id == "achievement_journey_streak_100" ? AchievementDefinition(titleKey: "achievement.streak_100.title") : nil
    }
}
// PRODUCTION_MODEL
// PRODUCTION_HELPER

@MainActor func verifyNotifications() {
    let lm = LocalizationManager.shared
    let languages = ["en","ru","uk","es","ca","zh","zh-Hant","de","fr","it","pt-BR","pl","nl","hi","cs","sv","ja","ar","bn","hu","vi","el","id","ko","ro","th","ta","te","tr","fil"]
    let level = AppNotificationLogItem(id: "level_100", title: "Level 100", body: "Well done! Keep practicing!", date: nil, source: "progress", kind: "progress", details: .init(level: 100, xp: 99000))
    let achievement = AppNotificationLogItem(id: "achievement_journey_streak_100", title: "Achievements", body: "100 days of fire", date: nil, source: "progress", kind: "progress", details: .init(achievementID: "journey_streak_100"))
    let league = AppNotificationLogItem(id: "league_old", title: "Leagues", body: "Gold League", date: nil, source: "server", kind: "progress", details: .init(rank: 2, league: "Gold League"))
    let name = "Ірина %@ 李"
    let friend = AppNotificationLogItem(id: "friend", title: "World Arena", body: name + " added you as a friend. Open the app to add them back or decline.", date: nil, source: "server", kind: "friend_request")
    let nudge = AppNotificationLogItem(id: "nudge", title: "Alice reminds you", body: "Don't give up! You've got this!", date: nil, source: "server", kind: "nudge")
    for language in languages {
        lm.currentBundleLanguageCode = language
        let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: englishPath).appendingPathComponent("Localizable.strings"))
        let english = try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: String]
        let localePath = Bundle.main.path(forResource: language, ofType: "lproj")!
        let localeBundle = Bundle(path: localePath)!
        for key in english.keys {
            let value = localeBundle.localizedString(forKey: key, value: "__MISSING__", table: nil)
            assert(value != "__MISSING__" && !value.isEmpty, "Missing bundled translation: \(language) / \(key)")
        }
        let timer = String(format: lm.localizedString("You will receive +%d new lives in %02d:%02d"), 7, 12, 34)
        assert(timer.contains("12:34") && timer.contains("7"), "Reordered timer arguments: \(language) / \(timer)")
        let recovery = String(format: lm.localizedString("streak.recovery.body_fmt"), 17, 23)
        assert(recovery.contains("17") && recovery.contains("23"), "Lost recovery arguments: \(language)")
        let accuracy = String(format: lm.localizedString("Теперь вы можете без единой ошибки отвечать на все наши вопросы с точностью в %d%%"), 87)
        assert(accuracy.contains("87%"), "Missing formatted accuracy: \(language)")
        assert(level.displayTitle == lm.localizedString("Уровень") + " 100")
        assert(level.displayBody == lm.localizedString("Well done! Keep practicing!") + " · 99000 XP")
        assert(achievement.displayTitle == lm.localizedString("Достижения"))
        assert(achievement.displayBody == lm.localizedString("achievement.streak_100.title"))
        assert(league.displayBody == lm.localizedString("Золотая лига") + " · #2")
        assert(friend.displayTitle == lm.localizedString("friends.requests.title"))
        assert(friend.displayBody == name + ": " + lm.localizedString("friends.requests.body"))
        assert(nudge.displayBody == lm.localizedString("nudge_phrase_1"))
        let invite = AppNotificationLogItem(id: "invite", title: "Duel", body: name + " challenged you to a duel", date: nil, source: "server", kind: "duel_challenge")
        assert(invite.displayBody == lm.localizedString("Duel challenge from %@").replacingOccurrences(of: "%@", with: name))
        let result = AppNotificationLogItem(id: "result", title: "Duel victory!", body: "old", date: nil, source: "server", kind: "duel_result", details: .init(opponentName: name, myScore: 15, opponentScore: 14, iWon: true))
        assert(result.displayTitle == lm.localizedString("Victory"))
        assert(result.displayBody == lm.localizedString("You") + ": 15 · " + name + ": 14")
    }
    lm.currentBundleLanguageCode = "ru"
    assert(level.displayTitle == "Уровень 100")
    let legacyResult = AppNotificationLogItem(id: "old-result", title: "Duel victory!", body: "You won against Alice. Your score: 15; opponent: 14.", date: nil, source: "server", kind: "duel_result", details: .init())
    assert(legacyResult.displayTitle == lm.localizedString("Victory"))
    assert(legacyResult.displayBody == lm.localizedString("You") + ": 15 · Alice: 14")
    let original = AppNotificationLogItem(id: "custom", title: "User text", body: "Do not translate my message", date: nil, source: "server")
    assert(original.displayTitle == original.title && original.displayBody == original.body)
    let lifecycle = AppNotificationLogItem(id: "campaign", title: "Week", body: "Wins: 3", date: nil, source: "server", kind: "lifecycle", details: .init(localizedTitles: ["ru":"Неделя"], localizedBodies: ["ru":"Победы: 3"]))
    assert(lifecycle.displayTitle == "Неделя" && lifecycle.displayBody == "Победы: 3")
    let payload: [AnyHashable: Any] = ["type":"duel_result", "details":["opponentName":"Bob", "myScore":15, "opponentScore":14, "iWon":true]]
    assert(NotificationTextLocalization.details(from: payload)?.myScore == 15)
    let json = try! JSONEncoder().encode(level)
    let restored = try! JSONDecoder().decode(AppNotificationLogItem.self, from: json)
    assert(restored.displayTitle == level.displayTitle && restored.readAt == level.readAt)
    assert(level.readAt == nil && level.deduplicationKey == "level_100")
    print("Localization: all app keys in 30 bundles, timers, recovery, accuracy, cached events, names, scores and read state passed")
}
MainActor.assumeIsolated { verifyNotifications() }
