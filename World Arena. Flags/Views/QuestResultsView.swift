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
    @State private var giftOverlayScale: CGFloat = 0.4
    @State private var giftOverlayGlow: Bool = false

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
                    .padding(.bottom, 0)
                }
                
                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Нижний блок с кнопками (Play again / Share / Home)
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
            .padding(.top, 8)
            .padding(.bottom, 18)
            #if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.8)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: showButton)
        }
        .overlay {
            if let text = showGiftRewardOverlay {
                ZStack {
                    // Затемнение всего экрана
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()

                    // Взрыв / открытие подарка
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.yellow.opacity(0.5), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 220
                                )
                            )
                            .scaleEffect(giftOverlayGlow ? 1.4 : 0.8)
                            .opacity(0.9)

                        VStack(spacing: 20) {
                            Text("🎁")
                                .font(.system(size: 90))
                                .shadow(color: .yellow.opacity(0.6), radius: 20, x: 0, y: 10)
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
                        .cornerRadius(30)
                        .shadow(color: .yellow.opacity(0.4), radius: 30, x: 0, y: 12)
                        .scaleEffect(giftOverlayScale)
                    }
                    .padding(24)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showGiftRewardOverlay = nil
                    }
                }
                .onAppear {
                    giftOverlayScale = 0.4
                    giftOverlayGlow = false
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                        giftOverlayScale = 1.05
                    }
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        giftOverlayGlow = true
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showGiftRewardOverlay)
        .onAppear {
            openedGiftIndices = QuestService.shared.openedDailyGiftIndices()
            refreshDisplayedQuestsForCurrentLanguage()
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshDisplayedQuestsForCurrentLanguage()
        }
    }
}

extension QuestResultsView {
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
    }

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

    private func refreshDisplayedQuestsForCurrentLanguage() {
        QuestService.shared.refreshQuestLocalization(save: false)
        displayedDailyQuests = QuestService.shared.dailyQuests
        displayedMonthlyQuests = UserProfile.shared.monthlyQuests
    }
}

private struct QuestResultRow: View {
    let quest: DailyQuest
    let delay: Double
    let isVisible: Bool
    let isGiftOpened: Bool
    let isGiftOpening: Bool
    var onGiftTap: (() -> Void)?

    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(quest.icon)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.14))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(quest.isCompleted ? Color.green : Color.orange)
                            .frame(width: geo.size.width * min(1, max(0, Double(quest.progress) / Double(max(quest.target, 1)))), height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(quest.progress) / \(quest.target)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if quest.isCompleted {
                if let onGiftTap {
                    Button(action: onGiftTap) {
                        Text(isGiftOpened ? "✅" : "🎁")
                            .font(.system(size: 24))
                            .scaleEffect(isGiftOpening ? 1.25 : 1.0)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 22))
                }
            }
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(14)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.easeOut(duration: 0.45).delay(delay), value: isVisible)
    }
}

private struct MonthlyQuestResultRow: View {
    let quest: MonthlyQuest
    let delay: Double
    let isVisible: Bool

    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quest.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(quest.color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(quest.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
            Text("+\(quest.xpReward) XP")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(cardBackground)
        .cornerRadius(14)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.easeOut(duration: 0.45).delay(delay), value: isVisible)
    }
}
