import Foundation

extension GameState.Language {
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("System", comment: "")
        case .english: return "English"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .ukrainian: return "Українська"
        case .catalan: return "Català"
        case .chinese: return "中文"
        }
    }
    
    var locale: Locale {
        switch self {
        case .system: return .current
        case .english: return Locale(identifier: "en")
        case .russian: return Locale(identifier: "ru")
        case .spanish: return Locale(identifier: "es")
        case .ukrainian: return Locale(identifier: "uk")
        case .catalan: return Locale(identifier: "ca")
        case .chinese: return Locale(identifier: "zh")
        }
    }
} 