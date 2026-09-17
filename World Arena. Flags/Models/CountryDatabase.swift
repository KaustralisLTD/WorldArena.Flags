import Foundation

// MARK: - Country Database
struct CountryDatabase {
    
    // MARK: - Main Database
    // Данные загружаются из JSON файлов для избежания проблем с синтаксисом Swift
    static let allCountries: [LocalizedCountryData] = {
        return loadCountriesFromJSON()
    }()
    
    // MARK: - JSON Loading
    private static func loadCountriesFromJSON() -> [LocalizedCountryData] {
        var allCountries: [LocalizedCountryData] = []
        
        // Загружаем данные из трех JSON файлов
        let jsonFiles = ["countries_part1", "countries_part2", "countries_part3"]
        
        for fileName in jsonFiles {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                print("⚠️ Warning: Could not find \(fileName).json in bundle")
                continue
            }
            
            guard let data = try? Data(contentsOf: url) else {
                print("⚠️ Warning: Could not read data from \(fileName).json")
                continue
            }
            
            guard let countries = try? JSONDecoder().decode([LocalizedCountryData].self, from: data) else {
                print("⚠️ Warning: Could not decode \(fileName).json")
                continue
            }
            
            allCountries.append(contentsOf: countries)
            print("✅ Загружено \(countries.count) стран из \(fileName).json")
        }
        
        print("✅ Всего загружено \(allCountries.count) стран из JSON файлов")
        return allCountries
    }
    
    // MARK: - Helper Functions
    static func getCountryData(for code: String) -> LocalizedCountryData? {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        return allCountries.first { $0.en.code.uppercased() == normalized }
    }
    
    static func getLocalizedCountryData(for code: String, language: String) -> CountryData? {
        guard let localizedData = getCountryData(for: code) else { return nil }
        
        let lang = language.lowercased()
        switch lang {
        case "ru":
            return localizedData.ru
        case "en":
            return localizedData.en
        case "es":
            return localizedData.es
        case "uk":
            return localizedData.uk
        case "ca":
            return localizedData.ca
        case let l where l.hasPrefix("zh"):
            return localizedData.zh
        default:
            return localizedData.en
        }
    }
    
    /// Единая точка: название страны по коду и языку. Для de, fr, it, pl, nl, pt — из встроенных словарей, иначе из БД.
    static func getLocalizedCountryName(for code: String, language: String, fallback: String) -> String {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        let lang = twoLetterKeyForExtraLocales(language)
        if ["de", "fr", "it", "pl", "nl", "pt"].contains(lang),
           let name = CountryNameLocalization.countryName(for: normalized, language: language) {
            return name
        }
        if let data = getLocalizedCountryData(for: normalized, language: language) {
            return data.name
        }
        if let name = CountryNameLocalization.countryName(for: normalized, language: language) {
            return name
        }
        return fallback
    }
    
    /// Единая точка: столица по коду и языку.
    static func getLocalizedCapitalName(for code: String, language: String, fallback: String) -> String {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        let lang = twoLetterKeyForExtraLocales(language)
        if ["de", "fr", "it", "pl", "nl", "pt"].contains(lang),
           let capital = CountryNameLocalization.capitalName(for: normalized, language: language) {
            return capital
        }
        if let data = getLocalizedCountryData(for: normalized, language: language) {
            return data.capital
        }
        if let capital = CountryNameLocalization.capitalName(for: normalized, language: language) {
            return capital
        }
        return fallback
    }

    /// Для словарей de/fr/it/pl/nl/pt: двухбуквенный ключ; `fil` не сводим к `fi` (финский).
    private static func twoLetterKeyForExtraLocales(_ language: String) -> String {
        let l = language.lowercased()
        if l.hasPrefix("pt") { return "pt" }
        if l == "fil" || l.hasPrefix("fil-") { return "en" }
        return String(l.prefix(2))
    }
}

// MARK: - Localized Country Data
struct LocalizedCountryData: Codable {
    let ru: CountryData
    let en: CountryData
    let es: CountryData
    let uk: CountryData
    let ca: CountryData
    let zh: CountryData
}

// MARK: - Country Data Model
struct CountryData: Codable {
    let code: String
    let name: String
    let flag: String
    let capital: String
    let officialLanguage: String
    let government: String
    let leader: String
    let dialingCode: String
    let population: String
    let currency: String
    let independence: String
    let area: String
    let description: String
    let flagDescription: String
    let anthemDescription: String
    let anthemMeaning: String
    let photos: [String]
    let anthemAudio: String
    let interestingFacts: [String] // Три интересных факта о стране
}

