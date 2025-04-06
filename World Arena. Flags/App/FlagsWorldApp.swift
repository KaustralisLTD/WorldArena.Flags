import SwiftUI

@main
struct FlagsWorldApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                BackgroundView()
                
                NavigationView {
                    ContentView()
                        .environmentObject(gameState)
                }
            }
            .onAppear {
                // Настраиваем метрики запуска
                #if DEBUG
                if CommandLine.arguments.contains("UITesting") {
                    // Для UI тестов
                    UIView.setAnimationsEnabled(false)
                }
                #endif
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
                DispatchQueue.main.async {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = scene.windows.first else { return }
                    let _ = window.layer.presentation()
                }
                #endif
            }
    }
} 