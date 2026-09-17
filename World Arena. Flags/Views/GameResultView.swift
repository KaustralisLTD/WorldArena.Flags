import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct GameResultView: View {
    let score: Int
    let totalQuestions: Int
    let timeElapsed: TimeInterval
    var duelResult: DuelResultInfo? = nil
    var bonusXP: Int = 0
    var earnedFBucks: Int = 0
    var appliedXPBoostMultiplier: Int = 1
    var xpBoostRemainingSeconds: Int? = nil
    var detailedResults: [GameQuestionResult] = []
    var isTimeChallengeResult: Bool = false
    var timeChallengeBestCombo: Int = 0
    var timeChallengeIsNewBestScore: Bool = false
    var timeChallengeBestScore: Int = 0
    var timeChallengeDailyRank: Int? = nil
    var timeChallengeWeeklyRank: Int? = nil
    var isSurvivalResult: Bool = false
    /// Вопросов сыграно до конца забега
    var survivalRunDepth: Int = 0
    var survivalRunMaxStage: Int = 1
    var survivalPersonalBestDisplay: Int = 0
    var survivalIsNewBestDepth: Bool = false
    var survivalSessionBestCombo: Int = 0
    let onContinue: () -> Void
    var onPlayAgain: (() -> Void)? = nil
    var onBackHome: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    
    @State private var showContent = false
    @State private var showScore = false
    
    private var systemGray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    @State private var showStats = false
    @State private var showButton = false
    @State private var scoreScale: CGFloat = 0.5
    @State private var characterScale: CGFloat = 0.8
    @State private var sparkleOpacity: Double = 0
    @State private var confettiAnimation = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var bounceAnimation = false
    @State private var glowOpacity: Double = 0
    @State private var showDetailedResults = false
    
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var tcCorrectCount: Int { detailedResults.filter(\.isCorrect).count }
    private var tcAnsweredCount: Int { detailedResults.count }
    private var endlessRunResult: Bool { isTimeChallengeResult || isSurvivalResult }
    private var correctAnswersForXP: Int { endlessRunResult ? tcCorrectCount : score }
    private var baseXP: Int { correctAnswersForXP * 10 + bonusXP }
    private var boostedXP: Int { baseXP * max(1, appliedXPBoostMultiplier) }
    /// Доля верных для эмодзи/конфетти (TC / Survival — по фактическим ответам).
    private var resultAccuracyRatio: Double {
        let den = max(1, endlessRunResult ? tcAnsweredCount : totalQuestions)
        let num = Double(endlessRunResult ? tcCorrectCount : score)
        return num / Double(den)
    }

    private var survivalNextMilestoneLine: String? {
        guard isSurvivalResult else { return nil }
        let c = tcCorrectCount
        guard let next = [10, 25, 50, 100, 200].first(where: { $0 > c }) else { return nil }
        let left = next - c
        return String(format: localizationManager.localizedString("Survival next milestone fmt"), left, next)
    }

    private var survivalSecondaryFooterVisible: Bool {
        survivalIsNewBestDepth || survivalNextMilestoneLine != nil
    }

    // Верхний safe-area inset для корректного отступа фиксированной шапки на iPhone.
    private var statusBarSafeTopInset: CGFloat {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return 0
        }
        return window.safeAreaInsets.top
        #else
        return 0
        #endif
    }

    /// Баннер «осталось X:XX» с обратным отсчётом каждую секунду (данные из UserProfile).
    @ViewBuilder
    private var xpBoostRemainingBanner: some View {
        let sec = UserProfile.shared.xpBoostRemainingSeconds ?? 0
        if sec > 0 {
            let m = sec / 60
            let s = sec % 60
            let timeStr = String(format: "%d:%02d", m, s)
            let boostName = appliedXPBoostMultiplier >= 3
                ? localizationManager.localizedString("triple XP")
                : localizationManager.localizedString("double XP")
            let message = String(format: localizationManager.localizedString("XP boost you have remaining"), timeStr, boostName)
            Text(message)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.top, 8)
        }
    }

    private var timeChallengeSecondaryFooterVisible: Bool {
        timeChallengeIsNewBestScore || timeChallengeDailyRank != nil || timeChallengeWeeklyRank != nil
    }

    /// Заголовок режима и личный рекорд — над карточками XP / статистики (не в нижней панели кнопок).
    private var timeChallengeResultsSummaryBlock: some View {
        let titleGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.22), Color.purple.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(titleGradient)
            }
            Text(localizationManager.localizedString("Time Challenge"))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
            Text(String(format: localizationManager.localizedString("TC best correct record"), timeChallengeBestScore))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(systemGray6)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    private var survivalResultsSummaryBlock: some View {
        let titleGradient = LinearGradient(
            colors: [Color.orange, Color.red],
            startPoint: .leading,
            endPoint: .trailing
        )
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.25), Color.red.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(titleGradient)
            }
            Text(localizationManager.localizedString("Survival"))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
            Text(String(format: localizationManager.localizedString("Survival result best depth fmt"), survivalPersonalBestDisplay))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(String(format: localizationManager.localizedString("Survival result combo fmt"), survivalSessionBestCombo))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(systemGray6)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.45), Color.red.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    /// Рекорд + мильстоун Survival — над блоком «Выживание» и карточками XP (раньше было в нижней панели).
    private var survivalNewRecordMilestoneBlock: some View {
        VStack(spacing: 10) {
            if survivalIsNewBestDepth {
                Text(localizationManager.localizedString("New record!"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
            if let line = survivalNextMilestoneLine {
                Text(line)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(systemGray6)
        .cornerRadius(16)
    }

    var body: some View {
        ZStack {
            // Animated background gradient
            AnimatedBackgroundView()
            .ignoresSafeArea()
            
            
            // Confetti particles
            if confettiAnimation {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                if let duel = duelResult {
                    VStack(spacing: 0) {
                        duelResultCard(duel)
                            .padding(.horizontal, 20)
                            // Смещаем шапку ниже времени/батареи примерно на одну строку.
                            .padding(.top, statusBarSafeTopInset + 12)
                            .padding(.bottom, 16)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.05),
                                        Color.white.opacity(0.22),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // Base material
                            Rectangle().fill(.ultraThinMaterial)
                            // Subtle premium-like tint to make it feel "designed", not just a card.
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.10),
                                    Color.purple.opacity(0.08),
                                    Color.blue.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    #if os(iOS)
                    .cornerRadius(26, corners: [.bottomLeft, .bottomRight])
                    #endif
                    .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 12)
                    .overlay(alignment: .top) {
                        // Top sheen line
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .ignoresSafeArea()
                    }
                }
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        if duelResult == nil {
                            Color.clear.frame(height: 1).padding(.top, 16)
                        }
                        // Main result section with enhanced animations
                        VStack(spacing: 25) {
                            // Animated character with glow effect
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [characterColor.opacity(glowOpacity), Color.clear],
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowOpacity)
                                
                                // Background circle with gradient
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [characterColor.opacity(0.3), characterColor.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .scaleEffect(characterScale)
                                    .rotationEffect(.degrees(rotationAngle))
                                    .shadow(color: characterColor.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                // Character emoji with bounce
                                Text(characterEmoji)
                                    .font(.system(size: 70))
                                    .scaleEffect(characterScale)
                                    .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatForever(autoreverses: true), value: bounceAnimation)
                                
                                // Enhanced sparkles with rotation
                                ForEach(0..<8, id: \.self) { index in
                                    Text(sparkleEmojis[index % sparkleEmojis.count])
                                        .font(.system(size: 25))
                                        .offset(
                                            x: sparklePositions[index].x,
                                            y: sparklePositions[index].y
                                        )
                                        .opacity(sparkleOpacity)
                                        .rotationEffect(.degrees(rotationAngle + Double(index * 45)))
                                        .animation(
                                            .easeInOut(duration: 2)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.15),
                                            value: sparkleOpacity
                                        )
                                }
                            }
                            
                            // Score and message with enhanced styling
                            VStack(spacing: 12) {
                                // Main score message
                                Text(scoreMessage)
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [characterColor, characterColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(scoreScale)
                                    .shadow(color: characterColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                // Итог: в TC — число верных и подпись очков; в классике — score / total
                                Group {
                                    if isSurvivalResult {
                                        // Верхний счётчик: верные / сыграно в забеге (не «глубина / размер пула», иначе при ошибках показывается 53/53 вместо 51/53).
                                        Text(String(
                                            format: localizationManager.localizedString("Survival result depth progress fmt"),
                                            tcCorrectCount,
                                            tcAnsweredCount
                                        ))
                                            .font(.system(size: 26, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                        Text(String(format: localizationManager.localizedString("Survival result stage reached fmt"), survivalRunMaxStage))
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    } else if isTimeChallengeResult {
                                        Text(String(format: localizationManager.localizedString("TC correct answers headline"), tcCorrectCount))
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text("\(score) / \(totalQuestions)")
                                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(systemGray6)
                                        .overlay(
                                            Capsule()
                                                .stroke(characterColor.opacity(0.5), lineWidth: 2)
                                        )
                                )
                                
                                // Encouragement message
                                Text(encouragementMessage)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }

                            if isSurvivalResult {
                                if survivalSecondaryFooterVisible {
                                    survivalNewRecordMilestoneBlock
                                }
                                survivalResultsSummaryBlock
                            }
                            if isTimeChallengeResult {
                                timeChallengeResultsSummaryBlock
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        
                        // Enhanced stats cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            EnhancedStatCard(
                                title: localizationManager.localizedString("XP EARNED"),
                                value: "\(boostedXP)",
                                oldValue: appliedXPBoostMultiplier > 1 ? "\(baseXP)" : nil,
                                boostMultiplier: appliedXPBoostMultiplier,
                                combineTitleWithOldValue: true,
                                icon: "",
                                iconImageName: "ResultXP",
                                systemImageName: "bolt.fill",
                                color: .orange,
                                isVisible: showStats,
                                delay: 0
                            )
                            
                            if isTimeChallengeResult {
                                EnhancedStatCard(
                                    title: localizationManager.localizedString("TC stat best combo"),
                                    value: "\(timeChallengeBestCombo)",
                                    icon: "🔥",
                                    iconImageName: nil,
                                    color: .orange,
                                    isVisible: showStats,
                                    delay: 0.1
                                )
                            } else if isSurvivalResult {
                                EnhancedStatCard(
                                    title: localizationManager.localizedString("Survival stat correct"),
                                    value: "\(tcCorrectCount)",
                                    icon: "✅",
                                    iconImageName: nil,
                                    color: .green,
                                    isVisible: showStats,
                                    delay: 0.1
                                )
                            } else {
                                EnhancedStatCard(
                                    title: localizationManager.localizedString("ACCURACY"),
                                    value: accuracyValue,
                                    icon: "🎯",
                                    iconImageName: "ResultAccuracy",
                                    color: .green,
                                    isVisible: showStats,
                                    delay: 0.1
                                )
                            }
                            
                            EnhancedStatCard(
                                title: localizationManager.localizedString("TIME"),
                                value: formattedTime,
                                icon: "",
                                iconImageName: "ResultTime",
                                systemImageName: "clock.fill",
                                color: .blue,
                                isVisible: showStats,
                                delay: 0.2
                            )

                            if earnedFBucks > 0 {
                                EnhancedStatCard(
                                    title: localizationManager.localizedString("F-BUCKS EARNED"),
                                    value: "\(earnedFBucks)",
                                    icon: "",
                                    iconImageName: "ResultFBucks",
                                    systemImageName: nil,
                                    color: Color(red: 0.85, green: 0.6, blue: 0.1),
                                    isVisible: showStats,
                                    delay: 0.3
                                )
                            }
                        }
                        .opacity(showStats ? 1 : 0)
                        .offset(y: showStats ? 0 : 50)
                        if appliedXPBoostMultiplier > 1 {
                            TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                                xpBoostRemainingBanner
                            }
                        }
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: .infinity)
                
                VStack(spacing: 14) {
                    if !detailedResults.isEmpty {
                        Button(action: { showDetailedResults = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(localizationManager.localizedString("View Detailed Results"))
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(systemGray6)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary.opacity(0.16), lineWidth: 1)
                            )
                        }
                    }

                    if isTimeChallengeResult && timeChallengeSecondaryFooterVisible {
                        VStack(spacing: 10) {
                            if timeChallengeIsNewBestScore {
                                Text(localizationManager.localizedString("New record!"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                            }
                            if let daily = timeChallengeDailyRank {
                                Text("\(localizationManager.localizedString("Day leaderboard place")): #\(daily)")
                                    .font(.system(size: 14, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                            if let weekly = timeChallengeWeeklyRank {
                                Text("\(localizationManager.localizedString("Week leaderboard place")): #\(weekly)")
                                    .font(.system(size: 14, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(systemGray6)
                        .cornerRadius(16)
                    }

                    if isTimeChallengeResult || isSurvivalResult {
                        Button(action: { onPlayAgain?() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text(localizationManager.localizedString("Play Again"))
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isSurvivalResult
                                        ? [Color.orange, Color.red]
                                        : [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(
                                color: (isSurvivalResult ? Color.orange : Color.blue).opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                        }
                        HStack(spacing: 15) {
                            Button(action: { onShare?() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(localizationManager.localizedString("Share"))
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSurvivalResult ? .orange : .blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background((isSurvivalResult ? Color.orange : Color.blue).opacity(0.1))
                                .cornerRadius(24)
                            }
                            Button(action: { onBackHome?() }) {
                                HStack(spacing: 8) {
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
                    } else {
                        Button(action: onContinue) {
                            HStack(spacing: 12) {
                                Text(localizationManager.localizedString("CONTINUE"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(32)
                            .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.8)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                .padding(.horizontal, 30)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .sheetOrFullScreenOnIPad(isPresented: $showDetailedResults) {
            GameDetailedResultsView(results: detailedResults, isTimeChallenge: isTimeChallengeResult)
        }
        .onAppear {
            startEnhancedAnimations()
        }
    }
    
    // MARK: - Computed Properties
    
    private var characterEmoji: String {
        let accuracy = resultAccuracyRatio
        if accuracy == 1.0 {
            return "🏆" // Trophy for perfect score
        } else if accuracy >= 0.9 {
            return "🦉" // Owl for excellent score
        } else if accuracy >= 0.8 {
            return "🌟" // Star for great score
        } else if accuracy >= 0.6 {
            return "👏" // Clapping for good score
        } else {
            return "💪" // Flexed biceps for encouragement
        }
    }
    
    private var characterColor: Color {
        let accuracy = resultAccuracyRatio
        if accuracy == 1.0 {
            return .yellow
        } else if accuracy >= 0.9 {
            return .orange
        } else if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .blue
        } else {
            return .purple
        }
    }
    
    private var scoreMessage: String {
        let accuracy = resultAccuracyRatio
        if accuracy == 1.0 {
            return localizationManager.localizedString("PERFECT!")
        } else if accuracy >= 0.9 {
            return localizationManager.localizedString("EXCELLENT!")
        } else if accuracy >= 0.8 {
            return localizationManager.localizedString("GREAT JOB!")
        } else if accuracy >= 0.6 {
            return localizationManager.localizedString("GOOD EFFORT!")
        } else {
            return localizationManager.localizedString("KEEP TRYING!")
        }
    }
    
    private var encouragementMessage: String {
        let accuracy = resultAccuracyRatio
        if accuracy == 1.0 {
            return localizationManager.localizedString("Absolutely incredible! You're a true champion! 🎉")
        } else if accuracy >= 0.9 {
            return localizationManager.localizedString("Outstanding performance! You're almost perfect! ✨")
        } else if accuracy >= 0.8 {
            return localizationManager.localizedString("Fantastic work! You're doing amazing! 🚀")
        } else if accuracy >= 0.6 {
            return localizationManager.localizedString("Nice job! Keep up the great work! 💫")
        } else {
            return localizationManager.localizedString("Don't give up! Every expert was once a beginner! 🌱")
        }
    }
    
    private var accuracyValue: String {
        let accuracy = Double(score) / Double(totalQuestions) * 100
        return "\(Int(accuracy))%"
    }
    
    private var formattedTime: String {
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var sparkleEmojis: [String] {
        ["✨", "⭐", "🌟", "💫", "🎆", "🎇", "✨", "⭐"]
    }
    
    private var sparklePositions: [CGPoint] {
        [
            CGPoint(x: -60, y: -40),
            CGPoint(x: 60, y: -40),
            CGPoint(x: -50, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: -70, y: 0),
            CGPoint(x: 70, y: 0),
            CGPoint(x: 0, y: -60),
            CGPoint(x: 0, y: 60)
        ]
    }
    
    private func duelResultCard(_ duel: DuelResultInfo) -> some View {
        let isPending = duel.isPending
        let yourScore = duel.yourScore
        let otherScore = duel.otherScore

        let winnerText: String = {
            if isPending {
                return "\(yourScore) : \(localizationManager.localizedString("Waiting for result"))"
            }
            if duel.iWon {
                return "\(localizationManager.localizedString("You won!")) \(yourScore) : \(otherScore)"
            }
            if duel.youAreChallenger {
                return "\(yourScore) : \(otherScore)"
            }
            return "\(duel.challengerName) \(localizationManager.localizedString("won"))"
        }()
        
        let rewardText = duel.iWon ? "+1 F-Bucks" : ""
        let challengerScoreText: String = {
            if isPending && !duel.youAreChallenger { return "—" }
            return "\(duel.challengerScore)"
        }()
        let opponentScoreText: String = {
            if isPending && duel.youAreChallenger {
                return localizationManager.localizedString("Waiting for result")
            }
            return "\(duel.opponentScore)"
        }()
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                // Premium-like badge
                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.18))
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.85),
                                    Color.purple.opacity(0.75),
                                    Color.blue.opacity(0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.2
                        )
                        .blur(radius: 0.1)
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.2)
                }
                .overlay {
                    Group {
                        if #available(iOS 16.0, *) {
                            Text(localizationManager.localizedString("Duel").uppercased())
                                .tracking(1.1)
                        } else {
                            Text(localizationManager.localizedString("Duel").uppercased())
                            // kerning недоступен на iOS < 16 — просто оставляем дефолтное кернинг.
                        }
                    }
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
                .frame(width: 74, height: 26)
                .shadow(color: Color.orange.opacity(0.28), radius: 10, x: 0, y: 6)

                Text(localizationManager.localizedString("Duel result"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer(minLength: 0)

                if !rewardText.isEmpty {
                    Text(rewardText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.14))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
            }

            Text(winnerText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor((duel.iWon || isPending) ? .orange : .primary)

            Text("\(duel.challengerName): \(challengerScoreText)  •  \(duel.opponentName): \(opponentScoreText)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if duel.showsTieTimeBreakdown,
               let ct = duel.challengerTimeMs,
               let ot = duel.opponentTimeMs {
                DuelTieBreakFootnote(
                    challengerName: duel.challengerName,
                    opponentName: duel.opponentName,
                    challengerTimeMs: ct,
                    opponentTimeMs: ot,
                    compact: false
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Enhanced Animations
    
    private func startEnhancedAnimations() {
        // Initial content appearance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            showContent = true
        }
        
        // Character and score scaling
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            scoreScale = 1.0
            characterScale = 1.0
        }
        
        // Sparkles and glow
        withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
            sparkleOpacity = 1.0
            glowOpacity = 0.6
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(0.5)) {
            rotationAngle = 360
        }
        
        // Bounce animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            bounceAnimation = true
        }
        
        // Stats cards
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.8)) {
            showStats = true
        }
        
        // Continue button
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.2)) {
            showButton = true
        }
        
        // Pulse animation for button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pulseAnimation = true
        }
        
        // Confetti for perfect score
        if resultAccuracyRatio >= 0.9 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                confettiAnimation = true
            }
        }
    }
}

private struct GameDetailedResultsView: View {
    let results: [GameQuestionResult]
    var isTimeChallenge: Bool = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private var secondaryGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(results) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("#\(item.questionNumber)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(item.isCorrect ? "✅ \(localizationManager.localizedString("Correct"))" : "❌ \(localizationManager.localizedString("Wrong"))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(item.isCorrect ? .green : .red)
                            }
                            Text(item.flagEmoji)
                                .font(.system(size: 28))
                            Text("\(localizationManager.localizedString("Flag")): \(localizationManager.localizedCountryDisplayName(iso2Code: item.correctCountryCode, englishFallback: item.flagName))")
                                .font(.system(size: 16, weight: .semibold))
                            if item.timedOut {
                                Text(localizationManager.localizedString("Time is up"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            } else if let selected = item.selectedAnswer {
                                Text("\(localizationManager.localizedString("Your answer")): \(localizationManager.localizedCountryDisplayName(iso2Code: item.selectedCountryCode, englishFallback: selected))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            if isTimeChallenge {
                                if let xp = item.xpAwardedThisQuestion, xp > 0 {
                                    Text(String(format: localizationManager.localizedString("TC detail xp earned"), xp))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                if let sec = item.timeAdjustmentSeconds {
                                    if sec < 0 {
                                        Text(String(
                                            format: localizationManager.localizedString("TC detail time penalty fmt"),
                                            abs(sec),
                                            localizationManager.localizedString("Time seconds unit short")
                                        ))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.red)
                                    } else if sec > 0 {
                                        Text(String(
                                            format: localizationManager.localizedString("TC detail time combo fmt"),
                                            sec,
                                            localizationManager.localizedString("Time seconds unit short")
                                        ))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(secondaryGroupedBackground)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(localizationManager.localizedString("Detailed Results"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("Close")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Enhanced Stat Card

struct EnhancedStatCard: View {
    let title: String
    let value: String
    var oldValue: String? = nil
    var boostMultiplier: Int = 1
    /// Когда true, первая строка: [oldValue перечёркнуто] + " " + title (одна строка «320 XP EARNED»)
    var combineTitleWithOldValue: Bool = false
    let icon: String
    /// Имя изображения в Assets для иконки (если задано — показывается вместо emoji).
    var iconImageName: String? = nil
    /// SF Symbol (приоритет над icon).
    var systemImageName: String? = nil
    let color: Color
    let isVisible: Bool
    let delay: Double
    
    @State private var cardScale: CGFloat = 0.8
    @State private var iconBounce: Bool = false
    @State private var glowPulse: Bool = false
    @State private var backgroundWave: Bool = false
    @State private var numberCountUp: Double = 0
    @State private var revealBoostedValue = false
    @State private var oldValueStriked = false
    @State private var boostedScale: CGFloat = 1.0
    @State private var strikeProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Modern icon container
            ZStack {
                // Animated background circles
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: backgroundWave ? 60 : 50, height: backgroundWave ? 60 : 50)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: backgroundWave)
                
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: glowPulse ? 45 : 40, height: glowPulse ? 45 : 40)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)
                
                // Glassmorphism background
                Circle()
                    .fill(.ultraThinMaterial, style: FillStyle())
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [color.opacity(0.6), color.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                if let name = iconImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .scaleEffect(iconBounce ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: iconBounce)
                } else {
                    Text(icon)
                        .font(.system(size: 20, weight: .bold))
                        .scaleEffect(iconBounce ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: iconBounce)
                }
            }
            
            VStack(spacing: 1) {
                if combineTitleWithOldValue, let oldValue, revealBoostedValue {
                    HStack(spacing: 4) {
                        ZStack {
                            Text(oldValue)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .overlay(alignment: .leading) {
                                    GeometryReader { geo in
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.9))
                                            .frame(width: geo.size.width * strikeProgress, height: 1.6)
                                            .offset(y: geo.size.height * 0.52)
                                    }
                                }
                        }
                        Text(title)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if let oldValue, revealBoostedValue {
                    ZStack {
                        Text(oldValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .overlay(alignment: .leading) {
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.9))
                                        .frame(width: geo.size.width * strikeProgress, height: 1.6)
                                        .offset(y: geo.size.height * 0.52)
                                }
                            }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                if !combineTitleWithOldValue || oldValue == nil || !revealBoostedValue {
                    Text(getAnimatedValue())
                        .font(.system(size: (oldValue != nil && revealBoostedValue) ? 30 : 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(boostedScale)
                        .animation(.easeOut(duration: 0.8).delay(delay), value: numberCountUp)
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: boostedScale)
                } else {
                    Text(getAnimatedValue())
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(boostedScale)
                        .animation(.easeOut(duration: 0.8).delay(delay), value: numberCountUp)
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: boostedScale)
                }

                if boostMultiplier > 1 {
                    Text("x\(boostMultiplier)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.75)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Если combineTitleWithOldValue=true, то заголовок обычно показывается только в строке с oldValue.
            // Когда буста нет (oldValue=nil), всё равно показываем подпись, чтобы не было голого числа.
            if !combineTitleWithOldValue || oldValue == nil {
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            ZStack {
                // Glassmorphism card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial, style: FillStyle())
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.05),
                                Color.clear,
                                color.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Animated border glow
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                color.opacity(glowPulse ? 0.6 : 0.3),
                                color.opacity(0.1),
                                color.opacity(glowPulse ? 0.4 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)
            }
        )
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        .scaleEffect(cardScale)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            if isVisible {
                startCardAnimations()
            }
        }
        .onChange(of: isVisible) { newValue in
            if newValue {
                startCardAnimations()
            }
        }
    }
    
    private func getAnimatedValue() -> String {
        if value.contains("%") {
            return String(format: "%.0f%%", numberCountUp)
        } else if value.contains(":") {
            // Time format - convert back from seconds to M:SS
            let totalSeconds = Int(numberCountUp)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%.0f", numberCountUp)
        }
    }
    
    private func extractNumericValue() -> Double? {
        // Handle time format (M:SS)
        if value.contains(":") {
            let components = value.components(separatedBy: ":")
            if components.count == 2,
               let minutes = Double(components[0]),
               let seconds = Double(components[1]) {
                return minutes * 60 + seconds
            }
        }
        
        // Handle percentage
        if value.contains("%") {
            let cleanValue = value.replacingOccurrences(of: "%", with: "")
            return Double(cleanValue)
        }
        
        // Handle regular numbers
        let cleanValue = value.replacingOccurrences(of: "s", with: "")
            .replacingOccurrences(of: "min", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleanValue)
    }
    
    private func startCardAnimations() {
        // Staggered entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay)) {
            cardScale = 1.0
        }
        
        // Start continuous animations
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
            iconBounce = true
            glowPulse = true
            backgroundWave = true

            let newNumeric = extractNumericValue() ?? 0
            if let oldValue, let oldNumeric = extractNumericValue(from: oldValue) {
                // 1) Показываем базовый XP, 2) зачёркиваем, 3) крупно показываем boosted XP.
                numberCountUp = oldNumeric
                revealBoostedValue = false
                oldValueStriked = false
                boostedScale = 1.0
                strikeProgress = 0

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        revealBoostedValue = true
                        oldValueStriked = true
                    }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        strikeProgress = 1
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        numberCountUp = newNumeric
                        boostedScale = 1.14
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            boostedScale = 1.0
                        }
                    }
                }
            } else {
                numberCountUp = newNumeric
            }
        }
    }

    private func extractNumericValue(from rawValue: String) -> Double? {
        if rawValue.contains(":") {
            let components = rawValue.components(separatedBy: ":")
            if components.count == 2,
               let minutes = Double(components[0]),
               let seconds = Double(components[1]) {
                return minutes * 60 + seconds
            }
        }
        if rawValue.contains("%") {
            let cleanValue = rawValue.replacingOccurrences(of: "%", with: "")
            return Double(cleanValue)
        }
        let cleanValue = rawValue.replacingOccurrences(of: "s", with: "")
            .replacingOccurrences(of: "min", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleanValue)
    }
}

// Карточка награды F-Bucks с миниатюрой (чип)
private struct FBucksEarnedCard: View {
    let title: String
    let earned: Int
    var iconImageName: String? = "ResultFBucks"
    let isVisible: Bool
    let delay: Double
    /// Контрастный золотой/янтарный, чтобы +1 не сливался со светлым фоном
    private let accentColor: Color = Color(red: 0.72, green: 0.45, blue: 0.05)
    private let cardTint: Color = Color(red: 0.85, green: 0.6, blue: 0.1)
    @State private var cardScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(cardTint.opacity(0.2))
                    .frame(width: 50, height: 50)
                if let name = iconImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                } else {
                    FBucksChipView(count: earned, size: .compact)
                }
            }
            Text("+\(earned)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.22), radius: 1, x: 0, y: 1)
                .shadow(color: accentColor.opacity(0.35), radius: 2, x: 0, y: 0)
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial, style: FillStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [cardTint.opacity(0.08), Color.clear, cardTint.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(cardTint.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: cardTint.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(cardScale)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            if isVisible {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay)) {
                    cardScale = 1.0
                }
            }
        }
    }
}

// MARK: - Animated Background

struct AnimatedBackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: animateGradient ? 
            [Color.blue.opacity(0.3), Color.purple.opacity(0.3), Color.pink.opacity(0.2)] :
            [Color.purple.opacity(0.2), Color.pink.opacity(0.3), Color.blue.opacity(0.3)],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(index: index, animate: $animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    @Binding var animate: Bool
    
    @State private var xPosition: CGFloat = 0
    @State private var yPosition: CGFloat = -100
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    private let shapes: [String] = ["●", "▲", "■", "♦", "★"]
    
    var body: some View {
        Text(shapes[index % shapes.count])
            .foregroundColor(colors[index % colors.count])
            .font(.system(size: CGFloat.random(in: 12...20)))
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: xPosition, y: yPosition)
            .onAppear {
                xPosition = CGFloat.random(in: 50...350)
                
                withAnimation(.linear(duration: Double.random(in: 2...4)).delay(Double.random(in: 0...2))) {
                    yPosition = 1000
                    rotation = Double.random(in: 0...720)
                    opacity = 0
                }
            }
    }
}

#Preview {
    GameResultView(
        score: 8,
        totalQuestions: 10,
        timeElapsed: 120,
        earnedFBucks: 1,
        onContinue: {}
    )
}