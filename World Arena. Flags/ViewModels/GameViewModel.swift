import SwiftUI
#if os(iOS)
import UIKit
#endif

@MainActor
final class FlagGameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedAnswer: Country?
    @Published var isShowingResult = false
    @Published var isShowingInfo = false
    @Published var showingGameOver = false
    @Published var showingOutOfLives = false
    @Published var flagScale: CGFloat = 1.0
    @Published var flagRotation: Double = 0.0
    @Published var optionsOpacity: Double = 1.0
    
    // MARK: - Private Properties
    private var nextQuestionTask: Task<Void, Never>?
    private var isInitialized = false
    
    // MARK: - Dependencies
    let gameState: GameState
    let statisticsService: StatisticsService
    
    // MARK: - Computed Properties
    var currentFlag: Country? { gameState.currentFlag }
    var options: [Country] { gameState.options }
    
    // MARK: - Initialization
    init(gameState: GameState, statisticsService: StatisticsService) {
        self.gameState = gameState
        self.statisticsService = statisticsService
        
        // Убедимся, что инициализация происходит только один раз
        if !isInitialized {
            _ = statisticsService.loadStatistics()
            statisticsService.loadMistakes()
            isInitialized = true
        }
    }
    
    // MARK: - Game Logic
    func selectAnswer(_ country: Country) {
        print("\n=== selectAnswer called ===")
        print("Selected country: \(country.name.common)")
        
        // Вибрация при выборе ответа
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        // Останавливаем таймер вопроса при выборе ответа
        gameState.stopQuestionTimer()
        
        nextQuestionTask?.cancel()
        selectedAnswer = country
        
        guard let currentFlag = gameState.currentFlag else {
            print("Error: currentFlag is nil")
            return
        }
        
        // Логируем результат ответа
        print("\n=== Answer Result ===")
        print("Question Flag: \(currentFlag.name.common)")
        print("Selected Answer: \(country.name.common)")
        let isCorrect = country == currentFlag
        print("Result: \(isCorrect ? "Correct" : "Incorrect")")
        
        // Если ответ неправильный, добавляем текущий флаг в список ошибок
        if !isCorrect {
            print("Adding to mistakes list: \(currentFlag.name.common)")
            gameState.addMistake(currentFlag)
            gameState.consumeLifeOnWrongAnswer()
            print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
            if !gameState.isPremium && gameState.lives <= 0 {
                print("\n=== Out Of Lives ===\nLives depleted. Stopping game.\n=====================\n")
                gameState.stopTimer()
                showingOutOfLives = true
                return
            }
            
            // Выводим текущий список ошибок
            print("\nCurrent Mistakes List:")
            for mistake in gameState.mistakeCountries {
                print("- \(mistake.name.common)")
            }
        }
        else {
            print("Lifes: \(gameState.isPremium ? Int.max : gameState.lives)")
        }
        print("=====================\n")
        
        // Обновляем UI
        isShowingResult = true
        isShowingInfo = true
        
        withAnimation(.easeOut(duration: 0.3)) {
            optionsOpacity = 0.7
        }
        
        if isCorrect {
            print("✅ CORRECT ANSWER!")
            gameState.score += 1
            
            // Вибрация при правильном ответе (более веселая)
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            #endif
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                flagScale = 1.2
            }
            
            // Проверяем, была ли страна в списке ошибок
            if gameState.mistakeCountries.contains(currentFlag) {
                print("🎉 Great job! This flag was in your mistakes list")
                gameState.removeMistake(currentFlag)
            }
        } else {
            print("❌ WRONG ANSWER!")
            
            // Вибрация при неправильном ответе (более грустная)
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            #endif
            
            print("\nMistake Details:")
            print("- You selected: \(country.name.common)")
            print("  Region: \(country.region)")
            print("  Subregion: \(country.subregion ?? "N/A")")
            if let capitals = country.capital {
                print("  Capital(s): \(capitals.joined(separator: ", "))")
            }
            
            print("\nCorrect Answer Details:")
            print("- Correct country: \(currentFlag.name.common)")
            print("  Region: \(currentFlag.region)")
            print("  Subregion: \(currentFlag.subregion ?? "N/A")")
            if let capitals = currentFlag.capital {
                print("  Capital(s): \(capitals.joined(separator: ", "))")
            }
        }
        
        gameState.updateStatistics(isCorrect: isCorrect)
        
        print("\nGame Statistics:")
        print("Current score: \(gameState.score)")
        print("Total mistakes: \(gameState.mistakeCountries.count)")
        print("Mistakes list: \(gameState.mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
        print("=====================\n")
        
        // Создаем новую задачу для автоматического перехода к следующему вопросу
        nextQuestionTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled && isShowingInfo && !showingGameOver {
                await goToNextQuestion()
            }
        }
    }
    
    func goToNextQuestion() async {
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
        
        if gameState.currentQuestion + 1 >= gameState.initialQuestionsCount {
            gameState.stopTimer()
            gameState.finishGame()
            showingGameOver = true
        } else {
            withAnimation {
                gameState.currentQuestion += 1
                flagScale = 1.0
                isShowingInfo = false
                optionsOpacity = 1.0
                gameState.loadNewQuestion()
                selectedAnswer = nil
                isShowingResult = false
            }
        }
    }
    
    // При деинициализации отменяем все задачи
    deinit {
        nextQuestionTask?.cancel()
    }
} 