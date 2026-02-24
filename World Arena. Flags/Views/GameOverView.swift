import SwiftUI

struct GameOverView: View {
    let score: Int
    let timeElapsed: String
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) private var sheetDismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var scoreScale = 0.5
    @State private var buttonsOpacity = 0.0
    @State private var isSharePresented = false
    @State private var confettiAnimation = false
    @State private var pulseAnimation = false
    
    private func getResultMessage(score: Int, total: Int) -> String {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return LocalizationManager.shared.localizedString("Excellent game!")
        } else if percentage >= 0.7 {
            return LocalizationManager.shared.localizedString("Great result!")
        } else if percentage >= 0.5 {
            return LocalizationManager.shared.localizedString("Good game!")
        } else {
            return LocalizationManager.shared.localizedString("Keep practicing!")
        }
    }
    
    private func getResultEmoji(score: Int, total: Int) -> String {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return "🏆"
        } else if percentage >= 0.7 {
            return "🎉"
        } else if percentage >= 0.5 {
            return "👏"
        } else {
            return "💪"
        }
    }
    
    private func getResultColor(score: Int, total: Int) -> Color {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return .yellow
        } else if percentage >= 0.7 {
            return .green
        } else if percentage >= 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: horizontalSizeClass == .regular ? 40 : 30) {
                // Эмодзи результата
                Text(getResultEmoji(score: score, total: gameState.questionsPerGame))
                    .font(.system(size: horizontalSizeClass == .regular ? 120 : 80))
                    .scaleEffect(confettiAnimation ? 1.2 : 1.0)
                    .rotationEffect(.degrees(confettiAnimation ? 360 : 0))
                
                // Сообщение о результате
                Text(getResultMessage(score: score, total: gameState.questionsPerGame))
                    .font(.system(size: horizontalSizeClass == .regular ? 34 : 28, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [getResultColor(score: score, total: gameState.questionsPerGame), .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.move(edge: .top))
                
                // Карточка со счетом
                VStack(spacing: horizontalSizeClass == .regular ? 20 : 15) {
                    Text("\(score)")
                        .font(.system(size: horizontalSizeClass == .regular ? 100 : 70, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .scaleEffect(scoreScale)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(LocalizationManager.shared.localizedString("points"))
                        .font(.system(size: horizontalSizeClass == .regular ? 20 : 17, weight: .semibold, design: .default))
                        .foregroundColor(.secondary)
                        .opacity(buttonsOpacity)
                    
                    // Время
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .foregroundColor(.blue)
                        Text("\(LocalizationManager.shared.localizedString("Time")): \(timeElapsed)")
                    }
                    .font(horizontalSizeClass == .regular ? .title2 : .headline)
                    .padding(horizontalSizeClass == .regular ? 15 : 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(horizontalSizeClass == .regular ? 15 : 10)
                    .opacity(buttonsOpacity)
                }
                .padding(horizontalSizeClass == .regular ? 30 : 20)
                .background(
                    RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 25 : 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 8)
                )
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                
                // Кнопки действий
                VStack(spacing: horizontalSizeClass == .regular ? 20 : 15) {
                    // Play Again - главная кнопка
                    Button(action: {
                        Task { @MainActor in
                            isSharePresented = false
                            // Сначала закрываем экран результатов (только шит)
                            sheetDismiss()
                            // Небольшая задержка до завершения dismiss, затем перезапуск в том же экране
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            await gameState.restartGameInPlace()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(horizontalSizeClass == .regular ? .title : .headline)
                            Text(LocalizationManager.shared.localizedString("Play Again"))
                                .font(.system(size: horizontalSizeClass == .regular ? 20 : 17, weight: .bold, design: .default))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(horizontalSizeClass == .regular ? 20 : 15)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(horizontalSizeClass == .regular ? 20 : 15)
                        .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    
                    HStack(spacing: horizontalSizeClass == .regular ? 20 : 15) {
                        // Share Result
                        Button(action: {
                            isSharePresented = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.circle.fill")
                                Text(LocalizationManager.shared.localizedString("Share Result"))
                            }
                            .font(.system(size: horizontalSizeClass == .regular ? 16 : 14, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(horizontalSizeClass == .regular ? 15 : 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(horizontalSizeClass == .regular ? 15 : 12)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // Home
                        Button(action: {
                            // Возврат на главную: явно выходим из игры
                            gameState.stopTimer()
                            gameState.isNavigatingToGame = false
                            // Закрываем только шит; уход на главную выполнит сам навигатор
                            sheetDismiss()
                        }) {
                            HStack {
                                Image(systemName: "house.circle.fill")
                                Text(LocalizationManager.shared.localizedString("Home"))
                            }
                            .font(.system(size: horizontalSizeClass == .regular ? 16 : 14, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(horizontalSizeClass == .regular ? 15 : 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(horizontalSizeClass == .regular ? 15 : 12)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
            }
            .padding(horizontalSizeClass == .regular ? 40 : 20)
        }
        .background(
            LinearGradient(
                colors: [
                    getResultColor(score: score, total: gameState.questionsPerGame).opacity(0.1),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            // Анимация появления счета
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scoreScale = 1.0
            }
            
            // Анимация появления кнопок
            withAnimation(.easeIn.delay(0.3)) {
                buttonsOpacity = 1.0
            }
            
            // Анимация конфетти для отличных результатов
            if Double(score) / Double(gameState.questionsPerGame) >= 0.7 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    confettiAnimation = true
                }
            }
            
            // Пульсация карточки счета
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                pulseAnimation = true
            }
        }
        .alert(LocalizationManager.shared.localizedString("Share Result"), isPresented: $isSharePresented) {
            Button(LocalizationManager.shared.localizedString("OK")) { }
        } message: {
            Text(ShareService.shared.createShareMessage(score: score))
        }
    }
}

 