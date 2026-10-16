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
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        }
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

/// Для deep link: открытие профиля по ссылке (worldarena.games/profile/CODE или worldarenacapitals://profile/CODE).
private struct PendingProfileLink: Identifiable {
    let id = UUID()
    let friendCode: String
}

private func parseProfileCode(from url: URL) -> String? {
    if ["worldarena.games", "capital.worldarena.games"].contains(url.host ?? ""), url.path.hasPrefix("/profile/") {
        return url.path.replacingOccurrences(of: "/profile/", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    if url.scheme == "worldarenacapitals", url.host == "profile" {
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
        if CommandLine.arguments.contains("UITestingOnboarding") { return true }
        if CommandLine.arguments.contains("UITesting") { return false }
        #endif
        return !OnboardingView.hasCompletedOnboarding
    }()

    @ViewBuilder private var launchContent: some View {
        #if targetEnvironment(simulator)
        if CommandLine.arguments.contains("AppIconQA") {
            AppIconSelectionView()
        } else if CommandLine.arguments.contains("LifecycleBonusQA") {
            LifecycleBonusView(contactID: "preview", loadState: {
                .init(sessionId: "preview", question: .init(index: 0, total: 10, flag: "FR", options: ["FR", "DE", "ES", "IT"]), done: false, correct: nil, total: 10, reward: nil)
            }, submitAnswer: { _, index, _ in
                let done = index == 9
                return .init(sessionId: "preview", question: done ? nil : .init(index: index + 1, total: 10, flag: "FR", options: ["FR", "DE", "ES", "IT"]), done: done, correct: done ? 10 : nil, total: 10, reward: done ? .init(id: "preview", amount: 2) : nil)
            })
        } else if CommandLine.arguments.contains("FBucksRewardQA") {
            VStack { FBucksFirstRewardCard(); Spacer() }.padding()
        } else if CommandLine.arguments.contains("StoreCaptureShop") {
            AvatarShopView()
        } else if CommandLine.arguments.contains("PremiumCaptureMap") {
            PremiumScreenshotCapture(screen: "map")
        } else if CommandLine.arguments.contains("PremiumCaptureCountry") {
            PremiumScreenshotCapture(screen: "country")
        } else if CommandLine.arguments.contains("LearningCaptureEurope") {
            NavigationView { ContinentDetailView(continentName: "Европа", continentEmoji: "🇪🇺") }.navigationViewStyle(.stack)
        } else if CommandLine.arguments.contains("LearningCaptureEgypt") {
            LearningCountryNavigationQA()
        } else if CommandLine.arguments.contains("PremiumStoryQA") {
            PremiumView(gameState: gameState)
        } else {
            normalLaunchContent
        }
        #else
        normalLaunchContent
        #endif
    }

    @ViewBuilder private var normalLaunchContent: some View {
        #if DEBUG
        if CommandLine.arguments.contains("UITestingDuelNotification") {
            DuelNotificationInteractionPreview()
        } else if CommandLine.arguments.contains("UITestingPremium") {
            PremiumView(gameState: gameState)
        } else if CommandLine.arguments.contains("UITestingShop") {
            AvatarShopView()
        } else if CommandLine.arguments.contains("UITestingLargeQuiz") {
            LargeQuizPreview(gameState: gameState)
        } else if CommandLine.arguments.contains("UITestingDuelResults") {
            DuelResultsPreview()
        } else if CommandLine.arguments.contains("UITestingLeagueResult") {
            LeagueResultPreview()
        } else if CommandLine.arguments.contains("UITestingTabletPages") {
            TabletLayoutPreview(gameState: gameState)
        } else {
            MainTabView()
        }
        #else
        MainTabView()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            launchContent
                .environmentObject(gameState)
                .environmentObject(notificationService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .modifier(PremiumPresentationModifier(showPremium: $showPremiumFromNotif, gameState: gameState))
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL, let code = parseProfileCode(from: url), !code.isEmpty {
                        pendingProfileLink = PendingProfileLink(friendCode: code)
                    }
                }
                .onOpenURL { url in
                    if url.scheme == "worldarenacapitals", url.host == "campaign", let id = url.pathComponents.last, UUID(uuidString: id) != nil {
                        UserDefaults.standard.set(id, forKey: "lifecycle.pendingLink")
                        NotificationCenter.default.post(name: Notification.Name("OpenLifecycleCampaign"), object: id)
                        return
                    }

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
                .task { await ProgressMailSync.sync() }
                .onAppear {
                    CapitalAppIconService.updateForCurrentLanguage()
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
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    UserProfile.shared.reconcileStreakFreezes()
                    await StreakFreezeGifts.shared.sync(profile: UserProfile.shared)
                    await gameState.syncPremiumStatus()
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

/// Present pages using the available window size; individual views own readable content widths.
struct IPadSheetLikeFullScreenContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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
#if DEBUG
private struct DuelResultsPreview: View {
    @State private var page = 0
    var body: some View {
        let winner = ["challenger", "opponent", "pending"][page % 3]
        GameResultView(score: 10, totalQuestions: 10, timeElapsed: 45,
            duelResult: DuelResultInfo(challengerName: "You", opponentName: "Alex",
                challengerScore: 10, opponentScore: 10, challengerTimeMs: 45000,
                opponentTimeMs: 40000, serverWinnerSide: winner, youAreChallenger: true),
            onContinue: { page += 1 })
            .id(page)
            .overlay(alignment: .topTrailing) {
                Button("Next QA outcome") { page += 1 }.accessibilityIdentifier("qa.nextOutcome")
            }
    }
}

private struct LeagueResultPreview: View {
    @State private var page = 0
    var body: some View {
        let movement = ["demoted", "stayed", "promoted", "stayed"][page % 4]
        let rank = [20, 9, 2, 1][page % 4]
        LeagueWeeklyResultModalView(result: LeagueWeeklyResult(
            weekId: "qa", leagueBeforeId: League.platinum.rawValue, leagueAfterId: League.gold.rawValue,
            finalRank: rank, participantsCount: 20, podiumPlace: rank <= 3 ? rank : nil,
            movement: movement, rewardCoins: 0, rewardXp: 0, rewardBucks: rank <= 3 ? 3 : 0,
            motivationMessageCode: "league_motivation_" + (movement == "demoted" ? "demotion" : "stayed") + "_01",
            homeBannerVisible: false, leagueResultSeenAt: nil, createdAt: Date()), onDismiss: { page += 1 })
            .id(page)
    }
}

private struct LargeQuizPreview: View {
    @ObservedObject var gameState: GameState
    @StateObject private var model: GameViewModel
    init(gameState: GameState) {
        self.gameState = gameState
        _model = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    private let country = Country(id: "BRA", name: .init(common: "Brazil", official: "Brazil", nativeName: nil),
        flagURL: URL(string: "https://flagcdn.com/w320/br.png")!, region: "Americas", subregion: "South America", latlng: [-10, -55],
        capital: ["Brasília"], population: 215000000, area: 8520000, translations: nil)
    var body: some View {
        VStack(spacing: 0) {
            Button("Flip QA card") { model.isShowingInfo.toggle(); model.isShowingResult = model.isShowingInfo }
                .font(.system(size: 16)).frame(height: 120).accessibilityIdentifier("qa.flip")
            FittingPhoneQuizContent(viewModel: model, country: country)
        }
        .dynamicTypeSize(CommandLine.arguments.contains("UITestingNormalText") ? .large : (CommandLine.arguments.contains("UITestingExtremeText") ? .accessibility3 : .xxxLarge))
        .onAppear {
            gameState.currentFlag = country
            gameState.options = (CommandLine.arguments.contains("UITestingNormalText") ? ["ARE", "ROU", "AUS", "TUR", "USA", "BRA"] : ["ARE", "ROU", "AUS", "TUR", "PER", "GBR", "USA", "BRA"]).map { code in
                Country(id: code, name: .init(common: code, official: code, nativeName: nil), flagURL: country.flagURL,
                    region: "Americas", subregion: nil, capital: nil, population: 0, area: nil, translations: nil)
            }
        }
    }
}

private struct TabletLayoutPreview: View {
    @ObservedObject var gameState: GameState
    @State private var page = 0
    var body: some View {
        IPadSheetLikeFullScreenContainer {
            Group {
                switch page {
                case 0: GameResultView(score: 14, totalQuestions: 15, timeElapsed: 87, earnedFBucks: 1, onContinue: {})
                case 1: StreakView(currentStreak: 3, onContinue: {})
                case 2: FriendStreaksView(friends: UserProfile.shared.friends, gameState: gameState, onRemind: { _ in nil }, onContinue: {})
                case 3: QuestResultsView(dailyQuests: [], monthlyQuests: UserProfile.shared.monthlyQuests, onContinue: {}, onPlayAgain: {}, onHome: {}, onShare: {})
                default: FBucksInfoView()
                }
            }
            .environmentObject(gameState)
            .environmentObject(UserProfile.shared)
            .overlay(alignment: .topTrailing) {
                Button("Next QA page") { page += 1 }
                    .padding(12).background(.regularMaterial)
                    .accessibilityIdentifier("qa.nextPage")
            }
        }
    }
}
#endif

#if DEBUG
private struct LearningCountryNavigationQA: View {
    @State private var showingCountry = true
    var body: some View {
        NavigationView {
            VStack {
                Text("Country navigation").accessibilityIdentifier("learning.qa.root")
                NavigationLink(isActive: $showingCountry) {
                    CountryDetailView(countryCode: "EG", countryName: "Єгипет", flagEmoji: "🇪🇬", navigationCountryCodes: ["EG", "TL", "JP"])
                } label: { Text("Open Egypt") }
            }
        }.navigationViewStyle(.stack)
    }
}
#endif
