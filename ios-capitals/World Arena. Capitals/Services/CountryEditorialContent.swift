import Foundation

struct CountryEditorialStory: Decodable {
    let text: String
    let url: String
}

/// Short Wikipedia introductions with a visible source and CC BY-SA attribution.
enum CountryEditorialContent {
    private static let stories: [String: [String: CountryEditorialStory]] = {
        guard let url = Bundle.main.url(forResource: "learning-country-stories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([String: [String: CountryEditorialStory]].self, from: data) else { return [:] }
        return result
    }()

    static func story(code: String, language: String) -> CountryEditorialStory? {
        stories[code.uppercased()]?[language] ?? stories[code.uppercased()]?["en"]
    }
}

struct AnthemRecordingCredit: Decodable {
    let anthem: String?
    let source: String
    let author: String?
    let license: String?
    let sharedNationalAnthemOf: String?
}

enum AnthemRecordingCredits {
    static let all: [String: AnthemRecordingCredit] = {
        guard let url = Bundle.main.url(forResource: "anthem-attribution", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([String: AnthemRecordingCredit].self, from: data) else { return [:] }
        return result
    }()
}

struct CountryReadingFacts: Decodable {
    let items: [String]
    let url: String
    let extraSource: String?
}
struct CountryAnthemStory: Decodable {
    let excerpt: String?
    let attribution: String?
    let title: String
    let text: String
    let url: String
}
struct CountryReadingDetails: Decodable {
    let facts: [String: CountryReadingFacts]
    let anthems: [String: CountryAnthemStory]
}
enum CountryReadingLibrary {
    static let all: [String: CountryReadingDetails] = {
        guard let url = Bundle.main.url(forResource: "learning-details", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([String: CountryReadingDetails].self, from: data) else { return [:] }
        return result
    }()
    static func facts(code: String, language: String) -> CountryReadingFacts? {
        let content = all[code.uppercased()]?.facts
        if let localized = content?[language], !localized.items.isEmpty { return localized }
        return content?["en"]
    }
    static func anthem(code: String, language: String) -> CountryAnthemStory? {
        let content = all[code.uppercased()]?.anthems
        return content?[language] ?? content?["en"]
    }
}
