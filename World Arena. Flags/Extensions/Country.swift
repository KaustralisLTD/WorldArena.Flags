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
    
    // Обычный инициализатор
    init(id: String, name: LocalizedName, flagURL: URL, region: String, subregion: String?, capital: [String]?, population: Int, area: Double?, translations: [String: Translation]?) {
        self.id = id
        self.name = name
        self.flagURL = flagURL
        self.region = region
        self.subregion = subregion
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
        let mapping: [String: String] = [
            "AFG": "AF", "ALB": "AL", "DZA": "DZ", "ASM": "AS", "AND": "AD",
            "AGO": "AO", "AIA": "AI", "ATA": "AQ", "ATG": "AG", "ARG": "AR",
            "ARM": "AM", "ABW": "AW", "AUS": "AU", "AUT": "AT", "AZE": "AZ",
            "BHS": "BS", "BHR": "BH", "BGD": "BD", "BRB": "BB", "BLR": "BY",
            "BEL": "BE", "BLZ": "BZ", "BEN": "BJ", "BMU": "BM", "BTN": "BT",
            "BOL": "BO", "BES": "BQ", "BIH": "BA", "BWA": "BW", "BVT": "BV",
            "BRA": "BR", "IOT": "IO", "BRN": "BN", "BGR": "BG", "BFA": "BF",
            "BDI": "BI", "CPV": "CV", "KHM": "KH", "CMR": "CM", "CAN": "CA",
            "CYM": "KY", "CAF": "CF", "TCD": "TD", "CHL": "CL", "CHN": "CN",
            "CXR": "CX", "CCK": "CC", "COL": "CO", "COM": "KM", "COG": "CG",
            "COD": "CD", "COK": "CK", "CRI": "CR", "CIV": "CI", "HRV": "HR",
            "CUB": "CU", "CUW": "CW", "CYP": "CY", "CZE": "CZ", "DNK": "DK",
            "DJI": "DJ", "DMA": "DM", "DOM": "DO", "ECU": "EC", "EGY": "EG",
            "SLV": "SV", "GNQ": "GQ", "ERI": "ER", "EST": "EE", "SWZ": "SZ",
            "ETH": "ET", "FLK": "FK", "FRO": "FO", "FJI": "FJ", "FIN": "FI",
            "FRA": "FR", "GUF": "GF", "PYF": "PF", "ATF": "TF", "GAB": "GA",
            "GMB": "GM", "GEO": "GE", "DEU": "DE", "GHA": "GH", "GIB": "GI",
            "GRC": "GR", "GRL": "GL", "GRD": "GD", "GLP": "GP", "GUM": "GU",
            "GTM": "GT", "GGY": "GG", "GIN": "GN", "GNB": "GW", "GUY": "GY",
            "HTI": "HT", "HMD": "HM", "VAT": "VA", "HND": "HN", "HKG": "HK",
            "HUN": "HU", "ISL": "IS", "IND": "IN", "IDN": "ID", "IRN": "IR",
            "IRQ": "IQ", "IRL": "IE", "IMN": "IM", "ISR": "IL", "ITA": "IT",
            "JAM": "JM", "JPN": "JP", "JEY": "JE", "JOR": "JO", "KAZ": "KZ",
            "KEN": "KE", "KIR": "KI", "PRK": "KP", "KOR": "KR", "KWT": "KW",
            "KGZ": "KG", "LAO": "LA", "LVA": "LV", "LBN": "LB", "LSO": "LS",
            "LBR": "LR", "LBY": "LY", "LIE": "LI", "LTU": "LT", "LUX": "LU",
            "MAC": "MO", "MDG": "MG", "MWI": "MW", "MYS": "MY", "MDV": "MV",
            "MLI": "ML", "MLT": "MT", "MHL": "MH", "MTQ": "MQ", "MRT": "MR",
            "MUS": "MU", "MYT": "YT", "MEX": "MX", "FSM": "FM", "MDA": "MD",
            "MCO": "MC", "MNG": "MN", "MNE": "ME", "MSR": "MS", "MAR": "MA",
            "MOZ": "MZ", "MMR": "MM", "NAM": "NA", "NRU": "NR", "NPL": "NP",
            "NLD": "NL", "NCL": "NC", "NZL": "NZ", "NIC": "NI", "NER": "NE",
            "NGA": "NG", "NIU": "NU", "NFK": "NF", "MKD": "MK", "MNP": "MP",
            "NOR": "NO", "OMN": "OM", "PAK": "PK", "PLW": "PW", "PSE": "PS",
            "PAN": "PA", "PNG": "PG", "PRY": "PY", "PER": "PE", "PHL": "PH",
            "PCN": "PN", "POL": "PL", "PRT": "PT", "PRI": "PR", "QAT": "QA",
            "REU": "RE", "ROU": "RO", "RUS": "RU", "RWA": "RW", "BLM": "BL",
            "SHN": "SH", "KNA": "KN", "LCA": "LC", "MAF": "MF", "SPM": "PM",
            "VCT": "VC", "WSM": "WS", "SMR": "SM", "STP": "ST", "SAU": "SA",
            "SEN": "SN", "SRB": "RS", "SYC": "SC", "SLE": "SL", "SGP": "SG",
            "SXM": "SX", "SVK": "SK", "SVN": "SI", "SLB": "SB", "SOM": "SO",
            "ZAF": "ZA", "SGS": "GS", "SSD": "SS", "ESP": "ES", "LKA": "LK",
            "SDN": "SD", "SUR": "SR", "SJM": "SJ", "SWE": "SE", "CHE": "CH",
            "SYR": "SY", "TWN": "TW", "TJK": "TJ", "TZA": "TZ", "THA": "TH",
            "TLS": "TL", "TGO": "TG", "TKL": "TK", "TON": "TO", "TTO": "TT",
            "TUN": "TN", "TUR": "TR", "TKM": "TM", "TCA": "TC", "TUV": "TV",
            "UGA": "UG", "UKR": "UA", "ARE": "AE", "GBR": "GB", "USA": "US",
            "UMI": "UM", "URY": "UY", "UZB": "UZ", "VUT": "VU", "VEN": "VE",
            "VNM": "VN", "VGB": "VG", "VIR": "VI", "WLF": "WF", "ESH": "EH",
            "YEM": "YE", "ZMB": "ZM", "ZWE": "ZW", "XKX": "XK"
        ]
        
        return mapping[threeLetterCode] ?? threeLetterCode.prefix(2).uppercased()
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
        capital: ["Washington, D.C."],
        population: 331900000,
        area: 9833517.0,
        translations: nil
    )
} 