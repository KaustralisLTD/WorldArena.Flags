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
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(horizontalSizeClass == .regular ? .title2 : .title3)
                    .foregroundColor(.blue)
                Text(gameState.formattedTime())
                    .font(horizontalSizeClass == .regular ? .title : .title2)
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(2)
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
            HStack(spacing: 10) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(horizontalSizeClass == .regular ? .title3 : .headline)
                    .foregroundColor(.orange)
                Text(String(format: "%.1f s", gameState.questionTimeLeft))
                    .font(horizontalSizeClass == .regular ? .title2 : .headline)
                    .monospacedDigit()
                    .foregroundColor(gameState.questionTimeLeft < 5 ? .red : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(2)
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
                        .font(.subheadline).foregroundColor(.secondary)
                    Text(gameState.selectedDifficulty.displayName)
                        .font(.headline)
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
                LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.lives, isPremium: gameState.isPremium)
                GameProgressView(gameState: gameState)
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 20 : 12)
        .padding(.top, horizontalSizeClass == .regular ? 8 : 6)
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

// Общая шапка игры (телефон + iPad): подписи к таймерам, анимации, минуты/секунды без дробной части
private struct GameHeaderSectionView: View {
    @ObservedObject var gameState: GameState
    var safeTopInset: CGFloat
    var onExitTap: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var previousLives: Int = -1
    @State private var showLoseAnimation = false
    @State private var showGainAnimation = false
    @State private var livesCountPop = false

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
        if let name = gameState.duelOpponentName, !name.isEmpty { return name }
        if let name = gameState.duelChallengerName, !name.isEmpty { return name }
        return LocalizationManager.shared.localizedString("Opponent")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: isIPad ? 16 : 12) {
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
                .padding(.leading, isIPad ? 24 : 20)
                Spacer()
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
                Spacer()
                HStack(spacing: isIPad ? 20 : 16) {
                    VStack(spacing: isIPad ? 6 : 4) {
                        Text(LocalizationManager.shared.localizedString("Total Game Time"))
                            .font(.system(size: fontSize(9, iPad: 13), weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: fontSize(13, iPad: 18)))
                                .foregroundColor(.white.opacity(0.95))
                                .scaleEffect(gameState.elapsedTime.truncatingRemainder(dividingBy: 2) < 1 ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameState.elapsedTime)
                            Text(formatGameTime(gameState.elapsedTime))
                                .font(.system(size: fontSize(13, iPad: 18), weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        }
                    }
                    VStack(spacing: isIPad ? 6 : 4) {
                        Text(LocalizationManager.shared.localizedString("Time Per Question"))
                            .font(.system(size: fontSize(9, iPad: 13), weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
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
                                .scaleEffect(gameState.questionTimeLeft < 5 ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: gameState.questionTimeLeft < 5)
                        }
                    }
                }
                .padding(.trailing, isIPad ? 24 : 20)
            }
            .padding(.top, safeTopInset + (isCompactPhone ? 2 : 6))
            HStack(alignment: .center, spacing: isIPad ? 24 : 16) {
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

                if gameState.selectedPlayMode == .duel {
                    VStack(spacing: 4) {
                        Text(LocalizationManager.shared.localizedString("Duel"))
                            .font(.system(size: fontSize(11, iPad: 15), weight: .bold))
                            .foregroundColor(.white)
                        Text(String(format: LocalizationManager.shared.localizedString("vs %@"), duelOpponentDisplayName))
                            .font(.system(size: fontSize(11, iPad: 14), weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
                }

                Spacer()
                HStack(spacing: 8) {
                    let heartAsset = LocalizationManager.shared.lifeHeartAssetName
                    let heartSize = fontSize(48, iPad: 64)
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: heartSize, height: heartSize)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    if gameState.isPremium {
                        Image(systemName: "infinity")
                            .foregroundColor(.white)
                            .font(.system(size: fontSize(18, iPad: 24), weight: .bold))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    } else {
                        Text("\(gameState.lives)")
                            .font(.system(size: fontSize(18, iPad: 24), weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .scaleEffect(livesCountPop ? 1.2 : 1.0)
                            .animation(.easeOut(duration: 0.15), value: livesCountPop)
                    }
                }
                .padding(.horizontal, isIPad ? 10 : 8)
                .padding(.vertical, isIPad ? 6 : 5)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .overlay(alignment: .leading) {
                    let heartSize = fontSize(54, iPad: 72)
                    ZStack {
                        if showLoseAnimation, !gameState.isPremium {
                            HeartLoseAnimationView(
                                heartAsset: LocalizationManager.shared.lifeHeartAssetName,
                                size: heartSize
                            ) { showLoseAnimation = false }
                        }
                        if showGainAnimation, !gameState.isPremium {
                            HeartGainAnimationView(
                                heartAsset: LocalizationManager.shared.lifeHeartAssetName,
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
                    Text(LocalizationManager.shared.localizedString("Flags"))
                        .font(.system(size: fontSize(12, iPad: 16), weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
                        .font(.system(size: fontSize(17, iPad: 22), weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .padding(.trailing, isIPad ? 24 : 20)
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
        }
        .frame(height: (isCompactPhone ? 120 : 140) + safeTopInset, alignment: .top)
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
        .onAppear { if previousLives < 0 { previousLives = gameState.lives } }
        .onChange(of: gameState.lives) { newValue in
            if previousLives >= 0 {
                if newValue < previousLives { showLoseAnimation = true }
                else if newValue > previousLives { showGainAnimation = true }
            }
            previousLives = newValue
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
                    .font(.subheadline).foregroundColor(.secondary)
                Text(gameState.selectedDifficulty.displayName)
                    .font(.headline)
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
                // В режиме крупных символов показываем одно сердце и счётчик
                LivesView(lives: gameState.isPremium ? .constant(99) : $gameState.lives, isPremium: gameState.isPremium)
                Text("\(LocalizationManager.shared.localizedString("Flags")) \(gameState.currentQuestion + 1) / \(gameState.initialQuestionsCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(horizontalSizeClass == .regular ? 20 : 10)
    }
}

struct LivesView: View {
    @Binding var lives: Int
    var isPremium: Bool
    @Environment(\.sizeCategory) private var sizeCategory
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private var heartAsset: String { localizationManager.lifeHeartAssetName }

    var body: some View {
        HStack(spacing: 6) {
            if isPremium {
                ZStack {
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                    Image(systemName: "infinity")
                        .font(.title2)
                        .foregroundColor(.white)
                        .offset(y: 0.5)
                }
            } else if sizeCategory.isAccessibilityCategory {
                Image(heartAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                Text("\(lives)")
                    .font(.headline)
                    .foregroundColor(.primary)
            } else {
                ForEach(0..<min(lives, 5), id: \.self) { _ in
                    Image(heartAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 66, height: 66)
                }
                if lives > 5 {
                    Text("+\(lives - 5)").font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundSecondary))
    }
}

struct GameProgressView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 8 : 4) {
            Text(LocalizationManager.shared.localizedString("Flags"))
                .font(horizontalSizeClass == .regular ? .body : .caption)
                .foregroundColor(.secondary)
            
            Text("\(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
                .font(horizontalSizeClass == .regular ? .title : .headline)
                .foregroundColor(.primary)
            
            ProgressView(
                value: Double(gameState.currentQuestion + 1),
                total: Double(gameState.questionsPerGame)
            )
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: horizontalSizeClass == .regular ? 200 : 100)
            .scaleEffect(horizontalSizeClass == .regular ? 1.5 : 1.0)
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
            // Полностью скрываем таббар во время игры
            setTabBarHidden(true)
        }
        .onDisappear {
            // При любом уходе с экрана игры полностью останавливаем игровые таймеры,
            // чтобы в фоне не росли ошибки и не списывались жизни.
            gameState.stopTimer()
            // Возвращаем таббар
            setTabBarHidden(false)
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
    @ObservedObject private var themeManager = AppThemeManager.shared
    @StateObject private var viewModel: GameViewModel
    @State private var safeTopInset: CGFloat = 0
    @State private var containerSize: CGSize = .zero
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(gameState: GameState) {
        _viewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }

    /// iPad в альбомной ориентации — уменьшаем флаг, чтобы флаг + варианты ответов помещались без скролла
    private var isIPadLandscape: Bool {
        guard isIPad else { return false }
        if verticalSizeClass == .compact { return true }
        #if os(iOS)
        let size = containerSize.width > 0 ? containerSize : UIScreen.main.bounds.size
        #else
        let size = containerSize
        #endif
        return size.width > size.height
    }
    
    /// Высота шапки игры (для расчёта доступного места в ландшафте)
    private var gameHeaderHeight: CGFloat { 140 + safeTopInset }
    
    /// В ландшафте iPad: доступная высота под контент (флаг + ответы) без скролла
    private var iPadLandscapeContentHeight: CGFloat {
        guard containerSize.height > 0 else { return 0 }
        return containerSize.height - gameHeaderHeight - 32
    }
    
    /// Максимальная высота флага в ландшафте (крупные флаг и кнопки)
    private var iPadLandscapeFlagMaxHeight: CGFloat {
        let reservedForGrid: CGFloat = 256
        let available = iPadLandscapeContentHeight - reservedForGrid
        return max(160, min(240, available))
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Базовый фон под всем контентом
            backgroundColor
                .ignoresSafeArea()

            // Градиентный фон шапки под статус-баром
            iPadGameHeaderBackground

            VStack(spacing: 0) {
                // Та же шапка, что и на телефоне: подписи, анимации, минуты/секунды
                GameHeaderSectionView(gameState: gameState, safeTopInset: safeTopInset, onExitTap: { showingExitAlert = true })
                    .zIndex(1)

                // Основной игровой контент (в ландшафте iPad — без скролла, всё на один экран)
                ScrollView {
                    VStack(spacing: isIPadLandscape ? 8 : (isIPad ? 40 : 30)) {
                        gameContent
                    }
                    .padding(.top, isIPadLandscape ? 6 : (isIPad ? 40 : 30))
                    .padding(.bottom, isIPadLandscape ? 6 : (isIPad ? 40 : 30))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isIPadLandscape ? iPadLandscapeContentHeight : nil)
                }
                .modifier(ScrollDisabledIfAvailable(disabled: isIPadLandscape))
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 30 : 25, style: .continuous)
                        .fill(backgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                        .ignoresSafeArea(.container, edges: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: isIPad ? 30 : 25, style: .continuous))
                .padding(.top, isIPad ? -15 : -10)
            }
        }
            // Считываем safe area inset сверху
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: GameSafeTopInsetKey.self, value: geo.safeAreaInsets.top)
                        .preference(key: GameContainerSizeKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(GameSafeTopInsetKey.self) { value in
                safeTopInset = value
            }
            .onPreferenceChange(GameContainerSizeKey.self) { value in
                containerSize = value
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
            .onChange(of: gameState.currentQuestion, perform: resetViewModelState)
            .sheet(isPresented: $viewModel.showingGameOver, content: gameOverSheet)
            .alert(LocalizationManager.shared.localizedString("Out of lives"), isPresented: $viewModel.showingOutOfLives) {
                if !gameState.isPremium {
                    if RewardedAdService.isRewardedAdEnabled {
                        Button(LocalizationManager.shared.localizedString("Watch video for +3 lives")) {
                            RewardedAdService.shared.showIfAvailable(from: nil) {
                                gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                                viewModel.showingOutOfLives = false
                                Task { await viewModel.goToNextQuestion() }
                            }
                        }
                    }
                    Button(LocalizationManager.shared.localizedString("Get Free Lives")) {
                        Task { @MainActor in
                            gameState.refillLivesFree()
                            viewModel.showingOutOfLives = false
                            await viewModel.goToNextQuestion()
                        }
                    }
                    Button(LocalizationManager.shared.localizedString("Go Premium")) {
                        Task { @MainActor in
                            gameState.isPremium = true
                            viewModel.showingOutOfLives = false
                            await viewModel.goToNextQuestion()
                        }
                    }
                }
                Button(LocalizationManager.shared.localizedString("Play Again")) {
                    Task { await gameState.restartGameInPlace() }
                }
                Button(LocalizationManager.shared.localizedString("Home")) {
                    gameState.isNavigatingToGame = false
                    dismiss()
                }
            } message: {
                if gameState.isPremium {
                    Text(LocalizationManager.shared.localizedString("Continue playing with unlimited hearts!"))
                } else {
                    Text(LocalizationManager.shared.localizedString("Unfortunately you ran out of lives this time. Try again or come back later."))
                }
            }
            .alert(
                LocalizationManager.shared.localizedString("Exit Confirmation"),
                isPresented: $showingExitAlert,
                actions: exitAlertActions,
                message: exitAlertMessage
            )
            .preferredColorScheme(themeManager.colorScheme)
    }
    
    private var iPadGameHeaderBackground: some View {
        Color.clear
            .frame(height: 140 + safeTopInset)
            .ignoresSafeArea(.container, edges: .top)
    }
    
    private var gameContent: some View {
        Group {
            if let currentFlag = viewModel.currentFlag {
                #if os(iOS)
                let isLargeText = UIFont.preferredFont(forTextStyle: .body).pointSize > 20
                #else
                let isLargeText = false
                #endif
                let flagTop: CGFloat = isIPadLandscape ? 52 : (isLargeText ? 4 : 0)
                let flagBottom: CGFloat = isIPadLandscape ? 52 : (isLargeText ? 4 : 0)
                let stackSpacing: CGFloat = isIPadLandscape ? 12 : (isLargeText ? 12 : (isIPad ? 40 : 30))
                VStack(spacing: stackSpacing) {
                    flagView(for: currentFlag)
                        .padding(.top, flagTop)
                        .padding(.bottom, flagBottom)
                    answerGrid(for: currentFlag)
                }
                .padding(.horizontal, isIPadLandscape ? 48 : (isIPad ? 32 : 20))
                .frame(maxWidth: .infinity)
            } else {
                loadingView
            }
        }
    }
    
    private func flagView(for currentFlag: Country) -> some View {
        // Адаптируем размер флага для крупного шрифта
        #if os(iOS)
        let isLargeText = UIFont.preferredFont(forTextStyle: .body).pointSize > 20
        #else
        let isLargeText = false
        #endif
        // iPad в альбомной: высота по доступному месту, чтобы флаг + ответы помещались без скролла
        let maxHeight: CGFloat = isIPadLandscape ? iPadLandscapeFlagMaxHeight : (isIPad ? 700 : (isLargeText ? 400 : 500))
        
        return FlagCardView(
            country: currentFlag,
            isShowingInfo: $viewModel.isShowingInfo,
            flagScale: viewModel.flagScale,
            flagRotation: viewModel.flagRotation,
            gameState: gameState,
            onNextQuestion: {},
            compactForLandscape: isIPadLandscape
        )
        .frame(maxWidth: isIPad ? nil : (isLargeText ? 600 : 800), maxHeight: maxHeight)
        .id(currentFlag.id)
        .transition(.opacity)
    }
    
    private func answerGrid(for currentFlag: Country) -> some View {
        #if os(iOS)
        let isLargeText = UIFont.preferredFont(forTextStyle: .body).pointSize > 20
        let twoColumnLargeText = isIPad && isLargeText
        #else
        let isLargeText = false
        let twoColumnLargeText = false
        #endif
        // iPad (портрет и альбом) + крупный шрифт: два столбца, крупный текст в 2 строки, ограниченная высота — все 6 без скролла
        let columns: [GridItem] = twoColumnLargeText ? [
            GridItem(.flexible()),
            GridItem(.flexible())
        ] : (gameState.optionsCount == 6 ? [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ] : (isLargeText ? [
            GridItem(.flexible())
        ] : [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]))
        let gridSpacing: CGFloat = twoColumnLargeText ? 8 : (isIPadLandscape ? 12 : 20)
        
        return LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(viewModel.options, id: \.id) { country in
                AnswerButton(
                    country: country,
                    isSelected: viewModel.selectedAnswer == country,
                    isCorrect: viewModel.isShowingResult ? (country == currentFlag) : nil,
                    isIncorrect: viewModel.isShowingResult ? viewModel.selectedAnswer == country && country != currentFlag : nil,
                    compact: isIPadLandscape,
                    compactLarge: isIPadLandscape,
                    twoColumnLargeText: twoColumnLargeText,
                    action: {
                        withAnimation {
                            viewModel.selectAnswer(country)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: isIPad ? nil : 1000)
        .disabled(viewModel.isShowingResult)
        .opacity(viewModel.optionsOpacity)
    }
    
    private var loadingView: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
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
        PostGameFlowContainer(
            score: gameState.score,
            totalQuestions: gameState.initialQuestionsCount,
            timeElapsed: gameState.elapsedTime,
            dailyQuests: QuestService.shared.dailyQuests,
            monthlyQuests: UserProfile.shared.monthlyQuests,
            friends: UserProfile.shared.friends,
            gameState: gameState,
            onFinish: {
                // Закрываем фуллскрин, остаёмся в GameView
                viewModel.showingGameOver = false
            },
            onPlayAgain: {
                // Закрываем модальное окно и запускаем новую игру
                viewModel.showingGameOver = false
                Task {
                    // Небольшая задержка для закрытия модального окна
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 секунды
                    await gameState.restartGameInPlace()
                }
            },
            onHome: {
                // Возвращаемся на главную
                gameState.isNavigatingToGame = false
                dismiss()
            }
        )
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
            BackgroundView()
                .edgesIgnoringSafeArea(.all)
            
            // Градиентный фон шапки под статус-баром
            gameHeaderBackground

            // На телефоне только вертикальный макет (горизонтальная ориентация отключена в AppDelegate)
            portraitLayout
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
            PostGameFlowContainer(
                score: gameState.score,
                totalQuestions: gameState.initialQuestionsCount,
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
        #else
        .sheet(isPresented: $viewModel.showingGameOver) {
            PostGameFlowContainer(
                score: gameState.score,
                totalQuestions: gameState.initialQuestionsCount,
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
        .alert("\(LocalizationManager.shared.localizedString("Out of lives"))", isPresented: $viewModel.showingOutOfLives) {
            if !gameState.isPremium {
                if RewardedAdService.isRewardedAdEnabled {
                    Button(LocalizationManager.shared.localizedString("Watch video for +3 lives")) {
                        RewardedAdService.shared.showIfAvailable(from: nil) {
                            gameState.addLivesFromRewardedAd(amount: RewardedAdService.livesRewardAmount)
                            viewModel.showingOutOfLives = false
                            Task { await viewModel.goToNextQuestion() }
                        }
                    }
                }
                Button(LocalizationManager.shared.localizedString("Get Free Lives")) {
                    Task { @MainActor in
                        gameState.refillLivesFree()
                        viewModel.showingOutOfLives = false
                        // Принудительно переходим к следующему вопросу или завершаем игру, если это был последний
                        await viewModel.goToNextQuestion()
                    }
                }
                Button(LocalizationManager.shared.localizedString("Go Premium")) {
                    Task { @MainActor in
                        gameState.isPremium = true
                        viewModel.showingOutOfLives = false
                        await viewModel.goToNextQuestion()
                    }
                }
            }
            Button(LocalizationManager.shared.localizedString("Play Again")) {
                Task { await gameState.restartGameInPlace() }
            }
            Button(LocalizationManager.shared.localizedString("Home")) {
                gameState.isNavigatingToGame = false
                dismiss()
            }
        } message: {
            if gameState.isPremium {
                Text(LocalizationManager.shared.localizedString("Continue playing with unlimited hearts!"))
            } else {
                Text(LocalizationManager.shared.localizedString("Unfortunately you ran out of lives this time. Try again or come back later."))
            }
        }
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
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        #endif
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
    
    private var gameHeaderSection: some View {
        GameHeaderSectionView(gameState: gameState, safeTopInset: safeTopInset, onExitTap: { showingExitAlert = true })
    }
    
    private var gameHeaderBackground: some View {
        // Фон уже включен в gameHeaderSection, поэтому здесь просто прозрачный фон
        Color.clear
            .frame(height: 140 + safeTopInset)
            .ignoresSafeArea(.container, edges: .top)
    }
    
    // MARK: - Portrait Layout
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Закрепленная шапка игры
            gameHeaderSection
                .zIndex(1) // Убеждаемся, что шапка поверх фона

            // Основной игровой контент
            ScrollView {
                VStack(spacing: 12) {
                    if let currentFlag = viewModel.currentFlag {
                        GameContentView(
                            viewModel: viewModel,
                            currentFlag: currentFlag,
                            gameState: gameState
                        )
                    } else {
                        LoadingView()
                    }
                }
                .padding(.top, isCompactPhone ? 12 : 30)
                .padding(.bottom, isCompactPhone ? 12 : 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                    .ignoresSafeArea(.container, edges: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .padding(.top, -10)
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
                    Text(gameState.formattedTime())
                        .font(.system(size: 14, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.primary)
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
        VStack {
            FlagCardView(
                country: currentFlag,
                isShowingInfo: $viewModel.isShowingInfo,
                flagScale: viewModel.flagScale,
                flagRotation: viewModel.flagRotation,
                gameState: gameState,
                onNextQuestion: {
                    // Переходы теперь управляются автоматически
                    // Убираем ручной переход по клику
                }
            )
            .id(currentFlag.id)
            .transition(.opacity)
            .padding(.horizontal, isIPad ? 40 : 16)
            .padding(.vertical, isCompactPhone ? 4 : 8)
            
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
                    compact: useSmallButtons,
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
            VStack(spacing: 8) {
                HStack {
                    Text("⏰")
                        .font(.system(size: 20))
                    
                    Text(String(format: "%.1f", gameState.questionTimeLeft))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(gameState.questionTimeLeft < 5 ? .red : .primary)
                    
                    Text("sec")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: gameState.questionTimeProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: gameState.questionTimeLeft < 5 ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(height: 4)
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.vertical, 8)
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
                Text("🔥")
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
        gameState.recordQuestionResult(
            correctCountry: currentFlag,
            selectedCountry: country,
            questionIndex: gameState.currentQuestion,
            isCorrect: isCorrect
        )
        
        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")
        
        if isCorrect {
            print("✅ CORRECT ANSWER!")
            gameState.score += 1
            gameState.comboStreak += 1
            if gameState.comboStreak >= 3 {
                showLiveCombo(streak: gameState.comboStreak)
            }

            // Бонус за серию правильных ответов: дофамин-поинты каждые 3/5/10
            if [3, 5, 10].contains(gameState.comboStreak) {
                gameState.bonusXP += 10
                showLiveBonus(text: String(format: LocalizationManager.shared.localizedString("Combo x%d bonus"), gameState.comboStreak))
            }

            // Бонус за скорость: если ответили быстро, начисляем +1
            let fastThreshold = gameState.selectedDifficulty.timeLimit * 0.7
            if gameState.questionTimeLeft >= fastThreshold {
                gameState.bonusXP += 10
                showLiveBonus(text: LocalizationManager.shared.localizedString("Speed bonus +1"))
            }
            
            // Положительная вибрация при правильном ответе
            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            }
            #endif
            
                         // Проверяем, была ли страна в списке ошибок
             if gameState.selectedRegions.contains(.myMistakes) {
                 print("Adding to correctly answered list: \(currentFlag.name.common) (ID: \(currentFlag.id))")
                 // Добавляем в список правильно отвеченных для режима Mistakes
                 if gameState.mistakeCountries.contains(where: { $0.id == currentFlag.id }) {
                     correctlyAnsweredMistakes.insert(currentFlag.id)
                     print("🎉 Great job! This flag was in your mistakes list")
                 }
             }
        } else {
            print("❌ WRONG ANSWER!")
            gameState.comboStreak = 0
            gameState.liveComboText = nil
            
            // Отрицательная вибрация при неправильном ответе
            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
            #endif
            
            if !gameState.selectedRegions.contains(.myMistakes) {
                addMistake(currentFlag)
            }
            // Списываем жизнь и логируем
            gameState.consumeLifeOnWrongAnswer()
            print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
            if !gameState.isPremium && gameState.lives <= 0 {
                print("\n=== Out Of Lives ===\nLives depleted. Stopping game.\n=====================\n")
                gameState.stopTimer()
                showingOutOfLives = true
                return
            }
        }

        if isCorrect {
            print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
        }
        
        print("\nGame Statistics:")
        print("Current score: \(gameState.score)")
        print("Question: \(gameState.currentQuestion + 1)/\(gameState.initialQuestionsCount)")
        print("=====================\n")
        
        // Показываем информацию о стране с анимацией переворота карточки
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isShowingInfo = true
            self.flagScale = 0.8
            self.flagRotation = 180
        }
        
        // Переходим к следующему вопросу через 3 секунды
        nextQuestionTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
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
    
    func goToNextQuestion() async {
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
        
        if gameState.currentQuestion + 1 >= gameState.initialQuestionsCount {
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
