import Foundation

enum DuelInviteSuppression {
    private static func snoozeUntilKey(_ challengeId: String) -> String {
        "duelInvite.snoozeUntil.\(challengeId)"
    }

    private static func declinedKey(_ challengeId: String) -> String {
        "duelInvite.declined.\(challengeId)"
    }

    static func isDeclined(_ challengeId: String) -> Bool {
        UserDefaults.standard.bool(forKey: declinedKey(challengeId))
    }

    static func suppressUntil(_ challengeId: String) -> Date? {
        let seconds = UserDefaults.standard.double(forKey: snoozeUntilKey(challengeId))
        guard seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    static func isSuppressed(_ challengeId: String, now: Date = Date()) -> Bool {
        if isDeclined(challengeId) { return true }
        guard let until = suppressUntil(challengeId) else { return false }
        return until > now
    }

    static func snooze(_ challengeId: String, until: Date) {
        let t = max(until.timeIntervalSince1970, 0)
        UserDefaults.standard.set(t, forKey: snoozeUntilKey(challengeId))
        // если мы снова "напомним", отменяем флаг declined (актуально при Accept)
        UserDefaults.standard.set(false, forKey: declinedKey(challengeId))
    }

    static func decline(_ challengeId: String) {
        UserDefaults.standard.set(true, forKey: declinedKey(challengeId))
        // чтобы гарантированно не всплывало до конца жизни вызова
        UserDefaults.standard.set(Date.distantFuture.timeIntervalSince1970, forKey: snoozeUntilKey(challengeId))
    }

    static func clear(_ challengeId: String) {
        UserDefaults.standard.removeObject(forKey: snoozeUntilKey(challengeId))
        UserDefaults.standard.removeObject(forKey: declinedKey(challengeId))
    }
}

