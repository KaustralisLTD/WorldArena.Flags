import Foundation

extension GameState.Region {
    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("All Regions", comment: "")
        case .europe:
            return NSLocalizedString("Europe", comment: "")
        case .asia:
            return NSLocalizedString("Asia", comment: "")
        case .africa:
            return NSLocalizedString("Africa", comment: "")
        case .northAmerica:
            return NSLocalizedString("North America", comment: "")
        case .southAmerica:
            return NSLocalizedString("South America", comment: "")
        case .oceania:
            return NSLocalizedString("Oceania", comment: "")
        case .myMistakes:
            return NSLocalizedString("My Mistakes", comment: "")
        }
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