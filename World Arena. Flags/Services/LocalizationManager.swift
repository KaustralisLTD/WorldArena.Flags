import Foundation

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