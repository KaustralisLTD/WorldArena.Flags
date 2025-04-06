import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    // Простые строковые идентификаторы для локализации
    var localizationKey: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

// Отдельное расширение для асинхронных операций
extension AppTheme {
    @MainActor
    func getLocalizedName() async -> String {
        await LocalizationManager.shared.localizedString(localizationKey)
    }
} 