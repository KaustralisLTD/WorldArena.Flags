import SwiftUI
#if os(iOS)
import UIKit
import AudioToolbox
#elseif os(macOS)
import AppKit
#endif

struct LeaguesView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var leaderboardData: [LeaderboardEntry] = []
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var now: Date = Date()
    @ObservedObject private var leaguesService = LeaguesService.shared
    @State private var showingWeeklyResultModal = false
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    @Environment(\.sizeCategory) private var sizeCategory

    private func localized(_ key: String) -> String { localizationManager.localizedString(key) }
    private var currentEntry: LeaderboardEntry? { leaderboardData.first(where: \.isCurrentUser) }

    var body: some View {
        GeometryReader { geometry in
            let phone = UIDevice.current.userInterfaceIdiom == .phone
            let wide = !phone && geometry.size.width >= 760 && !sizeCategory.isAccessibilityCategory
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        if wide {
                            HStack(alignment: .top, spacing: 24) {
                                VStack(spacing: 18) {
                                    leagueHero()
                                    standingCard(proxy: proxy)
                                    leaguePath(vertical: true)
                                }
                                .frame(width: min(340, geometry.size.width * 0.34))
                                leaderboardSection
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            leagueHero(topInset: phone ? geometry.safeAreaInsets.top : nil)
                                .padding(.horizontal, phone ? -16 : 0)
                            leaguePath(vertical: false)
                            standingCard(proxy: proxy)
                            leaderboardSection
                        }
                    }
                    .frame(maxWidth: 1120)
                    .padding(.horizontal, wide ? 28 : 16)
                    .padding(.top, phone ? 0 : 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea(.container, edges: phone ? .top : [])
                .accessibilityIdentifier("leagues.scroll")
                .refreshable { await refreshLeaguesContent() }
            }
        }
        .background(systemGroupedBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            checkPreviousWeekAndShowPopupIfNeeded()
            generateLeaderboardData()
            if leaguesService.latestWeeklyResult?.needsLeagueModal == true {
                showingWeeklyResultModal = true
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        .fullScreenCover(isPresented: $showingWeeklyResultModal) {
            if let result = leaguesService.latestWeeklyResult {
                LeagueWeeklyResultModalView(result: result, onDismiss: {
                    leaguesService.markLeagueResultSeen()
                    showingWeeklyResultModal = false
                })
            }
        }
    }

    private func leagueHero(topInset: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(localized("Лиги"))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
                    Text(userProfile.currentLeague.localizedName)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("leagues.title")
                }
                Spacer(minLength: 0)
                Image(userProfile.currentLeague.imageAssetName)
                    .resizable().scaledToFit().frame(width: 76, height: 76)
                    .accessibilityHidden(true)
            }
            Label(timeRemainingStringGMT(), systemImage: "clock")
                .font(.caption.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.white)
        .padding(22)
        .padding(.horizontal, topInset != nil ? 16 : 0)
        .padding(.top, topInset.map { $0 + 16 } ?? 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0.36, green: 0.25, blue: 0.72), Color(red: 0.20, green: 0.39, blue: 0.83)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: topInset == nil ? 24 : 0))
    }

    private func standingCard(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let entry = currentEntry {
                Button {
                    withAnimation(.easeInOut) { proxy.scrollTo(entry.id, anchor: .center) }
                } label: {
                    HStack(spacing: 12) {
                        Text("#\(entry.position)")
                            .font(.title.bold()).monospacedDigit().foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: localized("Вы занимаете #%d место"), entry.position))
                                .font(.subheadline.weight(.semibold))
                            Text("\(entry.xp) XP")
                                .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.down").foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("leagues.myPosition")
                Divider()
                Label(statusText(for: entry.position), systemImage: statusSymbol(for: entry.position))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(secondarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statusSymbol(for position: Int) -> String {
        let thresholds = leaguesService.leagueThresholds(for: userProfile)
        if thresholds.promote.contains(position), userProfile.currentLeague.leagueAbove != nil { return "arrow.up.right" }
        if thresholds.demote?.contains(position) == true, userProfile.currentLeague.leagueBelow != nil { return "arrow.down.right" }
        return "checkmark.shield"
    }

    private func statusText(for position: Int) -> String {
        switch statusSymbol(for: position) {
        case "arrow.up.right": return localized("Зона повышения - переход в следующую лигу!")
        case "arrow.down.right": return localized("Зона вылета - риск понижения лиги")
        default: return localized("Безопасная зона - остаетесь в текущей лиге")
        }
    }

    @ViewBuilder
    private func leaguePath(vertical: Bool) -> some View {
        if vertical {
            VStack(alignment: .leading, spacing: 12) {
                Text(localized("Лиги")).font(.headline)
                ForEach(League.allCases, id: \.self) { league in
                    leagueBadge(league, vertical: true)
                }
            }
            .padding(18)
            .background(secondarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(League.allCases, id: \.self) { league in
                            leagueBadge(league, vertical: false).id(league)
                        }
                    }
                }
                .onAppear { scrollLeaguesStripToCurrentLeague(proxy: proxy) }
                .onChange(of: userProfile.currentLeague) { _ in scrollLeaguesStripToCurrentLeague(proxy: proxy) }
            }
        }
    }

    private func leagueBadge(_ league: League, vertical: Bool) -> some View {
        let current = league == userProfile.currentLeague
        return HStack(spacing: 10) {
            Image(league.imageAssetName)
                .resizable().scaledToFit().frame(width: 36, height: 36)
                .grayscale(league.isReached(by: userProfile.currentLeague) ? 0 : 0.85)
                .accessibilityHidden(true)
            Text(league.localizedName)
                .font(.subheadline.weight(current ? .bold : .medium))
                .fixedSize(horizontal: false, vertical: true)
            if vertical {
                Spacer(minLength: 0)
                if current { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor) }
            }
        }
        .padding(10)
        .background(current ? Color.accentColor.opacity(0.1) : secondarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(current ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(current ? .isSelected : [])
    }

    private var leaderboardSection: some View {
        let thresholds = leaguesService.leagueThresholds(for: userProfile)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(localized("This Week")).font(.title3.bold())
                Spacer()
                Text("XP").font(.caption.bold()).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            LazyVStack(spacing: 6) {
                ForEach(leaderboardData) { entry in
                    if entry.position == thresholds.promote.lowerBound, userProfile.currentLeague.leagueAbove != nil {
                        zoneLabel("ЗОНА ПОВЫШЕНИЯ", range: thresholds.promote, color: .green, symbol: "arrow.up.right")
                    }
                    if let demote = thresholds.demote, entry.position == demote.lowerBound, userProfile.currentLeague.leagueBelow != nil {
                        zoneLabel("ЗОНА ВЫЛЕТА", range: demote, color: .red, symbol: "arrow.down.right")
                    }
                    LeaderboardRow(entry: entry, isHighlighted: entry.isCurrentUser)
                        .id(entry.id)
                        .background(secondarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier(entry.isCurrentUser ? "leagues.currentUser" : "leagues.row.\(entry.position)")
                    if entry.position == thresholds.promote.upperBound {
                        Divider().padding(.vertical, 6)
                    }
                }
            }
        }
        .accessibilityIdentifier("leagues.leaderboard")
    }

    private func zoneLabel(_ key: String, range: ClosedRange<Int>, color: Color, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(localized(key)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("\(range.lowerBound)–\(range.upperBound)").monospacedDigit()
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func generateLeaderboardData() {
        leaderboardData = leaguesService.leaderboardEntries(for: userProfile.currentLeague, userProfile: userProfile)
        if let userEntry = leaderboardData.first(where: { $0.isCurrentUser }) {
            userProfile.leaguePosition = userEntry.position
            leaguesService.saveCurrentWeekResult(position: userEntry.position, league: userProfile.currentLeague)
        }
    }

    @MainActor
    private func refreshLeaguesContent() async {
        leaguesService.tickCompetitors(for: userProfile.currentLeague)
        generateLeaderboardData()
    }

    private func checkPreviousWeekAndShowPopupIfNeeded() {
        guard let prev = leaguesService.takePreviousWeekResultIfNeeded() else { return }
        let place = prev.position
        let league = prev.league
        let thresholds = leaguesService.leagueThresholds(for: userProfile)
        var newLeague = league
        var outcome: LeagueEndOutcome = .stayed
        if thresholds.promote.contains(place), let up = league.leagueAbove {
            newLeague = up
            outcome = .promoted
            userProfile.addFBucks(1, reason: .leagueReward)
        } else if let demoteRange = thresholds.demote, demoteRange.contains(place), let down = league.leagueBelow {
            newLeague = down
            outcome = .demoted
        }
        userProfile.currentLeague = newLeague
        leaguesService.buildAndSaveWeeklyResult(
            position: place,
            leagueBefore: league,
            newLeague: newLeague,
            outcome: outcome,
            userProfile: userProfile
        )
        showingWeeklyResultModal = true
    }
    
    private func timeRemainingStringGMT() -> String {
        let calendar = Calendar(identifier: .gregorian)
        var cal = calendar
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        // Понедельник 00:00 GMT текущей недели
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let startOfWeek = cal.date(from: components) ?? now
        let nextWeekStart = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        let remaining = max(0, nextWeekStart.timeIntervalSince(now))
        
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        var timeString = ""
        if days > 0 {
            timeString += "\(days)\(localizationManager.localizedString("д")) "
        }
        timeString += "\(hours)\(localizationManager.localizedString("ч"))"
        if minutes > 0 {
            timeString += " \(minutes)\(localizationManager.localizedString("м"))"
        }
        
        return String(format: localizationManager.localizedString("До конца лиги: %@ (GMT)"), timeString)
    }

    /// Горизонтальная лента лиг: при открытии показываем текущую лигу слева (как первую видимую).
    private func scrollLeaguesStripToCurrentLeague(proxy: ScrollViewProxy) {
        let current = userProfile.currentLeague
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(current, anchor: .leading)
            }
        }
    }
}

// MARK: - League weekly modal (celebration / calm / demotion)

private enum LeagueWeeklyModalTier {
    case hero
    case nice
    case calm
    case demoted
}

private func leagueWeeklyModalPlayCelebrationFeedback() {
    #if os(iOS)
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.success)
    AudioServicesPlaySystemSound(1025)
    #endif
}

private struct LeagueWeeklyConfettiView: View {
    let pieceCount: Int
    let seed: Int

    private func rng(_ i: Int) -> UInt64 {
        var x = UInt64(bitPattern: Int64(seed &+ i &* 6364136223846793005))
        x ^= x >> 12
        x &*= 0x2545F4914F6CDD1D
        x ^= x >> 16
        return x
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(0..<pieceCount, id: \.self) { i in
                    let r = rng(i)
                    let colors: [Color] = [.yellow, .orange, .pink, .mint, .cyan, .white, .green]
                    let color = colors[Int(r % UInt64(colors.count))]
                    let size = CGFloat(5 + Int(r % 6))
                    let x = CGFloat(r % 1000) / 1000 * w
                    let startY = -CGFloat(Int(r % 400)) - 20
                    LeagueConfettiPiece(color: color, size: size, x: x, startY: startY, fallDistance: h + 120, delay: Double(i % 12) * 0.04, duration: 2.2 + Double(r % 80) / 100)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct LeagueConfettiPiece: View {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let startY: CGFloat
    let fallDistance: CGFloat
    let delay: Double
    let duration: Double
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: startY + offsetY)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: duration)) {
                        offsetY = fallDistance
                        rotation = Double.random(in: 120...420)
                        opacity = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.25) {
                        withAnimation(.easeOut(duration: duration * 0.75)) {
                            opacity = 0
                        }
                    }
                }
            }
    }
}

private struct LeagueWeeklyModalBackground: View {
    let tier: LeagueWeeklyModalTier

    var body: some View {
        ZStack {
            Group {
                switch tier {
                case .hero:
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.04, blue: 0.28),
                            Color(red: 0.32, green: 0.10, blue: 0.48),
                            Color(red: 0.92, green: 0.38, blue: 0.18),
                            Color(red: 0.98, green: 0.72, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                case .nice:
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.12, blue: 0.32),
                            Color(red: 0.22, green: 0.18, blue: 0.52),
                            Color(red: 0.45, green: 0.28, blue: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                case .calm:
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.22),
                            Color(red: 0.18, green: 0.20, blue: 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                case .demoted:
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.18),
                            Color(red: 0.16, green: 0.18, blue: 0.26)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()

            RadialGradient(
                colors: [.white.opacity(tier == .hero ? 0.22 : 0.12), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - League Weekly Result Modal
struct LeagueWeeklyResultModalView: View {
    let result: LeagueWeeklyResult
    let onDismiss: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var badgeScale: CGFloat = 0.78
    @State private var badgeGlow: Double = 0.35
    @State private var showRewardLine = false
    @State private var ctaPulse = false
    @State private var didPlayCelebrationFeedback = false

    private var tier: LeagueWeeklyModalTier {
        if result.movement == "demoted" { return .demoted }
        if result.movement == "promoted" || result.podiumPlace == 1 || result.finalRank == 1 {
            return .hero
        }
        if (2...3).contains(result.finalRank) { return .nice }
        return .calm
    }

    private var titleKey: String {
        if result.podiumPlace == 1 { return "league.weekly_result.title.win" }
        switch result.movement {
        case "promoted": return "league.weekly_result.title.promotion"
        case "stayed": return "league.weekly_result.title.stayed"
        case "demoted": return "league.weekly_result.title.demotion"
        default: return "league.weekly_result.title.stayed"
        }
    }

    private var bodyText: String {
        let rank = result.finalRank
        let leagueName = result.leagueAfter?.localizedName ?? ""
        if result.podiumPlace == 1 {
            return String(format: localizationManager.localizedString("league.weekly_result.body.win"), rank)
        }
        switch result.movement {
        case "promoted":
            return String(format: localizationManager.localizedString("league.weekly_result.body.promotion"), rank, leagueName)
        case "stayed":
            return String(format: localizationManager.localizedString("league.weekly_result.body.stayed"), rank, leagueName)
        case "demoted":
            return String(format: localizationManager.localizedString("league.weekly_result.body.demotion"), rank, leagueName)
        default:
            return String(format: localizationManager.localizedString("league.weekly_result.body.stayed"), rank, leagueName)
        }
    }

    private var hasReward: Bool {
        result.rewardBucks > 0 || result.rewardCoins > 0 || result.rewardXp > 0
    }

    private var subtitleForCelebration: String {
        let r = result.finalRank
        if (1...3).contains(r) {
            let useA = abs(result.weekId.hashValue) % 2 == 0
            if useA {
                return String(format: localizationManager.localizedString("league.weekly_result.promotion.subtitle.top3_a"), r)
            }
            return localizationManager.localizedString("league.weekly_result.promotion.subtitle.top3_b")
        }
        return String(format: localizationManager.localizedString("league.weekly_result.promotion.subtitle.other"), r)
    }

    private var nextMotivationLine: String? {
        guard tier != .demoted, let after = result.leagueAfter else { return nil }
        if let next = after.leagueAbove {
            if abs(result.weekId.hashValue) % 2 == 0 {
                return String(format: localizationManager.localizedString("league.weekly_result.next_goal"), next.localizedName)
            }
            return localizationManager.localizedString("league.weekly_result.next_goal.alt")
        }
        return localizationManager.localizedString("league.weekly_result.next_goal.pinnacle")
    }

    private var primaryCtaTitle: String {
        if tier == .demoted {
            return localizationManager.localizedString("league.weekly_result.demotion.cta")
        }
        if tier == .calm {
            return localizationManager.localizedString("league.weekly_result.stayed.cta")
        }
        if let after = result.leagueAfter, let next = after.leagueAbove {
            return String(format: localizationManager.localizedString("league.weekly_result.cta.toward_league_arrow"), next.localizedName)
        }
        return localizationManager.localizedString("league.weekly_result.cta.keep_playing_arrow")
    }

    private var confettiSeed: Int {
        abs(result.weekId.hashValue ^ result.finalRank.hashValue)
    }

    var body: some View {
        ZStack {
            LeagueWeeklyModalBackground(tier: tier)

            if tier == .hero {
                LeagueWeeklyConfettiView(pieceCount: 52, seed: confettiSeed)
                    .ignoresSafeArea()
            } else if tier == .nice {
                LeagueWeeklyConfettiView(pieceCount: 22, seed: confettiSeed &+ 17)
                    .ignoresSafeArea()
            }

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        VStack(spacing: 18) {
                            if tier == .hero || tier == .nice {
                                celebrationHeader
                            } else {
                                calmHeader
                            }

                            if hasReward {
                                rewardBlock
                            }

                            if let line = nextMotivationLine, tier == .hero || tier == .nice {
                                Text(line)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.95))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                            }

                            if tier == .calm || tier == .demoted {
                                Text(localizationManager.localizedString(result.motivationMessageCode))
                                    .font(.system(size: 14, weight: .medium))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.65))
                                    .padding(.horizontal, 20)
                            }

                            primaryButton
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                        }
                        .frame(maxWidth: 520)
                        .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            runEntranceAnimations()
        }
    }

    @ViewBuilder
    private var celebrationHeader: some View {
        if result.movement == "promoted", let after = result.leagueAfter {
            Text(localizationManager.localizedString("league.weekly_result.promotion.tagline"))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.orange)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
            Text(String(
                format: localizationManager.localizedString("league.weekly_result.promotion.title"),
                locale: localizationManager.currentLocale,
                after.localizedName.uppercased(with: localizationManager.currentLocale)
            ))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 16)
        } else if result.finalRank == 1 || result.podiumPlace == 1 {
            Text(localizationManager.localizedString("league.weekly_result.win.hero"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        } else if tier == .nice {
            Text(String(format: localizationManager.localizedString("league.weekly_result.nice.title"), result.finalRank))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }

        if let after = result.leagueAfter {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [after.color.opacity(0.55), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                    .opacity(badgeGlow)

                Image(after.imageAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: tier == .nice ? 100 : 124, height: tier == .nice ? 100 : 124)
                    .scaleEffect(badgeScale)
                    .shadow(color: after.color.opacity(0.85), radius: 28, x: 0, y: 10)
                    .shadow(color: .white.opacity(0.35), radius: 12, x: 0, y: 0)
            }
            .padding(.vertical, 8)
        }

        if tier == .hero {
            Text(subtitleForCelebration)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var calmHeader: some View {
        VStack(spacing: 12) {
            Text(localizationManager.localizedString(titleKey))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(bodyText)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.78))
                .padding(.horizontal)
            if let after = result.leagueAfter {
                HStack(spacing: 8) {
                    Text(localizationManager.localizedString("league.weekly_result.label.new_league"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text(after.localizedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var rewardBlock: some View {
        Group {
            if result.rewardBucks > 0 {
                Text(String(format: localizationManager.localizedString("league.weekly_result.reward.fbucks"), result.rewardBucks))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 0.92, blue: 0.45))
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                    .scaleEffect(showRewardLine ? 1 : 0.3)
                    .opacity(showRewardLine ? 1 : 0)
            }
            HStack(spacing: 14) {
                if result.rewardCoins > 0 {
                    Text("+\(result.rewardCoins) \(localizationManager.localizedString("coins"))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                if result.rewardXp > 0 {
                    Text("+\(result.rewardXp) XP")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    private var primaryButton: some View {
        Button(action: onDismiss) {
            Group {
                if tier == .demoted {
                    HStack(spacing: 8) {
                        Text(primaryCtaTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color.orange, Color.red.opacity(0.92)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        HStack(spacing: 8) {
                            Text(primaryCtaTitle)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.orange.opacity(ctaPulse ? 0.55 : 0.32), radius: ctaPulse ? 20 : 12, x: 0, y: ctaPulse ? 10 : 6)
                    .scaleEffect(ctaPulse ? 1.03 : 1.0)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func runEntranceAnimations() {
        let h = tier == .hero
        if h || tier == .nice {
            if h && !didPlayCelebrationFeedback {
                didPlayCelebrationFeedback = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    leagueWeeklyModalPlayCelebrationFeedback()
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                badgeScale = 1.22
                badgeGlow = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    badgeScale = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    showRewardLine = true
                }
            }
        } else {
            badgeScale = 1.0
            badgeGlow = 0.5
            showRewardLine = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                ctaPulse = true
            }
        }
    }
}

enum LeagueEndOutcome {
    case promoted
    case stayed
    case demoted
}

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let position: Int
    let username: String
    let avatar: String
    let xp: Int
    let streak: Int
    let isCurrentUser: Bool
    let countryFlag: String
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Position
            Text("\(entry.position)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(positionColor)
                .monospacedDigit()
                .frame(width: 28, height: 32)
                .background(positionColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if entry.isCurrentUser {
                    // For current user, show their actual avatar
                    if entry.avatar.hasPrefix("🇺🇦") || entry.avatar.hasPrefix("🇷🇺") || entry.avatar.hasPrefix("🇺🇸") || entry.avatar.hasPrefix("🇪🇸") || entry.avatar.hasPrefix("🇨🇳") {
                        // If it's a flag emoji, display it
                        Text(entry.avatar)
                            .font(.system(size: 20))
                    } else if entry.avatar.hasPrefix("person.") || entry.avatar.hasPrefix("face.") || entry.avatar.hasPrefix("graduationcap.") || entry.avatar.hasPrefix("star.") || entry.avatar.hasPrefix("heart.") || entry.avatar.hasPrefix("crown.") || entry.avatar.hasPrefix("gamecontroller.") {
                        // If it's a system icon, display it
                        Image(systemName: entry.avatar)
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    } else if entry.avatar.hasPrefix("custom_") {
                        // If it's a custom avatar, show initials
                        Text(String(entry.username.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        // If it's initials or other custom avatar, show as text
                        Text(String(entry.username.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    }
                } else {
                    // For other users: SF Symbol by name, else emoji/flag as text (avoid "?" from Image(systemName: emoji))
                    if entry.avatar.contains(".") {
                        Image(systemName: entry.avatar)
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    } else {
                        Text(entry.avatar)
                            .font(.system(size: 20))
                    }
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.subheadline.weight(isHighlighted ? .bold : .medium))
                        .lineLimit(1).truncationMode(.tail)
                        .foregroundColor(.primary)
                    
                    Text(entry.countryFlag)
                        .font(.system(size: 14))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                    
                    Text("\(entry.streak)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 4)
            
            // XP
            Text("\(entry.xp) \(LocalizationManager.shared.localizedString("XP"))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                .layoutPriority(1)
                .foregroundColor(isHighlighted ? .accentColor : .primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHighlighted ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private var positionColor: Color {
        switch entry.position {
        case 1: return .orange
        case 2: return .gray
        case 3: return .brown
        default: return .primary
        }
    }
}

#Preview {
    LeaguesView()
        .environmentObject(UserProfile.shared)
}
