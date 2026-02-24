import Foundation
import SwiftUI

@MainActor
class QuestService: ObservableObject {
    static let shared = QuestService()

    @Published private(set) var dailyQuests: [DailyQuest] = []

    private let storageKey = "quests.daily.v1"
    private let lastResetKey = "quests.daily.lastReset"

    private init() {
        loadDailyQuests()
    }

    func loadDailyQuests(forceReset: Bool = false) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date
        if forceReset || lastReset == nil || !calendar.isDate(lastReset!, inSameDayAs: today) {
            generateNewDailyQuests()
            UserDefaults.standard.set(today, forKey: lastResetKey)
            saveDailyQuests()
            return
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            generateNewDailyQuests(); saveDailyQuests(); return
        }
        do {
            let decoded = try JSONDecoder().decode([DailyQuestPersisted].self, from: data)
            dailyQuests = decoded.map { $0.toModel() }
        } catch {
            generateNewDailyQuests(); saveDailyQuests()
        }
    }

    func updateAfterGame(score: Int, totalQuestions: Int, correctAnswers: Int) {
        var updated = dailyQuests
        // Игры сыграно
        if let idx = updated.firstIndex(where: { $0.kind == .gamesPlayed }) {
            updated[idx].progress = min(updated[idx].target, updated[idx].progress + 1)
        }
        // Правильные ответы
        if let idx = updated.firstIndex(where: { $0.kind == .correctAnswers }) {
            updated[idx].progress = min(updated[idx].target, updated[idx].progress + correctAnswers)
        }
        // Очки (XP) через правильные ответы
        if let idx = updated.firstIndex(where: { $0.kind == .xpEarned }) {
            updated[idx].progress = min(updated[idx].target, updated[idx].progress + score * 10)
        }
        dailyQuests = updated
        saveDailyQuests()
    }

    private func generateNewDailyQuests() {
        // Лёгкие задания ~5-10 минут
        dailyQuests = [
            DailyQuest(title: LocalizationManager.shared.localizedString("Сыграй 3 игры"), target: 3, progress: 0, icon: "🎮", kind: .gamesPlayed),
            DailyQuest(title: LocalizationManager.shared.localizedString("Дай 10 правильных ответов"), target: 10, progress: 0, icon: "✅", kind: .correctAnswers),
            DailyQuest(title: LocalizationManager.shared.localizedString("Заработай 500 XP"), target: 500, progress: 0, icon: "⚡", kind: .xpEarned)
        ]
    }

    private func saveDailyQuests() {
        do {
            let toSave = dailyQuests.map { DailyQuestPersisted(from: $0) }
            let data = try JSONEncoder().encode(toSave)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save daily quests:", error)
        }
    }

    // MARK: - Daily gift boxes (награды за 3/3 ежедневных квестов)
    private static let dailyGiftsOpenedKey = "quests.daily.giftsOpened"
    private static let dailyGiftsOpenedDateKey = "quests.daily.giftsOpenedDate"

    /// Открытые сегодня индексы подарков (0, 1, 2). Сбрасывается по новому дню.
    func openedDailyGiftIndices() -> Set<Int> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: Self.dailyGiftsOpenedDateKey) as? Date
        if savedDate == nil || !calendar.isDate(savedDate!, inSameDayAs: today) {
            return []
        }
        let arr = UserDefaults.standard.array(forKey: Self.dailyGiftsOpenedKey) as? [Int] ?? []
        return Set(arr)
    }

    /// Открыть подарок по индексу (0..<3). Возвращает награду или nil, если уже открыт / не все квесты выполнены.
    func openDailyGift(index: Int, allQuestsCompleted: Bool) -> DailyGiftReward? {
        guard allQuestsCompleted, (0..<3).contains(index), !openedDailyGiftIndices().contains(index) else { return nil }
        let reward = DailyGiftReward.random()
        var opened = openedDailyGiftIndices()
        opened.insert(index)
        UserDefaults.standard.set(Array(opened), forKey: Self.dailyGiftsOpenedKey)
        UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: Self.dailyGiftsOpenedDateKey)
        return reward
    }
}

// Награда за открытие подарка: буст XP или F-Bucks
enum DailyGiftReward {
    case xpBoost2x10min
    case xpBoost3x15min
    case fBucks1
    case fBucks2

    static func random() -> DailyGiftReward {
        switch Int.random(in: 0..<100) {
        case 0..<40: return .xpBoost2x10min
        case 40..<75: return .xpBoost3x15min
        case 75..<92: return .fBucks1
        default: return .fBucks2
        }
    }

    @MainActor
    func apply(to profile: UserProfile) {
        switch self {
        case .xpBoost2x10min: profile.activateXPBoost(multiplier: 2, durationMinutes: 10)
        case .xpBoost3x15min: profile.activateXPBoost(multiplier: 3, durationMinutes: 15)
        case .fBucks1: profile.addFBucks(1, reason: .dailyGift)
        case .fBucks2: profile.addFBucks(2, reason: .dailyGift)
        }
    }
}

struct DailyQuest: Identifiable {
    enum Kind: String, Codable { case gamesPlayed, correctAnswers, xpEarned }
    let id: UUID = UUID()
    let title: String
    let target: Int
    var progress: Int
    let icon: String
    let kind: Kind
    var isCompleted: Bool { progress >= target }
}

private struct DailyQuestPersisted: Codable {
    let title: String
    let target: Int
    let progress: Int
    let icon: String
    let kind: DailyQuest.Kind

    init(from model: DailyQuest) {
        self.title = model.title
        self.target = model.target
        self.progress = model.progress
        self.icon = model.icon
        self.kind = model.kind
    }

    func toModel() -> DailyQuest {
        DailyQuest(title: title, target: target, progress: progress, icon: icon, kind: kind)
    }
}

