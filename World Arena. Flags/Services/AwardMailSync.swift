import Foundation

/// Account-scoped retry queue. Only real milestone transitions enqueue messages;
/// the server checks the player's email consent and deduplicates each milestone.
@MainActor
enum AwardMailSync {
    private static var syncing = false
    private static var key: String { "awardMail.outbox.v1." + (AuthService.shared.authUsername ?? "guest") }
    static func enqueue(_ event: [String: Any], id: String) {
        guard AuthService.shared.authUsername != nil else { return }
        var queue = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Any]] ?? [:]
        queue[id] = event
        UserDefaults.standard.set(queue, forKey: key)
        Task { await sync() }
    }
    static func sync() async {
        guard !syncing, let token = AuthService.shared.authToken, let username = AuthService.shared.authUsername else { return }
        syncing = true
        defer { syncing = false }
        let accountKey = key
        let queue = UserDefaults.standard.dictionary(forKey: accountKey) as? [String: [String: Any]] ?? [:]
        for (id, event) in queue {
            guard AuthService.shared.authUsername == username else { return }
            var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/award-mail")!)
            request.httpMethod = "POST"; request.timeoutInterval = 15
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: event)
            guard let (_, response) = try? await URLSession.shared.data(for: request), (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
            var remaining = UserDefaults.standard.dictionary(forKey: accountKey) as? [String: [String: Any]] ?? [:]
            remaining.removeValue(forKey: id)
            UserDefaults.standard.set(remaining, forKey: accountKey)
        }
    }
}
