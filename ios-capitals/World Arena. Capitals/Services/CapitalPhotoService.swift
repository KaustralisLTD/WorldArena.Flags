import Foundation

/// City pages, not country galleries: a country landmark may be far from its capital.
actor CapitalPhotoService {
    static let shared = CapitalPhotoService()
    struct Photo: Sendable, Decodable {
        let imageURL: URL
        let sourceURL: URL
        let imageName: String?
        let creator: String?
        let license: String?
    }
    private var cache: [String: Photo] = [:]
    private let bundled: [String: Photo] = {
        guard let url = Bundle.main.url(forResource: "capital-photos", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: Photo].self, from: data)) ?? [:]
    }()
    static func pageTitle(for country: Country) -> String? {
        let qualified: [String: String] = [
            "USA": "Washington,_D.C.", "MEX": "Mexico_City", "GTM": "Guatemala_City",
            "PAN": "Panama_City", "SLV": "San_Salvador", "CRI": "San_José,_Costa_Rica",
            "JAM": "Kingston,_Jamaica", "LCA": "Castries", "GRD": "St._George's,_Grenada",
            "VCT": "Kingstown", "TTO": "Port_of_Spain", "ATG": "St._John's,_Antigua_and_Barbuda",
            "DMA": "Roseau", "HTI": "Port-au-Prince", "PRI": "San_Juan,_Puerto_Rico",
            "DOM": "Santo_Domingo", "CUB": "Havana", "BRA": "Brasília",
            "BOL": "Sucre", "PER": "Lima", "CHL": "Santiago", "ARG": "Buenos_Aires",
            "GUY": "Georgetown,_Guyana", "SUR": "Paramaribo", "PRY": "Asunción",
            "URY": "Montevideo", "GBR": "London", "FRA": "Paris", "ITA": "Rome",
            "DEU": "Berlin", "ESP": "Madrid", "GEO": "Tbilisi", "ARM": "Yerevan",
            "UKR": "Kyiv", "CZE": "Prague", "VAT": "Vatican_City", "SMR": "City_of_San_Marino",
            "MCO": "Monaco", "IND": "New_Delhi", "LKA": "Colombo",
            "AIA": "The_Valley,_Anguilla", "BHS": "Nassau,_Bahamas", "COM": "Moroni,_Comoros", "LBY": "Tripoli,_Libya", "LUX": "Luxembourg_City", "REU": "Saint-Denis,_Réunion", "DJI": "Djibouti_City",
            "TWN": "Taipei", "KOR": "Seoul", "PRK": "Pyongyang", "CHN": "Beijing",
            "JPN": "Tokyo", "TLS": "Dili", "BRN": "Bandar_Seri_Begawan",
            "SGP": "Singapore", "MYS": "Kuala_Lumpur", "MDV": "Malé",
            "NPL": "Kathmandu", "BTN": "Thimphu", "MMR": "Naypyidaw",
            "ZAF": "Pretoria", "SWZ": "Mbabane", "TZA": "Dodoma",
            "BEN": "Porto-Novo", "COD": "Kinshasa", "COG": "Brazzaville",
            "SYC": "Victoria,_Seychelles", "MUS": "Port_Louis", "STP": "São_Tomé",
            "CPV": "Praia", "ESH": "Laayoune", "ISR": "Jerusalem", "PSE": "Ramallah",
            "KWT": "Kuwait_City", "ARE": "Abu_Dhabi", "YEM": "Sanaa",
            "AUS": "Canberra", "NZL": "Wellington", "FSM": "Palikir",
            "PLW": "Ngerulmud", "KIR": "South_Tarawa", "TUV": "Funafuti",
            "NRU": "Yaren_District", "WSM": "Apia", "ASM": "Pago_Pago",
            "COK": "Avarua", "NIU": "Alofi", "NFK": "Kingston,_Norfolk_Island",
            "SHN": "Jamestown,_Saint_Helena", "FLK": "Stanley,_Falkland_Islands",
            "GGY": "Saint_Peter_Port", "JEY": "Saint_Helier", "IMN": "Douglas,_Isle_of_Man",
            "VGB": "Road_Town", "VIR": "Charlotte_Amalie", "CYM": "George_Town,_Cayman_Islands",
            "SXM": "Philipsburg,_Sint_Maarten", "MAF": "Marigot,_Saint_Martin",
            "BLM": "Gustavia,_Saint_Barthélemy", "BMU": "Hamilton,_Bermuda",
            "PYF": "Papeete", "NCL": "Nouméa", "SPM": "Saint-Pierre,_Saint_Pierre_and_Miquelon"
        ]
        return qualified[country.id] ?? country.capital?.first?.replacingOccurrences(of: " ", with: "_")
    }

    func photo(for country: Country) async -> Photo? {
        if let local = bundled[country.id] { return local }
        if let cached = cache[country.id] { return cached }
        guard let title = Self.pageTitle(for: country), !title.isEmpty,
              let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else { return nil }
        struct Summary: Decodable {
            struct Thumbnail: Decodable { let source: URL }
            let type: String
            let thumbnail: Thumbnail?
            let originalimage: Thumbnail?
        }
        do {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
            request.setValue("WorldArenaCapitals/1.0 (https://capital.worldarena.games)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let summary = try JSONDecoder().decode(Summary.self, from: data)
            guard summary.type == "standard", let image = summary.thumbnail?.source,
                  ["upload.wikimedia.org", "thumb.wikimedia.org"].contains(image.host ?? ""),
                  let original = summary.originalimage?.source else { return nil }
            let components = image.pathComponents
            let filename = image.path.contains("/thumb/") && components.count > 2
                ? components[components.count - 2] : original.lastPathComponent
            guard !["flag_of", "coat_of", "locator", "location_map", ".svg", "seal_of"].contains(where: filename.lowercased().contains) else { return nil }
            var metadataURL = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
            metadataURL.queryItems = [URLQueryItem(name: "action", value: "query"), URLQueryItem(name: "format", value: "json"), URLQueryItem(name: "prop", value: "imageinfo"), URLQueryItem(name: "iiprop", value: "extmetadata|url"), URLQueryItem(name: "titles", value: "File:" + filename)]
            request.url = metadataURL.url
            let (credits, creditResponse) = try await URLSession.shared.data(for: request)
            guard (creditResponse as? HTTPURLResponse)?.statusCode == 200,
                  let root = try JSONSerialization.jsonObject(with: credits) as? [String: Any],
                  let query = root["query"] as? [String: Any], let pages = query["pages"] as? [String: [String: Any]],
                  let info = pages.values.compactMap({ ($0["imageinfo"] as? [[String: Any]])?.first }).first,
                  let metadata = info["extmetadata"] as? [String: [String: Any]],
                  let license = metadata["LicenseShortName"]?["value"] as? String,
                  let description = info["descriptionurl"] as? String, let sourceURL = URL(string: description) else { return nil }
            let lowerLicense = license.lowercased()
            guard ["cc by", "cc-by", "cc0", "public domain", "gfdl", "pd"].contains(where: lowerLicense.hasPrefix),
                  !lowerLicense.contains("-nc"), !lowerLicense.contains("-nd") else { return nil }
            let creator = (metadata["Artist"]?["value"] as? String)?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let photo = Photo(imageURL: image, sourceURL: sourceURL, imageName: nil, creator: creator, license: license)
            cache[country.id] = photo
            return photo
        } catch { return nil }
    }
}
