import SwiftUI
import OSLog

final class AppThemeManager: ObservableObject {
    static let shared = AppThemeManager()
    private let logger = Logger(subsystem: "com.flags.world", category: "Theme")
    
    @Published private(set) var selectedTheme: AppTheme = .system
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            selectedTheme = theme
            logger.info("Theme initialized with saved value: \(theme.rawValue)")
        } else {
            logger.info("Theme initialized with default value: system")
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
        logger.info("Theme changed to: \(theme.rawValue)")
    }
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
} 