import Foundation
import SwiftUI

struct AchievementDefinition: Identifiable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let icon: String
    let color: Color
    let target: AchievementTarget
}

enum AchievementTarget {
    case streak(Int)
    case xp(Int)
    case games(Int)
    case accuracy(Int)
    case league(League)
    case friends(Int)
    case shares(Int)
}

extension UserProfile {
    var allAchievementDefinitions: [AchievementDefinition] {
        [
            AchievementDefinition(id: "streak_5", titleKey: "Ранняя птица", descriptionKey: "Достигните серии 5 дней", icon: "sun.max.fill", color: .orange, target: .streak(5)),
            AchievementDefinition(id: "streak_10", titleKey: "Стабильность", descriptionKey: "Серия 10 дней", icon: "flame.fill", color: .red, target: .streak(10)),
            AchievementDefinition(id: "streak_30", titleKey: "Железная воля", descriptionKey: "Серия 30 дней", icon: "bolt.fill", color: .yellow, target: .streak(30)),
            AchievementDefinition(id: "xp_1000", titleKey: "Новичок XP", descriptionKey: "Наберите 1000 XP", icon: "star.fill", color: .yellow, target: .xp(1000)),
            AchievementDefinition(id: "xp_5000", titleKey: "Олимпиец XP", descriptionKey: "Наберите 5000 XP", icon: "star.circle.fill", color: .blue, target: .xp(5000)),
            AchievementDefinition(id: "xp_10000", titleKey: "Легенда XP", descriptionKey: "Наберите 10000 XP", icon: "sparkles", color: .purple, target: .xp(10000)),
            AchievementDefinition(id: "games_20", titleKey: "Исследователь", descriptionKey: "Сыграйте 20 игр", icon: "gamecontroller.fill", color: .green, target: .games(20)),
            AchievementDefinition(id: "games_100", titleKey: "Ветеран", descriptionKey: "Сыграйте 100 игр", icon: "gamecontroller", color: .teal, target: .games(100)),
            AchievementDefinition(id: "acc_70", titleKey: "Меткий стрелок", descriptionKey: "Точность 70%", icon: "scope", color: .pink, target: .accuracy(70)),
            AchievementDefinition(id: "acc_85", titleKey: "Снайпер", descriptionKey: "Точность 85%", icon: "target", color: .indigo, target: .accuracy(85)),
            AchievementDefinition(id: "league_silver", titleKey: "Серебряная лига", descriptionKey: "Достигните Серебра", icon: "medal.fill", color: .gray, target: .league(.silver)),
            AchievementDefinition(id: "league_gold", titleKey: "Золотая лига", descriptionKey: "Достигните Золота", icon: "medal.fill", color: .yellow, target: .league(.gold)),
            AchievementDefinition(id: "league_platinum", titleKey: "Платиновая лига", descriptionKey: "Достигните Платины", icon: "crown.fill", color: .blue, target: .league(.platinum)),
            AchievementDefinition(id: "league_diamond", titleKey: "Алмазная лига", descriptionKey: "Достигните Алмаза", icon: "diamond.fill", color: .cyan, target: .league(.diamond)),
            AchievementDefinition(id: "league_master", titleKey: "Мастер лиг", descriptionKey: "Достигните Мастера", icon: "star.fill", color: .purple, target: .league(.master)),
            AchievementDefinition(id: "friends_1", titleKey: "Первый друг", descriptionKey: "Добавьте друга", icon: "person.2.fill", color: .orange, target: .friends(1)),
            AchievementDefinition(id: "friends_5", titleKey: "Своя команда", descriptionKey: "Добавьте 5 друзей", icon: "person.3.fill", color: .mint, target: .friends(5)),
            AchievementDefinition(id: "share_1", titleKey: "Расскажите друзьям", descriptionKey: "Поделитесь профилем", icon: "square.and.arrow.up", color: .blue, target: .shares(1)),
            AchievementDefinition(id: "games_10_day", titleKey: "Спринтер", descriptionKey: "Сыграйте 10 игр за день", icon: "hare.fill", color: .red, target: .games(10)),
            AchievementDefinition(id: "xp_30000", titleKey: "XP Олимпиец", descriptionKey: "Наберите 30000 XP", icon: "trophy.fill", color: .orange, target: .xp(30000))
        ]
    }
    
    func isAchievementUnlocked(id: String) -> Bool {
        achievements.contains { $0.id.uuidString == id }
    }
    
    func progress(for def: AchievementDefinition) -> (current: Int, target: Int) {
        switch def.target {
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
                    id: UUID(uuidString: def.id) ?? UUID(),
                    title: def.titleKey,
                    description: def.descriptionKey,
                    icon: def.icon,
                    color: def.color,
                    unlockedDate: Date(),
                    rarity: .rare
                )
                updated.append(record)
            }
        }
        if updated.count != achievements.count {
            achievements = updated
        }
    }
}


