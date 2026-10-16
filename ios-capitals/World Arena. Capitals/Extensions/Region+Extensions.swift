import Foundation

@MainActor
extension GameState.Region {
    var displayName: String {
        let key: String
        switch self {
        case .all: key = "All Regions"
        case .europe: key = "Europe"
        case .asia: key = "Asia"
        case .africa: key = "Africa"
        case .northAmerica: key = "North America"
        case .southAmerica: key = "South America"
        case .oceania: key = "Oceania"
        case .myMistakes: key = "My Mistakes"
        }
        return LocalizationManager.shared.localizedString(key)
    }

    var systemImageName: String {
        switch self {
        case .all: return "globe"
        case .europe: return "globe.europe.africa"
        case .asia: return "globe.asia.australia"
        case .northAmerica: return "globe.americas"
        case .southAmerica: return "globe.americas"
        case .africa: return "globe.europe.africa"
        case .oceania: return "globe.asia.australia"
        case .myMistakes: return "exclamationmark.triangle"
        }
    }
    
    var imageName: String {
        switch self {
        case .all:
            return "globe"
        case .europe:
            return "europe"
        case .asia:
            return "asia"
        case .africa:
            return "africa"
        case .northAmerica:
            return "north.america"
        case .southAmerica:
            return "south.america"
        case .oceania:
            return "oceania"
        case .myMistakes:
            return "exclamationmark.triangle"
        }
    }
} 