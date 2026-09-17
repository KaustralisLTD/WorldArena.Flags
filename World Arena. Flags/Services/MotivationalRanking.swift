import Foundation

/// Мотивационные «глобальный / по стране» ранги: один алгоритм для профиля и карточки друга (детерминированно от статистики).
enum MotivationalRanking {
    /// Общий верхний предел «участников» (без заявления о реальном MAU).
    static let maxGlobalParticipants = 100_000
    static let minCountryPool = 500

    struct Inputs: Sendable {
        let username: String
        let joinDate: Date
        let xp: Int
        let streak: Int
        let totalGamesPlayed: Int
        let correctAnswers: Int
        /// Локальный `totalAnswers` у себя в профиле; у друга с сервера может не быть — тогда 0.
        let totalAnswersStored: Int
        let leagueTierIndex: Int
    }

    static func leagueTierIndex(_ league: League) -> Int {
        switch league {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        case .diamond: return 4
        case .master: return 5
        }
    }

    /// Нижняя оценка числа ответов, если с сервера нет `totalAnswers`.
    static func effectiveTotalAnswers(games: Int, correct: Int, storedTotal: Int) -> Int {
        let floorFromGames = max(1, games * 6)
        return max(max(storedTotal, correct), floorFromGames)
    }

    static func stableSeed(username: String, joinDate: Date, salt: String) -> Int {
        let raw = "\(username)|\(Int(joinDate.timeIntervalSince1970))|\(salt)"
        return raw.unicodeScalars.reduce(17) { ($0 &* 31) &+ Int($1.value) } & Int.max
    }

    static func worldRank(for inputs: Inputs) -> Int {
        let p = adjustedPercentile(inputs: inputs, salt: "WORLD")
        return rankFromPercentile(p, pool: maxGlobalParticipants)
    }

    static func countryRank(for inputs: Inputs, countryCode: String) -> Int {
        let upper = countryCode.uppercased()
        let pool = countryPool(for: upper)
        let p = adjustedPercentile(inputs: inputs, salt: "COUNTRY_\(upper)")
        return rankFromPercentile(p, pool: pool)
    }

    private static func rankFromPercentile(_ p: Double, pool: Int) -> Int {
        let bounded = min(0.995, max(0.01, p))
        return max(1, min(pool, Int((1.0 - bounded) * Double(pool)) + 1))
    }

    private static func adjustedPercentile(inputs: Inputs, salt: String) -> Double {
        let base = basePerformancePercentile(inputs: inputs)
        let jitter = (Double(stableSeed(username: inputs.username, joinDate: inputs.joinDate, salt: salt) % 1000) / 1000.0 - 0.5) * 0.028
        return min(0.995, max(0.01, base + jitter))
    }

    /// Выше процентиль → лучше игрок → ниже номер места. Сильнее реагирует на игры и точность.
    private static func basePerformancePercentile(inputs: Inputs) -> Double {
        let totalAns = effectiveTotalAnswers(
            games: inputs.totalGamesPlayed,
            correct: inputs.correctAnswers,
            storedTotal: inputs.totalAnswersStored
        )
        let accuracy = min(1.0, max(0.0, Double(inputs.correctAnswers) / Double(max(1, totalAns))))
        let xpNorm = min(1.0, log1p(Double(max(0, inputs.xp))) / log1p(120_000.0))
        let gamesNorm = min(1.0, log1p(Double(max(0, inputs.totalGamesPlayed))) / log1p(3_000.0))
        let answersNorm = min(1.0, log1p(Double(totalAns)) / log1p(45_000.0))
        let streakNorm = min(1.0, log1p(Double(max(0, inputs.streak))) / log1p(365.0))
        let leagueNorm = min(1.0, max(0.0, Double(inputs.leagueTierIndex) / 5.0))
        let consistency = min(1.0, accuracy * (0.52 + 0.48 * gamesNorm))

        var skill =
            0.36 * accuracy +
            0.20 * gamesNorm +
            0.18 * answersNorm +
            0.10 * xpNorm +
            0.08 * streakNorm +
            0.08 * leagueNorm

        skill += min(0.07, Double(inputs.totalGamesPlayed) / 3_500.0) * consistency
        skill = min(1.0, max(0.0, skill))
        return 0.02 + pow(skill, 1.28) * 0.965
    }

    /// Размер «пула по стране» не больше общего лимита; крупные страны получают больший подпул.
    private static func countryPool(for countryCode: String) -> Int {
        let pop = populationForCountry(countryCode)
        let raw = max(minCountryPool, min(maxGlobalParticipants, pop / 20_000))
        return min(maxGlobalParticipants, raw)
    }

    private static func populationForCountry(_ countryCode: String) -> Int {
        let upper = countryCode.uppercased()
        if let p = populationOverrides[upper] { return p }
        guard let country = CountryDatabase.getCountryData(for: upper) else { return 12_000_000 }
        let digits = country.en.population.filter { $0.isNumber }
        if let parsed = Int(digits), parsed > 100_000 { return parsed }
        return 12_000_000
    }

    private static let populationOverrides: [String: Int] = [
        "US": 334_000_000, "CN": 1_410_000_000, "IN": 1_430_000_000, "BR": 203_000_000,
        "ID": 278_000_000, "PK": 241_000_000, "NG": 223_000_000, "BD": 173_000_000,
        "RU": 146_000_000, "JP": 123_000_000, "MX": 129_000_000, "PH": 117_000_000,
        "VN": 100_000_000, "TR": 86_000_000, "DE": 84_000_000, "FR": 68_000_000,
        "GB": 68_000_000, "IT": 59_000_000, "ES": 48_000_000, "UA": 37_000_000,
        "PL": 38_000_000, "NL": 18_000_000, "CA": 40_000_000, "AU": 27_000_000,
        "SE": 10_500_000, "NO": 5_500_000, "CH": 8_900_000, "BE": 11_700_000
    ]
}

extension UserProfile {
    /// Данные для мотивационного ранга (свой профиль).
    func motivationalRankInputs(league: League) -> MotivationalRanking.Inputs {
        MotivationalRanking.Inputs(
            username: username,
            joinDate: joinDate,
            xp: xp,
            streak: streak,
            totalGamesPlayed: totalGamesPlayed,
            correctAnswers: correctAnswers,
            totalAnswersStored: totalAnswers,
            leagueTierIndex: MotivationalRanking.leagueTierIndex(league)
        )
    }
}

extension Friend {
    /// Данные для ранга друга (статистика с сервера + локальный joinDate).
    func motivationalRankInputs() -> MotivationalRanking.Inputs {
        let tier = min(5, max(0, level / 5))
        return MotivationalRanking.Inputs(
            username: username,
            joinDate: joinDate,
            xp: xp,
            streak: streak,
            totalGamesPlayed: totalGamesPlayed,
            correctAnswers: correctAnswers,
            totalAnswersStored: 0,
            leagueTierIndex: tier
        )
    }
}
