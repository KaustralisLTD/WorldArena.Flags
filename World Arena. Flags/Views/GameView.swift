import SwiftUI

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
                        .fill(Color(.systemGray5))
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
    
    var body: some View {
        VStack(spacing: 4) {
            Text(LocalizationManager.shared.localizedString("Time"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                Text(gameState.formattedTime())
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBackgroundSecondary)
            )
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    var onExit: () -> Void
    
    var body: some View {
        HStack {
            ExitButton(action: onExit)
            
            Spacer()
            
            GameInfoPanel(gameState: gameState)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct ExitButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(LocalizationManager.shared.localizedString("Exit"))
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appBackgroundSecondary)
                )
        }
        .padding(.top)
    }
}

struct GameInfoPanel: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack {
            GameTimerView(gameState: gameState)
            
            Spacer()
            
            GameProgressView(gameState: gameState)
            
            Spacer()
            
            GameScoreView(score: gameState.score)
        }
        .padding()
    }
}

struct GameProgressView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 4) {
            Text(LocalizationManager.shared.localizedString("Flags"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(gameState.currentQuestion + 1)/\(gameState.questionsPerGame)")
                .font(.headline)
                .foregroundColor(.primary)
            
            ProgressView(
                value: Double(gameState.currentQuestion + 1),
                total: Double(gameState.questionsPerGame)
            )
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 100)
        }
    }
}

struct GameScoreView: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(LocalizationManager.shared.localizedString("Score"))
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(score)")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appBackgroundSecondary)
                )
        }
    }
}

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var themeManager = AppThemeManager.shared
    
    @State private var showingExitAlert = false
    @State private var isFirstAppear = true
    
    init(gameState: GameState) {
        self.gameState = gameState
        _viewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                HeaderView(gameState: gameState) {
                    showingExitAlert = true
                }
                
                if let currentFlag = viewModel.currentFlag {
                    GameContentView(
                        viewModel: viewModel,
                        currentFlag: currentFlag,
                        gameState: gameState
                    )
                } else {
                    LoadingView()
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $viewModel.showingGameOver) {
            GameOverView(
                score: gameState.score,
                timeElapsed: gameState.formattedTime(),
                dismiss: dismiss
            )
        }
        .alert(LocalizationManager.shared.localizedString("Exit Confirmation"), isPresented: $showingExitAlert) {
            Button(LocalizationManager.shared.localizedString("Yes")) {
                Task {
                    await gameState.stopTimer()
                    gameState.resetGameState()
                    dismiss()
                }
            }
            Button(LocalizationManager.shared.localizedString("No"), role: .cancel) { }
        } message: {
            Text(LocalizationManager.shared.localizedString("Are you sure you want to exit the game?"))
        }
        .onChange(of: gameState.currentQuestion) { _ in
            withAnimation {
                viewModel.isShowingInfo = false
                viewModel.flagScale = 1.0
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
}

struct GameContentView: View {
    @ObservedObject var viewModel: GameViewModel
    let currentFlag: Country
    let gameState: GameState
    
    var body: some View {
        VStack {
            FlagCardView(
                country: currentFlag,
                isShowingInfo: $viewModel.isShowingInfo,
                flagScale: viewModel.flagScale,
                flagRotation: viewModel.flagRotation,
                gameState: gameState,
                onNextQuestion: {
                    Task {
                        await viewModel.goToNextQuestion()
                    }
                }
            )
            .id(currentFlag.id)
            .transition(.opacity)
            .padding()
            
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
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.options, id: \.id) { country in
                AnswerButton(
                    country: country,
                    isSelected: viewModel.selectedAnswer == country,
                    isCorrect: viewModel.isShowingResult ? (country == currentFlag) : nil,
                    isIncorrect: viewModel.isShowingResult ? viewModel.selectedAnswer == country && country != currentFlag : nil,
                    action: {
                        withAnimation {
                            viewModel.selectAnswer(country)
                        }
                    }
                )
            }
        }
        .padding()
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

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    @Published var selectedAnswer: Country?
    @Published var isShowingResult = false
    @Published var isShowingInfo = false
    @Published var showingGameOver = false
    @Published var flagScale = 1.0
    @Published var flagRotation = 0.0
    @Published var optionsOpacity = 1.0
    
    private var nextQuestionTask: Task<Void, Never>?
    
    var currentFlag: Country? { gameState.currentFlag }
    var options: [Country] { gameState.options }
    
    init(gameState: GameState) {
        self.gameState = gameState
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
        
        selectedAnswer = country
        isShowingResult = true
        
        let isCorrect = country.id == currentFlag.id
        
        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")
        
        if isCorrect {
            print("✅ CORRECT ANSWER!")
            gameState.score += 1
        } else {
            print("❌ WRONG ANSWER!")
            if !gameState.selectedRegions.contains(.myMistakes) {
                addMistake(currentFlag)
            }
        }
        
        print("\nGame Statistics:")
        print("Current score: \(gameState.score)")
        print("Question: \(gameState.currentQuestion + 1)/\(gameState.questionsPerGame)")
        print("=====================\n")
        
        // Показываем информацию о стране
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isShowingInfo = true
            self.flagScale = 0.8
            self.flagRotation = 180
        }
        
        // Переходим к следующему вопросу через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                await self.goToNextQuestion()
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
            return
        }
        
        // Запрашиваем следующий вопрос у GameState
        await gameState.prepareNextQuestion()
        
        withAnimation {
            flagScale = 1.0
            flagRotation = 0
            isShowingInfo = false
            optionsOpacity = 1.0
            selectedAnswer = nil
            isShowingResult = false
        }
    }
} 
