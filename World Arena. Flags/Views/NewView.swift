import SwiftUI
import StoreKit

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
                    onContinue: {
                        gameState.pendingDuelResult = nil
                        next()
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
                        onContinue: { onFinish() },
                        onPlayAgain: {
                            onPlayAgain?()
                        },
                        onHome: {
                            onFinish()
                            onHome?()
                        },
                        onShare: {
                            ShareService.shared.shareGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed)
                        }
                    )
                } else {
                    FriendStreaksView(
                        friends: friends,
                        gameState: gameState,
                        onRemind: { friend in
                            let me = UserProfile.shared.username
                            guard !me.isEmpty else { return nil }
                            let phraseId = Int.random(in: 0..<15)
                            do {
                                try await DuelAPIService.shared.sendNudge(fromUsername: me, toUsername: friend.username, phraseId: phraseId)
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
                        ShareService.shared.shareGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed)
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
                        // Share logic
                        ShareService.shared.shareGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed)
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
                                Text(friend.displayAvatar)
                                    .font(.system(size: friend.countryCode != nil ? 24 : 18, weight: .semibold))
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.blue.opacity(0.2)))
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
                Section {
                    Button(action: startDuelWithRandom) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text(localizationManager.localizedString("Random opponent"))
                        }
                    }
                    .disabled(isStarting || userProfile.friends.isEmpty)
                }
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
        }
    }
    
    private func startDuel(with friend: Friend) {
        guard !isStarting, gameState.canStartGameWithLives() else { return }
        isStarting = true
        let seed = Int.random(in: 0..<Int.max)
        let myName = userProfile.username
        Task {
            var challengeId = UUID().uuidString
            if let serverId = try? await DuelAPIService.shared.createChallenge(
                opponentId: friend.username,
                opponentName: friend.username,
                seed: seed,
                challengerName: myName,
                challengerId: myName
            ) {
                challengeId = serverId
            }
            let challenge = DuelChallenge(
                id: challengeId,
                challengerId: myName,
                challengerName: myName,
                opponentId: friend.id.uuidString,
                opponentName: friend.username,
                seed: seed,
                createdAt: Date(),
                challengerScore: nil,
                opponentScore: nil,
                status: .pending
            )
            await MainActor.run {
                userProfile.outgoingDuelChallenges.append(challenge)
                gameState.selectedPlayMode = .duel
                gameState.duelSeed = seed
                gameState.duelChallengeId = challengeId
                gameState.duelOpponentId = friend.id.uuidString
                gameState.duelChallengerName = myName
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Аватар (флаг страны или первая буква)
            ZStack {
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 100, height: 100)
                Text(friend.displayAvatar)
                    .font(.system(size: friend.countryCode != nil ? 56 : 48, weight: .bold))
            }
            
            Text(friend.displayNameOrUsername)
                .font(.system(size: 24, weight: .bold))
            
            HStack(spacing: 16) {
                stat("🔥", String(format: "%d", friend.streak), LocalizationManager.shared.localizedString("days"))
                stat("⚡", String(format: "%d", friend.xp), "XP")
                stat("🏆", LocalizationManager.shared.localizedString("Diamond"), LocalizationManager.shared.localizedString("League"))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            // Кнопка «Вызвать на дуэль»
            Button(action: { startDuel() }) {
                HStack {
                    Text("⚔️")
                    Text(localizationManager.localizedString("Challenge to Duel"))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .disabled(isStartingDuel || !gameState.canStartGameWithLives())
            
            Spacer()
            
            // Кнопка удаления друга
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "person.badge.minus")
                        .foregroundColor(.red)
                    Text(localizationManager.localizedString("Удалить из друзей"))
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
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.top, 40)
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
    }
    
    private func removeFriend() {
        userProfile.friends.removeAll { $0.id == friend.id }
        userProfile.saveToStorage()
        dismiss()
    }
    
    private func startDuel() {
        guard !isStartingDuel, gameState.canStartGameWithLives() else { return }
        isStartingDuel = true
        let seed = Int.random(in: 0..<Int.max)
        let myName = userProfile.username
        Task {
            var challengeId = UUID().uuidString
            if let serverId = try? await DuelAPIService.shared.createChallenge(
                opponentId: friend.username,
                opponentName: friend.username,
                seed: seed,
                challengerName: myName,
                challengerId: myName
            ) {
                challengeId = serverId
            }
            let challenge = DuelChallenge(
                id: challengeId,
                challengerId: myName,
                challengerName: myName,
                opponentId: friend.id.uuidString,
                opponentName: friend.username,
                seed: seed,
                createdAt: Date(),
                challengerScore: nil,
                opponentScore: nil,
                status: .pending
            )
            await MainActor.run {
                userProfile.outgoingDuelChallenges.append(challenge)
                gameState.selectedPlayMode = .duel
                gameState.duelSeed = seed
                gameState.duelChallengeId = challengeId
                gameState.duelOpponentId = friend.id.uuidString
                gameState.duelChallengerName = myName
            }
            await gameState.startNewGameWithCurrentRegions()
            await MainActor.run {
                isStartingDuel = false
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private func stat(_ icon: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title2)
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PremiumView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var animate = false
    @StateObject private var storeManager = StoreManager.shared
    @State private var showParentalGate = false
    @State private var parentalGateCompleted = false
    
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
                                .scaleEffect(animate ? 1.05 : 0.95)
                                .opacity(0.9)
                                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 80 : 64, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, isIPad ? 40 : 30)
                        .onAppear { 
                            animate = true
                            Task {
                                await storeManager.loadProducts()
                            }
                        }
                        .overlay(
                            ParentalGateOverlay(
                                isPresented: $showParentalGate,
                                onSuccess: {
                                    parentalGateCompleted = true
                                }
                            )
                        )
                        
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
                        }
                        .padding(isIPad ? 24 : 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(isIPad ? 20 : 16)
                        .padding(.horizontal, isIPad ? 40 : 20)
                        
                        // Purchase Options
                        VStack(spacing: 12) {
                            if storeManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                    .padding()
                            } else if !storeManager.hasProducts {
                                VStack(spacing: 16) {
                                    if let errorMessage = storeManager.errorMessage {
                                        VStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 32))
                                                .foregroundColor(.orange)
                                            Text("Unable to load products")
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
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                    // Плейсхолдеры подписок (Release: продукты не загрузились — по нажатию пробуем загрузить; после загрузки появятся цены и кнопки оформления)
                                    PremiumPlaceholderRow(
                                        title: LocalizationManager.shared.localizedString("Premium Monthly"),
                                        isYearly: false,
                                        isLoading: storeManager.isLoading
                                    ) {
                                        Task { await storeManager.loadProducts() }
                                    }
                                    PremiumPlaceholderRow(
                                        title: LocalizationManager.shared.localizedString("Yearly Premium"),
                                        isYearly: true,
                                        isLoading: storeManager.isLoading
                                    ) {
                                        Task { await storeManager.loadProducts() }
                                    }
                                    Button {
                                        Task { await storeManager.loadProducts() }
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
                                        .padding(.vertical, 12)
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
                                        gameState: gameState,
                                        parentalGateCompleted: parentalGateCompleted,
                                        onParentalGateRequired: {
                                            showParentalGate = true
                                        }
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
                            
                            // Restore Purchases
                            Button("Restore Purchases") {
                                Task {
                                    await storeManager.restorePurchases()
                                    if storeManager.isPremium {
                                        gameState.isPremium = true
                                        dismiss()
                                    }
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        
                        Button(LocalizationManager.shared.localizedString("NO THANKS")) {
                            dismiss()
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 30)
                    }
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
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 24))
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

    /// Цена и название плана из StoreKit (по региону пользователя) или мок
    private var monthlyDisplayPrice: String {
        if let p = storeManager.product(for: "WorldArena.Flags.MonthPremium2025") { return p.displayPrice }
        if let m = storeManager.mockProduct(for: "WorldArena.Flags.MonthPremium2025") { return m.displayPrice }
        return "$1.99"
    }

    private var monthlyPlanDisplayName: String {
        if let p = storeManager.product(for: "WorldArena.Flags.MonthPremium2025") { return p.displayName }
        if let m = storeManager.mockProduct(for: "WorldArena.Flags.MonthPremium2025") { return m.displayName }
        return "Premium Monthly"
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
                        
                        Text(localizationManager.localizedString("Управление подпиской"))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(localizationManager.localizedString("Ваша премиум подписка активна"))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    // Current Plan
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localizedString("Текущий план"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(monthlyPlanDisplayName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("\(localizationManager.localizedString("Цена")): \(monthlyDisplayPrice)/\(localizationManager.localizedString("месяц"))")
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
                        Text(localizationManager.localizedString("Информация о платежах"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            InfoRow(
                                title: localizationManager.localizedString("Дата начала"),
                                value: formatDate(subscriptionData.startDate),
                                icon: "calendar.badge.plus"
                            )
                            
                            InfoRow(
                                title: localizationManager.localizedString("Следующий платеж"),
                                value: formatDate(subscriptionData.nextBillingDate),
                                icon: "calendar.badge.clock"
                            )
                            
                            InfoRow(
                                title: localizationManager.localizedString("Статус"),
                                value: localizationManager.localizedString("Активна"),
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
                        Text(localizationManager.localizedString("Премиум преимущества"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                title: localizationManager.localizedString("Безлимитные жизни"),
                                description: localizationManager.localizedString("Играйте без ожидания"),
                                icon: "heart.fill",
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
                                title: localizationManager.localizedString("Мои ошибки"),
                                description: localizationManager.localizedString("Анализ ваших ошибок"),
                                icon: "exclamationmark.bubble.fill",
                                color: Color.orange
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
                            Text(localizationManager.localizedString("Отменить подписку"))
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
                    Button(localizationManager.localizedString("Закрыть")) {
                        dismiss()
                    }
                }
            }
        }
        .alert(localizationManager.localizedString("Отменить подписку"), isPresented: $showCancelAlert) {
            Button(localizationManager.localizedString("Отмена"), role: .cancel) { }
            Button(localizationManager.localizedString("Отменить"), role: .destructive) {
                // Здесь будет логика отмены подписки через StoreKit
                print("Отмена подписки")
                showCancellationView = true
            }
        } message: {
            Text(localizationManager.localizedString("Вы уверены, что хотите отменить премиум подписку? Вы потеряете доступ ко всем премиум функциям."))
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
                    if isYearly {
                        Text(LocalizationManager.shared.localizedString(Self.tapToLoadKey))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
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
            .padding(.vertical, 12)
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
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Premium Product Button
struct PremiumProductButton: View {
    let product: Product
    let storeManager: StoreManager
    let gameState: GameState
    let parentalGateCompleted: Bool
    let onParentalGateRequired: () -> Void
    let onPurchaseComplete: () -> Void
    
    var body: some View {
        Button {
            // Проверяем parental gate для Kids category
            if !parentalGateCompleted {
                onParentalGateRequired()
                return
            }
            
            Task {
                let success = await storeManager.purchase(product)
                if success {
                    gameState.isPremium = true
                    onPurchaseComplete()
                }
            }
        } label: {
            VStack(spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(productTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let pricePerMonth = monthlyPrice {
                            Text(pricePerMonth)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if isYearlyProduct && savingsPercentage > 0 {
                    HStack {
                        Text("Save \(savingsPercentage)%")
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: isYearlyProduct ? [.green.opacity(0.3), .blue.opacity(0.3)] : [.purple.opacity(0.3), .blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isYearlyProduct ? Color.green.opacity(0.5) : Color.purple.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .disabled(storeManager.isLoading)
    }
    
    private var productTitle: String {
        product.displayName
    }
    
    private var isYearlyProduct: Bool {
        product.id.contains("Yearly") || product.id.contains("yearly")
    }
    
    private var monthlyPrice: String? {
        if isYearlyProduct {
            let monthly = product.price / 12
            let n = NSDecimalNumber(decimal: monthly).doubleValue
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: n)) ?? String(format: "%.2f", n)
            return "\(str)/\(LocalizationManager.shared.localizedString("месяц"))"
        }
        return nil
    }
    
    private var savingsPercentage: Int {
        guard isYearlyProduct else { return 0 }
        guard let monthlyProduct = storeManager.product(for: "WorldArena.Flags.MonthPremium2025") else {
            if let mock = storeManager.mockProduct(for: "WorldArena.Flags.MonthPremium2025") {
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
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
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
                            Text("😢")
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
                                
                                ResultCard(
                                    icon: "🎯",
                                    title: localizationManager.localizedString("Лучший результат"),
                                    value: "\(userProfile.bestScore) \(localizationManager.localizedString("очков"))",
                                    color: .orange
                                )
                                
                                ResultCard(
                                    icon: "🔥",
                                    title: localizationManager.localizedString("Текущая серия"),
                                    value: "\(userProfile.streak) \(localizationManager.localizedString("дней"))",
                                    color: .red
                                )
                                
                                ResultCard(
                                    icon: "✅",
                                    title: localizationManager.localizedString("Точность"),
                                    value: String(format: "%.1f%%", min(100.0, max(0.0, userProfile.accuracy))),
                                    color: .green
                                )
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
                        
                        // Continue button — сброс подписки после dismiss (gameState передан параметром, не через environment)
                        Button(action: {
                            dismiss()
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 с после закрытия
                                StoreManager.shared.cancelMockSubscription()
                                gameState.isPremium = false
                            }
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
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
            
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
              let monthly = storeManager.mockProduct(for: "WorldArena.Flags.MonthPremium2025") else { return nil }
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
                
                // Синхронизируем статус с GameState
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