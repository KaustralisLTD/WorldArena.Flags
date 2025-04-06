import Foundation

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLocale: Locale
    private var bundle: Bundle?
    
    private init() {
        currentLocale = .current
        updateBundle(for: currentLocale)
    }
    
    func setLanguage(_ language: GameState.Language) {
        print("\n=== Changing Language ===")
        print("Old language: \(currentLocale.languageCode ?? "en")")
        print("New language: \(language.rawValue)")
        
        // Сохраняем выбранный язык
        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        
        // Обновляем локаль в зависимости от выбранного языка
        let localeIdentifier = language == .system ? Locale.current.identifier : language.rawValue
        currentLocale = Locale(identifier: localeIdentifier)
        
        // Обновляем bundle
        updateBundle(for: currentLocale)
        
        // Устанавливаем язык системы
        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
        
        // Принудительно обновляем UI
        UserDefaults.standard.synchronize()
        
        // Добавляем отправку уведомления для обновления UI
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        
        print("Language updated successfully")
        print("=====================\n")
    }
    
    private func updateBundle(for locale: Locale) {
        guard let languageCode = locale.languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = Bundle.main
            return
        }
        self.bundle = bundle
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