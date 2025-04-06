import SwiftUI

@MainActor
final class FlagGameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedAnswer: Country?
    @Published var isShowingResult = false
    @Published var isShowingInfo = false
    @Published var showingGameOver = false
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
            statisticsService.loadStatistics()
            statisticsService.loadMistakes()
            isInitialized = true
        }
    }
    
    // MARK: - Game Logic
    func selectAnswer(_ country: Country) {
        print("\n=== selectAnswer called ===")
        print("Selected country: \(country.name.common)")
        
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
            
            // Выводим текущий список ошибок
            print("\nCurrent Mistakes List:")
            for mistake in gameState.mistakeCountries {
                print("- \(mistake.name.common)")
            }
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
        
        if gameState.currentQuestion + 1 >= gameState.questionsPerGame {
            await gameState.stopTimer()
            await gameState.finishGame()
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