import Foundation

/// Relocalizes known event identities, not arbitrary messages or player names.
@MainActor
enum NotificationTextLocalization {
    private static let legacyKeys = ["Бронза", "Серебро", "Золото", "Платина", "Алмаз", "Мастер", "Бронзовая лига", "Серебряная лига", "Золотая лига", "Лига Мастеров", "Лига Чемпионов Мира", "Well done! Keep practicing!"] + (1...16).map { "nudge_phrase_" + String($0) }
    private static let aliases: [String: String] = {
        var result: [String: String] = [:]
        for code in Bundle.main.localizations {
            guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { continue }
            for key in legacyKeys {
                let value = bundle.localizedString(forKey: key, value: key, table: nil)
                result[value] = key
            }
        }
        for key in legacyKeys { result[key] = key }
        return result
    }()
    static func legacyKey(for value: String, prefix: String? = nil) -> String? {
        guard let key = aliases[value], prefix == nil || key.hasPrefix(prefix!) else { return nil }
        return key
    }
    static func format(_ key: String, args: [String]) -> String {
        // The wire format accepts string arguments only. Never pass remote keys
        // to String(format:) with unknown numeric specifiers or argument counts.
        let template = LocalizationManager.shared.localizedString(key)
        let parts = template.components(separatedBy: "%@")
        guard parts.count == args.count + 1 else { return template }
        return zip(parts.dropLast(), args).map { $0 + $1 }.joined() + (parts.last ?? "")
    }
    static func details(from payload: [AnyHashable: Any]) -> AppNotificationLogItem.Details? {
        if let object = payload["details"], JSONSerialization.isValidJSONObject(object),
           let data = try? JSONSerialization.data(withJSONObject: object),
           let details = try? JSONDecoder().decode(AppNotificationLogItem.Details.self, from: data) { return details }
        if let name = payload["fromUsername"] as? String { return .init(senderName: name, phraseID: payload["phraseID"] as? Int) }
        if let name = payload["challengerName"] as? String { return .init(opponentName: name) }
        return nil
    }
}
