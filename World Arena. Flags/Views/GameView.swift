import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Обёртка над scrollDisabled для поддержки iOS 15 (модификатор доступен с iOS 16).
private struct ScrollDisabledIfAvailable: ViewModifier {
    let disabled: Bool
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDisabled(disabled)
        } else {
            content
        }
    }
}

/// Ограничение Dynamic Type в панелях игры — иначе при крупном шрифте системы ломается компоновка (сердца, уровень).
private struct GamePanelDynamicTypeCap: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.dynamicTypeSize(.medium)
        } else {
            content
        }
    }
}

struct ProgressBarView: View {
    let current: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 4) {
            // Текст прогресса с локализацией
            Text("\(current) \(LocalizationManager.shared.localizedString("of")) \(total) \(LocalizationManager.shared.localizedString("flags"))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Прогресс
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}

struct GameTimerView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showGameTimeInfo = false
    @State private var showQuestionTimeInfo = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Верхний: общее время игры (таймер с начала)
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(horizontalSizeClass == .regular ? .title2 : .title3)
                    .foregroundColor(.blue)
                    .frame(width: horizontalSizeClass == .regular ? 34 : 30, height: 34, alignment: .center)
                Text(gameState.formattedTime())
                    .font(horizontalSizeClass == .regular ? .title : .title2)
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(2)
                    .frame(minWidth: horizontalSizeClass == .regular ? 104 : 90, alignment: .leading)
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 18 : 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))
            .onTapGesture { showGameTimeInfo.toggle() }
            .popover(isPresented: $showGameTimeInfo) {
                Text(LocalizationManager.shared.localizedString("Total game time since start"))
                    .font(.headline)
                    .padding()
            }

            // Нижний: обратный отсчёт на вопрос
            HStack(spacing: 8) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(horizontalSizeClass == .regular ? .title3 : .headline)
                    .foregroundColor(.orange)
                    .frame(width: horizontalSizeClass == .regular ? 34 : 30, height: 34, alignment: .center)
                Text(String(format: "%.1f s", gameState.questionTimeLeft))
                    .font(horizontalSizeClass == .regular ? .title2 : .headline)
                    .monospacedDigit()
                    .foregroundColor(gameState.questionTimeLeft < 5 ? .red : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(2)
                    .frame(minWidth: horizontalSizeClass == .regular ? 84 : 72, alignment: .leading)
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 18 : 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))
            .onTapGesture { showQuestionTimeInfo.toggle() }
            .popover(isPresented: $showQuestionTimeInfo) {
                Text(LocalizationManager.shared.localizedString("Time limit per question depending on difficulty"))
                    .font(.headline)
                    .padding()
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    var onExit: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Левая колонка: ВЫХОД и регион+сложность
            VStack(alignment: .leading, spacing: 8) {
            ExitButton(action: onExit)
                VStack(alignment: .leading, spacing: 4) {
                    let regionDisplay = gameState.selectedRegions.count == 1 ? (gameState.selectedRegions.first?.displayName ?? "") : LocalizationManager.shared.localizedString("Multiple Regions")
                    Text(LocalizationManager.shared.localizedString(regionDisplay))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(gameState.selectedDifficulty.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))
            }

            Spacer(minLength: 8)

            // Центр: два таймера в две строки
            GameTimerView(gameState: gameState)

            Spacer(minLength: 8)

            // Правая колонка: жизни и прогресс флагов
            VStack(alignment: .trailing, spacing: 8) {
                if gameState.selectedPlayMode == .timeChallenge {
                    LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.timeChallengeSessionLives, isPremium: gameState.isPremium)
                } else if gameState.selectedPlayMode == .survival {
                    LivesView(lives: $gameState.survivalSessionLives, isPremium: false)
                } else {
                    LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.lives, isPremium: gameState.isPremium)
                }
                GameProgressView(gameState: gameState)
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 20 : 12)
        .padding(.top, horizontalSizeClass == .regular ? 8 : 6)
        .modifier(GamePanelDynamicTypeCap())
    }
}

// MARK: - life_loss_premium (0.62s): Impact → Crack → Break → Dissolve
private struct LifeLossCrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx - rect.width * 0.35, y: cy - rect.height * 0.2))
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx + rect.width * 0.3, y: cy + rect.height * 0.15))
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx - rect.width * 0.15, y: cy + rect.height * 0.4))
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx + rect.width * 0.25, y: cy - rect.height * 0.25))
        return p
    }
}

private struct HeartLoseAnimationView: View {
    let heartAsset: String
    let size: CGFloat
    let onComplete: () -> Void
    private let duration: Double = 0.62
    @State private var startDate = Date()
    @State private var hasCompleted = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var particleColors: [Color] { localizationManager.lifeLossParticleColors }

    private static let particleCount = 8
    private static let particleAngles: [Double] = [45, 70, 90, 120, 180, 240, 270, 315].map { $0 * .pi / 180 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let p = min(1, elapsed / duration)
            let impactEnd = 0.12 / duration
            let crackEnd = 0.28 / duration
            let breakEnd = 0.48 / duration

            ZStack {
                if p >= 1 {
                    Color.clear
                        .onAppear {
                            if !hasCompleted { hasCompleted = true; onComplete() }
                        }
                }

                if p < crackEnd {
                    let impactScale = p <= impactEnd ? 1.0 + (0.92 - 1.0) * (p / impactEnd) : 0.92
                    let impactRotation: Double = {
                        if p <= impactEnd * 0.4 { return -8 * (p / (impactEnd * 0.4)) }
                        if p <= impactEnd { return -8 + (5 - (-8)) * ((p - impactEnd * 0.4) / (impactEnd * 0.6)) }
                        return 5
                    }()
                    let redFlash: Double = p <= impactEnd ? (p <= impactEnd * 0.5 ? 0.2 * (p / (impactEnd * 0.5)) : 0.2 * (1 - (p - impactEnd * 0.5) / (impactEnd * 0.5))) : 0
                    let shakeX: CGFloat = p <= impactEnd ? 0 : crackShakeX(p, impactEnd: impactEnd, crackEnd: crackEnd)
                    let crackOpacity: Double = p <= impactEnd ? 0 : (p - impactEnd) / (crackEnd - impactEnd)
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(impactScale)
                        .rotationEffect(.degrees(impactRotation))
                        .overlay(Color.red.opacity(redFlash))
                        .overlay(
                            LifeLossCrackShape()
                                .stroke(Color.white.opacity(0.7), lineWidth: max(1, size * 0.02))
                                .opacity(crackOpacity)
                        )
                        .offset(x: shakeX, y: 0)
                }

                if p >= crackEnd {
                    let pieceProgress = p <= breakEnd ? (p - crackEnd) / (breakEnd - crackEnd) : 1
                    let pieceScale: CGFloat = p <= breakEnd ? 1.0 - (1.0 - 0.86) * pieceProgress : 0.86
                    let leftX: CGFloat = -10 * pieceProgress
                    let leftY: CGFloat = 6 * pieceProgress
                    let rightX: CGFloat = 10 * pieceProgress
                    let rightY: CGFloat = 6 * pieceProgress
                    let bottomY: CGFloat = 14 * pieceProgress
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(pieceScale)
                        .rotationEffect(.degrees(-12 * pieceProgress))
                        .offset(x: leftX, y: leftY)
                        .opacity(dissolveOpacity(p))
                        .blur(radius: dissolveBlur(p))
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(pieceScale)
                        .rotationEffect(.degrees(12 * pieceProgress))
                        .offset(x: rightX, y: rightY)
                        .opacity(dissolveOpacity(p))
                        .blur(radius: dissolveBlur(p))
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(pieceScale)
                        .offset(y: bottomY)
                        .opacity(dissolveOpacity(p))
                        .blur(radius: dissolveBlur(p))
                }

                if p >= breakEnd {
                    let dissolveProgress = (p - breakEnd) / (1 - breakEnd)
                    ForEach(0..<Self.particleCount, id: \.self) { i in
                        Circle()
                            .fill(particleColors[i % particleColors.count].opacity(0.85))
                            .frame(width: 5, height: 5)
                            .opacity(1 - dissolveProgress)
                            .offset(
                                x: cos(Self.particleAngles[i]) * 30 * dissolveProgress,
                                y: 18 * dissolveProgress + 8 * sin(Self.particleAngles[i]) * dissolveProgress
                            )
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear { startDate = Date() }
    }

    private func crackShakeX(_ p: Double, impactEnd: Double, crackEnd: Double) -> CGFloat {
        guard p > impactEnd else { return 0 }
        let t = (p - impactEnd) / (crackEnd - impactEnd)
        if t <= 0.25 { return -2 + (2 - (-2)) * (t / 0.25) }
        if t <= 0.5 { return 2 + (-1 - 2) * ((t - 0.25) / 0.25) }
        if t <= 0.75 { return -1 + (0 - (-1)) * ((t - 0.5) / 0.25) }
        return 0
    }

    private func dissolveOpacity(_ p: Double) -> Double {
        let breakEnd = 0.48 / duration
        guard p >= breakEnd else { return 1 }
        return 1 - (p - breakEnd) / (1 - breakEnd)
    }

    private func dissolveBlur(_ p: Double) -> CGFloat {
        let breakEnd = 0.48 / duration
        guard p >= breakEnd else { return 0 }
        return 6 * (p - breakEnd) / (1 - breakEnd)
    }
}

// MARK: - life_gain_premium (1.05s): Energy spawn → Materialize → Pulse → Shine → Fly to HUD + snap
private struct HeartGainAnimationView: View {
    let heartAsset: String
    let size: CGFloat
    let onComplete: () -> Void
    private let duration: Double = 1.05
    @State private var startDate = Date()
    @State private var hasCompleted = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var particleColors: [Color] { localizationManager.lifeLossParticleColors }

    private static let spawnParticleCount = 12
    private static let spawnAngles: [Double] = (0..<spawnParticleCount).map { Double($0) * (360.0 / Double(spawnParticleCount)) * .pi / 180 }
    private static let snapParticleCount = 6
    private static let snapAngles: [Double] = [0, 60, 120, 180, 240, 300].map { $0 * .pi / 180 }

    private var spawnEnd: Double { 0.18 / duration }
    private var materializeEnd: Double { 0.42 / duration }
    private var pulseEnd: Double { 0.58 / duration }
    private var shineEnd: Double { 0.70 / duration }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let p = min(1, elapsed / duration)

            ZStack {
                if p >= 1 {
                    Color.clear
                        .onAppear {
                            if !hasCompleted { hasCompleted = true; onComplete() }
                        }
                }

                if p < spawnEnd {
                    let t = p / spawnEnd
                    let radius: CGFloat = 24 * (1 - t)
                    ForEach(0..<Self.spawnParticleCount, id: \.self) { i in
                        Circle()
                            .fill(particleColors[i % particleColors.count])
                            .frame(width: 6, height: 6)
                            .scaleEffect(0.4 + 0.6 * t)
                            .opacity(t)
                            .blur(radius: 6 * (1 - t))
                            .offset(x: radius * CGFloat(cos(Self.spawnAngles[i])), y: radius * CGFloat(sin(Self.spawnAngles[i])))
                    }
                }

                if p >= spawnEnd {
                    let matT = min(1, (p - spawnEnd) / (materializeEnd - spawnEnd))
                    let scaleVal = 0.45 + (1.12 - 0.45) * easeOutBack(matT)
                    let rotationVal = -7 * (1 - matT)
                    let heartOpacity = matT <= 0.3 ? matT / 0.3 : 1
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(p >= pulseEnd ? flyScale(p) : (p >= materializeEnd ? pulseScale(p) : scaleVal))
                        .rotationEffect(.degrees(p >= materializeEnd ? 0 : rotationVal))
                        .opacity(p >= shineEnd ? 1 : heartOpacity)
                        .shadow(color: .white.opacity(0.35), radius: glowRadius(p))
                        .overlay(shineOverlay(p))
                        .offset(x: flyOffsetX(p), y: flyOffsetY(p))
                }

                if p >= shineEnd {
                    let snapT = (p - shineEnd) / (1 - shineEnd)
                    let showSnapBurst = snapT >= 0.85
                    if showSnapBurst {
                        ForEach(0..<Self.snapParticleCount, id: \.self) { i in
                            let burstProgress = min(1, (p - (shineEnd + 0.85 * (1 - shineEnd))) / (0.15 * (1 - shineEnd)))
                            Circle()
                                .fill(particleColors[i % particleColors.count].opacity(0.9))
                                .frame(width: 4, height: 4)
                                .opacity(1 - burstProgress)
                                .offset(
                                    x: cos(Self.snapAngles[i]) * 20 * burstProgress,
                                    y: sin(Self.snapAngles[i]) * 20 * burstProgress
                                )
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear { startDate = Date() }
    }

    private func easeOutBack(_ t: Double) -> Double {
        let s = 1.70158
        guard t < 1 else { return 1 }
        let u = t - 1
        return 1 + (s + 1) * u * u + s * u * u * u
    }

    private func pulseScale(_ p: Double) -> CGFloat {
        let t = (p - materializeEnd) / (pulseEnd - materializeEnd)
        if t <= 0.12 { return 1.12 - 0.12 * (t / 0.12) }
        if t <= 0.45 { return 1.0 + 0.08 * ((t - 0.12) / 0.33) }
        return 1.08 - 0.08 * ((t - 0.45) / 0.55)
    }

    private func glowRadius(_ p: Double) -> CGFloat {
        guard p >= materializeEnd, p < pulseEnd else { return 0 }
        let t = (p - materializeEnd) / (pulseEnd - materializeEnd)
        if t <= 0.5 { return 6 + 8 * (t / 0.5) }
        return 14 - 6 * ((t - 0.5) / 0.5)
    }

    @ViewBuilder
    private func shineOverlay(_ p: Double) -> some View {
        if p >= pulseEnd, p < shineEnd {
            let t = (p - pulseEnd) / (shineEnd - pulseEnd)
            LinearGradient(
                colors: [.clear, .white.opacity(0.5), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: size * 0.5, height: size)
            .offset(x: -size * 0.5 + size * t)
            .blendMode(.screen)
        }
    }

    private func flyScale(_ p: Double) -> CGFloat {
        if p < pulseEnd { return pulseScale(p) }
        if p < shineEnd { return 1.0 }
        let t = (p - shineEnd) / (1 - shineEnd)
        let base: CGFloat = 1.0 - 0.45 * t
        if t >= 0.9 {
            let snap = (t - 0.9) / 0.1
            if snap <= 0.5 { return base + 0.05 * (snap / 0.5) }
            return base + 0.05 - 0.05 * ((snap - 0.5) / 0.5)
        }
        return base
    }

    private func flyOffsetX(_ p: Double) -> CGFloat {
        guard p >= shineEnd else { return 0 }
        let t = (p - shineEnd) / (1 - shineEnd)
        return 4 * sin(t * .pi)
    }

    private func flyOffsetY(_ p: Double) -> CGFloat {
        guard p >= shineEnd else { return 0 }
        let t = (p - shineEnd) / (1 - shineEnd)
        return -3 * (1 - cos(t * .pi))
    }
}

/// Слот фиксированной ширины: ±10s появляется и гаснет без сдвига таймера.
private struct TimeChallengeDeltaSlot: View {
    let delta: Int
    let isIPad: Bool

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var displayDelta: Int = 0
    @State private var labelOpacity: Double = 0
    @State private var fadeWorkItem: DispatchWorkItem?

    private var slotWidth: CGFloat { isIPad ? 128 : 108 }
    private var fontSize: CGFloat { isIPad ? 30 : 24 }

    var body: some View {
        ZStack {
            Text(formattedText)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(displayDelta > 0 ? .green : .red)
                .monospacedDigit()
                .opacity(labelOpacity)
                .allowsHitTesting(false)
        }
        .frame(width: slotWidth, alignment: .center)
        .accessibilityHidden(displayDelta == 0 || labelOpacity < 0.01)
        .onChange(of: delta) { newValue in
            guard newValue != 0 else { return }
            fadeWorkItem?.cancel()
            displayDelta = newValue
            withAnimation(.easeOut(duration: 0.14)) {
                labelOpacity = 1
            }
            let work = DispatchWorkItem {
                withAnimation(.easeIn(duration: 0.55)) {
                    labelOpacity = 0
                }
            }
            fadeWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: work)
        }
    }

    private var formattedText: String {
        guard displayDelta != 0 else { return " " }
        let unit = localizationManager.localizedString("Time seconds unit short")
        return String(format: localizationManager.localizedString("Time TC delta seconds fmt"), displayDelta, unit)
    }
}

/// Закрытие игры после оверлея «жизни»: sheet Premium на корне не показывается поверх fullScreenCover — сначала закрываем игру, затем уведомление.
private enum OutOfLivesExitActions {
    @MainActor
    static func dismissOverlayAndLeaveGame(
        viewModel: GameViewModel,
        gameState: GameState,
        dismiss: DismissAction
    ) {
        viewModel.showingOutOfLives = false
        gameState.isPausedForOutOfLives = false
        gameState.stopTimer()
        gameState.resetGameState()
        gameState.isNavigatingToGame = false
        dismiss()
    }

    @MainActor
    static func leaveGameThenShowPremium(
        viewModel: GameViewModel,
        gameState: GameState,
        dismiss: DismissAction
    ) {
        viewModel.showingOutOfLives = false
        gameState.isPausedForOutOfLives = false
        gameState.stopTimer()
        gameState.resetGameState()
        gameState.isNavigatingToGame = false
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            NotificationCenter.default.post(name: Notification.Name("showPremiumFromHome"), object: nil)
        }
    }
}

// Общая шапка игры (телефон + iPad): подписи к таймерам, анимации, минуты/секунды без дробной части
private struct GameHeaderSectionView: View {
    @ObservedObject var gameState: GameState
    var safeTopInset: CGFloat
    var onExitTap: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var previousLives: Int = -1
    @State private var previousTCSessionLives: Int = -1
    @State private var previousSurvivalLives: Int = -1
    @State private var showLoseAnimation = false
    @State private var showGainAnimation = false
    @State private var livesCountPop = false
    @State private var showingDuelOpponentInfo = false

    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var isCompactPhone: Bool {
        #if os(iOS)
        return !isIPad && UIScreen.main.bounds.height <= 880
        #else
        return false
        #endif
    }

    private static let motivationKeys = (1...8).map { "Game motivation \($0)" }
    private var motivationPhrase: String {
        let index = gameState.currentQuestion % Self.motivationKeys.count
        return LocalizationManager.shared.localizedString(Self.motivationKeys[index])
    }

    private func formatGameTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: LocalizationManager.shared.localizedString("%d min %d sec"), minutes, remainingSeconds)
        } else {
            return String(format: LocalizationManager.shared.localizedString("%d sec"), remainingSeconds)
        }
    }

    private func fontSize(_ phone: CGFloat, iPad: CGFloat) -> CGFloat { isIPad ? iPad : phone }
    private var duelOpponentDisplayName: String {
        if gameState.selectedPlayMode == .duel {
            if gameState.duelRoleIsChallenger {
                if let name = gameState.duelOpponentName, !name.isEmpty { return name }
            } else {
                if let name = gameState.duelChallengerName, !name.isEmpty { return name }
            }
        }
        if let name = gameState.duelOpponentName, !name.isEmpty { return name }
        if let name = gameState.duelChallengerName, !name.isEmpty { return name }
        return LocalizationManager.shared.localizedString("Opponent")
    }

    @ViewBuilder
    private var duelBadgeView: some View {
        ZStack {
            Capsule().fill(Color.black.opacity(0.18))
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
                    Text(LocalizationManager.shared.localizedString("Duel").uppercased())
                        .tracking(1.1)
                } else {
                    Text(LocalizationManager.shared.localizedString("Duel").uppercased())
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
    }

    private var duelOpponentInfoCard: some View {
        HStack(spacing: 6) {
            Text(LocalizationManager.shared.localizedString("vs"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Text(duelOpponentDisplayName)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.28))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: onExitTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: fontSize(18, iPad: 22), weight: .semibold))
                            Text(LocalizationManager.shared.localizedString("Exit"))
                                .font(.system(size: fontSize(15, iPad: 19), weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isIPad ? 18 : 14)
                        .padding(.vertical, isIPad ? 12 : 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        )
                    }
                    if gameState.selectedPlayMode == .duel && !isIPad {
                        Button {
                            showingDuelOpponentInfo = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showingDuelOpponentInfo = false
                            }
                        } label: {
                            duelBadgeView
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, isIPad ? 24 : 20)
                .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 8)

                if isIPad {
                    Text(motivationPhrase)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 12)
                }
                if isIPad {
                    Spacer()
                }
                HStack(spacing: isIPad ? 20 : 16) {
                    if gameState.selectedPlayMode == .timeChallenge {
                        VStack(spacing: isIPad ? 6 : 4) {
                            Text(LocalizationManager.shared.localizedString("Time Challenge"))
                                .font(.system(size: fontSize(11, iPad: 15), weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            HStack(spacing: isIPad ? 10 : 8) {
                                TimeChallengeDeltaSlot(delta: gameState.timeChallengeLastTimeDelta, isIPad: isIPad)
                                Image(systemName: "timer")
                                    .font(.system(size: fontSize(26, iPad: 36)))
                                    .foregroundColor(gameState.timeChallengeRemainingTime <= 10 ? .red : .white.opacity(0.95))
                                Text(gameState.formattedTime(gameState.timeChallengeRemainingTime, includeFraction: false))
                                    .font(.system(size: fontSize(28, iPad: 40), weight: .bold))
                                    .foregroundColor(gameState.timeChallengeRemainingTime <= 10 ? .red : .white)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.55)
                                    .monospacedDigit()
                                    .layoutPriority(1)
                            }
                        }
                    } else {
                        VStack(spacing: isIPad ? 6 : 4) {
                            Text(LocalizationManager.shared.localizedString("Total Game Time"))
                                .font(.system(size: fontSize(9, iPad: 13), weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: fontSize(13, iPad: 18)))
                                    .foregroundColor(.white.opacity(0.95))
                                    .opacity(gameState.elapsedTime.truncatingRemainder(dividingBy: 2) < 1 ? 1.0 : 0.82)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameState.elapsedTime)
                                    .frame(width: fontSize(22, iPad: 28), height: fontSize(22, iPad: 28), alignment: .center)
                                Text(formatGameTime(gameState.elapsedTime))
                                    .font(.system(size: fontSize(13, iPad: 18), weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                    .frame(minWidth: fontSize(64, iPad: 86), alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: isIPad ? 6 : 4) {
                            Text(LocalizationManager.shared.localizedString("Time Per Question"))
                                .font(.system(size: fontSize(9, iPad: 13), weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            HStack(spacing: 6) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: fontSize(13, iPad: 18)))
                                    .foregroundColor(.white.opacity(0.95))
                                    .rotationEffect(.degrees(gameState.questionTimeLeft < 5 ? 180 : 0))
                                    .animation(.easeInOut(duration: 0.5), value: gameState.questionTimeLeft < 5)
                                Text("\(Int(gameState.questionTimeLeft))s")
                                    .font(.system(size: fontSize(13, iPad: 18), weight: .bold))
                                    .foregroundColor(gameState.questionTimeLeft < 5 ? .red : .white)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                    .monospacedDigit()
                                    .scaleEffect(gameState.questionTimeLeft < 5 ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: gameState.questionTimeLeft < 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.leading, isIPad ? 10 : 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, isIPad ? 16 : 14)
            }
            HStack(alignment: .center, spacing: isIPad ? 20 : 14) {
                VStack(alignment: .leading, spacing: isIPad ? 8 : 6) {
                    let regionDisplay = gameState.selectedRegions.count == 1 ? (gameState.selectedRegions.first?.displayName ?? "") : LocalizationManager.shared.localizedString("Multiple Regions")
                    Text(LocalizationManager.shared.localizedString(regionDisplay))
                        .font(.system(size: fontSize(12, iPad: 16), weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Text(gameState.selectedDifficulty.displayName)
                        .font(.system(size: fontSize(17, iPad: 22), weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .padding(.leading, isIPad ? 24 : 20)
                .layoutPriority(2)

                // Просто освобождаем пространство перед сердцами.
                Spacer(minLength: isIPad ? 6 : 4)
                HStack(spacing: 8) {
                    let heartAsset = LocalizationManager.shared.lifeHeartAssetName(forCountryCode: UserProfile.shared.selectedCountryCode)
                    let heartSize = fontSize(48, iPad: 64)
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: heartSize, height: heartSize)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    if gameState.isPremium && gameState.selectedPlayMode != .survival {
                        Image(systemName: "infinity")
                            .foregroundColor(.white)
                            .font(.system(size: fontSize(18, iPad: 24), weight: .bold))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    } else {
                        let livesShown: Int = {
                            switch gameState.selectedPlayMode {
                            case .timeChallenge: return gameState.timeChallengeSessionLives
                            case .survival: return gameState.survivalSessionLives
                            default: return gameState.lives
                            }
                        }()
                        Text("\(livesShown)")
                            .font(.system(size: (gameState.selectedPlayMode == .duel && !isIPad) ? 16 : fontSize(18, iPad: 24), weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .scaleEffect(livesCountPop ? 1.2 : 1.0)
                            .animation(.easeOut(duration: 0.15), value: livesCountPop)
                            .layoutPriority(2)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.horizontal, isIPad ? 8 : 6)
                .padding(.vertical, isIPad ? 6 : 5)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .layoutPriority(1)
                .overlay(alignment: .leading) {
                    let heartSize = fontSize(54, iPad: 72)
                    ZStack {
                        if showLoseAnimation, gameState.selectedPlayMode == .survival || !gameState.isPremium {
                            HeartLoseAnimationView(
                                heartAsset: LocalizationManager.shared.lifeHeartAssetName(forCountryCode: UserProfile.shared.selectedCountryCode),
                                size: heartSize
                            ) { showLoseAnimation = false }
                        }
                        if showGainAnimation, gameState.selectedPlayMode == .survival || !gameState.isPremium {
                            HeartGainAnimationView(
                                heartAsset: LocalizationManager.shared.lifeHeartAssetName(forCountryCode: UserProfile.shared.selectedCountryCode),
                                size: heartSize
                            ) {
                                showGainAnimation = false
                                livesCountPop = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { livesCountPop = false }
                            }
                        }
                    }
                    .frame(width: heartSize, height: heartSize)
                    .padding(.leading, isIPad ? 20 : 16)
                    .allowsHitTesting(false)
                }
                VStack(alignment: .trailing, spacing: isIPad ? 6 : 4) {
                    if gameState.selectedPlayMode == .survival {
                        Text(LocalizationManager.shared.localizedString("Survival depth header"))
                            .font(.system(size: fontSize(12, iPad: 16), weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text("\(gameState.currentQuestion + 1)")
                            .font(
                                .system(
                                    size: (gameState.selectedPlayMode == .duel && !isIPad) ? 15 : fontSize(17, iPad: 22),
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .monospacedDigit()
                            .frame(minWidth: 36, alignment: .trailing)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        Text(
                            String(
                                format: LocalizationManager.shared.localizedString("Survival stage fmt"),
                                GameState.survivalStage(forQuestionOneBased: gameState.currentQuestion + 1)
                            )
                        )
                        .font(.system(size: fontSize(11, iPad: 14), weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    } else {
                        Text(LocalizationManager.shared.localizedString("Flags"))
                            .font(.system(size: fontSize(12, iPad: 16), weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text("\(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
                            .font(
                                .system(
                                    size: (gameState.selectedPlayMode == .duel && !isIPad) ? 15 : fontSize(17, iPad: 22),
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .lineLimit(1)
                            .frame(minWidth: isIPad ? 88 : 76, alignment: .trailing)
                    }
                }
                .padding(.trailing, isIPad ? 16 : 14)
                .layoutPriority(4)
            }
            .padding(.top, isCompactPhone ? 8 : 14)
            .padding(.bottom, isIPad ? 24 : (isCompactPhone ? 12 : 20))

            if gameState.liveComboText != nil || gameState.liveBonusText != nil {
                LiveBonusBannerView(
                    comboText: gameState.liveComboText,
                    bonusText: gameState.liveBonusText,
                    isIPad: isIPad
                )
                .padding(.horizontal, isIPad ? 24 : 16)
                .padding(.top, isCompactPhone ? 4 : 6)
                .padding(.bottom, isCompactPhone ? 8 : 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            if showingDuelOpponentInfo && gameState.selectedPlayMode == .duel && !isIPad {
                duelOpponentInfoCard
                    .padding(.top, isCompactPhone ? 42 : 48)
                    .padding(.leading, 110)
                    .padding(.trailing, 80)
            }
        }
        // На iPhone с Dynamic Island / крупным статус-баром safeTopInset иногда недостаточен визуально.
        // Сдвигаем ВСЮ шапку ниже (оба ряда), чтобы не накладывалось на время/батарею.
        .padding(.top, safeTopInset + (isCompactPhone ? 16 : 14))
        .frame(height: (isIPad ? 170 : (isCompactPhone ? 120 : 140)) + safeTopInset, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.9),
                    Color.purple.opacity(0.75),
                    Color.pink.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            if previousLives < 0 { previousLives = gameState.lives }
            if previousTCSessionLives < 0 { previousTCSessionLives = gameState.timeChallengeSessionLives }
            if previousSurvivalLives < 0 { previousSurvivalLives = gameState.survivalSessionLives }
        }
        .onChange(of: gameState.lives) { newValue in
            if previousLives >= 0 {
                if newValue < previousLives { showLoseAnimation = true }
                else if newValue > previousLives { showGainAnimation = true }
            }
            previousLives = newValue
        }
        .onChange(of: gameState.timeChallengeSessionLives) { newValue in
            guard gameState.selectedPlayMode == .timeChallenge else { return }
            if previousTCSessionLives >= 0 {
                if newValue < previousTCSessionLives { showLoseAnimation = true }
                else if newValue > previousTCSessionLives { showGainAnimation = true }
            }
            previousTCSessionLives = newValue
        }
        .onChange(of: gameState.survivalSessionLives) { newValue in
            guard gameState.selectedPlayMode == .survival else { return }
            if previousSurvivalLives >= 0 {
                if newValue < previousSurvivalLives { showLoseAnimation = true }
                else if newValue > previousSurvivalLives { showGainAnimation = true }
            }
            previousSurvivalLives = newValue
        }
    }
}
}

private struct LiveBonusBannerView: View {
    let comboText: String?
    let bonusText: String?
    let isIPad: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            if let comboText {
                bonusChip(
                    icon: "flame.fill",
                    text: comboText,
                    colors: [Color.orange, Color.red]
                )
            }
            if let bonusText {
                bonusChip(
                    icon: "bolt.fill",
                    text: bonusText,
                    colors: [Color.purple, Color.blue]
                )
            }
        }
        .padding(.horizontal, isIPad ? 14 : 10)
        .padding(.vertical, isIPad ? 10 : 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
        )
        .scaleEffect(pulse ? 1.03 : 1.0)
        .onAppear { pulse = true }
        .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: pulse)
    }

    private func bonusChip(icon: String, text: String, colors: [Color]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 14 : 12, weight: .bold))
            Text(text)
                .font(.system(size: isIPad ? 15 : 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundColor(.white)
        .padding(.horizontal, isIPad ? 12 : 9)
        .padding(.vertical, isIPad ? 8 : 6)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 6, x: 0, y: 2)
    }
}

struct ExitButton: View {
    var action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(horizontalSizeClass == .regular ? .headline : .subheadline)
            Text(LocalizationManager.shared.localizedString("Exit"))
                    .font(horizontalSizeClass == .regular ? .headline : .subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.leading, horizontalSizeClass == .regular ? 8 : 6)
            .padding(.trailing, horizontalSizeClass == .regular ? 14 : 12)
            .padding(.vertical, horizontalSizeClass == .regular ? 8 : 6)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .clipShape(Capsule())
        .padding(.top, horizontalSizeClass == .regular ? 8 : 6)
    }
}

struct GameInfoPanel: View {
    @ObservedObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Слева: регион и сложность
            VStack(alignment: .leading, spacing: 4) {
                Text(gameState.selectedRegions.count == 1 ? gameState.selectedRegions.first?.displayName ?? "" : LocalizationManager.shared.localizedString("Multiple Regions"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(gameState.selectedDifficulty.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))

            Spacer(minLength: 8)

            // Центр: таймер и прогресс
            VStack(spacing: 6) {
                GameTimerView(gameState: gameState)
            GameProgressView(gameState: gameState)
            }

            Spacer(minLength: 8)

            // Справа: жизни и под ними прогресс по флагам
            VStack(alignment: .trailing, spacing: 6) {
                if gameState.selectedPlayMode == .timeChallenge {
                    LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.timeChallengeSessionLives, isPremium: gameState.isPremium)
                } else if gameState.selectedPlayMode == .survival {
                    LivesView(lives: $gameState.survivalSessionLives, isPremium: false)
                } else {
                    LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.lives, isPremium: gameState.isPremium)
                }
                Text("\(LocalizationManager.shared.localizedString("Flags")) \(gameState.currentQuestion + 1) / \(gameState.initialQuestionsCount)")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .frame(minWidth: 140, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
        }
        .padding(horizontalSizeClass == .regular ? 20 : 10)
        .modifier(GamePanelDynamicTypeCap())
    }
}

struct LivesView: View {
    @Binding var lives: Int
    var isPremium: Bool
    @Environment(\.sizeCategory) private var sizeCategory
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var userProfile: UserProfile
    /// Фиксированный размер иконки жизни: не масштабируется с Dynamic Type, чтобы шапка игры не ломалась.
    private let heartSide: CGFloat = 30
    private var heartAsset: String {
        localizationManager.lifeHeartAssetName(forCountryCode: userProfile.selectedCountryCode)
    }

    private var livesRow: some View {
        HStack(spacing: 4) {
            if isPremium {
                ZStack {
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: heartSide + 4, height: heartSide + 4)
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: 0.5)
                }
            } else if sizeCategory.isAccessibilityCategory {
                Image(heartAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: heartSide, height: heartSide)
                Text("\(lives)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                ForEach(0..<min(lives, 5), id: \.self) { _ in
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: heartSide, height: heartSide)
                }
                if lives > 5 {
                    Text("+\(lives - 5)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    var body: some View {
        livesRow
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))
    }
}

struct GameProgressView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 8 : 4) {
            if gameState.selectedPlayMode == .survival {
                Text(LocalizationManager.shared.localizedString("Survival depth header"))
                    .font(horizontalSizeClass == .regular ? .body : .caption)
                    .foregroundColor(.secondary)
                Text("\(gameState.currentQuestion + 1)")
                    .font(horizontalSizeClass == .regular ? .title : .headline)
                    .monospacedDigit()
                    .frame(minWidth: 36, alignment: .trailing)
                    .foregroundColor(.primary)
                Text(
                    String(
                        format: LocalizationManager.shared.localizedString("Survival stage fmt"),
                        GameState.survivalStage(forQuestionOneBased: gameState.currentQuestion + 1)
                    )
                )
                .font(horizontalSizeClass == .regular ? .caption : .caption2)
                .foregroundColor(.secondary)
            } else {
                Text(LocalizationManager.shared.localizedString("Flags"))
                    .font(horizontalSizeClass == .regular ? .body : .caption)
                    .foregroundColor(.secondary)
                
                Text("\(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
                    .font(horizontalSizeClass == .regular ? .title : .headline)
                    .monospacedDigit()
                    .frame(minWidth: horizontalSizeClass == .regular ? 88 : 76, alignment: .trailing)
                    .foregroundColor(.primary)
                
                ProgressView(
                    value: Double(gameState.currentQuestion + 1),
                    total: Double(max(1, gameState.questionsPerGame == Int.max ? gameState.initialQuestionsCount : gameState.questionsPerGame))
                )
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: horizontalSizeClass == .regular ? 200 : 100)
                .scaleEffect(horizontalSizeClass == .regular ? 1.5 : 1.0)
            }
        }
    }
}

struct GameScoreView: View {
    let score: Int
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 8 : 4) {
            Text(LocalizationManager.shared.localizedString("Score"))
                .font(horizontalSizeClass == .regular ? .body : .caption)
                .foregroundColor(.secondary)
            Text("\(score)")
                .font(horizontalSizeClass == .regular ? .title : .headline)
                .foregroundColor(.primary)
                .padding(horizontalSizeClass == .regular ? 16 : 8)
                .background(
                    RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 12 : 8)
                        .fill(Color.appBackgroundSecondary)
                )
        }
    }
}

struct GameView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            // iPad определяется по размеру экрана и size class
            #if os(iOS)
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad || 
                        (horizontalSizeClass == .regular && (verticalSizeClass == .regular || geometry.size.width > 768))
            #else
            let isIPad = horizontalSizeClass == .regular && (verticalSizeClass == .regular || geometry.size.width > 768)
            #endif
            
            if isIPad {
                // iPad макет (работает в любой ориентации)
                iPadGameLayout(gameState: gameState)
                    .environmentObject(gameState)
            } else {
                // iPhone макет
                phoneGameLayout(gameState: gameState)
            }
        }
        .onAppear {
            setTabBarHidden(true)
            // Не возобновлять таймер, пока показан попап «жизни закончились» — пауза до возврата юзера в игру.
            if !gameState.isPausedForOutOfLives {
                gameState.resumeTimer()
            }
        }
        .onDisappear {
            // Всегда только пауза при уходе с экрана (реклама, модалки). Остановка игры — только явно (Exit, Game Over).
            if gameState.isGameInProgress {
                gameState.pauseTimer()
            }
            setTabBarHidden(false)
        }
        .alert(LocalizationManager.shared.localizedString("duel.error.alert.title"), isPresented: Binding(
            get: { gameState.duelPrepareErrorMessage != nil },
            set: { if !$0 { gameState.duelPrepareErrorMessage = nil } }
        )) {
            Button(LocalizationManager.shared.localizedString("OK"), role: .cancel) {
                gameState.duelPrepareErrorMessage = nil
            }
        } message: {
            Text(gameState.duelPrepareErrorMessage ?? "")
        }
    }
}

// MARK: - TabBar visibility control (локально для GameView)
private func setTabBarHidden(_ hidden: Bool) {
    #if os(iOS)
    // Используем несколько попыток с разными задержками для надежности
    func attemptHide() {
        // Пробуем все доступные window scenes
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        
        for scene in scenes {
            for window in scene.windows {
                hideTabBarInWindow(window, hidden: hidden)
            }
        }
        
        // Также пробуем через key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            hideTabBarInWindow(keyWindow, hidden: hidden)
        }
    }
    
    // Немедленная попытка
    attemptHide()
    
    // Попытки с задержками
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        attemptHide()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        attemptHide()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        attemptHide()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        attemptHide()
    }
    #endif
}

#if os(iOS)
private func hideTabBarInWindow(_ window: UIWindow, hidden: Bool) {
    // Агрессивный поиск TabBar через все возможные пути
    var foundTabBars: [UITabBar] = []
    var foundTabBarControllers: [UITabBarController] = []
    
    // Функция поиска TabBarController
    func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        for child in viewController.children {
            if let tabBarController = findTabBarController(in: child) {
                return tabBarController
            }
        }
        
        if let presented = viewController.presentedViewController,
           let tabBarController = findTabBarController(in: presented) {
            return tabBarController
        }
        
        if let navController = viewController as? UINavigationController {
            for vc in navController.viewControllers {
                if let tabBarController = findTabBarController(in: vc) {
                    return tabBarController
                }
            }
        }
        
        // Проверяем UIHostingController для SwiftUI views
        if let hostingController = viewController as? UIHostingController<AnyView> {
            if let tabBarController = findTabBarController(in: hostingController.parent) {
                return tabBarController
            }
        }
        
        return nil
    }
    
    // Функция поиска TabBar в view hierarchy
    func findAllTabBars(in view: UIView?) {
        guard let view = view else { return }
        if let tabBar = view as? UITabBar {
            foundTabBars.append(tabBar)
        }
        for subview in view.subviews {
            findAllTabBars(in: subview)
        }
    }
    
    // Ищем через TabBarController - проверяем все возможные пути
    var rootVC = window.rootViewController
    while let vc = rootVC {
        if let tabBarController = findTabBarController(in: vc) {
            foundTabBarControllers.append(tabBarController)
        }
        rootVC = vc.presentedViewController ?? vc.parent
    }
    
    // Также проверяем rootViewController напрямую
    if let tabBarController = findTabBarController(in: window.rootViewController) {
        foundTabBarControllers.append(tabBarController)
    }
    
    // Ищем напрямую в view hierarchy
    findAllTabBars(in: window.rootViewController?.view)
    
    // Собираем все TabBar из найденных контроллеров
    for controller in foundTabBarControllers {
        foundTabBars.append(controller.tabBar)
    }
    
    // Удаляем дубликаты
    foundTabBars = Array(Set(foundTabBars))
    
    // Скрываем/показываем все найденные TabBar
    for tabBar in foundTabBars {
        if hidden {
            tabBar.isHidden = true
            tabBar.isUserInteractionEnabled = false
            tabBar.alpha = 0
            tabBar.transform = CGAffineTransform(translationX: 0, y: 200)
        } else {
            tabBar.isHidden = false
            tabBar.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                tabBar.alpha = 1
                tabBar.transform = .identity
            }
        }
    }
    
}
#endif

private struct iPadGameLayout: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @State private var showingExitAlert = false
    @State private var rewardedUnavailableAlert = false
    @State private var outOfLivesHeadlineIndex = 0
    @State private var outOfLivesOverlayID = UUID()
    @ObservedObject private var themeManager = AppThemeManager.shared
    @StateObject private var viewModel: GameViewModel
    
    init(gameState: GameState) {
        _viewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            GeometryReader { geometry in
                let wide = geometry.size.width >= 850 && geometry.size.width > geometry.size.height
                VStack(spacing: 0) {
                    QuizGameHeader(gameState: gameState, isShowingResult: viewModel.isShowingResult, isTablet: geometry.size.width >= 650) {
                        showingExitAlert = true
                    }
                    .frame(maxWidth: 1280)
                    .zIndex(1)
                    ScrollView {
                        tabletContent(size: geometry.size, sideBySide: wide)
                            .frame(maxWidth: 1200)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, geometry.size.width < 650 ? 20 : 36)
                            .padding(.top, wide ? 32 : 20)
                            .padding(.bottom, 32)
                    }
                    .accessibilityIdentifier(wide ? "quiz.tablet.landscape" : "quiz.tablet.portrait")
                }
                .frame(maxWidth: .infinity)
            }

            if viewModel.showingOutOfLives {
                OutOfLivesContinueOverlay(
                    headlineVariant: outOfLivesHeadlineIndex,
                    livesRewardAmount: RewardedAdService.livesRewardAmount,
                    rewardedAdEnabled: RewardedAdService.isRewardedAdEnabled,
                    onContinuePrimary: {
                        if RewardedAdService.isRewardedAdEnabled {
                            RewardedAdService.shared.showIfAvailable(from: nil, onReward: {
                                DispatchQueue.main.async {
                                    gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                                    if gameState.selectedPlayMode == .timeChallenge {
                                        gameState.timeChallengeSessionLives += RewardedAdService.livesRewardAmount
                                    }
                                    viewModel.showingOutOfLives = false
                                    gameState.resumeTimer()
                                    Task { await viewModel.goToNextQuestion() }
                                }
                            }, onUnavailable: {
                                DispatchQueue.main.async { rewardedUnavailableAlert = true }
                            })
                        } else {
                            OutOfLivesExitActions.leaveGameThenShowPremium(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                        }
                    },
                    onPlayAgain: {
                        viewModel.showingOutOfLives = false
                        gameState.isPausedForOutOfLives = false
                        viewModel.resetAnswerState()
                        Task { await gameState.restartGameInPlace() }
                    },
                    onExit: {
                        OutOfLivesExitActions.dismissOverlayAndLeaveGame(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                    },
                    onPremiumFooter: {
                        OutOfLivesExitActions.leaveGameThenShowPremium(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                    }
                )
                .id(outOfLivesOverlayID)
                .zIndex(500)
                .transition(.opacity)
            }
        }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                setupViewModel()
                // Скрываем TabBar при появлении игры - вызываем несколько раз для надежности
                setTabBarHidden(true)
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onChange(of: viewModel.currentFlag) { _ in
                // Дополнительно скрываем TabBar при изменении флага
                setTabBarHidden(true)
            }
            .onDisappear {
                viewModel.cancelPendingWork()
                // Показываем TabBar при выходе из игры
                setTabBarHidden(false)
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onChange(of: gameState.isCardInteractionEnabled) { enabled in
                if !enabled && !viewModel.isShowingResult {
                    viewModel.isShowingResult = true
                    viewModel.isShowingInfo = true
                }
            }
            .onChange(of: gameState.currentQuestion, perform: resetViewModelState)
            .onChange(of: gameState.isGameOver) { isOver in
                if isOver {
                    viewModel.showingGameOver = true
                }
            }
            // iPad: .sheet без detents даёт крошечный лист; как на iPhone — полный экран с прокруткой контента
            .fullScreenCover(isPresented: $viewModel.showingGameOver, content: gameOverSheet)
            .onChange(of: viewModel.showingOutOfLives) { isShowing in
                if isShowing {
                    gameState.isPausedForOutOfLives = true
                    gameState.pauseTimer()
                    outOfLivesHeadlineIndex = Int.random(in: 0..<7)
                    outOfLivesOverlayID = UUID()
                }
            }
            .onChange(of: gameState.requestOutOfLivesAlert) { if $0 { gameState.requestOutOfLivesAlert = false; viewModel.showingOutOfLives = true } }
            .alert(
                LocalizationManager.shared.localizedString("Exit Confirmation"),
                isPresented: $showingExitAlert,
                actions: exitAlertActions,
                message: exitAlertMessage
            )
            .alert(LocalizationManager.shared.localizedString("Ad unavailable"), isPresented: $rewardedUnavailableAlert) {
                Button(LocalizationManager.shared.localizedString("OK"), role: .cancel) { }
            } message: {
                Text(LocalizationManager.shared.localizedString("Ad unavailable. Try again later."))
            }
            .preferredColorScheme(themeManager.colorScheme)
    }
    
    @ViewBuilder
    private func tabletContent(size: CGSize, sideBySide: Bool) -> some View {
        if let country = viewModel.currentFlag {
            let usableWidth = min(1200, size.width - (size.width < 650 ? 40 : 72))
            if sideBySide {
                let panelWidth = (usableWidth - 40) / 2
                HStack(alignment: .center, spacing: 40) {
                    tabletQuestion(country: country, width: panelWidth, height: min(380, max(230, size.height * 0.44)))
                        .frame(width: panelWidth)
                    tabletAnswers(country: country, columns: viewModel.options.count > 6 && !dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .frame(width: panelWidth)
                }
            } else {
                VStack(spacing: 28) {
                    tabletQuestion(country: country, width: min(usableWidth, 620), height: min(360, max(190, size.height * 0.29)))
                    tabletAnswers(country: country, columns: usableWidth >= 600 && !dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .frame(maxWidth: 900)
                }
            }
        } else {
            LoadingView().padding(40)
        }
    }

    private func tabletQuestion(country: Country, width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 24) {
            Text(LocalizationManager.shared.localizedString("Quiz identify flag"))
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundColor(viewModel.isShowingResult ? .clear : .primary)
                .overlay {
                    if viewModel.isShowingResult {
                        Text(LocalizationManager.shared.localizedString(viewModel.selectedAnswer == nil ? "Time is up" : (viewModel.selectedAnswer == country ? "Correct" : "Wrong")))
                            .font(.title2.weight(.bold))
                    }
                }
                .frame(minHeight: 60)
                .accessibilityIdentifier("quiz.question")
            FlagCardView(
                country: country,
                isShowingInfo: $viewModel.isShowingInfo,
                flagScale: 1,
                flagRotation: viewModel.flagRotation,
                gameState: gameState,
                onNextQuestion: {},
                presentationSize: CGSize(width: width, height: height)
            )
            .id(country.id)
        }
        .frame(width: width)
    }

    private func tabletAnswers(country: Country, columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns), spacing: 16) {
            ForEach(viewModel.options, id: \.id) { option in
                AnswerButton(
                    country: option,
                    isSelected: viewModel.selectedAnswer == option,
                    isCorrect: viewModel.isShowingResult ? option == country : nil,
                    isIncorrect: viewModel.isShowingResult ? viewModel.selectedAnswer == option && option != country : nil,
                    tabletStyle: true,
                    action: { viewModel.selectAnswer(option) }
                )
            }
        }
        .disabled(viewModel.isShowingResult)
        .opacity(viewModel.optionsOpacity)
    }

    private func setupViewModel() {
        viewModel.gameState = gameState
    }
    
    private func resetViewModelState(_ newValue: Int) {
        withAnimation {
            viewModel.isShowingInfo = false
            viewModel.flagScale = 1.0
            viewModel.flagRotation = 0
            viewModel.optionsOpacity = 1.0
            viewModel.selectedAnswer = nil
            viewModel.isShowingResult = false
        }
    }
    
    private func gameOverSheet() -> some View {
        IPadSheetLikeFullScreenContainer {
            PostGameFlowContainer(
                score: gameState.score,
                totalQuestions: {
                    if gameState.selectedPlayMode == .timeChallenge {
                        return max(1, gameState.lastGameResults.count)
                    }
                    return max(1, gameState.initialQuestionsCount)
                }(),
                timeElapsed: gameState.elapsedTime,
                dailyQuests: QuestService.shared.dailyQuests,
                monthlyQuests: UserProfile.shared.monthlyQuests,
                friends: UserProfile.shared.friends,
                gameState: gameState,
                onFinish: {
                    viewModel.showingGameOver = false
                },
                onPlayAgain: {
                    viewModel.showingGameOver = false
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await gameState.restartGameInPlace()
                    }
                },
                onHome: {
                    gameState.isNavigatingToGame = false
                    dismiss()
                }
            )
        }
    }
    
    private func exitAlertActions() -> some View {
        Group {
            Button(LocalizationManager.shared.localizedString("Yes")) {
                Task {
                    gameState.stopTimer()
                    gameState.resetGameState()
                    gameState.isNavigatingToGame = false
                }
            }
            Button(LocalizationManager.shared.localizedString("No"), role: .cancel) { }
        }
    }
    
    private func exitAlertMessage() -> some View {
        Text(LocalizationManager.shared.localizedString("Are you sure you want to exit the game?"))
    }
}

// Wrapper больше не нужен: управление возвратом на главную происходит через кнопку "Home" внутри GameOverView

/// The same localized heart and life effects are used in every modern game layout.
private struct BrandedQuizLives: View {
    @ObservedObject var gameState: GameState
    @ObservedObject private var profile = UserProfile.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var isTablet = false
    @State private var previousLives: Int?
    @State private var losing = false
    @State private var gaining = false
    @State private var effectID = UUID()

    private var heartAsset: String { localization.lifeHeartAssetName(forCountryCode: profile.selectedCountryCode) }
    private var size: CGFloat { isTablet ? 68 : 48 }
    private var unlimited: Bool { gameState.isPremium && gameState.selectedPlayMode != .survival }
    private var lives: Int {
        switch gameState.selectedPlayMode {
        case .timeChallenge: return gameState.timeChallengeSessionLives
        case .survival: return gameState.survivalSessionLives
        default: return gameState.lives
        }
    }

    var body: some View {
        HStack(spacing: isTablet ? 10 : 6) {
            ZStack {
                Image(heartAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .opacity(losing || gaining ? 0 : 1)
                if losing {
                    HeartLoseAnimationView(heartAsset: heartAsset, size: size) { losing = false }
                        .id(effectID)
                }
                if gaining {
                    HeartGainAnimationView(heartAsset: heartAsset, size: size) { gaining = false }
                        .id(effectID)
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
            Group {
                if unlimited { Image(systemName: "infinity") }
                else { Text("\(lives)").monospacedDigit() }
            }
            .font(isTablet ? .title2.bold() : .headline)
            .foregroundStyle(.primary)
        }
        .padding(.leading, 6)
        .padding(.trailing, isTablet ? 18 : 12)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.045), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localization.localizedString("Lives"))
        .accessibilityValue(unlimited ? "∞" : "\(lives)")
        .accessibilityIdentifier("quiz.lives")
        .onAppear { previousLives = lives }
        .onChange(of: lives) { newValue in
            defer { previousLives = newValue }
            guard let oldValue = previousLives, oldValue != newValue, !unlimited, !reduceMotion else { return }
            effectID = UUID()
            losing = newValue < oldValue
            gaining = newValue > oldValue
        }
        .onChange(of: reduceMotion) { value in
            if value { losing = false; gaining = false }
        }
    }
}

/// Compact game chrome; the countdown is the only primary time indicator.
private struct QuizGameHeader: View {
    @ObservedObject var gameState: GameState
    let isShowingResult: Bool
    var isTablet = false
    let onExit: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 0.68, green: 0.64, blue: 1)
            : Color(red: 0.34, green: 0.30, blue: 0.78)
    }
    private var isTimeChallenge: Bool { gameState.selectedPlayMode == .timeChallenge }
    private var remaining: Double { isTimeChallenge ? gameState.timeChallengeRemainingTime : gameState.questionTimeLeft }
    private var region: String {
        gameState.selectedRegions.count == 1
            ? (gameState.selectedRegions.first?.displayName ?? "")
            : LocalizationManager.shared.localizedString("Multiple Regions")
    }
    private var progressText: String {
        if isTimeChallenge { return "\(gameState.score)" }
        if gameState.selectedPlayMode == .survival { return "\(gameState.currentQuestion + 1)" }
        return "\(min(gameState.currentQuestion + 1, gameState.initialQuestionsCount)) / \(gameState.initialQuestionsCount)"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onExit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizationManager.shared.localizedString("Exit"))
                .accessibilityIdentifier("quiz.exit")
                if isTablet {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(region).font(.title3.weight(.semibold))
                        Text(LocalizationManager.shared.localizedString(gameState.selectedDifficulty.rawValue.capitalized))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)
                }
                Spacer(minLength: 12)
                HStack(spacing: 7) {
                    Image(systemName: isTimeChallenge ? "checkmark.circle" : "flag")
                        .foregroundStyle(accent)
                    Text(progressText).monospacedDigit()
                }
                .font(isTablet ? .title2.weight(.semibold) : .subheadline.weight(.semibold))
                .accessibilityLabel(LocalizationManager.shared.localizedString(isTimeChallenge ? "Correct Answers" : "Flags") + ": " + progressText)
                Spacer(minLength: 0)
                if isTablet { timerLabel }
                BrandedQuizLives(gameState: gameState, isTablet: isTablet)
            }
            if !isTablet {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(region)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(LocalizationManager.shared.localizedString(gameState.selectedDifficulty.rawValue.capitalized))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    timerLabel
                }
            }
            if gameState.selectedPlayMode == .duel {
                Text(LocalizationManager.shared.localizedString("Opponent") + ": " + ((gameState.duelRoleIsChallenger ? gameState.duelOpponentName : gameState.duelChallengerName) ?? ""))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !isTimeChallenge {
                GeometryReader { geometry in
                    Capsule().fill(accent.opacity(0.10))
                        .overlay(alignment: .leading) {
                            Capsule().fill(remaining <= 5 && !isShowingResult ? Color.red : accent)
                                .frame(width: geometry.size.width * max(0, min(1, remaining / max(1, gameState.selectedDifficulty.timeLimit))))
                        }
                }
                .frame(height: 4)
                .opacity(isShowingResult ? 0 : 1)
                .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, isTablet ? 28 : 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background {
            LinearGradient(colors: [accent.opacity(0.07), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            if gameState.liveComboText != nil || gameState.liveBonusText != nil {
                LiveBonusBannerView(comboText: gameState.liveComboText, bonusText: gameState.liveBonusText, isIPad: isTablet)
                    .allowsHitTesting(false)
                    .offset(y: 8)
            }
        }
    }
    private var timerLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: "timer")
            Text(gameState.formattedTime(max(0, remaining), includeFraction: false))
                .monospacedDigit()
        }
        .font(.headline)
        .foregroundStyle(remaining <= 5 && !isShowingResult ? Color.red : accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(accent.opacity(0.08), in: Capsule())
        .opacity(isShowingResult && !isTimeChallenge ? 0 : 1)
        .accessibilityLabel(LocalizationManager.shared.localizedString(isTimeChallenge ? "Time Challenge" : "Time Per Question"))
        .accessibilityValue(gameState.formattedTime(max(0, remaining), includeFraction: false))
        .accessibilityHidden(isShowingResult && !isTimeChallenge)
    }

}

private struct phoneGameLayout: View {
    @StateObject private var viewModel: GameViewModel
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var themeManager = AppThemeManager.shared
    
    @State private var showingExitAlert = false
    @State private var isFirstAppear = true
    @State private var safeTopInset: CGFloat = 0
    @State private var rewardedUnavailableAlert = false
    @State private var outOfLivesHeadlineIndex = 0
    @State private var outOfLivesOverlayID = UUID()
    
    init(gameState: GameState) {
        self.gameState = gameState
        _viewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    private var screenHeight: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #else
        return 800 // Fallback для macOS
        #endif
    }
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }

    private var isCompactPhone: Bool {
        !isIPad && screenHeight <= 880
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Базовый фон под всем контентом
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            // Градиентный фон шапки под статус-баром
            gameHeaderBackground

            // На телефоне только вертикальный макет (горизонтальная ориентация отключена в AppDelegate)
            portraitLayout

            if viewModel.showingOutOfLives {
                OutOfLivesContinueOverlay(
                    headlineVariant: outOfLivesHeadlineIndex,
                    livesRewardAmount: RewardedAdService.livesRewardAmount,
                    rewardedAdEnabled: RewardedAdService.isRewardedAdEnabled,
                    onContinuePrimary: {
                        if RewardedAdService.isRewardedAdEnabled {
                            RewardedAdService.shared.showIfAvailable(from: nil, onReward: {
                                DispatchQueue.main.async {
                                    gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                                    if gameState.selectedPlayMode == .timeChallenge {
                                        gameState.timeChallengeSessionLives += RewardedAdService.livesRewardAmount
                                    }
                                    viewModel.showingOutOfLives = false
                                    gameState.resumeTimer()
                                    Task { await viewModel.goToNextQuestion() }
                                }
                            }, onUnavailable: {
                                DispatchQueue.main.async { rewardedUnavailableAlert = true }
                            })
                        } else {
                            OutOfLivesExitActions.leaveGameThenShowPremium(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                        }
                    },
                    onPlayAgain: {
                        viewModel.showingOutOfLives = false
                        gameState.isPausedForOutOfLives = false
                        viewModel.resetAnswerState()
                        Task { await gameState.restartGameInPlace() }
                    },
                    onExit: {
                        OutOfLivesExitActions.dismissOverlayAndLeaveGame(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                    },
                    onPremiumFooter: {
                        OutOfLivesExitActions.leaveGameThenShowPremium(viewModel: viewModel, gameState: gameState, dismiss: dismiss)
                    }
                )
                .id(outOfLivesOverlayID)
                .zIndex(500)
                .transition(.opacity)
            }
        }
            // Считываем safe area inset сверху
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: GameSafeTopInsetKey.self, value: geo.safeAreaInsets.top)
                }
            )
            .onPreferenceChange(GameSafeTopInsetKey.self) { value in
                safeTopInset = value
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                // Скрываем TabBar при появлении игры
                setTabBarHidden(true)
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onDisappear {
                viewModel.cancelPendingWork()
                // Показываем TabBar при выходе из игры
                setTabBarHidden(false)
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onDisappear {
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.showingGameOver) {
            IPadSheetLikeFullScreenContainer {
                PostGameFlowContainer(
                    score: gameState.score,
                    totalQuestions: {
                        if gameState.selectedPlayMode == .timeChallenge {
                            return max(1, gameState.lastGameResults.count)
                        }
                        return max(1, gameState.initialQuestionsCount)
                    }(),
                    timeElapsed: gameState.elapsedTime,
                    dailyQuests: QuestService.shared.dailyQuests,
                    monthlyQuests: UserProfile.shared.monthlyQuests,
                    friends: UserProfile.shared.friends,
                    gameState: gameState,
                    onFinish: {
                        gameState.pendingDuelResult = nil
                        viewModel.showingGameOver = false
                    },
                    onPlayAgain: {
                        gameState.pendingDuelResult = nil
                        viewModel.showingGameOver = false
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            await gameState.restartGameInPlace()
                        }
                    },
                    onHome: {
                        gameState.pendingDuelResult = nil
                        gameState.isNavigatingToGame = false
                        dismiss()
                    }
                )
            }
        }
        #else
        .sheet(isPresented: $viewModel.showingGameOver) {
            PostGameFlowContainer(
                score: gameState.score,
                totalQuestions: {
                if gameState.selectedPlayMode == .timeChallenge {
                    return max(1, gameState.lastGameResults.count)
                }
                return max(1, gameState.initialQuestionsCount)
            }(),
                timeElapsed: gameState.elapsedTime,
                dailyQuests: QuestService.shared.dailyQuests,
                monthlyQuests: UserProfile.shared.monthlyQuests,
                friends: UserProfile.shared.friends,
                gameState: gameState,
                onFinish: {
                    gameState.pendingDuelResult = nil
                    viewModel.showingGameOver = false
                },
                onPlayAgain: {
                    gameState.pendingDuelResult = nil
                    viewModel.showingGameOver = false
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await gameState.restartGameInPlace()
                    }
                },
                onHome: {
                    gameState.pendingDuelResult = nil
                    gameState.isNavigatingToGame = false
                    dismiss()
                }
            )
        }
        #endif
        .onChange(of: viewModel.showingOutOfLives) { isShowing in
            if isShowing {
                gameState.isPausedForOutOfLives = true
                gameState.pauseTimer()
                outOfLivesHeadlineIndex = Int.random(in: 0..<7)
                outOfLivesOverlayID = UUID()
            }
        }
        .onChange(of: gameState.isGameOver) { isOver in
            if isOver {
                viewModel.showingGameOver = true
            }
        }
        .onChange(of: gameState.requestOutOfLivesAlert) { if $0 { gameState.requestOutOfLivesAlert = false; viewModel.showingOutOfLives = true } }
        .alert(LocalizationManager.shared.localizedString("Exit Confirmation"), isPresented: $showingExitAlert) {
            Button(LocalizationManager.shared.localizedString("Yes")) {
                Task {
                    gameState.stopTimer()
                    gameState.resetGameState()
                    gameState.isNavigatingToGame = false
                    dismiss()
                }
            }
            Button(LocalizationManager.shared.localizedString("No"), role: .cancel) { }
        } message: {
            Text(LocalizationManager.shared.localizedString("Are you sure you want to exit the game?"))
        }
        .alert(LocalizationManager.shared.localizedString("Ad unavailable"), isPresented: $rewardedUnavailableAlert) {
            Button(LocalizationManager.shared.localizedString("OK"), role: .cancel) { }
        } message: {
            Text(LocalizationManager.shared.localizedString("Ad unavailable. Try again later."))
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        #endif
        .onChange(of: gameState.isCardInteractionEnabled) { enabled in
            if !enabled && !viewModel.isShowingResult {
                viewModel.isShowingResult = true
                viewModel.isShowingInfo = true
            }
        }
        .onChange(of: gameState.currentQuestion) { _ in
            withAnimation {
                viewModel.isShowingInfo = false
                viewModel.flagScale = 1.0
                viewModel.flagRotation = 0
                viewModel.optionsOpacity = 1.0
                viewModel.selectedAnswer = nil
                viewModel.isShowingResult = false
            }
        }

        .onChange(of: gameState.mistakeCountries) { newValue in
            print("\n=== Mistakes Updated ===")
            print("Current mistakes count: \(newValue.count)")
            print("Mistakes: \(newValue.map { $0.name.common }.joined(separator: ", "))")
            print("=====================\n")
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    // MARK: - Helper Functions
    
    // MARK: - Game Header Components (общий компонент GameHeaderSectionView)
    
    @ViewBuilder
    private var gameHeaderSection: some View {
        if gameState.selectedPlayMode == .duel {
            GameHeaderSectionView(gameState: gameState, safeTopInset: safeTopInset, onExitTap: { showingExitAlert = true })
        } else {
            QuizGameHeader(gameState: gameState, isShowingResult: viewModel.isShowingResult) {
                showingExitAlert = true
            }
        }
    }

    private var gameHeaderBackground: some View { Color.clear }

    private var portraitLayout: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                gameHeaderSection
                    .zIndex(1)
                ScrollView {
                    if let currentFlag = viewModel.currentFlag {
                        GameContentView(
                            viewModel: viewModel,
                            currentFlag: currentFlag,
                            gameState: gameState,
                            phoneFlagSize: CGSize(
                                width: max(160, min(geometry.size.width - 72, 360)),
                                height: max(140, min(190, geometry.size.height * 0.22))
                            )
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    } else {
                        LoadingView()
                    }
                }
                .accessibilityIdentifier("quiz.content")
            }
        }
    }

    // MARK: - Landscape Layout
    private var landscapeLayout: some View {
        VStack(spacing: 0) {
            // Полноценная шапка для горизонтальной ориентации
            gameHeaderSection
                .padding(.top, safeTopInset)
            
            // Основной контент в горизонтальном макете
            if let currentFlag = viewModel.currentFlag {
                HStack(spacing: 20) {
                    // Левая часть: флаг с прогрессом
                    VStack(spacing: 16) {
                        // Прогресс бар
                        ProgressBarView(
                            current: gameState.currentQuestion + 1,
                            total: gameState.initialQuestionsCount,
                            progress: Double(gameState.currentQuestion + 1) / Double(gameState.initialQuestionsCount)
                        )
                        
                        // Флаг
                        FlagImageView(
                            countryCode: currentFlag.countryCode,
                            flagEmoji: currentFlag.flagEmoji
                        )
                        .frame(
                            width: min(200, screenHeight * 0.4), 
                            height: min(133, screenHeight * 0.27)
                        )
                        .scaleEffect(viewModel.flagScale)
                        .rotationEffect(.degrees(viewModel.flagRotation))
                        .id(currentFlag.id)
                        .transition(.opacity)
                        
                        if viewModel.isShowingInfo {
                            Text(currentFlag.name.common)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Правая часть: варианты ответов
                    VStack(spacing: 10) {
                        ForEach(viewModel.options, id: \.id) { option in
                            Button(action: {
                                viewModel.selectAnswer(option)
                            }) {
                                Text(option.name.common)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(buttonBackgroundColor(for: option))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(buttonBorderColor(for: option), lineWidth: 2)
                                            )
                                    )
                            }
                            .disabled(viewModel.isShowingResult)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(viewModel.optionsOpacity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            } else {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .background(
            backgroundColor
                .ignoresSafeArea(.container, edges: .bottom)
        )
    }
    
    // MARK: - Compact Header for Landscape
    private var compactGameHeaderSection: some View {
        HStack {
            // Exit кнопка
            Button(LocalizationManager.shared.localizedString("Exit")) {
                showingExitAlert = true
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, isIPad ? 40 : 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .cornerRadius(20)
            
            Spacer()
            
            // Информация о игре (компактно)
            HStack(spacing: 20) {
                // Прогресс
                HStack(spacing: 4) {
                    Text("\(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
                        .font(.system(size: 14, weight: .medium))
                        .monospacedDigit()
                        .frame(minWidth: 56, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
                
                // Счет
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                    Text("\(gameState.score)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // Время
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                        .frame(width: 14, alignment: .center)
                    Text(gameState.formattedTime())
                        .font(.system(size: 14, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .frame(minWidth: 52, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.appBackgroundSecondary)
    }
    
    // MARK: - Button Styling Helpers
    private func buttonBackgroundColor(for option: Country) -> Color {
        if let selectedAnswer = viewModel.selectedAnswer {
            if option == selectedAnswer {
                return option == viewModel.currentFlag ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
            } else if option == viewModel.currentFlag && viewModel.isShowingInfo {
                return Color.green.opacity(0.2)
            }
        }
        return Color.appBackgroundSecondary
    }
    
    private func buttonBorderColor(for option: Country) -> Color {
        if let selectedAnswer = viewModel.selectedAnswer {
            if option == selectedAnswer {
                return option == viewModel.currentFlag ? Color.green : Color.red
            } else if option == viewModel.currentFlag && viewModel.isShowingInfo {
                return Color.green
            }
        }
        return Color.clear
    }
}

struct GameContentView: View {
    @ObservedObject var viewModel: GameViewModel
    let currentFlag: Country
    let gameState: GameState
    var phoneFlagSize: CGSize? = nil
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    private var isCompactPhone: Bool {
        #if os(iOS)
        return !isIPad && UIScreen.main.bounds.height <= 880
        #else
        return false
        #endif
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if phoneFlagSize != nil {
                Text(LocalizationManager.shared.localizedString(
                    viewModel.isShowingResult
                        ? (viewModel.selectedAnswer == nil ? "Time is up" : (viewModel.selectedAnswer == currentFlag ? "Correct" : "Wrong"))
                        : "Quiz identify flag"
                ))
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .accessibilityIdentifier("quiz.question")
            }
            FlagCardView(
                country: currentFlag,
                isShowingInfo: $viewModel.isShowingInfo,
                flagScale: phoneFlagSize != nil ? 1 : viewModel.flagScale,
                flagRotation: viewModel.flagRotation,
                gameState: gameState,
                onNextQuestion: {
                    // Переходы теперь управляются автоматически
                    // Убираем ручной переход по клику
                },
                presentationSize: phoneFlagSize
            )
            .id(currentFlag.id)
            .transition(.opacity)
            .padding(.horizontal, isIPad ? 40 : 16)
            .padding(.vertical, phoneFlagSize != nil ? 0 : (isCompactPhone ? 4 : 8))
            
            AnswerOptionsView(
                viewModel: viewModel,
                currentFlag: currentFlag
            )
        }
    }
}

struct AnswerOptionsView: View {
    @ObservedObject var viewModel: GameViewModel
    let currentFlag: Country
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    private var isCompactPhone: Bool {
        #if os(iOS)
        return !isIPad && UIScreen.main.bounds.height <= 860
        #else
        return false
        #endif
    }
    private var useSmallButtons: Bool {
        #if os(iOS)
        return !isIPad && UIScreen.main.bounds.height <= 820
        #else
        return false
        #endif
    }
    
    var body: some View {
        VStack(spacing: isCompactPhone ? 10 : 12) {
            ForEach(viewModel.options, id: \.id) { country in
                AnswerButton(
                    country: country,
                    isSelected: viewModel.selectedAnswer == country,
                    isCorrect: viewModel.isShowingResult ? (country == currentFlag) : nil,
                    isIncorrect: viewModel.isShowingResult ? viewModel.selectedAnswer == country && country != currentFlag : nil,
                    compact: false,
                    action: {
                        withAnimation {
                            viewModel.selectAnswer(country)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, isIPad ? 40 : 16)
        .padding(.vertical, isCompactPhone ? 6 : 8)
        .disabled(viewModel.isShowingResult)
        .opacity(viewModel.optionsOpacity)
    }
}

struct LoadingView: View {
    var body: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
    }
}

// Добавляю компонент для отображения таймера вопроса
struct QuestionTimerView: View {
    @ObservedObject var gameState: GameState
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    
    var body: some View {
        if gameState.selectedPlayMode == .timeChallenge && gameState.isQuestionTimerActive {
            VStack(spacing: isIPad ? 12 : 10) {
                HStack(spacing: isIPad ? 10 : 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: isIPad ? 44 : 40))
                    
                    Text(String(format: "%.1f", gameState.questionTimeLeft))
                        .font(.system(size: isIPad ? 40 : 36, weight: .bold, design: .monospaced))
                        .foregroundColor(gameState.questionTimeLeft < 5 ? .red : .primary)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    
                    Text("sec")
                        .font(.system(size: isIPad ? 28 : 28))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: gameState.questionTimeProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: gameState.questionTimeLeft < 5 ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(height: isIPad ? 8 : 6)
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.vertical, isIPad ? 12 : 10)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// Добавляю компонент для отображения режима выживания
struct SurvivalModeView: View {
    @ObservedObject var gameState: GameState
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    
    var body: some View {
        if gameState.selectedPlayMode == .survival {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                
                Text(LocalizationManager.shared.localizedString("Survival Mode"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(LocalizationManager.shared.localizedString("One mistake = Game Over"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    @Published var selectedAnswer: Country?
    @Published var isShowingResult = false
    @Published var isShowingInfo = false
    @Published var showingGameOver = false
    @Published var showingOutOfLives = false
    @Published var flagScale = 1.0
    @Published var flagRotation = 0.0
    @Published var optionsOpacity = 1.0
    
    private var nextQuestionTask: Task<Void, Never>?
    private var liveEffectsHideTask: Task<Void, Never>?
    private var correctlyAnsweredMistakes: Set<String> = []
    
    var currentFlag: Country? { gameState.currentFlag }
    var options: [Country] { gameState.options }
    
    init(gameState: GameState) {
        self.gameState = gameState
        // Очищаем список правильных ответов при создании новой игры
        correctlyAnsweredMistakes.removeAll()
    }
    
    private func addMistake(_ country: Country) {
        gameState.addMistake(country)
    }
    
    private func removeMistake(_ country: Country) {
        if let index = gameState.mistakeCountries.firstIndex(where: { $0.id == country.id }) {
            gameState.mistakeCountries.remove(at: index)
            gameState.saveMistakes()
        }
    }
    
    func selectAnswer(_ country: Country) {
        guard !isShowingResult else { return }
        guard let currentFlag = currentFlag else { return }
        let isTimeChallenge = gameState.selectedPlayMode == .timeChallenge
        let isSurvival = gameState.selectedPlayMode == .survival

        // Сохраняем время до остановки таймера — для Speed bonus (stopQuestionTimer обнуляет questionTimeLeft)
        let timeLeftWhenAnswered = gameState.questionTimeLeft
        // Таймер вопроса только для текущего задания — сразу останавливаем и отменяем отложенный переход
        gameState.stopQuestionTimer()
        gameState.cancelQuestionTransition()

        // Легкая вибрация при клике на ответ
        #if os(iOS)
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()
        #endif

        // Отменяем предыдущую задачу перехода к следующему вопросу
        nextQuestionTask?.cancel()

        selectedAnswer = country
        isShowingResult = true
        
        let isCorrect = country.id == currentFlag.id
        gameState.recordCountryAnswerProgress(countryCode3: currentFlag.id, isCorrect: isCorrect)

        var xpAwardedThisQuestion: Int?
        var timeAdjustmentSeconds: Int?
        var tcCorrectTimeHint: String?
        /// Неверный ответ в TC уже записан до штрафа по времени — не дублировать в общем вызове recordQuestionResult.
        var skipDefaultRecordForTimeChallengeWrong = false
        var skipDefaultRecordForSurvivalWrong = false

        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")

        if isCorrect {
            print("✅ CORRECT ANSWER!")
            if isTimeChallenge {
                gameState.score += 1
                xpAwardedThisQuestion = 10
            } else {
                gameState.score += 1
            }
            gameState.comboStreak += 1
            if isTimeChallenge {
                gameState.timeChallengeBestCombo = max(gameState.timeChallengeBestCombo, gameState.comboStreak)
            }
            if isSurvival {
                gameState.survivalSessionBestCombo = max(gameState.survivalSessionBestCombo, gameState.comboStreak)
                let streak = gameState.comboStreak
                if streak > 0 && streak % 10 == 0 {
                    gameState.survivalSessionLives += 1
                    showLiveBonus(text: LocalizationManager.shared.localizedString("Survival bonus life streak"))
                }
            }
            if isTimeChallenge {
                let streak = gameState.comboStreak
                if streak > 0 && streak % 5 == 0 {
                    let addSec = gameState.selectedDifficulty.timeChallengeCombo5BonusSeconds
                    timeAdjustmentSeconds = addSec
                    tcCorrectTimeHint = "+\(addSec)s"
                    gameState.applyTimeChallengeBonus(seconds: addSec)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        gameState.clearTimeChallengeDelta()
                    }
                }
            }
            if gameState.comboStreak >= 3 {
                showLiveCombo(streak: gameState.comboStreak)
            }

            // Бонус за серию правильных ответов: +10 XP каждые 3/5/10
            var bonusMessage: String?
            if [3, 5, 10].contains(gameState.comboStreak) {
                gameState.bonusXP += 10
                if isTimeChallenge {
                    xpAwardedThisQuestion = (xpAwardedThisQuestion ?? 0) + 10
                }
                bonusMessage = String(format: LocalizationManager.shared.localizedString("Combo x%d +10 XP"), gameState.comboStreak)
            }

            // Бонус за скорость: ответил за 3 секунды — +10 XP (проверяем сохранённое время до stopQuestionTimer)
            let timeLimit = gameState.selectedDifficulty.timeLimit
            let answeredWithin3Sec = timeLeftWhenAnswered >= max(0, timeLimit - 3)
            let speedMessage = LocalizationManager.shared.localizedString("Speed bonus +10 XP")
            if answeredWithin3Sec {
                gameState.bonusXP += 10
                if isTimeChallenge {
                    xpAwardedThisQuestion = (xpAwardedThisQuestion ?? 0) + 10
                }
                bonusMessage = bonusMessage.map { "\($0) • \(speedMessage)" } ?? speedMessage
            }
            if isTimeChallenge, let hint = tcCorrectTimeHint {
                if let text = bonusMessage {
                    showLiveBonus(text: "\(hint) • \(text)")
                } else {
                    showLiveBonus(text: hint)
                }
            } else if let text = bonusMessage {
                showLiveBonus(text: text)
            }

            if isSurvival, [10, 25, 50, 100].contains(gameState.score) {
                gameState.bonusXP += 30
                UserProfile.shared.addFBucks(1)
                let msg = String(
                    format: LocalizationManager.shared.localizedString("Survival milestone banner fmt"),
                    gameState.score
                )
                gameState.survivalToastMessage = msg
                showLiveBonus(text: msg)
            }

            // Положительная вибрация при правильном ответе
            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            }
            #endif

            if gameState.selectedRegions.contains(.myMistakes) {
                print("Adding to correctly answered list: \(currentFlag.name.common) (ID: \(currentFlag.id))")
                if gameState.mistakeCountries.contains(where: { $0.id == currentFlag.id }) {
                    correctlyAnsweredMistakes.insert(currentFlag.id)
                    print("🎉 Great job! This flag was in your mistakes list")
                }
            }
        } else {
            print("❌ WRONG ANSWER!")
            gameState.comboStreak = 0
            gameState.liveComboText = nil

            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
            #endif

            if !gameState.selectedRegions.contains(.myMistakes) {
                addMistake(currentFlag)
            }
            if isTimeChallenge {
                let subSec = gameState.selectedDifficulty.timeChallengeWrongTimerSeconds
                timeAdjustmentSeconds = -subSec
                if !gameState.isPremium {
                    gameState.timeChallengeSessionLives = max(0, gameState.timeChallengeSessionLives - 1)
                    print("Time Challenge session lives: \(gameState.timeChallengeSessionLives)")
                }
                // Сначала журнал ответа, потом штраф (иначе finishGameSync не увидит этот вопрос).
                gameState.recordQuestionResult(
                    correctCountry: currentFlag,
                    selectedCountry: country,
                    questionIndex: gameState.currentQuestion,
                    isCorrect: isCorrect,
                    sessionPointsDelta: nil,
                    xpAwardedThisQuestion: nil,
                    timeAdjustmentSeconds: timeAdjustmentSeconds
                )
                skipDefaultRecordForTimeChallengeWrong = true
                gameState.applyTimeChallengePenalty(seconds: subSec)
                showLiveBonus(text: "-\(subSec)s")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    gameState.clearTimeChallengeDelta()
                }
                if !gameState.isPremium && gameState.timeChallengeSessionLives <= 0 && !gameState.isGameOver {
                    print("\n=== Out Of TC Session Lives (time still left) ===\n")
                    gameState.isPausedForOutOfLives = true
                    gameState.pauseTimer()
                    showingOutOfLives = true
                    return
                }
                if gameState.isGameOver {
                    // Время вышло (часто вместе с последней жизнью) — без рекламы/Premium, сразу итог.
                    showingOutOfLives = false
                    gameState.isPausedForOutOfLives = false
                    return
                }
            } else if isSurvival {
                gameState.survivalSessionLives = max(0, gameState.survivalSessionLives - 1)
                gameState.recordQuestionResult(
                    correctCountry: currentFlag,
                    selectedCountry: country,
                    questionIndex: gameState.currentQuestion,
                    isCorrect: isCorrect,
                    sessionPointsDelta: nil,
                    xpAwardedThisQuestion: nil,
                    timeAdjustmentSeconds: nil
                )
                skipDefaultRecordForSurvivalWrong = true
                if gameState.survivalSessionLives <= 0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isShowingInfo = true
                        self.flagScale = 0.8
                        self.flagRotation = 180
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        if !Task.isCancelled {
                            gameState.stopTimer()
                            gameState.finishGame()
                        }
                    }
                    return
                }
            } else {
                gameState.consumeLifeOnWrongAnswer()
                print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
                if !gameState.isPremium && gameState.lives <= 0 {
                    print("\n=== Out Of Lives ===\nLives depleted. Pausing game (timer can resume after ad).\n=====================\n")
                    gameState.pauseTimer()
                    showingOutOfLives = true
                    gameState.recordQuestionResult(
                        correctCountry: currentFlag,
                        selectedCountry: country,
                        questionIndex: gameState.currentQuestion,
                        isCorrect: isCorrect,
                        sessionPointsDelta: nil,
                        xpAwardedThisQuestion: nil,
                        timeAdjustmentSeconds: nil
                    )
                    return
                }
            }
        }

        if !skipDefaultRecordForTimeChallengeWrong && !skipDefaultRecordForSurvivalWrong {
            gameState.recordQuestionResult(
                correctCountry: currentFlag,
                selectedCountry: country,
                questionIndex: gameState.currentQuestion,
                isCorrect: isCorrect,
                sessionPointsDelta: nil,
                xpAwardedThisQuestion: isTimeChallenge ? xpAwardedThisQuestion : nil,
                timeAdjustmentSeconds: isTimeChallenge ? timeAdjustmentSeconds : nil
            )
        }

        if isCorrect {
            print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
        }

        print("\nGame Statistics:")
        print("Current score: \(gameState.score)")
        print("Question: \(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
        print("=====================\n")
        
        // В Time Challenge — быстрый переход без разворота карточки.
        if !isTimeChallenge {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isShowingInfo = true
                self.flagScale = 0.8
                self.flagRotation = 180
            }
        }

        let transitionNs: UInt64 = {
            if isTimeChallenge { return 350_000_000 }
            if isSurvival, !isCorrect { return 1_200_000_000 }
            return 3_000_000_000
        }()
        nextQuestionTask = Task {
            try? await Task.sleep(nanoseconds: transitionNs)
            if !Task.isCancelled {
                await goToNextQuestion()
            }
        }
    }

    private func showLiveBonus(text: String) {
        gameState.liveBonusText = text
        scheduleLiveEffectsHide()
    }

    private func showLiveCombo(streak: Int) {
        gameState.liveComboText = String(format: LocalizationManager.shared.localizedString("Combo x%d"), streak)
        scheduleLiveEffectsHide()
    }

    private func scheduleLiveEffectsHide() {
        liveEffectsHideTask?.cancel()
        liveEffectsHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            if !Task.isCancelled {
                gameState.liveComboText = nil
                gameState.liveBonusText = nil
            }
        }
    }
    
    /// Сброс состояния ответа/UI перед рестартом («Играть снова» после окончания жизней). Исключает отображение «уже выбран правильный ответ» на новом вопросе.
    func resetAnswerState() {
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
        showingOutOfLives = false
        selectedAnswer = nil
        isShowingResult = false
        isShowingInfo = false
        flagScale = 1.0
        flagRotation = 0
        optionsOpacity = 1.0
    }

    func goToNextQuestion() async {
        nextQuestionTask?.cancel()
        nextQuestionTask = nil

        // Time Challenge без лимита по числу вопросов; Survival и Классика — как в Классике (конец пула региона).
        let hitQuestionCap = gameState.selectedPlayMode != .timeChallenge
            && gameState.currentQuestion + 1 >= gameState.initialQuestionsCount
        if hitQuestionCap {
            // Обновляем список ошибок для режима Mistakes
            if gameState.selectedRegions.contains(.myMistakes) {
                updateMistakesAfterGame()
            }
            
            gameState.stopTimer()
            gameState.finishGame()
            showingGameOver = true
            return
        }
        
        // Переходим к следующему вопросу
        // prepareNextQuestion() сам увеличивает currentQuestion
        gameState.prepareNextQuestion()
        
        // Сбрасываем UI состояние для следующего вопроса
        withAnimation {
            flagScale = 1.0
            flagRotation = 0
            isShowingInfo = false
            optionsOpacity = 1.0
            selectedAnswer = nil
            isShowingResult = false
        }
    }

    func cancelPendingWork() {
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
        liveEffectsHideTask?.cancel()
        liveEffectsHideTask = nil
    }
    
    private func updateMistakesAfterGame() {
        print("\n=== Updating Mistakes List After Game ===")
        print("Correctly answered mistakes: \(correctlyAnsweredMistakes.count)")
        
        let correctlyAnsweredNames = gameState.mistakeCountries
            .filter { correctlyAnsweredMistakes.contains($0.id) }
            .map { $0.name.common }
        print("Correctly answered flags: \(correctlyAnsweredNames.joined(separator: ", "))")
        
        // Создаем новый список ошибок, исключая правильно отвеченные
        let updatedMistakes = gameState.mistakeCountries.filter { country in
            let shouldKeep = !correctlyAnsweredMistakes.contains(country.id)
            if !shouldKeep {
                print("Removing from mistakes: \(country.name.common) (ID: \(country.id))")
            }
            return shouldKeep
        }
        
        // Обновляем список ошибок
        gameState.mistakeCountries = updatedMistakes
        // Если «Мои ошибки» опустели — переключаем регион на «Все регионы», чтобы не остаться без выбора
        if updatedMistakes.isEmpty && gameState.selectedRegions.contains(.myMistakes) {
            gameState.selectedRegions = [.all]
        }
        // Сохраняем обновленный список ошибок
        gameState.saveMistakes()
        
        print("Remaining mistakes: \(gameState.mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
        print("=====================\n")
    }
}

// PreferenceKey для передачи safe area inset сверху для игры
private struct GameSafeTopInsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct GameContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
