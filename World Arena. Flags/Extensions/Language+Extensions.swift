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
        case .german: return "Deutsch"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .portugueseBrazil: return "Português (Brasil)"
        case .polish: return "Polski"
        case .dutch: return "Nederlands"
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
        case .german: return Locale(identifier: "de")
        case .french: return Locale(identifier: "fr")
        case .italian: return Locale(identifier: "it")
        case .portugueseBrazil: return Locale(identifier: "pt-BR")
        case .polish: return Locale(identifier: "pl")
        case .dutch: return Locale(identifier: "nl")
        }
    }
} 