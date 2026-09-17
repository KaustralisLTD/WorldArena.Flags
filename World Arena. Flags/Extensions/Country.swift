import Foundation

struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: LocalizedName
    let flagURL: URL
    let region: String
    let subregion: String?
    let latlng: [Double]?
    let capital: [String]?
    let population: Int
    let area: Double?
    let translations: [String: Translation]?
    
    struct LocalizedName: Codable, Hashable {
        let common: String
        let official: String
        let nativeName: [String: NativeName]?
        
        struct NativeName: Codable, Hashable {
            let official: String
            let common: String
        }
    }
    
    struct Translation: Codable, Hashable {
        let official: String
        let common: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "cca3"
        case name
        case flagURL = "flags"
        case region
        case subregion
        case latlng
        case capital
        case population
        case area
        case translations
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(LocalizedName.self, forKey: .name)
        
        let flags = try container.decode([String: String].self, forKey: .flagURL)
        guard let pngURL = flags["png"].flatMap({ URL(string: $0) }) else {
            throw DecodingError.dataCorruptedError(forKey: .flagURL, in: container, debugDescription: "Invalid flag URL")
        }
        flagURL = pngURL
        
        region = try container.decode(String.self, forKey: .region)
        subregion = try container.decodeIfPresent(String.self, forKey: .subregion)
        latlng = try container.decodeIfPresent([Double].self, forKey: .latlng)
        capital = try container.decodeIfPresent([String].self, forKey: .capital)
        population = try container.decode(Int.self, forKey: .population)
        area = try container.decodeIfPresent(Double.self, forKey: .area)
        translations = try container.decodeIfPresent([String: Translation].self, forKey: .translations)
    }
    
    // Реализация Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.id == rhs.id
    }
    
    // Обычный инициализатор
    init(id: String, name: LocalizedName, flagURL: URL, region: String, subregion: String?, latlng: [Double]? = nil, capital: [String]?, population: Int, area: Double?, translations: [String: Translation]?) {
        self.id = id
        self.name = name
        self.flagURL = flagURL
        self.region = region
        self.subregion = subregion
        self.latlng = latlng
        self.capital = capital
        self.population = population
        self.area = area
        self.translations = translations
    }
    
    // Computed property для получения emoji флага из кода страны
    var flagEmoji: String {
        // Преобразуем 3-буквенный код в 2-буквенный для emoji
        let code = countryCodeToTwoLetter(id)
        
        // Преобразуем 2-буквенный код в emoji флага
        let base: UInt32 = 127397
        var s = ""
        for v in code.unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
    
    // Computed property для получения 2-буквенного кода страны
    var countryCode: String {
        return countryCodeToTwoLetter(id)
    }
    
    // Преобразование 3-буквенного кода в 2-буквенный
    private func countryCodeToTwoLetter(_ threeLetterCode: String) -> String {
        ISO3166.alpha3ToAlpha2[threeLetterCode] ?? threeLetterCode.prefix(2).uppercased()
    }
    
    // Пример страны для предпросмотра
    static let sample = Country(
        id: "USA",
        name: LocalizedName(
            common: "United States",
            official: "United States of America",
            nativeName: ["eng": LocalizedName.NativeName(
                official: "United States of America",
                common: "United States"
            )]
        ),
        flagURL: URL(string: "https://flagcdn.com/w320/us.png")!,
        region: "Americas",
        subregion: "Northern America",
        latlng: [38.0, -97.0],
        capital: ["Washington, D.C."],
        population: 331900000,
        area: 9833517.0,
        translations: nil
    )
} 