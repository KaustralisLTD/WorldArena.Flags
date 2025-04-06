import Foundation

// Добавляем структуру Mistake прямо в этот файл, так как она тесно связана с сервисом
struct Mistake: Codable {
    let countryCode: String
    let flags: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case countryCode
        case flags
        case timestamp
    }
}

class StatisticsService {
    static let shared = StatisticsService()
    
    private let statisticsKey = "flagQuizStatistics"
    private let mistakesKey = "flagQuizMistakes"
    
    private var mistakes: [Mistake] = []
    
    // Добавляем флаг для отслеживания загрузки
    private var isLoading = false
    
    private init() {}
    
    func saveStatistics(_ statistics: GameState.Statistics) {
        print("\n=== Saving Statistics ===")
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statisticsKey)
            print("Statistics successfully saved")
        }
    }
    
    func loadStatistics() -> GameState.Statistics {
        print("\n=== Loading Statistics ===")
        
        if let data = UserDefaults.standard.data(forKey: statisticsKey) {
            do {
                let statistics = try JSONDecoder().decode(GameState.Statistics.self, from: data)
                print("Statistics successfully loaded:")
                print("Total games: \(statistics.totalGames)")
                print("Best score: \(statistics.bestScore)")
                print("Correct answers: \(statistics.correctAnswers)")
                print("Total answers: \(statistics.totalAnswers)")
                print("Best time: \(statistics.bestTime)")
                return statistics
            } catch {
                print("No saved statistics found or decode error")
                return GameState.Statistics()
            }
        } else {
            print("No saved statistics found or decode error")
            return GameState.Statistics()
        }
    }
    
    func clearStatistics() {
        UserDefaults.standard.removeObject(forKey: statisticsKey)
    }
    
    private func migrateMistakesIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: mistakesKey) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let newMistakes = json.compactMap { dict -> Mistake? in
                    guard let countryCode = dict["countryCode"] as? String,
                          let flags = dict["flags"] as? String,
                          let timestamp = dict["timestamp"] as? Date else {
                        return nil
                    }
                    return Mistake(countryCode: countryCode, flags: flags, timestamp: timestamp)
                }
                
                print("Migrating \(newMistakes.count) mistakes to new format")
                
                let encoder = JSONEncoder()
                if let newData = try? encoder.encode(newMistakes) {
                    UserDefaults.standard.set(newData, forKey: mistakesKey)
                    print("Migration successful")
                }
            }
        } catch {
            print("Migration error:", error)
            // Очищаем старые данные, если они повреждены
            UserDefaults.standard.removeObject(forKey: mistakesKey)
        }
    }
    
    func loadMistakes() {
        print("📂 Loading Mistakes")
        
        // Сначала пробуем мигрировать
        migrateMistakesIfNeeded()
        
        guard let data = UserDefaults.standard.data(forKey: mistakesKey) else {
            print("No mistakes data found")
            mistakes = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            mistakes = try decoder.decode([Mistake].self, from: data)
            print("Successfully loaded \(mistakes.count) mistakes")
        } catch {
            print("❌ Error decoding mistakes:", error)
            // Если произошла ошибка декодирования, очищаем данные
            mistakes = []
            UserDefaults.standard.removeObject(forKey: mistakesKey)
        }
        print("Initial mistakes count: \(mistakes.count)")
    }
} 