import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct QuestResultsView: View {
    let dailyQuests: [DailyQuest]
    let monthlyQuests: [MonthlyQuest]
    let onContinue: () -> Void
    let onPlayAgain: () -> Void
    let onHome: () -> Void
    let onShare: () -> Void

    @State private var openedGiftIndices: Set<Int> = []
    @State private var giftOpeningIndex: Int? = nil
    @State private var lastRewardText: String? = nil
    @State private var showGiftRewardOverlay: String? = nil
    @State private var showContent = false
    @State private var showDailyQuests = false
    @State private var showMonthlyQuests = false
    @State private var showButton = false
    @State private var titleScale: CGFloat = 0.8
    @State private var safeTopInset: CGFloat = 0
    @State private var pendingMonthlyRewardToasts: [MonthlyQuestCompletionReward] = []
    @State private var currentMonthlyRewardToast: MonthlyQuestCompletionReward? = nil
    @State private var displayedDailyQuests: [DailyQuest] = []
    @State private var displayedMonthlyQuests: [MonthlyQuest] = []

    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Add top spacing to avoid status bar
                Spacer()
                    .frame(height: safeTopInset + 20)
                
                Spacer()
                
                // Title section
                VStack(spacing: 12) {
                    Text(localizationManager.localizedString("Quest Update!"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .scaleEffect(titleScale)
                    
                    Text(localizationManager.localizedString("Check your progress"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -30)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Daily Quests Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizationManager.localizedString("Daily Quests"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(displayedDailyQuests.enumerated()), id: \.element.id) { index, quest in
                                    QuestResultRow(
                                        quest: quest,
                                        delay: Double(index) * 0.1,
                                        isVisible: showDailyQuests,
                                        isGiftOpened: openedGiftIndices.contains(index),
                                        isGiftOpening: giftOpeningIndex == index,
                                        onGiftTap: quest.isCompleted && !openedGiftIndices.contains(index) ? { openGift(at: index) } : nil
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .opacity(showDailyQuests ? 1 : 0)
                        .offset(y: showDailyQuests ? 0 : 30)
                        
                        // Monthly Quests Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizationManager.localizedString("Monthly Quest"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(displayedMonthlyQuests.enumerated()), id: \.element.id) { index, quest in
                                    MonthlyQuestResultRow(
                                        quest: quest,
                                        delay: Double(index) * 0.1,
                                        isVisible: showMonthlyQuests
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .opacity(showMonthlyQuests ? 1 : 0)
                        .offset(y: showMonthlyQuests ? 0 : 30)
                    }
                    .padding(.bottom, 24)
                }
                
                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Нижний блок с кнопками — только здесь фон, контент выше не перекрывается
            VStack(spacing: 15) {
                Button(action: onPlayAgain) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(localizationManager.localizedString("Play Again"))
                    }
                    .font(.system(size: 18, weight: .bold))
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
                    .cornerRadius(28)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
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
                        .frame(height: 48)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(24)
                    }
                    
                    Button(action: onHome) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text(localizationManager.localizedString("Home"))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(24)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
            .padding(.bottom, 24)
            #if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.8)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: showButton)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SafeTopInsetKeyQuest.self, value: geo.safeAreaInsets.top)
            }
        )
        .onPreferenceChange(SafeTopInsetKeyQuest.self) { safeTopInset = $0 }
        .onAppear {
            openedGiftIndices = QuestService.shared.openedDailyGiftIndices()
            refreshDisplayedQuestsForCurrentLanguage()
            startAnimations()
            pendingMonthlyRewardToasts = UserProfile.shared.consumeRecentMonthlyQuestRewards()
            showNextMonthlyRewardToastIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshDisplayedQuestsForCurrentLanguage()
        }
        .overlay(alignment: .top) {
            VStack(spacing: 10) {
                if let text = lastRewardText {
                    Text(text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .scale))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { lastRewardText = nil }
                        }
                }

                if let rewardToast = currentMonthlyRewardToast {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.22))
                                .frame(width: 38, height: 38)
                            Image(systemName: rewardToast.questIcon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(localizationManager.localizedString("Monthly Quest"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(rewardToast.questTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            Text(monthlyRewardSummaryText(rewardToast))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    #if os(iOS)
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.96))
                    #else
                    .background(Color(NSColor.controlBackgroundColor))
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: .green.opacity(0.2), radius: 10, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 56)
        }
        .overlay {
            if let text = showGiftRewardOverlay {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("🎁")
                            .font(.system(size: 70))
                            .scaleEffect(1.0)
                        Text(text)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(40)
                    #if os(iOS)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    #else
                    .background(Color(NSColor.controlBackgroundColor))
                    #endif
                    .cornerRadius(24)
                    .shadow(radius: 20)
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showGiftRewardOverlay = nil }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showGiftRewardOverlay)
    }

    @MainActor
    private func openGift(at index: Int) {
        guard (0..<3).contains(index), !openedGiftIndices.contains(index) else {
            openedGiftIndices = QuestService.shared.openedDailyGiftIndices()
            return
        }
        guard displayedDailyQuests.indices.contains(index), displayedDailyQuests[index].isCompleted else {
            openedGiftIndices = QuestService.shared.openedDailyGiftIndices()
            return
        }
        guard let reward = QuestService.shared.openDailyGift(index: index, allQuestsCompleted: displayedDailyQuests[index].isCompleted) else {
            openedGiftIndices = QuestService.shared.openedDailyGiftIndices()
            return
        }
        giftOpeningIndex = index
        reward.apply(to: UserProfile.shared)
        let rewardText: String = {
            switch reward {
            case .xpBoost2x10min: return localizationManager.localizedString("2x XP for 10 min!")
            case .xpBoost3x10min: return localizationManager.localizedString("3x XP for 10 min!")
            case .fBucks1: return "+1 F-Bucks"
            case .fBucks2: return "+2 F-Bucks"
            }
        }()
        withAnimation(.easeInOut(duration: 0.3)) {
            openedGiftIndices.insert(index)
        }
        lastRewardText = rewardText
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            showGiftRewardOverlay = rewardText
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            giftOpeningIndex = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showGiftRewardOverlay = nil
            }
        }
    }

    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
            titleScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            showDailyQuests = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            showMonthlyQuests = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            showButton = true
        }
    }

    private func monthlyRewardSummaryText(_ reward: MonthlyQuestCompletionReward) -> String {
        if reward.fBucks > 0 {
            return "+\(reward.xp) XP • +\(reward.fBucks) F-Bucks"
        }
        return "+\(reward.xp) XP"
    }

    private func showNextMonthlyRewardToastIfNeeded() {
        guard currentMonthlyRewardToast == nil, !pendingMonthlyRewardToasts.isEmpty else { return }
        let next = pendingMonthlyRewardToasts.removeFirst()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            currentMonthlyRewardToast = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentMonthlyRewardToast = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                showNextMonthlyRewardToastIfNeeded()
            }
        }
    }

    private func refreshDisplayedQuestsForCurrentLanguage() {
        displayedDailyQuests = dailyQuests.map { quest in
            DailyQuest(
                title: localizedDailyQuestTitle(for: quest),
                target: quest.target,
                progress: quest.progress,
                icon: quest.icon,
                kind: quest.kind
            )
        }
        displayedMonthlyQuests = monthlyQuests.map { quest in
            MonthlyQuest(
                id: quest.id,
                title: localizedMonthlyQuestTitle(for: quest),
                description: localizedMonthlyQuestDescription(for: quest),
                targetValue: quest.targetValue,
                currentValue: quest.currentValue,
                questType: quest.questType,
                xpReward: quest.xpReward,
                icon: quest.icon,
                color: quest.color
            )
        }
    }

    private func localizedDailyQuestTitle(for quest: DailyQuest) -> String {
        switch quest.kind {
        case .gamesPlayed:
            return String(format: localizationManager.localizedString("Сыграй %d игр"), quest.target)
        case .correctAnswers:
            return String(format: localizationManager.localizedString("Дай %d правильных ответов"), quest.target)
        case .xpEarned:
            return String(format: localizationManager.localizedString("Заработай %d XP"), quest.target)
        }
    }

    private func localizedMonthlyQuestTitle(for quest: MonthlyQuest) -> String {
        switch quest.questType {
        case .gamesPlayed:
            return String(format: localizationManager.localizedString("Сыграй %d игр"), quest.targetValue)
        case .accuracy:
            return String(format: localizationManager.localizedString("Точность %d%%"), quest.targetValue)
        case .streak:
            return String(format: localizationManager.localizedString("Серия %d дней"), quest.targetValue)
        case .correctAnswers:
            return String(format: localizationManager.localizedString("Дай %d правильных ответов"), quest.targetValue)
        case .perfectGames:
            return String(format: localizationManager.localizedString("Сыграй %d идеальных игр"), quest.targetValue)
        case .monthlyXP:
            return String(format: localizationManager.localizedString("Заработай %d XP за месяц"), quest.targetValue)
        }
    }

    private func localizedMonthlyQuestDescription(for quest: MonthlyQuest) -> String {
        switch quest.questType {
        case .gamesPlayed:
            return String(format: localizationManager.localizedString("Завершите %d игр в этом месяце"), quest.targetValue)
        case .accuracy:
            return String(format: localizationManager.localizedString("Достигните точности %d%% в играх"), quest.targetValue)
        case .streak:
            return String(format: localizationManager.localizedString("Поддерживайте серию %d дней подряд"), quest.targetValue)
        case .correctAnswers:
            return String(format: localizationManager.localizedString("Наберите %d правильных ответов за месяц"), quest.targetValue)
        case .perfectGames:
            return String(format: localizationManager.localizedString("Завершите %d игр без ошибок"), quest.targetValue)
        case .monthlyXP:
            return String(format: localizationManager.localizedString("Заработайте %d XP играя минимум 7 дней в месяц"), quest.targetValue)
        }
    }
}

// Safe area inset key for QuestResultsView
private struct SafeTopInsetKeyQuest: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if os(iOS)
/// Кнопка подарка через UIKit — тап гарантированно не забирается ScrollView.
private struct GiftButtonUIKit: UIViewRepresentable {
    let isOpening: Bool
    let onTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.text = "🎁"
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 56),
            container.heightAnchor.constraint(equalToConstant: 56),
        ])
        context.coordinator.label = label
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.label?.text = isOpening ? "✨" : "🎁"
        context.coordinator.label?.transform = CGAffineTransform(scaleX: isOpening ? 1.4 : 1.0, y: isOpening ? 1.4 : 1.0)
        context.coordinator.label?.alpha = isOpening ? 0.6 : 1.0
        context.coordinator.onTap = onTap
        uiView.isUserInteractionEnabled = !isOpening
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator: NSObject {
        var onTap: () -> Void
        weak var label: UILabel?
        init(onTap: @escaping () -> Void) { self.onTap = onTap }
        @objc func tapped() { onTap() }
    }
}
#endif

struct QuestResultRow: View {
    let quest: DailyQuest
    let delay: Double
    let isVisible: Bool
    var isGiftOpened: Bool = false
    var isGiftOpening: Bool = false
    var onGiftTap: (() -> Void)? = nil

    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Text(quest.icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

            // Quest info
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(quest.isCompleted ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * (quest.isCompleted ? 1.0 : Double(quest.progress) / Double(quest.target)), height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(quest.progress) / \(quest.target)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Gift box: tappable when all daily completed and this one not opened
            if quest.isCompleted {
                if isGiftOpened {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else if let onGiftTap = onGiftTap {
                    #if os(iOS)
                    GiftButtonUIKit(isOpening: isGiftOpening, onTap: onGiftTap)
                    #else
                    Button(action: onGiftTap) {
                        ZStack {
                            Text(isGiftOpening ? "✨" : "🎁")
                                .font(.system(size: 28))
                                .scaleEffect(isGiftOpening ? 1.4 : 1.0)
                                .opacity(isGiftOpening ? 0.6 : 1)
                        }
                        .frame(minWidth: 56, minHeight: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isGiftOpening)
                    #endif
                } else {
                    Text("🎁")
                        .font(.system(size: 24))
                }
            } else {
                Text("📦")
                    .font(.system(size: 24))
                    .opacity(0.5)
            }
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -50)
        .animation(
            .easeOut(duration: 0.6)
            .delay(delay),
            value: isVisible
        )
        .animation(.easeInOut(duration: 0.25), value: isGiftOpening)
        .modifier(QuestRowTapModifier(questCompleted: quest.isCompleted, hasGiftButton: onGiftTap != nil))
    }
}

/// Жест на строку только когда подарка нет (уже открыт) — иначе тап по подарку забирает кнопка.
private struct QuestRowTapModifier: ViewModifier {
    let questCompleted: Bool
    let hasGiftButton: Bool
    
    func body(content: Content) -> some View {
        if questCompleted && !hasGiftButton {
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    #if os(iOS)
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    #endif
                }
        } else {
            content
        }
    }
}

struct MonthlyQuestResultRow: View {
    let quest: MonthlyQuest
    let delay: Double
    let isVisible: Bool
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: quest.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(quest.color)
                .cornerRadius(12)
            
            // Quest info
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(quest.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(quest.color)
                            .frame(width: geometry.size.width * (quest.isCompleted ? 1.0 : quest.progress), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(quest.currentValue) / \(quest.targetValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                        
                        Text("+\(quest.xpReward) XP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if quest.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -50)
        .animation(
            .easeOut(duration: 0.6)
            .delay(delay),
            value: isVisible
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard quest.isCompleted else { return }
            #if os(iOS)
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            #endif
        }
    }
}

#Preview {
    QuestResultsView(
        dailyQuests: [
            DailyQuest(title: "Complete 2 lessons", target: 2, progress: 0, icon: "📚", kind: .gamesPlayed),
            DailyQuest(title: "Do 1 challenge", target: 1, progress: 0, icon: "🎯", kind: .correctAnswers),
            DailyQuest(title: "Complete 3 perfect lessons", target: 3, progress: 1, icon: "⭐", kind: .xpEarned)
        ],
        monthlyQuests: [
            MonthlyQuest(id: UUID(), title: "Play 20 games", description: "Complete 20 games this month", targetValue: 20, currentValue: 24, questType: .gamesPlayed, xpReward: 100, icon: "🎮", color: .blue)
        ],
        onContinue: {},
        onPlayAgain: {},
        onHome: {},
        onShare: {}
    )
}
