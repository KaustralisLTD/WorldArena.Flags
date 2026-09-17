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
    @State private var incomingDuelPopup: DuelChallenge?
    @State private var isAcceptingIncomingDuel = false
    @State private var duelActionErrorText: String?
    @State private var showDuelAnnouncement = false
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
            .overlay {
                if let nudge = pendingNudgeAlert {
                    FriendNudgePopupView(
                        fromUsername: nudge.fromUsername,
                        phraseKey: nudge.phraseLocalizationKey,
                        onContinue: {
                            Task {
                                try? await DuelAPIService.shared.markNudgesRead(userId: userProfile.username)
                            }
                            pendingNudgeAlert = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(2000)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: pendingNudgeAlert?.id)
            .overlay(alignment: .top) {
                if let duel = incomingDuelPopup {
                    GlobalIncomingDuelPopupView(
                        challenge: duel,
                        isAccepting: isAcceptingIncomingDuel,
                        onAccept: { acceptIncomingDuel(duel) },
                        onRemind: { withAnimation(.easeOut(duration: 0.25)) { remindIncomingDuel(duel) } },
                        onDecline: { Task { await declineIncomingDuel(duel) } },
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                remindIncomingDuel(duel)
                            }
                        }
                    )
                    .padding(.top, 12)
                    .padding(.horizontal, 14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: incomingDuelPopup?.id)
        }
        .environmentObject(gameState)
        .environmentObject(userProfile)
        .fullScreenCover(isPresented: isNavigatingToGameBinding) {
            GameView()
                .environmentObject(gameState)
                .environmentObject(userProfile)
        }
        .onChange(of: gameState.isNavigatingToGame) { isOpen in
            if !isOpen && gameState.isGameInProgress {
                gameState.abandonActiveGameIfFullScreenDismissed()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToLeagueTab"))) { _ in
            // Премиум: вкладка «Обучение» = 2, «Лиги» = 3. Раньше всегда ставили 2 → открывалось Обучение.
            selectedTab = gameState.isPremium ? 3 : 2
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToQuestsTab"))) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OnboardingDidFinish"))) { _ in
            Task { await checkNudgeInbox() }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("apnsDeviceTokenUpdated"))) { _ in
            Task { await registerAndSaveFriendCodeIfNeeded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .localProgressRestoredFromICloud)) { _ in
            gameState.reloadCountryLearningProgressFromStorage()
            gameState.refreshWeeklyChallengeCount()
            userProfile.reloadFromPersistence()
        }
        .onAppear {
            userProfile.checkAndAwardBirthdayBonusIfNeeded()
            Task {
                await syncMyCountryToServer()
                await fetchIncomingDuelChallenges()
                await registerAndSaveFriendCodeIfNeeded()
                await refreshFriendsDisplayNames()
                await checkNudgeInbox()
                await checkBirthdayGiftsInbox()
                #if os(iOS)
                await MainActor.run {
                    NotificationService.shared.scheduleFriendBirthdayNotificationsIfNeeded(friends: userProfile.friends)
                }
                #endif
            }
        }
        .onReceive(Timer.publish(every: 12, on: .main, in: .common).autoconnect()) { _ in
            Task {
                await fetchIncomingDuelChallenges()
                await gameState.syncIncomingDuelsWithServer(profile: userProfile)
                await refreshFriendsDisplayNames()
                await checkNudgeInbox()
            }
        }
        .onChange(of: userProfile.selectedCountryCode) { _ in
            Task {
                await syncMyCountryToServer()
                await registerAndSaveFriendCodeIfNeeded()
            }
        }
        .onChange(of: userProfile.username) { _ in
            Task { await registerAndSaveFriendCodeIfNeeded() }
        }
        .fullScreenCover(isPresented: $showDuelAnnouncement) {
            DuelAnnouncementView(
                gameState: gameState,
                onDismiss: { showDuelAnnouncement = false },
                onStart: {
                    Task {
                        await gameState.startNewGameWithCurrentRegions()
                        await MainActor.run { showDuelAnnouncement = false }
                    }
                }
            )
        }
    }

    private func checkNudgeInbox() async {
        guard OnboardingView.hasCompletedOnboarding else { return }
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let inbox = try? await DuelAPIService.shared.fetchNudgeInbox(userId: userId), let first = inbox.first else { return }
        await MainActor.run { pendingNudgeAlert = first }
    }

    private func checkBirthdayGiftsInbox() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let gifts = try? await DuelAPIService.shared.fetchBirthdayGiftsInbox(userId: userId), !gifts.isEmpty else { return }
        await MainActor.run {
            for gift in gifts {
                switch gift.type {
                case "xpBoost":
                    userProfile.activateXPBoost(multiplier: 3, durationMinutes: 10)
                case "fBucks":
                    userProfile.addFBucks(1, reason: .birthdayGiftFromFriend)
                default:
                    break
                }
            }
        }
        _ = try? await DuelAPIService.shared.consumeBirthdayGifts(userId: userId)
    }

    private func registerAndSaveFriendCodeIfNeeded() async {
        await FriendsService.shared.syncServerFriendCode(for: userProfile)
    }

    private func syncMyCountryToServer() async {
        let userId = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }
        guard let code = FriendsService.normalizeCountryCode(userProfile.selectedCountryCode) else { return }
        do {
            try await DuelAPIService.shared.updateMyCountryCode(userId: userId, countryCode: code)
        } catch {
            print("[MainTabView] updateMyCountryCode failed:", error.localizedDescription)
        }
    }
    
    private func fetchIncomingDuelChallenges() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let list = try? await DuelAPIService.shared.fetchIncomingChallenges(userId: userId) else { return }
        let existingIds = Set(userProfile.incomingDuelChallenges.map(\.id))
        let newOnes = list.compactMap { $0.toDuelChallenge(opponentId: userId, opponentName: userId) }
            .filter { !existingIds.contains($0.id) }
        await MainActor.run {
            if !newOnes.isEmpty {
                userProfile.incomingDuelChallenges.append(contentsOf: newOnes)
                for duel in newOnes {
                    NotificationService.shared.logDuelChallengeNotificationIfNeeded(
                        challengeId: duel.id,
                        challengerName: duel.challengerName
                    )
                }
            }
            let duelInvitesEnabled = (UserDefaults.standard.object(forKey: "duelInvitesNotifications") as? Bool) ?? true
            guard duelInvitesEnabled else {
                incomingDuelPopup = nil
                return
            }
            if incomingDuelPopup == nil {
                let now = Date()
                incomingDuelPopup = userProfile.incomingDuelChallenges
                    .filter {
                        ($0.status == .pending || $0.status == .challengerCompleted)
                        && now.timeIntervalSince($0.createdAt) < 24 * 60 * 60
                        && !DuelInviteSuppression.isSuppressed($0.id, now: now)
                    }
                    .sorted { $0.createdAt > $1.createdAt }
                    .first
            } else if let current = incomingDuelPopup, DuelInviteSuppression.isSuppressed(current.id) {
                incomingDuelPopup = nil
            }
        }
    }

    private func acceptIncomingDuel(_ challenge: DuelChallenge) {
        guard !isAcceptingIncomingDuel else { return }
        isAcceptingIncomingDuel = true
        Task {
            defer { Task { @MainActor in isAcceptingIncomingDuel = false } }
            let result: (seed: Int, challengerName: String, challengerScore: Int?, duelSetup: DuelAPIService.DuelSetup?)
            do {
                result = try await DuelAPIService.shared.acceptChallenge(challengeId: challenge.id)
                print("[MainTabView] acceptIncomingDuel success challengeId=", challenge.id, "seed=", result.seed)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("[MainTabView] acceptIncomingDuel failed:", msg, "challengeId=", challenge.id)
                await MainActor.run {
                    duelActionErrorText = msg
                    isAcceptingIncomingDuel = false
                }
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
                if gameState.duelQuestionsPayload == nil {
                    gameState.duelQuestionsPayload = challenge.duelQuestionsPayload
                }
                gameState.duelSeed = result.seed
                gameState.duelChallengeId = challenge.id
                gameState.duelOpponentId = challenge.challengerId
                gameState.duelRoleIsChallenger = false
                gameState.duelChallengerName = result.challengerName
                gameState.duelOpponentName = userProfile.username
                // Не удаляем incoming-челлендж: он нужен для ожидания результата и для отправки счёта после игры.
                DuelInviteSuppression.clear(challenge.id)
                incomingDuelPopup = nil
                selectedTab = 0
                showDuelAnnouncement = true
            }
        }
    }

    private func declineIncomingDuel(_ challenge: DuelChallenge) async {
        guard !isAcceptingIncomingDuel else { return }
        isAcceptingIncomingDuel = true
        defer { isAcceptingIncomingDuel = false }
        do {
            try await DuelAPIService.shared.declineChallenge(challengeId: challenge.id, userId: userProfile.username)
        } catch {
            // даже если сервер не отработал — локально прячем, чтобы не надоедало
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("[MainTabView] declineIncomingDuel failed:", msg, "challengeId=", challenge.id)
        }
        await MainActor.run {
            DuelInviteSuppression.decline(challenge.id)
            userProfile.incomingDuelChallenges.removeAll { $0.id == challenge.id }
            incomingDuelPopup = nil
        }
    }

    private func remindIncomingDuel(_ challenge: DuelChallenge) {
        let until = Date().addingTimeInterval(60 * 60) // 1 hour
        DuelInviteSuppression.snooze(challenge.id, until: until)
        incomingDuelPopup = nil
    }

    /// Обновить отображаемые имена друзей с сервера (после смены имени другом у него обновится имя у нас).
    private func refreshFriendsDisplayNames() async {
        let userId = userProfile.username
        guard !userId.isEmpty else { return }
        guard let fromAPI = try? await DuelAPIService.shared.fetchMyFriends(userId: userId) else { return }
        await MainActor.run {
            let oldFriends = userProfile.friends
            var usedOldIds = Set<UUID>()
            var merged: [Friend] = []
            for apiFriend in fromAPI {
                let mapped = apiFriend.toFriend()
                if let old = bestMatchingFriendForMerge(apiFriend: apiFriend, oldFriends: oldFriends, usedIds: usedOldIds) {
                    usedOldIds.insert(old.id)
                    merged.append(Friend(
                        id: old.id,
                        username: mapped.username,
                        displayName: apiFriend.displayName ?? mapped.displayName,
                        avatar: mapped.avatar,
                        avatarPhotoBase64: mapped.avatarPhotoBase64 ?? old.avatarPhotoBase64,
                        countryCode: mapped.countryCode,
                        level: apiFriend.level,
                        xp: apiFriend.xp,
                        streak: apiFriend.streak,
                        totalGamesPlayed: mapped.totalGamesPlayed,
                        correctAnswers: mapped.correctAnswers,
                        isOnline: old.isOnline,
                        joinDate: apiFriend.joinDateFromServer ?? old.joinDate,
                        playedToday: apiFriend.playedToday,
                        birthday: mapped.birthday ?? old.birthday,
                        achievements: apiFriend.achievements,
                        worldRankFromServer: apiFriend.worldRank ?? old.worldRankFromServer
                    ))
                } else {
                    merged.append(mapped)
                }
            }
            userProfile.friends = merged
            userProfile.saveToStorage()
        }
    }

    private func bestMatchingFriendForMerge(apiFriend: FriendFromAPI, oldFriends: [Friend], usedIds: Set<UUID>) -> Friend? {
        let apiUsername = apiFriend.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiDisplay = (apiFriend.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let apiUsernameNorm = canonicalFriendIdentity(apiUsername)
        let apiDisplayNorm = canonicalFriendIdentity(apiDisplay)
        if let exact = oldFriends.first(where: { !usedIds.contains($0.id) && $0.username.caseInsensitiveCompare(apiUsername) == .orderedSame }) {
            return exact
        }
        if let byDisplay = oldFriends.first(where: {
            !usedIds.contains($0.id)
            && !$0.displayNameOrUsername.isEmpty
            && $0.displayNameOrUsername.caseInsensitiveCompare(apiDisplay) == .orderedSame
        }) {
            return byDisplay
        }
        return oldFriends.first(where: {
            !usedIds.contains($0.id)
            && (canonicalFriendIdentity($0.username) == apiUsernameNorm
                || canonicalFriendIdentity($0.displayNameOrUsername) == apiUsernameNorm
                || (!apiDisplayNorm.isEmpty
                    && (canonicalFriendIdentity($0.username) == apiDisplayNorm
                        || canonicalFriendIdentity($0.displayNameOrUsername) == apiDisplayNorm)))
        })
    }

    private func canonicalFriendIdentity(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        s = s.replacingOccurrences(of: "[-_ ]?\\d+$", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[^a-zа-яёіїєґ0-9]", with: "", options: .regularExpression)
        return s
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

private struct GlobalIncomingDuelPopupView: View {
    let challenge: DuelChallenge
    let isAccepting: Bool
    let onAccept: () -> Void
    let onRemind: () -> Void
    let onDecline: () -> Void
    let onDismiss: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var glow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple.opacity(0.95), Color.blue.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.localizedString("duel_invite_popup_title"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(String(format: localizationManager.localizedString("duel_invite_popup_body_format"), challenge.challengerName))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Label(localizationManager.localizedString("24h to accept"), systemImage: "clock.badge.exclamationmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Button(action: onAccept) {
                    HStack(spacing: 4) {
                        if isAccepting {
                            ProgressView().tint(.white).scaleEffect(0.75)
                                .frame(width: 12, height: 12)
                        }
                        Text(localizationManager.localizedString("duel_invite_popup_accept"))
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36)
                    .padding(.horizontal, 4)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.green, Color.teal], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .disabled(isAccepting)
                .buttonStyle(.plain)

                Button(action: onRemind) {
                    Text(localizationManager.localizedString("duel_invite_popup_remind_1h"))
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 36)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDecline) {
                    Text(localizationManager.localizedString("duel_invite_popup_decline"))
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 36)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.72))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.black.opacity(0.9), Color.indigo.opacity(0.82), Color.purple.opacity(0.74)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(glow ? 0.36 : 0.18), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glow = true
            }
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
