import Foundation
import SwiftUI

// MARK: - League Weekly Result (snapshot after week ends)
struct LeagueWeeklyResult: Codable, Equatable {
    var weekId: String
    var leagueBeforeId: String
    var leagueAfterId: String
    var finalRank: Int
    var participantsCount: Int
    var podiumPlace: Int? // 1, 2, 3 or nil
    var movement: String // "promoted", "stayed", "demoted"
    var rewardCoins: Int
    var rewardXp: Int
    var rewardBucks: Int
    var motivationMessageCode: String
    var homeBannerVisible: Bool
    var leagueResultSeenAt: Date?
    var createdAt: Date

    var leagueBefore: League? { League(rawValue: leagueBeforeId) }
    var leagueAfter: League? { League(rawValue: leagueAfterId) }
    var needsLeagueModal: Bool { leagueResultSeenAt == nil }
}

struct LeagueCompetitor: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    /// ISO alpha-2 код страны (для стабильного восстановления emoji-флага).
    var countryCode: String?
    var flag: String
    var avatar: String
    var xp: Int
    var velocityPerHour: Double
    var lastUpdate: Date
}

private enum LeagueMotivationCategory {
    case win, promotion, stayed, demotion, general
    static func codes(for category: LeagueMotivationCategory) -> [String] {
        switch category {
        case .win: return ["league_motivation_win_01", "league_motivation_win_02", "league_motivation_win_03"]
        case .promotion: return ["league_motivation_promotion_01", "league_motivation_promotion_02"]
        case .stayed: return ["league_motivation_stayed_01", "league_motivation_stayed_02"]
        case .demotion: return ["league_motivation_demotion_01", "league_motivation_demotion_02"]
        case .general: return ["league_motivation_general_01"]
        }
    }
}

@MainActor
final class LeaguesService: ObservableObject {
    static let shared = LeaguesService()

    private init() {
        loadLatestWeeklyResult()
    }

    private static let weeklyResultUD = "league.weeklyResult.latest"
    @Published private(set) var latestWeeklyResult: LeagueWeeklyResult?

    private static let firstLaunchWeekKeyUD = "leagues.firstLaunchWeekKey"

    /// Неделя первого запуска приложения — чтобы не показывать баннер «итог прошлой недели», если юзер установил приложение уже в новой неделе.
    func recordFirstLaunchWeekIfNeeded() {
        if UserDefaults.standard.string(forKey: Self.firstLaunchWeekKeyUD) != nil { return }
        UserDefaults.standard.set(currentWeekKey(), forKey: Self.firstLaunchWeekKeyUD)
    }

    /// Ключ ISO-недели (GMT) для предыдущей календарной недели относительно «сейчас».
    func previousWeekKeyGMT() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let prev = cal.date(byAdding: .weekOfYear, value: -1, to: Date()) else {
            return currentWeekKey()
        }
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: prev)
        let y = comps.yearForWeekOfYear ?? 0
        let w = comps.weekOfYear ?? 0
        return "\(y)-W\(w)"
    }

    /// Сравнение ключей вида "2025-W14" (год и номер недели).
    private func weekKeyTuple(_ key: String) -> (Int, Int)? {
        guard let r = key.range(of: "-W") else { return nil }
        let yearStr = String(key[..<r.lowerBound])
        let weekStr = String(key[r.upperBound...])
        guard let y = Int(yearStr), let w = Int(weekStr) else { return nil }
        return (y, w)
    }

    private func weekKey(_ a: String, isAtLeast b: String) -> Bool {
        guard let ta = weekKeyTuple(a), let tb = weekKeyTuple(b) else { return a >= b }
        if ta.0 != tb.0 { return ta.0 > tb.0 }
        return ta.1 >= tb.1
    }

    /// Баннер на главной только для только что завершившейся недели и только если юзер уже «существовал» в той неделе (не свежая установка после её окончания).
    func shouldShowWeeklyHomeBanner(for result: LeagueWeeklyResult) -> Bool {
        guard result.homeBannerVisible else { return false }
        guard result.weekId == previousWeekKeyGMT() else { return false }
        recordFirstLaunchWeekIfNeeded()
        let firstWeek = UserDefaults.standard.string(forKey: Self.firstLaunchWeekKeyUD) ?? currentWeekKey()
        return weekKey(result.weekId, isAtLeast: firstWeek)
    }

    private func loadLatestWeeklyResult() {
        recordFirstLaunchWeekIfNeeded()
        guard let data = UserDefaults.standard.data(forKey: Self.weeklyResultUD),
              let decoded = try? JSONDecoder().decode(LeagueWeeklyResult.self, from: data) else {
            latestWeeklyResult = nil
            return
        }
        latestWeeklyResult = decoded
    }

    private func saveWeeklyResult(_ result: LeagueWeeklyResult) {
        latestWeeklyResult = result
        if let data = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(data, forKey: Self.weeklyResultUD)
        }
    }

    /// Сохранить снимок итога недели (вызывать из LeaguesView при смене недели).
    func buildAndSaveWeeklyResult(
        position: Int,
        leagueBefore: League,
        newLeague: League,
        outcome: LeagueEndOutcome,
        userProfile: UserProfile
    ) {
        let weekId = currentWeekKeyGMT()
        let prevWeekKey = UserDefaults.standard.string(forKey: Self.savedWeekKeyUD) ?? weekId
        let podiumPlace: Int? = (1...3).contains(position) ? position : nil
        let movement: String
        switch outcome {
        case .promoted: movement = "promoted"
        case .stayed: movement = "stayed"
        case .demoted: movement = "demoted"
        }
        let category: LeagueMotivationCategory
        switch outcome {
        case .promoted: category = podiumPlace != nil ? .win : .promotion
        case .stayed: category = podiumPlace != nil ? .win : .stayed
        case .demoted: category = .demotion
        }
        let codes = LeagueMotivationCategory.codes(for: category)
        let motivationCode = codes.randomElement() ?? "league_motivation_general_01"
        var rewardBucks = 0
        if outcome == .promoted { rewardBucks = 1 }
        let result = LeagueWeeklyResult(
            weekId: prevWeekKey,
            leagueBeforeId: leagueBefore.rawValue,
            leagueAfterId: newLeague.rawValue,
            finalRank: position,
            participantsCount: 20,
            podiumPlace: podiumPlace,
            movement: movement,
            rewardCoins: 0,
            rewardXp: 0,
            rewardBucks: rewardBucks,
            motivationMessageCode: motivationCode,
            homeBannerVisible: true,
            leagueResultSeenAt: nil,
            createdAt: Date()
        )
        saveWeeklyResult(result)
    }

    func markLeagueResultSeen() {
        guard var r = latestWeeklyResult else { return }
        r.leagueResultSeenAt = Date()
        r.homeBannerVisible = false
        saveWeeklyResult(r)
    }

    func markHomeBannerDismissed() {
        guard var r = latestWeeklyResult else { return }
        r.homeBannerVisible = false
        saveWeeklyResult(r)
    }

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
    private static let userWeeklyXPWeekKeyUD = "leagues.userWeeklyXP.week"
    private static let userWeeklyXPValueUD = "leagues.userWeeklyXP.value"

    private func isLikelyBrokenFlag(_ flag: String) -> Bool {
        let trimmed = flag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        // Если в сохраненных данных попали "?" / "??", считаем флаг битым.
        return trimmed.contains("?")
    }

    private func normalizedLeagueCompetitor(_ c: LeagueCompetitor) -> LeagueCompetitor {
        var fixed = c
        if let code = c.countryCode, let normalized = FriendsService.normalizeCountryCode(code) {
            fixed.countryCode = normalized
            fixed.flag = FriendsService.countryCodeToFlagEmoji(normalized)
            return fixed
        }
        if isLikelyBrokenFlag(c.flag) {
            fixed.flag = "🏳️"
        }
        return fixed
    }

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

    private func ensureWeeklyXPState() {
        let week = currentWeekKeyGMT()
        let savedWeek = UserDefaults.standard.string(forKey: Self.userWeeklyXPWeekKeyUD)
        if savedWeek != week {
            UserDefaults.standard.set(week, forKey: Self.userWeeklyXPWeekKeyUD)
            UserDefaults.standard.set(0, forKey: Self.userWeeklyXPValueUD)
        }
    }

    func currentWeekUserXP() -> Int {
        ensureWeeklyXPState()
        return max(0, UserDefaults.standard.integer(forKey: Self.userWeeklyXPValueUD))
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
            let normalized = list.map(normalizedLeagueCompetitor)
            // Миграция старых/битых данных в актуальный формат хранения.
            if normalized != list {
                saveCompetitors(normalized, for: league)
            }
            return normalized
        }
        return []
    }

    func saveCompetitors(_ list: [LeagueCompetitor], for league: League) {
        let key = storageKey(for: league, weekKey: currentWeekKeyGMT())
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Коды стран для соперников: много UA (разработчик из Украины), без RU и BY.
    private static let leagueOpponentCountryCodes: [String] = {
        let uaCount = 10
        let other: [String] = ["GB","US","DE","FR","PL","IT","ES","NL","CA","BR","JP","IN","NO","SE","CZ","PT","GR","TR","AR","CO","AU","ZA","IE","MX","CH","KR","FI","AT","BE"]
        return (0..<uaCount).map { _ in "UA" } + Array(other.shuffled().prefix(19 - uaCount))
    }()

    func ensureCompetitors(for league: League, around _: Int) -> [LeagueCompetitor] {
        var list = loadCompetitors(for: league)
        if list.isEmpty {
            let localeCode = LocalizationManager.shared.currentBundleLanguageCode
            let avatars = ["person.circle.fill","face.smiling","graduationcap.fill","star.fill","heart.fill","crown.fill","gamecontroller.fill","person.circle","face.dashed","star.circle"]
            var codes = Self.leagueOpponentCountryCodes
            codes.shuffle()
            var generated: [LeagueCompetitor] = []
            for i in 0..<19 {
                let name = RandomOpponentNames.randomName(for: localeCode)
                let code = codes[i % codes.count]
                let flag = FriendsService.countryCodeToFlagEmoji(code)
                let avatar = avatars[i % avatars.count]
                let v = Double(Int.random(in: 20...80))
                let xp0 = Int.random(in: 0...120)
                generated.append(LeagueCompetitor(id: UUID(), name: name, countryCode: code, flag: flag, avatar: avatar, xp: xp0, velocityPerHour: v, lastUpdate: Date()))
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
        ensureWeeklyXPState()
        let current = UserDefaults.standard.integer(forKey: Self.userWeeklyXPValueUD)
        UserDefaults.standard.set(max(0, current + max(0, points)), forKey: Self.userWeeklyXPValueUD)
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
        let competitors = ensureCompetitors(for: league, around: userProfile.xp)
        let userWeekXP = currentWeekUserXP()
        // Готовим пул: соперники + текущий пользователь
        var all: [(name: String, flag: String, avatar: String, xp: Int, streak: Int, isUser: Bool)] = competitors.map {
            (name: $0.name, flag: $0.flag, avatar: $0.avatar, xp: $0.xp, streak: Int.random(in: 0...21), isUser: false)
        }
        let userFlag = userProfile.selectedCountryCode.map { FriendsService.countryCodeToFlagEmoji($0) } ?? "🏳️"
        all.append((name: userProfile.username, flag: userFlag, avatar: userProfile.avatar, xp: userWeekXP, streak: userProfile.streak, isUser: true))
        // Сортируем по XP
        all.sort { $0.xp > $1.xp }
        // Собираем LeaderboardEntry
        var result: [LeaderboardEntry] = []
        for (i, item) in all.enumerated() {
            result.append(LeaderboardEntry(id: UUID(), position: i + 1, username: item.name, avatar: item.avatar, xp: item.xp, streak: item.streak, isCurrentUser: item.isUser, countryFlag: item.flag))
        }
        return result
    }

    /// XP-цель для повышения в следующую лигу:
    /// берем XP у самого нижнего участника в зоне повышения и добавляем +10.
    /// Расчет без тика соперников, чтобы UI главной не менял таблицу при каждом рендере.
    func promotionTargetXP(for userProfile: UserProfile) -> Int? {
        let league = userProfile.currentLeague
        guard league.leagueAbove != nil else { return nil }

        let competitors = ensureCompetitors(for: league, around: userProfile.xp)
        let userWeekXP = currentWeekUserXP()
        let userFlag = userProfile.selectedCountryCode.map { FriendsService.countryCodeToFlagEmoji($0) } ?? "🏳️"

        var all: [(name: String, flag: String, avatar: String, xp: Int, streak: Int, isUser: Bool)] = competitors.map {
            (name: $0.name, flag: $0.flag, avatar: $0.avatar, xp: $0.xp, streak: Int.random(in: 0...21), isUser: false)
        }
        all.append((name: userProfile.username, flag: userFlag, avatar: userProfile.avatar, xp: userWeekXP, streak: userProfile.streak, isUser: true))
        all.sort { $0.xp > $1.xp }

        let promoteRange = leagueThresholds(for: userProfile).promote
        let boundaryIndex = promoteRange.upperBound - 1
        guard boundaryIndex >= 0, boundaryIndex < all.count else { return nil }

        return max(0, all[boundaryIndex].xp + 10)
    }
}


