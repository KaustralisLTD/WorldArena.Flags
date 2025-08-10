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
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 8 : 4) {
            Text(LocalizationManager.shared.localizedString("Time"))
                .font(horizontalSizeClass == .regular ? .body : .caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(horizontalSizeClass == .regular ? .title2 : .body)
                    .foregroundColor(.blue)
                Text(gameState.formattedTime())
                    .font(horizontalSizeClass == .regular ? .title2 : .body)
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }
            .padding(horizontalSizeClass == .regular ? 16 : 8)
            .background(
                RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 12 : 8)
                    .fill(Color.appBackgroundSecondary)
            )
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    var onExit: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack {
            ExitButton(action: onExit)
            
            Spacer()
            
            GameInfoPanel(gameState: gameState)
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
        .padding(.top, horizontalSizeClass == .regular ? 20 : 10)
    }
}

struct ExitButton: View {
    var action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Button(action: action) {
            Text(LocalizationManager.shared.localizedString("Exit"))
                .font(horizontalSizeClass == .regular ? .title2 : .headline)
                .foregroundColor(.primary)
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                .padding(.vertical, horizontalSizeClass == .regular ? 16 : 8)
                .background(
                    RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 12 : 8)
                        .fill(Color.appBackgroundSecondary)
                )
        }
        .padding(.top, horizontalSizeClass == .regular ? 16 : 8)
    }
}

struct GameInfoPanel: View {
    @ObservedObject var gameState: GameState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack {
            GameTimerView(gameState: gameState)
            
            Spacer()
            
            GameProgressView(gameState: gameState)
            
            Spacer()
            
            GameScoreView(score: gameState.score)
        }
        .padding(horizontalSizeClass == .regular ? 20 : 10)
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
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && geometry.size.width > 768 {
                // iPad макет
                iPadGameLayout()
                    .environmentObject(gameState)
            } else {
                // iPhone макет
                phoneGameLayout(gameState: gameState)
            }
        }
    }
}

private struct iPadGameLayout: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @State private var showingExitAlert = false
    @ObservedObject private var themeManager = AppThemeManager.shared
    @StateObject private var viewModel: GameViewModel
    
    init() {
        // Создаем временный GameState для инициализации
        // Реальный gameState будет передан через @EnvironmentObject
        _viewModel = StateObject(wrappedValue: GameViewModel(gameState: GameState()))
    }
    
    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
            .preferredColorScheme(themeManager.colorScheme)
            .onAppear(perform: setupViewModel)
            .onChange(of: gameState.currentQuestion, perform: resetViewModelState)
            .sheet(isPresented: $viewModel.showingGameOver, content: gameOverSheet)
            .alert(
                LocalizationManager.shared.localizedString("Exit Confirmation"),
                isPresented: $showingExitAlert,
                actions: exitAlertActions,
                message: exitAlertMessage
            )
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            HeaderView(gameState: gameState, onExit: {
                showingExitAlert = true
            })
            
            gameContent
            
            Spacer()
        }
    }
    
    private var gameContent: some View {
        Group {
            if let currentFlag = viewModel.currentFlag {
                VStack(spacing: 30) {
                    flagView(for: currentFlag)
                    answerGrid(for: currentFlag)
                }
                .padding(.horizontal)
            } else {
                loadingView
            }
        }
    }
    
    private func flagView(for currentFlag: Country) -> some View {
        FlagCardView(
            country: currentFlag,
            isShowingInfo: $viewModel.isShowingInfo,
            flagScale: viewModel.flagScale,
            flagRotation: viewModel.flagRotation,
            gameState: gameState,
            onNextQuestion: {}
        )
        .frame(maxWidth: 800, maxHeight: 500)
        .id(currentFlag.id)
        .transition(.opacity)
    }
    
    private func answerGrid(for currentFlag: Country) -> some View {
        let columns = gameState.optionsCount == 6 ? [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ] : [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.options, id: \.id) { country in
                AnswerButton(
                    country: country,
                    isSelected: viewModel.selectedAnswer == country,
                    isCorrect: viewModel.isShowingResult ? (country == currentFlag) : nil,
                    isIncorrect: viewModel.isShowingResult ? viewModel.selectedAnswer == country && country != currentFlag : nil,
                    action: {
                        print("🔥 iPad Button clicked: \(country.name.common)")
                        withAnimation {
                            viewModel.selectAnswer(country)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: 1000)
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
        GameOverViewWrapper(
            score: gameState.score,
            timeElapsed: gameState.formattedTime(),
            onDismiss: {
                gameState.isNavigatingToGame = false
            }
        )
        .environmentObject(gameState)
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

struct GameOverViewWrapper: View {
    let score: Int
    let timeElapsed: String
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GameOverView(
            score: score,
            timeElapsed: timeElapsed,
            dismiss: dismiss
        )
        .onDisappear {
            onDismiss()
        }
    }
}

private struct phoneGameLayout: View {
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
                    // Переходы теперь управляются автоматически
                    // Убираем ручной переход по клику
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

// Добавляю компонент для отображения таймера вопроса
struct QuestionTimerView: View {
    @ObservedObject var gameState: GameState
    
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
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// Добавляю компонент для отображения режима выживания
struct SurvivalModeView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        if gameState.selectedPlayMode == .survival {
            HStack {
                Text("🔥")
                    .font(.system(size: 20))
                
                Text("Survival Mode")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("One mistake = Game Over")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
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
    @Published var flagScale = 1.0
    @Published var flagRotation = 0.0
    @Published var optionsOpacity = 1.0
    
    private var nextQuestionTask: Task<Void, Never>?
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
        
        // Отменяем предыдущую задачу перехода к следующему вопросу
        nextQuestionTask?.cancel()
        
        selectedAnswer = country
        isShowingResult = true
        
        let isCorrect = country.id == currentFlag.id
        
        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")
        
        if isCorrect {
            print("✅ CORRECT ANSWER!")
            gameState.score += 1
            
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
            if !gameState.selectedRegions.contains(.myMistakes) {
                addMistake(currentFlag)
            }
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
