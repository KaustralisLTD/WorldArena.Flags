import Foundation

// MARK: - F-Bucks Transaction Model
struct FBucksTransaction: Identifiable, Codable {
    let id: String
    let amount: Int
    let reason: FBucksReason
    let date: Date
    
    enum FBucksReason: String, Codable {
        case perfectGame = "perfect_game" // Идеальный результат игры
        case streak10 = "streak_10" // 10 дней подряд
        case streak20 = "streak_20" // 20 дней подряд
        case streak50 = "streak_50" // 50 дней подряд
        case streak100 = "streak_100" // 100 дней подряд
        case purchase = "purchase" // Покупка (отрицательное значение)
        case dailyGift = "daily_gift" // Подарок за ежедневные квесты
        case leagueReward = "league_reward" // Награда за повышение в лиге
        case registrationBonus = "registration_bonus" // Бонус за регистрацию
        case birthday = "birthday" // Поздравление с днём рождения (+10 F-bucks)
        case birthdayGiftFromFriend = "birthday_gift_from_friend" // Подарок от друга на ДР

        nonisolated(unsafe) var localizedDescription: String {
            return MainActor.assumeIsolated {
                let L = LocalizationManager.shared
                switch self {
                case .perfectGame: return L.localizedString("Идеальный результат игры")
                case .streak10: return L.localizedString("Серия 10 дней")
                case .streak20: return L.localizedString("Серия 20 дней")
                case .streak50: return L.localizedString("Серия 50 дней")
                case .streak100: return L.localizedString("Серия 100 дней")
                case .purchase: return L.localizedString("Покупка")
                case .dailyGift: return L.localizedString("Подарок за квесты")
                case .leagueReward: return L.localizedString("Награда за лигу")
                case .registrationBonus: return L.localizedString("Бонус за регистрацию")
                case .birthday: return L.localizedString("День рождения")
                case .birthdayGiftFromFriend: return L.localizedString("Подарок на ДР от друга")
                }
            }
        }
    }
}
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Codable Extension
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)
        
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        #if os(iOS)
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        #else
        let components = NSColor(self).cgColor.components ?? [0, 0, 0, 0]
        #endif
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(components[3])
        
        let hexString = String(format: "%02lX%02lX%02lX%02lX",
                              lroundf(r * 255),
                              lroundf(g * 255),
                              lroundf(b * 255),
                              lroundf(a * 255))
        try container.encode(hexString)
    }
}

// MARK: - User Profile Model
@MainActor
class UserProfile: ObservableObject {
    @Published var username: String = "Player" { didSet { saveIfReady() } }
    @Published var avatar: String = "person.circle.fill" { didSet { saveIfReady() } }
    @Published var customAvatarImageData: Data? = nil { didSet { saveIfReady() } }
    /// Код страны для отображения флага в профиле и у друзей (например "RU", "US")
    @Published var selectedCountryCode: String? = nil { didSet { saveIfReady() } }
    @Published var level: Int = 1 { didSet { saveIfReady() } }
    @Published var xp: Int = 0 { didSet { saveIfReady() } }
    @Published var streak: Int = 0 { didSet { saveIfReady() } }
    @Published var lastGameDate: Date? = nil { didSet { saveIfReady() } }
    @Published var joinDate: Date = Date() { didSet { saveIfReady() } }
    @Published var currentLeague: League = .bronze { didSet { saveIfReady() } }
    @Published var leaguePosition: Int = 1 { didSet { saveIfReady() } }
    @Published var totalGamesPlayed: Int = 0 { didSet { saveIfReady() } }
    @Published var correctAnswers: Int = 0 { didSet { saveIfReady() } }
    /// Общее количество данных ответов (вопросов) за все игры — нужно для корректного расчёта точности
    @Published var totalAnswers: Int = 0 { didSet { saveIfReady() } }
    @Published var bestScore: Int = 0 { didSet { saveIfReady() } }
    @Published var achievements: [Achievement] = []
    @Published var friends: [Friend] = []
    @Published var monthlyQuests: [MonthlyQuest] = []
    @Published var recentMonthlyQuestRewards: [MonthlyQuestCompletionReward] = []
    /// F-Bucks (Flags Bucks) — начисляются за идеальный результат игры (10/10 или 15/15) и за серии дней
    @Published var fBucks: Int = 0 { didSet { saveIfReady() } }
    /// История начислений F-bucks (для страницы статистики)
    @Published var fBucksHistory: [FBucksTransaction] = [] { didSet { saveIfReady() } }
    /// Исходящие вызовы на дуэль (я создал)
    @Published var outgoingDuelChallenges: [DuelChallenge] = [] { didSet { saveDuelChallenges() } }
    /// Входящие вызовы на дуэль (мне бросили; заполняется с push/сервера)
    @Published var incomingDuelChallenges: [DuelChallenge] = [] { didSet { saveDuelChallenges() } }
    /// День рождения (опционально); используется для поздравления +10 F-bucks раз в год
    @Published var birthday: Date? = nil { didSet { saveIfReady() } }
    /// Год, в котором уже начислен бонус за ДР (чтобы не давать повторно при смене даты)
    @Published var birthdayBonusClaimedYear: Int? = nil { didSet { saveIfReady() } }
    /// Флаг «бонус за ДР только что начислен в этом сеансе» — для текста баннера
    @Published var birthdayBonusJustAwarded: Bool = false

    // Computed properties
    /// Точность: доля правильных ответов от всех данных ответов (вопросов)
    var accuracy: Double {
        guard totalAnswers > 0 else { return 0 }
        return min(100, max(0, Double(correctAnswers) / Double(totalAnswers) * 100))
    }
    
    var xpToNextLevel: Int {
        return (level * 1000) - xp
    }
    
    var levelProgress: Double {
        let currentLevelXP = (level - 1) * 1000
        let nextLevelXP = level * 1000
        let progress = Double(xp - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
        return max(0, min(1, progress))
    }
    
    // Singleton instance
    static let shared = UserProfile()
    
    // Хранилище и флаг инициализации
    private let storageKey = "user.profile.v1"
    private let duelChallengesStorageKey = "user.duelChallenges.v1"
    private var isLoadedFromStorage = false
    
    private init() {
        loadFromStorage()
        loadDuelChallenges()
        // Квесты генерируем после загрузки профиля
        generateMonthlyQuests()
        ensureDefaultUsernameIfNeeded()
    }
    
    private struct DuelChallengesPayload: Codable {
        let outgoing: [DuelChallenge]
        let incoming: [DuelChallenge]
    }
    
    private func saveDuelChallenges() {
        let payload = DuelChallengesPayload(outgoing: outgoingDuelChallenges, incoming: incomingDuelChallenges)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: duelChallengesStorageKey)
        }
    }
    
    private func loadDuelChallenges() {
        guard let data = UserDefaults.standard.data(forKey: duelChallengesStorageKey),
              let p = try? JSONDecoder().decode(DuelChallengesPayload.self, from: data) else { return }
        outgoingDuelChallenges = p.outgoing
        incomingDuelChallenges = p.incoming
    }
    
    /// Множитель XP (2 или 3) и время окончания буста — хранятся в UserDefaults
    private static let xpBoostMultiplierKey = "user.xpBoostMultiplier"
    private static let xpBoostEndTimeKey = "user.xpBoostEndTime"

    var isXPBoostActive: Bool {
        let end = UserDefaults.standard.object(forKey: Self.xpBoostEndTimeKey) as? Date
        return end.map { $0 > Date() } ?? false
    }

    var xpBoostMultiplier: Int {
        guard isXPBoostActive else { return 1 }
        let m = UserDefaults.standard.integer(forKey: Self.xpBoostMultiplierKey)
        return (m == 2 || m == 3) ? m : 1
    }

    /// Включить буст XP на заданное время (2x или 3x на 10–15 мин)
    func activateXPBoost(multiplier: Int, durationMinutes: Int) {
        let m = min(3, max(2, multiplier))
        let end = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        UserDefaults.standard.set(m, forKey: Self.xpBoostMultiplierKey)
        UserDefaults.standard.set(end, forKey: Self.xpBoostEndTimeKey)
        objectWillChange.send()
    }

    func addXP(_ points: Int) {
        xp += points
        addXPForDay(points) // Отслеживаем XP по дням для месячных квестов
        checkLevelUp()
        evaluateAchievementsAndUnlock()
    }
    
    /// Начислить F-Bucks с записью в историю (amount может быть отрицательным для покупок)
    func addFBucks(_ amount: Int, reason: FBucksTransaction.FBucksReason) {
        guard amount != 0 else { return }
        fBucks = max(0, fBucks + amount) // Не даём уйти в минус
        let transaction = FBucksTransaction(
            id: UUID().uuidString,
            amount: amount,
            reason: reason,
            date: Date()
        )
        fBucksHistory.append(transaction)
        // Ограничиваем историю последними 100 записями
        if fBucksHistory.count > 100 {
            fBucksHistory.removeFirst(fBucksHistory.count - 100)
        }
    }
    
    /// Начислить F-Bucks (за идеальный результат игры 10/10 или 15/15) — для обратной совместимости
    func addFBucks(_ amount: Int) {
        addFBucks(amount, reason: .perfectGame)
    }
    
    /// Проверяет, совпадает ли сегодня с днём рождения (только месяц и день).
    func isTodayBirthday(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: date) == cal.component(.month, from: Date())
            && cal.component(.day, from: date) == cal.component(.day, from: Date())
    }

    /// Начислить бонус за ДР (+10 F-bucks) не более одного раза в год; при смене даты повторно не начисляем.
    func checkAndAwardBirthdayBonusIfNeeded() {
        guard let bday = birthday else { return }
        let year = Calendar.current.component(.year, from: Date())
        if birthdayBonusClaimedYear == year { return }
        if !isTodayBirthday(bday) { return }
        addFBucks(10, reason: .birthday)
        birthdayBonusClaimedYear = year
        birthdayBonusJustAwarded = true
    }

    /// Друзья, у которых сегодня день рождения (по месяцу и дню).
    var friendsWithBirthdayToday: [Friend] {
        let today = Date()
        let cal = Calendar.current
        let month = cal.component(.month, from: today)
        let day = cal.component(.day, from: today)
        return friends.filter { friend in
            guard let b = friend.birthday else { return false }
            return cal.component(.month, from: b) == month && cal.component(.day, from: b) == day
        }
    }

    /// Проверка и начисление F-bucks за серии дней (10, 20, 50, 100)
    func checkAndAwardStreakFBucks() {
        let milestones: [(days: Int, reward: Int, reason: FBucksTransaction.FBucksReason)] = [
            (10, 1, .streak10),
            (20, 2, .streak20),
            (50, 5, .streak50),
            (100, 10, .streak100)
        ]
        
        for milestone in milestones {
            // Проверяем, была ли уже награда за эту веху в истории
            let alreadyAwarded = fBucksHistory.contains { transaction in
                transaction.reason == milestone.reason
            }
            
            if !alreadyAwarded && streak >= milestone.days {
                addFBucks(milestone.reward, reason: milestone.reason)
            }
        }
    }
    
    // MARK: - Streak Management
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Если это первая игра
        if lastGameDate == nil {
            streak = 1
            lastGameDate = today
            addPlayedDate(today)
            return
        }
        
        let lastGameDay = Calendar.current.startOfDay(for: lastGameDate!)
        
        // Если играем в тот же день - не увеличиваем streak, но отмечаем день как сыгранный
        if Calendar.current.isDate(today, inSameDayAs: lastGameDay) {
            addPlayedDate(today)
            return
        }
        
        // Проверяем, играли ли вчера
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        if Calendar.current.isDate(lastGameDay, inSameDayAs: yesterday) {
            // Играли вчера - увеличиваем streak
            streak += 1
        } else {
            // Не играли вчера - сбрасываем streak
            streak = 1
        }
        
        lastGameDate = today
        addPlayedDate(today)
    }
    
    // MARK: - Game Days Tracking
    @Published var playedDates: Set<String> = []
    @Published var dailyXP: [String: Int] = [:] // Отслеживание XP по дням для месячных квестов
    
    private func addPlayedDate(_ date: Date) {
        let dateString = dateStringFromDate(date)
        playedDates.insert(dateString)
        saveIfReady()
    }
    
    func hasPlayedOnDate(_ date: Date) -> Bool {
        let dateString = dateStringFromDate(date)
        return playedDates.contains(dateString)
    }
    
    var hasPlayedToday: Bool {
        hasPlayedOnDate(Date())
    }
    
    private func dateStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Daily XP Tracking
    func addXPForDay(_ xp: Int, date: Date = Date()) {
        let dateString = dateStringFromDate(date)
        dailyXP[dateString, default: 0] += xp
        saveIfReady()
    }
    
    func getDaysWithXPInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        var daysCount = 0
        var currentDate = startOfMonth
        
        while currentDate <= endOfMonth && currentDate <= now {
            let dateString = dateStringFromDate(currentDate)
            if let xpForDay = dailyXP[dateString], xpForDay > 0 {
                daysCount += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endOfMonth
        }
        
        return daysCount
    }
    
    func getTotalXPInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        var totalXP = 0
        var currentDate = startOfMonth
        
        while currentDate <= endOfMonth && currentDate <= now {
            let dateString = dateStringFromDate(currentDate)
            totalXP += dailyXP[dateString, default: 0]
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endOfMonth
        }
        
        return totalXP
    }
    
    // Проверка завершения месячного XP квеста с требованием минимум 7 дней
    func isMonthlyXPQuestCompleted(_ quest: MonthlyQuest) -> Bool {
        guard quest.questType == .monthlyXP else {
            return quest.currentValue >= quest.targetValue
        }
        
        // Для месячного XP квеста требуется минимум 7 дней активности
        let daysWithXP = getDaysWithXPInCurrentMonth()
        let hasEnoughXP = quest.currentValue >= quest.targetValue
        let hasEnoughDays = daysWithXP >= 7
        
        return hasEnoughXP && hasEnoughDays
    }

    // MARK: - Persistence
    private struct PersistedProfile: Codable {
        let username: String
        let avatar: String
        let customAvatarImageData: Data?
        let selectedCountryCode: String?
        let level: Int
        let xp: Int
        let streak: Int
        let lastGameDate: Date?
        let joinDate: Date
        let currentLeague: String
        let leaguePosition: Int
        let totalGamesPlayed: Int
        let correctAnswers: Int
        let totalAnswers: Int?
        let bestScore: Int
        let friends: [Friend]
        let achievements: [Achievement]
        let playedDates: Set<String>
        let dailyXP: [String: Int]
        let fBucks: Int?
        let fBucksHistory: [FBucksTransaction]?
        let birthday: Date?
        let birthdayBonusClaimedYear: Int?
    }

    private func saveIfReady() {
        guard isLoadedFromStorage else { return }
        saveToStorage()
    }

    @MainActor
    func saveToStorage() {
        let toSave = PersistedProfile(
            username: username,
            avatar: avatar,
            customAvatarImageData: customAvatarImageData,
            selectedCountryCode: selectedCountryCode,
            level: level,
            xp: xp,
            streak: streak,
            lastGameDate: lastGameDate,
            joinDate: joinDate,
            currentLeague: currentLeague.rawValue,
            leaguePosition: leaguePosition,
            totalGamesPlayed: totalGamesPlayed,
            correctAnswers: correctAnswers,
            totalAnswers: totalAnswers,
            bestScore: bestScore,
            friends: friends,
            achievements: achievements,
            playedDates: playedDates,
            dailyXP: dailyXP,
            fBucks: fBucks,
            fBucksHistory: fBucksHistory,
            birthday: birthday,
            birthdayBonusClaimedYear: birthdayBonusClaimedYear
        )
        do {
            let data = try JSONEncoder().encode(toSave)
            _ = KeychainStorage.save(data: data, forKey: storageKey)
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ Failed to save user profile:", error)
        }
    }

    private func loadFromStorage() {
        defer { isLoadedFromStorage = true }
        var data = KeychainStorage.load(forKey: storageKey)
        if data == nil {
            data = UserDefaults.standard.data(forKey: storageKey)
            if let d = data { _ = KeychainStorage.save(data: d, forKey: storageKey) }
        }
        guard let data = data else { return }
        do {
            let obj = try JSONDecoder().decode(PersistedProfile.self, from: data)
            self.username = obj.username
            self.avatar = obj.avatar
            self.customAvatarImageData = obj.customAvatarImageData
            self.selectedCountryCode = obj.selectedCountryCode
            self.level = obj.level
            self.xp = obj.xp
            self.streak = obj.streak
            self.lastGameDate = obj.lastGameDate
            self.joinDate = obj.joinDate
            self.currentLeague = League(rawValue: obj.currentLeague) ?? .bronze
            self.leaguePosition = obj.leaguePosition
            self.totalGamesPlayed = obj.totalGamesPlayed
            self.correctAnswers = obj.correctAnswers
            self.totalAnswers = obj.totalAnswers ?? 0
            self.bestScore = obj.bestScore
            self.friends = obj.friends
            self.achievements = obj.achievements
            self.playedDates = obj.playedDates
            self.dailyXP = obj.dailyXP
            self.fBucks = obj.fBucks ?? 0
            self.fBucksHistory = obj.fBucksHistory ?? []
            self.birthday = obj.birthday
            self.birthdayBonusClaimedYear = obj.birthdayBonusClaimedYear
            ensureNonNegativeCriticalFields()
        } catch {
            print("❌ Failed to load user profile:", error)
            // Попробуем загрузить старую версию без playedDates
            if let legacyProfile = tryLoadLegacyProfile(from: data) {
                applyLegacyProfile(legacyProfile)
            } else {
                UserDefaults.standard.removeObject(forKey: storageKey)
                KeychainStorage.remove(forKey: storageKey)
            }
        }
    }
    
    // MARK: - Legacy Support
    private struct LegacyPersistedProfile: Codable {
        let username: String
        let avatar: String
        let customAvatarImageData: Data?
        let level: Int
        let xp: Int
        let streak: Int
        let lastGameDate: Date?
        let joinDate: Date
        let currentLeague: String
        let leaguePosition: Int
        let totalGamesPlayed: Int
        let correctAnswers: Int
        let bestScore: Int
        let friends: [Friend]
        let achievements: [Achievement]
    }
    
    private func tryLoadLegacyProfile(from data: Data) -> LegacyPersistedProfile? {
        do {
            return try JSONDecoder().decode(LegacyPersistedProfile.self, from: data)
        } catch {
            print("❌ Failed to load legacy profile:", error)
            return nil
        }
    }
    
    private func applyLegacyProfile(_ obj: LegacyPersistedProfile) {
        self.username = obj.username
        self.avatar = obj.avatar
        self.customAvatarImageData = obj.customAvatarImageData
        self.level = obj.level
        self.xp = obj.xp
        self.streak = obj.streak
        self.lastGameDate = obj.lastGameDate
        self.joinDate = obj.joinDate
        self.currentLeague = League(rawValue: obj.currentLeague) ?? .bronze
        self.leaguePosition = obj.leaguePosition
        self.totalGamesPlayed = obj.totalGamesPlayed
        self.correctAnswers = obj.correctAnswers
        self.totalAnswers = 0 // в старых сохранениях не было — точность будет пересчитана после следующих игр
        self.bestScore = obj.bestScore
        self.friends = obj.friends
        self.achievements = obj.achievements
        self.playedDates = [] // Пустой набор для старых профилей
        self.dailyXP = [:] // Пустой словарь для старых профилей
        self.selectedCountryCode = nil
        
        // Если у пользователя есть lastGameDate, добавим этот день как сыгранный
        if let lastDate = obj.lastGameDate {
            addPlayedDate(lastDate)
        }
        self.fBucks = 0 // в старых сохранениях не было
        ensureNonNegativeCriticalFields()
    }

    /// Проверка и исправление критичных полей (статистика, streak, XP, F-bucks) — не допускаем отрицательных значений
    private func ensureNonNegativeCriticalFields() {
        var changed = false
        if fBucks < 0 { fBucks = 0; changed = true }
        if streak < 0 { streak = 0; changed = true }
        if xp < 0 { xp = 0; changed = true }
        if level < 1 { level = 1; changed = true }
        if correctAnswers < 0 { correctAnswers = 0; changed = true }
        if totalAnswers < 0 { totalAnswers = 0; changed = true }
        if bestScore < 0 { bestScore = 0; changed = true }
        if totalGamesPlayed < 0 { totalGamesPlayed = 0; changed = true }
        if leaguePosition < 1 { leaguePosition = 1; changed = true }
        if changed {
            saveToStorage()
        }
    }

    // Генерация уникального имени по умолчанию при первом запуске (вместо одинакового Player)
    private func ensureDefaultUsernameIfNeeded() {
        let hasSavedProfile = KeychainStorage.load(forKey: storageKey) != nil
            || UserDefaults.standard.data(forKey: storageKey) != nil
        if !hasSavedProfile {
            if username.isEmpty || username == "Player" {
                username = generateDefaultUsername()
                saveToStorage()
            }
        }
    }

    private func generateDefaultUsername() -> String {
        let adjectives = [
            "Swift", "Brave", "Smart", "Lucky", "Rapid", "Calm", "Mighty", "Nimble", "Bright", "Epic"
        ]
        let animals = [
            "Lion", "Falcon", "Wolf", "Panda", "Tiger", "Eagle", "Bear", "Fox", "Dolphin", "Koala"
        ]
        let adj = adjectives.randomElement() ?? "Swift"
        let animal = animals.randomElement() ?? "Fox"
        let number = Int.random(in: 100...999)
        return "\(adj)\(animal)-\(number)"
    }
    
    // MARK: - Monthly quests live update after game
    private static let monthlyQuestRewardedMonthKey = "monthly.quest.rewarded.month"
    private static let monthlyQuestRewardedIndicesKey = "monthly.quest.rewarded.indices"

    private func currentMonthToken() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    private func loadRewardedMonthlyQuestIndices() -> Set<Int> {
        let token = currentMonthToken()
        let savedToken = UserDefaults.standard.string(forKey: Self.monthlyQuestRewardedMonthKey)
        if savedToken != token {
            UserDefaults.standard.set(token, forKey: Self.monthlyQuestRewardedMonthKey)
            UserDefaults.standard.set([], forKey: Self.monthlyQuestRewardedIndicesKey)
            return []
        }
        let raw = UserDefaults.standard.array(forKey: Self.monthlyQuestRewardedIndicesKey) as? [Int] ?? []
        return Set(raw)
    }

    private func saveRewardedMonthlyQuestIndices(_ indices: Set<Int>) {
        UserDefaults.standard.set(Array(indices), forKey: Self.monthlyQuestRewardedIndicesKey)
        UserDefaults.standard.set(currentMonthToken(), forKey: Self.monthlyQuestRewardedMonthKey)
    }

    func consumeRecentMonthlyQuestRewards() -> [MonthlyQuestCompletionReward] {
        let rewards = recentMonthlyQuestRewards
        recentMonthlyQuestRewards.removeAll()
        return rewards
    }

    private func applyMonthlyQuestCompletionReward(for quest: MonthlyQuest) -> MonthlyQuestCompletionReward {
        // Награды за месячные квесты не зависят от активного XP-бустера.
        let rewardXP = max(quest.xpReward, 0)
        var rewardFBucks = 0
        if rewardXP > 0 {
            addXP(rewardXP)
        }
        // Дополнительная мотивация за более сложные квесты.
        switch quest.questType {
        case .monthlyXP, .perfectGames:
            addFBucks(1, reason: .dailyGift)
            rewardFBucks = 1
        default:
            break
        }
        return MonthlyQuestCompletionReward(
            questTitle: quest.title,
            questIcon: quest.icon,
            xp: rewardXP,
            fBucks: rewardFBucks
        )
    }

    @MainActor
    func updateMonthlyQuestsAfterGame(score: Int, questions: Int) {
        // Update best score if current score is higher
        if score > bestScore {
            bestScore = score
        }
        
        guard !monthlyQuests.isEmpty else { return }
        var hasChanges = false
        var rewardedIndices = loadRewardedMonthlyQuestIndices()
        var rewardsChanged = false
        for index in monthlyQuests.indices {
            let wasCompleted = monthlyQuests[index].isCompleted
            switch monthlyQuests[index].questType {
            case .gamesPlayed:
                let newValue = min(monthlyQuests[index].targetValue, monthlyQuests[index].currentValue + 1)
                if newValue != monthlyQuests[index].currentValue {
                    monthlyQuests[index].currentValue = newValue
                    hasChanges = true
                }
            case .accuracy:
                let accNow = Int(accuracy)
                let newValue = min(monthlyQuests[index].targetValue, accNow)
                if newValue != monthlyQuests[index].currentValue {
                    monthlyQuests[index].currentValue = newValue
                    hasChanges = true
                }
            case .streak:
                let newValue = min(monthlyQuests[index].targetValue, streak)
                if newValue != monthlyQuests[index].currentValue {
                    monthlyQuests[index].currentValue = newValue
                    hasChanges = true
                }
            case .correctAnswers:
                let newValue = min(monthlyQuests[index].targetValue, monthlyQuests[index].currentValue + score)
                if newValue != monthlyQuests[index].currentValue {
                    monthlyQuests[index].currentValue = newValue
                    hasChanges = true
                }
            case .perfectGames:
                let isPerfect = (questions > 0 && score == questions)
                if isPerfect {
                    let newValue = min(monthlyQuests[index].targetValue, monthlyQuests[index].currentValue + 1)
                    if newValue != monthlyQuests[index].currentValue {
                        monthlyQuests[index].currentValue = newValue
                        hasChanges = true
                    }
                }
            case .monthlyXP:
                // Обновляем текущий месячный XP квест
                let currentMonthlyXP = getTotalXPInCurrentMonth()
                let newValue = min(monthlyQuests[index].targetValue, currentMonthlyXP)
                if newValue != monthlyQuests[index].currentValue {
                    monthlyQuests[index].currentValue = newValue
                    hasChanges = true
                }
            }
            let becameCompleted = !wasCompleted && monthlyQuests[index].isCompleted
            if becameCompleted && !rewardedIndices.contains(index) {
                let reward = applyMonthlyQuestCompletionReward(for: monthlyQuests[index])
                if reward.xp > 0 || reward.fBucks > 0 {
                    recentMonthlyQuestRewards.append(reward)
                }
                rewardedIndices.insert(index)
                rewardsChanged = true
            }
        }
        if rewardsChanged {
            saveRewardedMonthlyQuestIndices(rewardedIndices)
        }
        if hasChanges { saveToStorage() }
    }

    private func checkLevelUp() {
        let newLevel = (xp / 1000) + 1
        if newLevel > level {
            level = newLevel
            // Unlock new achievements, etc.
        }
    }
    
    @MainActor
    func generateMonthlyQuests() {
        
        // Clear existing quests
        monthlyQuests.removeAll()
        
        // Generate quests based on user level and stats
        let baseGamesTarget = max(16, level * 6)
        let baseAccuracyTarget = min(97, 68 + level * 2)
        let streakTarget = max(5, level + 2)
        let correctAnswersTarget = max(140, level * 70)
        let perfectGamesTarget = max(3, min(14, level / 2 + 2))
        let monthlyXPTarget = max(3500, level * 700) // Большая награда XP требует минимум 7 дней активности
        
        let L = LocalizationManager.shared
        monthlyQuests = [
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Сыграй %d игр"), baseGamesTarget),
                description: String(format: L.localizedString("Завершите %d игр в этом месяце"), baseGamesTarget),
                targetValue: baseGamesTarget,
                currentValue: min(baseGamesTarget, totalGamesPlayed),
                questType: .gamesPlayed,
                xpReward: baseGamesTarget * 10,
                icon: "gamecontroller.fill",
                color: .blue
            ),
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Точность %d%%"), baseAccuracyTarget),
                description: String(format: L.localizedString("Достигните точности %d%% в играх"), baseAccuracyTarget),
                targetValue: baseAccuracyTarget,
                currentValue: Int(accuracy),
                questType: .accuracy,
                xpReward: 500,
                icon: "target",
                color: .green
            ),
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Серия %d дней"), streakTarget),
                description: String(format: L.localizedString("Поддерживайте серию %d дней подряд"), streakTarget),
                targetValue: streakTarget,
                currentValue: streak,
                questType: .streak,
                xpReward: streakTarget * 50,
                icon: "flame.fill",
                color: .orange
            ),
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Дай %d правильных ответов"), correctAnswersTarget),
                description: String(format: L.localizedString("Наберите %d правильных ответов за месяц"), correctAnswersTarget),
                targetValue: correctAnswersTarget,
                currentValue: min(correctAnswersTarget, correctAnswers),
                questType: .correctAnswers,
                xpReward: correctAnswersTarget * 3,
                icon: "checkmark.seal.fill",
                color: .mint
            ),
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Сыграй %d идеальных игр"), perfectGamesTarget),
                description: String(format: L.localizedString("Завершите %d игр без ошибок"), perfectGamesTarget),
                targetValue: perfectGamesTarget,
                currentValue: 0,
                questType: .perfectGames,
                xpReward: perfectGamesTarget * 180,
                icon: "crown.fill",
                color: .yellow
            ),
            MonthlyQuest(
                id: UUID(),
                title: String(format: L.localizedString("Заработай %d XP за месяц"), monthlyXPTarget),
                description: String(format: L.localizedString("Заработайте %d XP играя минимум 7 дней в месяц"), monthlyXPTarget),
                targetValue: monthlyXPTarget,
                currentValue: getTotalXPInCurrentMonth(),
                questType: .monthlyXP,
                xpReward: monthlyXPTarget / 2, // Большая награда за месячную активность
                icon: "star.circle.fill",
                color: .purple
            )
        ]
    }
}

// MARK: - League System
enum League: String, CaseIterable {
    case bronze = "Бронза"
    case silver = "Серебро" 
    case gold = "Золото"
    case platinum = "Платина"
    case diamond = "Алмаз"
    case master = "Мастер"
    
    @MainActor var localizedName: String {
        LocalizationManager.shared.localizedString(self.rawValue)
    }
    
    @MainActor var localizedFullName: String {
        switch self {
        case .bronze:
            return LocalizationManager.shared.localizedString("Бронзовая лига")
        case .silver:
            return LocalizationManager.shared.localizedString("Серебряная лига")
        case .gold:
            return LocalizationManager.shared.localizedString("Золотая лига")
        case .platinum:
            return LocalizationManager.shared.localizedString("Лига Мастеров")
        case .diamond:
            return LocalizationManager.shared.localizedString("Лига Мастеров")
        case .master:
            return LocalizationManager.shared.localizedString("Лига Чемпионов Мира")
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .blue
        case .diamond: return .cyan
        case .master: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        case .master: return "star.fill"
        }
    }

    /// Имя изображения в Assets для миниатюры лиги (цветная — когда достигнута)
    var imageAssetName: String {
        switch self {
        case .bronze: return "LeagueBronze"
        case .silver: return "LeagueSilver"
        case .gold: return "LeagueGold"
        case .platinum: return "LeaguePlatinum"
        case .diamond: return "LeagueDiamond"
        case .master: return "LeagueMaster"
        }
    }

    /// Лига достигнута пользователем (текущая лига >= этой)
    func isReached(by current: League) -> Bool {
        let all = League.allCases
        guard let myIndex = all.firstIndex(of: self),
              let currentIndex = all.firstIndex(of: current) else { return false }
        return currentIndex >= myIndex
    }

    var xpRequirement: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1000
        case .gold: return 3000
        case .platinum: return 6000
        case .diamond: return 10000
        case .master: return 15000
        }
    }

    /// Лига выше (для повышения); nil если уже мастер.
    var leagueAbove: League? {
        let all = League.allCases
        guard let i = all.firstIndex(of: self), i < all.count - 1 else { return nil }
        return all[i + 1]
    }

    /// Лига ниже (для понижения); nil если уже бронза.
    var leagueBelow: League? {
        let all = League.allCases
        guard let i = all.firstIndex(of: self), i > 0 else { return nil }
        return all[i - 1]
    }
}

// MARK: - Monthly Quest
struct MonthlyQuest: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let questType: QuestType
    let xpReward: Int
    let icon: String
    let color: Color
    
    var progress: Double {
        return min(1.0, Double(currentValue) / Double(targetValue))
    }
    
    var isCompleted: Bool {
        return currentValue >= targetValue
    }
}

struct MonthlyQuestCompletionReward: Identifiable, Equatable {
    let id: UUID = UUID()
    let questTitle: String
    let questIcon: String
    let xp: Int
    let fBucks: Int
}

enum QuestType {
    case gamesPlayed
    case accuracy
    case streak
    case correctAnswers
    case perfectGames
    case monthlyXP
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: UUID
    /// Идентификатор из AchievementDefinition (например "xp_5000") для проверки разблокировки.
    let definitionId: String?
    let title: String
    let description: String
    let icon: String
    let color: Color
    let unlockedDate: Date
    let rarity: AchievementRarity

    init(id: UUID, definitionId: String? = nil, title: String, description: String, icon: String, color: Color, unlockedDate: Date, rarity: AchievementRarity) {
        self.id = id
        self.definitionId = definitionId
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.unlockedDate = unlockedDate
        self.rarity = rarity
    }

    enum CodingKeys: String, CodingKey {
        case id, definitionId, title, description, icon, color, unlockedDate, rarity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        definitionId = try c.decodeIfPresent(String.self, forKey: .definitionId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        icon = try c.decode(String.self, forKey: .icon)
        color = try c.decode(Color.self, forKey: .color)
        unlockedDate = try c.decode(Date.self, forKey: .unlockedDate)
        rarity = try c.decode(AchievementRarity.self, forKey: .rarity)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(definitionId, forKey: .definitionId)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(icon, forKey: .icon)
        try c.encode(color, forKey: .color)
        try c.encode(unlockedDate, forKey: .unlockedDate)
        try c.encode(rarity, forKey: .rarity)
    }
}

enum AchievementRarity: Codable {
    case common, rare, epic, legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Friend
struct Friend: Identifiable, Codable {
    let id: UUID
    let username: String
    /// Имя для отображения (с сервера); у друзей обновляется при смене имени пользователем.
    var displayName: String?
    let avatar: String
    var countryCode: String?
    let level: Int
    let xp: Int
    let streak: Int
    let isOnline: Bool
    let joinDate: Date
    /// true если друг уже играл сегодня (показываем огонёк и дни, иначе кнопку «Напомнить»).
    var playedToday: Bool
    /// День рождения (опционально; с сервера или локально) — для уведомления «Поздравьте друга».
    var birthday: Date?

    /// Имя, которое показываем в UI (у друзей — актуальное с сервера).
    var displayNameOrUsername: String { displayName ?? username }

    enum CodingKeys: String, CodingKey {
        case id, username, displayName, avatar, level, xp, streak, isOnline, joinDate
        case countryCode, playedToday, birthday
    }

    init(id: UUID, username: String, displayName: String? = nil, avatar: String, countryCode: String? = nil, level: Int, xp: Int, streak: Int, isOnline: Bool, joinDate: Date, playedToday: Bool = false, birthday: Date? = nil) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatar = avatar
        self.countryCode = countryCode
        self.level = level
        self.xp = xp
        self.streak = streak
        self.isOnline = isOnline
        self.joinDate = joinDate
        self.playedToday = playedToday
        self.birthday = birthday
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        avatar = try c.decode(String.self, forKey: .avatar)
        countryCode = try c.decodeIfPresent(String.self, forKey: .countryCode)
        level = try c.decode(Int.self, forKey: .level)
        xp = try c.decode(Int.self, forKey: .xp)
        streak = try c.decode(Int.self, forKey: .streak)
        isOnline = try c.decode(Bool.self, forKey: .isOnline)
        joinDate = try c.decode(Date.self, forKey: .joinDate)
        playedToday = try c.decodeIfPresent(Bool.self, forKey: .playedToday) ?? false
        birthday = try c.decodeIfPresent(Date.self, forKey: .birthday)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encodeIfPresent(displayName, forKey: .displayName)
        try c.encode(avatar, forKey: .avatar)
        try c.encodeIfPresent(countryCode, forKey: .countryCode)
        try c.encode(level, forKey: .level)
        try c.encode(xp, forKey: .xp)
        try c.encode(streak, forKey: .streak)
        try c.encode(isOnline, forKey: .isOnline)
        try c.encode(joinDate, forKey: .joinDate)
        try c.encode(playedToday, forKey: .playedToday)
        try c.encodeIfPresent(birthday, forKey: .birthday)
    }
}

// MARK: - Duel Challenge (режим «Дуэль»: один и тот же seed — одинаковые вопросы у обоих)
struct DuelChallenge: Identifiable, Codable {
    let id: String
    let challengerId: String
    let challengerName: String
    let opponentId: String
    let opponentName: String
    let seed: Int
    let createdAt: Date
    var challengerScore: Int?
    var opponentScore: Int?
    var status: Status
    enum Status: String, Codable { case pending, challengerCompleted, opponentCompleted, completed }
}
