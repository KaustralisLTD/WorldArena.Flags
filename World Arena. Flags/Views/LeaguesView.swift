import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct LeaguesView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var showingDemotionZone = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var safeTopInset: CGFloat = 0
    @State private var containerSize: CGSize = .zero
    @State private var now: Date = Date()
    @ObservedObject private var leaguesService = LeaguesService.shared
    @State private var showingLeagueEndPopup = false
    @State private var leagueEndPlace: Int = 0
    @State private var leagueEndOutcome: LeagueEndOutcome = .stayed
    @State private var leagueEndNewLeague: League?
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    
    private var isIPadLandscape: Bool {
        guard isIPad else { return false }
        #if os(iOS)
        if verticalSizeClass == .compact { return true }
        let size = containerSize.width > 0 ? containerSize : UIScreen.main.bounds.size
        return size.width > size.height
        #else
        return false
        #endif
    }
    
    private var headerHeightLandscape: CGFloat {
        92 + safeTopInset
    }
    
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
    
    var body: some View {
        ZStack(alignment: .top) {
                // Базовый фон под всем контентом, чтобы не было черных полос
                systemGroupedBackground
                    .ignoresSafeArea()

                if !isIPadLandscape { headerBackground }

                if isIPadLandscape {
                    // iPad альбомная: ScrollView на весь экран, шапка оверлеем — без белой полосы под шапкой
                    ZStack(alignment: .top) {
                        ScrollViewReader { proxy in
                            ScrollView {
                                leaderboardSection
                                    .padding(.top, headerHeightLandscape - 28)
                            }
                            .modifier(LeaguesHideScrollContentBackgroundModifier())
                            .background(systemGroupedBackground.ignoresSafeArea())
                            .onAppear { scrollToUserIfNeeded(proxy: proxy) }
                            .onChange(of: leaderboardData.count) { _ in scrollToUserIfNeeded(proxy: proxy) }
                        }
                        headerSectionCompact
                    }
                } else {
                    VStack(spacing: 0) {
                        headerSection
                        ScrollViewReader { proxy in
                            ScrollView {
                                leaderboardSection
                                    .padding(.top, contentTopInset)
                            }
                            .background(systemGroupedBackground)
                            .onAppear { scrollToUserIfNeeded(proxy: proxy) }
                            .onChange(of: leaderboardData.count) { _ in scrollToUserIfNeeded(proxy: proxy) }
                        }
                    }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: LeaguesSafeTopInsetKey.self, value: geo.safeAreaInsets.top)
                        .preference(key: LeaguesContainerSizeKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(LeaguesSafeTopInsetKey.self) { value in
                safeTopInset = value
            }
            .onPreferenceChange(LeaguesContainerSizeKey.self) { value in
                containerSize = value
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            #endif
            .onAppear {
                // Прозрачный навбар, чтобы не было чёрной полосы
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
                checkPreviousWeekAndShowPopupIfNeeded()
                generateLeaderboardData()
            }
            .onDisappear {
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { date in
                now = date
                generateLeaderboardData()
            }
            .alert(localizationManager.localizedString("Итоги лиги"), isPresented: $showingLeagueEndPopup) {
                Button(localizationManager.localizedString("OK")) { showingLeagueEndPopup = false }
            } message: {
                Text(leagueEndPopupMessage)
            }
    }

    private var leagueEndPopupMessage: String {
        let placeStr = String(format: localizationManager.localizedString("Вы заняли %d место."), leagueEndPlace)
        switch leagueEndOutcome {
        case .promoted:
            let leagueName = leagueEndNewLeague?.localizedName ?? ""
            return placeStr + " " + String(format: localizationManager.localizedString("Вы поднялись в лигу: %@"), leagueName)
        case .stayed:
            return placeStr + " " + localizationManager.localizedString("Вы остались в текущей лиге.")
        case .demoted:
            let leagueName = leagueEndNewLeague?.localizedName ?? ""
            return placeStr + " " + String(format: localizationManager.localizedString("Вы понижены в лигу: %@"), leagueName)
        }
    }
    
    // Новый закрепленный header по образцу страницы Квестов
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                     Text(localizationManager.localizedString("Лиги"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(userProfile.currentLeague.localizedName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(timeRemainingStringGMT())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text("🏆")
                    .font(.system(size: 36))
                    .padding(.trailing, 8)
            }
            .padding(.leading, 24)
            .padding(.trailing, 12)
            .padding(.top, max(0, safeTopInset - 60))

            // Горизонтальный скролл по всем лигам с выделением текущей
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(League.allCases, id: \.self) { league in
                        let isCurrent = league == userProfile.currentLeague
                        VStack(spacing: 6) {
                            // Убрал лого над текстом активной лиги
                            HStack(spacing: 6) {
                                Image(systemName: league.icon)
                                    .font(.system(size: isCurrent ? 16 : 14, weight: .semibold)) // Разные размеры для активной и неактивной
                                Text(league.localizedFullName)
                                    .font(.system(size: isCurrent ? 14 : 13, weight: .semibold)) // Разные размеры для активной и неактивной
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(maxWidth: 120)
                            }
                            .padding(.horizontal, isCurrent ? 14 : 12) // Больше отступы для активной
                            .padding(.vertical, isCurrent ? 10 : 8) // Больше отступы для активной
                            .background(
                                Capsule()
                                    .fill(isCurrent ? Color.white.opacity(0.25) : Color.white.opacity(0.08)) // Более яркий фон для активной
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isCurrent ? Color.white.opacity(0.9) : Color.white.opacity(0.2), lineWidth: isCurrent ? 2 : 1) // Толще граница для активной
                            )
                            .foregroundColor(.white)
                        }
                        .onTapGesture {
                            // Только текущая лига кликабельна
                            if isCurrent {
                                // Можно добавить анимацию или другой эффект
                            }
                        }
                    }
                }
                .padding(.horizontal, isIPad ? 40 : 20)
            }
            .padding(.bottom, 16)
        }
        .frame(height: 160 + safeTopInset, alignment: .top)
    }
    
    /// Шапка для iPad альбомная: градиент и контент в одном view, оверлей поверх скролла
    private var headerSectionCompact: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.localizedString("Лиги"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(userProfile.currentLeague.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(timeRemainingStringGMT())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text("🏆")
                    .font(.system(size: 28))
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(League.allCases, id: \.self) { league in
                        let isCurrent = league == userProfile.currentLeague
                        HStack(spacing: 4) {
                            Image(systemName: league.icon)
                                .font(.system(size: isCurrent ? 14 : 12, weight: .semibold))
                            Text(league.localizedFullName)
                                .font(.system(size: isCurrent ? 12 : 11, weight: .semibold))
                                .lineLimit(1)
                                .frame(maxWidth: 80)
                        }
                        .padding(.horizontal, isCurrent ? 10 : 8)
                        .padding(.vertical, isCurrent ? 6 : 4)
                        .background(Capsule().fill(isCurrent ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(isCurrent ? Color.white.opacity(0.9) : Color.white.opacity(0.2), lineWidth: isCurrent ? 2 : 1))
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 4)
        }
        .padding(.top, max(0, safeTopInset - 16))
        .frame(height: headerHeightLandscape, alignment: .top)
        .background(
            ZStack {
                Color(red: 0.45, green: 0.28, blue: 0.88)
                LinearGradient(
                    colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }
    
    private var contentTopInset: CGFloat {
        // Минимальный отступ, чтобы не было большого зазора при оттягивании списка
        return 12
    }

    private var headerBackground: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 180 + safeTopInset)
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
        .mask(
            Rectangle()
                .padding(.top, -20)
        )
        .ignoresSafeArea(.container, edges: .top)
    }
    
    private var leaderboardSection: some View {
        VStack(spacing: 0) {
            // Leaderboard entries
            LazyVStack(spacing: 1) {
                ForEach(leaderboardData.indices, id: \.self) { index in
                    let entry = leaderboardData[index]
                    
                    LeaderboardRow(
                        entry: entry,
                        isHighlighted: entry.isCurrentUser
                    )
                    .id(entry.id)
                    .background(getRowBackground(for: entry.position))
                    
                    // Разделители зон
                    if index == 4 {
                        // Маркер зоны повышения — ПОД 5 местом
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                            Text(LocalizationManager.shared.localizedString("ЗОНА ПОВЫШЕНИЯ"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .padding(.horizontal, isIPad ? 40 : 20)
                    } else if index == 14 {
                        // Начало зоны вылета
                        Divider()
                            .background(Color.red.opacity(0.5))
                            .padding(.horizontal, isIPad ? 40 : 20)
                        
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.red)
                            Text(LocalizationManager.shared.localizedString("ЗОНА ВЫЛЕТА"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                            Image(systemName: "arrow.down")
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func generateLeaderboardData() {
        leaderboardData = leaguesService.leaderboardEntries(for: userProfile.currentLeague, userProfile: userProfile)
        if let userEntry = leaderboardData.first(where: { $0.isCurrentUser }) {
            userProfile.leaguePosition = userEntry.position
            leaguesService.saveCurrentWeekResult(position: userEntry.position, league: userProfile.currentLeague)
        }
    }

    private func checkPreviousWeekAndShowPopupIfNeeded() {
        guard let prev = leaguesService.takePreviousWeekResultIfNeeded() else { return }
        let place = prev.position
        let league = prev.league
        var newLeague = league
        var outcome: LeagueEndOutcome = .stayed
        if (1...5).contains(place), let up = league.leagueAbove {
            newLeague = up
            outcome = .promoted
        } else if (16...20).contains(place), let down = league.leagueBelow {
            newLeague = down
            outcome = .demoted
        }
        userProfile.currentLeague = newLeague
        leagueEndPlace = place
        leagueEndOutcome = outcome
        leagueEndNewLeague = (outcome != .stayed ? newLeague : nil)
        showingLeagueEndPopup = true
    }
    
    private func getRowBackground(for position: Int) -> Color {
        switch position {
        case 1...5:
            return Color.green.opacity(0.05) // Зона повышения
        case 16...20:
            return Color.red.opacity(0.05)   // Зона вылета
        default:
            return secondarySystemGroupedBackground // Безопасная зона
        }
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

    private func scrollToUserIfNeeded(proxy: ScrollViewProxy) {
        if let user = leaderboardData.first(where: { $0.isCurrentUser }) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    proxy.scrollTo(user.id, anchor: .center)
                }
            }
        }
    }
}

// PreferenceKey для передачи safe area inset сверху (локально для LeaguesView)
private struct LeaguesSafeTopInsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct LeaguesContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct LeaguesHideScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
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
                .frame(width: 30, alignment: .leading)
            
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
                    // For other users, show system icon
                    Image(systemName: entry.avatar)
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 16, weight: isHighlighted ? .semibold : .medium))
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
            
            Spacer()
            
            // XP
            Text("\(entry.xp) \(LocalizationManager.shared.localizedString("XP"))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
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
        case 1: return .red
        case 2: return .green
        case 3: return .orange
        case 16...20: return .red
        default: return .primary
        }
    }
}

#Preview {
    LeaguesView()
        .environmentObject(UserProfile.shared)
}
