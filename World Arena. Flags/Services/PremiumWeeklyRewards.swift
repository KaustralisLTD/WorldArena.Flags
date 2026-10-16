import Foundation

/// A week is seven elapsed days, independent of locale, DST and calendar-week boundaries.
/// Currency is earned only for complete windows covered by verified StoreKit transactions.
enum PremiumWeeklyRewards {
    static let amount = 10
    static let week: TimeInterval = 7 * 24 * 60 * 60

    struct State: Codable, Equatable {
        var enrolledAt: Date
        var creditedWeeks: Set<Int> = []
    }

    struct Coverage {
        let start: Date
        let end: Date
    }

    static func dueWeeks(state: State, coverage: [Coverage], now: Date) -> [Int] {
        let elapsed = now.timeIntervalSince(state.enrolledAt)
        guard elapsed.isFinite, elapsed >= week else { return [] }
        // Reject corrupt clocks/state rather than allocate an unbounded range.
        guard elapsed / week < 10_000 else { return [] }
        let periods = coverage.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        return (0..<Int(elapsed / week)).filter { index in
            guard !state.creditedWeeks.contains(index) else { return false }
            let start = state.enrolledAt.addingTimeInterval(Double(index) * week)
            let end = start.addingTimeInterval(week)
            var coveredThrough = start
            for period in periods where period.end > coveredThrough {
                if period.start > coveredThrough { break }
                coveredThrough = max(coveredThrough, period.end)
                if coveredThrough >= end { return true }
            }
            return false
        }
    }
}
