import Foundation

/// Разрешение кода языка без привязки к MainActor — для метаданных сессии и фоновых хелперов.
enum LocalizationLanguageResolver {
    private static let supportedLanguageCodes: [String] = [
        "en", "ru", "uk", "es", "ca", "zh", "zh-Hant", "de", "fr", "it", "pt-BR", "pl", "nl",
        "hi", "cs", "sv", "ja", "ar", "bn", "hu", "vi", "el", "id", "ko", "ro", "th", "ta", "te", "tr", "fil",
    ]

    /// Код папки .lproj / API: pt-BR, zh-Hant, zh (упрощённый), fil и т.д.
    static func bundleLanguageCodeFromIdentifier(_ identifier: String) -> String {
        let norm = identifier.lowercased().replacingOccurrences(of: "_", with: "-")
        if norm.hasPrefix("pt") { return "pt-BR" }
        if norm.contains("hant") { return "zh-Hant" }
        if norm == "zh-tw" || norm.hasPrefix("zh-tw-")
            || norm == "zh-hk" || norm.hasPrefix("zh-hk-")
            || norm == "zh-mo" || norm.hasPrefix("zh-mo-") {
            return "zh-Hant"
        }
        if norm.hasPrefix("zh") { return "zh" }
        if norm == "fil" || norm.hasPrefix("fil-") { return "fil" }
        if norm == "tl" || norm.hasPrefix("tl-") { return "fil" }
        if let code = Locale(identifier: identifier).languageCode?.lowercased() {
            if code == "pt" { return "pt-BR" }
            return code
        }
        return norm.split(separator: "-").first.map(String.init) ?? "en"
    }

    /// Стартовый язык: сохранённый в настройках или системный.
    static func resolveLanguageCode(saved: String?) -> String {
        if let saved, saved != "system" {
            if supportedLanguageCodes.contains(saved) { return saved }
            let normalized = bundleLanguageCodeFromIdentifier(saved)
            if supportedLanguageCodes.contains(normalized) { return normalized }
            return "en"
        }
        let deviceCode = bundleLanguageCodeFromIdentifier(Locale.current.identifier)
        if supportedLanguageCodes.contains(deviceCode) { return deviceCode }
        for pref in Locale.preferredLanguages {
            let code = bundleLanguageCodeFromIdentifier(pref)
            if supportedLanguageCodes.contains(code) { return code }
        }
        return "en"
    }

    /// Язык интерфейса (настройка или система) — для метаданных сессии, без MainActor.
    static func resolvedAppLanguageCodeForMetadata() -> String {
        resolveLanguageCode(saved: UserDefaults.standard.string(forKey: "selectedLanguage"))
    }
}
