import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct MainTabView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var userProfile = UserProfile.shared
    @State private var selectedTab = 0
    @State private var pendingNudgeAlert: NudgeFromAPI?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var systemGray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    private var isNavigatingToGameBinding: Binding<Bool> {
        Binding(
            get: { gameState.isNavigatingToGame },
            set: { gameState.isNavigatingToGame = $0 }
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(iOS)
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad ||
                        (horizontalSizeClass == .regular && (verticalSizeClass == .regular || geometry.size.width > 768))
            #else
            let isIPad = horizontalSizeClass == .regular && (verticalSizeClass == .regular || geometry.size.width > 768)
            #endif
            Group {
                if isIPad {
                    iPadMainLayout()
                } else {
                    iPhoneMainLayout()
                }
            }
        }
        .environmentObject(gameState)
        .environmentObject(userProfile)
        .fullScreenCover(isPresented: isNavigatingToGameBinding) {
            GameView()
                .environmentObject(gameState)
                .environmentObject(userProfile)
        }
        .onAppear {
            Task {
                await fetchIncomingDuelChallenges()
                await registerAndSaveFriendCodeIfNeeded()
                await refreshFriendsDisplayNames()
                await checkNudgeInbox()
            }
        }
        .onChange(of: userProfile.selectedCountryCode) { _ in
            Task { await registerAndSaveFriendCodeIfNeeded() }
        }
        .alert(
            localizationManager.localizedString("%@ reminds you").replacingOccurrences(of: "%@", with: pendingNudgeAlert?.fromUsername ?? ""),
            isPresented: Binding(
                get: { pendingNudgeAlert != nil },
                set: { if !$0 { pendingNudgeAlert = nil } }
            )
        ) {
            Button(localizationManager.localizedString("CONTINUE")) {
                if let _ = pendingNudgeAlert {
                    Task {
                        try? await DuelAPIService.shared.markNudgesRead(userId: userProfile.username)
                    }
                }
                pendingNudgeAlert = nil
            }
        } message: {
            if let nudge = pendingNudgeAlert {
                Text(localizationManager.localizedString(nudge.phraseLocalizationKey))
            }
        }
    }

    private func checkNudgeInbox() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let inbox = try? await DuelAPIService.shared.fetchNudgeInbox(userId: userId), let first = inbox.first else { return }
        await MainActor.run { pendingNudgeAlert = first }
    }

    private func registerAndSaveFriendCodeIfNeeded() async {
        let name = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard let code = try? await DuelAPIService.shared.registerUser(
            userId: name,
            username: name,
            deviceToken: nil,
            stats: ["level": userProfile.level, "xp": userProfile.xp, "streak": userProfile.streak],
            countryCode: userProfile.selectedCountryCode
        ) else { return }
        UserDefaults.standard.set(code, forKey: "user.serverFriendCode")
    }
    
    private func fetchIncomingDuelChallenges() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let list = try? await DuelAPIService.shared.fetchIncomingChallenges(userId: userId) else { return }
        let existingIds = Set(userProfile.incomingDuelChallenges.map(\.id))
        let newOnes = list.compactMap { $0.toDuelChallenge(opponentId: userId, opponentName: userId) }
            .filter { !existingIds.contains($0.id) }
        guard !newOnes.isEmpty else { return }
        await MainActor.run {
            userProfile.incomingDuelChallenges.append(contentsOf: newOnes)
        }
    }

    /// Обновить отображаемые имена друзей с сервера (после смены имени другом у него обновится имя у нас).
    private func refreshFriendsDisplayNames() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let fromAPI = try? await DuelAPIService.shared.fetchMyFriends(userId: userId) else { return }
        await MainActor.run {
            for apiFriend in fromAPI {
                if let idx = userProfile.friends.firstIndex(where: { $0.username == apiFriend.username }) {
                    let old = userProfile.friends[idx]
                    let fromAPI = apiFriend.toFriend()
                    userProfile.friends[idx] = Friend(
                        id: old.id,
                        username: old.username,
                        displayName: apiFriend.displayName ?? fromAPI.displayName,
                        avatar: fromAPI.avatar,
                        countryCode: fromAPI.countryCode,
                        level: apiFriend.level,
                        xp: apiFriend.xp,
                        streak: apiFriend.streak,
                        isOnline: old.isOnline,
                        joinDate: old.joinDate
                    )
                } else {
                    userProfile.friends.append(apiFriend.toFriend())
                }
            }
            userProfile.saveToStorage()
        }
    }
    
    @ViewBuilder
    private func iPhoneMainLayout() -> some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                // Горизонтальная ориентация - боковое меню слева
                iPhoneLandscapeLayout()
            } else {
                // Вертикальная ориентация - стандартное нижнее меню
                iPhonePortraitLayout()
            }
        }
    }
    
    @ViewBuilder
    private func iPhonePortraitLayout() -> some View {
        NavigationView {
            TabView(selection: $selectedTab) {
            // Базовый план
            if !gameState.isPremium {
                ContentView(gameState: gameState)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "play.fill" : "play")
                        Text(LocalizationManager.shared.localizedString("Игра"))
                    }
                    .tag(0)
                
                MonthlyQuestsView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.exclamationmark" : "calendar")
                        Text(LocalizationManager.shared.localizedString("Квесты"))
                    }
                    .tag(1)
                
                LeaguesView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "trophy.fill" : "trophy")
                        Text(LocalizationManager.shared.localizedString("Лиги"))
                    }
                    .tag(2)
                
                StatisticsView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                        Text(LocalizationManager.shared.localizedString("Статистика"))
                    }
                    .tag(3)
                
                NavigationView {
                    ProfileView(selectedTab: $selectedTab)
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text(LocalizationManager.shared.localizedString("Профиль"))
                }
                .tag(4)
            } else {
                // Премиум план
                ContentView(gameState: gameState)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "play.fill" : "play")
                        Text(LocalizationManager.shared.localizedString("Игра"))
                    }
                    .tag(0)
                
                MonthlyQuestsView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.exclamationmark" : "calendar")
                        Text(LocalizationManager.shared.localizedString("Квесты"))
                    }
                    .tag(1)
                
                LearningView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "book.fill" : "book")
                        Text(LocalizationManager.shared.localizedString("Обучение"))
                    }
                    .tag(2)
                
                LeaguesView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "trophy.fill" : "trophy")
                        Text(LocalizationManager.shared.localizedString("Лиги"))
                    }
                    .tag(3)
                
                NavigationView {
                    ProfileView(selectedTab: $selectedTab)
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text(LocalizationManager.shared.localizedString("Профиль"))
                }
                .tag(4)
            }
            }
            .accentColor(.blue)
        }
        #if os(iOS)
        .navigationViewStyle(.stack) // Используем stack style для iPhone
        #endif
    }
    
    @ViewBuilder
    private func iPhoneLandscapeLayout() -> some View {
        HStack(spacing: 0) {
            // Боковое меню слева
            VStack(spacing: 8) {
                // Игра
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 0 ? "play.fill" : "play")
                            .font(.system(size: 20))
                        Text(LocalizationManager.shared.localizedString("Игра"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
                }
                .frame(width: 60, height: 50)
                
                // Квесты
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.exclamationmark" : "calendar")
                            .font(.system(size: 20))
                        Text(LocalizationManager.shared.localizedString("Квесты"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == 1 ? .blue : .gray)
                }
                .frame(width: 60, height: 50)
                
                // Обучение (только для премиум)
                if gameState.isPremium {
                    Button(action: { selectedTab = 2 }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 2 ? "book.fill" : "book")
                                .font(.system(size: 20))
                            Text(LocalizationManager.shared.localizedString("Обучение"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == 2 ? .blue : .gray)
                    }
                    .frame(width: 60, height: 50)
                }
                
                // Лиги
                Button(action: { selectedTab = gameState.isPremium ? 3 : 2 }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == (gameState.isPremium ? 3 : 2) ? "trophy.fill" : "trophy")
                            .font(.system(size: 20))
                        Text(LocalizationManager.shared.localizedString("Лиги"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == (gameState.isPremium ? 3 : 2) ? .blue : .gray)
                }
                .frame(width: 60, height: 50)
                
                // Статистика
                Button(action: { selectedTab = gameState.isPremium ? 4 : 3 }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == (gameState.isPremium ? 4 : 3) ? "chart.bar.fill" : "chart.bar")
                            .font(.system(size: 20))
                        Text(LocalizationManager.shared.localizedString("Статистика"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == (gameState.isPremium ? 4 : 3) ? .blue : .gray)
                }
                .frame(width: 60, height: 50)
                
                // More (только для премиум) или Профиль
                if gameState.isPremium {
                    Button(action: { selectedTab = 4 }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 4 ? "ellipsis" : "ellipsis")
                                .font(.system(size: 20))
                            Text(LocalizationManager.shared.localizedString("More"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == 4 ? .blue : .gray)
                    }
                    .frame(width: 60, height: 50)
                } else {
                    // Профиль для не-премиум
                    Button(action: { selectedTab = 4 }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                                .font(.system(size: 20))
                            Text(LocalizationManager.shared.localizedString("Профиль"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == 4 ? .blue : .gray)
                    }
                    .frame(width: 60, height: 50)
                }
                
                Spacer()
            }
            .frame(width: 80)
                    .background(systemGroupedBackground)
            
            // Основной контент справа
            Group {
                switch selectedTab {
                case 0:
                    ContentView(gameState: gameState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case 1:
                    MonthlyQuestsView()
                case 2:
                    if gameState.isPremium {
                        LearningView()
                    } else {
                        LeaguesView()
                    }
                case 3:
                    if gameState.isPremium {
                        LeaguesView()
                    } else {
                        StatisticsView()
                    }
                case 4:
                    if gameState.isPremium {
                        MoreMenuView(selectedTab: $selectedTab)
                    } else {
                        ProfileView(selectedTab: $selectedTab)
                    }
                case 5:
                    ProfileView(selectedTab: $selectedTab)
                case 6:
                    StatisticsView()
                default:
                    ContentView(gameState: gameState)
                }
            }
        }
    }
    
    @ViewBuilder
    private func iPadMainLayout() -> some View {
        // Полная ширина экрана на iPad (не ограничивать как на телефоне)
        iPadPortraitLayout()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func iPadPortraitLayout() -> some View {
        // Без NavigationView — на iPad он даёт боковую колонку (split); контент на весь экран как у Quests
        TabView(selection: $selectedTab) {
            // Базовый план
            if !gameState.isPremium {
                ContentView(gameState: gameState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "play.fill" : "play")
                        Text(LocalizationManager.shared.localizedString("Игра"))
                    }
                    .tag(0)
                
                MonthlyQuestsView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.exclamationmark" : "calendar")
                        Text(LocalizationManager.shared.localizedString("Квесты"))
                    }
                    .tag(1)
                
                LeaguesView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "trophy.fill" : "trophy")
                        Text(LocalizationManager.shared.localizedString("Лиги"))
                    }
                    .tag(2)
                
                StatisticsView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                        Text(LocalizationManager.shared.localizedString("Статистика"))
                    }
                    .tag(3)
                
                ProfileView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text(LocalizationManager.shared.localizedString("Профиль"))
                    }
                    .tag(4)
            } else {
                // Премиум план
                ContentView(gameState: gameState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "play.fill" : "play")
                        Text(LocalizationManager.shared.localizedString("Игра"))
                    }
                    .tag(0)
                
                MonthlyQuestsView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.exclamationmark" : "calendar")
                        Text(LocalizationManager.shared.localizedString("Квесты"))
                    }
                    .tag(1)
                
                LearningView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "book.fill" : "book")
                        Text(LocalizationManager.shared.localizedString("Обучение"))
                    }
                    .tag(2)
                
                LeaguesView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "trophy.fill" : "trophy")
                        Text(LocalizationManager.shared.localizedString("Лиги"))
                    }
                    .tag(3)
                
                ProfileView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text(LocalizationManager.shared.localizedString("Профиль"))
                    }
                    .tag(4)
            }
            }
            .accentColor(.blue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    UITabBar.appearance().itemPositioning = .centered
                    UITabBar.appearance().itemSpacing = 20
                }
                #endif
            }
    }
}

// MARK: - More Menu View
struct MoreMenuView: View {
    @Binding var selectedTab: Int
    @State private var showingActionSheet = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var systemGray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // Удаляем кнопку 'More'
            // Text(localizationManager.localizedString("More"))
            //     .font(.title)
            //     .fontWeight(.bold)
            //     .padding()
            
            Text(localizationManager.localizedString("Choose an option"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            VStack(spacing: 20) {
                // Profile button
                Button(action: {
                    selectedTab = 5 // Profile tab
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text(localizationManager.localizedString("Профиль"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(systemGray6)
                    .cornerRadius(12)
                }
                
                // Statistics button
                Button(action: {
                    selectedTab = 6 // Statistics tab
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text(localizationManager.localizedString("Статистика"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(systemGray6)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(systemBackground)
    }
}

#Preview {
    MainTabView()
        .environmentObject(GameState())
}
