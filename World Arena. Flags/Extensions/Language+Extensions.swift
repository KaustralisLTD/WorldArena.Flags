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
        case .hindi: return "हिन्दी"
        case .czech: return "Čeština"
        case .swedish: return "Svenska"
        case .japanese: return "日本語"
        case .arabic: return "العربية"
        case .bengali: return "বাংলা"
        case .hungarian: return "Magyar"
        case .vietnamese: return "Tiếng Việt"
        case .greek: return "Ελληνικά"
        case .indonesian: return "Bahasa Indonesia"
        case .korean: return "한국어"
        case .romanian: return "Română"
        case .thai: return "ไทย"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .chineseTraditional: return "繁體中文"
        case .turkish: return "Türkçe"
        case .filipino: return "Filipino"
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
        case .chinese: return Locale(identifier: "zh-Hans")
        case .german: return Locale(identifier: "de")
        case .french: return Locale(identifier: "fr")
        case .italian: return Locale(identifier: "it")
        case .portugueseBrazil: return Locale(identifier: "pt-BR")
        case .polish: return Locale(identifier: "pl")
        case .dutch: return Locale(identifier: "nl")
        case .hindi: return Locale(identifier: "hi")
        case .czech: return Locale(identifier: "cs")
        case .swedish: return Locale(identifier: "sv")
        case .japanese: return Locale(identifier: "ja")
        case .arabic: return Locale(identifier: "ar")
        case .bengali: return Locale(identifier: "bn")
        case .hungarian: return Locale(identifier: "hu")
        case .vietnamese: return Locale(identifier: "vi")
        case .greek: return Locale(identifier: "el")
        case .indonesian: return Locale(identifier: "id")
        case .korean: return Locale(identifier: "ko")
        case .romanian: return Locale(identifier: "ro")
        case .thai: return Locale(identifier: "th")
        case .tamil: return Locale(identifier: "ta")
        case .telugu: return Locale(identifier: "te")
        case .chineseTraditional: return Locale(identifier: "zh-Hant")
        case .turkish: return Locale(identifier: "tr")
        case .filipino: return Locale(identifier: "fil")
        }
    }
} 