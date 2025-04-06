import Foundation

class CountryService {
    static let shared = CountryService()
    private let session: URLSession
    private let cache = NSCache<NSString, NSArray>()
    
    private let baseURL = "https://restcountries.com/v3.1"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        session = URLSession(configuration: config)
    }
    
    func fetchCountries(for regions: Set<GameState.Region>) async throws -> [Country] {
        print("Fetching countries for regions: \(regions.map { $0.rawValue })")
        
        // Если выбран регион "Мои ошибки", возвращаем сохраненные ошибки
        if regions.contains(.myMistakes) {
            print("\nLoading mistakes region...")
            // Используем UserDefaults напрямую
            if let data = UserDefaults.standard.data(forKey: "mistakeCountries"),
               let mistakes = try? JSONDecoder().decode([Country].self, from: data) {
                print("Loaded \(mistakes.count) mistakes from storage")
                return mistakes
            }
            print("No mistakes found in storage")
            return []
        }
        
        // Если выбраны все регионы, загружаем каждый регион отдельно
        if regions == [.all] {
            print("\nLoading all regions separately...")
            var allCountries: [Country] = []
            
            // Загружаем каждый регион отдельно
            for region in GameState.Region.allCases where region != .all {
                print("Fetching region: \(region.rawValue)")
                let regionPath = getRegionPath(for: region)
                let url = URL(string: "\(baseURL)/\(regionPath)")!
                let countries = try await fetchCountriesFromURL(url)
                
                // Фильтруем страны для Северной и Южной Америки
                let filteredCountries = filterCountriesForRegion(countries, region: region)
                allCountries.append(contentsOf: filteredCountries)
                
                print("Fetched \(filteredCountries.count) countries for \(region.rawValue)")
            }
            
            print("Total countries loaded: \(allCountries.count)")
            return allCountries.filter { $0.region != "Antarctic" }
        }
        
        // Для конкретных регионов используем существующую логику
        var allCountries: [Country] = []
        for region in regions {
            let regionPath = getRegionPath(for: region)
            let url = URL(string: "\(baseURL)/\(regionPath)")!
            let countries = try await fetchCountriesFromURL(url)
            let filteredCountries = filterCountriesForRegion(countries, region: region)
            allCountries.append(contentsOf: filteredCountries)
        }
        
        return allCountries.filter { $0.region != "Antarctic" }
    }
    
    private func getRegionPath(for region: GameState.Region) -> String {
        switch region {
        case .all:
            return "all"
        case .europe:
            return "region/europe"
        case .asia:
            return "region/asia"
        case .northAmerica, .southAmerica:
            return "region/americas"
        case .africa:
            return "region/africa"
        case .oceania:
            return "region/oceania"
        case .myMistakes:
            return "my-mistakes"
        }
    }
    
    private func filterCountriesForRegion(_ countries: [Country], region: GameState.Region) -> [Country] {
        switch region {
        case .northAmerica:
            return countries.filter { country in
                country.subregion == "Northern America" ||
                country.subregion == "Central America" ||
                country.subregion == "Caribbean"
            }
        case .southAmerica:
            return countries.filter { country in
                country.subregion == "South America"
            }
        default:
            return countries
        }
    }
    
    private func fetchAllCountries() async throws -> [Country] {
        let url = URL(string: "\(baseURL)/all")!
        return try await fetchCountriesFromURL(url)
    }
    
    private func fetchCountriesForRegion(_ region: GameState.Region) async throws -> [Country] {
        let regionPath = switch region {
        case .europe:
            "region/europe"
        case .asia:
            "region/asia"
        case .northAmerica, .southAmerica:
            "region/americas"
        case .africa:
            "region/africa"
        case .oceania:
            "region/oceania"
        case .all:
            "all"
        case .myMistakes:
            "my-mistakes"
        }
        
        print("Fetching countries from endpoint: \(baseURL)/\(regionPath)")
        let url = URL(string: "\(baseURL)/\(regionPath)")!
        var countries = try await fetchCountriesFromURL(url)
        
        // Дополнительная фильтрация для Северной и Южной Америки
        if region == .northAmerica {
            countries = countries.filter { country in
                country.subregion == "Northern America" ||
                country.subregion == "Central America" ||
                country.subregion == "Caribbean"
            }
        } else if region == .southAmerica {
            countries = countries.filter { country in
                country.subregion == "South America"
            }
        }
        
        return countries.filter { $0.region != "Antarctic" }
    }
    
    private func fetchCountriesFromURL(_ url: URL) async throws -> [Country] {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let countries = try decoder.decode([Country].self, from: data)
            return countries.filter { $0.region != "Antarctic" }
        case 404:
            return []
        case 429:
            throw NetworkError.tooManyRequests
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func fetchCountriesForRegionString(_ region: String) async throws -> [Country] {
        let regionPath = region.lowercased()
        print("Fetching countries from endpoint: \(baseURL)/region/\(regionPath)")
        let url = URL(string: "\(baseURL)/region/\(regionPath)")!
        return try await fetchCountriesFromURL(url)
    }
    
    func loadCountries(for regions: [String]) async throws -> [Country] {
        print("\n=== Loading Countries ===")
        print("Current regions:", regions)
        print("Fetching countries for regions:", regions)
        
        // Если выбраны все регионы, загружаем каждый регион отдельно
        if regions.contains("All Regions") {
            print("Loading all regions...")
            let allRegions = ["Europe", "Asia", "Africa", "Americas", "Oceania"]
            var allCountries: [Country] = []
            
            for region in allRegions {
                print("Fetching countries from endpoint: \(baseURL)/region/\(region.lowercased())")
                let countries = try await fetchCountriesForRegionString(region)
                allCountries.append(contentsOf: countries)
            }
            
            print("Loaded \(allCountries.count) countries from all regions")
            print("======================\n")
            return allCountries
        }
        
        // Загрузка для конкретных регионов
        var loadedCountries: [Country] = []
        
        for region in regions {
            if region == "South America" || region == "North America" {
                print("Fetching countries from endpoint: \(baseURL)/region/americas")
                let americasCountries = try await fetchCountriesForRegionString("Americas")
                let filteredCountries = americasCountries.filter { country in
                    if region == "South America" {
                        return country.subregion == "South America"
                    } else {
                        return country.subregion == "North America" || 
                               country.subregion == "Central America" || 
                               country.subregion == "Caribbean"
                    }
                }
                loadedCountries.append(contentsOf: filteredCountries)
            } else {
                print("Fetching countries from endpoint: \(baseURL)/region/\(region.lowercased())")
                let countries = try await fetchCountriesForRegionString(region)
                loadedCountries.append(contentsOf: countries)
            }
        }
        
        print("Loaded \(loadedCountries.count) countries")
        print("======================\n")
        return loadedCountries
    }
    
    func fetchCountries(for regions: [String]) async throws -> [Country] {
        print("Fetching countries for regions: \(regions)")
        var allCountries: [Country] = []
        
        for region in regions {
            // Пропускаем регион "My Mistakes", так как он обрабатывается в GameState
            if region.lowercased() == "my mistakes" {
                continue
            }
            
            let endpoint = "https://restcountries.com/v3.1/region/\(region.lowercased())"
            print("Fetching countries from endpoint: \(endpoint)")
            
            guard let url = URL(string: endpoint) else {
                print("Invalid URL for region: \(region)")
                continue
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let countries = try JSONDecoder().decode([Country].self, from: data)
                allCountries.append(contentsOf: countries)
                print("Loaded \(countries.count) countries from region \(region)")
            } catch {
                print("Error loading countries for region \(region): \(error)")
            }
        }
        
        print("Loaded \(allCountries.count) countries in total")
        return allCountries
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