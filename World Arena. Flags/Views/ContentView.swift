import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var themeManager = AppThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return horizontalSizeClass == .regular
        #endif
    }
    
    private func isLandscapeIPad(_ width: CGFloat, _ height: CGFloat) -> Bool {
        isIPad && width > height
    }

    private var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }
    
    // Animation states
    @State private var showContent = false
    @State private var pendingPremiumAlert = false
    @State private var showPremiumSheet = false
    @State private var eruditePremiumAlert = false
    @State private var showDuelOpponentPicker = false
    @State private var showFBucksInfo = false
    @State private var isAcceptingIncomingDuel = false
    @State private var isDifficultySliderInteracting = false
    @State private var firstLaunchDate: Date = Date()
    @State private var onboardingNow: Date = Date()
    @State private var cityLeaderboardPercentile: Int = 72

    private static let duelExpiryHours: TimeInterval = 24
    private static let firstRunWindowSeconds: TimeInterval = 180
    private static let firstLaunchDateKey = "onboarding.firstLaunchDate.v1"
    private static let firstRunPercentileKey = "onboarding.cityPercentile.v1"

    private var firstRunRemainingSeconds: Int {
        let spent = onboardingNow.timeIntervalSince(firstLaunchDate)
        return max(0, Int(Self.firstRunWindowSeconds - spent))
    }

    private var shouldShowFirstRunMotivation: Bool {
        firstRunRemainingSeconds > 0
    }
    private var pendingIncomingDuel: DuelChallenge? {
        userProfile.incomingDuelChallenges.first { c in
            c.status == .pending && Date().timeIntervalSince(c.createdAt) < Self.duelExpiryHours
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
                        } else {
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
                        }

                        ScrollView {
                            VStack(spacing: compactPhone ? 10 : 14) {
                                if (userProfile.birthday != nil && userProfile.isTodayBirthday(userProfile.birthday!)) || !userProfile.friendsWithBirthdayToday.isEmpty {
                                    BirthdayBannerView(userProfile: userProfile)
                                        .padding(.horizontal, 20)
                                }

                                if shouldShowFirstRunMotivation {
                                    FirstRunMotivationCardView(
                                        percentile: cityLeaderboardPercentile,
                                        secondsLeft: firstRunRemainingSeconds
                                    )
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
                            
                            // Выбор сложности (на iPad landscape — компактнее)
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
                            
                            // Режим игры
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

                            // Входящий вызов на дуэль (24ч)
                            if let duel = pendingIncomingDuel {
                                IncomingDuelBannerView(
                                    challenge: duel,
                                    isAccepting: isAcceptingIncomingDuel,
                                    onAccept: { acceptIncomingDuel(duel) }
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .opacity(showContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.85), value: showContent)
                            }

                            // Кнопка запуска игры
                            Button(action: {
                                if !gameState.isStartingNewGame {
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
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                    impactFeedback.impactOccurred()
                                    Task {
                                        await gameState.startNewGameWithCurrentRegions()
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if gameState.isStartingNewGame || gameState.isPreloadingFlags {
                                        VStack(spacing: 4) {
                                            HStack(spacing: 8) {
                                                if gameState.isPreloadingFlags {
                                                    // Круговой прогресс для загрузки флагов
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
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 50)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
                        }
                        .padding(.bottom, compactPhone ? 8 : 20)
                    }
                    }
                }
            }
            .modifier(PremiumPresentationModifier(showPremium: $showPremiumSheet, gameState: gameState))
            .alert(isPresented: $pendingPremiumAlert) {
                Alert(
                    title: Text(localizationManager.localizedString("No lives available")),
                    message: Text(localizationManager.localizedString("Unfortunately, the game is not available now: you have no lives. You can buy lives or go Premium.")),
                    primaryButton: .default(Text(localizationManager.localizedString("Go Premium"))) {
                        showPremiumSheet = true
                    },
                    secondaryButton: .cancel(Text(localizationManager.localizedString("Close")))
                )
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
            .sheet(isPresented: $showDuelOpponentPicker) {
                DuelOpponentPickerView(gameState: gameState)
                    .environmentObject(userProfile)
            }
            .sheet(isPresented: $showFBucksInfo) {
                FBucksInfoView()
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
                gameState.updateOptionsCount(isIPad: horizontalSizeClass == .regular)
                setupFirstRunMotivation()
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                Task { await refreshIncomingDuelChallenges() }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
                onboardingNow = date
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            for c in newOnes {
                NotificationService.shared.scheduleDuelChallengeNotification(from: c.challengerName)
            }
        }
    }

    private func acceptIncomingDuel(_ challenge: DuelChallenge) {
        guard isAcceptingIncomingDuel == false, gameState.canStartGameWithLives() else { return }
        isAcceptingIncomingDuel = true
        Task {
            defer { Task { @MainActor in isAcceptingIncomingDuel = false } }
            guard let result = try? await DuelAPIService.shared.acceptChallenge(challengeId: challenge.id) else { return }
            await MainActor.run {
                gameState.selectedPlayMode = .duel
                gameState.duelSeed = result.seed
                gameState.duelChallengeId = challenge.id
                gameState.duelOpponentId = challenge.challengerId
                gameState.duelOpponentName = result.challengerName
                gameState.duelChallengerName = result.challengerName
            }
            await gameState.startNewGameWithCurrentRegions()
        }
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

struct FirstRunMotivationCardView: View {
    let percentile: Int
    let secondsLeft: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: localizationManager.localizedString("You already outranked %d%% of players in your city"), percentile))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(localizationManager.localizedString("Goal: keep 90% accuracy in first challenge"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
            Text(String(format: localizationManager.localizedString("Challenge ends in %d sec"), secondsLeft))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
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
    }
}

// MARK: - Баннер входящего вызова на дуэль (24ч)
struct IncomingDuelBannerView: View {
    let challenge: DuelChallenge
    let isAccepting: Bool
    let onAccept: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Text("⚔️")
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
            Button(action: onAccept) {
                Group {
                    if isAccepting {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Text(localizationManager.localizedString("Accept"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(minWidth: 88, minHeight: 40)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isAccepting)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.blue.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - F-Bucks chip (фишка казино с буквой F)
struct FBucksChipView: View {
    let count: Int
    enum Size { case compact, regular }
    var size: Size = .compact
    
    private var chipDiameter: CGFloat { size == .compact ? 44 : 64 }
    private var countFontSize: CGFloat { size == .compact ? 14 : 20 }
    
    var body: some View {
        HStack(spacing: size == .compact ? 6 : 10) {
            Image("FBucksLogo")
                .resizable()
                .scaledToFit()
                .frame(width: chipDiameter, height: chipDiameter)
            Text("\(count)")
                .font(.system(size: countFontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, size == .compact ? 10 : 16)
        .padding(.vertical, size == .compact ? 8 : 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
    }
}

// MARK: - Lives info bar on Home
struct LivesInfoBar: View {
    @ObservedObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    var largeText: Bool = false
    @State private var showTooltip = false
    @State private var showUpgradePromo = false
    @State private var countdown: TimeInterval = 0
    @State private var timer: Timer?

    private func startCountdownTimer() {
        guard !gameState.isPremium else { return }
        countdown = gameState.timeToNextLivesRefill() ?? 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                gameState.refillLivesIfNeeded()
                countdown = gameState.timeToNextLivesRefill() ?? 0
            }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if gameState.isPremium {
                ZStack {
                    Image(localizationManager.lifeHeartAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: largeText ? 72 : 60, height: largeText ? 72 : 60)
                    Image(systemName: "infinity")
                        .font(.system(size: largeText ? 20 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: 0.5)
                }
                Text(LocalizationManager.shared.localizedString("Unlimited Hearts"))
                    .font(.system(size: largeText ? 20 : 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.primary)
                Spacer()
            } else {
                Image(localizationManager.lifeHeartAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: largeText ? 60 : 48, height: largeText ? 60 : 48)
                Text("\(LocalizationManager.shared.localizedString("Lives")): \(String(gameState.lives))")
                    .font(.system(size: largeText ? 20 : 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if let remaining = (countdown > 0 ? countdown : gameState.timeToNextLivesRefill()) {
                    let minutes = Int(remaining) / 60
                    let seconds = Int(remaining) % 60
                    Text(String(format: LocalizationManager.shared.localizedString("Next +%d in %02d:%02d"), gameState.maxLives, minutes, seconds))
                        .font(.system(size: largeText ? 14 : 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(largeText ? 14 : 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .onTapGesture {
            if gameState.isPremium {
                showTooltip.toggle()
            } else {
                showUpgradePromo = true
            }
        }
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 12) {
                if gameState.isPremium {
                    Text(LocalizationManager.shared.localizedString("Your Premium benefits"))
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Label(LocalizationManager.shared.localizedString("Unlimited Hearts"), image: LocalizationManager.shared.lifeHeartAssetName)
                            .font(.subheadline)
                        Label(LocalizationManager.shared.localizedString("Personalized Practice"), systemImage: "star.fill")
                            .font(.subheadline)
                        Label(LocalizationManager.shared.localizedString("Explain My Answer"), systemImage: "text.bubble.fill")
                            .font(.subheadline)
                        Label(LocalizationManager.shared.localizedString("Access 'My Mistakes'"), systemImage: "list.bullet")
                            .font(.subheadline)
                        Label(LocalizationManager.shared.localizedString("Erudite Difficulty"), systemImage: "brain.head.profile")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                    Button(LocalizationManager.shared.localizedString("Управление подпиской")) {
                        showTooltip = false
                        NotificationCenter.default.post(name: NSNotification.Name("showPremiumFromHome"), object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(minWidth: 260)
        }
        .sheet(isPresented: $showUpgradePromo) {
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

private struct LivesUpgradePromoView: View {
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
                            Text("🚀")
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
                                iconImageName: localizationManager.lifeHeartAssetName,
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
        if let box = container as? SliderContainerView {
            box.sliderView = slider
        }
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
            HStack(spacing: 4) {
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
        if difficulty == .erudite {
            // Для эрудита - все вопросы по выбранным регионам
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
            Button(action: { isHidden = true }) {
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
                    if value.translation.width < -40 {
                        isHidden = true
                    }
                }
        )
        .onAppear {
            // После показа считаем, что «только что начислено» уже донесли до пользователя
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
    }
}

// ScaleButtonStyle уже определен в StartView.swift

#Preview {
    ContentView(gameState: GameState())
}