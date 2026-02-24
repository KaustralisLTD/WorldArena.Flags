import Foundation
import StoreKit
import SwiftUI

// Детерминированный RNG для дуэли: одинаковый seed даёт одинаковый порядок вопросов/вариантов.
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) {
        self.state = UInt64(truncatingIfNeeded: seed)
        if self.state == 0 { self.state = 1 }
    }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Результат дуэли для отображения после завершения игры (когда оба игрока сыграли).
struct DuelResultInfo {
    let challengerName: String
    let challengerScore: Int
    let opponentScore: Int
    let winnerSide: String
    var iWon: Bool { winnerSide == "opponent" }
}

@MainActor
class GameState: ObservableObject {
    @Published var score = 0
    @Published var currentQuestion = 0
    @Published var selectedRegions: Set<Region> = [.all]
    @Published private(set) var selectedLanguage: Language = .system {
        didSet {
            print("\n=== Changing Language ===")
            print("Old language: \(oldValue.rawValue)")
            print("New language: \(selectedLanguage.rawValue)")
            localizationManager.setLanguage(selectedLanguage)
            print("Language updated successfully")
            print("=====================\n")
        }
    }
    @Published var statistics = Statistics()
    @Published var countries: [Country] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentFlag: Country?
    @Published var options: [Country] = []
    @Published var localizationManager = LocalizationManager.shared
    @Published var networkMonitor = NetworkMonitor.shared
    @Published var isGameOver = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var timeProgress: Double = 0
    @Published var isNavigatingToGame = false {
        didSet {
            if isNavigatingToGame {
                print("\n🎮 Navigation to game triggered")
            }
        }
    }
    @Published var selectedGameMode: GameMode = .twenty {
        didSet {
            print("\n=== Game Mode Changed ===")
            print("New mode: \(selectedGameMode.displayName)")
            print("=====================\n")
        }
    }
    
    @Published var selectedPlayMode: PlayMode = .classic {
        didSet {
            print("\n=== Play Mode Changed ===")
            print("New mode: \(selectedPlayMode.displayName)")
            print("=====================\n")
        }
    }
    
    @Published var selectedDifficulty: Difficulty = .medium {
        didSet {
            print("\n=== Difficulty Changed ===")
            print("New difficulty: \(selectedDifficulty.displayName)")
            print("Questions per game: \(questionsPerGame)")
            print("=====================\n")
        }
    }
    
    /// Режим дуэли: seed для одинаковой игры у обоих игроков
    @Published var duelSeed: Int?
    @Published var duelChallengeId: String?
    @Published var duelOpponentId: String?
    @Published var duelChallengerName: String?
    /// Результат дуэли для отображения после завершения игры вторым игроком (opponent).
    @Published var pendingDuelResult: DuelResultInfo?
    
    var questionsPerGame: Int {
        switch selectedPlayMode {
        case .classic:
            // В классическом режиме используем количество вопросов из сложности
            // но ограничиваем максимальным количеством флагов из GameMode
            let difficultyQuestions = selectedDifficulty.questionCount(for: self)
            let maxFlags = selectedGameMode.flagCount
            
            // Для эрудита всегда используем все доступные страны
            if selectedDifficulty == .erudite {
                return difficultyQuestions // Int.max, будет ограничено доступными странами
            }
            
            // Если выбрано "Все флаги", используем количество из сложности
            if maxFlags == 0 {
                return difficultyQuestions
            }
            
            // Иначе берем минимум из сложности и лимита GameMode
            return min(difficultyQuestions, maxFlags)
        case .timeChallenge, .survival:
            return selectedDifficulty.questionCount(for: self)
        case .duel:
            let difficultyQuestions = selectedDifficulty.questionCount(for: self)
            let maxFlags = selectedGameMode.flagCount
            if selectedDifficulty == .erudite { return difficultyQuestions }
            if maxFlags == 0 { return difficultyQuestions }
            return min(difficultyQuestions, maxFlags)
        }
    }
    
    // Новые свойства для игровых режимов
    @Published var questionTimeLeft: TimeInterval = 0
    @Published var questionTimeProgress: Double = 0
    @Published var isQuestionTimerActive = false
    @Published var isSurvivalMode = false
    @Published var survivalLives = 3
    
    let gameDuration: TimeInterval = 900 // 15 минут на игру
    
    private var startTime: Date?
    private var timer: Timer?
    private var questionTimer: Timer?
    private var questionStartTime: Date?
    
    @Published private(set) var usedCountries: Set<String> = []
    private var availableCountries: [Country] = []
    
    private var isUpdatingRegions = false
    
        // Адаптивное количество вариантов ответов: 6 для iPhone, 8 для iPad
    @Published var optionsCount = 6

    
    @Published var mistakeCountries: [Country] = []
    
    // Добавляем новые свойства
    @Published var isCardFlipped = false
    @Published var canProceedToNextQuestion = false
    
    // Добавляем новое свойство для отслеживания причины перехода
    private var lastActionReason = ""
    
    // Добавляем свойство для отслеживания состояния обработки
    private var isProcessingAnswer = false
    
    // Добавляем свойство для отслеживания источника вызова
    private var callStack: [String] = []
    
    // Добавляем свойство для отслеживания предыдущего флага
    private var previousFlags: [String] = []
    
    // Добавляем новое свойство для отслеживания всех использованных флагов в текущей игре
    private var usedFlagsInGame: Set<String> = []
    
    // Добавляем новое свойство для таймера перехода
    private var transitionTimer: Timer?
    
    // Добавляем новые свойства
    @Published private var usedCountriesInGame: Set<String> = []
    @Published private var totalQuestionsInGame: Int = 20
    
    @Published var isStartingNewGame = false
    @Published var isPreloadingFlags = false
    @Published var flagPreloadProgress = 0.0
    private var preloadTask: Task<Void, Never>?
    
    private var loadedCountriesCache: [Region: [Country]] = [:]
    
    private var gameStartTime: Date?
    
    private var lastGameStartAttempt: Date?
    private let minimumTimeBetweenStarts: TimeInterval = 2.0
    
    // Добавим проверку, чтобы не загружать ошибки повторно
    private var mistakesLoaded = false
    
    // Добавляем флаг для отслеживания загрузки статистики
    private var statisticsLoaded = false
    
    // Добавим свойство для отслеживания последнего обработанного ответа
    private var lastProcessedAnswer: (id: String, time: Date)?
    
    private var isGameInProgress = false
    
    // Добавим новое свойство для хранения временных правильных ответов
    private var correctlyAnsweredMistakes: Set<String> = []
    
    // Добавляем свойство для хранения изначального количества вопросов
    @Published var initialQuestionsCount: Int = 0
    
    // Добавим свойство для отслеживания состояния карточки
    @Published var isCardInteractionEnabled = true

    // MARK: - Lives & Premium
    @Published var lives: Int = 5
    @Published var isPremium: Bool = false
    @Published var showMistakesPremiumAlert: Bool = false
    let maxLives: Int = 5
    private let livesRefillInterval: TimeInterval = 3600 // 1 час
    private var livesRefillTimer: Timer?
    private let livesStorageKey = "game.lives.current"
    private let lastRefillStorageKey = "game.lives.lastRefillAt"
    private let premiumStorageKey = "game.premium.enabled"

    private func loadLivesState() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: livesStorageKey) == nil {
            defaults.set(maxLives, forKey: livesStorageKey)
        }
        lives = defaults.integer(forKey: livesStorageKey)
        
        // НЕ загружаем isPremium из UserDefaults - он будет синхронизирован с StoreManager
        // isPremium = defaults.bool(forKey: premiumStorageKey)
        
        refillLivesIfNeeded()
        startLivesRefillTimer()
        
        // Синхронизируем Premium статус при каждой загрузке
        Task {
            await syncPremiumStatus()
        }
    }

    private func saveLivesState() {
        let defaults = UserDefaults.standard
        defaults.set(lives, forKey: livesStorageKey)
        // НЕ сохраняем isPremium в UserDefaults - он управляется StoreManager
        // defaults.set(isPremium, forKey: premiumStorageKey)
    }

    private func startLivesRefillTimer() {
        livesRefillTimer?.invalidate()
        livesRefillTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refillLivesIfNeeded()
            }
        }
        if let timer = livesRefillTimer { RunLoop.main.add(timer, forMode: .common) }
    }

    func refillLivesIfNeeded() {
        guard !isPremium else { return }
        let defaults = UserDefaults.standard
        let now = Date().timeIntervalSince1970
        let last = defaults.double(forKey: lastRefillStorageKey)
        if last == 0 {
            defaults.set(now, forKey: lastRefillStorageKey)
            return
        }
        if now - last >= livesRefillInterval, lives < maxLives {
            lives = maxLives
            defaults.set(now, forKey: lastRefillStorageKey)
            saveLivesState()
            print("❤️ Lives refilled to max: \(lives)")
        }
    }

    // Время до следующего автоматического пополнения жизней
    func timeToNextLivesRefill() -> TimeInterval? {
        guard !isPremium else { return nil }
        let defaults = UserDefaults.standard
        let last = defaults.double(forKey: lastRefillStorageKey)
        let now = Date().timeIntervalSince1970
        if last == 0 { return livesRefillInterval }
        let remaining = livesRefillInterval - (now - last)
        return max(0, remaining)
    }

    func consumeLifeOnWrongAnswer() {
        guard !isPremium else { return }
        if lives > 0 {
            lives -= 1
            saveLivesState()
            print("💔 Life consumed. Lives left: \(lives)")
        }
    }

    func canStartGameWithLives() -> Bool {
        return isPremium || lives > 0
    }
    
    /// Перемешивает массив: при дуэли — детерминированно по seed (одинаковый порядок у обоих игроков).
    private func shuffledWithSeed<T>(_ array: [T], seed: Int?, questionIndex: Int = 0) -> [T] {
        guard let s = seed else { return array.shuffled() }
        let combinedSeed = s &+ questionIndex &* 31
        var rng = SeededRNG(seed: combinedSeed)
        return array.shuffled(using: &rng)
    }

    // Бесплатное пополнение жизней (например, из алерта «Бесплатно +5 жизней»)
    func refillLivesFree() {
        guard !isPremium else { return }
        lives = maxLives
        saveLivesState()
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: lastRefillStorageKey)
        print("❤️ Free lives refilled to: \(lives)")
    }
    
    struct Statistics: Codable {
        var totalGames = 0
        var bestScore = 0
        var correctAnswers = 0
        var totalAnswers = 0
        var bestTime: TimeInterval = 0
    }
    
    enum Region: String, CaseIterable {
        case all = "All Regions"
        case europe = "Europe"
        case asia = "Asia"
        case africa = "Africa"
        case northAmerica = "North America"
        case southAmerica = "South America"
        case oceania = "Oceania"
        case myMistakes = "My Mistakes"
    }
    
    enum Language: String, CaseIterable {
        case system = "system"
        case english = "en"
        case russian = "ru"
        case spanish = "es"
        case ukrainian = "uk"
        case catalan = "ca"
        case chinese = "zh"
    }
    
    // Восстанавливаем оригинальный GameMode для количества флагов
    enum GameMode: Int, CaseIterable {
        case twenty = 20
        case fifty = 50
        case hundred = 100
        case all = 0
        
        @MainActor
        var displayName: String {
            switch self {
            case .twenty:
                return LocalizationManager.shared.localizedString("20 Flags")
            case .fifty:
                return LocalizationManager.shared.localizedString("50 Flags")
            case .hundred:
                return LocalizationManager.shared.localizedString("100 Flags")
            case .all:
                return LocalizationManager.shared.localizedString("All Flags")
            }
        }
        
        var flagCount: Int {
            return self.rawValue
        }
    }
    
    // Новый enum для режимов игры
    enum PlayMode: String, CaseIterable {
        case classic = "classic"
        case timeChallenge = "time-challenge"
        case survival = "survival"
        case duel = "duel"
        
        @MainActor
        var displayName: String {
            switch self {
            case .classic:
                return LocalizationManager.shared.localizedString("Classic")
            case .timeChallenge:
                return LocalizationManager.shared.localizedString("Time Challenge")
            case .survival:
                return LocalizationManager.shared.localizedString("Survival")
            case .duel:
                return LocalizationManager.shared.localizedString("Duel")
            }
        }
        
        @MainActor
        var description: String {
            switch self {
            case .classic:
                return LocalizationManager.shared.localizedString("Standard multiple choice game")
            case .timeChallenge:
                return LocalizationManager.shared.localizedString("Answer quickly, time is limited")
            case .survival:
                return LocalizationManager.shared.localizedString("Game until first mistake")
            case .duel:
                return LocalizationManager.shared.localizedString("Challenge a friend to the same game, compare results")
            }
        }
        
        var icon: String {
            switch self {
            case .classic:
                return "🎯"
            case .timeChallenge:
                return "⚡"
            case .survival:
                return "🔥"
            case .duel:
                return "⚔️"
            }
        }
        
        /// SF Symbol для режима (если есть — в UI показывать его вместо emoji)
        var systemImage: String? {
            switch self {
            case .duel: return "person.2.fill"
            default: return nil
            }
        }
    }
    
    enum Difficulty: String, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case expert = "expert"
        case erudite = "erudite"
        
        @MainActor
        var displayName: String {
            switch self {
            case .easy:
                return "Level - \(LocalizationManager.shared.localizedString("Easy"))"
            case .medium:
                return "Level - \(LocalizationManager.shared.localizedString("Medium"))"
            case .hard:
                return "Level - \(LocalizationManager.shared.localizedString("Hard"))"
            case .expert:
                return "Level - \(LocalizationManager.shared.localizedString("Expert"))"
            case .erudite:
                return "Level - \(LocalizationManager.shared.localizedString("Erudite"))"
            }
        }
        
        @MainActor
        var description: String {
            switch self {
            case .easy:
                return LocalizationManager.shared.localizedString("10 questions, 45 sec per answer")
            case .medium:
                return LocalizationManager.shared.localizedString("15 questions, 30 sec per answer")
            case .hard:
                return LocalizationManager.shared.localizedString("20 questions, 15 sec per answer")
            case .expert:
                return LocalizationManager.shared.localizedString("25 questions, 10 sec per answer")
            case .erudite:
                return LocalizationManager.shared.localizedString("30 questions, 5 sec per answer")
            }
        }
        
        func questionCount(for gameState: GameState) -> Int {
            switch self {
            case .easy: return 10
            case .medium: return 15
            case .hard: return 20
            case .expert: return 25
            case .erudite:
                // Для эрудита возвращаем максимальное количество (будет ограничено доступными странами)
                return Int.max
            }
        }
        
        var questionCount: Int {
            switch self {
            case .easy: return 10
            case .medium: return 15
            case .hard: return 20
            case .expert: return 25
            case .erudite: return 30 // Fallback значение
            }
        }
        
        var timeLimit: TimeInterval {
            switch self {
            case .easy: return 45
            case .medium: return 30
            case .hard: return 15
            case .expert: return 10
            case .erudite: return 5
            }
        }
    }

    @Published var availableGameModes: [GameMode] = GameMode.allCases
    @Published var availablePlayModes: [PlayMode] = PlayMode.allCases
    @Published var availableDifficulties: [Difficulty] = Difficulty.allCases
    
    init() {
        // Загружаем статистику и ошибки только один раз при инициализации
        statistics = StatisticsService.shared.loadStatistics()
        loadMistakes()
    }
    
    // Метод для обновления количества вариантов ответов в зависимости от устройства
    func updateOptionsCount(isIPad: Bool) {
        optionsCount = isIPad ? 8 : 6
    }
    
    // Метод для получения количества стран в выбранных регионах
    func getCountriesCountInSelectedRegions() async -> Int {
        do {
            let countries = try await fetchCountries(for: Array(selectedRegions))
            return countries.count
        } catch {
            return 0
        }
    }
    
    private func isCountryInSelectedRegions(_ country: Country) -> Bool {
        // Исключаем Антарктику
        if country.region == "Antarctic" {
            return false
        }
        
        // Проверяем все регионы
        if selectedRegions.contains(.all) {
            return true
        }
        
        // Проверяем список ошибок
        if selectedRegions.contains(Region.myMistakes) {
            if mistakeCountries.contains(where: { $0.id == country.id }) {
                return true
            }
        }
        
        // Проверяем конкретные регионы
        if selectedRegions.contains(.europe) && country.region == "Europe" {
            return true
        }
        
        if selectedRegions.contains(.asia) && country.region == "Asia" {
            return true
        }
        
        if selectedRegions.contains(.africa) && country.region == "Africa" {
            return true
        }
        
        if selectedRegions.contains(.oceania) && country.region == "Oceania" {
            return true
        }
        
        if selectedRegions.contains(.northAmerica) && 
           country.region == "Americas" && 
           (country.subregion == "Northern America" ||
            country.subregion == "Central America" ||
            country.subregion == "Caribbean") {
            return true
        }
        
        if selectedRegions.contains(.southAmerica) && 
           country.region == "Americas" && 
           country.subregion == "South America" {
            return true
        }
        
        return false
    }
    
    func startNewGame() async {
        print("\n=== Starting New Game ===")
        // Сбрасываем состояние игры
        resetGameState()
        
        do {
            // Загружаем страны для выбранных регионов
            let loadedCountries = try await fetchCountries(for: Array(selectedRegions))
            print("Total countries loaded: \(loadedCountries.count)")
            
            // Перемешиваем страны (в дуэли — по seed)
            availableCountries = Array(shuffledWithSeed(loadedCountries, seed: duelSeed).prefix(totalQuestionsInGame))
            print("Countries selected for game: \(availableCountries.count)")
            
            // Выбираем первый вопрос
            selectNextQuestion()
            
        } catch {
            print("Error starting new game: \(error)")
        }
    }
    
    // Заменим асинхронный метод selectNextQuestion на синхронный
    private func selectNextQuestion() {
        print("\n=== Preparing Question \(currentQuestion + 1)/\(initialQuestionsCount) ===")
        
        guard currentQuestion < availableCountries.count else {
            print("No more questions available")
            isGameOver = true
            return
        }
        
        // Берем следующую страну из уже отобранного списка
        let nextCountry = availableCountries[currentQuestion]
        print("Next country: \(nextCountry.name.common)")
        
        // Обновляем UI
        withAnimation(.easeInOut(duration: 0.3)) {
            // Устанавливаем новый флаг
            self.currentFlag = nextCountry
            
            var answerOptions = [nextCountry]
            
            // Если играем в режиме "Мои ошибки" и не хватает вариантов ответов
            if selectedRegions.contains(.myMistakes) && mistakeCountries.count < optionsCount {
                print("Not enough mistake countries for options, adding countries from other regions")
                
                // Собираем все доступные страны из кэша
                var otherCountries: [Country] = []
                for region in Region.allCases where region != .myMistakes && region != .all {
                    if let countries = loadedCountriesCache[region] {
                        otherCountries.append(contentsOf: countries)
                    }
                }
                
                // Перемешиваем и добавляем недостающие варианты
                otherCountries.shuffle()
                let additionalOptions = otherCountries
                    .filter { $0.id != nextCountry.id && !mistakeCountries.contains($0) }
                    .prefix(optionsCount - answerOptions.count)
                
                answerOptions.append(contentsOf: additionalOptions)
            } else {
                // Стандартная логика: всегда набираем optionsCount вариантов (6/8), при нехватке — дополняем из кэша регионов
                var pool = availableCountries.filter { $0.id != nextCountry.id }
                if pool.count < optionsCount - 1 {
                    var supplement: [Country] = []
                    for (_, list) in loadedCountriesCache { supplement.append(contentsOf: list) }
                    let poolIds = Set(pool.map(\.id))
                    let extra = supplement.filter { $0.id != nextCountry.id && !poolIds.contains($0.id) }
                    let needed = (optionsCount - 1) - pool.count
                    let taken = shuffledWithSeed(extra, seed: duelSeed, questionIndex: currentQuestion + 1000).prefix(needed)
                    pool = pool + Array(taken)
                }
                let shuffledOthers = shuffledWithSeed(pool, seed: duelSeed, questionIndex: currentQuestion)
                answerOptions.append(contentsOf: shuffledOthers.prefix(optionsCount - 1))
            }
            
            // Перемешиваем все варианты ответов (в дуэли — по seed+question)
            self.options = shuffledWithSeed(answerOptions, seed: duelSeed, questionIndex: currentQuestion)
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        // Запускаем таймер для вопроса
        startQuestionTimer()
        
        print("=== Question Timer Started ===\n")
    }
    
    // Добавим синхронную версию метода selectNextQuestion
    private func selectNextQuestionSync() {
        print("\n=== Preparing Question \(currentQuestion + 1)/\(initialQuestionsCount) ===")
        
        guard currentQuestion < availableCountries.count else {
            print("No more questions available")
            isGameOver = true
            return
        }
        
        // Берем следующую страну из уже отобранного списка
        let nextCountry = availableCountries[currentQuestion]
        print("Next country: \(nextCountry.name.common)")
        
        // Обновляем UI
        withAnimation(.easeInOut(duration: 0.3)) {
            // Устанавливаем новый флаг
            self.currentFlag = nextCountry
            
            var answerOptions = [nextCountry]
            
            // Стандартная логика: всегда optionsCount вариантов, при нехватке — дополняем из кэша
            var pool = availableCountries.filter { $0.id != nextCountry.id }
            if pool.count < optionsCount - 1 {
                var supplement: [Country] = []
                for (_, list) in loadedCountriesCache { supplement.append(contentsOf: list) }
                let poolIds = Set(pool.map(\.id))
                let extra = supplement.filter { $0.id != nextCountry.id && !poolIds.contains($0.id) }
                let needed = (optionsCount - 1) - pool.count
                let taken = shuffledWithSeed(extra, seed: duelSeed, questionIndex: currentQuestion + 1000).prefix(needed)
                pool = pool + Array(taken)
            }
            let shuffledOthers = shuffledWithSeed(pool, seed: duelSeed, questionIndex: currentQuestion)
            answerOptions.append(contentsOf: shuffledOthers.prefix(optionsCount - 1))
            
            // Перемешиваем все варианты ответов
            self.options = shuffledWithSeed(answerOptions, seed: duelSeed, questionIndex: currentQuestion)
            
            // Разрешаем взаимодействие с карточкой
            self.isCardInteractionEnabled = true
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        // Запускаем таймер для вопроса
        startQuestionTimer()
        
        print("=== Question Timer Started ===\n")
    }
    
    // Изменим метод selectAnswer на синхронный
    func selectAnswer(_ country: Country) {
        guard let currentFlag = currentFlag else {
            print("⚠️ No current flag to check answer against")
            return
        }
        
        guard !isProcessingAnswer else {
            print("\n⚠️ Answer is already being processed")
            return
        }
        
        // Блокируем взаимодействие с карточкой
        isCardInteractionEnabled = false
        isProcessingAnswer = true
        
        // Останавливаем таймер вопроса
        stopQuestionTimer()
        
        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")
        
        let isCorrect = country.id == currentFlag.id
        
        if isCorrect {
            print("✅ CORRECT ANSWER!")
            score += 1
            // Сохраняем правильный ответ в список, если играем в режиме ошибок
            if selectedRegions.contains(.myMistakes) {
                print("Adding to correctly answered list: \(currentFlag.name.common) (ID: \(currentFlag.id))")
                correctlyAnsweredMistakes.insert(currentFlag.id)
                print("Current correctly answered count: \(correctlyAnsweredMistakes.count)")
                let correctlyAnswered = mistakeCountries
                    .filter { correctlyAnsweredMistakes.contains($0.id) }
                    .map { $0.name.common }
                print("Correctly answered so far: \(correctlyAnswered.joined(separator: ", "))")
            }
        } else {
            print("❌ WRONG ANSWER!")
        }
        
        print("\nGame Statistics:")
        print("Current score: \(score)")
        print("Question: \(currentQuestion + 1)/\(initialQuestionsCount)")
        print("=====================\n")
        
        // Обновляем статистику
        updateStatistics(isCorrect: isCorrect)
        
        // Разблокируем обработку ответов
        isProcessingAnswer = false
    }
    
    func updateStatistics(isCorrect: Bool) {
        statistics.totalAnswers += 1
        if isCorrect {
            statistics.correctAnswers += 1
        }
    }
    
    // Добавим синхронный метод для завершения игры
    private func finishGameSync() {
        print("\n=== Finishing Game ===")
        print("Current score: \(score)")
        print("Current time: \(formattedTime())")
        print("Previous best time: \(formattedTime(statistics.bestTime))")
        
        // Обновляем список ошибок после завершения игры
        if selectedRegions.contains(.myMistakes) {
            print("\n=== Updating Mistakes List After Game ===")
            print("Correctly answered mistakes: \(correctlyAnsweredMistakes.count)")
            
            let correctlyAnsweredNames = mistakeCountries
                .filter { correctlyAnsweredMistakes.contains($0.id) }
                .map { $0.name.common }
            print("Correctly answered flags: \(correctlyAnsweredNames.joined(separator: ", "))")
            
            // Создаем новый список ошибок, исключая правильно отвеченные
            let updatedMistakes = mistakeCountries.filter { country in
                let shouldKeep = !correctlyAnsweredMistakes.contains(country.id)
                if !shouldKeep {
                    print("Removing from mistakes: \(country.name.common) (ID: \(country.id))")
                }
                return shouldKeep
            }
            
            // Обновляем список ошибок
            mistakeCountries = updatedMistakes
            
            // Сохраняем обновленный список ошибок
            saveMistakes()
            
            print("Remaining mistakes: \(mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
        }
        
        // Останавливаем таймер
        stopTimer()
        
        // Обновляем статистику
        print("\n=== Updating Statistics ===")
        print("Before update:")
        print("  Total games: \(statistics.totalGames)")
        print("  Best score: \(statistics.bestScore)")
        print("  Correct answers: \(statistics.correctAnswers)")
        print("  Total answers: \(statistics.totalAnswers)")
        print("  Best time: \(statistics.bestTime)")
        
        print("\nCurrent game results:")
        print("  Score (correct answers): \(score)")
        print("  Questions per game: \(questionsPerGame)")
        print("  Current question index: \(currentQuestion)")
        print("  Elapsed time: \(elapsedTime)")
        
        statistics.totalGames += 1
        statistics.bestScore = max(statistics.bestScore, score)
        // score уже содержит количество правильных ответов за игру
        statistics.correctAnswers += score
        // Плюсуем фактическое количество заданных вопросов в игре
        statistics.totalAnswers += initialQuestionsCount
        if elapsedTime < statistics.bestTime || statistics.bestTime == 0 {
            statistics.bestTime = elapsedTime
        }
        
        print("\nAfter update:")
        print("  Total games: \(statistics.totalGames)")
        print("  Best score: \(statistics.bestScore)")
        print("  Correct answers: \(statistics.correctAnswers)")
        print("  Total answers: \(statistics.totalAnswers)")
        print("  Best time: \(statistics.bestTime)")
        let accuracy = statistics.totalAnswers > 0 ? Double(statistics.correctAnswers) / Double(statistics.totalAnswers) * 100 : 0
        print("  Accuracy: \(String(format: "%.1f", accuracy))%")
        print("=====================\n")
        
        // Валидируем статистику перед сохранением
        validateStatistics()
        
        saveStatistics()

        // Обновляем профиль пользователя и достижения
        let profile = UserProfile.shared
        let gainedXP = score * 10
        let effectiveXP = gainedXP * profile.xpBoostMultiplier
        let answersThisGame = initialQuestionsCount
        print("\n=== Updating UserProfile After Game ===")
        print("Gained XP: \(gainedXP)" + (profile.xpBoostMultiplier > 1 ? " x\(profile.xpBoostMultiplier) = \(effectiveXP)" : ""))
        print("Answers this game: \(answersThisGame)")
        profile.totalGamesPlayed += 1
        profile.correctAnswers += score
        profile.totalAnswers += initialQuestionsCount
        // Правильная логика серии по дням
        profile.updateStreak()
        profile.addXP(gainedXP)
        profile.evaluateAchievementsAndUnlock()
        // Сообщаем сервису лиг о росте пользователя (с учётом буста XP)
        LeaguesService.shared.userGainedXP(effectiveXP, in: profile.currentLeague)
        // Обновляем месячные цели на основе результатов игры
        profile.updateMonthlyQuestsAfterGame(score: score, questions: initialQuestionsCount)
        // F-Bucks: +1 за идеальный результат (в дуэли — отдельно; за «Мои Ошибки» не начисляем)
        if selectedPlayMode != .duel && !selectedRegions.contains(.myMistakes) && score == initialQuestionsCount && initialQuestionsCount > 0 {
            profile.addFBucks(1, reason: .perfectGame)
        }
        // Режим дуэли: сохраняем результат и при двух результатах определяем победителя
        if selectedPlayMode == .duel, let cid = duelChallengeId {
            handleDuelFinish(score: score, challengeId: cid, profile: profile)
        }
        // Сохраняем обновлённый профиль
        profile.saveToStorage()
        // Обновляем ежедневные квесты
        QuestService.shared.updateAfterGame(score: score, totalQuestions: initialQuestionsCount, correctAnswers: score)
        print("✅ UserProfile updated; achievements re-evaluated")
    }
    
    // Изменим метод handleGameTimeout
    private func handleGameTimeout() {
        timer?.invalidate()
        timer = nil
        finishGameSync()
    }
    
    // Оставим асинхронный метод для вызова из других мест
    func finishGame() {
        stopTimer()
        finishGameSync()
    }
    
    private func handleDuelFinish(score: Int, challengeId: String, profile: UserProfile) {
        var side: String?
        if let idx = profile.outgoingDuelChallenges.firstIndex(where: { $0.id == challengeId }) {
            var c = profile.outgoingDuelChallenges[idx]
            c.challengerScore = score
            c.status = .challengerCompleted
            profile.outgoingDuelChallenges[idx] = c
            side = "challenger"
        }
        if let idx = profile.incomingDuelChallenges.firstIndex(where: { $0.id == challengeId }) {
            var c = profile.incomingDuelChallenges[idx]
            c.opponentScore = score
            c.status = .opponentCompleted
            let challengerScoreVal = c.challengerScore ?? 0
            let challengerNameVal = c.challengerName
            profile.incomingDuelChallenges[idx] = c
            if challengerScoreVal >= 0 {
                let opponentWon = score > challengerScoreVal
                if opponentWon {
                    profile.addFBucks(1)
                    Task { @MainActor in
                        NotificationService.shared.scheduleDuelWonNotification()
                    }
                }
                profile.incomingDuelChallenges.removeAll { $0.id == challengeId }
            }
            side = "opponent"
            let nameForResult = challengerNameVal
            let chScoreForResult = challengerScoreVal
            Task {
                guard let winner = try? await DuelAPIService.shared.submitScore(challengeId: challengeId, score: score, side: "opponent") else { return }
                await MainActor.run {
                    self.pendingDuelResult = DuelResultInfo(
                        challengerName: nameForResult,
                        challengerScore: chScoreForResult,
                        opponentScore: score,
                        winnerSide: winner
                    )
                }
            }
        }
        if let s = side, s == "challenger" {
            Task {
                guard let winner = try? await DuelAPIService.shared.submitScore(challengeId: challengeId, score: score, side: s) else { return }
                await MainActor.run {
                    if winner == "challenger" {
                        profile.addFBucks(1)
                        NotificationService.shared.scheduleDuelWonNotification()
                    }
                }
            }
        }
    }
    
    func setLanguage(_ language: Language) async {
        // Проверяем, не тот же ли это язык
        guard language != selectedLanguage else {
            print("ℹ️ Language already set to \(language.rawValue), skipping...")
            return
        }
        
        print("\n=== Changing Language ===")
        print("Old language: \(selectedLanguage.rawValue)")
        print("New language: \(language.rawValue)")
        // Если игра была активна, мягко останавливаем таймеры и снимаем флаг активности,
        // чтобы после смены языка можно было начать новую игру
        if isGameInProgress {
            print("⏸️ Pausing active game due to language change")
            stopTimer()
        }
        
        selectedLanguage = language
        localizationManager.setLanguage(language)
        
        // Принудительно обновляем режимы игры
        let currentFlags = countries.count
        await MainActor.run {
            // Сохраняем текущий режим
            let currentMode = selectedGameMode
            
            // Обновляем доступные режимы
            updateAvailableGameModes(totalFlags: currentFlags)
            
            // Восстанавливаем выбранный режим
            if availableGameModes.contains(currentMode) {
                selectedGameMode = currentMode
            }
            
            // Уведомляем об изменениях
            objectWillChange.send()
        }
        
        print("Language and game modes updated successfully")
        print("=====================\n")
    }
    
    private func updateRegions(_ newRegions: Set<Region>) async {
        print("\n=== Updating Regions ===")
        print("Old regions: \(selectedRegions.map { $0.rawValue })")
        print("New regions: \(newRegions.map { $0.rawValue })")
        
        selectedRegions = newRegions
        
        do {
            isLoading = true
            error = nil
            
            print("\n=== Loading Countries ===")
            print("Current regions: \(selectedRegions.map { $0.rawValue })")
            
            let loadedCountries = try await fetchCountries(for: Array(selectedRegions))
            countries = loadedCountries
            
            print("Total countries loaded: \(countries.count)")
            
            // Обновляем режимы игры с учетом новой логики
            await MainActor.run {
                updateAvailableGameModes(totalFlags: countries.count)
            }
            
            isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
            print("Error updating regions: \(error)")
        }
    }
    
    func setRegions(_ newRegions: Set<Region>) {
        selectedRegions = newRegions
        Task {
            await updateRegions(newRegions)
            // Режимы игры уже обновляются в updateRegions
        }
    }
    
    func toggleRegion(_ region: Region) {
        var newRegions = Set<Region>()
        
        if region == .all {
            newRegions = [.all]
        } else {
            newRegions = selectedRegions.filter { $0 != .all }
            
            if newRegions.contains(region) {
                newRegions.remove(region)
                if newRegions.isEmpty {
                    newRegions = [region]
                }
            } else {
                newRegions.insert(region)
            }
        }
        
        Task {
            await updateRegions(newRegions)
        }
    }
    
    func startNewGameWithCurrentRegions() async {
        guard !isStartingNewGame else {
            print("\n⚠️ Game start in progress")
            return
        }
        
        guard !isGameInProgress else {
            print("\n⚠️ Game is already in progress")
            return
        }

        guard canStartGameWithLives() else {
            print("\n⚠️ Not enough lives to start the game")
            self.error = nil
            return
        }
        
        isStartingNewGame = true
        isGameInProgress = true
        
        print("\n=== Starting New Game ===")
        print("Selected regions: \(selectedRegions.map { $0.rawValue })")
        
        // Сбрасываем состояние
        resetGameState()
        loadLivesState()
        
        // Загружаем ошибки
        loadMistakes()
        
        print("Final selected regions: \(selectedRegions.map { $0.rawValue })")
        
        // Сохраняем изначальное количество вопросов
        initialQuestionsCount = questionsPerGame
        print("Setting initial questions count to: \(initialQuestionsCount)")
        
        // Очищаем список правильных ответов при начале новой игры
        print("Clearing previously correctly answered mistakes")
        correctlyAnsweredMistakes.removeAll()
        
        do {
            // Загружаем страны только для выбранных регионов
            let loadedCountries = try await fetchCountries(for: Array(selectedRegions))
            print("Total unique countries loaded: \(loadedCountries.count)")
            
            guard !loadedCountries.isEmpty else {
                print("Error: No countries loaded")
                self.error = GameError.notEnoughCountries(count: 0)
                isStartingNewGame = false
                isGameInProgress = false
                return
            }
            
            // Корректируем количество вопросов в зависимости от доступных стран
            let actualQuestionsCount = min(questionsPerGame, loadedCountries.count)
            initialQuestionsCount = actualQuestionsCount
            print("Adjusted questions count from \(questionsPerGame) to \(actualQuestionsCount) based on available countries")
            
            // Перемешиваем страны (в дуэли — по seed для одинаковой игры)
            availableCountries = Array(shuffledWithSeed(loadedCountries, seed: duelSeed).prefix(actualQuestionsCount))
            print("\n=== Selected Countries for Game (\(availableCountries.count)) ===")
            for (index, country) in availableCountries.enumerated() {
                print("\(index + 1). \(country.name.common)")
            }
            print("=====================\n")
            
            // Оппортунистическая предзагрузка: быстрый буфер и ограниченный бюджет времени
            print("🚀 Starting opportunistic preloading...")
            isPreloadingFlags = true
            flagPreloadProgress = 0.0
            preloadTask?.cancel()
            preloadTask = Task { [countries = availableCountries] in
                // 1) Прогреть первые 3 флага мгновенно
                let warmCount = min(3, countries.count)
                if warmCount > 0 {
                    await FlagImageService.shared.preloadFlagsOpportunistic(
                        for: countries,
                        startIndex: 0,
                        count: warmCount,
                        maxDuration: 3.0
                    ) { [weak self] progress in
                        Task { @MainActor in self?.flagPreloadProgress = progress * 0.3 }
                    }
                }
                // 2) Скользящий буфер на следующие 6 флагов с бюджетом 5с
                let bufferStart = warmCount
                let bufferCount = min(6, max(0, countries.count - bufferStart))
                if bufferCount > 0 {
                    await FlagImageService.shared.preloadFlagsOpportunistic(
                        for: countries,
                        startIndex: bufferStart,
                        count: bufferCount,
                        maxDuration: 5.0
                    ) { [weak self] progress in
                        Task { @MainActor in self?.flagPreloadProgress = 0.3 + progress * 0.5 }
                    }
                }
                // 3) Остальные — только если остался бюджет времени, не более 8с суммарно
                let restStart = bufferStart + bufferCount
                if restStart < countries.count {
                    await FlagImageService.shared.preloadFlagsOpportunistic(
                        for: countries,
                        startIndex: restStart,
                        count: countries.count - restStart,
                        maxDuration: 8.0
                    ) { [weak self] progress in
                        Task { @MainActor in self?.flagPreloadProgress = 0.8 + progress * 0.2 }
                    }
                }
                await MainActor.run {
                    self.isPreloadingFlags = false
                    print("✅ Opportunistic preloading done (time-bounded)")
                }
            }
            
            // Выбираем первый вопрос синхронно
            selectNextQuestion()

            // Мгновенно прогреваем первое изображение флага для комфортного старта
            if let first = currentFlag {
                Task.detached(priority: .userInitiated) {
                    _ = await FlagImageService.shared.loadImageFast(from: first.flagURL)
                }
            }
            
            // Запускаем таймер
            startTimer()
            
            // Небольшая задержка для показа завершения загрузки
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
            
            // Устанавливаем флаг навигации
            await MainActor.run {
                isNavigatingToGame = true
            }
            
        } catch {
            print("Error starting new game: \(error)")
            self.error = error
            isStartingNewGame = false
            isGameInProgress = false
            return
        }
        
        isStartingNewGame = false
        print("\n✅ Game successfully started")
    }
    
    func proceedToNextQuestion() {
        // Добавляем вызов в стек
        callStack.append("proceedToNextQuestion")
        if callStack.count > 10 { callStack.removeFirst() }
        
        guard canProceedToNextQuestion else {
            print("\n=== Attempted to Proceed to Next Question ===")
            print("Status: Blocked")
            print("Reason: Cannot proceed yet")
            print("Card flipped: \(isCardFlipped)")
            print("Can proceed: \(canProceedToNextQuestion)")
            print("Is processing: \(isProcessingAnswer)")
            print("Call stack depth: \(callStack.count)")
            print("=====================\n")
            return
        }
        
        // Проверяем, не обрабатывается ли уже ответ
        if isProcessingAnswer {
            print("\n=== Proceed Blocked ===")
            print("Status: Blocked")
            print("Reason: Answer is being processed")
            print("=====================\n")
            return
        }
        
        print("\n=== Proceeding to Next Question ===")
        print("Status: Allowed")
        print("Previous action: \(lastActionReason)")
        print("Card flipped: \(isCardFlipped)")
        print("Current question: \(currentQuestion)")
        print("=====================\n")
        
        lastActionReason = "Manual proceed to next question"
        isCardFlipped = false
        canProceedToNextQuestion = false
        
        // Принудительно очищаем текущий флаг перед загрузкой нового
        currentFlag = nil
        
        loadNewQuestion()
    }
    
    private func moveToNextQuestion() {
        print("\n=== Moving to Next Question ===")
        print("Current state:")
        print("Card flipped: \(isCardFlipped)")
        print("Can proceed: \(canProceedToNextQuestion)")
        print("Is processing: \(isProcessingAnswer)")
        
        // Сбрасываем состояние
        isCardFlipped = false
        canProceedToNextQuestion = false
        isProcessingAnswer = false
        lastActionReason = "Auto proceed after answer"
        
        // Загружаем новый вопрос
        loadNewQuestion()
        
        print("State after reset:")
        print("Card flipped: \(isCardFlipped)")
        print("Can proceed: \(canProceedToNextQuestion)")
        print("Is processing: \(isProcessingAnswer)")
        print("=====================\n")
    }
    
    func loadNewQuestion() {
        if currentQuestion == 0 {
            generateNewQuestion()
        }
    }
    
    private func generateNewQuestion() {
        var newCountry: Country?
        let availableForSelection = availableCountries.filter { country in
            !previousFlags.contains(country.id)
        }
        
        if !availableForSelection.isEmpty {
            newCountry = availableForSelection.randomElement()
        } else {
            previousFlags.removeAll()
            newCountry = availableCountries.randomElement()
        }
        
        guard let randomCountry = newCountry else { return }
        
        var options = Set([randomCountry])
        let otherCountries = availableCountries.filter { $0.id != randomCountry.id }
        while options.count < optionsCount {
            if let country = otherCountries.randomElement() {
                options.insert(country)
            }
        }
        
        withAnimation {
            currentFlag = randomCountry
            self.options = Array(options).shuffled()
            isCardFlipped = false
            canProceedToNextQuestion = false
            isProcessingAnswer = false
        }
    }
    
    func addMistake(_ country: Country) {
        print("\n=== Adding to Mistakes List ===")
        print("Country: \(country.name.common)")
        
        // Проверяем, нет ли уже такой страны в списке ошибок
        if !mistakeCountries.contains(where: { $0.id == country.id }) {
            mistakeCountries.append(country)
            saveMistakes() // Сразу сохраняем изменения
            print("✅ Country added and saved to mistakes list")
            print("Total mistakes now: \(mistakeCountries.count)")
        } else {
            print("ℹ️ Country already in mistakes list")
        }
    }
    
    func removeMistake(_ country: Country) {
        print("\n=== Removing from Mistakes List ===")
        print("Country: \(country.name.common)")
        print("Reason: Correctly answered")
        
        mistakeCountries.removeAll(where: { $0.id == country.id })
        saveMistakes()
        
        print("\nMistakes List Status:")
        print("Total mistakes: \(mistakeCountries.count)")
        print("Remaining mistakes: \(mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
        print("=====================\n")
    }
    
    var hasMistakes: Bool {
        !mistakeCountries.isEmpty
    }
    
    private func getRegionPath(for region: GameState.Region) -> String {
        switch region {
        case .all:
            return "all"
        case .europe:
            return "region/europe"
        case .asia:
            return "region/asia"
        case .northAmerica, .southAmerica:
            return "region/americas"
        case .africa:
            return "region/africa"
        case .oceania:
            return "region/oceania"
        case .myMistakes:
            return "my-mistakes"
        }
    }
    
    func saveMistakes() {
        print("\n💾 Saving Mistakes")
        if let encoded = try? JSONEncoder().encode(mistakeCountries) {
            UserDefaults.standard.set(encoded, forKey: "mistakeCountries")
            print("✅ Saved \(mistakeCountries.count) mistakes")
            if !mistakeCountries.isEmpty {
                print("Current mistakes: \(mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
                print("Remaining mistakes: \(mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
            }
        } else {
            print("❌ Failed to save mistakes")
        }
    }
    
    func loadMistakes() {
        print("\n📂 Loading Mistakes")
        guard !mistakesLoaded else {
            print("ℹ️ Mistakes already loaded, skipping...")
            return
        }
        
        if let data = UserDefaults.standard.data(forKey: "mistakeCountries") {
            do {
                mistakeCountries = try JSONDecoder().decode([Country].self, from: data)
                print("✅ Successfully loaded \(mistakeCountries.count) mistakes")
                if !mistakeCountries.isEmpty {
                    print("Current mistakes: \(mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
                }
            } catch {
                print("❌ Error decoding mistakes:", error)
                print("Clearing incompatible mistake data...")
                UserDefaults.standard.removeObject(forKey: "mistakeCountries")
                mistakeCountries = []
            }
        } else {
            print("ℹ️ No mistakes data found")
            mistakeCountries = []
        }
        
        print("Initial mistakes count: \(mistakeCountries.count)")
        mistakesLoaded = true
    }
    
    func fetchCountries(for regions: [Region]) async throws -> [Country] {
        print("\nFetching countries for regions: \(regions.map { $0.rawValue })")
        var allCountries: [Country] = []
        
        // Проверяем кэш для каждого региона
        for region in regions {
            if let cachedCountries = loadedCountriesCache[region] {
                print("Using cached data for region: \(region.rawValue)")
                allCountries.append(contentsOf: cachedCountries)
                continue
            }
            
            // Если данных нет в кэше, загружаем
            switch region {
            case .myMistakes:
                loadMistakes()
                if !mistakeCountries.isEmpty {
                    print("Found \(mistakeCountries.count) mistakes to use")
                    allCountries.append(contentsOf: mistakeCountries)
                    loadedCountriesCache[.myMistakes] = mistakeCountries
                }
            case .all:
                let allRegions = Region.allCases.filter { $0 != .all && $0 != .myMistakes }
                for subRegion in allRegions {
                    if let cachedSubRegion = loadedCountriesCache[subRegion] {
                        allCountries.append(contentsOf: cachedSubRegion)
                    } else {
                        let countries = try await CountryService.shared.fetchCountries(for: Set([subRegion]))
                        loadedCountriesCache[subRegion] = countries
                        allCountries.append(contentsOf: countries)
                    }
                }
            default:
                let countries = try await CountryService.shared.fetchCountries(for: Set([region]))
                loadedCountriesCache[region] = countries
                allCountries.append(contentsOf: countries)
            }
        }
        
        let uniqueCountries = Array(Set(allCountries))
        print("Total unique countries loaded: \(uniqueCountries.count)")
        return uniqueCountries
    }
    
    private func saveStatistics() {
        print("\n=== Saving Statistics ===")
        print("Total games: \(statistics.totalGames)")
        print("Best score: \(statistics.bestScore)")
        print("Correct answers: \(statistics.correctAnswers)")
        print("Total answers: \(statistics.totalAnswers)")
        print("Best time: \(statistics.bestTime)")
        
        StatisticsService.shared.saveStatistics(statistics)
        
        print("Statistics successfully encoded and saved")
        print("=====================\n")
    }
    
    // При деинициализации класса
    deinit {
        timer?.invalidate()
        timer = nil
        questionTimer?.invalidate()
        questionTimer = nil
        transitionTimer?.invalidate()
        transitionTimer = nil
    }
    
    // Метод для проверки целостности статистики
    func validateStatistics() {
        print("\n=== Validating Statistics ===")
        print("Current statistics:")
        print("  Total games: \(statistics.totalGames)")
        print("  Best score: \(statistics.bestScore)")
        print("  Correct answers: \(statistics.correctAnswers)")
        print("  Total answers: \(statistics.totalAnswers)")
        print("  Best time: \(statistics.bestTime)")
        
        // Проверки целостности
        var issues: [String] = []
        
        if statistics.totalGames < 0 {
            issues.append("Total games is negative")
        }
        
        if statistics.bestScore < 0 {
            issues.append("Best score is negative")
        }
        
        if statistics.correctAnswers < 0 {
            issues.append("Correct answers is negative")
        }
        
        if statistics.totalAnswers < 0 {
            issues.append("Total answers is negative")
        }
        
        if statistics.correctAnswers > statistics.totalAnswers {
            issues.append("Correct answers (\(statistics.correctAnswers)) > Total answers (\(statistics.totalAnswers))")
        }
        
        if statistics.bestTime < 0 {
            issues.append("Best time is negative")
        }
        
        let accuracy = statistics.totalAnswers > 0 ? Double(statistics.correctAnswers) / Double(statistics.totalAnswers) * 100 : 0
        if accuracy > 100 {
            issues.append("Accuracy is over 100%")
        }
        
        if issues.isEmpty {
            print("✅ Statistics validation passed")
        } else {
            print("❌ Statistics validation failed:")
            for issue in issues {
                print("  - \(issue)")
            }
        }
        
        print("  Calculated accuracy: \(String(format: "%.1f", accuracy))%")
        print("=====================\n")
    }
    
    // Тестовый метод для проверки сохранения статистики
    func testStatisticsSaveLoad() {
        print("\n=== Testing Statistics Save/Load ===")
        
        // Сохраняем текущую статистику
        let originalStats = statistics
        print("Original statistics:")
        print("  Total games: \(originalStats.totalGames)")
        print("  Best score: \(originalStats.bestScore)")
        print("  Correct answers: \(originalStats.correctAnswers)")
        print("  Total answers: \(originalStats.totalAnswers)")
        print("  Best time: \(originalStats.bestTime)")
        
        // Создаем тестовую статистику
        var testStats = GameState.Statistics()
        testStats.totalGames = 5
        testStats.bestScore = 18
        testStats.correctAnswers = 75
        testStats.totalAnswers = 100
        testStats.bestTime = 120.5
        
        print("\nSaving test statistics:")
        print("  Total games: \(testStats.totalGames)")
        print("  Best score: \(testStats.bestScore)")
        print("  Correct answers: \(testStats.correctAnswers)")
        print("  Total answers: \(testStats.totalAnswers)")
        print("  Best time: \(testStats.bestTime)")
        
        // Сохраняем тестовую статистику
        StatisticsService.shared.saveStatistics(testStats)
        
        // Загружаем статистику обратно
        let loadedStats = StatisticsService.shared.loadStatistics()
        
        print("\nLoaded statistics:")
        print("  Total games: \(loadedStats.totalGames)")
        print("  Best score: \(loadedStats.bestScore)")
        print("  Correct answers: \(loadedStats.correctAnswers)")
        print("  Total answers: \(loadedStats.totalAnswers)")
        print("  Best time: \(loadedStats.bestTime)")
        
        // Проверяем соответствие
        let isMatching = testStats.totalGames == loadedStats.totalGames &&
                        testStats.bestScore == loadedStats.bestScore &&
                        testStats.correctAnswers == loadedStats.correctAnswers &&
                        testStats.totalAnswers == loadedStats.totalAnswers &&
                        abs(testStats.bestTime - loadedStats.bestTime) < 0.01
        
        if isMatching {
            print("✅ Statistics save/load test PASSED")
        } else {
            print("❌ Statistics save/load test FAILED")
        }
        
        // Восстанавливаем оригинальную статистику
        StatisticsService.shared.saveStatistics(originalStats)
        statistics = originalStats
        
        print("Original statistics restored")
        print("=====================\n")
    }
    
    private func formatPopulation(_ population: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        
        if population >= 1_000_000 {
            let millions = Double(population) / 1_000_000.0
            return String(format: "%.1f million", millions)
        } else if population >= 1_000 {
            let thousands = Double(population) / 1_000.0
            return String(format: "%.1f thousand", thousands)
        } else {
            return "\(population)"
        }
    }
    
    private func formatArea(_ area: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        
        if area >= 1_000_000 {
            let millions = area / 1_000_000.0
            return String(format: "%.2f million km²", millions)
        } else {
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) km²"
        }
    }
    
    func resetGameState() {
        resetGameState(preserveNavigation: false)
    }

    // Мягкий сброс без изменения флага навигации при перезапуске внутри GameView
    func resetGameState(preserveNavigation: Bool) {
        print("\n=== Resetting Game State ===")
        score = 0
        currentQuestion = 0
        isGameOver = false
        elapsedTime = 0
        timeProgress = 0
        if !preserveNavigation {
            isNavigatingToGame = false
        }
        usedCountriesInGame.removeAll()
        usedFlagsInGame.removeAll()
        timer?.invalidate()
        timer = nil
        questionTimer?.invalidate()
        questionTimer = nil
        questionStartTime = nil
        questionTimeLeft = 0
        questionTimeProgress = 0
        isQuestionTimerActive = false
        startTime = nil
        lastGameStartAttempt = nil
        isGameInProgress = false // Сбрасываем флаг при окончании игры
        duelSeed = nil
        duelChallengeId = nil
        duelOpponentId = nil
        duelChallengerName = nil
        pendingDuelResult = nil
        print("Game state has been reset")
        print("=====================\n")
    }

    // Перезапуск игры без выхода с экрана игры
    func restartGameInPlace() async {
        guard !isStartingNewGame else { return }
        isStartingNewGame = true
        print("\n=== Restarting Game In Place ===")
        print("Current question before reset: \(currentQuestion)")
        // Сохраняем навигацию и сбрасываем только игровые счетчики
        resetGameState(preserveNavigation: true)
        print("Current question after reset: \(currentQuestion)")
        isGameOver = false
        isNavigatingToGame = true
        loadLivesState()
        // отменяем предзагрузку от предыдущей сессии
        preloadTask?.cancel(); preloadTask = nil
        loadMistakes()
        correctlyAnsweredMistakes.removeAll()
        // Сбрасываем состояние карточки и вариантов ответов
        currentFlag = nil
        options = []
        isCardFlipped = false
        canProceedToNextQuestion = false
        do {
            let loadedCountries = try await fetchCountries(for: Array(selectedRegions))
            guard !loadedCountries.isEmpty else {
                self.error = GameError.notEnoughCountries(count: 0)
                isStartingNewGame = false
                return
            }
            let actualQuestionsCount = min(questionsPerGame, loadedCountries.count)
            initialQuestionsCount = actualQuestionsCount
            availableCountries = Array(shuffledWithSeed(loadedCountries, seed: duelSeed).prefix(actualQuestionsCount))
            print("Available countries count: \(availableCountries.count)")
            print("Current question before selectNextQuestion: \(currentQuestion)")
            // Оппортунистическая предзагрузка в фоне
            isPreloadingFlags = true
            flagPreloadProgress = 0.0
            preloadTask = Task { [countries = availableCountries] in
                await FlagImageService.shared.preloadFlagsOpportunistic(
                    for: countries,
                    startIndex: 0,
                    count: min(3, countries.count),
                    maxDuration: 3.0
                ) { [weak self] progress in
                    Task { @MainActor in self?.flagPreloadProgress = progress * 0.5 }
                }
                let bufferStart = min(3, countries.count)
                let bufferCount = min(6, max(0, countries.count - bufferStart))
                if bufferCount > 0 {
                    await FlagImageService.shared.preloadFlagsOpportunistic(
                        for: countries,
                        startIndex: bufferStart,
                        count: bufferCount,
                        maxDuration: 5.0
                    ) { [weak self] progress in
                        Task { @MainActor in self?.flagPreloadProgress = 0.5 + progress * 0.5 }
                    }
                }
                await MainActor.run { self.isPreloadingFlags = false }
            }
            // Убеждаемся, что currentQuestion равен 0 перед выбором первого вопроса
            currentQuestion = 0
            print("Current question set to 0, calling selectNextQuestion")
            selectNextQuestion()
            startTimer()
        } catch {
            self.error = error
        }
        isStartingNewGame = false
        isGameInProgress = true
        print("=== Restart In Place Completed ===\n")
    }
    
    func prepareNextQuestion() {
        currentQuestion += 1
        print("\n=== Preparing Question \(currentQuestion + 1)/\(initialQuestionsCount) ===")
        
        // Проверяем, есть ли еще вопросы
        guard currentQuestion < availableCountries.count else {
            print("No more questions available - finishing game")
            isGameOver = true
            finishGame()
            return
        }
        
        // Получаем следующую страну из предварительно загруженного списка
        let nextCountry = availableCountries[currentQuestion]
        print("Next country: \(nextCountry.name.common)")
        
        // Обновляем текущий флаг и варианты ответов
        withAnimation {
            self.currentFlag = nextCountry
            
            // Генерируем варианты ответов: всегда optionsCount, при нехватке — дополняем из кэша
            var pool = availableCountries.filter { $0.id != nextCountry.id }
            if pool.count < optionsCount - 1 {
                var supplement: [Country] = []
                for (_, list) in loadedCountriesCache { supplement.append(contentsOf: list) }
                let poolIds = Set(pool.map(\.id))
                let extra = supplement.filter { $0.id != nextCountry.id && !poolIds.contains($0.id) }
                let needed = (optionsCount - 1) - pool.count
                let taken = shuffledWithSeed(extra, seed: duelSeed, questionIndex: currentQuestion + 1000).prefix(needed)
                pool = pool + Array(taken)
            }
            var newOptions = [nextCountry]
            let shuffledOthers = shuffledWithSeed(pool, seed: duelSeed, questionIndex: currentQuestion)
            newOptions.append(contentsOf: shuffledOthers.prefix(optionsCount - 1))
            self.options = shuffledWithSeed(newOptions, seed: duelSeed, questionIndex: currentQuestion)
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        // Запускаем таймер для вопроса
        startQuestionTimer()
        
        print("=== Question Timer Started ===\n")
    }
    
    private func updateAvailableGameModes(totalFlags: Int) {
        print("\n=== Updating Game Modes ===")
        print("Total flags available: \(totalFlags)")
        
        // Все игровые режимы доступны всегда
        availableGameModes = GameMode.allCases
        
        // Обновляем доступные уровни сложности в зависимости от количества флагов
        var difficulties: [Difficulty] = []
        
        if totalFlags >= 10 {
            difficulties.append(.easy)
        }
        if totalFlags >= 15 {
            difficulties.append(.medium)
        }
        if totalFlags >= 20 {
            difficulties.append(.hard)
        }
        if totalFlags >= 25 {
            difficulties.append(.expert)
        }
        if totalFlags >= 30 {
            difficulties.append(.erudite)
        }
        
        availableDifficulties = difficulties.isEmpty ? [.easy] : difficulties
        
        // Если текущая сложность недоступна, выбираем первую доступную
        if !availableDifficulties.contains(selectedDifficulty) {
            selectedDifficulty = availableDifficulties.first ?? .easy
        }
        
        print("Available difficulties: \(availableDifficulties.map { $0.displayName })")
        print("Selected difficulty: \(selectedDifficulty.displayName)")
        print("Available game modes: \(availableGameModes.map { $0.displayName })")
        print("Selected game mode: \(selectedGameMode.displayName)")
        print("=====================\n")
    }
    
    // Изменим метод formattedTime (includeFraction: false — только минуты и секунды, без десятых)
    func formattedTime(_ time: TimeInterval = 0, includeFraction: Bool = true) -> String {
        let timeToFormat = time > 0 ? time : elapsedTime
        let minutes = Int(timeToFormat) / 60
        let seconds = timeToFormat.truncatingRemainder(dividingBy: 60)
        if includeFraction {
            return String(format: "%02d:%04.1f", minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, Int(seconds))
    }
    
    // Изменим метод startTimer
    func startTimer() {
        print("\n=== Starting Timer ===")
        startTime = Date()
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self,
                      let startTime = self.startTime else { return }
                
                self.elapsedTime = Date().timeIntervalSince(startTime)
                self.timeProgress = min(self.elapsedTime / self.gameDuration, 1.0)
                
                if self.timeProgress >= 1.0 {
                    self.timer?.invalidate()
                    self.timer = nil
                    // Вызываем синхронное завершение игры
                    self.finishGameSync()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
        print("Timer started")
        print("=====================\n")
    }
    
    // Методы для управления таймером вопросов
    func startQuestionTimer() {
        let timeLimit = selectedDifficulty.timeLimit
        print("\n=== Starting Question Timer ===")
        print("Time limit: \(timeLimit) seconds")
        
        questionStartTime = Date()
        questionTimeLeft = timeLimit
        questionTimeProgress = 0
        isQuestionTimerActive = true
        
        questionTimer?.invalidate()
        questionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self,
                      let startTime = self.questionStartTime else { return }
                
                let elapsed = Date().timeIntervalSince(startTime)
                self.questionTimeLeft = max(0, timeLimit - elapsed)
                self.questionTimeProgress = min(elapsed / timeLimit, 1.0)
                
                // Если время истекло
                if self.questionTimeLeft <= 0 {
                    print("⏰ Question time expired!")
                    self.stopQuestionTimer()
                    self.handleQuestionTimeout()
                }
            }
        }
        
        RunLoop.main.add(questionTimer!, forMode: .common)
        print("Question timer started")
        print("=====================\n")
    }
    
    func stopQuestionTimer() {
        print("\n=== Stopping Question Timer ===")
        questionTimer?.invalidate()
        questionTimer = nil
        isQuestionTimerActive = false
        questionStartTime = nil
        // Обнуляем отображаемые значения таймера
        questionTimeLeft = 0
        questionTimeProgress = 1.0
        print("Question timer stopped")
        print("=====================\n")
    }
    
    private func handleQuestionTimeout() {
        print("\n=== Handling Question Timeout ===")
        
        // Блокируем взаимодействие с карточкой
        isCardInteractionEnabled = false
        
        // Засчитываем как неправильный ответ
        updateStatistics(isCorrect: false)
        
        // Отнимаем жизнь при истечении времени (только для не-Premium пользователей)
        if !isPremium {
            consumeLifeOnWrongAnswer()
            print("💔 Lost life due to timeout")
        }
        
        // Добавляем в список ошибок, если это не режим "Мои ошибки"
        if let currentFlag = currentFlag, !selectedRegions.contains(.myMistakes) {
            addMistake(currentFlag)
            print("🔥 Added to mistakes due to timeout: \(currentFlag.name.common)")
        }
        
        print("Statistics updated for timeout")
        print("Current score: \(score)")
        print("Question: \(currentQuestion + 1)/\(initialQuestionsCount)")
        print("=====================\n")
        
        // Переходим к следующему вопросу через небольшую задержку
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.proceedToNextQuestionAfterTimeout()
        }
    }
    
    private func proceedToNextQuestionAfterTimeout() {
        print("\n=== Proceeding After Timeout ===")
        
        // Проверяем, не закончилась ли игра
        if currentQuestion + 1 >= initialQuestionsCount {
            print("Game finished due to timeout on last question")
            isGameOver = true
            finishGame()
            return
        }
        
        // Переходим к следующему вопросу
        prepareNextQuestion()
        
        // Разрешаем взаимодействие с карточкой
        isCardInteractionEnabled = true
        
        print("Ready for next question after timeout")
        print("=====================\n")
    }

    // Изменим метод stopTimer на синхронный
    func stopTimer() {
        print("\n=== Stopping Timer ===")
        timer?.invalidate()
        timer = nil
        stopQuestionTimer() // Также останавливаем таймер вопросов
        print("Timer stopped")
        print("Final time: \(formattedTime())")
        print("=====================\n")
        // Останавливаем любую предзагрузку
        preloadTask?.cancel()
        preloadTask = nil
        // Сессия игры больше не активна
        isGameInProgress = false
    }
    
    // MARK: - Flag Preloading
    
    @MainActor
    private func preloadFlagsWithProgress(for countries: [Country]) async {
        await FlagImageService.shared.preloadFlagsWithProgress(for: countries) { [weak self] progress in
            Task { @MainActor in
                self?.flagPreloadProgress = progress
            }
        }
    }
    
    // MARK: - Premium Status Sync
    
    func syncPremiumStatus() async {
        await StoreManager.shared.updatePurchasedProducts()
        self.isPremium = StoreManager.shared.isPremium
        print("✅ Premium status synced: \(isPremium)")
    }
    
    func initializeStoreManager() {
        Task {
            await StoreManager.shared.loadProducts()
            await syncPremiumStatus()
            
            // Устанавливаем наблюдение за изменениями Premium статуса
            await setupPremiumStatusObserver()
        }
    }
    
    private func setupPremiumStatusObserver() async {
        // Наблюдаем за изменениями purchasedProductIDs в StoreManager
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let newPremiumStatus = StoreManager.shared.isPremium
                if self.isPremium != newPremiumStatus {
                    self.isPremium = newPremiumStatus
                    print("🔄 Premium status updated: \(self.isPremium)")
                }
            }
        }
    }
}

enum GameError: LocalizedError {
    case notEnoughCountries(count: Int)
    
    var errorDescription: String? {
        switch self {
        case .notEnoughCountries(let count):
            return String(format: NSLocalizedString("Not enough countries in selected regions (found %d, need at least 6)", comment: ""), count)
        }
    }
}

// Оставляем только одно расширение для NotificationCenter.Name
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// Все остальные объявления уже существуют в других местах кода 