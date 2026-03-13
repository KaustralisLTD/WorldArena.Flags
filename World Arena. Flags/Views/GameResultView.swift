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
    var detailedResults: [GameQuestionResult] = []
    let onContinue: () -> Void
    
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
    
    private var baseXP: Int { score * 10 + bonusXP }
    private var boostedXP: Int { baseXP * max(1, appliedXPBoostMultiplier) }
    
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
            
            VStack(spacing: 25) {
                Spacer()
                if let duel = duelResult {
                    duelResultCard(duel)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
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
                        
                        // Score breakdown
                        Text("\(score) / \(totalQuestions)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
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
                        icon: "⚡",
                        iconImageName: "ResultXP",
                        color: .orange,
                        isVisible: showStats,
                        delay: 0
                    )
                    
                    EnhancedStatCard(
                        title: localizationManager.localizedString("ACCURACY"),
                        value: accuracyValue,
                        icon: "🎯",
                        iconImageName: "ResultAccuracy",
                        color: .green,
                        isVisible: showStats,
                        delay: 0.1
                    )
                    
                    EnhancedStatCard(
                        title: localizationManager.localizedString("TIME"),
                        value: formattedTime,
                        icon: "⏱️",
                        iconImageName: "ResultTime",
                        color: .blue,
                        isVisible: showStats,
                        delay: 0.2
                    )

                    if earnedFBucks > 0 {
                        FBucksEarnedCard(
                            title: localizationManager.localizedString("F-BUCKS EARNED"),
                            earned: earnedFBucks,
                            iconImageName: "ResultFBucks",
                            isVisible: showStats,
                            delay: 0.3
                        )
                    }
                }
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 50)
                
                Spacer()
                
                VStack(spacing: 10) {
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

                    // Enhanced continue button
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
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.8)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showDetailedResults) {
            GameDetailedResultsView(results: detailedResults)
        }
        .onAppear {
            startEnhancedAnimations()
        }
    }
    
    // MARK: - Computed Properties
    
    private var characterEmoji: String {
        let accuracy = Double(score) / Double(totalQuestions)
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
        let accuracy = Double(score) / Double(totalQuestions)
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
        let accuracy = Double(score) / Double(totalQuestions)
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
        let accuracy = Double(score) / Double(totalQuestions)
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
        let winnerText = duel.winnerSide == "opponent"
            ? localizationManager.localizedString("You won!")
            : "\(duel.challengerName) \(localizationManager.localizedString("won"))"
        let rewardText = duel.iWon
            ? "+1 F-Bucks"
            : ""
        return VStack(spacing: 8) {
            Text(localizationManager.localizedString("Duel result"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Text("\(duel.challengerName): \(duel.challengerScore) — \(localizationManager.localizedString("You")): \(duel.opponentScore)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(winnerText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(duel.iWon ? .green : .primary)
            if !rewardText.isEmpty {
                Text(rewardText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(systemGray6.opacity(0.9))
        .cornerRadius(16)
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
        let accuracy = Double(score) / Double(totalQuestions)
        if accuracy >= 0.9 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                confettiAnimation = true
            }
        }
    }
}

private struct GameDetailedResultsView: View {
    let results: [GameQuestionResult]
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
                        VStack(alignment: .leading, spacing: 6) {
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
                            Text("\(localizationManager.localizedString("Flag")): \(item.flagName)")
                                .font(.system(size: 16, weight: .semibold))
                            if item.timedOut {
                                Text(localizationManager.localizedString("Time is up"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            } else if let selected = item.selectedAnswer {
                                Text("\(localizationManager.localizedString("Your answer")): \(selected)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
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
    let icon: String
    /// Имя изображения в Assets для иконки (если задано — показывается вместо emoji).
    var iconImageName: String? = nil
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
                if let oldValue, revealBoostedValue {
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
                // Animated value display
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
            
            // Modern title styling
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
    private let color: Color = .yellow
    @State private var cardScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
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
                        colors: [color, color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
                                colors: [color.opacity(0.05), Color.clear, color.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
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