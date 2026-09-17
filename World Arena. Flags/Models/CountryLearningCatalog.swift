import Foundation

/// Списки стран для Learning / AllCountries / Continent — из CountryDatabase + country_regions.json.
enum CountryLearningCatalog {
    private struct RegionMeta: Codable {
        let region: String
        let subregion: String
        let cca3: String
    }

    private static let excludedCodes: Set<String> = ["AQ", "BV", "HM", "TF", "GS", "UM"]

    private static let regionsByCode: [String: RegionMeta] = {
        guard let url = Bundle.main.url(forResource: "country_regions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: RegionMeta].self, from: data) else {
            print("⚠️ CountryLearningCatalog: country_regions.json missing")
            return [:]
        }
        return decoded
    }()

    static var allCountryInfos: [CountryInfo] {
        CountryDatabase.allCountries.compactMap { loc in
            let code = loc.en.code.uppercased()
            guard !excludedCodes.contains(code) else { return nil }
            let en = loc.en
            return CountryInfo(name: en.name, flag: en.flag, capital: en.capital, code: code)
        }
    }

    static func countries(forContinentName continent: String) -> [CountryInfo] {
        allCountryInfos.filter { matchesContinent($0.code, continentName: continent) }
    }

    private static func matchesContinent(_ code: String, continentName: String) -> Bool {
        guard let meta = regionsByCode[code.uppercased()] else { return false }
        switch continentName {
        case "Европа":
            return meta.region == "Europe"
        case "Азия":
            return meta.region == "Asia"
        case "Африка":
            return meta.region == "Africa"
        case "Океания":
            return meta.region == "Oceania"
        case "Северная Америка":
            return meta.region == "Americas" && (
                meta.subregion == "Northern America" ||
                meta.subregion == "Central America" ||
                meta.subregion == "Caribbean"
            )
        case "Южная Америка":
            return meta.region == "Americas" && meta.subregion == "South America"
        default:
            return false
        }
    }
}
