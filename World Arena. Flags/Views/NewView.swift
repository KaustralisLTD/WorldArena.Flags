import SwiftUI
import StoreKit
#if os(iOS)
import UIKit
#endif

// Контейнер пост-игрового флоу со страницами: результаты → серия → серии друзей → квесты
struct PostGameFlowContainer: View {
    let score: Int
    let totalQuestions: Int
    let timeElapsed: TimeInterval
    let dailyQuests: [DailyQuest]
    let monthlyQuests: [MonthlyQuest]
    let friends: [Friend]
    @ObservedObject var gameState: GameState
    var onFinish: () -> Void
    var onPlayAgain: (() -> Void)?
    var onHome: (() -> Void)?

    @State private var step: Int = 0

    private static let streakViewShownDateKey = "PostGameFlow.streakViewShownDate"
    private static let friendStreaksLastShownAtKey = "PostGameFlow.friendStreaksLastShownAt"
    private static let friendStreaksCooldownHours: TimeInterval = 8

    private static func alreadyShownStreakViewToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        let todayStr = formatter.string(from: today)
        return UserDefaults.standard.string(forKey: streakViewShownDateKey) == todayStr
    }

    private static func markStreakViewShownToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: streakViewShownDateKey)
    }

    /// Экран «Напомнить друзьям» показываем не чаще раза в 8 часов.
    private static func shouldShowFriendStreaksView() -> Bool {
        let last = UserDefaults.standard.double(forKey: friendStreaksLastShownAtKey)
        guard last > 0 else { return true }
        return Date().timeIntervalSince1970 - last >= friendStreaksCooldownHours * 3600
    }

    private static func markFriendStreaksViewShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: friendStreaksLastShownAtKey)
    }

    var body: some View {
        Group {
            
            switch step {
            case 0:
                GameResultView(
                    score: score,
                    totalQuestions: totalQuestions,
                    timeElapsed: timeElapsed,
                    duelResult: gameState.pendingDuelResult,
                    bonusXP: gameState.bonusXP,
                    earnedFBucks: gameState.lastGameEarnedFBucks,
                    appliedXPBoostMultiplier: gameState.lastAppliedXPBoostMultiplier,
                    xpBoostRemainingSeconds: UserProfile.shared.xpBoostRemainingSeconds,
                    detailedResults: gameState.lastGameResults,
                    isTimeChallengeResult: gameState.selectedPlayMode == .timeChallenge,
                    timeChallengeBestCombo: gameState.timeChallengeBestCombo,
                    timeChallengeIsNewBestScore: gameState.timeChallengeIsNewBestScore,
                    timeChallengeBestScore: gameState.timeChallengeBestScore,
                    timeChallengeDailyRank: gameState.timeChallengeDailyRank,
                    timeChallengeWeeklyRank: gameState.timeChallengeWeeklyRank,
                    isSurvivalResult: gameState.selectedPlayMode == .survival,
                    survivalRunDepth: gameState.survivalLastRunQuestions,
                    survivalRunMaxStage: gameState.survivalLastRunMaxStage,
                    survivalPersonalBestDisplay: gameState.survivalPersonalBestDepth,
                    survivalIsNewBestDepth: gameState.survivalIsNewBestDepth,
                    survivalSessionBestCombo: gameState.survivalSessionBestCombo,
                    onContinue: {
                        // Итог дуэли не сбрасываем — покажем баннер на главной
                        next()
                    },
                    onPlayAgain: {
                        onPlayAgain?()
                    },
                    onBackHome: {
                        onFinish()
                        onHome?()
                    },
                    onShare: {
                        ShareService.shared.sharePostGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed, gameState: gameState)
                    }
                )
            case 1:
                StreakView(
                    currentStreak: UserProfile.shared.streak,
                    onContinue: {
                        Self.markStreakViewShownToday()
                        next()
                    }
                )
            case 2:
                if friends.isEmpty || !Self.shouldShowFriendStreaksView() {
                    // Нет друзей или экран «Напомнить друзьям» уже показывали менее 8 часов назад — сразу квесты, затем завершение
                    QuestResultsView(
                        dailyQuests: dailyQuests,
                        monthlyQuests: monthlyQuests,
                        playAgainIsDuelRepeat: gameState.selectedPlayMode == .duel,
                        onContinue: { onFinish() },
                        onPlayAgain: {
                            onPlayAgain?()
                        },
                        onHome: {
                            onFinish()
                            onHome?()
                        },
                        onShare: {
                            ShareService.shared.sharePostGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed, gameState: gameState)
                        }
                    )
                } else {
                    FriendStreaksView(
                        friends: friends,
                        gameState: gameState,
                        onRemind: { friend in
                            let me = UserProfile.shared.username
                            guard !me.isEmpty else { return nil }
                            // phraseId 15 = «не выполнен ежедневный урок на пути в изучении Флагов»
                            do {
                                try await DuelAPIService.shared.sendNudge(fromUsername: me, toUsername: friend.username, phraseId: 15)
                            } catch {
                                // Бэкенд может ещё не иметь /nudge — всё равно показываем тост
                            }
                            return await MainActor.run {
                                String(format: LocalizationManager.shared.localizedString("Reminder sent to %@"), friend.displayNameOrUsername)
                            }
                        },
                        onContinue: {
                            Self.markFriendStreaksViewShown()
                            next()
                        }
                    )
                }
            case 3:
                QuestResultsView(
                    dailyQuests: dailyQuests,
                    monthlyQuests: monthlyQuests,
                    onContinue: { onFinish() },
                    onPlayAgain: { 
                        // Не вызываем onFinish() здесь, так как onPlayAgain сам закроет модальное окно
                        onPlayAgain?()
                    },
                    onHome: { 
                        onFinish()
                        onHome?()
                    },
                    onShare: {
                        ShareService.shared.sharePostGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed, gameState: gameState)
                    }
                )
            default:
                FinalGameOverView(
                    score: score,
                    totalQuestions: totalQuestions,
                    timeElapsed: timeElapsed,
                    onPlayAgain: {
                        // Не вызываем onFinish() здесь, так как onPlayAgain сам закроет модальное окно
                        onPlayAgain?()
                    },
                    onHome: {
                        onFinish()
                        onHome?()
                    },
                    onShare: {
                        ShareService.shared.sharePostGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed, gameState: gameState)
                    }
                )
            }
        }
        .ignoresSafeArea()
    }

    private func next() {
        var newStep = min(step + 1, 4)
        // Серия с результатами по дням — только первый раз за день
        if newStep == 1 && Self.alreadyShownStreakViewToday() {
            newStep = 2
        }
        step = newStep
    }
}

// Выбор соперника для дуэли: друзья или случайный (похожая статистика)
struct DuelOpponentPickerView: View {
    @ObservedObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isStarting = false
    @State private var showDuelPrepareFailedAlert = false
    @State private var showingAddFriends = false
    /// Если задан — после выбора соперника не запускаем игру, а вызываем callback (показать анонс на главной).
    var onDuelReadyToStart: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section(localizationManager.localizedString("Friends")) {
                    if userProfile.friends.isEmpty {
                        Text(localizationManager.localizedString("No friends yet. Add friends in Profile."))
                            .foregroundColor(.secondary)
                    }
                    ForEach(userProfile.friends, id: \.id) { friend in
                        Button(action: { startDuel(with: friend) }) {
                            HStack(spacing: 12) {
                                friendAvatarView(friend, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.displayNameOrUsername).font(.headline)
                                    Text("\(friend.xp) XP · \(friend.streak) \(localizationManager.localizedString("days"))")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isStarting)
                    }
                }
                Section(localizationManager.localizedString("Random opponent")) {
                    Button(action: startVirtualDuel) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text(localizationManager.localizedString("Random opponent"))
                        }
                    }
                    .disabled(isStarting)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    Button(action: {
                        showingAddFriends = true
                    }) {
                        HStack(spacing: 12) {
                            Image("IconAddFriends")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                            Text(localizationManager.localizedString("ДОБАВИТЬ ДРУЗЕЙ"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuelSummaryView().environmentObject(gameState).environmentObject(userProfile)) {
                        HStack(spacing: 6) {
                            Image("IconDuelSummary")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            Text(localizationManager.localizedString("Duel Summary"))
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
            .navigationTitle(localizationManager.localizedString("Duel"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("Cancel")) {
                        dismiss()
                    }
                }
            }
            .alert(localizationManager.localizedString("duel.error.alert.title"), isPresented: $showDuelPrepareFailedAlert) {
                Button(localizationManager.localizedString("OK"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("duel.error.prepare_questions"))
            }
            .sheetOrFullScreenOnIPad(isPresented: $showingAddFriends) {
                AddFriendsView()
                    .environmentObject(userProfile)
            }
        }
    }
    
    private func startDuel(with friend: Friend) {
        guard !isStarting, gameState.canStartGameWithLives() else { return }
        if gameState.isGameInProgress && gameState.selectedPlayMode == .duel { return }
        isStarting = true
        let myName = userProfile.username
        if let onReady = onDuelReadyToStart {
            gameState.selectedPlayMode = .duel
            gameState.duelServerQuestionsCount = nil
            gameState.duelServerQuestionsCount = gameState.questionsPerGame
            gameState.duelSeed = Int.random(in: 0..<Int.max)
            gameState.duelChallengeId = nil
            gameState.duelOpponentId = friend.username
            gameState.duelOpponentName = friend.displayNameOrUsername
            gameState.duelChallengerName = myName
            gameState.duelRoleIsChallenger = true
            isStarting = false
            onReady()
            dismiss()
            return
        }

        let seed = Int.random(in: 0..<Int.max)
        Task {
            await MainActor.run { gameState.duelServerQuestionsCount = nil }
            let regions = await MainActor.run { gameState.duelRegionsServerStrings() }
            let difficulty = await MainActor.run { gameState.selectedDifficulty.rawValue }
            let gameMode = await MainActor.run { gameState.selectedGameMode.rawValue }
            let questionsCount = await MainActor.run { gameState.questionsPerGame }
            let optionsCount = await MainActor.run { gameState.optionsCount }
            let questionsPayload = await gameState.buildDuelQuestionsPayload(
                seed: seed,
                questionsCount: questionsCount,
                optionsCount: optionsCount
            )
            guard let questionsPayload, !questionsPayload.isEmpty else {
                await MainActor.run {
                    isStarting = false
                    showDuelPrepareFailedAlert = true
                }
                return
            }
            var challengeId = UUID().uuidString
            if let serverId = try? await DuelAPIService.shared.createChallenge(
                opponentId: friend.username,
                opponentName: friend.username,
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
            let challenge = DuelChallenge(
                id: challengeId,
                challengerId: myName,
                challengerName: myName,
                opponentId: friend.username,
                opponentName: friend.username,
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
            await MainActor.run {
                userProfile.outgoingDuelChallenges.append(challenge)
                gameState.selectedPlayMode = .duel
                gameState.duelServerQuestionsCount = questionsCount
                gameState.duelSeed = seed
                gameState.duelChallengeId = challengeId
                gameState.duelOpponentId = friend.username
                gameState.duelOpponentName = friend.displayNameOrUsername
                gameState.duelChallengerName = myName
                gameState.duelRoleIsChallenger = true
                gameState.duelQuestionsPayload = questionsPayload
            }
            await gameState.startNewGameWithCurrentRegions()
            await MainActor.run {
                isStarting = false
                dismiss()
            }
        }
    }
    
    private func startDuelWithRandom() {
        let similar = DuelService.pickSimilarOpponent(from: userProfile.friends, myXP: userProfile.xp, myStreak: userProfile.streak)
        guard let friend = similar else { return }
        startDuel(with: friend)
    }

    private static let virtualDuelCountKey = "duel.virtualCount.v1"

        private func startVirtualDuel() {
        guard !isStarting, gameState.canStartGameWithLives() else { return }
        isStarting = true
        let count = UserDefaults.standard.integer(forKey: Self.virtualDuelCountKey)
        UserDefaults.standard.set(count + 1, forKey: Self.virtualDuelCountKey)
        let seed = Int.random(in: 0..<Int.max)
        let localeCode = LocalizationManager.shared.currentBundleLanguageCode
        let name = RandomOpponentNames.randomName(for: localeCode)
        let myName = userProfile.username
        gameState.selectedPlayMode = .duel
        gameState.duelServerQuestionsCount = nil
        gameState.duelServerQuestionsCount = gameState.questionsPerGame
        gameState.duelSeed = seed
        gameState.duelChallengeId = "virtual-\(UUID().uuidString)"
        gameState.duelOpponentId = "virtual"
        gameState.duelOpponentName = name
        gameState.duelChallengerName = myName
        gameState.duelRoleIsChallenger = true
        gameState.duelIsVirtual = true
        if let onReady = onDuelReadyToStart {
            onReady()
            isStarting = false
            dismiss()
        } else {
            Task {
                await gameState.startNewGameWithCurrentRegions()
                await MainActor.run {
                    isStarting = false
                    dismiss()
                }
            }
        }
    }
}


@ViewBuilder
private func friendAvatarView(_ friend: Friend, size: CGFloat) -> some View {
    ZStack {
        Circle().fill(Color.blue.opacity(0.2)).frame(width: size, height: size)
        #if os(iOS)
        if let data = friend.remotePhotoAvatarData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Text(friend.displayAvatar)
                .font(.system(size: friend.countryCode != nil ? size * 0.6 : size * 0.46, weight: .semibold))
        }
        #else
        Text(friend.displayAvatar)
            .font(.system(size: friend.countryCode != nil ? size * 0.6 : size * 0.46, weight: .semibold))
        #endif
    }
}

// Подбор соперника с похожей статистикой (XP, streak)
enum DuelService {
    static func pickSimilarOpponent(from friends: [Friend], myXP: Int, myStreak: Int) -> Friend? {
        guard !friends.isEmpty else { return nil }
        let sorted = friends.sorted { a, b in
            let scoreA = abs(a.xp - myXP) + abs(a.streak - myStreak) * 100
            let scoreB = abs(b.xp - myXP) + abs(b.streak - myStreak) * 100
            return scoreA < scoreB
        }
        return sorted.first
    }
}

// Экран профиля друга (упрощённый)
struct FriendProfileView: View {
    let friend: Friend
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showDeleteAlert = false
    @State private var isStartingDuel = false
    @State private var showDuelPrepareFailedAlert = false
    @State private var isSendingBirthdayGift = false
    @State private var birthdayGiftSentThisSession = false
    @State private var birthdayGiftError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Аватар (миниатюра как у друга: флаг или эмодзи)
                ZStack {
                    friendAvatarView(friend, size: 100)
                }
                Text(friend.displayNameOrUsername)
                    .font(.system(size: 24, weight: .bold))
                Text("@\(friend.username)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                // Серия дней и прогресс
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localizedString("Friend profile progress title"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        stat("flame.fill", String(format: "%d", friend.streak), localizationManager.localizedString("days"))
                        stat("bolt.fill", String(format: "%d", friend.xp), "XP")
                        stat("chart.bar.fill", String(format: "%d", friend.level), localizationManager.localizedString("Level"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)

                // Рейтинг (оценка по данным друга, без «You are…»)
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localizedString("Global ranking by countries"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    if let cc = friend.countryCode, !cc.isEmpty {
                        Text(friendCountryRankLineDisplay(code: cc))
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text(friendWorldRankLineDisplay())
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal, 20)

                if !friendDuelEntries.isEmpty {
                    friendDuelsSection
                }

                friendAchievementsSection

                // Подарок на день рождения (если сегодня ДР друга)
                if let bday = friend.birthday, userProfile.isTodayBirthday(bday), !birthdayGiftSentThisSession {
                    Button(action: { Task { await sendBirthdayGift() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                            Text(localizationManager.localizedString("Поздравить друга"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isSendingBirthdayGift)
                }

                Spacer(minLength: 88)
            }
        }
        .padding(.top, 24)
        .navigationTitle(friend.displayNameOrUsername)
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        #endif
        .alert(localizationManager.localizedString("Удалить друга"), isPresented: $showDeleteAlert) {
            Button(localizationManager.localizedString("Отмена"), role: .cancel) { }
            Button(localizationManager.localizedString("Удалить"), role: .destructive) {
                removeFriend()
            }
        } message: {
            Text(localizationManager.localizedString("Вы уверены, что хотите удалить \(friend.displayNameOrUsername) из друзей и перестать следить за его успехами?"))
        }
        .alert(isPresented: Binding(
            get: { birthdayGiftError != nil },
            set: { if !$0 { birthdayGiftError = nil } }
        )) {
            Alert(
                title: Text(localizationManager.localizedString("Ошибка")),
                message: Text(birthdayGiftError ?? ""),
                dismissButton: .default(Text(localizationManager.localizedString("OK")))
            )
        }
        .alert(localizationManager.localizedString("duel.error.alert.title"), isPresented: $showDuelPrepareFailedAlert) {
            Button(localizationManager.localizedString("OK"), role: .cancel) { }
        } message: {
            Text(localizationManager.localizedString("duel.error.prepare_questions"))
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button(action: { startDuel() }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text(localizationManager.localizedString("Challenge to Duel"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .disabled(isStartingDuel || !gameState.canStartGameWithLives())

                Button(action: { showDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "person.badge.minus")
                        Text(localizationManager.localizedString("Удалить из друзей"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }

    @MainActor
    private func sendBirthdayGift() async {
        guard !isSendingBirthdayGift else { return }
        isSendingBirthdayGift = true
        defer { isSendingBirthdayGift = false }
        let me = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else {
            birthdayGiftError = localizationManager.localizedString("Укажите имя профиля перед отправкой подарка")
            return
        }
        do {
            try await DuelAPIService.shared.sendBirthdayGift(fromUsername: me, toUsername: friend.username, type: "xpBoost")
            birthdayGiftSentThisSession = true
        } catch {
            birthdayGiftError = error.localizedDescription
        }
    }
    
    private func removeFriend() {
        let me = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            if !me.isEmpty {
                try? await DuelAPIService.shared.removeFriend(myUserId: me, friendUsername: friend.username)
            }
            await MainActor.run {
                userProfile.friends.removeAll { $0.id == friend.id }
                userProfile.saveToStorage()
                dismiss()
            }
        }
    }
    
    private func startDuel() {
        guard !isStartingDuel, gameState.canStartGameWithLives() else { return }
        isStartingDuel = true
        let seed = Int.random(in: 0..<Int.max)
        let myName = userProfile.username
        Task {
            await MainActor.run { gameState.duelServerQuestionsCount = nil }
            let regions = await MainActor.run { gameState.duelRegionsServerStrings() }
            let difficulty = await MainActor.run { gameState.selectedDifficulty.rawValue }
            let gameMode = await MainActor.run { gameState.selectedGameMode.rawValue }
            let questionsCount = await MainActor.run { gameState.questionsPerGame }
            let optionsCount = await MainActor.run { gameState.optionsCount }
            let questionsPayload = await gameState.buildDuelQuestionsPayload(
                seed: seed,
                questionsCount: questionsCount,
                optionsCount: optionsCount
            )
            guard let questionsPayload, !questionsPayload.isEmpty else {
                await MainActor.run {
                    isStartingDuel = false
                    showDuelPrepareFailedAlert = true
                }
                return
            }
            var challengeId = UUID().uuidString
            if let serverId = try? await DuelAPIService.shared.createChallenge(
                opponentId: friend.username,
                opponentName: friend.username,
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
            let challenge = DuelChallenge(
                id: challengeId,
                challengerId: myName,
                challengerName: myName,
                opponentId: friend.username,
                opponentName: friend.username,
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
            await MainActor.run {
                userProfile.outgoingDuelChallenges.append(challenge)
                gameState.selectedPlayMode = .duel
                gameState.duelServerQuestionsCount = questionsCount
                gameState.duelSeed = seed
                gameState.duelChallengeId = challengeId
                gameState.duelOpponentId = friend.username
                gameState.duelOpponentName = friend.displayNameOrUsername
                gameState.duelChallengerName = myName
                gameState.duelRoleIsChallenger = true
                gameState.duelQuestionsPayload = questionsPayload
            }
            await gameState.startNewGameWithCurrentRegions()
            await MainActor.run {
                isStartingDuel = false
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private func stat(_ systemImageName: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImageName).font(.title2)
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func friendCountryRankLineDisplay(code: String) -> String {
        let upper = code.uppercased()
        let flag = FriendsService.countryCodeToFlagEmoji(upper)
        let rank = MotivationalRanking.countryRank(for: friend.motivationalRankInputs(), countryCode: upper)
        let format = localizationManager.localizedString("Friend country rank line")
        return String(
            format: format,
            flag,
            friend.displayNameOrUsername,
            rank,
            localizationManager.localizedString(friendCountryNameByCode(upper))
        )
    }

    private func friendWorldRankLineDisplay() -> String {
        let rank = friend.worldRankFromServer ?? MotivationalRanking.worldRank(for: friend.motivationalRankInputs())
        let format = localizationManager.localizedString("Friend world rank line")
        return String(format: format, friend.displayNameOrUsername, rank)
    }

    private func friendCountryNameByCode(_ code: String) -> String {
        let upper = code.uppercased()
        let lang = localizationManager.currentLocale.languageCode ?? "en"
        return CountryDatabase.getLocalizedCountryData(for: upper, language: lang)?.name
            ?? CountryDatabase.getCountryData(for: upper)?.ru.name
            ?? upper
    }

    private var friendAchievementDefs: [AchievementDefinition] {
        userProfile.allAchievementDefinitions.filter { friend.achievements.contains($0.id) }
    }

    private var friendDuelEntries: [DuelHistoryEntry] {
        gameState.duelHistory
            .filter { $0.opponentName == friend.username || $0.opponentName == friend.displayNameOrUsername }
            .sorted { $0.playedAt > $1.playedAt }
    }

    private var friendDuelsWonCount: Int {
        friendDuelEntries.filter(\.iWon).count
    }

    private var friendDuelsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("Duel Summary"))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                stat("person.2.fill", "\(friendDuelEntries.count)", localizationManager.localizedString("Total Games"))
                stat("trophy.fill", "\(friendDuelsWonCount)", localizationManager.localizedString("Wins"))
            }
            if let latest = friendDuelEntries.first {
                Text("\(localizationManager.localizedString("Last played")): \(latest.playedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    private var friendAchievementsTitle: String {
        localizationManager.localizedString("МЕСЯЧНЫЕ ДОСТИЖЕНИЯ")
    }

    private var friendAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(friendAchievementsTitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            if friendAchievementDefs.isEmpty {
                Text(localizationManager.localizedString("Friend achievements placeholder"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(friendAchievementDefs.prefix(9), id: \.id) { def in
                        friendAchievementCell(definition: def)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func friendAchievementCell(definition: AchievementDefinition) -> some View {
        VStack(spacing: 6) {
            if let asset = definition.imageAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
            } else {
                Circle()
                    .fill(definition.color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: definition.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            Text(localizationManager.localizedString(definition.titleKey))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(Color.white.opacity(0.18))
        .cornerRadius(10)
    }
}

// MARK: - Профиль по ссылке (deep link: worldarena.games/profile/CODE)
struct ProfileByLinkView: View {
    let friendCode: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject var gameState: GameState
    @ObservedObject private var lm = LocalizationManager.shared
    @State private var loadedFriend: Friend?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isAdding = false
    @State private var addedFriend: Friend?

    private var existingFriend: Friend? {
        guard let f = loadedFriend else { return nil }
        return userProfile.friends.first { $0.username.lowercased() == f.username.lowercased() }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(lm.localizedString("Загрузка..."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(err)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let friend = existingFriend ?? addedFriend {
                    FriendProfileView(friend: friend, gameState: gameState)
                        .environmentObject(userProfile)
                } else if let friend = loadedFriend {
                    profileCardWithAddButton(friend: friend)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle(loadedFriend?.displayNameOrUsername ?? lm.localizedString("Профиль"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.localizedString("Готово")) { dismiss() }
                }
            }
        }
        .task { await loadUser() }
    }

    private func profileCardWithAddButton(friend: Friend) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    friendAvatarView(friend, size: 100)
                }
                Text(friend.displayNameOrUsername)
                    .font(.system(size: 24, weight: .bold))
                Text("@\(friend.username)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text(lm.localizedString("Friend profile progress title"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        statRow("flame.fill", "\(friend.streak)", lm.localizedString("days"))
                        statRow("bolt.fill", "\(friend.xp)", "XP")
                        statRow("chart.bar.fill", "\(friend.level)", lm.localizedString("Level"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                Button(action: { Task { await addFriend() } }) {
                    HStack {
                        if isAdding { ProgressView().tint(.white) }
                        Text(isAdding ? lm.localizedString("Добавляем...") : lm.localizedString("Добавить в друзья"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .disabled(isAdding)
            }
            .padding(.top, 24)
        }
    }

    private func statRow(_ systemImageName: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImageName).font(.title2)
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    private func loadUser() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let api = try await DuelAPIService.shared.fetchUserByCode(friendCode) else {
                errorMessage = lm.localizedString("Пользователь не найден")
                return
            }
            loadedFriend = api.toFriend()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func addFriend() async {
        guard !isAdding, let _ = loadedFriend else { return }
        isAdding = true
        defer { isAdding = false }
        let result = await FriendsService.shared.addFriend(by: friendCode, to: userProfile)
        switch result {
        case .success:
            if let f = userProfile.friends.first(where: { $0.username.lowercased() == loadedFriend?.username.lowercased() }) {
                addedFriend = f
            }
        case .alreadyFriends:
            if let f = userProfile.friends.first(where: { $0.username.lowercased() == loadedFriend?.username.lowercased() }) {
                addedFriend = f
            }
        default:
            errorMessage = lm.localizedString("Не удалось добавить друга")
        }
    }
}

struct PremiumView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var storeManager = StoreManager.shared
    private let privacyPolicyURL = URL(string: "https://worldarena.games/privacy-policy.html")!
    private let termsOfUseURL = URL(string: "https://worldarena.games/terms-of-use.html")!
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return horizontalSizeClass == .regular
        #endif
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.purple.opacity(0.5), Color.black.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: isIPad ? 30 : 20) {
                        // Simple youth animation
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                                .frame(width: isIPad ? 240 : 180, height: isIPad ? 240 : 180)
                                .opacity(0.9)
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 80 : 64, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, isIPad ? 40 : 30)
                        .onAppear { 
                            Task {
                                await storeManager.loadProducts()
                            }
                        }
                        
                        Text(LocalizationManager.shared.localizedString("Go Premium"))
                            .font(.system(size: isIPad ? 44 : 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 6)
                        Text(LocalizationManager.shared.localizedString("Learn all countries and flags in ~2 months with Premium"))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: isIPad ? 20 : 16))
                            .padding(.horizontal, isIPad ? 40 : 24)
                        
                        VStack(alignment: .leading, spacing: isIPad ? 18 : 14) {
                            premiumRow(title: "Unlimited Hearts", icon: "infinity")
                            premiumRow(title: "Personalized Practice", icon: "dumbbell.fill")
                            premiumRow(title: "Explain My Answer", icon: "text.bubble.fill")
                            premiumRow(title: "Roleplay Scenarios", icon: "theatermasks.fill")
                            premiumRow(title: "Access 'My Mistakes'", icon: "exclamationmark.bubble.fill")
                            premiumRow(title: "Erudite Difficulty", icon: "brain.head.profile")
                            premiumRow(title: "Learning Section", icon: "book.fill")
                            premiumRow(title: "Exclusive tournaments with cash F-Bucks prizes", icon: "trophy.fill")
                        }
                        .padding(isIPad ? 24 : 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(isIPad ? 20 : 16)
                        .padding(.horizontal, isIPad ? 40 : 20)
                        
                        // Purchase Options
                        VStack(spacing: 12) {
                            if let errorMessage = storeManager.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: isIPad ? 15 : 12, weight: .medium))
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }

                            if storeManager.isLoading {
                                VStack(spacing: 10) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(isIPad ? 1.5 : 1.2)
                                    Text(LocalizationManager.shared.localizedString("Connecting to App Store..."))
                                        .font(.system(size: isIPad ? 17 : 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.95))
                                }
                                .padding(.vertical, isIPad ? 12 : 8)
                            } else if !storeManager.hasProducts {
                                VStack(spacing: 16) {
                                    if let errorMessage = storeManager.errorMessage {
                                        VStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 32))
                                                .foregroundColor(.orange)
                                            Text(LocalizationManager.shared.localizedString("Unable to load products"))
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(errorMessage)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        }
                                    }
                                    Text(LocalizationManager.shared.localizedString("Sign in with Apple ID in Settings → App Store to see prices. Tap an option or Retry to try again."))
                                        .font(.system(size: isIPad ? 16 : 13))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                    // Плейсхолдеры подписок (Release: продукты не загрузились — по нажатию пробуем загрузить снова)
                                    PremiumPlaceholderRow(
                                        title: LocalizationManager.shared.localizedString("Premium Monthly"),
                                        isYearly: false,
                                        isLoading: storeManager.isLoading
                                    ) {
                                        Task { await storeManager.retryLoadProducts() }
                                    }
                                    PremiumPlaceholderRow(
                                        title: LocalizationManager.shared.localizedString("Yearly Premium"),
                                        isYearly: true,
                                        isLoading: storeManager.isLoading
                                    ) {
                                        Task { await storeManager.retryLoadProducts() }
                                    }
                                    Button {
                                        Task { await storeManager.retryLoadProducts() }
                                    } label: {
                                        HStack {
                                            if storeManager.isLoading {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                            } else {
                                                Image(systemName: "arrow.clockwise")
                                            }
                                            Text(storeManager.isLoading ? LocalizationManager.shared.localizedString("Loading...") : LocalizationManager.shared.localizedString("Retry"))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, isIPad ? 16 : 12)
                                        .font(.system(size: isIPad ? 20 : 16, weight: .bold))
                                        .background(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(8)
                                    }
                                    .disabled(storeManager.isLoading)
                                }
                                .padding()
                            } else {
                                // Показываем реальные продукты, если есть
                                ForEach(storeManager.products, id: \.id) { product in
                                    PremiumProductButton(
                                        product: product, 
                                        storeManager: storeManager, 
                                        gameState: gameState
                                    ) {
                                        dismiss()
                                    }
                                }
                                #if DEBUG
                                // Моковые продукты только для разработки — не показываются в Release (App Store)
                                if storeManager.products.isEmpty {
                                    if let monthlyMock = storeManager.monthlyMockProduct {
                                        MockPremiumProductButton(mockProduct: monthlyMock, storeManager: storeManager, gameState: gameState) {
                                            dismiss()
                                        }
                                    }
                                    if let yearlyMock = storeManager.yearlyMockProduct {
                                        MockPremiumProductButton(mockProduct: yearlyMock, storeManager: storeManager, gameState: gameState) {
                                            dismiss()
                                        }
                                    }
                                }
                                #endif
                            }

                            Button(LocalizationManager.shared.localizedString("Redeem Offer Code")) {
                                #if os(iOS)
                                SKPaymentQueue.default().presentCodeRedemptionSheet()
                                #endif
                            }
                            .foregroundColor(.white)
                            .font(.system(size: isIPad ? 20 : 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, isIPad ? 14 : 10)
                            .background(Color.white.opacity(0.16))
                            .cornerRadius(10)

                            Text(LocalizationManager.shared.localizedString("Have a promo code?"))
                                .font(.system(size: isIPad ? 16 : 12))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                            
                            // Restore Purchases
                            Button(LocalizationManager.shared.localizedString("Restore Purchases")) {
                                Task {
                                    await storeManager.restorePurchases()
                                    if storeManager.isPremium {
                                        GameState.userDidCancelSubscription = false
                                        gameState.isPremium = true
                                        dismiss()
                                    }
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: isIPad ? 20 : 14, weight: .semibold))
                            .padding(.top, 8)
                            .padding(.vertical, isIPad ? 6 : 0)

                            HStack(spacing: 16) {
                                Link(LocalizationManager.shared.localizedString("Политика конфиденциальности"), destination: privacyPolicyURL)
                                    .font(.system(size: isIPad ? 18 : 13, weight: .semibold))
                                Link(LocalizationManager.shared.localizedString("Условия использования"), destination: termsOfUseURL)
                                    .font(.system(size: isIPad ? 18 : 13, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.top, 2)
                        }
                        .padding(.horizontal, 20)
                        
                        Button(LocalizationManager.shared.localizedString("NO THANKS")) {
                            dismiss()
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: isIPad ? 19 : 14, weight: .semibold))
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").foregroundColor(.white).font(.title2) }
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumRow(title: String, icon: String) -> some View {
        let fontSize: CGFloat = isIPad ? 20 : 16
        let iconSize: CGFloat = isIPad ? 24 : 20
        HStack(spacing: isIPad ? 16 : 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: iconSize, weight: .semibold))
                .frame(width: isIPad ? 32 : 28)
            Text(LocalizationManager.shared.localizedString(title))
                .foregroundColor(.white)
                .font(.system(size: fontSize, weight: .semibold))
            Spacer()
        }
    }

}

// MARK: - FinalGameOverView
struct FinalGameOverView: View {
    let score: Int
    let totalQuestions: Int
    let timeElapsed: TimeInterval
    let onPlayAgain: () -> Void
    let onHome: () -> Void
    let onShare: () -> Void
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Game results content
                VStack(spacing: 20) {
                    // Score display
                    VStack(spacing: 8) {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        Text(localizationManager.localizedString("POINTS"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Statistics
                    HStack(spacing: 30) {
                        StatisticItem(
                            icon: "🎯",
                            value: "\(Int((Double(score) / Double(totalQuestions)) * 100))%",
                            label: localizationManager.localizedString("Accuracy")
                        )
                        
                        StatisticItem(
                            icon: "⏱️",
                            value: formatTime(timeElapsed),
                            label: localizationManager.localizedString("Time")
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: onPlayAgain) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(localizationManager.localizedString("Play Again"))
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: onShare) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text(localizationManager.localizedString("Share"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: onHome) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text(localizationManager.localizedString("Home"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatisticItem: View {
    let icon: String
    var systemImageName: String? = nil
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let name = systemImageName {
                    Image(systemName: name)
                        .font(.system(size: 24))
                } else {
                    Text(icon)
                        .font(.system(size: 24))
                }
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Manage Subscription View
struct ManageSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var userProfile: UserProfile
    @ObservedObject private var storeManager = StoreManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showCancelAlert = false
    @State private var showCancellationView = false
    
    // Даты и статус — можно в будущем брать из Transaction или Subscription API
    @State private var subscriptionData = SubscriptionData(
        planName: "", // заполняется из продукта
        price: "",
        nextBillingDate: Date().addingTimeInterval(30 * 24 * 3600),
        startDate: Date().addingTimeInterval(-7 * 24 * 3600),
        isActive: true
    )

    /// Текущий план (годовой или месячный) — название и цена для отображения
    private var currentPlanDisplayPrice: String {
        if let p = storeManager.currentSubscriptionProduct { return p.displayPrice }
        if let m = storeManager.currentSubscriptionMockProduct { return m.displayPrice }
        return storeManager.isCurrentPlanYearly ? "$5.99" : "$1.99"
    }

    private var currentPlanDisplayName: String {
        if let p = storeManager.currentSubscriptionProduct { return p.displayName }
        if let m = storeManager.currentSubscriptionMockProduct { return m.displayName }
        return storeManager.isCurrentPlanYearly
            ? localizationManager.localizedString("Yearly Premium")
            : localizationManager.localizedString("Premium Monthly")
    }

    private var currentPlanPeriodKey: String {
        storeManager.isCurrentPlanYearly ? "year" : "month"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text(localizationManager.localizedString("Manage subscription"))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(localizationManager.localizedString("Your premium subscription is active"))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    // Current Plan
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localizedString("Current plan"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(currentPlanDisplayName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("\(localizationManager.localizedString("Price")): \(currentPlanDisplayPrice)/\(localizationManager.localizedString(currentPlanPeriodKey))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Billing Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localizedString("Billing information"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            InfoRow(
                                title: localizationManager.localizedString("Start date"),
                                value: formatDate(subscriptionData.startDate),
                                icon: "calendar.badge.plus"
                            )
                            
                            InfoRow(
                                title: localizationManager.localizedString("Next payment"),
                                value: formatDate(subscriptionData.nextBillingDate),
                                icon: "calendar.badge.clock"
                            )
                            
                            InfoRow(
                                title: localizationManager.localizedString("Status"),
                                value: localizationManager.localizedString("Active"),
                                icon: "checkmark.shield.fill",
                                valueColor: .green
                            )
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Premium Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localizedString("Premium benefits"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("Безлимитные жизни"),
                                description: localizationManager.localizedString("Играйте без ожидания"),
                                icon: "heart.fill",
                                iconImageName: localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode),
                                color: Color.red
                            )
                            
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("Раздел Обучения"),
                                description: localizationManager.localizedString("Изучайте флаги и страны"),
                                icon: "book.fill",
                                color: Color.blue
                            )
                            
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("Сложность Эрудит"),
                                description: localizationManager.localizedString("Продвинутые вопросы"),
                                icon: "brain.head.profile",
                                color: Color.purple
                            )
                            
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("My mistakes"),
                                description: localizationManager.localizedString("Analysis of your mistakes"),
                                icon: "exclamationmark.bubble.fill",
                                color: Color.orange
                            )
                            
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("Premium tournaments"),
                                description: localizationManager.localizedString("Exclusive tournaments with F-Bucks prizes"),
                                icon: "trophy.fill",
                                color: Color.yellow
                            )
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Cancel Subscription Button
                    Button(action: {
                        showCancelAlert = true
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(localizationManager.localizedString("Cancel subscription"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString("Close")) {
                        dismiss()
                    }
                }
            }
        }
        .alert(localizationManager.localizedString("Cancel subscription"), isPresented: $showCancelAlert) {
            Button(localizationManager.localizedString("Keep subscription"), role: .cancel) { }
            Button(localizationManager.localizedString("Yes, cancel"), role: .destructive) {
                print("Cancel subscription")
                showCancellationView = true
            }
        } message: {
            Text(localizationManager.localizedString("Are you sure you want to cancel premium? You will lose access to all premium features."))
        }
        .fullScreenCover(isPresented: $showCancellationView) {
            SubscriptionCancellationView(gameState: gameState, userProfile: userProfile)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Subscription Data Model
struct SubscriptionData {
    let planName: String
    let price: String
    let nextBillingDate: Date
    let startDate: Date
    let isActive: Bool
}

// MARK: - Placeholder row when products not loaded (Release: no mock, show Monthly/Yearly + Retry)
struct PremiumPlaceholderRow: View {
    let title: String
    let isYearly: Bool
    let isLoading: Bool
    let onTap: () -> Void
    private static let tapToLoadKey = "Tap to load price"

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(LocalizationManager.shared.localizedString(isYearly ? "Duration: 1 year (auto-renewable)" : "Duration: 1 month (auto-renewable)"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                } else {
                    Text(LocalizationManager.shared.localizedString(Self.tapToLoadKey))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .background(
                LinearGradient(
                    colors: isYearly ? [.green.opacity(0.3), .blue.opacity(0.3)] : [.purple.opacity(0.3), .blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isYearly ? Color.green.opacity(0.5) : Color.purple.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(14)
            .shadow(color: (isYearly ? Color.green : Color.purple).opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Premium Product Button
struct PremiumProductButton: View {
    let product: Product
    @ObservedObject var storeManager: StoreManager
    let gameState: GameState
    let onPurchaseComplete: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasEligibleWeekTrial = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var showsTrial: Bool {
        hasEligibleWeekTrial && !storeManager.isPremium
    }

    private var isIPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
    
    var body: some View {
        Button {
            Task {
                let success = await storeManager.purchase(product)
                if success {
                    GameState.userDidCancelSubscription = false
                    gameState.isPremium = true
                    onPurchaseComplete()
                }
            }
        } label: {
            VStack(spacing: 12) {
                Text(productTitle)
                    .font(.system(size: isIPad ? 22 : 18, weight: .bold))

                Text(product.displayPrice)
                    .font(.system(size: isIPad ? 32 : 26, weight: .heavy))
                    .monospacedDigit()

                Text(durationText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                if isYearlyProduct && savingsPercentage > 0 {
                    Text(String(format: localizationManager.localizedString("Save %d%%"), savingsPercentage))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15), in: Capsule())
                }

                Text(localizationManager.localizedString(showsTrial ? "premium.trial.start" : "premium.subscribe"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))

                if showsTrial {
                    Text(String(format: localizationManager.localizedString(isYearlyProduct ? "premium.trial.yearly" : "premium.trial.monthly"), product.displayPrice))
                        .font(.subheadline.weight(.semibold))
                }
                Text(localizationManager.localizedString("premium.renewal"))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, isIPad ? 20 : 14)
            .background(
                LinearGradient(
                    colors: isYearlyProduct ? [.green.opacity(0.3), .blue.opacity(0.3)] : [.purple.opacity(0.3), .blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isYearlyProduct ? Color.green.opacity(0.6) : Color.purple.opacity(0.6), lineWidth: 1.2)
            )
            .cornerRadius(16)
            .shadow(color: (isYearlyProduct ? Color.green : Color.purple).opacity(0.28), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(storeManager.isLoading)
        .accessibilityIdentifier("premium.product.\(product.id)")
        .task(id: scenePhase) {
            hasEligibleWeekTrial = false
            guard scenePhase == .active,
                  let subscription = product.subscription,
                  let offer = subscription.introductoryOffer,
                  offer.paymentMode == .freeTrial,
                  offer.periodCount == 1,
                  (offer.period.unit == .week && offer.period.value == 1)
                    || (offer.period.unit == .day && offer.period.value == 7) else { return }
            let eligible = await subscription.isEligibleForIntroOffer
            guard !Task.isCancelled else { return }
            hasEligibleWeekTrial = eligible
        }
    }
    
    private var productTitle: String {
        localizationManager.localizedString(isYearlyProduct ? "Yearly Premium Title" : "Monthly Premium Title")
    }

    private var durationText: String {
        localizationManager.localizedString(isYearlyProduct ? "Duration: 1 year (auto-renewable)" : "Duration: 1 month (auto-renewable)")
    }
    
    private var isYearlyProduct: Bool {
        product.id.contains("Yearly") || product.id.contains("yearly")
    }
    
    private var savingsPercentage: Int {
        guard isYearlyProduct else { return 0 }
        guard let monthlyProduct = storeManager.monthlyProduct else {
            if let mock = storeManager.monthlyMockProduct {
                let monthly12 = NSDecimalNumber(decimal: mock.price).doubleValue * 12
                let yearly = NSDecimalNumber(decimal: product.price).doubleValue
                guard monthly12 > 0 else { return 0 }
                return Int((monthly12 - yearly) / monthly12 * 100)
            }
            return 0
        }
        let monthly12 = NSDecimalNumber(decimal: monthlyProduct.price).doubleValue * 12
        let yearly = NSDecimalNumber(decimal: product.price).doubleValue
        guard monthly12 > 0 else { return 0 }
        return Int((monthly12 - yearly) / monthly12 * 100)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Premium Feature Row Component
struct PremiumFeatureRow: View {
    let title: String
    let description: String
    let icon: String
    var iconImageName: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let name = iconImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

// MARK: - Subscription Cancellation Confirmation View
/// Принимает gameState и userProfile параметрами, чтобы не зависеть от environment в fullScreenCover (где он может отсутствовать).
struct SubscriptionCancellationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gameState: GameState
    @ObservedObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header with sad emoji
                        VStack(spacing: 16) {
                            Image(systemName: "face.sad.fill")
                                .font(.system(size: 80))
                            
                            Text(localizationManager.localizedString("Нам очень жаль, что вы отменили премиум подписку"))
                                .font(.system(size: 24, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                        
                        // User's premium period results
                        VStack(spacing: 20) {
                            Text(localizationManager.localizedString("Ваши результаты за период премиум подписки:"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 16) {
                                ResultCard(
                                    icon: "🏁",
                                    title: localizationManager.localizedString("Изучено флагов"),
                                    value: "\(userProfile.correctAnswers)",
                                    color: .blue
                                )
                                
                                ResultCard(icon: "", systemImageName: "target", title: localizationManager.localizedString("Лучший результат"), value: "\(userProfile.bestScore) \(localizationManager.localizedString("очков"))", color: .orange)
                                ResultCard(icon: "", systemImageName: "flame.fill", iconImageName: "StatDayStreak", title: localizationManager.localizedString("Текущая серия"), value: "\(userProfile.streak) \(localizationManager.localizedString("дней"))", color: .red)
                                ResultCard(icon: "", systemImageName: "checkmark.circle.fill", title: localizationManager.localizedString("Точность"), value: String(format: "%.1f%%", min(100.0, max(0.0, userProfile.accuracy))), color: .green)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // Encouragement message
                        VStack(spacing: 12) {
                            Text(localizationManager.localizedString("Теперь вы можете без единой ошибки отвечать на все наши вопросы с точностью в \(Int(userProfile.accuracy))%"))
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            Text(localizationManager.localizedString("Мы будем рады, если вы захотите снова вернуться к нам!"))
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        // Continue button — сброс подписки после dismiss
                        Button(action: {
                            GameState.userDidCancelSubscription = true
                            StoreManager.shared.cancelMockSubscription()
                            gameState.isPremium = false
                            dismiss()
                        }) {
                            Text(localizationManager.localizedString("Продолжить"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Result Card Component
struct ResultCard: View {
    let icon: String
    var systemImageName: String? = nil
    var iconImageName: String? = nil
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let assetName = iconImageName {
                    Image(assetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(color)
                } else if let name = systemImageName {
                    Image(systemName: name)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                } else {
                    Text(icon)
                        .font(.system(size: 32))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#if DEBUG
// MARK: - Mock Premium Product Button for Development (only in DEBUG)
struct MockPremiumProductButton: View {
    let mockProduct: MockProduct
    let storeManager: StoreManager
    let gameState: GameState
    let onPurchaseComplete: () -> Void

    private var mockSavingsPercentage: Int? {
        guard mockProduct.id.contains("Yearly"),
              let monthly = storeManager.monthlyMockProduct else { return nil }
        let monthly12 = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        let yearly = NSDecimalNumber(decimal: mockProduct.price).doubleValue
        guard monthly12 > 0 else { return nil }
        return Int((monthly12 - yearly) / monthly12 * 100)
    }

    var body: some View {
        Button {
            // Симулируем покупку в режиме разработки
            Task {
                // Добавляем небольшую задержку для реалистичности
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
                
                // Симулируем успешную покупку через StoreManager
                storeManager.simulateMockPurchase(productID: mockProduct.id)
                GameState.userDidCancelSubscription = false
                await gameState.syncPremiumStatus()
                
                print("🔧 Mock purchase successful: \(mockProduct.id)")
                onPurchaseComplete()
            }
        } label: {
            VStack(spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mockProduct.displayName + " (Dev)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Development Mode")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text(mockProduct.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if mockProduct.id.contains("Yearly"), let pct = mockSavingsPercentage {
                    HStack {
                        Text("Save \(pct)%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: mockProduct.id.contains("Yearly")
                    ? [Color.green.opacity(0.3), Color.blue.opacity(0.3)]
                    : [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}
#endif