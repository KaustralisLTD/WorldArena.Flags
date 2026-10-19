import Foundation

/// Notification history may predate structured achievement payloads. Resolve a
/// stable catalog identity before choosing artwork, without relying on UI language.
@MainActor
enum NotificationAchievementLookup {
    private static let definitions = UserProfile.shared.allAchievementDefinitions
    private static let byID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
    private static let byTitle: [String: AchievementDefinition] = {
        let bundles = Bundle.main.localizations.compactMap { code in
            Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:))
        }
        var result: [String: AchievementDefinition] = [:]
        for definition in definitions {
            result[definition.titleKey] = definition
            for bundle in bundles {
                let title = bundle.localizedString(forKey: definition.titleKey, value: nil, table: nil)
                result[title] = definition
            }
        }
        return result
    }()

    static func definition(for item: AppNotificationLogItem) -> AchievementDefinition? {
        if let id = item.details?.achievementID, !id.isEmpty { return byID[id] }
        if item.id.hasPrefix("achievement_") {
            return byID[String(item.id.dropFirst("achievement_".count))]
        }
        // Level 25/50/100 celebrations use the same badge as their collection entry.
        let level = item.details?.level ?? (item.id.hasPrefix("level_") ? Int(item.id.dropFirst("level_".count)) : nil)
        if let level {
            return definitions.first { definition in
                if case .level(let target) = definition.target { return target == level }
                return false
            }
        }
        guard item.kind == "progress" || item.source == "progress" else { return nil }
        // Old local entries sometimes stored only the translated title and goal.
        let title = item.body.components(separatedBy: " · ").first ?? item.body
        return byTitle[title]
    }
}

extension AppNotificationLogItem {
    @MainActor var achievementDefinition: AchievementDefinition? {
        NotificationAchievementLookup.definition(for: self)
    }
}
