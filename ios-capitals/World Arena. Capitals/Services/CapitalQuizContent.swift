import Foundation

@MainActor
enum CapitalQuizContent {
    static func answer(for country: Country) -> String {
        let capitals = country.capital ?? []
        guard capitals.count == 1 else { return capitals.joined(separator: " / ") }
        return CountryDatabase.getLocalizedCapitalName(for: country.countryCode,
            language: LocalizationManager.shared.currentBundleLanguageCode,
            fallback: capitals.first ?? "")
    }
    static func uniqueOptions(_ options: [Country], correct: Country, pool: [Country]) -> [Country] {
        let correctCapitals = Set(correct.capital ?? [])
        var usedLabels = Set<String>()
        var usedIDs = Set<String>()
        var result: [Country] = []
        // The same accepted capital cannot appear as a wrong answer.
        for country in options + pool.sorted(by: { $0.id < $1.id }) {
            guard result.count < options.count, !(country.capital ?? []).isEmpty else { continue }
            if country.id != correct.id && !(correctCapitals.intersection(country.capital ?? []).isEmpty) { continue }
            let label = (country.capital ?? []).joined(separator: " / ").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            guard !usedLabels.contains(label), usedIDs.insert(country.id).inserted else { continue }
            usedLabels.insert(label); result.append(country)
        }
        if !result.contains(where: { $0.id == correct.id }) {
            if result.count == options.count { result.removeLast() }
            result.append(correct)
        }
        return result
    }
}
