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
    
    // Animation states
    @State private var showContent = false
    @State private var pendingPremiumAlert = false
    @State private var showPremiumSheet = false
    @State private var eruditePremiumAlert = false
    @State private var showDuelOpponentPicker = false
    @State private var showFBucksInfo = false
    @State private var isAcceptingIncomingDuel = false
    @State private var isDifficultySliderInteracting = false

    private static let duelExpiryHours: TimeInterval = 24
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
                    
                    VStack(spacing: 0) {
                        if landscapeIPad {
                            // iPad горизонтально: крупный логотип по центру, жизни слева и F-Bucks справа
                            ZStack(alignment: .center) {
                                HStack(alignment: .center, spacing: 16) {
                                    LivesInfoBar(gameState: gameState)
                                    Spacer(minLength: 8)
                                    Button(action: { showFBucksInfo = true }) {
                                        FBucksChipView(count: userProfile.fBucks, size: .compact)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                                VStack(spacing: 6) {
                                    Text("World Arena Flags")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: Color.appTextGradient(for: themeManager.colorScheme),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Learn flags and countries of the World")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
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
                                            colors: Color.appTextGradient(for: themeManager.colorScheme),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: themeManager.colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.3), radius: themeManager.colorScheme == .dark ? 6 : 4, x: 0, y: 2)
                                Text("Learn flags and countries of the World")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                            HStack(alignment: .center, spacing: 10) {
                                LivesInfoBar(gameState: gameState)
                                Button(action: {
                                    showFBucksInfo = true
                                }) {
                                    FBucksChipView(count: userProfile.fBucks, size: .compact)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 6)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                        }

                        ScrollView {
                            VStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizationManager.localizedString("Select Region"))
                                        .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 20)
                                    RegionSelectionView(gameState: gameState, columnCount: landscapeIPad ? 3 : 2, compact: landscapeIPad, largeFontForLandscape: isIPad)
                                }
                            .padding(.vertical, 8)
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
                                Text("Select Level")
                                    .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                
                                DifficultySelectionView(
                                    gameState: gameState,
                                    compact: landscapeIPad,
                                    largeFontForIPad: isIPad,
                                    isInteracting: $isDifficultySliderInteracting
                                )
                            }
                            .padding(.vertical, landscapeIPad ? 2 : 4)
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
                                
                                GameModeSelectionView(gameState: gameState, largeFontForLandscape: isIPad)
                            }
                            .padding(.vertical, 8)
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
                                .frame(height: isIPad ? 76 : 52)
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
                        .padding(.bottom, 20)
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
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                Task { await refreshIncomingDuelChallenges() }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var chipDiameter: CGFloat { size == .compact ? 44 : 56 }
    private var fontSize: CGFloat { size == .compact ? 18 : 24 }
    private var countFontSize: CGFloat { size == .compact ? 14 : 16 }
    
    var body: some View {
        HStack(spacing: size == .compact ? 6 : 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.2),
                                Color(red: 0.7, green: 0.5, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: chipDiameter, height: chipDiameter)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.8, blue: 0.35),
                                        Color(red: 0.55, green: 0.4, blue: 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: size == .compact ? 2.5 : 3
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 2)
                Text("F")
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 0.5, x: 0, y: 1)
            }
            Text("\(count)")
                .font(.system(size: countFontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, size == .compact ? 10 : 14)
        .padding(.vertical, size == .compact ? 8 : 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
    }
}

// MARK: - Lives info bar on Home
struct LivesInfoBar: View {
    @ObservedObject var gameState: GameState
    @State private var showTooltip = false
    @State private var countdown: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            if gameState.isPremium {
                ZStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.title2)
                        .foregroundColor(.pink)
                    Image(systemName: "infinity")
                        .font(.caption)
                        .foregroundColor(.white)
                        .offset(y: 0.5)
                }
                Text(LocalizationManager.shared.localizedString("Unlimited Hearts"))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.primary)
                Spacer()
            } else {
                // Для обычных пользователей: ограничиваем размер шрифта, чтобы при увеличенном тексте шапка не занимала весь экран и кнопка «ПОЧАТИ ГРУ» помещалась
                Image(systemName: "heart.fill").foregroundColor(.red)
                Text("\(LocalizationManager.shared.localizedString("Lives")): \(String(gameState.lives))")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if let remaining = (countdown > 0 ? countdown : gameState.timeToNextLivesRefill()) {
                    let minutes = Int(remaining) / 60
                    let seconds = Int(remaining) % 60
                    Text(String(format: LocalizationManager.shared.localizedString("Next +%d in %02d:%02d"), gameState.maxLives, minutes, seconds))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .onTapGesture { showTooltip.toggle() }
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 12) {
                if gameState.isPremium {
                    Text(LocalizationManager.shared.localizedString("Your Premium benefits"))
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Label(LocalizationManager.shared.localizedString("Unlimited Hearts"), systemImage: "heart.fill")
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
                } else {
                    Text(LocalizationManager.shared.localizedString("Lives refill info"))
                        .font(.headline)
                    if let remaining = (countdown > 0 ? countdown : gameState.timeToNextLivesRefill()) {
                        let minutes = Int(remaining) / 60
                        let seconds = Int(remaining) % 60
                        Text(String(format: LocalizationManager.shared.localizedString("You will receive +%d new lives in %02d:%02d"), gameState.maxLives, minutes, seconds))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Button(LocalizationManager.shared.localizedString("Go Premium")) {
                        showTooltip = false
                        NotificationCenter.default.post(name: NSNotification.Name("showPremiumFromHome"), object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(minWidth: 260)
        }
        .onAppear {
            if !gameState.isPremium {
                // Инициализируем текущее значение и запускаем тикающий таймер раз в секунду
                countdown = gameState.timeToNextLivesRefill() ?? 0
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if countdown > 0 {
                        countdown -= 1
                    } else {
                        countdown = gameState.timeToNextLivesRefill() ?? 0
                    }
                }
                if let t = timer { RunLoop.main.add(t, forMode: .common) }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
    
    /// Блок с названием уровня и описанием (крупный шрифт на iPad или в compact)
    private var difficultyLabelBlock: some View {
        let useLarge = compact || largeFontForIPad
        return VStack(spacing: compact ? 4 : 4) {
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
        .padding(.horizontal, compact ? 10 : 8)
        .padding(.vertical, compact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 10 : 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 10 : 12)
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
        return VStack(spacing: compact ? 8 : 10) {
            TappableDifficultySlider(
                value: $sliderValue,
                maxValue: maxVal,
                onValueChanged: applySliderChange,
                onInteractionChanged: { isInteracting = $0 }
            )
            .frame(height: compact ? 42 : 46)
            .padding(.horizontal, horizontalPadding)
        }
        .padding(.top, compact ? 4 : 6)
        .padding(.bottom, compact ? 2 : 3)
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
                VStack(spacing: 16) {
                    sliderWithTap(horizontalPadding: 20)
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

// ScaleButtonStyle уже определен в StartView.swift

#Preview {
    ContentView(gameState: GameState())
}