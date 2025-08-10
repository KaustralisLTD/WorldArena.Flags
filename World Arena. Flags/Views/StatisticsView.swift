import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingClearAlert = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: horizontalSizeClass == .regular ? 30 : 20) {
                    // Заголовок с эмодзи
                    VStack(spacing: horizontalSizeClass == .regular ? 15 : 10) {
                        Text("📊")
                            .font(.system(size: horizontalSizeClass == .regular ? 80 : 50))
                        Text(LocalizationManager.shared.localizedString("Statistics"))
                            .font(.system(size: horizontalSizeClass == .regular ? 34 : 28, weight: .bold, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, horizontalSizeClass == .regular ? 30 : 20)
                    
                    // Статистические карточки
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: horizontalSizeClass == .regular ? 20 : 15) {
                        
                        StatisticCard(
                            icon: "🎮",
                            title: LocalizationManager.shared.localizedString("Total Games"),
                            value: "\(gameState.statistics.totalGames)",
                            color: .blue,
                            isLarge: horizontalSizeClass == .regular
                        )
                        
                        StatisticCard(
                            icon: "🏆",
                            title: LocalizationManager.shared.localizedString("Best Score"),
                            value: "\(gameState.statistics.bestScore)",
                            color: .orange,
                            isLarge: horizontalSizeClass == .regular
                        )
                        
                        StatisticCard(
                            icon: "✅",
                            title: LocalizationManager.shared.localizedString("Correct Answers"),
                            value: "\(gameState.statistics.correctAnswers)",
                            color: .green,
                            isLarge: horizontalSizeClass == .regular
                        )
                        
                        StatisticCard(
                            icon: "🎯",
                            title: LocalizationManager.shared.localizedString("Accuracy"),
                            value: String(format: "%.1f%%", accuracy),
                            color: .purple,
                            isLarge: horizontalSizeClass == .regular
                        )
                        
                        StatisticCard(
                            icon: "⏱️",
                            title: LocalizationManager.shared.localizedString("Best Time"),
                            value: gameState.formattedTime(gameState.statistics.bestTime),
                            color: .red,
                            isLarge: horizontalSizeClass == .regular
                        )
                        
                        // Пустая карточка для симметрии
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
                    
                    // Кнопки управления
                    VStack(spacing: horizontalSizeClass == .regular ? 20 : 15) {
                        #if DEBUG
                        // Кнопка тестирования (только в DEBUG)
                        Button(action: {
                            gameState.testStatisticsSaveLoad()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Test Statistics")
                            }
                            .font(horizontalSizeClass == .regular ? .title2 : .headline)
                            .foregroundColor(.white)
                            .padding(horizontalSizeClass == .regular ? 20 : 15)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 300 : 200)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(horizontalSizeClass == .regular ? 20 : 15)
                            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        #endif
                        
                        // Кнопка очистки
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(LocalizationManager.shared.localizedString("Clear"))
                            }
                            .font(horizontalSizeClass == .regular ? .title2 : .headline)
                            .foregroundColor(.white)
                            .padding(horizontalSizeClass == .regular ? 20 : 15)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 300 : 200)
                            .background(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(horizontalSizeClass == .regular ? 20 : 15)
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.top, horizontalSizeClass == .regular ? 30 : 20)
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0.0)
                }
                .padding(.bottom, horizontalSizeClass == .regular ? 40 : 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                // Кнопка закрытия
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: horizontalSizeClass == .regular ? 35 : 25))
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(horizontalSizeClass == .regular ? 30 : 20)
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text(LocalizationManager.shared.localizedString("Clear Statistics")),
                    message: Text(LocalizationManager.shared.localizedString("Are you sure you want to clear all statistics?")),
                    primaryButton: .destructive(Text(LocalizationManager.shared.localizedString("Clear"))) {
                        StatisticsService.shared.clearStatistics()
                        gameState.statistics = GameState.Statistics()
                    },
                    secondaryButton: .cancel(Text(LocalizationManager.shared.localizedString("Cancel")))
                )
            }
            .onAppear {
                // Обновляем статистику при открытии окна
                gameState.statistics = StatisticsService.shared.loadStatistics()
                
                // Валидируем загруженную статистику
                gameState.validateStatistics()
                
                // Анимация появления
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animateCards = true
                }
            }
        }
    }
    
    private var accuracy: Double {
        guard gameState.statistics.totalAnswers > 0 else { return 0 }
        return Double(gameState.statistics.correctAnswers) / Double(gameState.statistics.totalAnswers) * 100
    }
}

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let isLarge: Bool
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: isLarge ? 15 : 10) {
            Text(icon)
                .font(.system(size: isLarge ? 50 : 35))
                .scaleEffect(animateValue ? 1.2 : 1.0)
            
            Text(title)
                .font(.system(size: isLarge ? 18 : 12, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(value)
                .font(.system(size: isLarge ? 28 : 22, weight: .bold, design: .default))
                .foregroundColor(color)
        }
        .padding(isLarge ? 25 : 20)
        .frame(maxWidth: .infinity)
        .frame(height: isLarge ? 180 : 140)
        .background(
            RoundedRectangle(cornerRadius: isLarge ? 20 : 15)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isLarge ? 20 : 15)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.5), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateValue = true
            }
        }
    }
} 