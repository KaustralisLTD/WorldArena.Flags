import SwiftUI

// MARK: - App Colors Extension
extension Color {
    // Основные цвета приложения, адаптируются к теме
    static let appBackground = Color("AppBackground")
    static let appBackgroundSecondary = Color("AppBackgroundSecondary")
    static let appPrimary = Color("AppPrimary")
    static let appSecondary = Color("AppSecondary")
    static let appAccent = Color("AppAccent")
    
    // Градиенты для разных тем
    static func appGradientColors(for colorScheme: ColorScheme?) -> [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.05, green: 0.1, blue: 0.25)
            ]
        case .light:
            return [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.9, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.9, blue: 1.0)
            ]
        case .none:
            // Системная тема - используем светлую по умолчанию
            return [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.9, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.9, blue: 1.0)
            ]
        case .some(_):
            return [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.9, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.9, blue: 1.0)
            ]
        }
    }
    
    /// Градиент для заголовка/логотипа. В тёмной теме — яркие светлые цвета, чтобы логотип не терялся на чёрном фоне.
    static func appTextGradient(for colorScheme: ColorScheme?) -> [Color] {
        switch colorScheme {
        case .dark:
            return [Color.white, Color(red: 0.85, green: 0.9, blue: 1.0)]
        case .light:
            return [Color.black, Color.blue]
        case .none:
            return [Color.black, Color.blue]
        case .some(_):
            return [Color.black, Color.blue]
        }
    }
    
    static func appCardBackground(for colorScheme: ColorScheme?) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8)
        case .light:
            return Color.white.opacity(0.9)
        case .none:
            return Color.white.opacity(0.9)
        case .some(_):
            return Color.white.opacity(0.9)
        }
    }
}