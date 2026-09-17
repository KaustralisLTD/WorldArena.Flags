import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Вариант главного экрана «быстрый старт» (A/B с классической разметкой). Переключение: `UserDefaults` + Настройки.
enum GameHomeLayoutVariant: Int, CaseIterable, Identifiable {
    case classic = 1
    case quickStart = 2

    var id: Int { rawValue }

    static let storageKey = "gameHome.layoutVariant.v1"

    @MainActor
    var title: String {
        switch self {
        case .classic:
            // legacy home
            return LocalizationManager.shared.localizedString("home.layout.variant2")
        case .quickStart:
            // new home
            return LocalizationManager.shared.localizedString("home.layout.classic")
        }
    }
}

// MARK: - Quick home shared progress / sticky copy

@MainActor
private enum QuickHomeUX {
    static func perfectProgress(userProfile: UserProfile) -> (Int, Int) {
        if let q = userProfile.monthlyQuests.first(where: { $0.questType == .perfectGames }) {
            return (q.currentValue, q.targetValue)
        }
        return (0, 10)
    }

    static func streakProgress(userProfile: UserProfile) -> (Int, Int) {
        if let q = userProfile.monthlyQuests.first(where: { $0.questType == .streak }) {
            // Реальная серия сразу, без ожидания обновления квеста после первой игры.
            return (min(q.targetValue, userProfile.streak), q.targetValue)
        }
        return (min(userProfile.streak, 10), 10)
    }

    static func stickyHookSubtitle(userProfile: UserProfile, loc: LocalizationManager) -> String {
        let (ps, pt) = perfectProgress(userProfile: userProfile)
        let (ss, st) = streakProgress(userProfile: userProfile)
        func tr(_ key: String, fallback: String) -> String {
            let value = loc.localizedString(key)
            return value == key ? loc.localizedString(fallback) : value
        }
        if userProfile.canClaimDailyFBucksBonus() {
            return tr("home.sticky.hook.reward", fallback: "home.hero.play_bonus")
        }
        if ss < st {
            if ss > 0 {
                return tr("home.sticky.hook.streak", fallback: "home.streak_nudge.solo_sub")
            }
            return tr("home.sticky.hook.reward", fallback: "home.hero.play_bonus")
        }
        if ps < pt {
            return tr("home.sticky.hook.reward", fallback: "home.hero.play_bonus")
        }
        return tr("home.sticky.hook.play", fallback: "home.hero.headline.keep_playing")
    }
}

// MARK: - Sticky CONTINUE (variant 2)

struct GameHomeStickyContinueView: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    var compactPhone: Bool
    var isIPad: Bool
    var showContent: Bool
    var onContinue: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var pulse: CGFloat = 1

    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0, green: 122 / 255, blue: 1),
                Color(red: 106 / 255, green: 92 / 255, blue: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        #if os(iOS)
        let constrainStickyWidth = isIPad && UIDevice.current.userInterfaceIdiom == .pad
        #else
        let constrainStickyWidth = false
        #endif
        let hook = QuickHomeUX.stickyHookSubtitle(userProfile: userProfile, loc: localizationManager)
        VStack(spacing: 6) {
            HStack {
                Spacer(minLength: 0)
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        if gameState.isStartingNewGame || gameState.isPreloadingFlags {
                            ProgressView()
                                .tint(.white)
                            Text(
                                gameState.isPreloadingFlags
                                    ? localizationManager.localizedString("Loading flags...")
                                    : localizationManager.localizedString("Starting...")
                            )
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text(localizationManager.localizedString("home.continue"))
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                        }
                    }
                    .frame(maxWidth: constrainStickyWidth ? 620 : .infinity)
                    .frame(height: isIPad ? 64 : (compactPhone ? 58 : 62))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(primaryGradient)
                            .shadow(color: Color(red: 0, green: 122 / 255, blue: 1).opacity(0.55), radius: 22, x: 0, y: 10)
                            .shadow(color: Color(red: 106 / 255, green: 92 / 255, blue: 1).opacity(0.35), radius: 14, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(gameState.selectedRegions.isEmpty || gameState.isStartingNewGame || gameState.isPreloadingFlags)
                .scaleEffect(pulse)
                Spacer(minLength: 0)
            }
            if !gameState.isStartingNewGame, !gameState.isPreloadingFlags {
                Text(hook)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 14)
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: showContent)
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            guard !gameState.isStartingNewGame, !gameState.isPreloadingFlags else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55)) {
                pulse = 1.03
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    pulse = 1
                }
            }
        }
    }
}

// MARK: - Quick home (variant 2)

private struct QuickHomeLivesPillView: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var isDark: Bool
    /// Как `LivesInfoBar.largeText`: крупное число жизней на iPad.
    var largeText: Bool = false
    @State private var countdown: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showPremiumBenefits = false
    @State private var showUpgradePromo = false

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

    private var pillFill: Color {
        if isDark {
            #if os(iOS)
            return Color(UIColor.secondarySystemGroupedBackground)
            #else
            return Color(NSColor.controlBackgroundColor)
            #endif
        }
        return Color.white
    }

    var body: some View {
        Group {
            if gameState.isPremium {
                // Как у не‑Premium с таймером «+5 через …»: первая строка — только иконки, подпись ниже
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Image(systemName: "infinity")
                            .font(.system(size: largeText ? 20 : 18, weight: .bold))
                            .foregroundColor(.primary)
                        if largeText {
                            Spacer(minLength: 0)
                        }
                    }
                    Text(localizationManager.localizedString("Unlimited Hearts"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(Capsule().fill(pillFill))
                .shadow(color: Color.black.opacity(isDark ? 0.28 : 0.08), radius: 16, x: 0, y: 4)
            } else {
                let remaining = countdown > 0 ? countdown : (gameState.timeToNextLivesRefill() ?? 0)
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                HStack(spacing: 6) {
                    Image(localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                    Text("\(gameState.lives)")
                        .font(.system(size: largeText ? 22 : 15, weight: .bold, design: .rounded))
                    Spacer(minLength: 4)
                    if gameState.lives >= gameState.maxLives {
                        Text(localizationManager.localizedString("home.header.lives_max"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    } else if remaining > 0 {
                        Text(String(format: localizationManager.localizedString("home.lives.refill_in_fmt"), gameState.maxLives, minutes, seconds))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, -2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(Capsule().fill(pillFill))
                .shadow(color: Color.black.opacity(isDark ? 0.28 : 0.08), radius: 16, x: 0, y: 4)
            }
        }
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

struct GameHomeVariant2View: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @ObservedObject private var leaguesService = LeaguesService.shared
    @Environment(\.colorScheme) private var systemColorScheme
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var compactPhone: Bool
    var isIPad: Bool
    /// iPad альбомная: баннер «настройки игры» — многострочный текст.
    var tabletLandscapeAlbum: Bool = false
    var showContent: Bool
    var showsHeaderRow: Bool = true
    var onShowFBucks: () -> Void
    var onOpenLeagueTab: () -> Void
    var onOpenQuestsTab: () -> Void
    /// iPad: Continue внутри hero (нижний sticky скрыт в ContentView).
    var onContinuePlay: (() -> Void)? = nil

    @State private var showSettingsSheet = false
    @State private var earnAnimatedStage: Int = 0
    @State private var goalVisible = false
    @State private var heroEntranceScale: CGFloat = 0.94
    @State private var heroWowVisible = false
    @State private var dailyAppearScale: CGFloat = 0.92
    @State private var hideDailyRewardUntilDate: String? = nil
    @State private var isDailyRewardDismissing = false

    private static let dailyRewardDismissDateKey = "home.v2.dailyReward.dismissedUntilDate"

    private var dailyRewardDismissSlideDistance: CGFloat {
        #if os(iOS)
        UIScreen.main.bounds.width
        #else
        800
        #endif
    }

    private var effectiveScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }

    private var isDark: Bool { effectiveScheme == .dark }

    /// Двухколоночный dashboard на iPad в полноэкранной ширине (не split compact).
    private var useTabletDashboardLayout: Bool {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        return horizontalSizeClass == .regular
        #else
        return false
        #endif
    }

    private var homeTabletContentMaxWidth: CGFloat { 1050 }

    private var tabletSplitLeftWidth: CGFloat {
        let margin: CGFloat = 56
        #if os(iOS)
        let screenW = UIScreen.main.bounds.width
        #else
        let screenW: CGFloat = 1200
        #endif
        let total = min(homeTabletContentMaxWidth, screenW - margin)
        return total * 0.62
    }

    private var embedContinueInTabletHero: Bool {
        onContinuePlay != nil && useTabletDashboardLayout
    }

    private var canvasBackground: Color {
        if isDark {
            #if os(iOS)
            return Color(UIColor.systemGroupedBackground)
            #else
            return Color(NSColor.windowBackgroundColor)
            #endif
        }
        return Color(red: 245 / 255, green: 246 / 255, blue: 248 / 255)
    }

    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0, green: 122 / 255, blue: 1),
                Color(red: 106 / 255, green: 92 / 255, blue: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var regionSummary: String {
        if gameState.selectedRegions.count == 1 {
            return gameState.selectedRegions.first?.displayName ?? localizationManager.localizedString("All Regions")
        }
        return localizationManager.localizedString("Multiple Regions")
    }

    private var perfectProgress: (Int, Int) {
        QuickHomeUX.perfectProgress(userProfile: userProfile)
    }

    private var streakProgress: (Int, Int) {
        QuickHomeUX.streakProgress(userProfile: userProfile)
    }

    private var bestFriendAheadOnStreak: Friend? {
        userProfile.friends
            .filter { $0.streak > userProfile.streak }
            .max(by: { $0.streak < $1.streak })
    }

    private var heroHeadline: String {
        let (ps, pt) = perfectProgress
        let (ss, st) = streakProgress
        if let f = bestFriendAheadOnStreak, f.streak >= 3, f.streak > userProfile.streak {
            return String(format: localizationManager.localizedString("home.hero.headline.friend"), f.displayNameOrUsername)
        }
        if ss < st {
            return localizationManager.localizedString("home.hero.headline.streak_alive")
        }
        if ps < pt {
            return localizationManager.localizedString("home.hero.headline.perfect_push")
        }
        if userProfile.canClaimDailyFBucksBonus() {
            return localizationManager.localizedString("home.hero.headline.daily_up")
        }
        return localizationManager.localizedString("home.hero.headline.keep_playing")
    }

    private var heroDetailLine: String {
        let (ps, pt) = perfectProgress
        let (ss, st) = streakProgress
        if let f = bestFriendAheadOnStreak, f.streak >= 3, f.streak > userProfile.streak {
            return String(format: localizationManager.localizedString("home.hero.detail.friend_streak"), f.streak)
        }
        if ss < st {
            return String(format: localizationManager.localizedString("home.hero.detail.streak_fmt"), ss, st)
        }
        if ps < pt {
            return String(format: localizationManager.localizedString("home.hero.detail.perfect_fmt"), ps, pt)
        }
        if userProfile.streak == 0 {
            return localizationManager.localizedString("home.hero.detail.start_streak")
        }
        return String(format: localizationManager.localizedString("home.hero.detail.day_fmt"), userProfile.streak)
    }

    private var heroNeedsUrgencyLayers: Bool {
        let (ps, pt) = perfectProgress
        let (ss, st) = streakProgress
        if let f = bestFriendAheadOnStreak, f.streak >= 3, f.streak > userProfile.streak { return true }
        return ss < st || ps < pt || userProfile.canClaimDailyFBucksBonus()
    }

    private func playHeroEntranceAndWow() {
        heroWowVisible = false
        heroEntranceScale = 0.94
        withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
            heroEntranceScale = 1.02
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                heroEntranceScale = 1
            }
        }
        guard heroNeedsUrgencyLayers else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.28)) {
                heroWowVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeOut(duration: 0.35)) {
                heroWowVisible = false
            }
        }
    }

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var isDailyRewardTemporarilyHidden: Bool {
        guard let until = hideDailyRewardUntilDate else { return false }
        return until == todayKey()
    }

    private func dismissDailyRewardUntilTomorrow() {
        let today = todayKey()
        hideDailyRewardUntilDate = today
        UserDefaults.standard.set(today, forKey: Self.dailyRewardDismissDateKey)
    }

    private func dismissDailyRewardWithAnimation() {
        guard !isDailyRewardDismissing else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            isDailyRewardDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismissDailyRewardUntilTomorrow()
            isDailyRewardDismissing = false
        }
    }

    private func localizedOrFallback(_ key: String, fallbackKey: String) -> String {
        let value = localizationManager.localizedString(key)
        return value == key ? localizationManager.localizedString(fallbackKey) : value
    }

    private func earnEmotion(current: Int, total: Int, almost: String, start: String, going: String, done: String) -> (text: String, hot: Bool) {
        let t = max(1, total)
        if current >= total { return (done, false) }
        if total - current <= 1 { return (almost, true) }
        if current == 0 { return (start, true) }
        if Double(current) / Double(t) >= 0.6 { return (almost, true) }
        return (going, false)
    }

    var body: some View {
        let horizontalPad: CGFloat = useTabletDashboardLayout ? 28 : 20
        VStack(alignment: .leading, spacing: compactPhone ? 14 : 18) {
            if showsHeaderRow {
                headerResourceRow
            }
            if let lost = userProfile.streakRecoveryLostChain, lost >= 2 {
                StreakRecoveryOfferBanner(lost: lost, isDark: isDark)
                    .environmentObject(userProfile)
            }
            if useTabletDashboardLayout {
                tabletWideMainColumn
            } else {
                phoneStackMainColumn
            }
        }
        .padding(.horizontal, horizontalPad)
        .padding(.top, compactPhone ? 6 : 10)
        .padding(.bottom, compactPhone ? 16 : 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(canvasBackground)
        .onAppear {
            hideDailyRewardUntilDate = UserDefaults.standard.string(forKey: Self.dailyRewardDismissDateKey)
            scheduleEarnAnimations()
            dailyAppearScale = 0.92
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                    dailyAppearScale = 1
                }
            }
            if showContent {
                playHeroEntranceAndWow()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    goalVisible = true
                }
            }
        }
        .onChange(of: showContent) { visible in
            if visible {
                scheduleEarnAnimations()
                playHeroEntranceAndWow()
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            GameHomeQuickSettingsSheet(gameState: gameState, isIPad: isIPad)
                .modifier(QuickSettingsSheetPresentation())
        }
    }

    /// A dismissible sheet on both devices; keep Save visible above the scrolling content.
    private struct QuickSettingsSheetPresentation: ViewModifier {
        func body(content: Content) -> some View {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                content
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                content
            }
            #else
            content
            #endif
        }
    }

    private func scheduleEarnAnimations() {
        earnAnimatedStage = 0
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(i)) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    earnAnimatedStage = i
                }
            }
        }
    }

    private var headerResourceRow: some View {
        let statNumberSize: CGFloat = isIPad ? 22 : 15
        let fBucksLogo: CGFloat = isIPad ? 30 : 26
        return HStack(spacing: 8) {
            QuickHomeLivesPillView(gameState: gameState, isDark: isDark, largeText: isIPad)
                .environmentObject(userProfile)
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 24))
                Text("\(userProfile.streak)")
                    .font(.system(size: statNumberSize, weight: .bold, design: .rounded))
                Text(localizationManager.localizedString("days"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(headerPillFill)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 8, x: 0, y: 2)
            Button(action: onShowFBucks) {
                HStack(spacing: 4) {
                    Image("FBucksLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: fBucksLogo, height: fBucksLogo)
                    Text("\(userProfile.fBucks)")
                        .font(.system(size: statNumberSize, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(headerPillFill)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 8)
        .animation(.easeOut(duration: 0.4), value: showContent)
    }

    private var phoneStackMainColumn: some View {
        VStack(alignment: .leading, spacing: compactPhone ? 14 : 18) {
            heroBlock
            settingsCompactRow
            if !(isDailyRewardTemporarilyHidden && !userProfile.canClaimDailyFBucksBonus()) || isDailyRewardDismissing {
                dailyRewardBlock
            }
            prideMomentBlock
            earnTodayBlock
            nextGoalBlock(tabletEmphasis: false)
            gameSettingsPromoBanner
        }
    }

    /// Две колонки на iPad: слева Today (earn), справа Next goal — и в книжной, и в альбомной ориентации.
    private var tabletWideMainColumn: some View {
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 22) {
                heroBlockTabletPrimary
                if !(isDailyRewardTemporarilyHidden && !userProfile.canClaimDailyFBucksBonus()) || isDailyRewardDismissing {
                    dailyRewardBlockTablet
                }
                earnTodayBlockTablet
                socialMotivationBlock
                prideMomentBlock
            }
            .frame(width: tabletSplitLeftWidth, alignment: .leading)
            VStack(alignment: .leading, spacing: 22) {
                nextGoalBlock(tabletEmphasis: true)
                quickPlayModesBlock
                settingsCompactRow
                gameSettingsPromoBanner
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: homeTabletContentMaxWidth)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var heroBlockTabletPrimary: some View {
        if embedContinueInTabletHero, let play = onContinuePlay {
            heroBlockTabletDashboard(onContinue: play)
        } else {
            heroBlockTablet
        }
    }

    /// Крупный hero: streak bar + CTA (без дубля снизу).
    private func heroBlockTabletDashboard(onContinue: @escaping () -> Void) -> some View {
        let (ss, st) = streakProgress
        let t = max(1, st)
        let streakFill = min(1, Double(ss) / Double(t))
        let hook = QuickHomeUX.stickyHookSubtitle(userProfile: userProfile, loc: localizationManager)
        return VStack(alignment: .leading, spacing: 14) {
            if heroWowVisible {
                Text(localizedOrFallback("home.hero.wow.tip", fallbackKey: "home.daily.subtitle.claim"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
            }
            HStack(alignment: .top, spacing: 12) {
                Text("🔥")
                    .font(.system(size: 36))
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text(heroHeadline)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text(heroDetailLine)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("\(ss)/\(st) \(localizationManager.localizedString("days"))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.22))
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: max(10, g.size.width * CGFloat(streakFill)))
                    }
                }
                .frame(height: 10)
            }
            if heroNeedsUrgencyLayers {
                Text(localizedOrFallback("home.hero.hook.reward_play", fallbackKey: "home.hero.play_bonus"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    if gameState.isStartingNewGame || gameState.isPreloadingFlags {
                        ProgressView()
                            .tint(.white)
                        Text(
                            gameState.isPreloadingFlags
                                ? localizationManager.localizedString("Loading flags...")
                                : localizationManager.localizedString("Starting...")
                        )
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(localizationManager.localizedString("home.continue"))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(gameState.selectedRegions.isEmpty || gameState.isStartingNewGame || gameState.isPreloadingFlags)
            Text(hook)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 26)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(primaryGradient)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.clear,
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
            .shadow(color: Color(red: 0, green: 122 / 255, blue: 1).opacity(0.45), radius: 28, x: 0, y: 14)
        )
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? heroEntranceScale : 0.97)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: showContent)
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: heroEntranceScale)
    }

    private var socialMotivationBlock: some View {
        Group {
            if let f = bestFriendAheadOnStreak, f.streak >= 2 {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizationManager.localizedString("home.social.title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack(alignment: .top, spacing: 12) {
                        Text("👤")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                String(
                                    format: localizationManager.localizedString("home.social.friend_streak_fmt"),
                                    f.displayNameOrUsername,
                                    f.streak
                                )
                            )
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            Text(localizationManager.localizedString("home.social.catch_today"))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isDark ? Color.white.opacity(0.06) : Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.purple.opacity(0.22), lineWidth: 1)
                )
            }
        }
    }

    private var quickPlayModesBlock: some View {
        let modes = gameState.availablePlayModes.filter { m in
            m == .classic || m == .duel || m == .survival
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("home.quick_modes.title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            VStack(spacing: 10) {
                ForEach(modes, id: \.self) { mode in
                    Button {
                        gameState.selectedPlayMode = mode
                        onContinuePlay?()
                    } label: {
                        HStack {
                            Image(systemName: mode.systemImage ?? "gamecontroller.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(mode.homeDisplayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isDark ? Color.white.opacity(0.06) : Color.white)
                                .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 6, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var headerPillFill: Color {
        if isDark {
            #if os(iOS)
            return Color(UIColor.secondarySystemGroupedBackground)
            #else
            return Color(NSColor.controlBackgroundColor)
            #endif
        }
        return Color.white
    }

    private var heroBlock: some View {
        VStack(spacing: 10) {
            if heroWowVisible {
                Text(localizedOrFallback("home.hero.wow.tip", fallbackKey: "home.daily.subtitle.claim"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
            Text("🔥")
                .font(.system(size: 32))
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            Text(heroHeadline)
                .font(.system(size: compactPhone ? 19 : 21, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(heroDetailLine)
                .font(.system(size: compactPhone ? 16 : 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
            if heroNeedsUrgencyLayers {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("👉")
                        .font(.system(size: 15))
                    Text(localizedOrFallback("home.hero.hook.reward_play", fallbackKey: "home.hero.play_bonus"))
                        .font(.system(size: compactPhone ? 14 : 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                Text(localizedOrFallback("home.hero.pressure", fallbackKey: "home.streak_nudge.solo_sub"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, compactPhone ? 22 : 26)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(primaryGradient)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                Color.clear,
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
            .shadow(color: Color(red: 0, green: 122 / 255, blue: 1).opacity(0.48), radius: 24, x: 0, y: 12)
        )
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? heroEntranceScale : 0.97)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: showContent)
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: heroEntranceScale)
        .animation(.easeOut(duration: 0.28), value: heroWowVisible)
    }

    /// iPad: высота следует за текстом, включая дополнительные строки о награде.
    private var heroBlockTablet: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                if heroWowVisible {
                    Text(localizedOrFallback("home.hero.wow.tip", fallbackKey: "home.daily.subtitle.claim"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
                HStack(alignment: .top, spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 30))
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(heroHeadline)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(heroDetailLine)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.leading)
                    }
                }
                if heroNeedsUrgencyLayers {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("👉")
                                .font(.system(size: 15))
                            Text(localizedOrFallback("home.hero.hook.reward_play", fallbackKey: "home.hero.play_bonus"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        Text(localizedOrFallback("home.hero.pressure", fallbackKey: "home.streak_nudge.solo_sub"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Spacer(minLength: 0)
            Text("🔥")
                .font(.system(size: 54))
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                .foregroundStyle(.white.opacity(heroNeedsUrgencyLayers ? 0.95 : 0.35))
                .padding(.trailing, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 26)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(primaryGradient)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                Color.clear,
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
            .shadow(color: Color(red: 0, green: 122 / 255, blue: 1).opacity(0.48), radius: 24, x: 0, y: 12)
        )
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? heroEntranceScale : 0.97)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: showContent)
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: heroEntranceScale)
        .animation(.easeOut(duration: 0.28), value: heroWowVisible)
    }

    private var settingsCompactRow: some View {
        Button(action: { showSettingsSheet = true }) {
            HStack(alignment: .center, spacing: 10) {
                Text("🌍 \(regionSummary) • ⚡ \(gameState.selectedDifficulty.displayName) • 🎯 \(gameState.selectedPlayMode.homeDisplayName)")
                    .font(.system(size: compactPhone ? 14 : 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 6)
                Text(localizationManager.localizedString("home.settings.change"))
                    .font(.system(size: compactPhone ? 14 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0, green: 122 / 255, blue: 1))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.06) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0, green: 122 / 255, blue: 1).opacity(0.22), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.quickSettings")
    }

    /// Второй вход на те же быстрые настройки, что и «Изменить» — под блоком «Следующая цель».
    private var gameSettingsPromoBanner: some View {
        Button(action: { showSettingsSheet = true }) {
            HStack(alignment: tabletLandscapeAlbum ? .top : .center, spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0, green: 122 / 255, blue: 1), Color(red: 106 / 255, green: 92 / 255, blue: 1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(red: 0, green: 122 / 255, blue: 1).opacity(isDark ? 0.2 : 0.12))
                    )
                VStack(alignment: .leading, spacing: tabletLandscapeAlbum ? 6 : 4) {
                    Text(localizationManager.localizedString("home.settings.promo.title"))
                        .font(.system(size: compactPhone ? 16 : (tabletLandscapeAlbum ? 18 : 17), weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(tabletLandscapeAlbum ? 2 : nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(localizationManager.localizedString("home.settings.promo.subtitle"))
                        .font(.system(size: tabletLandscapeAlbum ? 14 : 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(tabletLandscapeAlbum ? 3 : nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, tabletLandscapeAlbum ? 4 : 0)
            }
            .padding(.vertical, tabletLandscapeAlbum ? 18 : 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardFillColor)
                    .shadow(color: Color.black.opacity(isDark ? 0.14 : 0.06), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0, green: 122 / 255, blue: 1).opacity(0.35), Color.purple.opacity(0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(goalVisible ? 1 : 0)
        .offset(y: goalVisible ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: goalVisible)
    }

    private var prideStreakLine: String {
        if userProfile.streak == 1 {
            return localizedOrFallback("home.pride.streak_full_one", fallbackKey: "home.pride.streak_line_one")
        }
        let fmt = localizationManager.localizedString("home.pride.streak_full_fmt")
        if fmt == "home.pride.streak_full_fmt" {
            return String(format: localizationManager.localizedString("home.pride.streak_line_fmt"), userProfile.streak)
        }
        return String(format: fmt, userProfile.streak)
    }

    private var leagueEarnSubtitle: String {
        if userProfile.leaguePosition > 0 && userProfile.leaguePosition <= 5 {
            return localizationManager.localizedString("home.earn.league.almost")
        }
        return localizationManager.localizedString("home.earn.league.hint")
    }

    private var prideMomentBlock: some View {
        let showStreak = userProfile.streak >= 1
        let showLeague =
            userProfile.totalGamesPlayed >= 3
            && userProfile.leaguePosition > 0
            && userProfile.leaguePosition <= 50
        return Group {
            if showStreak || showLeague {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localizedString("home.pride.section_title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    if showLeague {
                        HStack(alignment: .top, spacing: 12) {
                            Text("🏆")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(String(format: localizationManager.localizedString("home.pride.rank_headline_fmt"), userProfile.leaguePosition))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                if userProfile.leaguePosition > 10 {
                                    prideLeagueGapLabel(position: userProfile.leaguePosition)
                                }
                            }
                        }
                    }
                    if showStreak {
                        HStack(spacing: 8) {
                            Text("🔥")
                            Text(prideStreakLine)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(prideCardFill)
                        .shadow(color: Color.black.opacity(isDark ? 0.14 : 0.05), radius: 8, x: 0, y: 3)
                )
            }
        }
    }

    private var earnTodayBlock: some View {
        let pe = earnEmotion(
            current: perfectProgress.0,
            total: perfectProgress.1,
            almost: localizationManager.localizedString("home.earn.perfect.almost"),
            start: localizationManager.localizedString("home.earn.perfect.start"),
            going: localizationManager.localizedString("home.earn.perfect.going"),
            done: localizationManager.localizedString("home.earn.done")
        )
        let se = earnEmotion(
            current: streakProgress.0,
            total: streakProgress.1,
            almost: localizationManager.localizedString("home.earn.streak.almost"),
            start: localizationManager.localizedString("home.earn.streak.start"),
            going: localizationManager.localizedString("home.earn.streak.going"),
            done: localizationManager.localizedString("home.earn.done")
        )
        return VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("home.earn.section"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    earnCard(
                        index: 1,
                        systemIcon: "target",
                        title: localizationManager.localizedString("fbucks.earn.perfect.title"),
                        progress: perfectProgress,
                        reward: "+1",
                        emotion: pe.text,
                        tint: .green,
                        onTap: nil,
                        grid: false
                    )
                    earnCard(
                        index: 2,
                        systemIcon: "flame.fill",
                        title: localizationManager.localizedString("fbucks.earn.streak"),
                        progress: streakProgress,
                        reward: streakProgress.0 >= streakProgress.1 ? "✓" : "+1",
                        emotion: se.text,
                        tint: .orange,
                        onTap: nil,
                        grid: false
                    )
                    earnLeagueCard(index: 3, grid: false)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var earnTodayBlockTablet: some View {
        let pe = earnEmotion(
            current: perfectProgress.0,
            total: perfectProgress.1,
            almost: localizationManager.localizedString("home.earn.perfect.almost"),
            start: localizationManager.localizedString("home.earn.perfect.start"),
            going: localizationManager.localizedString("home.earn.perfect.going"),
            done: localizationManager.localizedString("home.earn.done")
        )
        let se = earnEmotion(
            current: streakProgress.0,
            total: streakProgress.1,
            almost: localizationManager.localizedString("home.earn.streak.almost"),
            start: localizationManager.localizedString("home.earn.streak.start"),
            going: localizationManager.localizedString("home.earn.streak.going"),
            done: localizationManager.localizedString("home.earn.done")
        )
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("home.earn.section"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
                earnCard(
                    index: 1,
                    systemIcon: "target",
                    title: localizationManager.localizedString("fbucks.earn.perfect.title"),
                    progress: perfectProgress,
                    reward: "+1",
                    emotion: pe.text,
                    tint: .green,
                    onTap: nil,
                    grid: true
                )
                earnCard(
                    index: 2,
                    systemIcon: "flame.fill",
                    title: localizationManager.localizedString("fbucks.earn.streak"),
                    progress: streakProgress,
                    reward: streakProgress.0 >= streakProgress.1 ? "✓" : "+1",
                    emotion: se.text,
                    tint: .orange,
                    onTap: nil,
                    grid: true
                )
                earnLeagueCard(index: 3, grid: true)
            }
        }
    }

    private func earnCard(
        index: Int,
        systemIcon: String,
        title: String,
        progress: (Int, Int),
        reward: String,
        emotion: String,
        tint: Color,
        onTap: (() -> Void)?,
        grid: Bool
    ) -> some View {
        let visible = earnAnimatedStage >= index
        let cardBg = RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(earnCardMutedFill)
            .shadow(color: Color.black.opacity(isDark ? 0.1 : 0.03), radius: 4, x: 0, y: 2)
        let iconSize: CGFloat = grid ? 22 : 20
        let titleSize: CGFloat = grid ? 15 : 14
        let emotionSize: CGFloat = grid ? 13 : 12
        let stack = VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemIcon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint.opacity(0.9))
            Text(title)
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)
            Text(emotion)
                .font(.system(size: emotionSize, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            progressBarMuted(filled: progress.0, total: progress.1)
            Text("\(progress.0)/\(progress.1)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            Text(reward)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(tint.opacity(0.95))
        }
        .padding(grid ? 14 : 12)

        let content = Group {
            if grid {
                stack
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            } else {
                stack
                    .frame(width: 152, height: 182, alignment: .topLeading)
            }
        }
        .background(cardBg)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 14)

        return Group {
            if let onTap {
                Button(action: onTap) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private func earnLeagueCard(index: Int, grid: Bool) -> some View {
        let visible = earnAnimatedStage >= index
        let calmBg = RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(earnCardMutedFill)
            .shadow(color: Color.black.opacity(isDark ? 0.1 : 0.03), radius: 4, x: 0, y: 2)
        let titleSize: CGFloat = grid ? 15 : 14
        let subSize: CGFloat = grid ? 13 : 12
        let padded = VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: grid ? 22 : 20, weight: .semibold))
                .foregroundStyle(Color.yellow.opacity(0.85))
            Text(localizationManager.localizedString("fbucks.earn.league"))
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)
            Text(leagueEarnSubtitle)
                .font(.system(size: subSize, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            Text("+3")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow.opacity(0.9))
        }
        .padding(grid ? 14 : 12)
        return Button(action: onOpenLeagueTab) {
            Group {
                if grid {
                    padded
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                } else {
                    padded
                        .frame(width: 152, height: 182, alignment: .topLeading)
                }
            }
            .background(calmBg)
        }
        .buttonStyle(.plain)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 14)
    }

    private func progressBarMuted(filled: Int, total: Int) -> some View {
        let t = max(1, total)
        let p = min(1, Double(filled) / Double(t))
        let fill = Color(red: 0, green: 122 / 255, blue: 1).opacity(0.38)
        return GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(fill)
                    .frame(width: max(4, g.size.width * CGFloat(p)))
            }
        }
        .frame(height: 6)
    }

    private var dailyRewardBlock: some View {
        dailyRewardBlockInner(useTabletButtonSizing: false)
    }

    private var dailyRewardBlockTablet: some View {
        dailyRewardBlockInner(useTabletButtonSizing: true)
    }

    @ViewBuilder
    private func dailyRewardBlockInner(useTabletButtonSizing: Bool) -> some View {
        let canClaim = userProfile.canClaimDailyFBucksBonus()
        let titleSize: CGFloat = useTabletButtonSizing ? 21 : 19
        VStack(alignment: .leading, spacing: useTabletButtonSizing ? 14 : 16) {
            HStack(alignment: .top, spacing: 14) {
                Text("🎁")
                    .font(.system(size: useTabletButtonSizing ? 40 : 36))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(isDark ? 0.22 : 0.14))
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizationManager.localizedString("home.daily.title"))
                        .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                    Text(
                        canClaim
                            ? localizationManager.localizedString("home.daily.subtitle.claim")
                            : localizationManager.localizedString("home.daily.subtitle.claimed")
                    )
                    .font(.system(size: useTabletButtonSizing ? 16 : 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                }
            }
            if canClaim {
                if useTabletButtonSizing {
                    HStack {
                        Spacer(minLength: 0)
                        HomeDailyShimmerClaimButton(
                            title: localizationManager.localizedString("home.daily.claim"),
                            action: { userProfile.claimDailyFBucksBonus() },
                            maxButtonWidth: 380
                        )
                        Spacer(minLength: 0)
                    }
                } else {
                    HomeDailyShimmerClaimButton(
                        title: localizationManager.localizedString("home.daily.claim"),
                        action: { userProfile.claimDailyFBucksBonus() },
                        maxButtonWidth: nil
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizationManager.localizedString("home.daily.claimed"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(localizationManager.localizedString("home.daily.tomorrow"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, useTabletButtonSizing ? 20 : 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(dailyCardTintFill)
                .shadow(color: Color.black.opacity(isDark ? 0.16 : 0.07), radius: 11, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.orange.opacity(canClaim ? 0.32 : 0.14), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if !canClaim {
                Button(action: dismissDailyRewardWithAnimation) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Circle().fill(Color.black.opacity(isDark ? 0.18 : 0.06)))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
        }
        .scaleEffect(canClaim ? dailyAppearScale : 1)
        .offset(x: isDailyRewardDismissing ? -dailyRewardDismissSlideDistance : 0)
        .opacity(isDailyRewardDismissing ? 0 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 18).onEnded { value in
                if !canClaim && value.translation.width < -40 {
                    dismissDailyRewardWithAnimation()
                }
            }
        )
    }

    private func nextGoalBlock(tabletEmphasis: Bool) -> some View {
        let league = userProfile.currentLeague
        let nextLeague = league.leagueAbove
        let currentWeekXP = leaguesService.currentWeekUserXP()
        let promotionTargetXP = leaguesService.promotionTargetXP(for: userProfile)
        let remainingXP = promotionTargetXP.map { max(0, $0 - currentWeekXP) } ?? 0
        let pendingQuestRewards = !userProfile.recentMonthlyQuestRewards.isEmpty
        let calmGoalShadow = Color.black.opacity(isDark ? 0.15 : 0.06)
        let sectionFont: CGFloat = tabletEmphasis ? 17 : 14
        let headlineFont: CGFloat = tabletEmphasis ? 24 : 19
        let detailFont: CGFloat = tabletEmphasis ? 18 : 15
        let ctaFont: CGFloat = tabletEmphasis ? 17 : 14
        let iconNext: CGFloat = tabletEmphasis ? 80 : 58
        let iconMax: CGFloat = tabletEmphasis ? 76 : 56
        return Button(action: {
            if pendingQuestRewards {
                onOpenQuestsTab()
            } else {
                onOpenLeagueTab()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Text(localizationManager.localizedString("home.next_goal.title"))
                    .font(.system(size: sectionFont, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                if let next = nextLeague {
                    let targetXP = max(1, promotionTargetXP ?? next.xpRequirement)
                    let progress = min(1, max(0, Double(currentWeekXP) / Double(targetXP)))
                    HStack(alignment: .top, spacing: 14) {
                        Image(next.imageAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconNext, height: iconNext)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(format: localizationManager.localizedString("home.goal.headline_almost_fmt"), next.localizedName))
                                .font(.system(size: headlineFont, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(String(format: localizationManager.localizedString("home.goal.xp_remaining_detail"), remainingXP))
                                .font(.system(size: detailFont, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.18))
                                    Capsule()
                                        .fill(Color(red: 0, green: 122 / 255, blue: 1).opacity(0.42))
                                        .frame(width: max(8, g.size.width * CGFloat(progress)))
                                }
                            }
                            .frame(height: tabletEmphasis ? 14 : 10)
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: tabletEmphasis ? 14 : 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(pendingQuestRewards
                                ? localizationManager.localizedString("home.goal.claim_reward_cta")
                                : localizationManager.localizedString("home.goal.open_league")
                            )
                            .font(.system(size: ctaFont, weight: .bold, design: .rounded))
                            .foregroundColor(pendingQuestRewards ? .white : Color(red: 0, green: 122 / 255, blue: 1))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                            .padding(.vertical, pendingQuestRewards ? (tabletEmphasis ? 12 : 10) : 0)
                            .padding(.horizontal, pendingQuestRewards ? (tabletEmphasis ? 14 : 12) : 0)
                            .background(
                                Group {
                                    if pendingQuestRewards {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.pink.opacity(0.9)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                            )
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(league.imageAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconMax, height: iconMax)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localizedString("home.league.max"))
                                .font(.system(size: tabletEmphasis ? 22 : 17, weight: .heavy, design: .rounded))
                            if pendingQuestRewards {
                                Text(localizationManager.localizedString("home.goal.claim_reward_cta"))
                                    .font(.system(size: tabletEmphasis ? 17 : 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.pink.opacity(0.9)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            } else {
                                Text(localizationManager.localizedString("home.goal.open_league"))
                                    .font(.system(size: ctaFont, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0, green: 122 / 255, blue: 1))
                            }
                        }
                    }
                }
            }
            .padding(tabletEmphasis ? 22 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: tabletEmphasis ? 22 : 18, style: .continuous)
                    .fill(cardFillColor)
                    .shadow(color: calmGoalShadow, radius: tabletEmphasis ? 14 : 10, x: 0, y: 4)
            )
            .opacity(goalVisible ? 1 : 0)
            .offset(y: goalVisible ? 0 : 12)
        }
        .buttonStyle(.plain)
    }

    private var cardFillColor: Color {
        if isDark {
            #if os(iOS)
            return Color(UIColor.secondarySystemGroupedBackground)
            #else
            return Color(NSColor.controlBackgroundColor)
            #endif
        }
        return Color.white
    }

    private var prideCardFill: Color {
        if isDark {
            return Color(white: 0.19)
        }
        return Color(red: 0.91, green: 0.91, blue: 0.93)
    }

    private var dailyCardTintFill: Color {
        isDark ? Color.orange.opacity(0.12) : Color.orange.opacity(0.07)
    }

    private var earnCardMutedFill: Color {
        #if os(iOS)
        if isDark {
            return Color(UIColor.systemGray5).opacity(0.38)
        }
        return Color(UIColor.systemGray6).opacity(0.65)
        #else
        return cardFillColor.opacity(0.88)
        #endif
    }

    @ViewBuilder
    private func prideLeagueGapLabel(position: Int) -> some View {
        let gap = position - 10
        if gap <= 3 {
            let text = localizedOrFallback("home.pride.close_top10_short", fallbackKey: "home.pride.top10_hint")
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color.orange)
        } else {
            let fmt = localizationManager.localizedString("home.pride.gap_top10_fmt")
            if fmt == "home.pride.gap_top10_fmt" {
                Text(localizationManager.localizedString("home.pride.top10_hint"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.orange)
            } else {
                Text(String(format: fmt, gap))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.orange)
            }
        }
    }

}

// MARK: - Daily claim (F-Bucks style + shimmer)

private struct HomeDailyShimmerClaimButton: View {
    var title: String
    var action: () -> Void
    /// Ограничение ширины (например iPad — не «труба» на всю карточку).
    var maxButtonWidth: CGFloat?
    @State private var shimmerSlide = false

    var body: some View {
        Button(action: {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            action()
        }) {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                GeometryReader { g in
                    let w = g.size.width
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.62), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(44, w * 0.4))
                    .offset(x: shimmerSlide ? w * 0.58 : -w * 0.48)
                    .animation(.easeInOut(duration: 1.05), value: shimmerSlide)
                    .allowsHitTesting(false)
                }
                .clipShape(Capsule())
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: maxButtonWidth ?? .infinity)
            .frame(height: 50)
        }
        .buttonStyle(ScaleButtonStyle())
        .onReceive(Timer.publish(every: 4, on: .main, in: .common).autoconnect()) { _ in
            shimmerSlide.toggle()
        }
        .onAppear {
            shimmerSlide = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                shimmerSlide = true
            }
        }
    }

}

// MARK: - Bottom sheet настроек (черновик → Apply)

private struct GameHomeQuickSettingsSheet: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var isIPad: Bool

    @State private var draftRegions: Set<GameState.Region> = []
    @State private var draftDifficulty: GameState.Difficulty = .medium
    @State private var draftPlayMode: GameState.PlayMode = .classic
    @State private var initialDifficulty: GameState.Difficulty?
    @State private var initialPlayMode: GameState.PlayMode?
    @State private var didEditRegions = false
    @State private var discardChanges = false
    @State private var didCommit = false
    @State private var availableRegions: [GameState.Region] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionTitle("Select Region")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(availableRegions, id: \.self) { region in
                            regionChip(region)
                        }
                    }

                    sectionTitle("Select Level")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(GameState.Difficulty.allCases, id: \.self) { d in
                            difficultyChip(d)
                        }
                    }

                    sectionTitle("Game Mode")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(gameState.availablePlayModes, id: \.self) { m in
                            modeChip(m)
                        }
                    }

                    Button {
                        applyDraft()
                    } label: {
                        Text(localizationManager.localizedString("home.settings.apply"))
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0, green: 122 / 255, blue: 1),
                                                Color(red: 106 / 255, green: 92 / 255, blue: 1)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(20)
                .padding(.bottom, 28)
            }
            .accessibilityIdentifier("quickSettings.content")
            .navigationTitle(localizationManager.localizedString("home.settings.sheet_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("Cancel")) {
                        discardChanges = true
                        dismiss()
                    }
                    .accessibilityIdentifier("quickSettings.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizationManager.localizedString("Сохранить")) { applyDraft() }
                        .font(.headline)
                        .accessibilityIdentifier("quickSettings.save")
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            guard initialDifficulty == nil else { return }
            draftRegions = gameState.selectedRegions
            draftDifficulty = gameState.selectedDifficulty
            draftPlayMode = gameState.selectedPlayMode
            normalizeDraftRegions()
            refreshRegions()
            initialDifficulty = draftDifficulty
            initialPlayMode = draftPlayMode
        }
        .onDisappear { commitDraft() }
        .onChange(of: gameState.mistakeCountries.count) { _ in refreshRegions() }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(localizationManager.localizedString(key))
            .font(.system(size: isIPad ? 20 : 16, weight: .bold, design: .rounded))
    }

    private func regionChip(_ region: GameState.Region) -> some View {
        let isSelected: Bool = {
            if region == .all { return draftRegions == [.all] }
            return draftRegions == [region]
        }()
        return Button {
            if region == .myMistakes && !gameState.isPremium {
                gameState.showMistakesPremiumAlert = true
                return
            }
            didEditRegions = true
            if region == .all {
                draftRegions = [.all]
            } else {
                draftRegions = [region]
            }
        } label: {
            VStack(spacing: 8) {
                regionThumbnail(region: region, isSelected: isSelected)
                HStack(spacing: 4) {
                    Text(localizationManager.localizedString(region.rawValue))
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                    if region == .myMistakes {
                        Text("(\(gameState.mistakeCountries.count))")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(isSelected ? Color.white.opacity(0.85) : .secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quickSettings.region." + region.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func difficultyChip(_ d: GameState.Difficulty) -> some View {
        let sel = draftDifficulty == d
        return Button {
            draftDifficulty = d
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: sel
                                    ? [Color.white.opacity(0.28), Color.white.opacity(0.12)]
                                    : [d.iconColor.opacity(0.35), d.iconColor.opacity(0.62)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: d.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(sel ? Color.white : Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                }
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(sel ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1.5)
                )
                Text(shortDifficultyTitle(d))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(sel ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundColor(sel ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quickSettings.difficulty." + d.rawValue)
        .accessibilityAddTraits(sel ? .isSelected : [])
    }

    private func shortDifficultyTitle(_ d: GameState.Difficulty) -> String {
        switch d {
        case .easy: return localizationManager.localizedString("Easy")
        case .medium: return localizationManager.localizedString("Medium")
        case .hard: return localizationManager.localizedString("Hard")
        case .expert: return localizationManager.localizedString("Expert")
        case .erudite: return localizationManager.localizedString("Erudite")
        }
    }

    private func modeChip(_ m: GameState.PlayMode) -> some View {
        let sel = draftPlayMode == m
        return Button {
            draftPlayMode = m
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: sel
                                    ? [Color.white.opacity(0.28), Color.white.opacity(0.12)]
                                    : [m.iconColor.opacity(0.38), m.iconColor.opacity(0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: m.systemImage ?? "gamecontroller.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(sel ? Color.white : Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                }
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(sel ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1.5)
                )
                Text(m.homeDisplayName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(sel ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundColor(sel ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Миниатюра региона: градиент + символ (частичные глобусы на iOS 17+, иначе запасной вариант).
    @ViewBuilder
    private func regionThumbnail(region: GameState.Region, isSelected: Bool) -> some View {
        let g = regionThumbnailGradient(region)
        let sym = regionThumbnailSystemImage(region)
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isSelected
                            ? [Color.white.opacity(0.28), Color.white.opacity(0.12)]
                            : g,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: sym)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
        }
        .frame(width: 52, height: 52)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
    }

    private func regionThumbnailSystemImage(_ region: GameState.Region) -> String {
        if #available(iOS 17.0, macOS 14.0, *) {
            switch region {
            case .all: return "globe"
            case .europe: return "globe.europe.africa"
            case .africa: return "globe.europe.africa"
            case .asia: return "globe.asia.australia"
            case .oceania: return "globe.asia.australia"
            case .northAmerica: return "globe.americas"
            case .southAmerica: return "globe.americas"
            case .myMistakes: return "exclamationmark.triangle.fill"
            }
        }
        switch region {
        case .all: return "globe"
        case .myMistakes: return "exclamationmark.triangle.fill"
        default: return "map.fill"
        }
    }

    private func regionThumbnailGradient(_ region: GameState.Region) -> [Color] {
        switch region {
        case .all:
            return [Color(red: 0.2, green: 0.55, blue: 1), Color(red: 0.35, green: 0.85, blue: 0.95)]
        case .europe:
            return [Color(red: 0.35, green: 0.28, blue: 0.85), Color(red: 0.55, green: 0.4, blue: 0.95)]
        case .africa:
            return [Color(red: 0.95, green: 0.55, blue: 0.2), Color(red: 0.75, green: 0.35, blue: 0.12)]
        case .asia:
            return [Color(red: 0.95, green: 0.35, blue: 0.25), Color(red: 0.85, green: 0.2, blue: 0.45)]
        case .oceania:
            return [Color(red: 0.15, green: 0.65, blue: 0.78), Color(red: 0.25, green: 0.82, blue: 0.72)]
        case .northAmerica:
            return [Color(red: 0.15, green: 0.45, blue: 0.92), Color(red: 0.3, green: 0.72, blue: 0.98)]
        case .southAmerica:
            return [Color(red: 0.2, green: 0.72, blue: 0.38), Color(red: 0.95, green: 0.78, blue: 0.2)]
        case .myMistakes:
            return [Color(red: 1, green: 0.45, blue: 0.35), Color(red: 0.85, green: 0.2, blue: 0.25)]
        }
    }

    private func refreshRegions() {
        var regions = GameState.Region.allCases.filter { $0 != .myMistakes && $0 != .all }
        regions.insert(.all, at: 0)
        if gameState.hasMistakes {
            regions.append(.myMistakes)
        }
        availableRegions = regions
    }

    /// В sheet один визуальный выбор региона; при множественном выборе с классической главной — берём первый осмысленный.
    private func normalizeDraftRegions() {
        if draftRegions.isEmpty {
            draftRegions = [.all]
            return
        }
        if draftRegions == [.all] { return }
        if draftRegions.count == 1 { return }
        let sorted = draftRegions.filter { $0 != .all }.sorted { $0.rawValue < $1.rawValue }
        if let first = sorted.first {
            draftRegions = [first]
        } else {
            draftRegions = [.all]
        }
    }

    private func applyDraft() {
        commitDraft()
        dismiss()
    }

    /// Explicit Save and interactive dismissal share one commit, without duplicate region loads.
    private func commitDraft() {
        guard let initialDifficulty, let initialPlayMode, !discardChanges, !didCommit else { return }
        didCommit = true
        if draftDifficulty != initialDifficulty { gameState.selectedDifficulty = draftDifficulty }
        if draftPlayMode != initialPlayMode { gameState.selectedPlayMode = draftPlayMode }
        if didEditRegions && draftRegions != gameState.selectedRegions {
            gameState.setRegions(draftRegions)
        }
    }
}

// MARK: - Восстановление серии (главная quick + classic)
struct StreakRecoveryOfferBanner: View {
    let lost: Int
    let isDark: Bool
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var payGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0, green: 122 / 255, blue: 1),
                Color(red: 106 / 255, green: 92 / 255, blue: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        let cost = userProfile.streakRecoveryFBucksCost() ?? 0
        let canPay = cost > 0 && userProfile.fBucks >= cost
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.orange)
                Text(localizationManager.localizedString("streak.recovery.title"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            Text(String(format: localizationManager.localizedString("streak.recovery.body_fmt"), lost, cost))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button(action: {
                    if userProfile.restoreStreakWithFBucks() {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
                }) {
                    Text(String(format: localizationManager.localizedString("streak.recovery.pay_btn_fmt"), cost))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if canPay {
                                    payGradient
                                } else {
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.38), Color.gray.opacity(0.48)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canPay)
                Button(action: {
                    userProfile.chooseStreakRecoveryPlayPath()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }) {
                    Text(localizationManager.localizedString("streak.recovery.play_btn"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.accentColor, lineWidth: 1.5))
                        .foregroundColor(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            Button(action: { userProfile.dismissStreakRecoveryOffer() }) {
                Text(localizationManager.localizedString("streak.recovery.later_btn"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.06) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 8, x: 0, y: 3)
        )
    }
}
