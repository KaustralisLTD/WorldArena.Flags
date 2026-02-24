import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        guard let window = window else { return .all }
        if window.traitCollection.userInterfaceIdiom == .phone {
            return .portrait
        }
        return .all
    }
}
#endif

@main
struct FlagsWorldApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameState = GameState()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var themeManager = AppThemeManager.shared
    @State private var showPremiumFromNotif = false
    @State private var previousScenePhase: ScenePhase?
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(gameState)
                .environmentObject(notificationService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .modifier(PremiumPresentationModifier(showPremium: $showPremiumFromNotif, gameState: gameState))
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
                    
                    // Инициализируем StoreManager
                    gameState.initializeStoreManager()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showPremiumFromHome"))) { _ in
                    showPremiumFromNotif = true
                }
                .measureMetrics()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // При уходе в фон принудительно сохраняем профиль (статистика, streak, XP, F-bucks) и статистику игр
                Task { @MainActor in
                    UserProfile.shared.saveToStorage()
                    StatisticsService.shared.saveStatistics(gameState.statistics)
                }
            }
            previousScenePhase = newPhase
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

// Модификатор для presentationDetents с проверкой версии iOS
struct PresentationDetentsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

// В настройках: Premium или ManageSubscription; на iPad — полноэкранно
struct SettingsPremiumModifier: ViewModifier {
    @Binding var showingPremium: Bool
    @ObservedObject var gameState: GameState
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    func body(content: Content) -> some View {
        Group {
            if isIPad {
                content
                    .fullScreenCover(isPresented: $showingPremium) {
                        if gameState.isPremium {
                            ManageSubscriptionView()
                                .environmentObject(gameState)
                                .environmentObject(UserProfile.shared)
                        } else {
                            PremiumView(gameState: gameState)
                        }
                    }
            } else {
                content
                    .sheet(isPresented: $showingPremium) {
                        if gameState.isPremium {
                            ManageSubscriptionView()
                                .environmentObject(gameState)
                                .environmentObject(UserProfile.shared)
                        } else {
                            PremiumView(gameState: gameState)
                                #if os(iOS)
                                .modifier(PresentationDetentsModifier())
                                #endif
                        }
                    }
            }
        }
    }
}

// На iPad показываем Premium полноэкранно, на iPhone — sheet. Для подписчиков — управление подпиской.
struct PremiumPresentationModifier: ViewModifier {
    @Binding var showPremium: Bool
    @ObservedObject var gameState: GameState
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    func body(content: Content) -> some View {
        Group {
            if isIPad {
                content
                    .fullScreenCover(isPresented: $showPremium) {
                        if gameState.isPremium {
                            ManageSubscriptionView()
                                .environmentObject(gameState)
                                .environmentObject(UserProfile.shared)
                        } else {
                            PremiumView(gameState: gameState)
                        }
                    }
            } else {
                content
                    .sheet(isPresented: $showPremium) {
                        Group {
                            if gameState.isPremium {
                                ManageSubscriptionView()
                                    .environmentObject(gameState)
                                    .environmentObject(UserProfile.shared)
                            } else {
                                PremiumView(gameState: gameState)
                            }
                        }
                        #if os(iOS)
                        .modifier(PresentationDetentsModifier())
                        #endif
                    }
            }
        }
    }
} 