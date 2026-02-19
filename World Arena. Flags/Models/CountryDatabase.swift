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
        return allCountries.first { $0.ru.code == code }
    }
    
    static func getLocalizedCountryData(for code: String, language: String) -> CountryData? {
        guard let localizedData = getCountryData(for: code) else { return nil }
        
        switch language {
        case "en":
            return localizedData.en
        case "es":
            return localizedData.es
        case "uk":
            return localizedData.uk
        case "ca":
            return localizedData.ca
        case "zh":
            return localizedData.zh
        default: // "ru"
            return localizedData.ru
        }
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

