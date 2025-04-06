import Foundation

struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: LocalizedName
    let flagURL: URL
    let region: String
    let subregion: String?
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
} 