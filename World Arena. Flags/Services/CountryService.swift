import Foundation

class CountryService {
    static let shared = CountryService()
    private let cache = NSCache<NSString, NSArray>()

    /// Локальный снимок стран для квиза (restcountries v1–v4 deprecated с 2026).
    private static let localCatalogResource = "game_countries"

    private init() {}

    private lazy var localCatalog: [Country] = {
        Self.loadLocalCatalog()
    }()

    private static func loadLocalCatalog() -> [Country] {
        guard let url = Bundle.main.url(forResource: localCatalogResource, withExtension: "json") else {
            print("❌ CountryService: \(localCatalogResource).json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let countries = try JSONDecoder().decode([Country].self, from: data)
            print("✅ CountryService: loaded \(countries.count) countries from local catalog")
            return countries.filter { $0.region != "Antarctic" }
        } catch {
            print("❌ CountryService: failed to decode local catalog: \(error)")
            return []
        }
    }

    func fetchCountries(for regions: Set<GameState.Region>) async throws -> [Country] {
        print("Fetching countries for regions: \(regions.map { $0.rawValue })")

        if regions.contains(.myMistakes) {
            print("\nLoading mistakes region...")
            if let data = UserDefaults.standard.data(forKey: "mistakeCountries"),
               let mistakes = try? JSONDecoder().decode([Country].self, from: data) {
                print("Loaded \(mistakes.count) mistakes from storage")
                return mistakes
            }
            print("No mistakes found in storage")
            return []
        }

        let catalog = localCatalog
        guard !catalog.isEmpty else {
            throw NetworkError.emptyResponse
        }

        if regions.contains(.all) || regions.isEmpty {
            let cacheKey = "local-all" as NSString
            if let cached = cache.object(forKey: cacheKey) as? [Country] {
                return cached
            }
            cache.setObject(catalog as NSArray, forKey: cacheKey)
            return catalog
        }

        var result: [Country] = []
        for region in regions where region != .all && region != .myMistakes {
            let cacheKey = "local-\(region.rawValue)" as NSString
            if let cached = cache.object(forKey: cacheKey) as? [Country] {
                result.append(contentsOf: cached)
                continue
            }
            let filtered = filterCountriesForRegion(catalog, region: region)
            cache.setObject(filtered as NSArray, forKey: cacheKey)
            result.append(contentsOf: filtered)
            print("Fetched \(filtered.count) countries for \(region.rawValue) (local)")
        }

        var seen = Set<String>()
        return result.filter { seen.insert($0.id).inserted }
    }

    private func filterCountriesForRegion(_ countries: [Country], region: GameState.Region) -> [Country] {
        switch region {
        case .europe:
            return countries.filter { $0.region == "Europe" }
        case .asia:
            return countries.filter { $0.region == "Asia" }
        case .africa:
            return countries.filter { $0.region == "Africa" }
        case .oceania:
            return countries.filter { $0.region == "Oceania" }
        case .northAmerica:
            return countries.filter { country in
                country.region == "Americas" && (
                    country.subregion == "Northern America" ||
                    country.subregion == "Central America" ||
                    country.subregion == "Caribbean"
                )
            }
        case .southAmerica:
            return countries.filter { country in
                country.region == "Americas" && country.subregion == "South America"
            }
        case .all, .myMistakes:
            return countries
        }
    }

    func loadCountries(for regions: [String]) async throws -> [Country] {
        if regions.contains("Americas") {
            let north = try await fetchCountries(for: [.northAmerica])
            let south = try await fetchCountries(for: [.southAmerica])
            return north + south
        }
        let mapped: Set<GameState.Region> = Set(regions.compactMap { name in
            switch name {
            case "All Regions": return .all
            case "Europe": return .europe
            case "Asia": return .asia
            case "Africa": return .africa
            case "Oceania": return .oceania
            case "North America", "Northern America": return .northAmerica
            case "South America": return .southAmerica
            case "My Mistakes": return .myMistakes
            default: return GameState.Region(rawValue: name)
            }
        })
        return try await fetchCountries(for: mapped.isEmpty ? [.all] : mapped)
    }

    func fetchCountries(for regions: [String]) async throws -> [Country] {
        try await loadCountries(for: regions)
    }
}

// MARK: - RestCountries full response for single country (detail screen)
struct RestCountryDetailResponse: Codable {
    let name: Name?
    let capital: [String]?
    let population: Int?
    let area: Double?
    let region: String?
    let subregion: String?
    let flags: Flags?
    let currencies: [String: CurrencyInfo]?
    let idd: Idd?
    let languages: [String: String]?

    struct Name: Codable {
        let common: String?
        let official: String?
    }
    struct Flags: Codable {
        let png: String?
    }
    struct CurrencyInfo: Codable {
        let name: String?
        let symbol: String?
    }
    struct Idd: Codable {
        let root: String?
        let suffixes: [String]?
    }

    var capitalFirst: String? { capital?.first }
    var dialingCode: String? {
        guard let root = idd?.root?.trimmingCharacters(in: CharacterSet(charactersIn: "+")),
              let suffix = idd?.suffixes?.first else { return nil }
        return "+" + root + suffix
    }
    var currencyString: String? {
        guard let cur = currencies?.first else { return nil }
        let name = cur.value.name ?? cur.key
        let sym = cur.value.symbol ?? ""
        return "\(name) (\(sym))".trimmingCharacters(in: CharacterSet(charactersIn: " ()"))
    }
    var languageString: String? {
        languages?.values.sorted().joined(separator: ", ")
    }
}

extension CountryService {
    /// Детали страны: из локального каталога (remote REST Countries v3.1 больше недоступен).
    func fetchCountryDetailByCode(_ code: String) async throws -> RestCountryDetailResponse? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let alpha3 = ISO3166.alpha2ToAlpha3[normalized] ?? (normalized.count == 3 ? normalized : nil)
        guard let a3 = alpha3,
              let country = localCatalog.first(where: { $0.id == a3 }) else {
            return nil
        }
        return RestCountryDetailResponse(
            name: .init(common: country.name.common, official: country.name.official),
            capital: country.capital,
            population: country.population,
            area: country.area,
            region: country.region,
            subregion: country.subregion,
            flags: .init(png: country.flagURL.absoluteString),
            currencies: nil,
            idd: nil,
            languages: nil
        )
    }
}

enum NetworkError: LocalizedError {
    case noInternet
    case timeout
    case hostNotFound
    case tooManyRequests
    case serverError
    case httpError(statusCode: Int)
    case emptyResponse
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return NSLocalizedString("No Internet Connection", comment: "")
        case .timeout:
            return NSLocalizedString("Request Timeout", comment: "")
        case .hostNotFound:
            return NSLocalizedString("Server Not Found", comment: "")
        case .tooManyRequests:
            return NSLocalizedString("Too Many Requests", comment: "")
        case .serverError:
            return NSLocalizedString("Server Error", comment: "")
        case .httpError(let statusCode):
            return String(format: NSLocalizedString("HTTP Error: %d", comment: ""), statusCode)
        case .emptyResponse:
            return NSLocalizedString("Empty response from server", comment: "")
        case .other(let error):
            return error.localizedDescription
        }
    }
}
