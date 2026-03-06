import Foundation
import SwiftUI

struct LeagueCompetitor: Codable, Identifiable {
    let id: UUID
    var name: String
    var flag: String
    var avatar: String
    var xp: Int
    var velocityPerHour: Double
    var lastUpdate: Date
}

@MainActor
final class LeaguesService: ObservableObject {
    static let shared = LeaguesService()

    private init() {}
    
    private static let onboardingStartDateKey = "leagues.onboardingStartDate"

    private func storageKey(for league: League, weekKey: String) -> String {
        return "leagues.competitors.\(league.rawValue).\(weekKey)"
    }

    private func currentWeekKeyGMT() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let y = comps.yearForWeekOfYear ?? 0
        let w = comps.weekOfYear ?? 0
        return "\(y)-W\(w)"
    }

    /// Текущий ключ недели (GMT) для проверки смены недели и показа попапа итогов лиги.
    func currentWeekKey() -> String {
        currentWeekKeyGMT()
    }

    private static let savedWeekKeyUD = "leagues.savedWeekKey"
    private static let savedPositionUD = "leagues.savedPosition"
    private static let savedLeagueUD = "leagues.savedLeague"

    private func ensureOnboardingStartDate() -> Date {
        if let saved = UserDefaults.standard.object(forKey: Self.onboardingStartDateKey) as? Date {
            return saved
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: Self.onboardingStartDateKey)
        return now
    }

    private func onboardingWeeksSinceStart() -> Int {
        let start = ensureOnboardingStartDate()
        let days = max(0, Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0)
        return max(1, days / 7 + 1)
    }

    /// Более мягкий режим лиг для первых недель:
    /// - ранний период: шире зона повышения, без понижения;
    /// - переходный: немного шире повышение, понижение только с последнего места.
    func leagueThresholds(for userProfile: UserProfile) -> (promote: ClosedRange<Int>, demote: ClosedRange<Int>?) {
        let weeks = onboardingWeeksSinceStart()
        if weeks <= 2 || userProfile.totalGamesPlayed < 40 {
            return (1...10, nil)
        }
        if weeks <= 4 || userProfile.totalGamesPlayed < 90 {
            return (1...8, 20...20)
        }
        return (1...5, 16...20)
    }

    /// Сохранить позицию и лигу пользователя за текущую неделю (вызывать при отображении лиги).
    func saveCurrentWeekResult(position: Int, league: League) {
        UserDefaults.standard.set(currentWeekKeyGMT(), forKey: Self.savedWeekKeyUD)
        UserDefaults.standard.set(position, forKey: Self.savedPositionUD)
        UserDefaults.standard.set(league.rawValue, forKey: Self.savedLeagueUD)
    }

    /// Если неделя сменилась — вернуть (место, лига за прошлую неделю); иначе nil. После вызова применить повышение/понижение и показать попап.
    func takePreviousWeekResultIfNeeded() -> (position: Int, league: League)? {
        let current = currentWeekKeyGMT()
        guard let savedKey = UserDefaults.standard.string(forKey: Self.savedWeekKeyUD),
              savedKey != current else { return nil }
        let pos = UserDefaults.standard.integer(forKey: Self.savedPositionUD)
        let raw = UserDefaults.standard.string(forKey: Self.savedLeagueUD) ?? League.bronze.rawValue
        let league = League(rawValue: raw) ?? .bronze
        return (pos > 0 ? pos : 20, league)
    }

    func loadCompetitors(for league: League) -> [LeagueCompetitor] {
        let key = storageKey(for: league, weekKey: currentWeekKeyGMT())
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([LeagueCompetitor].self, from: data) {
            return list
        }
        return []
    }

    func saveCompetitors(_ list: [LeagueCompetitor], for league: League) {
        let key = storageKey(for: league, weekKey: currentWeekKeyGMT())
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func ensureCompetitors(for league: League, around userXP: Int) -> [LeagueCompetitor] {
        var list = loadCompetitors(for: league)
        if list.isEmpty {
            // Сгенерировать 19 соперников с реалистичными скоростями
            let names = ["Michael","Emma","Lucas","Sofia","Chen","Yuki","Ahmed","Priya","Lars","Marie","Diego","Anna","Raj","Kim","Alex","Nina","Paolo","Liam","Zara","Maya","Oliver","Fatima","Erik","Lily","Hassan","Ingrid","Carlos","Aisha"]
            let flags = ["🇺🇸","🇬🇧","🇧🇷","🇪🇸","🇨🇳","🇯🇵","🇪🇬","🇮🇳","🇳🇴","🇫🇷","🇲🇽","🇩🇪","🇮🇳","🇰🇷","🇨🇦","🇷🇺","🇮🇹","🇮🇪","🇿🇦","🇹🇭","🇦🇺","🇲🇦","🇸🇪","🇳🇿","🇸🇦","🇩🇰","🇨🇱","🇳🇬"]
            let avatars = ["person.circle.fill","face.smiling","graduationcap.fill","star.fill","heart.fill","crown.fill","gamecontroller.fill","person.circle","face.dashed","star.circle"]
            var generated: [LeagueCompetitor] = []
            let base = max(100, userXP)
            for i in 0..<19 {
                let name = names[i % names.count]
                let flag = flags[i % flags.count]
                let avatar = avatars[i % avatars.count]
                // Скорости: 20–80 XP/час, чтобы за день активные могли набрать 500–1500 XP
                let v = Double(Int.random(in: 20...80))
                // Базовый XP вокруг пользователя с разбросом
                let xp0 = max(50, base + Int.random(in: -200...200))
                generated.append(LeagueCompetitor(id: UUID(), name: name, flag: flag, avatar: avatar, xp: xp0, velocityPerHour: v, lastUpdate: Date()))
            }
            saveCompetitors(generated, for: league)
            list = generated
        }
        return list
    }

    func tickCompetitors(for league: League) {
        var list = loadCompetitors(for: league)
        guard !list.isEmpty else { return }
        let now = Date()
        for idx in list.indices {
            let dt = now.timeIntervalSince(list[idx].lastUpdate)
            guard dt > 0 else { continue }
            let hours = dt / 3600.0
            // Немного случайности в наборе очков
            let gain = list[idx].velocityPerHour * hours * Double.random(in: 0.7...1.3)
            list[idx].xp += Int(gain)
            list[idx].lastUpdate = now
        }
        saveCompetitors(list, for: league)
    }

    func userGainedXP(_ points: Int, in league: League) {
        // При повышении пользователя — соперники тоже слегка растут прямо сейчас
        var list = loadCompetitors(for: league)
        let now = Date()
        for idx in list.indices {
            let bump = Int(Double(points) * Double.random(in: 0.2...0.6))
            list[idx].xp += bump
            list[idx].lastUpdate = now
        }
        saveCompetitors(list, for: league)
    }

    func leaderboardEntries(for league: League, userProfile: UserProfile) -> [LeaderboardEntry] {
        // Обновляем прогресс соперников с момента последнего апдейта
        tickCompetitors(for: league)
        // Гарантируем наличие
        var competitors = ensureCompetitors(for: league, around: userProfile.xp)
        // Готовим пул: соперники + текущий пользователь
        var all: [(name: String, flag: String, avatar: String, xp: Int, streak: Int, isUser: Bool)] = competitors.map {
            (name: $0.name, flag: $0.flag, avatar: $0.avatar, xp: $0.xp, streak: Int.random(in: 0...21), isUser: false)
        }
        let userFlag = userProfile.selectedCountryCode.map { FriendsService.countryCodeToFlagEmoji($0) } ?? "🏳️"
        all.append((name: userProfile.username, flag: userFlag, avatar: userProfile.avatar, xp: userProfile.xp, streak: userProfile.streak, isUser: true))
        // Сортируем по XP
        all.sort { $0.xp > $1.xp }
        // Собираем LeaderboardEntry
        var result: [LeaderboardEntry] = []
        for (i, item) in all.enumerated() {
            result.append(LeaderboardEntry(id: UUID(), position: i + 1, username: item.name, avatar: item.avatar, xp: item.xp, streak: item.streak, isCurrentUser: item.isUser, countryFlag: item.flag))
        }
        return result
    }
}


