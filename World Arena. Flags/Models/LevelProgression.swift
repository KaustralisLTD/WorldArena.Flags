import Foundation

/// Lifetime XP still drives leagues and statistics. Level progress has its own
/// increasing costs, with a one-time migration preserving earned levels.
enum LevelProgression {
    static func cost(for level: Int) -> Int { 2_000 + 500 * min(1_000_000, max(1, level)) }
    static func isCelebrationLevel(_ level: Int) -> Bool {
        [10, 50, 100].contains(level) || (level > 100 && level.isMultiple(of: 100))
    }
    static func highestCelebration(from old: Int, through new: Int) -> Int? {
        guard new > old else { return nil }
        let candidates = [10,50,100,new / 100 * 100]
        return candidates.filter { $0 > old && $0 <= new && isCelebrationLevel($0) }.max()
    }
    struct State: Codable, Equatable {
        var level: Int
        var progressXP: Int
        var lastTotalXP: Int
        static func migrate(level: Int, totalXP: Int) -> State {
            let level = max(1, level), total = max(0, totalXP)
            let legacyRemainder = max(0, min(999, total - (level - 1) * 1000))
            return State(level: level, progressXP: Int(Double(legacyRemainder) / 1000 * Double(LevelProgression.cost(for: level))), lastTotalXP: total)
        }
        func advanced(to totalXP: Int) -> State {
            var result = self
            // A stale cloud snapshot must not count previously earned XP again.
            let delta = max(0, totalXP - lastTotalXP)
            result.lastTotalXP = max(lastTotalXP, totalXP)
            result.progressXP += delta
            while result.progressXP >= LevelProgression.cost(for: result.level) {
                result.progressXP -= LevelProgression.cost(for: result.level)
                result.level += 1
            }
            return result
        }
        var remaining: Int { max(0, LevelProgression.cost(for: level) - progressXP) }
        var fraction: Double { max(0, min(1, Double(progressXP) / Double(LevelProgression.cost(for: level)))) }
    }
}
