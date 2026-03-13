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
        let resolvedCode: String = LocalizationManager.resolveLanguageCode(saved: saved)
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
            ? LocalizationManager.resolveLanguageCode(saved: nil)
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
    
    // Поддерживаемые языки приложения
    private static let supportedLanguageCodes: [String] = ["en", "ru", "uk", "es", "ca", "zh", "de", "fr", "it", "pt-BR", "pl", "nl"]
    
    // Разрешение старта языка при выборе «Система»
    private static func resolveLanguageCode(saved: String?) -> String {
        // Если сохранён пользовательский выбор и он не "system"
        if let saved, saved != "system" { return saved }
        // Сначала — основной язык устройства (Locale.current), чтобы при испанской системе не подставлять украинский
        if let current = Locale.current.languageCode?.lowercased() {
            if current == "pt" {
                return "pt-BR"
            }
            if supportedLanguageCodes.contains(current) {
                return current
            }
        }
        // Иначе — первая из preferredLanguages, которую поддерживаем
        let preferred = Locale.preferredLanguages
            .compactMap { langId -> String? in
                if let code = Locale(identifier: langId).languageCode?.lowercased() {
                    if code == "pt" { return "pt-BR" }
                    return code
                }
                let two = langId.split(separator: "-").first.map(String.init)?.lowercased()
                if two == "pt" { return "pt-BR" }
                return two
            }
        if let match = preferred.first(where: { supportedLanguageCodes.contains($0) }) {
            return match
        }
        return "en"
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
        let identifier = locale.identifier.lowercased()
        if identifier.hasPrefix("pt") { return "pt-BR" }
        if let code = locale.languageCode?.lowercased() {
            return code
        }
        return "en"
    }
    
    /// Код языка для API (Accept-Language), совпадает с тем, что видит пользователь в приложении.
    var apiLanguageCode: String {
        let id = currentLocale.identifier
        if id.lowercased().hasPrefix("pt") { return "pt-BR" }
        return currentLocale.languageCode ?? "en"
    }

    /// Код языка для бандла (.lproj), совпадает с папками локализации.
    var currentBundleLanguageCode: String {
        let id = currentLocale.identifier.lowercased()
        if id.hasPrefix("pt") { return "pt-BR" }
        return currentLocale.languageCode?.lowercased() ?? "en"
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
        default: return "HeartEN"
        }
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
        default: return [Color(red: 0.9, green: 0.25, blue: 0.25), Color(red: 1, green: 1, blue: 1), Color(red: 0.2, green: 0.4, blue: 0.9)]
        }
    }

    func localizedString(_ key: String) -> String {
        return bundle?.localizedString(forKey: key, value: key, table: nil) 
            ?? Bundle.main.localizedString(forKey: key, value: key, table: nil)
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
        
        // 6. Возвращаем общее название как запасной вариант
        return country.name.common
    }
} 