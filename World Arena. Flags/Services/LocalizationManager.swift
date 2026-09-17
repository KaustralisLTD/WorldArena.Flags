import Foundation
import SwiftUI

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLocale: Locale
    private var bundle: Bundle?
    
    private init() {
        // Логика старта:
        // 1) если пользователь выбрал язык в приложении — используем его
        // 2) иначе — подстраиваемся под систему (Locale.preferredLanguages)
        // 3) никаких манипуляций с AppleLanguages (во избежание неожиданных переопределений)
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage")
        let resolvedCode: String = LocalizationLanguageResolver.resolveLanguageCode(saved: saved)
        currentLocale = Locale(identifier: resolvedCode)
        updateBundle(for: currentLocale)
        // Чистим возможные старые переопределения AppleLanguages
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    }
    
    func setLanguage(_ language: GameState.Language) {
        print("\n=== Changing Language ===")
        print("Old language: \(currentLocale.languageCode ?? "en")")
        print("New language: \(language.rawValue)")
        
        // Сохраняем выбранный язык
        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        
        // Обновляем локаль в зависимости от выбранного языка
        let localeIdentifier = language == .system
            ? LocalizationLanguageResolver.resolveLanguageCode(saved: nil)
            : language.rawValue
        currentLocale = Locale(identifier: localeIdentifier)
        
        // Обновляем bundle
        updateBundle(for: currentLocale)
        
        // Принудительно обновляем UI
        UserDefaults.standard.synchronize()
        
        // Добавляем отправку уведомления для обновления UI
        NotificationCenter.default.post(name: .languageChanged, object: nil)
        
        print("Language updated successfully")
        print("=====================\n")
    }
    
    /// Код папки .lproj / API: pt-BR, zh-Hant, zh (упрощённый), fil и т.д.
    static func bundleLanguageCodeFromIdentifier(_ identifier: String) -> String {
        LocalizationLanguageResolver.bundleLanguageCodeFromIdentifier(identifier)
    }

    /// Язык интерфейса приложения (настройка или система) — для метаданных сессии и т.п., без MainActor.
    static func resolvedAppLanguageCodeForMetadata() -> String {
        LocalizationLanguageResolver.resolvedAppLanguageCodeForMetadata()
    }

    private func updateBundle(for locale: Locale) {
        let bundleLanguageCode = preferredBundleLanguageCode(for: locale)
        guard let path = Bundle.main.path(forResource: bundleLanguageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Для языков без своего lproj пока используем английский fallback.
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                self.bundle = enBundle
            } else {
                self.bundle = Bundle.main
            }
            return
        }
        self.bundle = bundle
    }
    
    private func preferredBundleLanguageCode(for locale: Locale) -> String {
        Self.bundleLanguageCodeFromIdentifier(locale.identifier)
    }

    /// Код языка для API (Accept-Language), совпадает с тем, что видит пользователь в приложении.
    var apiLanguageCode: String {
        Self.bundleLanguageCodeFromIdentifier(currentLocale.identifier)
    }

    /// Код языка для бандла (.lproj), совпадает с папками локализации.
    var currentBundleLanguageCode: String {
        Self.bundleLanguageCodeFromIdentifier(currentLocale.identifier)
    }

    /// Идентификатор локали для MapKit (язык подписей на карте). zh → zh-Hans и т.д.
    var mapKitLocaleIdentifier: String {
        let code = currentBundleLanguageCode
        if code == "zh" { return "zh-Hans" }
        if code == "zh-Hant" { return "zh-Hant" }
        return code
    }

    /// Имя изображения «жизни» (сердце) в Assets по выбранному языку приложения.
    var lifeHeartAssetName: String {
        switch currentBundleLanguageCode {
        case "ru": return "HeartRU"
        case "uk": return "HeartUK"
        case "de": return "HeartDE"
        case "fr": return "HeartFR"
        case "es": return "HeartES"
        case "it": return "HeartIT"
        case "pt-BR": return "HeartPTBR"
        case "pl": return "HeartPL"
        case "nl": return "HeartNL"
        case "ca": return "HeartCA"
        case "zh": return "HeartZH"
        case "zh-Hant": return "HeartZHHant"
        case "ja": return "HeartJA"
        case "ar": return "HeartAR"
        case "bn": return "HeartBN"
        case "cs": return "HeartCS"
        case "el": return "HeartEL"
        case "fil": return "HeartFIL"
        case "hi": return "HeartHI"
        case "hu": return "HeartHU"
        case "id": return "HeartID"
        case "ko": return "HeartKO"
        case "ro": return "HeartRO"
        case "sv": return "HeartSV"
        case "ta": return "HeartTA"
        case "te": return "HeartTE"
        case "th": return "HeartTH"
        case "tr": return "HeartTR"
        case "vi": return "HeartVI"
        default: return "HeartEN"
        }
    }

    /// Имя изображения «жизни» с учётом выбранной страны профиля.
    /// Специальное правило: если пользователь выбрал страну Украины (UA),
    /// то всегда показываем украинское сердце, даже если язык приложения — русский.
    func lifeHeartAssetName(forCountryCode countryCode: String?) -> String {
        let code = countryCode?.uppercased()
        if code == "UA" {
            return "HeartUK"
        }
        // Критично: русское сердце показываем ТОЛЬКО если пользователь из РФ.
        if currentBundleLanguageCode == "ru", code != "RU" {
            return "HeartEN"
        }
        return lifeHeartAssetName
    }

    /// 2–3 основных цвета флага языка для частиц анимации потери жизни (glass/premium style).
    var lifeLossParticleColors: [Color] {
        switch currentBundleLanguageCode {
        case "ru": return [Color(red: 1, green: 1, blue: 1), Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.2, green: 0.35, blue: 0.85)]
        case "uk": return [Color(red: 0.2, green: 0.45, blue: 0.95), Color(red: 1, green: 0.85, blue: 0.2)]
        case "de": return [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.85, green: 0.2, blue: 0.15), Color(red: 0.95, green: 0.78, blue: 0.2)]
        case "fr": return [Color(red: 0.15, green: 0.25, blue: 0.65), Color(red: 1, green: 1, blue: 1), Color(red: 0.9, green: 0.2, blue: 0.25)]
        case "es": return [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 1, green: 0.85, blue: 0.2)]
        case "it": return [Color(red: 0.1, green: 0.55, blue: 0.3), Color(red: 1, green: 1, blue: 1), Color(red: 0.85, green: 0.2, blue: 0.2)]
        case "pt-BR": return [Color(red: 0.1, green: 0.55, blue: 0.3), Color(red: 1, green: 0.85, blue: 0.2)]
        case "pl": return [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 1, green: 1, blue: 1)]
        case "nl": return [Color(red: 0.75, green: 0.2, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 1, green: 0.82, blue: 0.2)]
        case "ca": return [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 1, green: 0.9, blue: 0.2)]
        case "zh": return [Color(red: 0.95, green: 0.25, blue: 0.2), Color(red: 1, green: 0.85, blue: 0.2), Color(red: 0.95, green: 0.78, blue: 0.2)]
        case "zh-Hant": return [Color(red: 0.2, green: 0.35, blue: 0.75), Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 1, green: 1, blue: 1)]
        case "ja": return [Color(red: 0.95, green: 1, blue: 1), Color(red: 0.85, green: 0.15, blue: 0.2)]
        case "ar": return [Color(red: 0.1, green: 0.45, blue: 0.28), Color(red: 1, green: 1, blue: 1)]
        case "bn": return [Color(red: 0, green: 0.42, blue: 0.31), Color(red: 0.96, green: 0.2, blue: 0.26)]
        case "cs": return [Color(red: 0.9, green: 1, blue: 1), Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 0.15, green: 0.25, blue: 0.55)]
        case "el": return [Color(red: 0.1, green: 0.35, blue: 0.65), Color(red: 1, green: 1, blue: 1)]
        case "fil": return [Color(red: 0.15, green: 0.35, blue: 0.75), Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 1, green: 1, blue: 1), Color(red: 0.95, green: 0.8, blue: 0.2)]
        case "hi": return [Color(red: 1, green: 0.6, blue: 0.2), Color(red: 1, green: 1, blue: 1), Color(red: 0.1, green: 0.45, blue: 0.22)]
        case "hu": return [Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 1, green: 1, blue: 1), Color(red: 0.2, green: 0.55, blue: 0.28)]
        case "id": return [Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 1, green: 1, blue: 1)]
        case "ko": return [Color(red: 1, green: 1, blue: 1), Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.25, blue: 0.55)]
        case "ro": return [Color(red: 0.15, green: 0.35, blue: 0.65), Color(red: 1, green: 0.85, blue: 0.2), Color(red: 0.85, green: 0.15, blue: 0.2)]
        case "sv": return [Color(red: 0.1, green: 0.35, blue: 0.65), Color(red: 1, green: 0.85, blue: 0.2)]
        case "ta", "te": return [Color(red: 1, green: 0.55, blue: 0.15), Color(red: 1, green: 1, blue: 1), Color(red: 0.05, green: 0.45, blue: 0.22)]
        case "th": return [Color(red: 0.85, green: 0.15, blue: 0.2), Color(red: 1, green: 1, blue: 1), Color(red: 0.15, green: 0.25, blue: 0.65)]
        case "tr": return [Color(red: 0.85, green: 0.12, blue: 0.18), Color(red: 1, green: 1, blue: 1)]
        case "vi": return [Color(red: 0.85, green: 0.12, blue: 0.15), Color(red: 1, green: 0.9, blue: 0.2)]
        default: return [Color(red: 0.9, green: 0.25, blue: 0.25), Color(red: 1, green: 1, blue: 1), Color(red: 0.2, green: 0.4, blue: 0.9)]
        }
    }

    func localizedString(_ key: String) -> String {
        return bundle?.localizedString(forKey: key, value: key, table: nil) 
            ?? Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    /// Название страны для UI по ISO 3166-1 alpha-2 (детальные результаты игры).
    func localizedCountryDisplayName(iso2Code: String?, englishFallback: String) -> String {
        guard let raw = iso2Code?.trimmingCharacters(in: .whitespacesAndNewlines), raw.count >= 2 else {
            return englishFallback
        }
        let upper = raw.uppercased()
        return CountryDatabase.getLocalizedCountryName(for: upper, language: currentBundleLanguageCode, fallback: englishFallback)
    }
    
    func localizedCountryName(_ country: Country) -> String {
        let languageCode = currentLocale.languageCode ?? "en"
        
        // Специальная обработка для Kosovo
        if country.name.common.contains("Kosovo") {
            return localizedString("Kosovo")
        }
        
        // 1. Пробуем получить перевод из API для полного локале (например, "uk-UA")
        if let translations = country.name.nativeName?[currentLocale.identifier]?.common {
            return translations
        }
        
        // 2. Пробуем получить перевод для языкового кода (например, "uk")
        if let translations = country.name.nativeName?[languageCode]?.common {
            return translations
        }
        
        // 3. Пробуем получить перевод из translations (если есть)
        if let translations = country.translations?[languageCode]?.common {
            return translations
        }
        
        // 4. Используем Locale.current для получения локализованного названия
        let locale = Locale(identifier: languageCode)
        if let localizedName = locale.localizedString(forRegionCode: country.id) {
            return localizedName
        }
        
        // 5. Пробуем получить перевод из локализационных файлов
        let localizedString = self.localizedString(country.name.common)
        if localizedString != country.name.common {
            return localizedString
        }
        
        // 6. Единый источник: БД стран (ru, en, es, uk, ca, zh + de, fr, it, pl, nl, pt из доп. словарей)
        return CountryDatabase.getLocalizedCountryName(for: country.countryCode, language: currentBundleLanguageCode, fallback: country.name.common)
    }
} 