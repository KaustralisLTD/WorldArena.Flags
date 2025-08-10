import SwiftUI

@main
struct FlagsWorldApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(gameState: gameState)
                .environmentObject(gameState)
                .environmentObject(notificationService)
                .onAppear {
                    // Настраиваем метрики запуска
                    #if DEBUG
                    if CommandLine.arguments.contains("UITesting") {
                        // Для UI тестов - отключаем анимации
                    }
                    #endif
                    
                    // Обновляем время последнего открытия приложения
                    notificationService.updateLastAppOpenDate()
                    
                    // Проверяем статус уведомлений
                    notificationService.checkNotificationStatus()
                }
                .measureMetrics()
        }
    }
}

// Расширение для измерения метрик
extension View {
    func measureMetrics() -> some View {
        self.modifier(MetricsModifier())
    }
}

struct MetricsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if DEBUG
                // Отмечаем момент готовности UI
                print("UI готов к отображению")
                #endif
            }
    }
} 