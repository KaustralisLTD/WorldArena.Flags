import Foundation
import StoreKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
    /// Имя оппонента challengера (для корректного текста в pending-сценарии).
    let opponentName: String
    let challengerScore: Int
    let opponentScore: Int
    /// Время прохождения (мс), если сервер вернул — для ничьей по счёту победитель по меньшему времени.
    let challengerTimeMs: Int?
    let opponentTimeMs: Int?
    /// Победитель на сервере: "challenger" | "opponent" | "pending"
    let serverWinnerSide: String
    /// true — текущий пользователь является challengером для этой дуэли
    let youAreChallenger: Bool
    
    var isPending: Bool { serverWinnerSide == "pending" }
    var yourScore: Int { youAreChallenger ? challengerScore : opponentScore }
    var otherScore: Int { youAreChallenger ? opponentScore : challengerScore }
    var iWon: Bool {
        guard !isPending else { return false }
        return serverWinnerSide == (youAreChallenger ? "challenger" : "opponent")
    }
    /// Одинаковый счёт и есть оба времени — показываем тай-брейк по времени.
    var showsTieTimeBreakdown: Bool {
        !isPending && challengerScore == opponentScore
            && challengerTimeMs != nil && opponentTimeMs != nil
    }
}

struct DuelHistoryEntry: Identifiable, Codable {
    let id: String
    let opponentName: String
    let myScore: Int
    let opponentScore: Int
    let iWon: Bool
    let playedAt: Date
    /// Идентификатор дуэли с сервера — чтобы не дублировать запись при синхронизации исходящих.
    var duelChallengeId: String?
    /// Моё время и соперника (мс), если известно — при равном счёте победитель по времени.
    var myTimeMs: Int? = nil
    var rivalTimeMs: Int? = nil

    var showsTieTimeBreakdown: Bool {
        myScore == opponentScore && myTimeMs != nil && rivalTimeMs != nil
    }
}

struct GameQuestionResult: Identifiable, Codable {
    let id: String
    let questionNumber: Int
    let flagEmoji: String
    let flagName: String
    /// ISO 3166-1 alpha-2 для локализованного названия в «Детальных результатах».
    let correctCountryCode: String?
    let selectedAnswer: String?
    /// ISO 3166-1 alpha-2 для выбранного ответа (если был).
    let selectedCountryCode: String?
    let isCorrect: Bool
    let timedOut: Bool
    /// Устарело для TC (очки не используются); оставлено для совместимости декодирования.
    let sessionPointsDelta: Int?
    /// XP, отнесённый к этому ответу (база + комбо/скорость за этот ход).
    let xpAwardedThisQuestion: Int?
    /// Изменение таймера: −10 штраф, +10 бонус за серию из 5.
    let timeAdjustmentSeconds: Int?
}

struct CountryLearningProgress: Codable, Hashable {
    var correct: Int
    var wrong: Int

    var total: Int { correct + wrong }
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}

@MainActor
class GameState: ObservableObject {
    @Published var score = 0
    @Published var currentQuestion = 0
    @Published var selectedRegions: Set<Region> = [.all] {
        didSet {
            guard !isLoadingClassicSetupPrefs, oldValue != selectedRegions else { return }
            persistClassicSetupPrefsIfNeeded()
        }
    }
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
    /// Сообщение для алерта: не удалось собрать вопросы дуэли (повтор дуэли и т.п.).
    @Published var duelPrepareErrorMessage: String?
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
            guard !isLoadingClassicSetupPrefs, oldValue != selectedGameMode else { return }
            persistClassicSetupPrefsIfNeeded()
        }
    }
    
    @Published var selectedPlayMode: PlayMode = .classic {
        didSet {
            print("\n=== Play Mode Changed ===")
            print("New mode: \(selectedPlayMode.displayName)")
            print("=====================\n")
            // Режим не персистим как домашний (см. persistClassicSetupPrefsIfNeeded).
        }
    }
    
    @Published var selectedDifficulty: Difficulty = .medium {
        didSet {
            print("\n=== Difficulty Changed ===")
            print("New difficulty: \(selectedDifficulty.displayName)")
            print("Questions per game: \(questionsPerGame)")
            print("=====================\n")
            guard !isLoadingClassicSetupPrefs, oldValue != selectedDifficulty else { return }
            persistClassicSetupPrefsIfNeeded()
        }
    }
    
    /// Режим дуэли: seed для одинаковой игры у обоих игроков
    @Published var duelSeed: Int?
    /// Число вопросов из записи вызова на сервере (у challengera и opponent должно совпадать; иначе пересчёт от сложности может разъехаться).
    @Published var duelServerQuestionsCount: Int?
    /// Серверный снимок дуэли: идентичные вопросы и порядок вариантов для обоих игроков.
    @Published var duelQuestionsPayload: [DuelQuestionPayloadItem]?
    @Published var duelChallengeId: String?
    @Published var duelOpponentId: String?
    @Published var duelOpponentName: String?
    @Published var duelChallengerName: String?
    /// Дуэль с виртуальным соперником (без сервера); результат считается локально.
    @Published var duelIsVirtual: Bool = false
    /// true — текущий пользователь бросил вызов; false — принял входящий вызов (для бейджа «vs …»).
    @Published var duelRoleIsChallenger: Bool = true
    /// UUID вызова для текущей **игровой** сессии; не меняется, если пользователь создал новый вызов в UI до конца партии (иначе submit уходил бы на другой challenge).
    private var duelSessionChallengeId: String?
    /// Результат дуэли для отображения после завершения игры вторым игроком (opponent).
    @Published var pendingDuelResult: DuelResultInfo?
    @Published var duelHistory: [DuelHistoryEntry] = []
    @Published var currentGameResults: [GameQuestionResult] = []
    @Published var lastGameResults: [GameQuestionResult] = []
    @Published private(set) var countryLearningProgress: [String: CountryLearningProgress] = [:]

    /// Загрузка сохранённых регионов/сложности/режима — не триггерить запись в UserDefaults.
    private var isLoadingClassicSetupPrefs = false
    private static let classicSetupPrefsKey = "game.classic.setup.prefs.v1"

    private struct StoredClassicSetup: Codable {
        var playMode: String?
        var difficulty: String
        var gameMode: Int
        var regions: [String]
    }

    private func persistClassicSetupPrefsIfNeeded() {
        guard !isLoadingClassicSetupPrefs else { return }
        // Режим (дуэль/survival) не пишем как «домашний» — иначе Continue открывает пикер вместо квиза.
        // Сохраняем сложность, регионы и лимит флагов — то, что юзер просил переживать между днями.
        let payload = StoredClassicSetup(
            playMode: nil,
            difficulty: selectedDifficulty.rawValue,
            gameMode: selectedGameMode.rawValue,
            regions: selectedRegions.map(\.rawValue).sorted()
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: Self.classicSetupPrefsKey)
    }

    private func loadClassicSetupPreferencesFromStorage() {
        isLoadingClassicSetupPrefs = true
        defer { isLoadingClassicSetupPrefs = false }
        guard let data = UserDefaults.standard.data(forKey: Self.classicSetupPrefsKey),
              let s = try? JSONDecoder().decode(StoredClassicSetup.self, from: data) else { return }
        // playMode из старых снимков игнорируем — домашний старт всегда classic.
        selectedPlayMode = .classic
        if let d = Difficulty(rawValue: s.difficulty) { selectedDifficulty = d }
        if let gm = GameMode(rawValue: s.gameMode) { selectedGameMode = gm }
        let regs = Set(s.regions.compactMap { Region(rawValue: $0) })
        if !regs.isEmpty { selectedRegions = regs }
    }
    
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
        case .timeChallenge:
            // Time Challenge ограничен только таймером, не числом вопросов.
            return Int.max
        case .survival:
            // Бесконечный забег; фактический размер пула задаём при старте/расширении.
            return Int.max
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
    @Published var timeChallengeRemainingTime: TimeInterval = 0
    @Published var timeChallengeBestCombo: Int = 0
    @Published var timeChallengeLastTimeDelta: Int = 0
    /// Жизни только в сессии Time Challenge (не списываем глобальные сердца).
    @Published var timeChallengeSessionLives: Int = 0

    static let timeChallengeSessionLivesStartCount = 5
    /// Сессионные жизни Survival (Premium не даёт бесконечные сердца в этом режиме).
    static let survivalSessionLivesStartCount = 3
    private static let survivalBestDepthKey = "game.survival.bestDepth.v1"
    @Published var survivalSessionLives: Int = 0
    @Published var survivalSessionBestCombo: Int = 0
    @Published var survivalIsNewBestDepth: Bool = false
    @Published var survivalLastRunQuestions: Int = 0
    @Published var survivalLastRunCorrect: Int = 0
    @Published var survivalLastRunMaxStage: Int = 1
    @Published var survivalToastMessage: String?
    /// Личный рекорд глубины (вопросов до конца матча), из UserDefaults.
    @Published var survivalPersonalBestDepth: Int = 0
    /// Еженедельный челлендж Survival: сходинки глубины за ISO-неделю (показываем следующую невыполненную).
    static let survivalWeeklyMilestoneDepths: [Int] = [25, 50, 100, 200]
    /// Первая сходинка (для обратной совместимости логов/старых ссылок).
    static var survivalWeeklyChallengeTargetDepth: Int { survivalWeeklyMilestoneDepths.first ?? 25 }
    /// Бонус XP за каждую новую пройденную сходинку в течение недели (один раз на сходинку).
    static let survivalWeeklyChallengeBonusXP = 1000
    private static let survivalWeeklyPeriodKey = "survival.weekly.isoPeriod.v1"
    private static let survivalWeeklyBestDepthKey = "survival.weekly.bestDepth.v1"
    /// Максимальное значение сходинки (25/50/100/200), за которое уже начислили бонус на этой неделе.
    private static let survivalWeeklyRewardedMaxMilestoneKey = "survival.weekly.rewardedMaxMilestone.v1"
    private static let survivalWeeklyRewardClaimedKey = "survival.weekly.rewardClaimed.v1"
    @Published var survivalWeeklyBestThisWeek: Int = 0
    /// Наибольшая сходинка, за которую уже получен недельный бонус XP (0 = ни одной).
    @Published var survivalWeeklyRewardedMaxMilestone: Int = 0
    @Published var timeChallengeDailyRank: Int? = nil
    @Published var timeChallengeWeeklyRank: Int? = nil
    @Published var timeChallengeIsNewBestScore: Bool = false
    @Published var timeChallengeBestScore: Int = 0

    /// Наступна «сходинка» для тексту на престарті: перша з 25/50/100/200, яку ще не закрито найкращим забігом тижня.
    var survivalWeeklyNextMilestoneToShow: Int? {
        let best = survivalWeeklyBestThisWeek
        for m in Self.survivalWeeklyMilestoneDepths where best < m {
            return m
        }
        return nil
    }

    /// Усі чотири недільні бонуси вже отримані (200 прапорів за тиждень).
    var survivalWeeklyAllBonusesClaimed: Bool {
        guard let cap = Self.survivalWeeklyMilestoneDepths.last else { return false }
        return survivalWeeklyRewardedMaxMilestone >= cap
    }
    
    let gameDuration: TimeInterval = 900 // 15 минут на игру
    
    private var startTime: Date?
    private var timer: Timer?
    /// Сохранённое время при паузе (попап «жизни закончились», реклама). При возобновлении восстанавливаем с этого значения.
    private var savedElapsedTimeWhenPaused: TimeInterval?
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

    /// Индекс вопроса, к которому привязан текущий таймер вопроса. Таймаут обрабатывается только если он для этого вопроса.
    private var questionTimerBoundToQuestionIndex: Int?

    /// Вопрос, для которого запланирован отложенный переход по таймауту. Используется в proceedToNextQuestionAfterTimeout.
    private var timeoutScheduledForQuestionIndex: Int?
    
    // Добавляем новые свойства
    @Published private var usedCountriesInGame: Set<String> = []
    @Published private var totalQuestionsInGame: Int = 20
    
    @Published var isStartingNewGame = false
    @Published var isPreloadingFlags = false
    @Published var flagPreloadProgress = 0.0
    private var preloadTask: Task<Void, Never>?
    
    private var loadedCountriesCache: [Region: [Country]] = [:]
    private let timeChallengeBestScoreKey = "timeChallenge.bestCorrect.v2"
    
    private var gameStartTime: Date?

    /// Если задано, игра стартует только по этим странам (слабые для тренировки). Очищается после начала игры.
    var weakCountryIdsForTraining: Set<String>?
    /// Тренировка одной страны с экрана «Обучение» — не считать сессию в недельном челлендже слабых.
    var suppressNextWeeklyWeakSessionRecord = false

    /// Страны (ISO alpha-3), добавленные с экрана «Страна» для следующей классической игры. Сливаются в weakCountryIdsForTraining при старте.
    @Published private(set) var learningPracticePlaylistAlpha3: Set<String> = []

    // MARK: - Learning: избранное и вручную «сложные» (ISO alpha-2)
    private let learningFavoritesStorageKey = "learning.favorites.iso2.v1"
    private let learningManualDifficultStorageKey = "learning.difficult.manual.iso2.v1"
    private let learningPracticePlaylistStorageKey = "learning.practicePlaylist.alpha3.v1"
    @Published private(set) var learningFavoriteISO2Codes: Set<String> = []
    @Published private(set) var learningManualDifficultISO2Codes: Set<String> = []

    private let weeklyChallengeWeekKey = "learning.weeklyChallenge.weekStart"
    private let weeklyChallengeCountKey = "learning.weeklyChallenge.weakSessionsCount"
    static let weeklyChallengeGoal = 5
    @Published var weeklyChallengeSessionsThisWeek: Int = 0
    
    private var lastGameStartAttempt: Date?
    private let minimumTimeBetweenStarts: TimeInterval = 2.0
    
    // Добавим проверку, чтобы не загружать ошибки повторно
    private var mistakesLoaded = false
    private let duelHistoryStorageKey = "duel.history.v1"
    private let countryLearningProgressStorageKey = "learning.countryProgress.v1"
    
    // Добавляем флаг для отслеживания загрузки статистики
    private var statisticsLoaded = false
    
    // Добавим свойство для отслеживания последнего обработанного ответа
    private var lastProcessedAnswer: (id: String, time: Date)?
    
    /// Игра идёт (таймер можно ставить на паузу при уходе с экрана и возобновлять при возврате).
    private(set) var isGameInProgress = false {
        didSet {
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = isGameInProgress
            #endif
        }
    }
    
    // Добавим новое свойство для хранения временных правильных ответов
    private var correctlyAnsweredMistakes: Set<String> = []
    
    // Добавляем свойство для хранения изначального количества вопросов
    @Published var initialQuestionsCount: Int = 0
    
    // Добавим свойство для отслеживания состояния карточки
    @Published var isCardInteractionEnabled = true
    @Published var comboStreak: Int = 0
    @Published var liveComboText: String? = nil
    @Published var liveBonusText: String? = nil
    @Published var bonusXP: Int = 0
    @Published var lastAppliedXPBoostMultiplier: Int = 1
    @Published var lastGameEarnedFBucks: Int = 0
    /// Нужен чтобы не проигрывать анимацию главной повторно при пересоздании ContentView.
    var hasAnimatedHomeContentOnce = false

    // MARK: - Lives & Premium
    @Published var lives: Int = 5
    @Published var isPremium: Bool = false
    @Published var showMistakesPremiumAlert: Bool = false
    /// Устанавливается в true при таймауте, когда жизни кончились — View показывает попап «Жизни закончились» и сбрасывает флаг.
    @Published var requestOutOfLivesAlert: Bool = false
    /// true, пока показан попап «жизни закончились» — чтобы onAppear не вызывал resumeTimer() и таймер не продолжал идти.
    @Published var isPausedForOutOfLives: Bool = false
    let maxLives: Int = 5
    private let firstDailyRefillInterval: TimeInterval = 300   // 5 минут
    private let secondDailyRefillInterval: TimeInterval = 900  // 15 минут
    private let nextDailyRefillInterval: TimeInterval = 3600   // 60 минут
    private var livesRefillTimer: Timer?
    private let livesStorageKey = "game.lives.current"
    private let lastRefillStorageKey = "game.lives.lastRefillAt"
    private let dailyRefillCountStorageKey = "game.lives.dailyRefillCount"
    private let dailyRefillDayStartStorageKey = "game.lives.dailyRefillDayStart"
    private let premiumStorageKey = "game.premium.enabled"

    private func currentDayStartTimestamp(_ date: Date = Date()) -> TimeInterval {
        Calendar.current.startOfDay(for: date).timeIntervalSince1970
    }

    private func refillIntervalForCurrentDailyStep() -> TimeInterval {
        let count = UserDefaults.standard.integer(forKey: dailyRefillCountStorageKey)
        switch count {
        case 0: return firstDailyRefillInterval
        case 1: return secondDailyRefillInterval
        default: return nextDailyRefillInterval
        }
    }

    private func resetDailyRefillProgressIfNeeded(now: Date = Date()) {
        let defaults = UserDefaults.standard
        let today = currentDayStartTimestamp(now)
        let storedDay = defaults.double(forKey: dailyRefillDayStartStorageKey)
        if storedDay == 0 || storedDay != today {
            defaults.set(today, forKey: dailyRefillDayStartStorageKey)
            defaults.set(0, forKey: dailyRefillCountStorageKey)
            // С новым днём стартуем новый цикл отсчёта интервалов.
            defaults.set(now.timeIntervalSince1970, forKey: lastRefillStorageKey)
        }
    }

    private func loadLivesState() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: livesStorageKey) == nil {
            defaults.set(maxLives, forKey: livesStorageKey)
        }
        lives = defaults.integer(forKey: livesStorageKey)
        
        // НЕ загружаем isPremium из UserDefaults - он будет синхронизирован с StoreManager
        // isPremium = defaults.bool(forKey: premiumStorageKey)

        resetDailyRefillProgressIfNeeded()
        
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
        // Во время активной игры не пополняем жизни автоматически:
        // иначе при ошибке life уменьшается и тут же возвращается до maxLives, что выглядит как баг.
        guard !isGameInProgress else { return }
        let defaults = UserDefaults.standard
        let nowDate = Date()
        resetDailyRefillProgressIfNeeded(now: nowDate)
        let now = nowDate.timeIntervalSince1970
        let last = defaults.double(forKey: lastRefillStorageKey)
        let interval = refillIntervalForCurrentDailyStep()
        if last == 0 {
            defaults.set(now, forKey: lastRefillStorageKey)
            return
        }
        if now - last >= interval, lives < maxLives {
            lives = min(maxLives, lives + maxLives)
            let newDailyCount = defaults.integer(forKey: dailyRefillCountStorageKey) + 1
            defaults.set(newDailyCount, forKey: dailyRefillCountStorageKey)
            defaults.set(now, forKey: lastRefillStorageKey)
            saveLivesState()
            print("❤️ Lives refilled (+\(maxLives)), daily step: \(newDailyCount), lives: \(lives)")
        }
    }

    // Время до следующего автоматического пополнения жизней
    func timeToNextLivesRefill() -> TimeInterval? {
        guard !isPremium else { return nil }
        // Пока идёт игра — авто‑рефил не выполняем и таймер на главной не актуален.
        guard !isGameInProgress else { return nil }
        let defaults = UserDefaults.standard
        let nowDate = Date()
        resetDailyRefillProgressIfNeeded(now: nowDate)
        let last = defaults.double(forKey: lastRefillStorageKey)
        let now = nowDate.timeIntervalSince1970
        let interval = refillIntervalForCurrentDailyStep()
        if last == 0 { return interval }
        let remaining = interval - (now - last)
        return max(0, remaining)
    }

    func consumeLifeOnWrongAnswer() {
        guard !isPremium else { return }
        if lives > 0 {
            lives -= 1
            saveLivesState()
            print("💔 Life consumed. Lives left: \(lives)")
            if lives <= 0 {
                isPausedForOutOfLives = true
                pauseTimer()
            }
        }
    }

    func canStartGameWithLives() -> Bool {
        return isPremium || lives > 0
    }

    /// Полноэкранная игра закрыта (свайп и т.д.), но сессия ещё помечена активной — сбрасываем, иначе на главной ломаются таймеры/жизни и возможен краш при UI.
    func abandonActiveGameIfFullScreenDismissed() {
        guard isGameInProgress else { return }
        stopTimer()
        resetGameState()
    }
    
    /// Перемешивает массив: при дуэли — детерминированно по seed (одинаковый порядок у обоих игроков).
    private func shuffledWithSeed<T>(_ array: [T], seed: Int?, questionIndex: Int = 0) -> [T] {
        guard let s = seed else { return array.shuffled() }
        let combinedSeed = s &+ questionIndex &* 31
        var rng = SeededRNG(seed: combinedSeed)
        return array.shuffled(using: &rng)
    }

    // MARK: - Adaptive country difficulty
    private enum CountryBucket { case easy, medium, hard }

    private func easyCountryCodes() -> Set<String> {
        [
            "USA","CAN","MEX","BRA","ARG","GBR","FRA","DEU","ITA","ESP","PRT","NLD","BEL","CHE","AUT","SWE","NOR","FIN",
            "POL","UKR","RUS","TUR","GRC","JPN","CHN","IND","KOR","THA","VNM","AUS","NZL","ZAF","EGY","MAR","SAU","ARE",
            "ISR","IRL","DNK","CZE","HUN","ROU"
        ]
    }

    private func bucket(for country: Country) -> CountryBucket {
        var score = 60
        if easyCountryCodes().contains(country.id) { score -= 35 }
        if country.population >= 50_000_000 { score -= 12 }
        if country.population <= 5_000_000 { score += 10 }
        if country.name.common.count <= 6 { score -= 8 }
        if country.name.common.count >= 12 { score += 8 }
        if country.region == "Europe" || country.region == "Americas" { score -= 4 }
        if country.region == "Oceania" { score += 4 }
        if score <= 35 { return .easy }
        if score <= 65 { return .medium }
        return .hard
    }

    private func adaptiveMixForCurrentPlayer() -> (easy: Double, medium: Double, hard: Double) {
        var mix: (Double, Double, Double)
        switch selectedDifficulty {
        case .easy: mix = (0.75, 0.20, 0.05)
        case .medium: mix = (0.55, 0.35, 0.10)
        case .hard: mix = (0.30, 0.45, 0.25)
        case .expert: mix = (0.15, 0.35, 0.50)
        case .erudite: mix = (0.10, 0.30, 0.60)
        }

        let profile = UserProfile.shared
        let accuracy = profile.accuracy
        let isNewPlayer = profile.totalGamesPlayed < 3 || profile.totalAnswers < 30

        // На старте даём ощущение успеха: Easy/Medium ~90% простых вопросов.
        if isNewPlayer && (selectedDifficulty == .easy || selectedDifficulty == .medium) {
            return (0.90, 0.09, 0.01)
        }

        if selectedDifficulty == .easy || selectedDifficulty == .medium {
            if accuracy < 85 {
                mix.0 += 0.15; mix.1 -= 0.10; mix.2 -= 0.05
            } else if accuracy > 93 {
                mix.0 -= 0.10; mix.1 += 0.06; mix.2 += 0.04
            }
        }

        let total = max(0.01, mix.0 + mix.1 + mix.2)
        return (mix.0 / total, mix.1 / total, mix.2 / total)
    }

    // MARK: - Survival: прогрессия сложности по «глубине» вопроса
    static func survivalStage(forQuestionOneBased q: Int) -> Int {
        switch max(1, q) {
        case 1...10: return 1
        case 11...20: return 2
        case 21...35: return 3
        case 36...50: return 4
        default: return 5
        }
    }

    private static func survivalStageBucketMix(_ stage: Int) -> (Double, Double, Double) {
        switch stage {
        case 1: return (0.88, 0.10, 0.02)
        case 2: return (0.45, 0.40, 0.15)
        case 3: return (0.20, 0.45, 0.35)
        case 4: return (0.10, 0.30, 0.60)
        default: return (0.05, 0.25, 0.70)
        }
    }

    private func selectCountriesForSession(_ loadedCountries: [Country], count: Int) -> [Country] {
        guard selectedPlayMode != .duel else {
            // Одинаковый порядок пула на обоих устройствах — сортируем по id, затем shuffle по seed.
            let sorted = loadedCountries.sorted { $0.id < $1.id }
            return Array(shuffledWithSeed(sorted, seed: duelSeed).prefix(count))
        }
        let mix = adaptiveMixForCurrentPlayer()
        var easy: [Country] = []
        var medium: [Country] = []
        var hard: [Country] = []
        for c in loadedCountries {
            switch bucket(for: c) {
            case .easy: easy.append(c)
            case .medium: medium.append(c)
            case .hard: hard.append(c)
            }
        }
        easy.shuffle(); medium.shuffle(); hard.shuffle()

        var needEasy = Int(Double(count) * mix.easy)
        var needMedium = Int(Double(count) * mix.medium)
        var needHard = max(0, count - needEasy - needMedium)

        // Если в какой-то корзине мало стран — перераспределяем.
        if easy.count < needEasy { let d = needEasy - easy.count; needEasy = easy.count; needMedium += d / 2; needHard += d - d / 2 }
        if medium.count < needMedium { let d = needMedium - medium.count; needMedium = medium.count; needHard += d }
        if hard.count < needHard { let d = needHard - hard.count; needHard = hard.count; needEasy += d }
        if easy.count < needEasy { needEasy = easy.count }

        var selected: [Country] = []
        selected.append(contentsOf: easy.prefix(needEasy))
        selected.append(contentsOf: medium.prefix(needMedium))
        selected.append(contentsOf: hard.prefix(needHard))

        if selected.count < count {
            let picked = Set(selected.map(\.id))
            let tail = loadedCountries.filter { !picked.contains($0.id) }.shuffled().prefix(count - selected.count)
            selected.append(contentsOf: tail)
        }
        return Array(shuffledWithSeed(selected, seed: nil).prefix(count))
    }

    /// Уникальные страны по id, порядок первых вхождений (нет двух одной страны в вариантах ответа).
    private func uniqueCountriesPreservingOrder(_ countries: [Country]) -> [Country] {
        var seen = Set<String>()
        var out: [Country] = []
        out.reserveCapacity(countries.count)
        for c in countries where !seen.contains(c.id) {
            seen.insert(c.id)
            out.append(c)
        }
        return out
    }

    /// Ровно до `optionsCount` вариантов с уникальными id; `correct` всегда в списке.
    private func shuffledUniqueAnswerOptions(correct: Country, sessionPool: [Country], questionIndex: Int) -> [Country] {
        let uniqueSession = uniqueCountriesPreservingOrder(sessionPool)
        var pool = uniqueSession.filter { $0.id != correct.id }
        if pool.count < optionsCount - 1 {
            var supplement: [Country] = []
            for key in loadedCountriesCache.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
                guard let list = loadedCountriesCache[key] else { continue }
                supplement.append(contentsOf: list)
            }
            let deduped = uniqueCountriesPreservingOrder(supplement).sorted { $0.id < $1.id }
            var used = Set(pool.map(\.id))
            used.insert(correct.id)
            let extra = deduped.filter { !used.contains($0.id) }
            let needed = (optionsCount - 1) - pool.count
            let taken = Array(shuffledWithSeed(extra, seed: duelSeed, questionIndex: questionIndex + 1000).prefix(needed))
            pool.append(contentsOf: taken)
            pool = uniqueCountriesPreservingOrder(pool).filter { $0.id != correct.id }
        }
        var chosen: [Country] = [correct]
        let shuffledOthers = shuffledWithSeed(pool, seed: duelSeed, questionIndex: questionIndex)
        for c in shuffledOthers where chosen.count < optionsCount {
            if !chosen.contains(where: { $0.id == c.id }) {
                chosen.append(c)
            }
        }
        return shuffledWithSeed(chosen, seed: duelSeed, questionIndex: questionIndex)
    }

    /// В дуэли нельзя использовать «Мои ошибки» — у игроков разные персональные списки.
    private func normalizedDuelRegions(_ regions: Set<Region>) -> Set<Region> {
        let cleaned = regions.filter { $0 != .myMistakes }
        return cleaned.isEmpty ? [.all] : cleaned
    }

    /// Регионы инициатора для POST `/duel/challenge` (без «Мои ошибки»; если только он был — All Regions).
    func duelRegionsServerStrings() -> [String] {
        normalizedDuelRegions(selectedRegions).map(\.rawValue).sorted()
    }

    func buildDuelQuestionsPayload(seed: Int, questionsCount: Int, optionsCount: Int) async -> [DuelQuestionPayloadItem]? {
        let regionsToLoad = Array(normalizedDuelRegions(selectedRegions))
        guard let loaded = try? await fetchCountries(for: regionsToLoad), !loaded.isEmpty else { return nil }

        let sorted = loaded.sorted { $0.id < $1.id }
        let sessionPool = Array(shuffledWithSeed(sorted, seed: seed).prefix(min(questionsCount, sorted.count)))
        guard !sessionPool.isEmpty else { return nil }

        var payload: [DuelQuestionPayloadItem] = []
        payload.reserveCapacity(sessionPool.count)

        for (index, correct) in sessionPool.enumerated() {
            var optionPool = sessionPool.filter { $0.id != correct.id }
            if optionPool.count < optionsCount - 1 {
                let extra = sorted.filter { candidate in
                    candidate.id != correct.id && !optionPool.contains(where: { $0.id == candidate.id })
                }
                optionPool.append(contentsOf: extra)
            }
            let shuffledOthers = shuffledWithSeed(optionPool, seed: seed, questionIndex: index)
            let picked = Array(shuffledOthers.prefix(max(1, optionsCount - 1)))
            let finalOptions = shuffledWithSeed([correct] + picked, seed: seed, questionIndex: index)
            payload.append(
                DuelQuestionPayloadItem(
                    correctCountryId: correct.id,
                    optionCountryIds: finalOptions.map(\.id)
                )
            )
        }

        return payload
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

    /// Добавить жизни за просмотр награждаемой рекламы (видео).
    func addLivesFromRewardedAd(amount: Int) {
        guard !isPremium else { return }
        lives = min(maxLives, lives + amount)
        saveLivesState()
        print("❤️ +\(amount) lives from rewarded ad. Lives: \(lives)")
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
        case german = "de"
        case french = "fr"
        case italian = "it"
        case portugueseBrazil = "pt-BR"
        case polish = "pl"
        case dutch = "nl"
        case hindi = "hi"
        case czech = "cs"
        case swedish = "sv"
        case japanese = "ja"
        case arabic = "ar"
        case bengali = "bn"
        case hungarian = "hu"
        case vietnamese = "vi"
        case greek = "el"
        case indonesian = "id"
        case korean = "ko"
        case romanian = "ro"
        case thai = "th"
        case tamil = "ta"
        case telugu = "te"
        case chineseTraditional = "zh-Hant"
        case turkish = "tr"
        case filipino = "fil"
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

        /// Короткий заголовок для сетки режимов на главной (Time Challenge — компактно).
        @MainActor
        var homeDisplayName: String {
            switch self {
            case .timeChallenge:
                return LocalizationManager.shared.localizedString("Time Challenge short")
            default:
                return displayName
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
                return LocalizationManager.shared.localizedString("Survival mode short description")
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
        
        /// SF Symbol для режима (в UI показывается вместо emoji, чтобы не было "?" на части устройств)
        var systemImage: String? {
            switch self {
            case .classic: return "target"
            case .timeChallenge: return "bolt.fill"
            case .survival: return "flame.fill"
            case .duel: return "person.2.fill"
            }
        }

        /// Цвет иконки режима (всегда цветной, не ч/б)
        var iconColor: Color {
            switch self {
            case .classic: return Color.blue
            case .timeChallenge: return Color.orange
            case .survival: return Color.red
            case .duel: return Color.purple
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
            let format = LocalizationManager.shared.localizedString("Level - %@")
            switch self {
            case .easy:
                return String(format: format, LocalizationManager.shared.localizedString("Easy"))
            case .medium:
                return String(format: format, LocalizationManager.shared.localizedString("Medium"))
            case .hard:
                return String(format: format, LocalizationManager.shared.localizedString("Hard"))
            case .expert:
                return String(format: format, LocalizationManager.shared.localizedString("Expert"))
            case .erudite:
                return String(format: format, LocalizationManager.shared.localizedString("Erudite"))
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

        /// Секунды к таймеру за комбо из 5 верных подряд (Time Challenge).
        var timeChallengeCombo5BonusSeconds: Int {
            switch self {
            case .easy: return 10
            case .medium: return 5
            case .hard: return 5
            case .expert: return 3
            case .erudite: return 1
            }
        }

        /// Секунды, снимаемые с таймера за ошибку (Time Challenge).
        var timeChallengeWrongTimerSeconds: Int {
            switch self {
            case .easy: return 5
            case .medium: return 5
            case .hard: return 10
            case .expert: return 10
            case .erudite: return 10
            }
        }

        @MainActor
        func description(for playMode: PlayMode) -> String {
            if playMode == .timeChallenge {
                let dur = Int(timeChallengeDuration)
                let add = timeChallengeCombo5BonusSeconds
                let sub = timeChallengeWrongTimerSeconds
                let unit = LocalizationManager.shared.localizedString("Time seconds unit short")
                return String(
                    format: LocalizationManager.shared.localizedString("Difficulty description TC"),
                    dur,
                    unit,
                    add,
                    sub
                )
            }
            if playMode == .survival {
                let sec = Int(timeLimit)
                return String(
                    format: LocalizationManager.shared.localizedString("Survival difficulty blurb fmt"),
                    sec
                )
            }
            return description
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

        var timeChallengeDuration: TimeInterval {
            switch self {
            case .easy: return 60
            case .medium: return 120
            case .hard: return 180
            case .expert: return 300
            case .erudite: return 500
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

        /// SF Symbol для уровня сложности
        var systemImage: String {
            switch self {
            case .easy: return "leaf.fill"
            case .medium: return "flame"
            case .hard: return "bolt.fill"
            case .expert: return "star.fill"
            case .erudite: return "crown.fill"
            }
        }

        /// Цвет иконки уровня
        var iconColor: Color {
            switch self {
            case .easy: return Color.green
            case .medium: return Color.blue
            case .hard: return Color.orange
            case .expert: return Color.red
            case .erudite: return Color(red: 0.6, green: 0.4, blue: 0.9) // фиолетовый/премиум
            }
        }
    }

    @Published var availableGameModes: [GameMode] = GameMode.allCases
    @Published var availablePlayModes: [PlayMode] = PlayMode.allCases
    @Published var availableDifficulties: [Difficulty] = Difficulty.allCases
    
    init() {
        LocalProgressICloudMirror.restoreFromICloudIntoUserDefaultsIfMissing()
        // Жизни и Premium-статус: загружаем сразу, чтобы на главном экране показывать корректное количество жизней.
        loadLivesState()
        timeChallengeBestScore = UserDefaults.standard.integer(forKey: timeChallengeBestScoreKey)
        // Статистика и ошибки: загружаем один раз при инициализации.
        statistics = StatisticsService.shared.loadStatistics()
        loadMistakes()
        loadDuelHistory()
        loadCountryLearningProgress()
        loadLearningPreferences()
        refreshSurvivalWeeklyChallengeState()
        loadClassicSetupPreferencesFromStorage()
        // Домашний Continue всегда стартует классический квиз; дуэль/survival выбираются явно на главной.
        if selectedPlayMode != .classic && duelSeed == nil {
            selectedPlayMode = .classic
        }
        if selectedDifficulty == .erudite && !StoreManager.shared.isPremium {
            selectedDifficulty = .medium
        }
    }

    /// Синхронизация недельного Survival-челленджа с UserDefaults (смена ISO-недели сбравает прогресс).
    func refreshSurvivalWeeklyChallengeState() {
        let pid = Self.survivalISOWeekPeriodId(for: Date())
        let d = UserDefaults.standard
        if d.string(forKey: Self.survivalWeeklyPeriodKey) != pid {
            d.set(pid, forKey: Self.survivalWeeklyPeriodKey)
            d.set(0, forKey: Self.survivalWeeklyBestDepthKey)
            d.set(0, forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
            d.removeObject(forKey: Self.survivalWeeklyRewardClaimedKey)
        }
        survivalWeeklyBestThisWeek = d.integer(forKey: Self.survivalWeeklyBestDepthKey)
        var rewardedMax = d.integer(forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
        if rewardedMax == 0, d.bool(forKey: Self.survivalWeeklyRewardClaimedKey) {
            rewardedMax = Self.survivalWeeklyMilestoneDepths.first ?? 25
            d.set(rewardedMax, forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
            d.removeObject(forKey: Self.survivalWeeklyRewardClaimedKey)
        }
        survivalWeeklyRewardedMaxMilestone = rewardedMax
    }

    private static func survivalISOWeekPeriodId(for date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone.current
        let y = cal.component(.yearForWeekOfYear, from: date)
        let w = cal.component(.weekOfYear, from: date)
        return "\(y)-W\(w)"
    }

    /// Обновляет недельный лучший результат; начисляет по +`survivalWeeklyChallengeBonusXP` за каждую новую сходинку (25→50→100→200) за неделю.
    private func applySurvivalWeeklyChallengeAfterRun(depth: Int) -> Int {
        let pid = Self.survivalISOWeekPeriodId(for: Date())
        let d = UserDefaults.standard
        if d.string(forKey: Self.survivalWeeklyPeriodKey) != pid {
            d.set(pid, forKey: Self.survivalWeeklyPeriodKey)
            d.set(0, forKey: Self.survivalWeeklyBestDepthKey)
            d.set(0, forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
            d.removeObject(forKey: Self.survivalWeeklyRewardClaimedKey)
        }
        let prevBest = d.integer(forKey: Self.survivalWeeklyBestDepthKey)
        if depth > prevBest {
            d.set(depth, forKey: Self.survivalWeeklyBestDepthKey)
        }
        survivalWeeklyBestThisWeek = max(prevBest, depth)

        var rewardedMax = d.integer(forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
        if rewardedMax == 0, d.bool(forKey: Self.survivalWeeklyRewardClaimedKey) {
            rewardedMax = Self.survivalWeeklyMilestoneDepths.first ?? 25
            d.removeObject(forKey: Self.survivalWeeklyRewardClaimedKey)
        }

        var totalBonus = 0
        var newMaxRewarded = rewardedMax
        for m in Self.survivalWeeklyMilestoneDepths where depth >= m && m > newMaxRewarded {
            newMaxRewarded = m
            totalBonus += Self.survivalWeeklyChallengeBonusXP
            GameAnalyticsService.logEvent("survival_weekly_goal", parameters: [
                "milestone": m,
                "depth": depth
            ])
        }
        if newMaxRewarded != rewardedMax {
            d.set(newMaxRewarded, forKey: Self.survivalWeeklyRewardedMaxMilestoneKey)
        }
        survivalWeeklyRewardedMaxMilestone = newMaxRewarded
        return totalBonus
    }

    private func loadDuelHistory() {
        guard let data = UserDefaults.standard.data(forKey: duelHistoryStorageKey),
              let decoded = try? JSONDecoder().decode([DuelHistoryEntry].self, from: data) else {
            duelHistory = []
            return
        }
        duelHistory = deduplicatedDuelHistory(decoded)
        saveDuelHistory()
    }

    private func saveDuelHistory() {
        guard let data = try? JSONEncoder().encode(duelHistory) else { return }
        UserDefaults.standard.set(data, forKey: duelHistoryStorageKey)
    }

    private func loadCountryLearningProgress() {
        guard let data = UserDefaults.standard.data(forKey: countryLearningProgressStorageKey),
              let decoded = try? JSONDecoder().decode([String: CountryLearningProgress].self, from: data) else {
            countryLearningProgress = [:]
            return
        }
        countryLearningProgress = decoded
    }

    private func saveCountryLearningProgress() {
        guard let data = try? JSONEncoder().encode(countryLearningProgress) else { return }
        UserDefaults.standard.set(data, forKey: countryLearningProgressStorageKey)
        LocalProgressICloudMirror.pushData(data, forKey: LocalProgressICloudMirror.keyCountryProgress)
    }

    private func mirrorWeeklyChallengeToICloud() {
        let d = UserDefaults.standard
        LocalProgressICloudMirror.pushWeekly(
            weekStart: d.double(forKey: weeklyChallengeWeekKey),
            sessionsCount: d.integer(forKey: weeklyChallengeCountKey)
        )
    }

    private func startOfWeek(_ date: Date = Date()) -> TimeInterval {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return date.timeIntervalSince1970
        }
        return start.timeIntervalSince1970
    }

    /// Обновить отображаемый счётчик weekly challenge (вызывать при появлении экрана карты/weak).
    func refreshWeeklyChallengeCount() {
        let now = Date()
        let currentWeek = startOfWeek(now)
        let defaults = UserDefaults.standard
        let storedWeek = defaults.double(forKey: weeklyChallengeWeekKey)
        if storedWeek == 0 || storedWeek != currentWeek {
            defaults.set(currentWeek, forKey: weeklyChallengeWeekKey)
            defaults.set(0, forKey: weeklyChallengeCountKey)
            weeklyChallengeSessionsThisWeek = 0
            mirrorWeeklyChallengeToICloud()
            return
        }
        weeklyChallengeSessionsThisWeek = defaults.integer(forKey: weeklyChallengeCountKey)
    }

    /// Увеличить счётчик сессий «слабые страны» за текущую неделю (вызывать при старте такой игры).
    func recordWeeklyWeakSession() {
        let now = Date()
        let currentWeek = startOfWeek(now)
        let defaults = UserDefaults.standard
        let storedWeek = defaults.double(forKey: weeklyChallengeWeekKey)
        var count = weeklyChallengeSessionsThisWeek
        if storedWeek == 0 || storedWeek != currentWeek {
            defaults.set(currentWeek, forKey: weeklyChallengeWeekKey)
            count = 0
        }
        count += 1
        defaults.set(count, forKey: weeklyChallengeCountKey)
        weeklyChallengeSessionsThisWeek = count
        mirrorWeeklyChallengeToICloud()
    }

    func recordCountryAnswerProgress(countryCode3: String, isCorrect: Bool) {
        let code = countryCode3.uppercased()
        var progress = countryLearningProgress[code] ?? CountryLearningProgress(correct: 0, wrong: 0)
        if isCorrect {
            progress.correct += 1
        } else {
            progress.wrong += 1
        }
        countryLearningProgress[code] = progress
        saveCountryLearningProgress()
    }

    func progressForCountry(code3: String) -> CountryLearningProgress {
        countryLearningProgress[code3.uppercased()] ?? CountryLearningProgress(correct: 0, wrong: 0)
    }

    /// Прогресс обучения по ISO alpha-2 (списки в разделе «Обучение»).
    func learningProgress(forISO2 iso2: String) -> CountryLearningProgress {
        guard let alpha3 = ISO3166.alpha2ToAlpha3[iso2.uppercased()] else {
            return CountryLearningProgress(correct: 0, wrong: 0)
        }
        return progressForCountry(code3: alpha3)
    }

    /// Перезагрузить прогресс по странам из UserDefaults (вызывать при открытии карты прогресса).
    func reloadCountryLearningProgressFromStorage() {
        loadCountryLearningProgress()
        loadLearningPreferences()
    }

    private func loadLearningPreferences() {
        if let data = UserDefaults.standard.data(forKey: learningFavoritesStorageKey),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            learningFavoriteISO2Codes = Set(arr.map { $0.uppercased() })
        } else {
            learningFavoriteISO2Codes = []
        }
        if let data = UserDefaults.standard.data(forKey: learningManualDifficultStorageKey),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            learningManualDifficultISO2Codes = Set(arr.map { $0.uppercased() })
        } else {
            learningManualDifficultISO2Codes = []
        }
        if let data = UserDefaults.standard.data(forKey: learningPracticePlaylistStorageKey),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            learningPracticePlaylistAlpha3 = Set(arr.map { $0.uppercased() })
        } else {
            learningPracticePlaylistAlpha3 = []
        }
    }

    private func saveLearningPracticePlaylist() {
        let arr = Array(learningPracticePlaylistAlpha3).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            UserDefaults.standard.set(data, forKey: learningPracticePlaylistStorageKey)
        }
    }

    /// Добавить страну в очередь следующей игры (классика). Возвращает `true`, если id новый.
    @discardableResult
    func addCountryToLearningPracticePlaylist(alpha3: String) -> Bool {
        let id = alpha3.uppercased()
        guard !id.isEmpty else { return false }
        if learningPracticePlaylistAlpha3.contains(id) { return false }
        learningPracticePlaylistAlpha3.insert(id)
        saveLearningPracticePlaylist()
        return true
    }

    func removeCountryFromLearningPracticePlaylist(alpha3: String) {
        let id = alpha3.uppercased()
        learningPracticePlaylistAlpha3.remove(id)
        saveLearningPracticePlaylist()
    }

    /// Перед стартом игры: объединить очередь с weakCountryIdsForTraining и очистить очередь.
    private func mergeLearningPracticePlaylistIntoWeakTraining() {
        guard !learningPracticePlaylistAlpha3.isEmpty else { return }
        let merged = learningPracticePlaylistAlpha3
        learningPracticePlaylistAlpha3.removeAll()
        saveLearningPracticePlaylist()
        if weakCountryIdsForTraining == nil {
            weakCountryIdsForTraining = merged
        } else {
            weakCountryIdsForTraining = weakCountryIdsForTraining!.union(merged)
        }
    }

    private func saveLearningFavorites() {
        let arr = Array(learningFavoriteISO2Codes).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            UserDefaults.standard.set(data, forKey: learningFavoritesStorageKey)
        }
    }

    private func saveLearningManualDifficult() {
        let arr = Array(learningManualDifficultISO2Codes).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            UserDefaults.standard.set(data, forKey: learningManualDifficultStorageKey)
        }
    }

    func isLearningFavorite(iso2: String) -> Bool {
        learningFavoriteISO2Codes.contains(iso2.uppercased())
    }

    func isLearningManualDifficult(iso2: String) -> Bool {
        learningManualDifficultISO2Codes.contains(iso2.uppercased())
    }

    /// Сложная: статистика «слабая» или ручная отметка.
    func isLearningCountryDifficult(iso2: String) -> Bool {
        let p = learningProgress(forISO2: iso2)
        return LearningCountryProgressLogic.isWeak(p) || isLearningManualDifficult(iso2: iso2)
    }

    func toggleLearningFavorite(iso2: String) {
        let c = iso2.uppercased()
        var next = learningFavoriteISO2Codes
        if next.contains(c) { next.remove(c) } else { next.insert(c) }
        learningFavoriteISO2Codes = next
        saveLearningFavorites()
    }

    func toggleLearningManualDifficult(iso2: String) {
        let c = iso2.uppercased()
        var next = learningManualDifficultISO2Codes
        if next.contains(c) { next.remove(c) } else { next.insert(c) }
        learningManualDifficultISO2Codes = next
        saveLearningManualDifficult()
    }

    private func addDuelHistory(
        opponentName: String,
        myScore: Int,
        opponentScore: Int,
        iWon: Bool,
        duelChallengeId: String? = nil,
        myTimeMs: Int? = nil,
        rivalTimeMs: Int? = nil
    ) {
        if let cid = duelChallengeId, duelHistory.contains(where: { $0.duelChallengeId == cid }) {
            return
        }
        let item = DuelHistoryEntry(
            id: UUID().uuidString,
            opponentName: opponentName,
            myScore: myScore,
            opponentScore: opponentScore,
            iWon: iWon,
            playedAt: Date(),
            duelChallengeId: duelChallengeId,
            myTimeMs: myTimeMs,
            rivalTimeMs: rivalTimeMs
        )
        duelHistory.insert(item, at: 0)
        duelHistory = deduplicatedDuelHistory(duelHistory)
        if duelHistory.count > 50 {
            duelHistory.removeLast(duelHistory.count - 50)
        }
        saveDuelHistory()
    }

    private func deduplicatedDuelHistory(_ input: [DuelHistoryEntry]) -> [DuelHistoryEntry] {
        var out: [DuelHistoryEntry] = []
        var byChallengeId = Set<String>()
        var byComposite = Set<String>()
        let sorted = input.sorted { $0.playedAt > $1.playedAt }

        for item in sorted {
            if let cid = item.duelChallengeId, !cid.isEmpty {
                if byChallengeId.contains(cid) { continue }
                byChallengeId.insert(cid)
                out.append(item)
                continue
            }
            let normalizedOpponent = item.opponentName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let minuteBucket = Int(item.playedAt.timeIntervalSince1970 / 60.0)
            let key = "\(normalizedOpponent)|\(item.myScore)|\(item.opponentScore)|\(item.iWon ? 1 : 0)|\(minuteBucket)"
            if byComposite.contains(key) { continue }
            byComposite.insert(key)
            out.append(item)
        }
        return out
    }

    /// Синхронизация с сервером: завершённая исходящая дуэль (соперник уже отправил счёт).
    func recordDuelFromOutgoingSync(
        opponentName: String,
        myScore: Int,
        opponentScore: Int,
        iWon: Bool,
        duelChallengeId: String,
        challengerTimeMs: Int? = nil,
        opponentTimeMs: Int? = nil
    ) {
        addDuelHistory(
            opponentName: opponentName,
            myScore: myScore,
            opponentScore: opponentScore,
            iWon: iWon,
            duelChallengeId: duelChallengeId,
            myTimeMs: challengerTimeMs,
            rivalTimeMs: opponentTimeMs
        )
    }

    /// Синхронизация с сервером: завершённая входящая дуэль (вы — opponent).
    func recordDuelFromIncomingSync(
        challengerName: String,
        myScore: Int,
        challengerScore: Int,
        iWon: Bool,
        duelChallengeId: String,
        myTimeMs: Int? = nil,
        rivalTimeMs: Int? = nil
    ) {
        addDuelHistory(
            opponentName: challengerName,
            myScore: myScore,
            opponentScore: challengerScore,
            iWon: iWon,
            duelChallengeId: duelChallengeId,
            myTimeMs: myTimeMs,
            rivalTimeMs: rivalTimeMs
        )
    }

    /// Подтянуть с сервера исходящие дуэли (когда соперник уже отправил счёт / завершено) — убирает «Waiting for result».
    func syncOutgoingDuelsWithServer(profile: UserProfile) async {
        let uid = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        guard let rows = try? await DuelAPIService.shared.fetchOutgoingChallenges(userId: uid) else { return }
        await MainActor.run {
            for row in rows {
                let opponentNameForSync: String
                if let idx = profile.outgoingDuelChallenges.firstIndex(where: { $0.id == row.id }) {
                    var local = profile.outgoingDuelChallenges[idx]
                    if let cs = row.challengerScore { local.challengerScore = cs }
                    if let os = row.opponentScore { local.opponentScore = os }
                    local.status = mapDuelServerStatusToLocal(row.status)
                    profile.outgoingDuelChallenges[idx] = local
                    opponentNameForSync = local.opponentName
                } else {
                    opponentNameForSync = row.opponentName
                }

                if row.status == "completed",
                   let w = row.winner, w == "challenger" || w == "opponent",
                   let cs = row.challengerScore, let os = row.opponentScore {
                    let iWon = w == "challenger"
                    recordDuelFromOutgoingSync(
                        opponentName: opponentNameForSync,
                        myScore: cs,
                        opponentScore: os,
                        iWon: iWon,
                        duelChallengeId: row.id,
                        challengerTimeMs: row.challengerTimeMs,
                        opponentTimeMs: row.opponentTimeMs
                    )
                    profile.outgoingDuelChallenges.removeAll { $0.id == row.id }
                }
            }
        }
    }

    /// Синхронизация с сервером: входящие дуэли для оппонента (нужно, чтобы статус ожидания и финальный результат обновлялись).
    func syncIncomingDuelsWithServer(profile: UserProfile) async {
        let uid = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        guard let rows = try? await DuelAPIService.shared.fetchIncomingChallengesForSync(userId: uid) else { return }
        
        await MainActor.run {
            for row in rows {
                if let idx = profile.incomingDuelChallenges.firstIndex(where: { $0.id == row.id }) {
                    var local = profile.incomingDuelChallenges[idx]
                    if let cs = row.challengerScore { local.challengerScore = cs }
                    if let os = row.opponentScore { local.opponentScore = os }
                    local.status = mapDuelServerStatusToLocal(row.status)
                    profile.incomingDuelChallenges[idx] = local
                }

                if row.status == "completed" {
                    guard let winner = row.winner,
                          let cs = row.challengerScore,
                          let os = row.opponentScore else { continue }
                    let iWon = winner == "opponent"
                    recordDuelFromIncomingSync(
                        challengerName: row.challengerName,
                        myScore: os,
                        challengerScore: cs,
                        iWon: iWon,
                        duelChallengeId: row.id,
                        myTimeMs: row.opponentTimeMs,
                        rivalTimeMs: row.challengerTimeMs
                    )
                    profile.incomingDuelChallenges.removeAll { $0.id == row.id }
                }
            }
        }
    }

    private func mapDuelServerStatusToLocal(_ status: String) -> DuelChallenge.Status {
        switch status {
        case "pending", "accepted": return .pending
        case "challenger_completed": return .challengerCompleted
        case "opponent_completed": return .opponentCompleted
        case "completed": return .completed
        default: return .pending
        }
    }

    /// Если по исходящей дуэли вышло время и соперник не сыграл, фиксируем техническую победу.
    @discardableResult
    func assignWinsForExpiredOutgoingDuels(profile: UserProfile, expirySeconds: TimeInterval = 24 * 3600) -> Int {
        let now = Date()
        let expiredNoShow = profile.outgoingDuelChallenges.filter { challenge in
            challenge.status == .challengerCompleted &&
            now.timeIntervalSince(challenge.createdAt) >= expirySeconds
        }
        let expiredPending = profile.outgoingDuelChallenges.filter { challenge in
            challenge.status == .pending &&
            now.timeIntervalSince(challenge.createdAt) >= expirySeconds
        }
        let totalQuestionsFallback = max(1, questionsPerGame)
        let expiredIds = Set((expiredNoShow + expiredPending).map(\.id))
        guard !expiredIds.isEmpty else { return 0 }

        // challengerCompleted: у challenger уже есть реальный счёт
        for challenge in expiredNoShow {
            let myScore = challenge.challengerScore ?? 0
            addDuelHistory(
                opponentName: challenge.opponentName,
                myScore: myScore,
                opponentScore: 0,
                iWon: true,
                duelChallengeId: challenge.id
            )
        }
        
        // pending: оппонент не принял/не пришёл -> challenger считается победителем
        for challenge in expiredPending {
            let totalQuestions = challenge.duelQuestionsCount ?? totalQuestionsFallback
            addDuelHistory(
                opponentName: challenge.opponentName,
                myScore: totalQuestions,
                opponentScore: 0,
                iWon: true,
                duelChallengeId: challenge.id
            )
        }
        
        profile.outgoingDuelChallenges.removeAll { expiredIds.contains($0.id) }
        profile.saveToStorage()
        return expiredIds.count
    }

    /// Если истекло время по входящим дуэлям — определяем победителя локально:
    /// - `pending`: вы не приняли дуэль -> проигрыш, победитель — challenger
    /// - `opponentCompleted`: challenger не сыграл -> победа, проигрыш challenger
    @discardableResult
    func assignWinsForExpiredIncomingDuels(profile: UserProfile, expirySeconds: TimeInterval = 24 * 3600) -> Int {
        let now = Date()
        
        let expiredPending = profile.incomingDuelChallenges.filter { c in
            c.status == .pending && now.timeIntervalSince(c.createdAt) >= expirySeconds
        }
        let expiredOpponentCompleted = profile.incomingDuelChallenges.filter { c in
            c.status == .opponentCompleted && now.timeIntervalSince(c.createdAt) >= expirySeconds
        }
        let expiredChallengerCompleted = profile.incomingDuelChallenges.filter { c in
            c.status == .challengerCompleted && now.timeIntervalSince(c.createdAt) >= expirySeconds
        }

        let totalQuestionsFallback = max(1, questionsPerGame)

        for challenge in expiredPending {
            let totalQuestions = challenge.duelQuestionsCount ?? totalQuestionsFallback
            addDuelHistory(
                opponentName: challenge.challengerName,
                myScore: 0,
                opponentScore: totalQuestions,
                iWon: false,
                duelChallengeId: challenge.id
            )
        }
        
        for challenge in expiredOpponentCompleted {
            let myScore = challenge.opponentScore ?? 0
            addDuelHistory(
                opponentName: challenge.challengerName,
                myScore: myScore,
                opponentScore: 0,
                iWon: true,
                duelChallengeId: challenge.id
            )
        }

        for challenge in expiredChallengerCompleted {
            let opponentPlayedScore = challenge.challengerScore ?? 0
            addDuelHistory(
                opponentName: challenge.challengerName,
                myScore: 0,
                opponentScore: opponentPlayedScore,
                iWon: false,
                duelChallengeId: challenge.id
            )
        }

        let expiredIds = Set(
            expiredPending.map(\.id) + expiredOpponentCompleted.map(\.id) + expiredChallengerCompleted.map(\.id)
        )
        guard !expiredIds.isEmpty else { return 0 }
        
        profile.incomingDuelChallenges.removeAll { expiredIds.contains($0.id) }
        profile.saveToStorage()
        return expiredIds.count
    }

    func recordQuestionResult(
        correctCountry: Country,
        selectedCountry: Country?,
        questionIndex: Int,
        isCorrect: Bool,
        timedOut: Bool = false,
        sessionPointsDelta: Int? = nil,
        xpAwardedThisQuestion: Int? = nil,
        timeAdjustmentSeconds: Int? = nil
    ) {
        let item = GameQuestionResult(
            id: UUID().uuidString,
            questionNumber: questionIndex + 1,
            flagEmoji: correctCountry.flagEmoji,
            flagName: correctCountry.name.common,
            correctCountryCode: correctCountry.countryCode,
            selectedAnswer: selectedCountry?.name.common,
            selectedCountryCode: selectedCountry?.countryCode,
            isCorrect: isCorrect,
            timedOut: timedOut,
            sessionPointsDelta: sessionPointsDelta,
            xpAwardedThisQuestion: xpAwardedThisQuestion,
            timeAdjustmentSeconds: timeAdjustmentSeconds
        )
        currentGameResults.append(item)
    }
    
    // Метод для обновления количества вариантов ответов в зависимости от устройства
    func updateOptionsCount(isIPad: Bool) {
        guard selectedPlayMode != .duel else { return }
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

        if selectedPlayMode == .duel {
            let normalized = normalizedDuelRegions(selectedRegions)
            if normalized != selectedRegions { selectedRegions = normalized }
        }
        
        do {
            // Загружаем страны для выбранных регионов
            let loadedCountries = try await fetchCountries(for: Array(selectedRegions))
            print("Total countries loaded: \(loadedCountries.count)")
            
            // Подбираем страны адаптивно по сложности (в дуэли — по seed одинаково у обоих).
            availableCountries = uniqueCountriesPreservingOrder(
                selectCountriesForSession(loadedCountries, count: totalQuestionsInGame)
            )
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
        
        // Берем следующую страну из server payload (если есть), иначе из локально отобранного списка.
        let nextCountry: Country
        if selectedPlayMode == .duel,
           let payload = duelQuestionsPayload,
           currentQuestion < payload.count,
           let forcedCountry = countryById(payload[currentQuestion].correctCountryId) {
            nextCountry = forcedCountry
        } else {
            nextCountry = availableCountries[currentQuestion]
        }
        print("Next country: \(nextCountry.name.common)")
        
        // Обновляем UI
        withAnimation(.easeInOut(duration: 0.3)) {
            // Устанавливаем новый флаг
            self.currentFlag = nextCountry
            
            var answerOptions = [nextCountry]

            if selectedPlayMode == .duel,
               let payload = duelQuestionsPayload,
               currentQuestion < payload.count {
                let forced = payload[currentQuestion]
                let forcedOptions = forced.optionCountryIds.compactMap { countryById($0) }
                if !forcedOptions.isEmpty {
                    answerOptions = uniqueCountriesPreservingOrder(forcedOptions)
                    if !answerOptions.contains(where: { $0.id == nextCountry.id }) {
                        answerOptions.insert(nextCountry, at: 0)
                    }
                    self.options = answerOptions
                    print("Answer options (server payload): \(self.options.map { $0.name.common })")
                    startQuestionTimerIfNeeded()
                    return
                }
            }
            
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
                
                // В дуэли — только детерминированное перемешивание (ветка «мои ошибки» в дуэли отключена, но на всякий случай).
                if selectedPlayMode == .duel {
                    otherCountries = shuffledWithSeed(
                        otherCountries,
                        seed: duelSeed,
                        questionIndex: currentQuestion + 2000
                    )
                } else {
                    otherCountries.shuffle()
                }
                let additionalOptions = otherCountries
                    .filter { $0.id != nextCountry.id && !mistakeCountries.contains($0) }
                    .prefix(optionsCount - answerOptions.count)
                
                answerOptions.append(contentsOf: additionalOptions)
                answerOptions = uniqueCountriesPreservingOrder(answerOptions)
            } else {
                answerOptions = shuffledUniqueAnswerOptions(
                    correct: nextCountry,
                    sessionPool: availableCountries,
                    questionIndex: currentQuestion
                )
            }
            
            if selectedRegions.contains(.myMistakes) && mistakeCountries.count < optionsCount {
                self.options = shuffledWithSeed(answerOptions, seed: duelSeed, questionIndex: currentQuestion)
            } else {
                self.options = answerOptions
            }
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        startQuestionTimerIfNeeded()
        
        print("=== Question Timer Started ===\n")
    }

    private func startQuestionTimerIfNeeded() {
        if selectedPlayMode != .timeChallenge { startQuestionTimer() } else { stopQuestionTimer() }
    }

    private func countryById(_ id: String) -> Country? {
        if let inSession = availableCountries.first(where: { $0.id == id }) {
            return inSession
        }
        for countries in loadedCountriesCache.values {
            if let cached = countries.first(where: { $0.id == id }) {
                return cached
            }
        }
        return nil
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
            
            let answerOptions = shuffledUniqueAnswerOptions(
                correct: nextCountry,
                sessionPool: availableCountries,
                questionIndex: currentQuestion
            )
            self.options = answerOptions
            
            // Разрешаем взаимодействие с карточкой
            self.isCardInteractionEnabled = true
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        // В Time Challenge используется только общий таймер.
        if selectedPlayMode != .timeChallenge { startQuestionTimer() } else { stopQuestionTimer() }
        
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

        // Сразу останавливаем таймер вопроса и отменяем отложенный переход по таймауту — таймер относится только к текущему вопросу
        stopQuestionTimer()
        transitionTimer?.invalidate()
        transitionTimer = nil

        // Блокируем взаимодействие с карточкой
        isCardInteractionEnabled = false
        isProcessingAnswer = true
        
        print("\n=== Answer Processing ===")
        print("Selected answer: \(country.name.common)")
        print("Correct answer: \(currentFlag.name.common)")
        
        let isCorrect = country.id == currentFlag.id
        recordCountryAnswerProgress(countryCode3: currentFlag.id, isCorrect: isCorrect)
        
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
        isGameOver = true
        print("Current score: \(score)")
        print("Current time: \(formattedTime())")
        print("Previous best time: \(formattedTime(statistics.bestTime))")
        lastGameResults = currentGameResults
        
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
            // Если «Мои ошибки» опустели — снимаем регион и переключаем на «Все регионы», чтобы не остаться без выбора
            if updatedMistakes.isEmpty && selectedRegions.contains(.myMistakes) {
                selectedRegions = [.all]
            }
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
        // Для Time Challenge score — игровые очки; правильные считаем по журналу ответов.
        let answeredQuestionsCount = max(0, currentGameResults.count)
        let correctAnswersThisGame = (selectedPlayMode == .timeChallenge || selectedPlayMode == .survival)
            ? currentGameResults.filter(\.isCorrect).count
            : score
        statistics.correctAnswers += correctAnswersThisGame
        // Для Time Challenge и Survival — только реально сыгранные вопросы.
        let totalQuestionsForStats = (selectedPlayMode == .timeChallenge || selectedPlayMode == .survival)
            ? answeredQuestionsCount
            : initialQuestionsCount
        let survivalWeeklyBonusXP = selectedPlayMode == .survival
            ? applySurvivalWeeklyChallengeAfterRun(depth: answeredQuestionsCount)
            : 0
        statistics.totalAnswers += totalQuestionsForStats
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
        let fBucksBefore = profile.fBucks
        // XP: в классике score = число верных; в TC — очки сессии, XP считаем от числа верных ответов.
        let gainedXP = correctAnswersThisGame * 10 + bonusXP + survivalWeeklyBonusXP
        let effectiveXP = gainedXP * profile.xpBoostMultiplier
        lastAppliedXPBoostMultiplier = profile.xpBoostMultiplier
        let answersThisGame = totalQuestionsForStats
        print("\n=== Updating UserProfile After Game ===")
        print("Gained XP: \(gainedXP)" + (profile.xpBoostMultiplier > 1 ? " x\(profile.xpBoostMultiplier) = \(effectiveXP)" : ""))
        print("Answers this game: \(answersThisGame)")
        profile.totalGamesPlayed += 1
        profile.correctAnswers += correctAnswersThisGame
        profile.totalAnswers += totalQuestionsForStats
        // Правильная логика серии по дням
        profile.updateStreak()
        profile.applyPendingStreakRecoveryAfterGameIfNeeded()
        profile.addXP(effectiveXP)
        profile.evaluateAchievementsAndUnlock()
        // Сообщаем сервису лиг о росте пользователя (с учётом буста XP)
        LeaguesService.shared.userGainedXP(effectiveXP, in: profile.currentLeague)
        // Обновляем месячные цели на основе результатов игры
        let monthlyQuestScore = (selectedPlayMode == .timeChallenge || selectedPlayMode == .survival) ? correctAnswersThisGame : score
        let monthlyQuestQuestions = (selectedPlayMode == .timeChallenge || selectedPlayMode == .survival) ? totalQuestionsForStats : initialQuestionsCount
        profile.updateMonthlyQuestsAfterGame(score: monthlyQuestScore, questions: monthlyQuestQuestions)
        // F-Bucks:
        // 1) Первая игра дня: +1, а если первая игра дня идеальная — +2 (один раз в день).
        // 2) Для остальных идеальных игр сохраняем прежнее правило +1.
        let fbucksModeEligible = selectedPlayMode != .timeChallenge && selectedPlayMode != .duel && !selectedRegions.contains(.myMistakes)
        let isPerfectGame = fbucksModeEligible && score == initialQuestionsCount && initialQuestionsCount > 0
        let awardedFirstGameDailyBonus = fbucksModeEligible
            ? profile.claimFirstGameDailyFBucksBonus(isPerfectGame: isPerfectGame)
            : false
        if isPerfectGame && !awardedFirstGameDailyBonus {
            profile.addFBucks(1, reason: .perfectGame)
        }
        // Режим дуэли: сохраняем результат и при двух результатах определяем победителя
        if selectedPlayMode == .duel {
            if duelIsVirtual {
                handleVirtualDuelFinish(score: score, totalQuestions: initialQuestionsCount, profile: profile)
            } else if let cid = duelSessionChallengeId ?? duelChallengeId {
                let duelMs = Int(min(max(elapsedTime, 0) * 1000, Double(Int32.max)))
                handleDuelFinish(score: score, challengeId: cid, profile: profile, durationMs: duelMs)
            }
        }
        // Сохраняем обновлённый профиль
        profile.saveToStorage()
        // Обновляем ежедневные квесты
        QuestService.shared.updateAfterGame(
            score: score,
            totalQuestions: totalQuestionsForStats,
            correctAnswers: correctAnswersThisGame,
            earnedXP: effectiveXP
        )
        if selectedPlayMode == .survival {
            let depth = answeredQuestionsCount
            let correct = correctAnswersThisGame
            survivalLastRunQuestions = depth
            survivalLastRunCorrect = correct
            var peakStage = 1
            if depth > 0 {
                for i in 1...depth {
                    peakStage = max(peakStage, Self.survivalStage(forQuestionOneBased: i))
                }
            }
            survivalLastRunMaxStage = peakStage
            let prevBest = UserDefaults.standard.integer(forKey: Self.survivalBestDepthKey)
            survivalIsNewBestDepth = depth > prevBest
            if survivalIsNewBestDepth {
                UserDefaults.standard.set(depth, forKey: Self.survivalBestDepthKey)
            }
            survivalPersonalBestDepth = max(prevBest, depth)
            if let msg = survivalToastMessage { print("Survival toast at end: \(msg)") }
        }
        if selectedPlayMode == .timeChallenge {
            let previousBest = timeChallengeBestScore
            timeChallengeIsNewBestScore = score > previousBest
            if timeChallengeIsNewBestScore {
                timeChallengeBestScore = score
                UserDefaults.standard.set(score, forKey: timeChallengeBestScoreKey)
            }
            let userId = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
            if !userId.isEmpty {
                Task {
                    if let result = try? await DuelAPIService.shared.submitTimeChallengeResult(
                        userId: userId,
                        score: score,
                        correctAnswers: correctAnswersThisGame,
                        totalAnswers: totalQuestionsForStats,
                        bestCombo: timeChallengeBestCombo,
                        durationSec: Int(selectedDifficulty.timeChallengeDuration)
                    ) {
                        await MainActor.run {
                            self.timeChallengeDailyRank = result.dailyRank
                            self.timeChallengeWeeklyRank = result.weeklyRank
                        }
                    }
                }
            }
        }
        lastGameEarnedFBucks = max(0, profile.fBucks - fBucksBefore)
        switch selectedPlayMode {
        case .survival:
            GameAnalyticsService.logEvent("survival_session_end", parameters: [
                "depth": survivalLastRunQuestions,
                "correct": survivalLastRunCorrect,
                "max_stage": survivalLastRunMaxStage,
                "new_pb": survivalIsNewBestDepth ? 1 : 0,
                "weekly_bonus": survivalWeeklyBonusXP > 0 ? 1 : 0
            ])
        case .timeChallenge:
            GameAnalyticsService.logEvent("tc_session_end", parameters: [
                "correct": correctAnswersThisGame,
                "answered": answeredQuestionsCount,
                "best_combo": timeChallengeBestCombo,
                "new_pb": timeChallengeIsNewBestScore ? 1 : 0
            ])
        default:
            break
        }
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
        // Не завершать игру, если просто кончились жизни (показ попапа «реклама / Premium»).
        if !isPremium && lives <= 0 && (currentQuestion + 1) < initialQuestionsCount {
            return
        }
        stopTimer()
        finishGameSync()
    }
    
    private static let virtualDuelCountKey = "duel.virtualCount.v1"

    private func handleVirtualDuelFinish(score: Int, totalQuestions: Int, profile: UserProfile) {
        let count = UserDefaults.standard.integer(forKey: Self.virtualDuelCountKey)
        let isThirdGame = (count % 3) == 0 && count > 0
        let userLost = isThirdGame && score < totalQuestions
        let opponentScore: Int
        let winnerSide: String
        if userLost {
            opponentScore = totalQuestions
            winnerSide = "challenger"
        } else {
            opponentScore = max(0, score - Int.random(in: 0...2))
            winnerSide = "opponent"
        }
        let localeCode = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.languageCode ?? "en"
        let nameList = RandomOpponentNames.names(for: localeCode)
        let name = duelOpponentName ?? duelChallengerName ?? nameList[count % nameList.count]
        pendingDuelResult = DuelResultInfo(
            challengerName: name,
            opponentName: profile.username,
            challengerScore: opponentScore,
            opponentScore: score,
            challengerTimeMs: nil,
            opponentTimeMs: nil,
            serverWinnerSide: winnerSide,
            youAreChallenger: false
        )
        addDuelHistory(
            opponentName: name,
            myScore: score,
            opponentScore: opponentScore,
            iWon: winnerSide == "opponent"
        )
        if winnerSide == "opponent" {
            profile.addFBucks(1)
            NotificationService.shared.scheduleDuelWonNotification()
        }
        duelIsVirtual = false
    }

    private func handleDuelFinish(score: Int, challengeId: String, profile: UserProfile, durationMs: Int) {
        let elapsedMs = max(0, durationMs)
        let rivalName = duelOpponentName ?? duelChallengerName ?? LocalizationManager.shared.localizedString("Opponent")

        if duelRoleIsChallenger {
            if let idx = profile.outgoingDuelChallenges.firstIndex(where: { $0.id == challengeId }) {
                var c = profile.outgoingDuelChallenges[idx]
                c.challengerScore = score
                c.status = .challengerCompleted
                profile.outgoingDuelChallenges[idx] = c
            }
            Task {
                guard let result = try? await DuelAPIService.shared.submitScore(
                    challengeId: challengeId,
                    score: score,
                    side: "challenger",
                    elapsedMs: elapsedMs
                ) else { return }
                await MainActor.run {
                    self.finishDuelAfterSubmitChallenger(
                        result: result,
                        challengeId: challengeId,
                        profile: profile,
                        fallbackOpponentName: rivalName,
                        localChallengerScore: score
                    )
                }
            }
            return
        }

        if let snap = profile.incomingDuelChallenges.first(where: { $0.id == challengeId }) {
            let challengerNameVal = snap.challengerName
            Task {
                guard let result = try? await DuelAPIService.shared.submitScore(
                    challengeId: challengeId,
                    score: score,
                    side: "opponent",
                    elapsedMs: elapsedMs
                ) else { return }
                await MainActor.run {
                    let completed = self.finishDuelAfterSubmitOpponent(
                        result: result,
                        challengerName: challengerNameVal,
                        myScore: score,
                        profile: profile,
                        challengeId: challengeId
                    )
                    if completed {
                        profile.incomingDuelChallenges.removeAll { $0.id == challengeId }
                    }
                }
            }
            return
        }

        // Фоллбэк: если локальная коллекция входящих ещё не успела обновиться,
        // но роль = opponent, всё равно отправляем правильную сторону.
        if !duelRoleIsChallenger {
            let challengerNameVal = duelChallengerName ?? LocalizationManager.shared.localizedString("Opponent")
            Task {
                guard let result = try? await DuelAPIService.shared.submitScore(
                    challengeId: challengeId,
                    score: score,
                    side: "opponent",
                    elapsedMs: elapsedMs
                ) else { return }
                await MainActor.run {
                    let completed = self.finishDuelAfterSubmitOpponent(
                        result: result,
                        challengerName: challengerNameVal,
                        myScore: score,
                        profile: profile,
                        challengeId: challengeId
                    )
                    if completed {
                        profile.incomingDuelChallenges.removeAll { $0.id == challengeId }
                    }
                }
            }
        }
    }

    private func finishDuelAfterSubmitChallenger(
        result: DuelSubmitResult,
        challengeId: String,
        profile: UserProfile,
        fallbackOpponentName: String,
        localChallengerScore: Int
    ) {
        if let idx = profile.outgoingDuelChallenges.firstIndex(where: { $0.id == challengeId }) {
            var c = profile.outgoingDuelChallenges[idx]
            if let cs = result.challengerScore { c.challengerScore = cs }
            if let os = result.opponentScore { c.opponentScore = os }
            let st = result.status ?? ""
            if st == "completed" || (c.challengerScore != nil && c.opponentScore != nil) {
                c.status = .completed
            } else {
                c.status = .challengerCompleted
            }
            profile.outgoingDuelChallenges[idx] = c
        }

        let cs = result.challengerScore ?? localChallengerScore

        // Сервер может вернуть winner только когда оба счёта есть (status == completed).
        if let winner = result.winner,
           winner == "challenger" || winner == "opponent",
           let os = result.opponentScore {
            profile.outgoingDuelChallenges.removeAll { $0.id == challengeId }
            let iWon = winner == "challenger"
            if iWon { profile.addFBucks(1) }

            addDuelHistory(
                opponentName: fallbackOpponentName,
                myScore: cs,
                opponentScore: os,
                iWon: iWon,
                duelChallengeId: challengeId,
                myTimeMs: result.challengerTimeMs,
                rivalTimeMs: result.opponentTimeMs
            )

            let challDisplay = profile.username
            pendingDuelResult = DuelResultInfo(
                challengerName: challDisplay,
                opponentName: fallbackOpponentName,
                challengerScore: cs,
                opponentScore: os,
                challengerTimeMs: result.challengerTimeMs,
                opponentTimeMs: result.opponentTimeMs,
                serverWinnerSide: winner,
                youAreChallenger: true
            )
            NotificationService.shared.scheduleDuelResultNotification(
                challengerName: challDisplay,
                challengerScore: cs,
                myScore: cs,
                iWon: iWon
            )
        } else {
            // pending-случай: показываем верхний блок, но без победителя
            let challDisplay = profile.username
            pendingDuelResult = DuelResultInfo(
                challengerName: challDisplay,
                opponentName: fallbackOpponentName,
                challengerScore: cs,
                opponentScore: 0,
                challengerTimeMs: result.challengerTimeMs,
                opponentTimeMs: result.opponentTimeMs,
                serverWinnerSide: "pending",
                youAreChallenger: true
            )
        }
    }

    /// - Returns: true если дуэль завершена на сервере и запись из входящих можно убрать.
    @discardableResult
    private func finishDuelAfterSubmitOpponent(
        result: DuelSubmitResult,
        challengerName: String,
        myScore: Int,
        profile: UserProfile,
        challengeId: String
    ) -> Bool {
        let os = result.opponentScore ?? myScore
        let st = result.status ?? ""

        // Обновляем локальный статус входящей дуэли до того, как сервер даст winner
        if let idx = profile.incomingDuelChallenges.firstIndex(where: { $0.id == challengeId }) {
            var c = profile.incomingDuelChallenges[idx]
            c.opponentScore = os
            c.status = (st == "completed") ? .completed : (st == "opponent_completed" ? .opponentCompleted : c.status)
            profile.incomingDuelChallenges[idx] = c
        }

        // completed-случай
        if let cs = result.challengerScore,
           let winner = result.winner,
           winner == "challenger" || winner == "opponent" {
            let iWon = winner == "opponent"
            if iWon { profile.addFBucks(1) }

            addDuelHistory(
                opponentName: challengerName,
                myScore: os,
                opponentScore: cs,
                iWon: iWon,
                duelChallengeId: challengeId,
                myTimeMs: result.opponentTimeMs,
                rivalTimeMs: result.challengerTimeMs
            )

            pendingDuelResult = DuelResultInfo(
                challengerName: challengerName,
                opponentName: profile.username,
                challengerScore: cs,
                opponentScore: os,
                challengerTimeMs: result.challengerTimeMs,
                opponentTimeMs: result.opponentTimeMs,
                serverWinnerSide: winner,
                youAreChallenger: false
            )
            NotificationService.shared.scheduleDuelResultNotification(
                challengerName: challengerName,
                challengerScore: cs,
                myScore: os,
                iWon: iWon
            )
            return true
        }

        // pending-случай: верхний блок показываем всегда
        pendingDuelResult = DuelResultInfo(
            challengerName: challengerName,
            opponentName: profile.username,
            challengerScore: 0,
            opponentScore: os,
            challengerTimeMs: result.challengerTimeMs,
            opponentTimeMs: result.opponentTimeMs,
            serverWinnerSide: "pending",
            youAreChallenger: false
        )
        return false
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
        
        // Сразу пере-локализуем квесты, чтобы вкладка "Квесты" обновлялась без pull-to-refresh.
        QuestService.shared.refreshQuestLocalization()
        UserProfile.shared.generateMonthlyQuests()
        UserProfile.shared.saveToStorage()
        
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

    /// Применяет параметры дуэли, пришедшие с сервера от инициатора, чтобы у обоих была одинаковая сессия.
    func applyDuelSetupFromServer(_ setup: DuelAPIService.DuelSetup) {
        let parsedRegions = normalizedDuelRegions(Set(setup.regions.compactMap { Region(rawValue: $0) }))
        if !parsedRegions.isEmpty {
            selectedRegions = parsedRegions
        }
        if let difficulty = Difficulty(rawValue: setup.difficulty) {
            selectedDifficulty = difficulty
        }
        if let mode = GameMode(rawValue: setup.gameMode) {
            selectedGameMode = mode
        }
        if setup.optionsCount > 0 {
            optionsCount = setup.optionsCount
        }
        if setup.questionsCount > 0 {
            duelServerQuestionsCount = setup.questionsCount
        }
        if let payload = setup.questionsPayload, !payload.isEmpty {
            duelQuestionsPayload = payload
        }
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
        // Всегда должен быть выбран хотя бы один регион: при пустом выборе — «Все регионы»
        if selectedRegions.isEmpty {
            selectedRegions = [.all]
        }
        // «Мои ошибки» без сохранённых ошибок — иначе старт тихо падает с empty countries.
        if selectedRegions == [.myMistakes] {
            loadMistakes()
            if mistakeCountries.isEmpty {
                selectedRegions = [.all]
            }
        }
        if selectedPlayMode == .duel {
            let normalized = normalizedDuelRegions(selectedRegions)
            if normalized != selectedRegions { selectedRegions = normalized }
        }
        guard !isStartingNewGame else {
            print("\n⚠️ Game start in progress")
            return
        }
        
        guard !isGameInProgress else {
            print("\n⚠️ Game is already in progress")
            // Игра уже запущена, но пользователь может быть на главной (например после рекламы).
            // В этом случае просто возвращаем его на экран игры.
            isNavigatingToGame = true
            return
        }

        guard canStartGameWithLives() else {
            print("\n⚠️ Not enough lives to start the game")
            // Важно: при попытке стартовать дуэль по push/pop-up без жизней должен быть понятный UX.
            // GameView слушает `requestOutOfLivesAlert` и показывает попап "Out of lives".
            if !isPremium {
                requestOutOfLivesAlert = true
            }
            self.error = nil
            return
        }
        
        isStartingNewGame = true
        isPausedForOutOfLives = false
        error = nil
        let duelContext = (
            seed: duelSeed,
            challengeId: duelChallengeId,
            opponentId: duelOpponentId,
            opponentName: duelOpponentName,
            challengerName: duelChallengerName,
            roleIsChallenger: duelRoleIsChallenger,
            serverQuestionsCount: duelServerQuestionsCount,
            questionsPayload: duelQuestionsPayload
        )
        let shouldPreserveDuelContext = selectedPlayMode == .duel && duelContext.seed != nil
        
        print("\n=== Starting New Game ===")
        print("Selected regions: \(selectedRegions.map { $0.rawValue })")
        print("Play mode: \(selectedPlayMode.rawValue), difficulty: \(selectedDifficulty.rawValue)")
        
        // Сбрасываем состояние (в т.ч. isGameInProgress). Флаг активности сессии выставим после успешной подготовки.
        resetGameState(preserveNavigation: false, preserveDuelContext: shouldPreserveDuelContext)
        if shouldPreserveDuelContext {
            duelSeed = duelContext.seed
            duelChallengeId = duelContext.challengeId
            duelOpponentId = duelContext.opponentId
            duelOpponentName = duelContext.opponentName
            duelChallengerName = duelContext.challengerName
            duelRoleIsChallenger = duelContext.roleIsChallenger
            duelServerQuestionsCount = duelContext.serverQuestionsCount
            duelQuestionsPayload = duelContext.questionsPayload
        }
        loadLivesState()
        
        // Загружаем ошибки
        loadMistakes()
        
        print("Final selected regions: \(selectedRegions.map { $0.rawValue })")
        
        // Сохраняем изначальное количество вопросов
        initialQuestionsCount = questionsPerGame
        if selectedPlayMode == .timeChallenge {
            optionsCount = 6
            timeChallengeRemainingTime = selectedDifficulty.timeChallengeDuration
            timeChallengeBestCombo = 0
            timeChallengeLastTimeDelta = 0
            timeChallengeDailyRank = nil
            timeChallengeWeeklyRank = nil
            timeChallengeIsNewBestScore = false
            timeChallengeSessionLives = Self.timeChallengeSessionLivesStartCount
        }
        if selectedPlayMode == .survival {
            optionsCount = 6
            survivalSessionLives = Self.survivalSessionLivesStartCount
            survivalSessionBestCombo = 0
            survivalIsNewBestDepth = false
            survivalToastMessage = nil
            survivalPersonalBestDepth = UserDefaults.standard.integer(forKey: Self.survivalBestDepthKey)
        }
        print("Setting initial questions count to: \(initialQuestionsCount)")
        
        // Очищаем список правильных ответов при начале новой игры
        print("Clearing previously correctly answered mistakes")
        correctlyAnsweredMistakes.removeAll()
        
        do {
            // Для дуэли должен быть идентичный пул стран у обоих игроков (иначе разъедутся вопросы/варианты).
            // Поэтому "weak/training" подмена регионов игнорируется в режиме .duel.
            // Очередь со страницы «Страна» применяется только к классике (не к дуэли / тайм-челленджу / survival).
            if selectedPlayMode == .classic {
                mergeLearningPracticePlaylistIntoWeakTraining()
            }
            let weakIds = (selectedPlayMode == .duel) ? nil : weakCountryIdsForTraining
            weakCountryIdsForTraining = (selectedPlayMode == .duel) ? weakCountryIdsForTraining : nil
            let regionsToLoad: [Region] = weakIds != nil ? [.all] : Array(selectedRegions)
            var loadedCountries = try await fetchCountries(for: regionsToLoad)
            if let ids = weakIds, !ids.isEmpty {
                loadedCountries = loadedCountries.filter { ids.contains($0.id) }
                if !loadedCountries.isEmpty && !suppressNextWeeklyWeakSessionRecord {
                    recordWeeklyWeakSession()
                }
            }
            suppressNextWeeklyWeakSessionRecord = false
            print("Total unique countries loaded: \(loadedCountries.count)")
            
            guard !loadedCountries.isEmpty else {
                print("Error: No countries loaded")
                self.error = GameError.notEnoughCountries(count: 0)
                isStartingNewGame = false
                isGameInProgress = false
                duelSessionChallengeId = nil
                return
            }
            
            // Корректируем количество вопросов в зависимости от доступных стран
            let actualQuestionsCount = min(questionsPerGame, loadedCountries.count)
            initialQuestionsCount = actualQuestionsCount
            print("Adjusted questions count from \(questionsPerGame) to \(actualQuestionsCount) based on available countries")
            
            // Подбираем страны адаптивно по сложности (Survival / Классика — один лимит по региону).
            availableCountries = uniqueCountriesPreservingOrder(
                selectCountriesForSession(loadedCountries, count: actualQuestionsCount)
            )
            if selectedPlayMode == .duel, let payload = duelQuestionsPayload, !payload.isEmpty {
                let byId = Dictionary(uniqueKeysWithValues: loadedCountries.map { ($0.id, $0) })
                let forcedOrder = payload.compactMap { byId[$0.correctCountryId] }
                if !forcedOrder.isEmpty {
                    availableCountries = forcedOrder
                    initialQuestionsCount = forcedOrder.count
                }
            }
            print("\n=== Selected Countries for Game (\(availableCountries.count)) ===")
            for (index, country) in availableCountries.enumerated() {
                print("\(index + 1). \(country.name.common)")
            }
            print("=====================\n")

            guard !availableCountries.isEmpty else {
                self.error = GameError.notEnoughCountries(count: 0)
                isStartingNewGame = false
                isGameInProgress = false
                return
            }
            
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

            guard currentFlag != nil, !options.isEmpty else {
                print("Error: first question not ready (flag/options empty)")
                self.error = GameError.notEnoughCountries(count: availableCountries.count)
                isPreloadingFlags = false
                isStartingNewGame = false
                isGameInProgress = false
                duelSessionChallengeId = nil
                return
            }

            // Мгновенно прогреваем первое изображение флага для комфортного старта
            if let first = currentFlag {
                Task.detached(priority: .userInitiated) {
                    _ = await FlagImageService.shared.loadImageFast(from: first.flagURL)
                }
            }

            // Сессия активна: таймер + экран игры. Важно: после resetGameState флаг был false.
            isGameInProgress = true
            
            // Запускаем таймер
            startTimer()
            
            // Небольшая задержка для показа завершения загрузки
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
            
            // Устанавливаем флаг навигации
            await MainActor.run {
                isNavigatingToGame = true
                switch self.selectedPlayMode {
                case .survival:
                    GameAnalyticsService.logEvent("survival_session_start", parameters: [
                        "difficulty": self.selectedDifficulty.rawValue
                    ])
                case .timeChallenge:
                    GameAnalyticsService.logEvent("tc_session_start", parameters: [
                        "difficulty": self.selectedDifficulty.rawValue,
                        "duration_sec": Int(self.selectedDifficulty.timeChallengeDuration)
                    ])
                default:
                    break
                }
            }
            
        } catch {
            print("Error starting new game: \(error)")
            self.error = error
            isPreloadingFlags = false
            isStartingNewGame = false
            isGameInProgress = false
            duelSessionChallengeId = nil
            return
        }

        if selectedPlayMode == .duel, !duelIsVirtual, let cid = duelChallengeId, !cid.hasPrefix("virtual-") {
            duelSessionChallengeId = cid
        } else if selectedPlayMode != .duel {
            duelSessionChallengeId = nil
        }

        isStartingNewGame = false
        print("\n✅ Game successfully started (navigating=\(isNavigatingToGame), inProgress=\(isGameInProgress))")
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
        resetGameState(preserveNavigation: false, preserveDuelContext: false)
    }

    // Мягкий сброс без изменения флага навигации при перезапуске внутри GameView
    func resetGameState(preserveNavigation: Bool, preserveDuelContext: Bool = false) {
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
        transitionTimer?.invalidate()
        transitionTimer = nil
        questionStartTime = nil
        questionTimeLeft = 0
        questionTimeProgress = 0
        isQuestionTimerActive = false
        comboStreak = 0
        liveComboText = nil
        liveBonusText = nil
        bonusXP = 0
        lastGameEarnedFBucks = 0
        currentGameResults.removeAll()
        startTime = nil
        lastGameStartAttempt = nil
        isGameInProgress = false // Сбрасываем флаг при окончании игры
        if !preserveDuelContext {
            duelSeed = nil
            duelServerQuestionsCount = nil
            duelQuestionsPayload = nil
            duelChallengeId = nil
            duelOpponentId = nil
            duelOpponentName = nil
            duelChallengerName = nil
            duelIsVirtual = false
            duelRoleIsChallenger = true
        }
        pendingDuelResult = nil
        timeChallengeSessionLives = 0
        survivalSessionLives = 0
        survivalSessionBestCombo = 0
        survivalToastMessage = nil
        print("Game state has been reset")
        print("=====================\n")
    }

    // Перезапуск игры без выхода с экрана игры
    func restartGameInPlace() async {
        guard !isStartingNewGame else { return }
        isStartingNewGame = true
        duelPrepareErrorMessage = nil
        var duelContext = (
            seed: duelSeed,
            challengeId: duelChallengeId,
            opponentId: duelOpponentId,
            opponentName: duelOpponentName,
            challengerName: duelChallengerName,
            roleIsChallenger: duelRoleIsChallenger,
            serverQuestionsCount: duelServerQuestionsCount,
            questionsPayload: duelQuestionsPayload
        )
        if selectedPlayMode == .duel, !duelIsVirtual {
            if let rematch = await createDuelRematchContextFromCurrentState() {
                duelContext = rematch
            } else if duelPrepareErrorMessage != nil {
                isStartingNewGame = false
                return
            }
        }
        let shouldPreserveDuelContext = selectedPlayMode == .duel && duelContext.seed != nil
        print("\n=== Restarting Game In Place ===")
        print("Current question before reset: \(currentQuestion)")
        // Сохраняем навигацию и сбрасываем только игровые счетчики
        resetGameState(preserveNavigation: true, preserveDuelContext: shouldPreserveDuelContext)
        if shouldPreserveDuelContext {
            duelSeed = duelContext.seed
            duelChallengeId = duelContext.challengeId
            duelOpponentId = duelContext.opponentId
            duelOpponentName = duelContext.opponentName
            duelChallengerName = duelContext.challengerName
            duelRoleIsChallenger = duelContext.roleIsChallenger
            duelServerQuestionsCount = duelContext.serverQuestionsCount
            duelQuestionsPayload = duelContext.questionsPayload
        }
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
                duelSessionChallengeId = nil
                return
            }
            let actualQuestionsCount = min(questionsPerGame, loadedCountries.count)
            initialQuestionsCount = actualQuestionsCount
            availableCountries = uniqueCountriesPreservingOrder(
                selectCountriesForSession(loadedCountries, count: actualQuestionsCount)
            )
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
            if selectedPlayMode == .timeChallenge {
                timeChallengeSessionLives = Self.timeChallengeSessionLivesStartCount
                timeChallengeRemainingTime = selectedDifficulty.timeChallengeDuration
                timeChallengeBestCombo = 0
                timeChallengeLastTimeDelta = 0
            }
            if selectedPlayMode == .survival {
                survivalSessionLives = Self.survivalSessionLivesStartCount
                survivalSessionBestCombo = 0
                survivalToastMessage = nil
                survivalPersonalBestDepth = UserDefaults.standard.integer(forKey: Self.survivalBestDepthKey)
            }
            print("Current question set to 0, calling selectNextQuestion")
            selectNextQuestion()
            startTimer()
        } catch {
            self.error = error
        }

        // Как в `startNewGameWithCurrentRegions`: иначе `finishGameSync` шлёт submit на старый `duelSessionChallengeId` после рематча.
        if selectedPlayMode == .duel, !duelIsVirtual, let cid = duelChallengeId, !cid.hasPrefix("virtual-") {
            duelSessionChallengeId = cid
        } else if selectedPlayMode != .duel {
            duelSessionChallengeId = nil
        }

        isStartingNewGame = false
        isGameInProgress = true
        isPausedForOutOfLives = false
        print("=== Restart In Place Completed ===\n")
    }

    /// Username оппонента для API дуэли (сервер ищет по username). Раньше в `duelOpponentId` ошибочно попадал UUID друга из карточки профиля.
    private func resolvedDuelOpponentUsernameForAPI() -> String? {
        let raw = (duelOpponentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, raw != "virtual", !raw.hasPrefix("virtual-") else { return nil }
        if let uuid = UUID(uuidString: raw),
           let friend = UserProfile.shared.friends.first(where: { $0.id == uuid }) {
            return friend.username
        }
        return raw
    }

    /// Для кнопки «Повторить дуэль»: создаёт новый challenge и возвращает свежий контекст дуэли.
    private func createDuelRematchContextFromCurrentState() async -> (
        seed: Int?,
        challengeId: String?,
        opponentId: String?,
        opponentName: String?,
        challengerName: String?,
        roleIsChallenger: Bool,
        serverQuestionsCount: Int?,
        questionsPayload: [DuelQuestionPayloadItem]?
    )? {
        let profile = UserProfile.shared
        let myName = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let opponentUsername = resolvedDuelOpponentUsernameForAPI(), !myName.isEmpty else { return nil }

        let seed = Int.random(in: 0..<Int.max)
        let regions = duelRegionsServerStrings()
        let difficulty = selectedDifficulty.rawValue
        let gameMode = selectedGameMode.rawValue
        let questionsCount = duelServerQuestionsCount ?? questionsPerGame
        let options = optionsCount
        let questionsPayload = await buildDuelQuestionsPayload(seed: seed, questionsCount: questionsCount, optionsCount: options)
        guard let questionsPayload, !questionsPayload.isEmpty else {
            await MainActor.run {
                self.duelPrepareErrorMessage = LocalizationManager.shared.localizedString("duel.error.prepare_questions")
            }
            return nil
        }

        var challengeId = UUID().uuidString
        if let serverId = try? await DuelAPIService.shared.createChallenge(
            opponentId: opponentUsername,
            opponentName: opponentUsername,
            seed: seed,
            challengerName: myName,
            challengerId: myName,
            duelSetup: .init(
                regions: regions,
                difficulty: difficulty,
                gameMode: gameMode,
                questionsCount: questionsCount,
                optionsCount: options,
                questionsPayload: questionsPayload
            )
        ) {
            challengeId = serverId
        }

        let challenge = DuelChallenge(
            id: challengeId,
            challengerId: myName,
            challengerName: myName,
            opponentId: opponentUsername,
            opponentName: duelOpponentName ?? opponentUsername,
            seed: seed,
            createdAt: Date(),
            challengerScore: nil,
            opponentScore: nil,
            status: .pending,
            duelRegions: regions,
            duelDifficulty: difficulty,
            duelGameMode: gameMode,
            duelQuestionsCount: questionsCount,
            duelOptionsCount: options,
            duelQuestionsPayload: questionsPayload
        )
        if !profile.outgoingDuelChallenges.contains(where: { $0.id == challengeId }) {
            profile.outgoingDuelChallenges.append(challenge)
        }

        return (
            seed: seed,
            challengeId: challengeId,
            opponentId: opponentUsername,
            opponentName: duelOpponentName ?? opponentUsername,
            challengerName: myName,
            roleIsChallenger: true,
            serverQuestionsCount: questionsCount,
            questionsPayload: questionsPayload
        )
    }
    
    func prepareNextQuestion() {
        currentQuestion += 1
        print("\n=== Preparing Question \(currentQuestion + 1)/\(initialQuestionsCount) ===")

        // Survival всегда конечный: после последнего вопроса завершаем сессию, без цикла по кругу.
        if selectedPlayMode == .survival, initialQuestionsCount > 0, currentQuestion >= initialQuestionsCount {
            print("Survival reached max questions (\(initialQuestionsCount)) - finishing game")
            isGameOver = true
            finishGame()
            return
        }
        
        // Проверяем, есть ли еще вопросы
        if currentQuestion >= availableCountries.count {
            if selectedPlayMode == .timeChallenge, !availableCountries.isEmpty {
                currentQuestion = 0
                previousFlags.removeAll()
                availableCountries.shuffle()
            } else {
                print("No more questions available - finishing game")
                isGameOver = true
                finishGame()
                return
            }
        }
        
        // Получаем следующую страну из предварительно загруженного списка
        let nextCountry = availableCountries[currentQuestion]
        print("Next country: \(nextCountry.name.common)")
        
        // Обновляем текущий флаг и варианты ответов
        withAnimation {
            self.currentFlag = nextCountry
            
            self.options = shuffledUniqueAnswerOptions(
                correct: nextCountry,
                sessionPool: availableCountries,
                questionIndex: currentQuestion
            )
            
            print("Answer options: \(self.options.map { $0.name.common })")
        }
        
        print("=== Question Ready ===")
        
        // В Time Challenge используется только общий таймер.
        if selectedPlayMode != .timeChallenge { startQuestionTimer() } else { stopQuestionTimer() }
        
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
        if selectedPlayMode == .timeChallenge {
            timeChallengeRemainingTime = selectedDifficulty.timeChallengeDuration
            elapsedTime = 0
            timeProgress = 0
        }
        startTime = Date()
        timer?.invalidate()
        runGameTimer()
    }

    /// Приостановить таймер игры (попап «жизни закончились» или уход на рекламу). Сохраняем текущее время для последующего resumeTimer().
    func pauseTimer() {
        let outOfLives = !isPremium && lives <= 0
        guard isGameInProgress || outOfLives else { return }
        if outOfLives { isPausedForOutOfLives = true }
        savedElapsedTimeWhenPaused = elapsedTime
        timer?.invalidate()
        timer = nil
        print("\n=== Game timer PAUSED (saved \(String(format: "%.1f", savedElapsedTimeWhenPaused ?? 0))s) ===\n")
    }

    /// Возобновить таймер после паузы: восстанавливаем время из сохранённого и продолжаем отсчёт.
    func resumeTimer() {
        if !isGameInProgress {
            guard savedElapsedTimeWhenPaused != nil else { return }
            isGameInProgress = true
        }
        if timer != nil { return }
        isPausedForOutOfLives = false
        let toRestore = savedElapsedTimeWhenPaused ?? elapsedTime
        savedElapsedTimeWhenPaused = nil
        elapsedTime = toRestore
        timeProgress = min(toRestore / gameDuration, 1.0)
        startTime = Date().addingTimeInterval(-toRestore)
        runGameTimer()
        print("\n=== Game timer RESUMED from \(String(format: "%.1f", toRestore))s ===\n")
    }

    private func runGameTimer() {
        let sessionDuration: TimeInterval = selectedPlayMode == .timeChallenge
            ? selectedDifficulty.timeChallengeDuration
            : gameDuration
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self,
                      let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
                self.timeProgress = min(self.elapsedTime / sessionDuration, 1.0)
                if self.selectedPlayMode == .timeChallenge {
                    self.timeChallengeRemainingTime = max(0, sessionDuration - self.elapsedTime)
                }
                if self.timeProgress >= 1.0 {
                    self.timer?.invalidate()
                    self.timer = nil
                    self.finishGameSync()
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    // Методы для управления таймером вопросов
    func startQuestionTimer() {
        if selectedPlayMode == .timeChallenge {
            stopQuestionTimer()
            return
        }
        // Таймер привязан только к текущему вопросу; старый таймер всегда сбрасываем
        questionTimer?.invalidate()
        questionTimer = nil
        transitionTimer?.invalidate()
        transitionTimer = nil

        let timeLimit = selectedDifficulty.timeLimit
        questionTimerBoundToQuestionIndex = currentQuestion
        print("\n=== Starting Question Timer ===")
        print("Time limit: \(timeLimit) seconds, question index: \(currentQuestion)")

        questionStartTime = Date()
        questionTimeLeft = timeLimit
        questionTimeProgress = 0
        isQuestionTimerActive = true

        questionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self,
                      self.questionTimerBoundToQuestionIndex == self.currentQuestion,
                      let startTime = self.questionStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                self.questionTimeLeft = max(0, timeLimit - elapsed)
                self.questionTimeProgress = min(elapsed / timeLimit, 1.0)
                if self.questionTimeLeft <= 0 {
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
        questionTimerBoundToQuestionIndex = nil
        // Обнуляем отображаемые значения таймера
        questionTimeLeft = 0
        questionTimeProgress = 1.0
        print("Question timer stopped")
        print("=====================\n")
    }

    /// Отменить отложенный переход к следующему вопросу (по таймауту). Вызывать при ответе пользователя.
    func cancelQuestionTransition() {
        transitionTimer?.invalidate()
        transitionTimer = nil
        timeoutScheduledForQuestionIndex = nil
    }

    private func handleQuestionTimeout() {
        if selectedPlayMode == .timeChallenge { return }
        guard isQuestionTimerActive else { return }
        guard questionTimerBoundToQuestionIndex == currentQuestion else {
            print("⏰ Timeout ignored — already moved to next question")
            return
        }
        print("\n=== Handling Question Timeout ===")
        stopQuestionTimer()
        questionTimerBoundToQuestionIndex = nil
        isCardInteractionEnabled = false
        
        // Засчитываем как неправильный ответ
        updateStatistics(isCorrect: false)
        if let currentFlag = currentFlag {
            recordCountryAnswerProgress(countryCode3: currentFlag.id, isCorrect: false)
        }
        if let currentFlag = currentFlag {
            recordQuestionResult(
                correctCountry: currentFlag,
                selectedCountry: nil,
                questionIndex: currentQuestion,
                isCorrect: false,
                timedOut: true
            )
        }
        
        // Survival: сессионные жизни (и Premium теряет жизнь). Классика: только не-Premium.
        if selectedPlayMode == .survival {
            survivalSessionLives = max(0, survivalSessionLives - 1)
            print("💔 Survival: lost session life due to timeout")
        } else if !isPremium {
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
        
        if selectedPlayMode == .survival, survivalSessionLives <= 0 {
            timeoutScheduledForQuestionIndex = nil
            transitionTimer?.invalidate()
            transitionTimer = nil
            stopTimer()
            finishGame()
            print("\n=== Survival over (timeout on last life) ===\n")
            return
        }
        // Если жизни кончились — не переходим к следующему вопросу: ставим игровой таймер на паузу и показываем попап.
        if !isPremium && lives <= 0 {
            timeoutScheduledForQuestionIndex = nil
            transitionTimer?.invalidate()
            transitionTimer = nil
            isPausedForOutOfLives = true
            pauseTimer()
            requestOutOfLivesAlert = true
            print("\n=== Out of lives (timeout) — game timer paused, showing popup ===\n")
            return
        }
        
        // Переходим к следующему вопросу через небольшую задержку.
        timeoutScheduledForQuestionIndex = currentQuestion
        transitionTimer?.invalidate()
        transitionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.transitionTimer = nil
                self.proceedToNextQuestionAfterTimeout()
            }
        }
        if let t = transitionTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func proceedToNextQuestionAfterTimeout() {
        defer { timeoutScheduledForQuestionIndex = nil }
        guard let scheduledFor = timeoutScheduledForQuestionIndex, currentQuestion == scheduledFor else {
            print("⏰ Proceed after timeout skipped — question index changed (user may have answered)")
            return
        }
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
        // Если жизни кончились, но игра не закончена (попап «реклама / Premium») — не останавливать сессию, только пауза.
        if !isPremium && lives <= 0 && (currentQuestion + 1) < initialQuestionsCount && !isGameOver {
            pauseTimer()
            return
        }
        print("\n=== Stopping Timer ===")
        timer?.invalidate()
        timer = nil
        stopQuestionTimer() // Также останавливаем таймер вопросов
        transitionTimer?.invalidate()
        transitionTimer = nil
        print("Game timer STOPPED (game ended)")
        print("Final time: \(formattedTime())")
        print("=====================\n")
        // Останавливаем любую предзагрузку
        preloadTask?.cancel()
        preloadTask = nil
        // Сессия игры больше не активна
        isGameInProgress = false
    }

    func applyTimeChallengePenalty(seconds: Int = 10) {
        guard selectedPlayMode == .timeChallenge else { return }
        guard startTime != nil else { return }
        let newRemaining = max(0, timeChallengeRemainingTime - Double(seconds))
        timeChallengeRemainingTime = newRemaining
        timeChallengeLastTimeDelta = -seconds
        let consumed = max(0, selectedDifficulty.timeChallengeDuration - newRemaining)
        elapsedTime = consumed
        timeProgress = min(consumed / selectedDifficulty.timeChallengeDuration, 1.0)
        startTime = Date().addingTimeInterval(-consumed)
        if newRemaining <= 0 {
            timer?.invalidate()
            timer = nil
            finishGameSync()
        }
    }

    func applyTimeChallengeBonus(seconds: Int = 10) {
        guard selectedPlayMode == .timeChallenge else { return }
        guard startTime != nil else { return }
        let newRemaining = min(selectedDifficulty.timeChallengeDuration, timeChallengeRemainingTime + Double(seconds))
        timeChallengeRemainingTime = newRemaining
        timeChallengeLastTimeDelta = seconds
        let consumed = max(0, selectedDifficulty.timeChallengeDuration - newRemaining)
        elapsedTime = consumed
        timeProgress = min(consumed / selectedDifficulty.timeChallengeDuration, 1.0)
        startTime = Date().addingTimeInterval(-consumed)
    }

    func clearTimeChallengeDelta() {
        guard selectedPlayMode == .timeChallenge else { return }
        timeChallengeLastTimeDelta = 0
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
    private func enforceLivesAfterPremiumStatusUpdate(oldPremium: Bool, newPremium: Bool) {
        // Даем 5 жизней ОДИН РАЗ при переходе Premium -> non-Premium.
        // Это стартовый "компенсационный" набор, а не автопополнение после каждой ошибки.
        let lostPremiumNow = oldPremium && !newPremium
        guard lostPremiumNow, lives < maxLives else { return }
        lives = maxLives
        saveLivesState()
        print("❤️ Premium ended — restoring lives to \(maxLives)")
    }
    
    func syncPremiumStatus() async {
        await StoreManager.shared.updatePurchasedProducts()
        let oldPremium = self.isPremium
        let storePremium = StoreManager.shared.isPremium
        let newPremium = storePremium && !Self.userDidCancelSubscription
        self.isPremium = newPremium
        enforceLivesAfterPremiumStatusUpdate(oldPremium: oldPremium, newPremium: newPremium)
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
    
    private static let userCancelledSubscriptionKey = "game.user.cancelled.subscription"

    /// Пользователь подтвердил отмену подписки — до следующей покупки считаем его без премиума.
    static var userDidCancelSubscription: Bool {
        get { UserDefaults.standard.bool(forKey: userCancelledSubscriptionKey) }
        set { UserDefaults.standard.set(newValue, forKey: userCancelledSubscriptionKey) }
    }

    private func setupPremiumStatusObserver() async {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let storePremium = StoreManager.shared.isPremium
                let cancelled = Self.userDidCancelSubscription
                let newPremiumStatus = storePremium && !cancelled
                let oldPremium = self.isPremium
                if self.isPremium != newPremiumStatus {
                    self.isPremium = newPremiumStatus
                    print("🔄 Premium status updated: \(self.isPremium)")
                }
                self.enforceLivesAfterPremiumStatusUpdate(oldPremium: oldPremium, newPremium: newPremiumStatus)
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