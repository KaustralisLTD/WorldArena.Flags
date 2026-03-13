import SwiftUI
#if os(iOS)
import UIKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
        return true
    }
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

/// Для deep link: открытие профиля по ссылке (worldarena.games/profile/CODE или worldarenaflags://profile/CODE).
private struct PendingProfileLink: Identifiable {
    let id = UUID()
    let friendCode: String
}

private func parseProfileCode(from url: URL) -> String? {
    if url.host == "worldarena.games", url.path.hasPrefix("/profile/") {
        return url.path.replacingOccurrences(of: "/profile/", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    if url.scheme == "worldarenaflags", url.host == "profile" {
        return url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    return nil
}

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
    @State private var pendingProfileLink: PendingProfileLink?

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(gameState)
                .environmentObject(notificationService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .modifier(PremiumPresentationModifier(showPremium: $showPremiumFromNotif, gameState: gameState))
                .onOpenURL { url in
                    let code = parseProfileCode(from: url)
                    if let code, !code.isEmpty {
                        pendingProfileLink = PendingProfileLink(friendCode: code)
                    }
                }
                .fullScreenCover(item: $pendingProfileLink) { link in
                    ProfileByLinkView(friendCode: link.friendCode, gameState: gameState)
                        .environmentObject(UserProfile.shared)
                }
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
                    // Предзагрузка награждаемой рекламы (видео за жизни)
                    Task { await RewardedAdService.shared.loadAd() }
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