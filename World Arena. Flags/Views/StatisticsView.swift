import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    StatisticRow(
                        title: LocalizationManager.shared.localizedString("Total Games"),
                        value: "\(gameState.statistics.totalGames)"
                    )
                    StatisticRow(
                        title: LocalizationManager.shared.localizedString("Best Score"),
                        value: "\(gameState.statistics.bestScore)"
                    )
                    StatisticRow(
                        title: LocalizationManager.shared.localizedString("Correct Answers"),
                        value: "\(gameState.statistics.correctAnswers)"
                    )
                    StatisticRow(
                        title: LocalizationManager.shared.localizedString("Accuracy"),
                        value: String(format: "%.1f%%", accuracy)
                    )
                    StatisticRow(
                        title: LocalizationManager.shared.localizedString("Best Time"),
                        value: gameState.formattedTime(gameState.statistics.bestTime)
                    )
                }
                .listStyle(.insetGrouped)
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Text(LocalizationManager.shared.localizedString("Clear"))
                        .foregroundColor(.red)
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("Statistics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Close")) {
                        dismiss()
                    }
                }
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
            }
        }
    }
    
    private var accuracy: Double {
        guard gameState.statistics.totalAnswers > 0 else { return 0 }
        return Double(gameState.statistics.correctAnswers) / Double(gameState.statistics.totalAnswers) * 100
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(.green)
        }
    }
} 