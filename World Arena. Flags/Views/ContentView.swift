import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var themeManager = AppThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var leaguesService = LeaguesService.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    @AppStorage(GameHomeLayoutVariant.storageKey) private var homeLayoutRaw: Int = GameHomeLayoutVariant.quickStart.rawValue

    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    /// iPad полноширинный layout главной (variant 2): Continue внутри hero, без нижнего sticky.
    private var isIPadQuickTabletHome: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
        #else
        false
        #endif
    }
    
    private func isLandscapeIPad(_ width: CGFloat, _ height: CGFloat) -> Bool {
        isIPad && width > height
    }

    private var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    /// Вариант 2 главной — быстрый старт (переключение в Настройках).
    private var useQuickHomeLayout: Bool {
        GameHomeLayoutVariant(rawValue: homeLayoutRaw) == .quickStart
    }

    // Animation states
    @State private var showContent = false
    @State private var hasAnimatedContentOnce = false
    @State private var pendingPremiumAlert = false
    @State private var showPremiumSheet = false
    @State private var eruditePremiumAlert = false
    @State private var showDuelOpponentPicker = false
    @State private var showFBucksInfo = false
    @State private var isAcceptingIncomingDuel = false
    @State private var isDifficultySliderInteracting = false
    @State private var isRewardedLoadingFromHome = false
    @State private var rewardedUnavailableAlert = false
    @State private var firstLaunchDate: Date = Date()
    @State private var onboardingNow: Date = Date()
    @State private var cityLeaderboardPercentile: Int = 72
    @State private var showDuelAnnouncement = false
    @State private var showDuelPrepareFailedAlert = false
    @State private var showTimeChallengeIntro = false
    @State private var showSurvivalIntro = false
    @State private var dismissedIncomingDuelIds: Set<String> = []
    @State private var userDismissedCityCard = false
    @State private var userDismissedWelcomeBanner = false
    @State private var userDismissedFirstGameBanner = false
    @State private var onboardingBannerPhase: Int = 0
    @State private var didInitialAppearSetup = false

    private static let duelExpiryHours: TimeInterval = 24
    // MARK: — Онбоардинг баннеры (порядок сверху вниз)
    // 1) Welcome — 0 игр: «Выбери регион и сыграй первую игру»; скрывается по крестику/свайпу или после первой игры.
    // 2) First game — после 1-й игры один раз: «Первая игра позади! Сыграй ещё 4 с 70%+ — откроется рейтинг города».
    // 3) Birthday — свой/друга ДР (если есть).
    // 4) City challenge — 5+ игр, 70%+ точности, 5 мин с первого показа: «Ты в топ X% города», цель 90%.
    // 5) Incoming duel — входящий вызов (24ч).
    private static let firstRunWindowSeconds: TimeInterval = 300
    private static let firstLaunchDateKey = "onboarding.firstLaunchDate.v1"
    private static let firstRunPercentileKey = "onboarding.cityPercentile.v1"
    private static let cityCardFirstShownAtKey = "onboarding.cityCardFirstShownAt.v1"
    private static let welcomeBannerDismissedKey = "onboarding.welcomeBannerDismissed.v1"
    private static let firstGameBannerShownKey = "onboarding.firstGameBannerShown.v1"
    /// Очередь онбоардинг-баннеров: 0=welcome, 1=first game, 2=city. Показываем только один результативный за раз.
    private static let onboardingBannerPhaseKey = "onboarding.bannerPhase.v1"

    /// Оставшееся время челленджа от момента первого показа карточки (не от установки приложения).
    private var firstRunRemainingSeconds: Int {
        let defaults = UserDefaults.standard
        guard let shownAt = defaults.object(forKey: Self.cityCardFirstShownAtKey) as? Date else {
            return Int(Self.firstRunWindowSeconds)
        }
        let elapsed = onboardingNow.timeIntervalSince(shownAt)
        return max(0, Int(Self.firstRunWindowSeconds - elapsed))
    }

    private var shouldShowWelcomeBanner: Bool {
        userProfile.totalGamesPlayed == 0 && !userDismissedWelcomeBanner && onboardingBannerPhase <= 0
    }

    private var shouldShowFirstGameBanner: Bool {
        guard !UserDefaults.standard.bool(forKey: Self.firstGameBannerShownKey) else { return false }
        return userProfile.totalGamesPlayed >= 1 && !userDismissedFirstGameBanner && onboardingBannerPhase == 1
    }

    /// Показывать карточку «ты в топ X% игроков города» только после 5+ игр с точностью 70%+ и в течение 5 мин после первого показа. Один результативный баннер за раз.
    private var shouldShowFirstRunMotivation: Bool {
        guard !userDismissedCityCard, onboardingBannerPhase >= 2 else { return false }
        let qualifies = userProfile.totalGamesPlayed >= 5 && userProfile.accuracy >= 70
        guard qualifies else { return false }
        let defaults = UserDefaults.standard
        if let shownAt = defaults.object(forKey: Self.cityCardFirstShownAtKey) as? Date {
            return onboardingNow.timeIntervalSince(shownAt) < Self.firstRunWindowSeconds
        }
        return true
    }
    private var pendingIncomingDuel: DuelChallenge? {
        let duelInvitesEnabled = (UserDefaults.standard.object(forKey: "duelInvitesNotifications") as? Bool) ?? true
        guard duelInvitesEnabled else { return nil }
        return userProfile.incomingDuelChallenges.first { c in
            (c.status == .pending || c.status == .challengerCompleted)
                && Date().timeIntervalSince(c.createdAt) < Self.duelExpiryHours
                && !DuelInviteSuppression.isSuppressed(c.id)
        }
    }

    /// Основной контент главной (без обёртки NavigationView — на iPad она даёт боковую колонку)
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            // На iPad контент на всю ширину экрана (без ограничения как на телефоне)
            // Игра открывается через fullScreenCover в MainTabView (isNavigatingToGame)
            // Статичный фон без анимации (убрана анимация градиента из угла)
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            GeometryReader { geo in
                    let landscapeIPad = isLandscapeIPad(geo.size.width, geo.size.height)
                    let compactPhone = !isIPad && geo.size.height <= 880
                    
                    VStack(spacing: 0) {
                        if landscapeIPad {
                            if useQuickHomeLayout {
                                Color.clear
                                    .frame(height: 8)
                            } else {
                            // iPad горизонтально: крупный логотип по центру, жизни слева и F-Bucks справа
                            ZStack(alignment: .center) {
                                HStack(alignment: .center, spacing: 16) {
                                    LivesInfoBar(gameState: gameState, largeText: isIPad)
                                    Spacer(minLength: 8)
                                    Button(action: { showFBucksInfo = true }) {
                                        FBucksChipView(count: userProfile.fBucks, size: isIPad ? .regular : .compact)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                                VStack(spacing: 6) {
                                    Text("World Arena Flags")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: Color.appTextGradient(for: effectiveColorScheme),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text(localizationManager.localizedString("Learn flags and countries of the World"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule()
                                        .fill(effectiveColorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.22))
                                )
                            }
                            .padding(.vertical, 14)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                            }
                        } else {
                            if !useQuickHomeLayout {
                            // Обычная шапка (телефон). В тёмной теме — тень под текст логотипа, чтобы не терялся на чёрном фоне.
                            VStack(spacing: 6) {
                                Text("World Arena Flags")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: Color.appTextGradient(for: effectiveColorScheme),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: effectiveColorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.3), radius: effectiveColorScheme == .dark ? 6 : 4, x: 0, y: 2)
                                Text(localizationManager.localizedString("Learn flags and countries of the World"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                            .background(
                                Capsule()
                                    .fill(effectiveColorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.22))
                            )
                            .padding(.top, 8)
                            .padding(.bottom, compactPhone ? 2 : 6)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                            HStack(alignment: .center, spacing: 10) {
                                LivesInfoBar(gameState: gameState, largeText: isIPad)
                                Spacer(minLength: 0)
                                Button(action: {
                                    showFBucksInfo = true
                                }) {
                                    FBucksChipView(count: userProfile.fBucks, size: isIPad ? .regular : .compact)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, compactPhone ? 2 : 6)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                            } else {
                                Color.clear
                                    .frame(height: compactPhone ? 6 : 10)
                            }
                        }

                        if useQuickHomeLayout {
                            quickPinnedHeader
                                .padding(.horizontal, 20)
                                .padding(.bottom, compactPhone ? 6 : 10)
                                .background(Color(UIColor.systemGroupedBackground))
                        }

                        ScrollView {
                            VStack(spacing: compactPhone ? 10 : 14) {
                                // Входящий дуэльный popup показывается только глобально (в MainTabView),
                                // чтобы не дублировать уведомление вторым баннером на Главной.

                                // Итог дуэли — баннер на главной (не за шторкой), с возможностью закрыть
                                if let duelResult = gameState.pendingDuelResult {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        DuelResultBannerView(result: duelResult) {
                                            gameState.pendingDuelResult = nil
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .opacity(showContent ? 1 : 0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                                    }
                                }

                                // Итоги недели лиги — баннер до просмотра или закрытия
                                if let weeklyResult = leaguesService.latestWeeklyResult,
                                   leaguesService.shouldShowWeeklyHomeBanner(for: weeklyResult) {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        LeagueWeekFinishedBannerView(
                                            result: weeklyResult,
                                            onViewResults: {
                                                NotificationCenter.default.post(name: Notification.Name("SwitchToLeagueTab"), object: nil)
                                            },
                                            onDismiss: { leaguesService.markHomeBannerDismissed() }
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .opacity(showContent ? 1 : 0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28), value: showContent)
                                    }
                                }

                                if shouldShowWelcomeBanner {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        OnboardingWelcomeBannerView(
                                            onDismiss: {
                                                userDismissedWelcomeBanner = true
                                                UserDefaults.standard.set(true, forKey: Self.welcomeBannerDismissedKey)
                                                onboardingBannerPhase = 1
                                                UserDefaults.standard.set(1, forKey: Self.onboardingBannerPhaseKey)
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }

                                if shouldShowFirstGameBanner {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        OnboardingFirstGameBannerView(
                                            onDismiss: {
                                                userDismissedFirstGameBanner = true
                                                UserDefaults.standard.set(true, forKey: Self.firstGameBannerShownKey)
                                                onboardingBannerPhase = 2
                                                UserDefaults.standard.set(2, forKey: Self.onboardingBannerPhaseKey)
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }

                                if (userProfile.birthday != nil && userProfile.isTodayBirthday(userProfile.birthday!)) || !userProfile.friendsWithBirthdayToday.isEmpty {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        BirthdayBannerView(userProfile: userProfile)
                                            .padding(.horizontal, 20)
                                    }
                                }

                                if shouldShowFirstRunMotivation {
                                    ipadHomeBannerWidth(landscapeIPad: landscapeIPad) {
                                        FirstRunMotivationCardView(
                                            percentile: cityLeaderboardPercentile,
                                            secondsLeft: firstRunRemainingSeconds,
                                            onDismiss: { userDismissedCityCard = true }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }

                                if useQuickHomeLayout {
                                    GameHomeVariant2View(
                                        gameState: gameState,
                                        compactPhone: compactPhone,
                                        isIPad: isIPad,
                                        tabletLandscapeAlbum: isIPad && landscapeIPad,
                                        showContent: showContent,
                                        showsHeaderRow: false,
                                        onShowFBucks: { showFBucksInfo = true },
                                        onOpenLeagueTab: {
                                            NotificationCenter.default.post(name: Notification.Name("SwitchToLeagueTab"), object: nil)
                                        },
                                        onOpenQuestsTab: {
                                            NotificationCenter.default.post(name: Notification.Name("SwitchToQuestsTab"), object: nil)
                                        },
                                        onContinuePlay: isIPadQuickTabletHome ? { performStartGameFromHome() } : nil
                                    )
                                    .environmentObject(userProfile)
                                } else {
                                    if let lost = userProfile.streakRecoveryLostChain, lost >= 2 {
                                        StreakRecoveryOfferBanner(lost: lost, isDark: effectiveColorScheme == .dark)
                                            .environmentObject(userProfile)
                                            .padding(.horizontal, 20)
                                    }
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(localizationManager.localizedString("Select Region"))
                                            .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)
                                        RegionSelectionView(gameState: gameState, columnCount: landscapeIPad ? 3 : 2, compact: landscapeIPad, largeFontForLandscape: isIPad)
                                    }
                                    .padding(.vertical, compactPhone ? 4 : 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal, 20)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 20)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)

                                    VStack(alignment: .leading, spacing: landscapeIPad ? 4 : 8) {
                                        Text(localizationManager.localizedString("Select Level"))
                                            .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)

                                        DifficultySelectionView(
                                            gameState: gameState,
                                            compact: landscapeIPad,
                                            phoneCompact: compactPhone,
                                            largeFontForIPad: isIPad,
                                            isInteracting: $isDifficultySliderInteracting
                                        )
                                    }
                                    .padding(.vertical, landscapeIPad ? 2 : (compactPhone ? 1 : 4))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal, 20)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showContent)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(localizationManager.localizedString("Game Mode"))
                                            .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)

                                        GameModeSelectionView(
                                            gameState: gameState,
                                            largeFontForLandscape: isIPad,
                                            compactForAccessibility: sizeCategory.isAccessibilityCategory || sizeCategory >= .extraExtraLarge
                                        )
                                    }
                                    .padding(.vertical, compactPhone ? 4 : 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal, 20)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 40)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: showContent)

                                    if landscapeIPad {
                                        startGameButtonContent(compactPhone: compactPhone)
                                    }
                                }
                        }
                        .padding(.bottom, landscapeIPad ? (compactPhone ? 8 : 20) : 24)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if useQuickHomeLayout, !isIPadQuickTabletHome {
                            GameHomeStickyContinueView(
                                gameState: gameState,
                                compactPhone: compactPhone,
                                isIPad: isIPad,
                                showContent: showContent,
                                onContinue: { performStartGameFromHome() }
                            )
                            .environmentObject(userProfile)
                            .padding(.top, 10)
                            .padding(.bottom, landscapeIPad ? 20 : 10)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.systemGroupedBackground))
                        } else if !landscapeIPad {
                            startGameButtonContent(compactPhone: compactPhone)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                                .background(Color(UIColor.systemGroupedBackground))
                        }
                    }
                    }
                }
            }
            .modifier(PremiumPresentationModifier(showPremium: $showPremiumSheet, gameState: gameState))
            .alert(localizationManager.localizedString("No lives available"), isPresented: $pendingPremiumAlert) {
                if !gameState.isPremium && RewardedAdService.isRewardedAdEnabled {
                    Button(localizationManager.localizedString(isRewardedLoadingFromHome ? "Loading..." : "Watch video for +3 lives")) {
                        isRewardedLoadingFromHome = true
                        Task { @MainActor in
                            var adShown = false
                            // Пытаемся несколько раз: загрузить и сразу показать
                            for attempt in 0..<3 where !adShown {
                                if RewardedAdService.shared.isReady {
                                    adShown = true
                                    RewardedAdService.shared.showIfAvailable(from: nil, onReward: {
                                        DispatchQueue.main.async {
                                            gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                                            if gameState.selectedPlayMode == .duel {
                                                showDuelOpponentPicker = true
                                            } else {
                                                Task { await gameState.startNewGameWithCurrentRegions() }
                                            }
                                        }
                                    }, onUnavailable: {
                                        // здесь ничего не делаем, обработаем ниже через adShown
                                    })
                                    break
                                }
                                await RewardedAdService.shared.loadAd()
                                if RewardedAdService.shared.isReady {
                                    adShown = true
                                    RewardedAdService.shared.showIfAvailable(from: nil, onReward: {
                                        DispatchQueue.main.async {
                                            gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                                            if gameState.selectedPlayMode == .duel {
                                                showDuelOpponentPicker = true
                                            } else {
                                                Task { await gameState.startNewGameWithCurrentRegions() }
                                            }
                                        }
                                    }, onUnavailable: {
                                        // см. выше — обрабатываем через adShown
                                    })
                                    break
                                }
                                // Небольшая пауза перед следующей попыткой, кроме последней
                                if attempt < 2 {
                                    try? await Task.sleep(nanoseconds: 600_000_000)
                                }
                            }
                            isRewardedLoadingFromHome = false
                            if !adShown {
                                rewardedUnavailableAlert = true
                            }
                        }
                    }
                    .disabled(isRewardedLoadingFromHome)
                }
                Button(localizationManager.localizedString("Go Premium")) {
                    showPremiumSheet = true
                }
                Button(localizationManager.localizedString("Close"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("Unfortunately, the game is not available now: you have no lives. You can buy lives or go Premium."))
            }
            .alert(localizationManager.localizedString("Ad unavailable"), isPresented: $rewardedUnavailableAlert) {
                Button(localizationManager.localizedString("OK"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("Ad unavailable. Try again later."))
            }
            .alert(localizationManager.localizedString("Erudite Level - Premium Only"), isPresented: $eruditePremiumAlert) {
                Button(localizationManager.localizedString("Continue with Premium")) {
                    showPremiumSheet = true
                }
                Button(localizationManager.localizedString("Cancel"), role: .cancel) { }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localizedString("This feature is available only for Premium users"))
                    
                    Text(localizationManager.localizedString("Get Premium access to unlock:"))
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("• Erudite difficulty level"))
                        Text(localizationManager.localizedString("• My Mistakes section"))
                        Text(localizationManager.localizedString("• Unlimited lives"))
                        Text(localizationManager.localizedString("• All premium features"))
                    }
                    .font(.caption)
                }
            }
            .sheetOrFullScreenOnIPad(isPresented: $showDuelOpponentPicker) {
                DuelOpponentPickerView(gameState: gameState, onDuelReadyToStart: {
                    showDuelOpponentPicker = false
                    showDuelAnnouncement = true
                })
                    .environmentObject(userProfile)
            }
            .fullScreenCover(isPresented: $showDuelAnnouncement) {
                DuelAnnouncementView(
                    gameState: gameState,
                    onDismiss: { showDuelAnnouncement = false },
                    onStart: {
                        Task {
                            let ok = await createDuelChallengeIfNeeded()
                            if !ok {
                                await MainActor.run { showDuelPrepareFailedAlert = true }
                                return
                            }
                            await gameState.startNewGameWithCurrentRegions()
                            await MainActor.run { showDuelAnnouncement = false }
                        }
                    }
                )
            }
            .fullScreenCover(isPresented: $showTimeChallengeIntro) {
                TimeChallengeIntroView(
                    gameState: gameState,
                    onDismiss: { showTimeChallengeIntro = false },
                    onStart: {
                        Task {
                            await gameState.startNewGameWithCurrentRegions()
                            await MainActor.run { showTimeChallengeIntro = false }
                        }
                    }
                )
            }
            .fullScreenCover(isPresented: $showSurvivalIntro) {
                SurvivalIntroView(
                    gameState: gameState,
                    onDismiss: { showSurvivalIntro = false },
                    onStart: {
                        Task {
                            await gameState.startNewGameWithCurrentRegions()
                            await MainActor.run { showSurvivalIntro = false }
                        }
                    }
                )
            }
            .sheetOrFullScreenOnIPad(isPresented: $showFBucksInfo) {
                FBucksInfoView()
            }
            .alert(localizationManager.localizedString("duel.error.alert.title"), isPresented: $showDuelPrepareFailedAlert) {
                Button(localizationManager.localizedString("OK"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("duel.error.prepare_questions"))
            }
            .alert(
                localizationManager.localizedString("Error"),
                isPresented: Binding(
                    get: { gameState.error != nil },
                    set: { if !$0 { gameState.error = nil } }
                )
            ) {
                Button(localizationManager.localizedString("OK"), role: .cancel) {
                    gameState.error = nil
                }
            } message: {
                Text(
                    (gameState.error as? LocalizedError)?.errorDescription
                        ?? gameState.error?.localizedDescription
                        ?? localizationManager.localizedString("Failed to start game")
                )
            }
            .alert(localizationManager.localizedString("My Mistakes - Premium Only"), isPresented: $gameState.showMistakesPremiumAlert) {
                Button(localizationManager.localizedString("Continue with Premium")) {
                    showPremiumSheet = true
                }
                Button(localizationManager.localizedString("Cancel"), role: .cancel) { }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localizedString("This feature is available only for Premium users"))
                    
                    Text(localizationManager.localizedString("Get Premium access to unlock:"))
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("• Erudite difficulty level"))
                        Text(localizationManager.localizedString("• My Mistakes section"))
                        Text(localizationManager.localizedString("• Unlimited lives"))
                        Text(localizationManager.localizedString("• All premium features"))
                    }
                    .font(.caption)
                }
            }
            .onAppear {
                if !didInitialAppearSetup {
                    didInitialAppearSetup = true
                    // Сброс «залипшего» старта (если прошлый запуск оборвался mid-flight).
                    if gameState.isStartingNewGame && !gameState.isNavigatingToGame {
                        gameState.isStartingNewGame = false
                        gameState.isPreloadingFlags = false
                    }
                    gameState.updateOptionsCount(isIPad: horizontalSizeClass == .regular)
                    setupFirstRunMotivation()
                    userDismissedWelcomeBanner = UserDefaults.standard.bool(forKey: Self.welcomeBannerDismissedKey)
                    userDismissedFirstGameBanner = UserDefaults.standard.bool(forKey: Self.firstGameBannerShownKey)
                    onboardingBannerPhase = UserDefaults.standard.integer(forKey: Self.onboardingBannerPhaseKey)
                    if onboardingBannerPhase == 0 && userProfile.totalGamesPlayed >= 1 {
                        onboardingBannerPhase = 1
                        UserDefaults.standard.set(1, forKey: Self.onboardingBannerPhaseKey)
                    }
                }

                if !gameState.hasAnimatedHomeContentOnce {
                    gameState.hasAnimatedHomeContentOnce = true
                    hasAnimatedContentOnce = true
                    withAnimation(.easeOut(duration: 0.5)) {
                        showContent = true
                    }
                } else {
                    showContent = true
                    hasAnimatedContentOnce = true
                }
                Task {
                    await refreshIncomingDuelChallenges()
                    await gameState.syncOutgoingDuelsWithServer(profile: userProfile)
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
                onboardingNow = date
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// iPad полноэкранный режим: не растягивать три «полосы» на весь экран.
    private var quickHomePinnedHeaderMaxWidth: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
            return 1050
        }
        #endif
        return .infinity
    }

    /// iPad альбом: баннеры по той же max ширине, что и контент главной.
    @ViewBuilder
    private func ipadHomeBannerWidth<Content: View>(landscapeIPad: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: (useQuickHomeLayout && isIPad && landscapeIPad) ? quickHomePinnedHeaderMaxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }

    private var quickPinnedHeader: some View {
        let unifiedBlockHeight: CGFloat = isIPad ? 72 : 56
        let logoSize: CGFloat = isIPad ? 52 : 26
        /// Как число жизней в LivesInfoBar (largeText).
        let statNumberSize: CGFloat = isIPad ? 22 : 15
        return HStack(spacing: 8) {
            LivesInfoBar(gameState: gameState, largeText: isIPad)
                .frame(maxWidth: .infinity, minHeight: unifiedBlockHeight)
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 24))
                Text("\(userProfile.streak)")
                    .font(.system(size: statNumberSize, weight: .bold, design: .rounded))
                Text(localizationManager.localizedString("days"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: unifiedBlockHeight)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            Button(action: { showFBucksInfo = true }) {
                HStack(spacing: 4) {
                    Image("FBucksLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                    Text("\(userProfile.fBucks)")
                        .font(.system(size: statNumberSize, weight: .bold, design: .rounded))
                }
                    .frame(maxWidth: .infinity, minHeight: unifiedBlockHeight)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: quickHomePinnedHeaderMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private func performStartGameFromHome() {
        guard !gameState.isStartingNewGame else { return }
        if gameState.selectedDifficulty == .erudite && !gameState.isPremium {
            eruditePremiumAlert = true
            return
        }
        if !gameState.canStartGameWithLives() {
            pendingPremiumAlert = true
            return
        }
        if gameState.selectedPlayMode == .duel {
            showDuelOpponentPicker = true
            return
        }
        if gameState.selectedPlayMode == .timeChallenge {
            showTimeChallengeIntro = true
            return
        }
        if gameState.selectedPlayMode == .survival {
            showSurvivalIntro = true
            return
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        Task {
            await gameState.startNewGameWithCurrentRegions()
        }
    }

    @ViewBuilder
    private func startGameButtonContent(compactPhone: Bool) -> some View {
        Button(action: {
            performStartGameFromHome()
        }) {
            HStack(spacing: 12) {
                if gameState.isStartingNewGame || gameState.isPreloadingFlags {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            if gameState.isPreloadingFlags {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    Circle()
                                        .trim(from: 0, to: gameState.flagPreloadProgress)
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .frame(width: 20, height: 20)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 0.3), value: gameState.flagPreloadProgress)
                                }
                                Text(localizationManager.localizedString("Loading flags..."))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                                Text(localizationManager.localizedString("Starting..."))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        if gameState.isPreloadingFlags {
                            Text("\(Int(gameState.flagPreloadProgress * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .animation(.easeInOut(duration: 0.3), value: gameState.flagPreloadProgress)
                        }
                    }
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: isIPad ? 26 : 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(localizationManager.localizedString("START GAME"))
                        .font(.system(size: isIPad ? 28 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 76 : (compactPhone ? 46 : 52))
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 1.0),
                                Color(red: 0.4, green: 0.2, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .scaleEffect((gameState.isStartingNewGame || gameState.isPreloadingFlags) ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameState.isStartingNewGame || gameState.isPreloadingFlags)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(gameState.selectedRegions.isEmpty || gameState.isStartingNewGame || gameState.isPreloadingFlags)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
    }

    private func setupFirstRunMotivation() {
        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: Self.firstLaunchDateKey) as? Date {
            firstLaunchDate = saved
        } else {
            let now = Date()
            firstLaunchDate = now
            defaults.set(now, forKey: Self.firstLaunchDateKey)
        }

        let storedPercentile = defaults.integer(forKey: Self.firstRunPercentileKey)
        if storedPercentile == 0 {
            let generated = Int.random(in: 68...78)
            cityLeaderboardPercentile = generated
            defaults.set(generated, forKey: Self.firstRunPercentileKey)
        } else {
            cityLeaderboardPercentile = storedPercentile
        }
        if userProfile.totalGamesPlayed >= 5 && userProfile.accuracy >= 70,
           defaults.object(forKey: Self.cityCardFirstShownAtKey) as? Date == nil {
            defaults.set(Date(), forKey: Self.cityCardFirstShownAtKey)
        }
    }

    private func refreshIncomingDuelChallenges() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let list = try? await DuelAPIService.shared.fetchIncomingChallenges(userId: userId) else { return }
        let existingIds = Set(userProfile.incomingDuelChallenges.map(\.id))
        let newOnes = list.compactMap { $0.toDuelChallenge(opponentId: userId, opponentName: userId) }
            .filter { !existingIds.contains($0.id) }
        await MainActor.run {
            userProfile.incomingDuelChallenges.append(contentsOf: newOnes)
        }
    }

    private func acceptIncomingDuel(_ challenge: DuelChallenge) {
        guard isAcceptingIncomingDuel == false else { return }
        isAcceptingIncomingDuel = true
        Task {
            defer { Task { @MainActor in isAcceptingIncomingDuel = false } }
            let result: (seed: Int, challengerName: String, challengerScore: Int?, duelSetup: DuelAPIService.DuelSetup?)
            do {
                result = try await DuelAPIService.shared.acceptChallenge(
                    challengeId: challenge.id,
                    userId: userProfile.username
                )
                print("[ContentView] acceptIncomingDuel success challengeId=", challenge.id, "seed=", result.seed)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("[ContentView] acceptIncomingDuel failed:", msg, "challengeId=", challenge.id)
                await MainActor.run { isAcceptingIncomingDuel = false }
                return
            }
            await MainActor.run {
                gameState.selectedPlayMode = .duel
                if let setup = result.duelSetup {
                    gameState.applyDuelSetupFromServer(setup)
                } else if
                    let regions = challenge.duelRegions,
                    let difficulty = challenge.duelDifficulty,
                    let gameMode = challenge.duelGameMode
                {
                    gameState.applyDuelSetupFromServer(
                        .init(
                            regions: regions,
                            difficulty: difficulty,
                            gameMode: gameMode,
                            questionsCount: challenge.duelQuestionsCount ?? 0,
                            optionsCount: challenge.duelOptionsCount ?? 0
                        )
                    )
                }
                gameState.duelSeed = result.seed
                gameState.duelChallengeId = challenge.id
                gameState.duelOpponentId = challenge.challengerId
                gameState.duelRoleIsChallenger = false
                gameState.duelChallengerName = result.challengerName
                gameState.duelOpponentName = userProfile.username
                DuelInviteSuppression.clear(challenge.id)
                // Не удаляем incoming-челлендж: он нужен, чтобы после игры дуэль появилась в «Сводке Дуэлей» и чтобы оппонент мог отправить свой счёт.
                dismissedIncomingDuelIds.remove(challenge.id)
            }
            await MainActor.run { showDuelAnnouncement = true }
        }
    }

    private func declineIncomingDuel(_ challenge: DuelChallenge) async {
        guard isAcceptingIncomingDuel == false else { return }
        isAcceptingIncomingDuel = true
        defer { isAcceptingIncomingDuel = false }

        do {
            try await DuelAPIService.shared.declineChallenge(challengeId: challenge.id, userId: userProfile.username)
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("[ContentView] declineIncomingDuel failed:", msg, "challengeId=", challenge.id)
        }

        await MainActor.run {
            DuelInviteSuppression.decline(challenge.id)
            userProfile.incomingDuelChallenges.removeAll { $0.id == challenge.id }
            dismissedIncomingDuelIds.remove(challenge.id)
        }
    }

    /// Для исходящей дуэли: создаём challenge только по нажатию Start duel. `false` — не удалось собрать вопросы (игру не начинаем).
    private func createDuelChallengeIfNeeded() async -> Bool {
        guard gameState.selectedPlayMode == .duel else { return true }
        guard gameState.duelChallengeId == nil else { return true }
        guard gameState.duelRoleIsChallenger else { return true }
        let opponentUsername = (gameState.duelOpponentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let myName = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !opponentUsername.isEmpty, !myName.isEmpty else { return true }

        let seed = gameState.duelSeed ?? Int.random(in: 0..<Int.max)
        await MainActor.run {
            if gameState.duelServerQuestionsCount == nil {
                gameState.duelServerQuestionsCount = gameState.questionsPerGame
            }
        }
        let regions = await MainActor.run { gameState.duelRegionsServerStrings() }
        let difficulty = await MainActor.run { gameState.selectedDifficulty.rawValue }
        let gameMode = await MainActor.run { gameState.selectedGameMode.rawValue }
        let questionsCount = await MainActor.run { gameState.duelServerQuestionsCount ?? gameState.questionsPerGame }
        let optionsCount = await MainActor.run { gameState.optionsCount }
        let questionsPayload = await gameState.buildDuelQuestionsPayload(
            seed: seed,
            questionsCount: questionsCount,
            optionsCount: optionsCount
        )
        guard let questionsPayload, !questionsPayload.isEmpty else { return false }
        var challengeId = UUID().uuidString
        if let serverId = try? await DuelAPIService.shared.createChallenge(
            opponentId: opponentUsername,
            opponentName: opponentUsername,
            seed: seed,
            challengerName: myName,
            challengerId: myName,
            duelSetup: .init(
                regions: regions,
                difficulty: difficulty,
                gameMode: gameMode,
                questionsCount: questionsCount,
                optionsCount: optionsCount,
                questionsPayload: questionsPayload
            )
        ) {
            challengeId = serverId
        }

        await MainActor.run {
            gameState.duelSeed = seed
            gameState.duelChallengeId = challengeId
            gameState.duelServerQuestionsCount = questionsCount
            gameState.duelQuestionsPayload = questionsPayload
            let challenge = DuelChallenge(
                id: challengeId,
                challengerId: myName,
                challengerName: myName,
                opponentId: opponentUsername,
                opponentName: gameState.duelOpponentName ?? opponentUsername,
                seed: seed,
                createdAt: Date(),
                challengerScore: nil,
                opponentScore: nil,
                status: .pending,
                duelRegions: regions,
                duelDifficulty: difficulty,
                duelGameMode: gameMode,
                duelQuestionsCount: questionsCount,
                duelOptionsCount: optionsCount,
                duelQuestionsPayload: questionsPayload
            )
            if !userProfile.outgoingDuelChallenges.contains(where: { $0.id == challengeId }) {
                userProfile.outgoingDuelChallenges.append(challenge)
            }
        }
        return true
    }

    var body: some View {
        Group {
            if isIPad {
                mainContent
            } else {
                NavigationView {
                    mainContent
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Онбоардинг: приветственный баннер (0 игр)
private struct OnboardingWelcomeBannerView: View {
    var onDismiss: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isDismissing = false

    private func dismissWithAnimation() {
        guard !isDismissing else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            Text(localizationManager.localizedString("Onboarding welcome message"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Button(action: dismissWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.green.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.green.opacity(0.3), lineWidth: 1))
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }
}

// MARK: - Онбоардинг: «первая игра сыграна» (1+ игра, один раз)
private struct OnboardingFirstGameBannerView: View {
    var onDismiss: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isDismissing = false

    private func dismissWithAnimation() {
        guard !isDismissing else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            Text(localizationManager.localizedString("Onboarding first game done"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Button(action: dismissWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }
}

struct FirstRunMotivationCardView: View {
    let percentile: Int
    let secondsLeft: Int
    var onDismiss: (() -> Void)? = nil
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isDismissing = false

    private func dismissWithAnimation() {
        guard !isDismissing, let onDismiss = onDismiss else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: localizationManager.localizedString("You already outranked %d%% of players in your city"), percentile))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(localizationManager.localizedString("Goal: keep 90% accuracy in first challenge"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
            if secondsLeft > 0 {
                Text(String(format: localizationManager.localizedString("Challenge ends in %d sec"), secondsLeft))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if onDismiss != nil {
                Button(action: dismissWithAnimation) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }
}

// MARK: - Пре-старт экран Time Challenge
struct TimeChallengeIntroView: View {
    @ObservedObject var gameState: GameState
    var onDismiss: () -> Void
    var onStart: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    private var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    private var introBackgroundColors: [Color] {
        if effectiveColorScheme == .dark {
            return [
                Color(red: 0.04, green: 0.05, blue: 0.09),
                Color(red: 0.10, green: 0.05, blue: 0.12),
                Color(red: 0.02, green: 0.06, blue: 0.14)
            ]
        }
        #if os(iOS)
        return [
            Color(UIColor.systemGroupedBackground),
            Color(UIColor.secondarySystemGroupedBackground),
            Color(UIColor.systemBackground)
        ]
        #else
        return [Color(white: 0.94), Color(white: 0.90), Color(white: 0.97)]
        #endif
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: introBackgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                VStack(spacing: 12) {
                    Text(localizationManager.localizedString("Time Challenge"))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: Color.appTextGradient(for: effectiveColorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .shadow(
                            color: effectiveColorScheme == .dark ? .black.opacity(0.45) : .black.opacity(0.18),
                            radius: effectiveColorScheme == .dark ? 12 : 6,
                            x: 0,
                            y: effectiveColorScheme == .dark ? 6 : 3
                        )

                    Text(localizationManager.localizedString("Answer as many flags as possible before time runs out"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 36)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 12)
                .animation(.spring(response: 0.55, dampingFraction: 0.86), value: headerAppeared)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    introMetricCard(
                        title: localizationManager.localizedString("Duration"),
                        value: String(
                            format: localizationManager.localizedString("Time intro duration seconds fmt"),
                            Int(gameState.selectedDifficulty.timeChallengeDuration),
                            localizationManager.localizedString("Time seconds unit short")
                        ),
                        accent: Color(red: 0.35, green: 0.55, blue: 1.0),
                        symbol: "timer",
                        index: 0
                    )
                    introMetricCard(
                        title: localizationManager.localizedString("TC intro best correct title"),
                        value: "\(gameState.timeChallengeBestScore)",
                        accent: Color(red: 1.0, green: 0.62, blue: 0.22),
                        symbol: "trophy.fill",
                        index: 1
                    )
                    introMetricCard(
                        title: localizationManager.localizedString("Wrong answer penalty"),
                        value: String(
                            format: localizationManager.localizedString("Time intro penalty seconds fmt"),
                            gameState.selectedDifficulty.timeChallengeWrongTimerSeconds,
                            localizationManager.localizedString("Time seconds unit short")
                        ),
                        accent: Color(red: 1.0, green: 0.32, blue: 0.38),
                        symbol: "minus.circle.fill",
                        index: 2
                    )
                    introMetricCard(
                        title: localizationManager.localizedString("TC intro combo5 bonus title"),
                        value: String(
                            format: localizationManager.localizedString("Time intro bonus seconds fmt"),
                            gameState.selectedDifficulty.timeChallengeCombo5BonusSeconds,
                            localizationManager.localizedString("Time seconds unit short")
                        ),
                        accent: Color(red: 0.22, green: 0.82, blue: 0.52),
                        symbol: "plus.circle.fill",
                        index: 3
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 8)

                HStack(spacing: 14) {
                    Button(action: onDismiss) {
                        Text(localizationManager.localizedString("Cancel"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(effectiveColorScheme == .dark ? Color.white.opacity(0.14) : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(effectiveColorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
                            )
                    }
                    Button(action: onStart) {
                        Text(localizationManager.localizedString("Start"))
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.48, blue: 0.18),
                                                Color(red: 0.92, green: 0.22, blue: 0.38)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.orange.opacity(0.42), radius: 16, x: 0, y: 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.88).delay(0.28), value: cardsAppeared)
            }
        }
        .onAppear {
            headerAppeared = true
            cardsAppeared = true
        }
    }

    @ViewBuilder
    private func introMetricCard(title: String, value: String, accent: Color, symbol: String, index: Int) -> some View {
        let isDark = effectiveColorScheme == .dark
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(isDark ? 0.42 : 0.28), accent.opacity(isDark ? 0.08 : 0.05)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(accent.opacity(isDark ? 0.35 : 0.45), lineWidth: 1)
                    )
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .shadow(color: Color.primary.opacity(isDark ? 0 : 0.08), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, minHeight: 148)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accent.opacity(isDark ? 0.5 : 0.4),
                                isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.12), radius: isDark ? 18 : 10, x: 0, y: isDark ? 12 : 6)
        .shadow(color: accent.opacity(isDark ? 0.18 : 0.12), radius: isDark ? 28 : 14, x: 0, y: isDark ? 16 : 8)
        .scaleEffect(cardsAppeared ? 1 : 0.93)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(
            .spring(response: 0.52, dampingFraction: 0.82)
                .delay(Double(index) * 0.068),
            value: cardsAppeared
        )
    }
}

// MARK: - Пре-старт экран Survival
struct SurvivalIntroView: View {
    @ObservedObject var gameState: GameState
    var onDismiss: () -> Void
    var onStart: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    private var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    private var introBackgroundColors: [Color] {
        if effectiveColorScheme == .dark {
            return [
                Color(red: 0.06, green: 0.03, blue: 0.05),
                Color(red: 0.12, green: 0.04, blue: 0.06),
                Color(red: 0.04, green: 0.05, blue: 0.10)
            ]
        }
        #if os(iOS)
        return [
            Color(UIColor.systemGroupedBackground),
            Color(UIColor.secondarySystemGroupedBackground),
            Color(UIColor.systemBackground)
        ]
        #else
        return [Color(white: 0.94), Color(white: 0.90), Color(white: 0.97)]
        #endif
    }

    /// Время на один ответ в Survival = лимит классики для выбранной сложности.
    private var survivalIntroPerQuestionTimerText: String {
        String(
            format: localizationManager.localizedString("Time intro duration seconds fmt"),
            Int(gameState.selectedDifficulty.timeLimit),
            localizationManager.localizedString("Time seconds unit short")
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: introBackgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    VStack(spacing: 12) {
                        Text(localizationManager.localizedString("Survival"))
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .shadow(
                                color: effectiveColorScheme == .dark ? .black.opacity(0.45) : .black.opacity(0.18),
                                radius: effectiveColorScheme == .dark ? 12 : 6,
                                x: 0,
                                y: effectiveColorScheme == .dark ? 6 : 3
                            )

                        Text(localizationManager.localizedString("Survival intro description"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 36)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 12)
                    .animation(.spring(response: 0.55, dampingFraction: 0.86), value: headerAppeared)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        spacing: 14
                    ) {
                        introMetricCard(
                            title: localizationManager.localizedString("Survival intro lives title"),
                            value: "\(GameState.survivalSessionLivesStartCount)",
                            accent: Color(red: 1.0, green: 0.35, blue: 0.38),
                            symbol: "heart.fill",
                            index: 0
                        )
                        introMetricCard(
                            title: localizationManager.localizedString("Survival intro best depth title"),
                            value: "\(gameState.survivalPersonalBestDepth)",
                            accent: Color(red: 1.0, green: 0.62, blue: 0.22),
                            symbol: "flag.fill",
                            index: 1
                        )
                        introMetricCard(
                            title: localizationManager.localizedString("Survival intro choices title"),
                            value: "\(gameState.optionsCount)",
                            accent: Color(red: 0.35, green: 0.55, blue: 1.0),
                            symbol: "square.grid.3x3.fill",
                            index: 2
                        )
                        introMetricCard(
                            title: localizationManager.localizedString("Survival intro timer title"),
                            value: survivalIntroPerQuestionTimerText,
                            accent: Color(red: 0.22, green: 0.82, blue: 0.52),
                            symbol: "timer",
                            index: 3
                        )
                    }
                    .padding(.horizontal, 20)

                    survivalWeeklyBanner
                        .padding(.horizontal, 20)

                    Color.clear.frame(height: 12)
                }
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                survivalIntroBottomBar
            }
        }
        .onAppear {
            gameState.refreshSurvivalWeeklyChallengeState()
            headerAppeared = true
            cardsAppeared = true
        }
    }

    /// Фиксированная панель, как «START GAME» на главной: контент скроллится выше.
    private var survivalIntroBottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onDismiss) {
                    Text(localizationManager.localizedString("Cancel"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(effectiveColorScheme == .dark ? Color.white.opacity(0.14) : Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(effectiveColorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
                        )
                }
                Button(action: onStart) {
                    Text(localizationManager.localizedString("Start"))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.42, blue: 0.12),
                                            Color(red: 0.88, green: 0.12, blue: 0.28)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.42), radius: 16, x: 0, y: 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.88).delay(0.28), value: cardsAppeared)
    }

    private var survivalWeeklyBanner: some View {
        let isDark = effectiveColorScheme == .dark
        let nextMilestone = gameState.survivalWeeklyNextMilestoneToShow
        return VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("Survival weekly title"))
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            if let target = nextMilestone {
                Text(String(format: localizationManager.localizedString("Survival weekly target fmt"), target))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(localizationManager.localizedString("Survival weekly all milestones met body"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(String(format: localizationManager.localizedString("Survival weekly best fmt"), gameState.survivalWeeklyBestThisWeek))
                .font(.system(size: 15, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            if gameState.survivalWeeklyAllBonusesClaimed {
                Text(localizationManager.localizedString("Survival weekly reward all claimed"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(localizationManager.localizedString("Survival weekly reward hint"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.orange.opacity(isDark ? 0.35 : 0.25), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func introMetricCard(title: String, value: String, accent: Color, symbol: String, index: Int) -> some View {
        let isDark = effectiveColorScheme == .dark
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(isDark ? 0.42 : 0.28), accent.opacity(isDark ? 0.08 : 0.05)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(accent.opacity(isDark ? 0.35 : 0.45), lineWidth: 1)
                    )
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: Color.primary.opacity(isDark ? 0 : 0.08), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, minHeight: 148)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accent.opacity(isDark ? 0.5 : 0.4),
                                isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.12), radius: isDark ? 18 : 10, x: 0, y: isDark ? 12 : 6)
        .shadow(color: accent.opacity(isDark ? 0.18 : 0.12), radius: isDark ? 28 : 14, x: 0, y: isDark ? 16 : 8)
        .scaleEffect(cardsAppeared ? 1 : 0.93)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(
            .spring(response: 0.52, dampingFraction: 0.82)
                .delay(Double(index) * 0.068),
            value: cardsAppeared
        )
    }
}

// MARK: - Анонс боя перед стартом дуэли (X vs Y, регион, сложность)
struct DuelAnnouncementView: View {
    @ObservedObject var gameState: GameState
    var onDismiss: () -> Void
    var onStart: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    private var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }
    private var isDark: Bool { effectiveColorScheme == .dark }
    private var introBackgroundColors: [Color] {
        if isDark {
            return [Color.black, Color(red: 0.12, green: 0.06, blue: 0.18), Color(red: 0.02, green: 0.06, blue: 0.12)]
        }
        #if os(iOS)
        return [
            Color(UIColor.systemGroupedBackground),
            Color(UIColor.secondarySystemGroupedBackground),
            Color(UIColor.systemBackground)
        ]
        #else
        return [Color(white: 0.94), Color(white: 0.90), Color(white: 0.97)]
        #endif
    }

    private var challengerName: String { gameState.duelChallengerName ?? "" }
    private var opponentName: String { gameState.duelOpponentName ?? "" }
    
    private var isUserChallenger: Bool { gameState.duelRoleIsChallenger }
    private var duelHistoryForMatchup: [DuelHistoryEntry] {
        let opponentKey = isUserChallenger ? opponentName : challengerName
        return gameState.duelHistory
            .filter { $0.opponentName == opponentKey }
            .sorted { $0.playedAt > $1.playedAt }
    }
    
    private var myWins: Int { duelHistoryForMatchup.filter(\.iWon).count }
    private var myLosses: Int { max(0, duelHistoryForMatchup.count - myWins) }
    
    private var user1Wins: Int { isUserChallenger ? myWins : myLosses }
    private var user2Wins: Int { isUserChallenger ? myLosses : myWins }
    private var timeLimitSeconds: Int { max(0, Int(gameState.selectedDifficulty.timeLimit)) }
    private var timeUnit: String { localizationManager.localizedString("Time seconds unit short") }
    private var questionsCount: Int { gameState.questionsPerGame }
    private var duelRegionDisplay: String {
        gameState.selectedRegions.count == 1
            ? (gameState.selectedRegions.first?.displayName ?? localizationManager.localizedString("All Regions"))
            : localizationManager.localizedString("Multiple Regions")
    }
    private var user1Title: String {
        challengerName.isEmpty ? localizationManager.localizedString("User 1") : challengerName
    }
    private var user2Title: String {
        opponentName.isEmpty ? localizationManager.localizedString("User 2") : opponentName
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: introBackgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text(localizationManager.localizedString("Duel announcement title").uppercased())
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .shadow(
                                color: isDark ? .black.opacity(0.45) : .black.opacity(0.18),
                                radius: isDark ? 12 : 6,
                                x: 0,
                                y: isDark ? 6 : 3
                            )
                        Text(localizationManager.localizedString("Duel announcement subtitle"))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(localizationManager.localizedString("Select Region")): \(duelRegionDisplay)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 36)
                    .padding(.horizontal, 24)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 12)
                    .animation(.spring(response: 0.55, dampingFraction: 0.86), value: headerAppeared)

                    duelPlayersCard
                        .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        spacing: 14
                    ) {
                        duelIntroMetricCard(
                            title: localizationManager.localizedString("Number of Questions"),
                            value: "\(questionsCount)",
                            accent: Color(red: 1.0, green: 0.62, blue: 0.22),
                            symbol: "list.bullet.rectangle.portrait",
                            index: 0
                        )
                        duelIntroMetricCard(
                            title: localizationManager.localizedString("Time Per Question"),
                            value: "\(timeLimitSeconds)\(timeUnit)",
                            accent: timeLimitSeconds < 5 ? .red : Color(red: 0.22, green: 0.82, blue: 0.52),
                            symbol: "hourglass",
                            index: 1
                        )
                        duelIntroMetricCard(
                            title: user1Title,
                            value: "\(user1Wins)",
                            accent: Color(red: 0.35, green: 0.55, blue: 1.0),
                            symbol: "trophy.fill",
                            index: 2
                        )
                        duelIntroMetricCard(
                            title: user2Title,
                            value: "\(user2Wins)",
                            accent: Color(red: 1.0, green: 0.35, blue: 0.38),
                            symbol: "trophy.fill",
                            index: 3
                        )
                    }
                    .padding(.horizontal, 20)

                    Color.clear.frame(height: 12)
                }
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                duelIntroBottomBar
            }
        }
        .onAppear {
            headerAppeared = true
            cardsAppeared = true
        }
    }

    private var duelPlayersCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(localizationManager.localizedString("User 1"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Text(challengerName)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                        Text("\(user1Wins)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
            }

            Text("⚔︎")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.orange)

            VStack(spacing: 6) {
                Text(localizationManager.localizedString("User 2"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Text(opponentName)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                        Text("\(user2Wins)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.orange.opacity(isDark ? 0.35 : 0.25), lineWidth: 1)
                )
        )
        .scaleEffect(cardsAppeared ? 1 : 0.94)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 18)
        .animation(.spring(response: 0.52, dampingFraction: 0.84).delay(0.05), value: cardsAppeared)
    }

    private var duelIntroBottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onDismiss) {
                    Text(localizationManager.localizedString("Cancel"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isDark ? Color.white.opacity(0.14) : Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(isDark ? 0.22 : 0.12), lineWidth: 1)
                        )
                }
                Button(action: onStart) {
                    Text(localizationManager.localizedString("Start duel"))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.42, blue: 0.12),
                                            Color(red: 0.88, green: 0.12, blue: 0.28)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.42), radius: 16, x: 0, y: 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.88).delay(0.28), value: cardsAppeared)
    }

    @ViewBuilder
    private func duelIntroMetricCard(title: String, value: String, accent: Color, symbol: String, index: Int) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(isDark ? 0.42 : 0.28), accent.opacity(isDark ? 0.08 : 0.05)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(accent.opacity(isDark ? 0.35 : 0.45), lineWidth: 1)
                    )
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 148)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accent.opacity(isDark ? 0.5 : 0.4),
                                isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.12), radius: isDark ? 18 : 10, x: 0, y: isDark ? 12 : 6)
        .shadow(color: accent.opacity(isDark ? 0.18 : 0.12), radius: isDark ? 28 : 14, x: 0, y: isDark ? 16 : 8)
        .scaleEffect(cardsAppeared ? 1 : 0.93)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(
            .spring(response: 0.52, dampingFraction: 0.82)
                .delay(Double(index) * 0.068),
            value: cardsAppeared
        )
    }
}

// MARK: - Баннер итога дуэли на главной (всплывающий блок, не за шторкой)
struct DuelResultBannerView: View {
    let result: DuelResultInfo
    let onDismiss: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        let isPending = result.isPending
        let yourScore = result.yourScore
        let otherScore = result.otherScore
        let challengerScoreText: String = {
            if isPending && !result.youAreChallenger { return "—" }
            return "\(result.challengerScore)"
        }()
        let opponentScoreText: String = {
            if isPending && result.youAreChallenger {
                return localizationManager.localizedString("Waiting for result")
            }
            return "\(result.opponentScore)"
        }()
        let winnerText: String = {
            if isPending {
                return "\(yourScore) : \(localizationManager.localizedString("Waiting for result"))"
            }
            if result.iWon {
                return "\(localizationManager.localizedString("You won!")) \(yourScore) : \(otherScore)"
            }
            if result.youAreChallenger {
                return "\(yourScore) : \(otherScore)"
            }
            return "\(result.challengerName) \(localizationManager.localizedString("won")) \(result.challengerScore) : \(yourScore)"
        }()
        
        let rewardTextColor: Color = result.iWon ? .green : (isPending ? .orange : .primary)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localizationManager.localizedString("Duel result"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text("\(result.challengerName): \(challengerScoreText) — \(result.opponentName): \(opponentScoreText)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(winnerText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(rewardTextColor)
            if result.showsTieTimeBreakdown,
               let ct = result.challengerTimeMs,
               let ot = result.opponentTimeMs {
                DuelTieBreakFootnote(
                    challengerName: result.challengerName,
                    opponentName: result.opponentName,
                    challengerTimeMs: ct,
                    opponentTimeMs: ot,
                    compact: true
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((result.iWon || isPending) ? Color.orange.opacity(0.4) : Color.orange.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Баннер «Неделя лиги завершена» на главной
struct LeagueWeekFinishedBannerView: View {
    let result: LeagueWeeklyResult
    let onViewResults: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isDismissing = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var isPadBannerLayout: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
        #else
        false
        #endif
    }

    private var bodyText: String {
        let rank = result.finalRank
        let leagueName = result.leagueAfter?.localizedName ?? ""
        if result.podiumPlace == 1 {
            return String(format: localizationManager.localizedString("home.league_banner.body.win"), rank)
        }
        switch result.movement {
        case "promoted":
            return String(format: localizationManager.localizedString("home.league_banner.body.promotion"), rank, leagueName)
        case "stayed":
            return String(format: localizationManager.localizedString("home.league_banner.body.stayed"), rank, leagueName)
        case "demoted":
            return String(format: localizationManager.localizedString("home.league_banner.body.demotion"), rank, leagueName)
        default:
            return String(format: localizationManager.localizedString("home.league_banner.body.stayed"), rank, leagueName)
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.35)) { isDismissing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDismiss() }
    }

    var body: some View {
        Group {
            if isPadBannerLayout {
                VStack {
                    Spacer(minLength: 0)
                    bannerCard
                    Spacer(minLength: 0)
                }
                .frame(minHeight: max(380, UIScreen.main.bounds.height * 0.42))
            } else {
                bannerCard
            }
        }
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }

    private var bannerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: isPadBannerLayout ? 32 : 26))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localizedString("home.league_banner.title"))
                        .font(.system(size: isPadBannerLayout ? 20 : 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(bodyText)
                        .font(.system(size: isPadBannerLayout ? 17 : 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                Button(action: dismissWithAnimation) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button(action: onViewResults) {
                Text(localizationManager.localizedString("home.league_banner.cta"))
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Баннер входящего вызова на дуэль (24ч)
struct IncomingDuelBannerView: View {
    let challenge: DuelChallenge
    let isAccepting: Bool
    let onAccept: () -> Void
    let onRemind: (() -> Void)?
    let onDecline: (() -> Void)?
    var onDismiss: (() -> Void)? = nil

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isDismissing = false

    private func dismissWithAnimation() {
        guard !isDismissing, let onDismiss = onDismiss else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: localizationManager.localizedString("Duel challenge from %@"), challenge.challengerName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(localizationManager.localizedString("24h to accept"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        if isAccepting {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(.white)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .opacity(0)
                                .frame(width: 14, height: 14)
                        }
                        Text(localizationManager.localizedString("Accept"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 108, minHeight: 40)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(isAccepting)
                .buttonStyle(PlainButtonStyle())

                HStack(spacing: 8) {
                    if let onRemind {
                        Button(action: onRemind) {
                            Text("\(localizationManager.localizedString("Remind")) \(localizationManager.localizedString("1 hour"))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 132, minHeight: 36)
                                .background(Color.blue.opacity(0.6))
                                .cornerRadius(10)
                        }
                        .disabled(isAccepting)
                        .buttonStyle(.plain)
                    }

                    if let onDecline {
                        Button(action: onDecline) {
                            Text(localizationManager.localizedString("Cancel"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 96, minHeight: 36)
                                .background(Color.red.opacity(0.72))
                                .cornerRadius(10)
                        }
                        .disabled(isAccepting)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if onDismiss != nil {
                Button(action: dismissWithAnimation) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }
}

// MARK: - F-Bucks chip (фишка казино с буквой F)
struct FBucksChipView: View {
    let count: Int
    enum Size { case compact, regular, hero }
    var size: Size = .compact
    /// Якщо false — без прямокутної «підкладки» (.ultraThinMaterial), лише логотип і число (наприклад, герой на екрані F-bucks).
    var showRoundedBackground: Bool = true

    private var chipDiameter: CGFloat {
        switch size {
        case .compact: return 44
        case .regular: return 64
        case .hero: return 96
        }
    }
    private var countFontSize: CGFloat {
        switch size {
        case .compact: return 14
        case .regular: return 20
        case .hero: return 34
        }
    }
    
    var body: some View {
        HStack(spacing: size == .compact ? 6 : (size == .hero ? 14 : 10)) {
            Image("FBucksLogo")
                .resizable()
                .scaledToFit()
                .frame(width: chipDiameter, height: chipDiameter)
            Text("\(count)")
                .font(.system(size: countFontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, showRoundedBackground ? (size == .compact ? 10 : (size == .hero ? 22 : 16)) : 0)
        .padding(.vertical, showRoundedBackground ? (size == .compact ? 8 : (size == .hero ? 18 : 12)) : 0)
        .background {
            if showRoundedBackground {
                RoundedRectangle(cornerRadius: size == .hero ? 22 : 12).fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Sheet «Ваши преимущества» при тапе на сердца (премиум)
struct PremiumBenefitsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let userProfile: UserProfile
    var onClose: () -> Void
    var onManageSubscription: () -> Void

    /// Иконка: сердце (lifeHeartAssetName 30×30) или SF Symbol. Тексты локализуются в body.
    private static let benefitRows: [(useHeart: Bool, sfSymbol: String?, titleKey: String, subtitleKey: String)] = [
        (true, nil, "Unlimited Hearts", "Играйте без ожидания"),
        (false, "star.fill", "Personalized Practice", "Study flags and countries"),
        (false, "text.bubble.fill", "Explain My Answer", "Analysis of your mistakes"),
        (false, "list.bullet", "Access 'My Mistakes'", "Analysis of your mistakes"),
        (false, "brain.head.profile", "Erudite Difficulty", "Advanced questions"),
    ]

    private var benefitsScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localizedString("Your Premium benefits"))
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(Self.benefitRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 12) {
                            Group {
                                if row.useHeart {
                                        Image(localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode))
                                        .resizable()
                                        .scaledToFit()
                                } else if let sf = row.sfSymbol {
                                    Image(systemName: sf)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(width: 30, height: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.localizedString(row.titleKey))
                                    .font(.subheadline.weight(.medium))
                                Text(localizationManager.localizedString(row.subtitleKey))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.body)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        if row.titleKey != Self.benefitRows.last?.titleKey {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))

                Text(localizationManager.localizedString("Up to +750% faster flag learning with Premium"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.blue.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.blue.opacity(0.2), lineWidth: 1))

                Button(action: {
                    onManageSubscription()
                    dismiss()
                }) {
                    Text(localizationManager.localizedString("Управление подпиской"))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(localizationManager.localizedString("Close")) {
                    onClose()
                    dismiss()
                }
            }
        }
    }

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack { benefitsScrollContent }
            } else {
                NavigationView { benefitsScrollContent }
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

// MARK: - Lives info bar on Home
struct LivesInfoBar: View {
    @ObservedObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.scenePhase) private var scenePhase
    var largeText: Bool = false
    @State private var showPremiumBenefits = false
    @State private var showUpgradePromo = false
    @State private var countdown: TimeInterval = 0
    @State private var timer: Timer?

    private func startCountdownTimer() {
        guard !gameState.isPremium else { return }
        countdown = gameState.timeToNextLivesRefill() ?? 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if countdown > 0 {
                    countdown -= 1
                } else {
                    gameState.refillLivesIfNeeded()
                    countdown = gameState.timeToNextLivesRefill() ?? 0
                }
            }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
    }
    
    var body: some View {
        HStack(spacing: largeText ? 12 : 8) {
            if gameState.isPremium {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: largeText ? 10 : 8) {
                        Image(localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode))
                            .resizable()
                            .scaledToFit()
                            .frame(width: largeText ? 52 : 44, height: largeText ? 52 : 44)
                        Image(systemName: "infinity")
                            .font(.system(size: largeText ? 22 : 18, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    Text(LocalizationManager.shared.localizedString("Unlimited Hearts"))
                        .font(.system(size: largeText ? 18 : 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .padding(.top, 4)
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: largeText ? 10 : 8) {
                        Image(localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode))
                            .resizable()
                            .scaledToFit()
                            .frame(width: largeText ? 60 : 44, height: largeText ? 60 : 44)
                        Text("\(gameState.lives)")
                            .font(.system(size: largeText ? 22 : 16, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                    }
                    if let remaining = (countdown > 0 ? countdown : gameState.timeToNextLivesRefill()),
                       gameState.lives < gameState.maxLives {
                        let minutes = Int(remaining) / 60
                        let seconds = Int(remaining) % 60
                        Text("+\(gameState.maxLives) \(localizationManager.localizedString("через")) \(String(format: "%02d:%02d", minutes, seconds))")
                            .font(.system(size: largeText ? 14 : 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.top, -2)
                    }
                }
            }
        }
        .padding(.horizontal, largeText ? 14 : 10)
        .padding(.vertical, largeText ? 14 : 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .onTapGesture {
            if gameState.isPremium {
                showPremiumBenefits = true
            } else {
                showUpgradePromo = true
            }
        }
        .sheetOrFullScreenOnIPad(isPresented: $showPremiumBenefits) {
            PremiumBenefitsSheetView(
                userProfile: userProfile,
                onClose: { showPremiumBenefits = false },
                onManageSubscription: {
                    showPremiumBenefits = false
                    NotificationCenter.default.post(name: NSNotification.Name("showPremiumFromHome"), object: nil)
                }
            )
        }
        .sheetOrFullScreenOnIPad(isPresented: $showUpgradePromo) {
            LivesUpgradePromoView(
                onClose: { showUpgradePromo = false },
                onGoPremium: {
                    showUpgradePromo = false
                    NotificationCenter.default.post(name: NSNotification.Name("showPremiumFromHome"), object: nil)
                }
            )
        }
        .onAppear {
            if !gameState.isPremium {
                startCountdownTimer()
            }
        }
        .onChange(of: gameState.isPremium) { isPremium in
            if isPremium {
                timer?.invalidate()
                timer = nil
            } else {
                startCountdownTimer()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            guard !gameState.isPremium else { return }
            switch newPhase {
            case .active:
                // После возврата из другого приложения сразу пересчитываем остаток,
                // чтобы таймер на главной не "зависал".
                gameState.refillLivesIfNeeded()
                startCountdownTimer()
            case .inactive, .background:
                timer?.invalidate()
                timer = nil
            @unknown default:
                break
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct LivesUpgradePromoView: View {
    let onClose: () -> Void
    let onGoPremium: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.22),
                        Color.purple.opacity(0.20),
                        Color.orange.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 8) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 52))
                            Text(localizationManager.localizedString("Unlock your full progress"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(localizationManager.localizedString("Get Premium tools for faster learning and better game results"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.top, 8)

                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.green)
                            Text(localizationManager.localizedString("Up to +750% faster flag learning with Premium"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.12))
                        )

                        VStack(spacing: 12) {
                            PromoFeatureRow(
                                icon: "heart.fill",
                                iconImageName: localizationManager.lifeHeartAssetName(forCountryCode: UserProfile.shared.selectedCountryCode),
                                color: .red,
                                title: localizationManager.localizedString("Unlimited Hearts"),
                                subtitle: localizationManager.localizedString("Play without waiting and keep your learning momentum")
                            )
                            PromoFeatureRow(
                                icon: "book.fill",
                                color: .blue,
                                title: localizationManager.localizedString("Learning section"),
                                subtitle: localizationManager.localizedString("Train flags, listen to anthems, and explore detailed country profiles")
                            )
                            PromoFeatureRow(
                                icon: "brain.head.profile",
                                color: .purple,
                                title: localizationManager.localizedString("Erudite difficulty"),
                                subtitle: localizationManager.localizedString("Advanced challenge with deeper knowledge checks")
                            )
                            PromoFeatureRow(
                                icon: "exclamationmark.bubble.fill",
                                color: .orange,
                                title: localizationManager.localizedString("My mistakes"),
                                subtitle: localizationManager.localizedString("Focus on weak topics and improve accuracy")
                            )
                            PromoFeatureRow(
                                icon: "sparkles",
                                color: .green,
                                title: localizationManager.localizedString("Personalized practice"),
                                subtitle: localizationManager.localizedString("Adaptive sessions based on your progress")
                            )
                            PromoFeatureRow(
                                icon: "text.bubble.fill",
                                color: .indigo,
                                title: localizationManager.localizedString("Explain my answer"),
                                subtitle: localizationManager.localizedString("Understand every mistake and learn faster")
                            )
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                        )

                        Button(action: onGoPremium) {
                            HStack(spacing: 10) {
                                Image(systemName: "crown.fill")
                                Text(localizationManager.localizedString("Go Premium"))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.35), radius: 10, x: 0, y: 6)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString("Close")) { onClose() }
                }
            }
        }
    }
}

private struct PromoFeatureRow: View {
    let icon: String
    var iconImageName: String? = nil
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let name = iconImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 34, height: 34)
            .background(iconImageName != nil ? Color.clear : color)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

// Контейнер, который отдаёт все касания слайдеру (чтобы ScrollView не забирал перетаскивание)
#if os(iOS)
private final class SliderContainerView: UIView {
    weak var sliderView: UISlider?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let slider = sliderView, bounds.contains(point) else { return nil }
        let pt = convert(point, to: slider)
        return slider.hitTest(pt, with: event) ?? slider
    }
}
#endif

// Слайдер сложности — только перетаскивание (без тапа по треку)
struct TappableDifficultySlider: UIViewRepresentable {
    @Binding var value: Double
    let maxValue: Double
    let onValueChanged: () -> Void
    let onInteractionChanged: (Bool) -> Void

    func makeUIView(context: Context) -> UIView {
        #if os(iOS)
        let container = SliderContainerView()
        #else
        let container = UIView()
        #endif
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = true

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4
        slider.isUserInteractionEnabled = true
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderChanged), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderTouchBegan), for: .touchDown)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderTouchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.sliderTapped(_:)))
        tap.cancelsTouchesInView = false
        slider.addGestureRecognizer(tap)
        slider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(slider)
        let heightConstraint = container.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            heightConstraint,
        ])
        context.coordinator.slider = slider
        #if os(iOS)
        container.sliderView = slider
        #endif
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let slider = context.coordinator.slider else { return }
        let newVal = Float(value)
        // Не перезаписываем значение во время перетаскивания — только при заметном расхождении (смена снаружи)
        if abs(slider.value - newVal) > 0.5 {
            slider.value = newVal
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            value: $value,
            maxValue: maxValue,
            onValueChanged: onValueChanged,
            onInteractionChanged: onInteractionChanged
        )
    }

    class Coordinator: NSObject {
        @Binding var value: Double
        let maxValue: Double
        let onValueChanged: () -> Void
        let onInteractionChanged: (Bool) -> Void
        weak var slider: UISlider?

        init(
            value: Binding<Double>,
            maxValue: Double,
            onValueChanged: @escaping () -> Void,
            onInteractionChanged: @escaping (Bool) -> Void
        ) {
            _value = value
            self.maxValue = maxValue
            self.onValueChanged = onValueChanged
            self.onInteractionChanged = onInteractionChanged
        }

        @objc func sliderChanged() {
            guard let s = slider else { return }
            value = Double(s.value)
            onValueChanged()
        }

        @objc func sliderTouchBegan() {
            onInteractionChanged(true)
            setParentScrollEnabled(false)
        }

        @objc func sliderTouchEnded() {
            onInteractionChanged(false)
            setParentScrollEnabled(true)
        }

        @objc func sliderTapped(_ recognizer: UITapGestureRecognizer) {
            guard let s = slider else { return }
            let location = recognizer.location(in: s)
            guard s.bounds.width > 0 else { return }

            let percent = min(max(location.x / s.bounds.width, 0), 1)
            let newValue = s.minimumValue + Float(percent) * (s.maximumValue - s.minimumValue)
            s.setValue(newValue, animated: true)
            value = Double(newValue)
            onValueChanged()
        }

        private func setParentScrollEnabled(_ enabled: Bool) {
            #if os(iOS)
            var view = slider?.superview
            while let current = view {
                if let scroll = current as? UIScrollView {
                    scroll.isScrollEnabled = enabled
                    break
                }
                view = current.superview
            }
            #endif
        }
    }
}

// Компонент для выбора сложности с слайдером
struct DifficultySelectionView: View {
    @ObservedObject var gameState: GameState
    var compact: Bool = false
    var phoneCompact: Bool = false
    /// Крупный шрифт названия уровня и описания на iPad (портрет и ландшафт)
    var largeFontForIPad: Bool = false
    @Binding var isInteracting: Bool
    @State private var sliderValue: Double = 2.0 // Средняя сложность по умолчанию
    @State private var availableCountriesCount: Int = 0
    @State private var lastSelectedIndex: Int = 2
    
    private var difficulties: [GameState.Difficulty] {
        return GameState.Difficulty.allCases
    }
    
    private var currentDifficulty: GameState.Difficulty {
        let index = Int(sliderValue.rounded())
        return difficulties[min(max(index, 0), difficulties.count - 1)]
    }

    private var currentIndex: Int {
        min(max(Int(sliderValue.rounded()), 0), difficulties.count - 1)
    }

    private var useCompactLayout: Bool {
        compact || phoneCompact
    }
    
    /// Блок с названием уровня и описанием (крупный шрифт на iPad или в compact)
    private var difficultyLabelBlock: some View {
        let useLarge = compact || largeFontForIPad
        return VStack(spacing: useCompactLayout ? 3 : 4) {
            HStack(spacing: 8) {
                Image(systemName: currentDifficulty.systemImage)
                    .font(.system(size: useLarge ? 20 : 16))
                    .foregroundColor(currentDifficulty.iconColor)
                Text(currentDifficulty.displayName)
                    .font(.system(size: useLarge ? 22 : 16, weight: .bold))
                    .foregroundColor(.primary)
                if currentDifficulty == .erudite && !gameState.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: useLarge ? 16 : 12))
                        .foregroundColor(.orange)
                }
            }
            Text(getDifficultyDescription(currentDifficulty))
                .font(.system(size: useLarge ? 15 : 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, useCompactLayout ? 8 : 8)
        .padding(.vertical, useCompactLayout ? 6 : 12)
        .background(
            RoundedRectangle(cornerRadius: useCompactLayout ? 10 : 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: useCompactLayout ? 10 : 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func applySliderChange() {
        let snappedIndex = currentIndex
        if lastSelectedIndex != snappedIndex {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            lastSelectedIndex = snappedIndex
        }
        let newDifficulty = difficulties[snappedIndex]
        if gameState.selectedDifficulty != newDifficulty {
            gameState.selectedDifficulty = newDifficulty
        }
    }

    private func sliderWithTap(horizontalPadding: CGFloat = 0) -> some View {
        let maxVal = Double(difficulties.count - 1)
        return VStack(spacing: useCompactLayout ? 7 : 10) {
            TappableDifficultySlider(
                value: $sliderValue,
                maxValue: maxVal,
                onValueChanged: applySliderChange,
                onInteractionChanged: { isInteracting = $0 }
            )
            .frame(height: useCompactLayout ? 40 : 46)
            .padding(.horizontal, horizontalPadding)
        }
        .padding(.top, useCompactLayout ? 1 : 3)
        .padding(.bottom, compact ? 1 : 1)
    }

    var body: some View {
        Group {
            if compact {
                // iPad landscape: слайдер слева, значение уровня справа крупно
                HStack(alignment: .center, spacing: 16) {
                    sliderWithTap(horizontalPadding: 0)
                    difficultyLabelBlock
                        .frame(minWidth: 140)
                }
                .padding(.horizontal, 8)
            } else {
                VStack(spacing: useCompactLayout ? 6 : 8) {
                    sliderWithTap(horizontalPadding: useCompactLayout ? 12 : 20)
                    difficultyLabelBlock
                }
            }
        }
        .onAppear {
            // Устанавливаем слайдер в позицию текущей сложности
            if let index = difficulties.firstIndex(of: gameState.selectedDifficulty) {
                sliderValue = Double(index)
                lastSelectedIndex = index
            }
            updateCountriesCount()
        }
        .onChange(of: gameState.selectedRegions) { _ in
            updateCountriesCount()
        }
        .onChange(of: gameState.selectedDifficulty) { newValue in
            if let index = difficulties.firstIndex(of: newValue) {
                sliderValue = Double(index)
                lastSelectedIndex = index
            }
        }
    }
    
    private func updateCountriesCount() {
        Task {
            let count = await gameState.getCountriesCountInSelectedRegions()
            await MainActor.run {
                availableCountriesCount = count
            }
        }
    }
    
    private func getDifficultyDescription(_ difficulty: GameState.Difficulty) -> String {
        if gameState.selectedPlayMode == .timeChallenge {
            let dur = Int(difficulty.timeChallengeDuration)
            let add = difficulty.timeChallengeCombo5BonusSeconds
            let sub = difficulty.timeChallengeWrongTimerSeconds
            let unit = LocalizationManager.shared.localizedString("Time seconds unit short")
            if difficulty == .erudite {
                if gameState.selectedRegions.contains(.all) {
                    return String(
                        format: LocalizationManager.shared.localizedString("Difficulty TC erudite all"),
                        dur,
                        unit,
                        add,
                        sub
                    )
                }
                let count = max(0, availableCountriesCount)
                return String(
                    format: LocalizationManager.shared.localizedString("Difficulty TC erudite regions"),
                    count,
                    dur,
                    unit,
                    add,
                    sub
                )
            }
            return difficulty.description(for: .timeChallenge)
        }
        if difficulty == .erudite {
            if gameState.selectedRegions.contains(.all) {
                return LocalizationManager.shared.localizedString("All 238 countries of the world, 5 sec per answer")
            } else {
                let count = availableCountriesCount > 0 ? availableCountriesCount : 0
                return String(format: LocalizationManager.shared.localizedString("All %d countries of selected regions, 5 sec per answer"), count)
            }
        } else {
            return difficulty.description
        }
    }
}

// MARK: - Birthday banner (главный экран: свой ДР или день рождения друга)
private struct BirthdayBannerView: View {
    @ObservedObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isHidden: Bool = false
    @State private var isDismissing = false

    private func dismissWithAnimation() {
        guard !isDismissing else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isHidden = true
        }
    }

    var body: some View {
        Group {
            if !isHidden {
                if userProfile.birthday != nil && userProfile.isTodayBirthday(userProfile.birthday!) {
                    myBirthdayBanner
                } else if let first = userProfile.friendsWithBirthdayToday.first {
                    friendBirthdayBanner(friend: first, total: userProfile.friendsWithBirthdayToday.count)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHidden)
    }

    private var myBirthdayBanner: some View {
        let currentYear = Calendar.current.component(.year, from: Date())
        let claimedThisYear = userProfile.birthdayBonusClaimedYear == currentYear
        let justAwarded = userProfile.birthdayBonusJustAwarded && claimedThisYear

        return HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.localizedString("С днём рождения!"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(justAwarded
                     ? localizationManager.localizedString("Birthday bonus F-bucks message")
                     : localizationManager.localizedString("Birthday bonus already claimed"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: dismissWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
        .onAppear {
            if userProfile.birthdayBonusJustAwarded {
                userProfile.birthdayBonusJustAwarded = false
            }
        }
    }

    private func friendBirthdayBanner(friend: Friend, total: Int) -> some View {
        let title = total > 1
            ? String(format: localizationManager.localizedString("Friends birthday today count"), total)
            : String(format: localizationManager.localizedString("Friend birthday today"), friend.displayNameOrUsername)
        return HStack(spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 24))
                .foregroundColor(.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(localizationManager.localizedString("Friend birthday congratulate hint"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: dismissWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.pink.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -40 { dismissWithAnimation() }
                }
        )
        .offset(x: isDismissing ? -UIScreen.main.bounds.width : 0)
        .opacity(isDismissing ? 0 : 1)
    }
}

// ScaleButtonStyle уже определен в StartView.swift

#Preview {
    ContentView(gameState: GameState())
}