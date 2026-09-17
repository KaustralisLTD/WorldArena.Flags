import SwiftUI
#if os(iOS)
import UIKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let apnsDeviceTokenKey = "apns.deviceToken"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        LocalProgressICloudMirror.restoreFromICloudIntoUserDefaultsIfMissing()
        LocalProgressICloudMirror.registerForRemoteUpdates()
        // ATT: запрашиваем сразу после старта приложения, чтобы системный попап гарантированно появлялся и на iPad.
        // Инициализацию рекламных SDK (MobileAds) держим позже в `FlagsWorldApp.bootstrapTrackingAndAdsIfNeeded()`.
#if canImport(AppTrackingTransparency)
        Task { @MainActor in
            TrackingAuthorizationService.shared.requestIfNeeded { }
        }
#endif

        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        // Для Google Sign-In на реальном устройстве иногда нужен явный clientID.
        #if canImport(GoogleSignIn) && os(iOS)
        if let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url),
           let clientID = dict["CLIENT_ID"] as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        #endif
        #if canImport(GoogleMobileAds)
        // Важно: MobileAds.start() вызываем позже, после ATT (см. FlagsWorldApp.onAppear).
        #if !DEBUG
        // Release: явно без тестовых device id. В DEBUG не трогаем список — иначе `= []` затирает авто-пометку симулятора как тестового (Google: simulators are test devices).
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = []
        #endif
        #endif
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: Self.apnsDeviceTokenKey)
        NotificationCenter.default.post(name: Notification.Name("apnsDeviceTokenUpdated"), object: nil)
        print("✅ APNs device token saved")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs registration failed: \(error.localizedDescription)")
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

    #if canImport(GoogleSignIn)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Для завершения Google Sign-In после возврата из браузера/окон.
        return GIDSignIn.sharedInstance.handle(url)
    }
    #endif
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
    @State private var didBootstrapAds = false
    @State private var showPremiumFromNotif = false
    @State private var previousScenePhase: ScenePhase?
    @State private var pendingProfileLink: PendingProfileLink?
    @State private var showOnboarding: Bool = {
        #if DEBUG
        if CommandLine.arguments.contains("UITesting") { return false }
        #endif
        return !OnboardingView.hasCompletedOnboarding
    }()

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
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                        .environmentObject(gameState)
                        .interactiveDismissDisabled(true)
                }
                .onAppear {
                    #if os(macOS)
                    LocalProgressICloudMirror.registerForRemoteUpdates()
                    #endif
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

                    // Game Center: аутентифицируем игрока и синхронизируем прогресс достижений.
                    GameCenterAchievementsService.shared.authenticateIfNeeded { ok in
                        if ok {
                            Task { @MainActor in
                                GameCenterAchievementsService.shared.reportAllAchievementsProgress(userProfile: UserProfile.shared)
                            }
                        }
                    }

                    // ATT сначала, AdMob и загрузка rewarded — только после ATT-шага.
                    bootstrapTrackingAndAdsIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showPremiumFromHome"))) { _ in
                    showPremiumFromNotif = true
                }
                .measureMetrics()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    await FriendsService.shared.syncServerFriendCode(for: UserProfile.shared, maxAttempts: 1)
                }
            }
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

    @MainActor
    private func bootstrapTrackingAndAdsIfNeeded() {
        guard !didBootstrapAds else { return }
        didBootstrapAds = true

        TrackingAuthorizationService.shared.requestIfNeeded {
            #if canImport(GoogleMobileAds)
            // Рекомендация Google: загружать объявления после колбэка start (таймаут ~10 с, медиация может догонять позже).
            MobileAds.shared.start { _ in
                Task { @MainActor in
                    await RewardedAdService.shared.loadAd()
                }
            }
            #else
            Task { await RewardedAdService.shared.loadAd() }
            #endif
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

/// iPad: полноэкранный фон, контент по центру с шириной как у системного sheet (~телефонная колонка), без «растягивания».
struct IPadSheetLikeFullScreenContainer<Content: View>: View {
    static var maxContentWidth: CGFloat { 600 }
    static var horizontalInset: CGFloat { 24 }

    @ViewBuilder var content: () -> Content

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            GeometryReader { geo in
                let w = geo.size.width
                let safeW = (w.isFinite && w > 0) ? w : UIScreen.main.bounds.width
                let colW = max(1, min(Self.maxContentWidth, safeW - Self.horizontalInset * 2))
                ZStack {
                    Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea()
                    HStack(alignment: .top, spacing: 0) {
                        Spacer(minLength: 0)
                        content()
                            .frame(maxWidth: colW)
                            .frame(maxHeight: .infinity, alignment: .top)
                        Spacer(minLength: 0)
                    }
                }
            }
            .ignoresSafeArea()
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}

/// На iPad даже `presentationDetents([.large])` даёт узкий лист; fullScreen + узкая колонка по центру.
private struct SheetOrFullScreenOnIPadModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .fullScreenCover(isPresented: $isPresented) {
                    IPadSheetLikeFullScreenContainer {
                        sheetContent()
                    }
                }
        } else {
            content
                .sheet(isPresented: $isPresented, content: sheetContent)
        }
        #else
        content
            .sheet(isPresented: $isPresented, content: sheetContent)
        #endif
    }
}

private struct SheetItemOrFullScreenOnIPadModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let sheetContent: (Item) -> SheetContent

    func body(content: Content) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .fullScreenCover(item: $item) { i in
                    IPadSheetLikeFullScreenContainer {
                        sheetContent(i)
                    }
                }
        } else {
            content
                .sheet(item: $item, content: sheetContent)
        }
        #else
        content
            .sheet(item: $item, content: sheetContent)
        #endif
    }
}

extension View {
    /// iPhone: обычный sheet. iPad: на весь экран (как ожидают «страницы» F-Bucks, премиум, настройки).
    func sheetOrFullScreenOnIPad<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(SheetOrFullScreenOnIPadModifier(isPresented: isPresented, sheetContent: content))
    }

    func sheetItemOrFullScreenOnIPad<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(SheetItemOrFullScreenOnIPadModifier(item: item, sheetContent: content))
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
                        IPadSheetLikeFullScreenContainer {
                            if gameState.isPremium {
                                ManageSubscriptionView()
                                    .environmentObject(gameState)
                                    .environmentObject(UserProfile.shared)
                            } else {
                                PremiumView(gameState: gameState)
                            }
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
                        IPadSheetLikeFullScreenContainer {
                            if gameState.isPremium {
                                ManageSubscriptionView()
                                    .environmentObject(gameState)
                                    .environmentObject(UserProfile.shared)
                            } else {
                                PremiumView(gameState: gameState)
                            }
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