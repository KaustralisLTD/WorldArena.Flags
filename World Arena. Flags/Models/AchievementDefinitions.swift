import Foundation
import SwiftUI

struct AchievementDefinition: Identifiable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let icon: String
    let color: Color
    let target: AchievementTarget
    /// Имя изображения в Assets.xcassets для миниатюры и детального экрана
    let imageAssetName: String?
}

enum AchievementTarget {
    case streak(Int)
    case xp(Int)
    case games(Int)
    case accuracy(Int)
    case league(League)
    case friends(Int)
    case shares(Int)
    case level(Int)
}

extension UserProfile {
    var allAchievementDefinitions: [AchievementDefinition] {
        [
            AchievementDefinition(id: "streak_5", titleKey: "Ранняя птица", descriptionKey: "Достигните серии 5 дней", icon: "sun.max.fill", color: .orange, target: .streak(5), imageAssetName: "Ach_streak_5"),
            AchievementDefinition(id: "streak_10", titleKey: "Стабильность", descriptionKey: "Серия 10 дней", icon: "flame.fill", color: .red, target: .streak(10), imageAssetName: "Ach_streak_10"),
            AchievementDefinition(id: "streak_30", titleKey: "Железная воля", descriptionKey: "Серия 30 дней", icon: "bolt.fill", color: .yellow, target: .streak(30), imageAssetName: "Ach_streak_30"),
            AchievementDefinition(id: "xp_1000", titleKey: "Новичок XP", descriptionKey: "Наберите 1000 XP", icon: "star.fill", color: .yellow, target: .xp(1000), imageAssetName: "Ach_xp_1000"),
            AchievementDefinition(id: "xp_5000", titleKey: "Олимпиец XP", descriptionKey: "Наберите 5000 XP", icon: "star.circle.fill", color: .blue, target: .xp(5000), imageAssetName: "Ach_xp_5000"),
            AchievementDefinition(id: "xp_10000", titleKey: "Легенда XP", descriptionKey: "Наберите 10000 XP", icon: "sparkles", color: .purple, target: .xp(10000), imageAssetName: "Ach_xp_10000"),
            AchievementDefinition(id: "games_20", titleKey: "Исследователь", descriptionKey: "Сыграйте 20 игр", icon: "gamecontroller.fill", color: .green, target: .games(20), imageAssetName: "Ach_games_20"),
            AchievementDefinition(id: "games_100", titleKey: "Ветеран", descriptionKey: "Сыграйте 100 игр", icon: "gamecontroller", color: .teal, target: .games(100), imageAssetName: "Ach_games_100"),
            AchievementDefinition(id: "acc_70", titleKey: "Меткий стрелок", descriptionKey: "Точность 70%", icon: "scope", color: .pink, target: .accuracy(70), imageAssetName: "Ach_acc_70"),
            AchievementDefinition(id: "acc_85", titleKey: "Снайпер", descriptionKey: "Точность 85%", icon: "target", color: .indigo, target: .accuracy(85), imageAssetName: "Ach_acc_85"),
            AchievementDefinition(id: "league_silver", titleKey: "Серебряная лига", descriptionKey: "Достигните Серебра", icon: "medal.fill", color: .gray, target: .league(.silver), imageAssetName: "Ach_league_silver"),
            AchievementDefinition(id: "league_gold", titleKey: "Золотая лига", descriptionKey: "Достигните Золота", icon: "medal.fill", color: .yellow, target: .league(.gold), imageAssetName: "Ach_league_gold"),
            AchievementDefinition(id: "league_platinum", titleKey: "Платиновая лига", descriptionKey: "Достигните Платины", icon: "crown.fill", color: .blue, target: .league(.platinum), imageAssetName: "Ach_league_platinum"),
            AchievementDefinition(id: "league_diamond", titleKey: "Алмазная лига", descriptionKey: "Достигните Алмаза", icon: "diamond.fill", color: .cyan, target: .league(.diamond), imageAssetName: "Ach_league_diamond"),
            AchievementDefinition(id: "league_master", titleKey: "Мастер лиг", descriptionKey: "Достигните Мастера", icon: "star.fill", color: .purple, target: .league(.master), imageAssetName: "Ach_league_master"),
            AchievementDefinition(id: "friends_1", titleKey: "Первый друг", descriptionKey: "Добавьте друга", icon: "person.2.fill", color: .orange, target: .friends(1), imageAssetName: "Ach_friends_1"),
            AchievementDefinition(id: "friends_5", titleKey: "Своя команда", descriptionKey: "Добавьте 5 друзей", icon: "person.3.fill", color: .mint, target: .friends(5), imageAssetName: "Ach_friends_5"),
            AchievementDefinition(id: "share_1", titleKey: "Расскажите друзьям", descriptionKey: "Поделитесь профилем", icon: "square.and.arrow.up", color: .blue, target: .shares(1), imageAssetName: "Ach_share_1"),
            AchievementDefinition(id: "games_10_day", titleKey: "Спринтер", descriptionKey: "Сыграйте 10 игр за день", icon: "hare.fill", color: .red, target: .games(10), imageAssetName: "Ach_games_10_day"),
            AchievementDefinition(id: "xp_30000", titleKey: "Мастер Олимпиец XP", descriptionKey: "Наберите 30000 XP", icon: "trophy.fill", color: .orange, target: .xp(30000), imageAssetName: "Ach_xp_30000"),
            AchievementDefinition(id: "journey_streak_60", titleKey: "achievement.streak_60.title", descriptionKey: "achievement.streak_60.body", icon: "sun.horizon.fill", color: .orange, target: .streak(60), imageAssetName: nil),
            AchievementDefinition(id: "journey_streak_100", titleKey: "achievement.streak_100.title", descriptionKey: "achievement.streak_100.body", icon: "flame.circle.fill", color: .red, target: .streak(100), imageAssetName: nil),
            AchievementDefinition(id: "journey_streak_365", titleKey: "achievement.streak_365.title", descriptionKey: "achievement.streak_365.body", icon: "globe.americas.fill", color: .yellow, target: .streak(365), imageAssetName: nil),
            AchievementDefinition(id: "journey_games_250", titleKey: "achievement.games_250.title", descriptionKey: "achievement.games_250.body", icon: "binoculars.fill", color: .teal, target: .games(250), imageAssetName: nil),
            AchievementDefinition(id: "journey_games_500", titleKey: "achievement.games_500.title", descriptionKey: "achievement.games_500.body", icon: "globe.europe.africa.fill", color: .cyan, target: .games(500), imageAssetName: nil),
            AchievementDefinition(id: "journey_games_1000", titleKey: "achievement.games_1000.title", descriptionKey: "achievement.games_1000.body", icon: "safari.fill", color: .indigo, target: .games(1000), imageAssetName: nil),
            AchievementDefinition(id: "journey_xp_50000", titleKey: "achievement.xp_50000.title", descriptionKey: "achievement.xp_50000.body", icon: "bolt.shield.fill", color: .blue, target: .xp(50000), imageAssetName: nil),
            AchievementDefinition(id: "journey_xp_100000", titleKey: "achievement.xp_100000.title", descriptionKey: "achievement.xp_100000.body", icon: "crown.fill", color: .purple, target: .xp(100000), imageAssetName: nil),
            AchievementDefinition(id: "journey_level_25", titleKey: "achievement.level_25.title", descriptionKey: "achievement.level_25.body", icon: "mountain.2.fill", color: .mint, target: .level(25), imageAssetName: nil),
            AchievementDefinition(id: "journey_level_50", titleKey: "achievement.level_50.title", descriptionKey: "achievement.level_50.body", icon: "flag.2.crossed.fill", color: .orange, target: .level(50), imageAssetName: nil),
            AchievementDefinition(id: "journey_level_100", titleKey: "achievement.level_100.title", descriptionKey: "achievement.level_100.body", icon: "trophy.circle.fill", color: .yellow, target: .level(100), imageAssetName: nil),
            AchievementDefinition(id: "journey_friends_10", titleKey: "achievement.friends_10.title", descriptionKey: "achievement.friends_10.body", icon: "person.3.sequence.fill", color: .pink, target: .friends(10), imageAssetName: nil)
        ]
    }
    
    func isAchievementUnlocked(id: String) -> Bool {
        achievements.contains { $0.definitionId == id }
    }
    
    func progress(for def: AchievementDefinition) -> (current: Int, target: Int) {
        switch def.target {
        case .level(let t): return (level, t)
        case .streak(let t): return (streak, t)
        case .xp(let t): return (xp, t)
        case .games(let t): return (totalGamesPlayed, t)
        case .accuracy(let t): return (Int(accuracy.rounded()), t)
        case .league(let l):
            let order = League.allCases
            let current = (order.firstIndex(of: currentLeague) ?? 0)
            let target = (order.firstIndex(of: l) ?? 0)
            return (current, target)
        case .friends(let t): return (friends.count, t)
        case .shares(let t):
            let count = UserDefaults.standard.integer(forKey: "profileShareCount")
            return (count, t)
        }
    }
    
    func evaluateAchievementsAndUnlock() {
        var updated = achievements
        for def in allAchievementDefinitions {
            if isAchievementUnlocked(id: def.id) { continue }
            let p = progress(for: def)
            if p.current >= p.target {
                let record = Achievement(
                    id: UUID(),
                    definitionId: def.id,
                    title: def.titleKey,
                    description: def.descriptionKey,
                    icon: def.icon,
                    color: def.color,
                    unlockedDate: Date(),
                    rarity: .rare
                )
                updated.append(record)
                let coveredByLevelCelebration: Bool
                if case .level(let target) = def.target { coveredByLevelCelebration = LevelProgression.isCelebrationLevel(target) }
                else { coveredByLevelCelebration = false }
                if !coveredByLevelCelebration {
                    NotificationService.shared.notifyProgress(id: "achievement_" + def.id,
                        title: LocalizationManager.shared.localizedString("Достижения"),
                        body: LocalizationManager.shared.localizedString(def.titleKey), preference: "achievementNotifications", details: .init(achievementID: def.id))
                }
            }
        }
        if updated.count != achievements.count {
            achievements = updated
        }

        // Game Center: репортим текущий прогресс (с троттлингом в сервисе).
        #if os(iOS) && canImport(GameKit)
        GameCenterAchievementsService.shared.reportAllAchievementsProgress(userProfile: self)
        #endif
    }
}


