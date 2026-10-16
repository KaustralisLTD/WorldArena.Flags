import Foundation

/// Per-account durable outbox. Events are removed only after an authenticated acknowledgement.
@MainActor
enum LifecycleService {
    struct Question: Codable { let code: String; let correct: Bool }
    struct Event: Codable {
        let id: String
        let type: String
        let at: Int64
        let timezone: String
        let answers: Int
        let correct: Int
        let mode: String
        let difficulty: String
        let region: String
        let questions: [Question]
        var weakCountries: [String]? = nil
        var masteredCountries: [String]? = nil
    }
    struct Message: Decodable {
        struct Fact: Decodable { let label: String; let value: String }
        let id: String
        let journey: String
        let title: String
        let body: String
        let button: String
        let action: String
        let facts: [Fact]
    }
    struct Reward: Decodable { let id: String; let amount: Int }
    struct Completion: Decodable { let id: String; let correct: Int; let total: Int; let completedAt: Int64 }
    struct BonusQuestion: Decodable { let index: Int; let total: Int; let flag: String; let options: [String] }
    struct BonusState: Decodable { let sessionId: String?; let question: BonusQuestion?; let done: Bool?; let correct: Int?; let total: Int?; let reward: Reward? }
    private struct SyncResponse: Decodable { let accepted: [String]; let progress: Bool; let offers: Bool; let rewards: [Reward]; let completions: [Completion] }
    private struct MessageResponse: Decodable { let message: Message? }
    private static var syncing = false
    private static var syncAgain = false
    static var offersKey: String { "lifecycleOffers." + (AuthService.shared.authUsername ?? "guest") }
    private static let outbox = LifecycleEventOutbox(defaults: .standard)
    private static func events(_ owner: String) -> [Event] { outbox.load(owner: owner) }
    static func record(id: String, owner: String?, answers: Int, correct: Int, mode: String, difficulty: String, region: String, questions: [Question], weakCountries: [String] = [], masteredCountries: [String] = []) {
        guard let owner, owner == AuthService.shared.authUsername, answers > 0 else { return }
        guard UserDefaults.standard.bool(forKey: ProgressMailSync.preferenceKey) || UserDefaults.standard.bool(forKey: offersKey) else { return }
        var event = Event(id: id, type: "game_completed", at: Int64(Date().timeIntervalSince1970 * 1000), timezone: TimeZone.current.identifier, answers: answers, correct: min(correct, answers), mode: mode == "time-challenge" ? "timeChallenge" : mode, difficulty: difficulty, region: region, questions: Array(questions.prefix(answers)))
        event.weakCountries = weakCountries
        event.masteredCountries = masteredCountries
        outbox.append(event, owner: owner)
        ProgressMailSync.schedule()
    }
    static func sync(explicitConsent: Bool = false) async {
        guard let owner = AuthService.shared.authUsername, let token = AuthService.shared.authToken else { return }
        let consentKey = "lifecycle.explicitConsentAt." + owner
        if explicitConsent { UserDefaults.standard.set(Date().timeIntervalSince1970 * 1000, forKey: consentKey) }
        if syncing { syncAgain = true; return }
        syncing = true
        defer {
            syncing = false
            if syncAgain {
                syncAgain = false
                Task { await sync() }
            }
        }
        let consentAt = Int64(UserDefaults.standard.double(forKey: consentKey))
        let requestedProgress = UserDefaults.standard.bool(forKey: ProgressMailSync.preferenceKey)
        let requestedOffers = UserDefaults.standard.bool(forKey: offersKey)
        let cutoff = Int64(Date().addingTimeInterval(-28 * 86400).timeIntervalSince1970 * 1000)
        let collecting = UserDefaults.standard.bool(forKey: ProgressMailSync.preferenceKey) || UserDefaults.standard.bool(forKey: offersKey)
        if !collecting { outbox.clear(owner: owner) }
        let batch = Array(events(owner).filter { $0.at >= cutoff }.prefix(100))
        guard let eventData = try? JSONEncoder().encode(batch), let eventObjects = try? JSONSerialization.jsonObject(with: eventData) else { return }
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/lifecycle/sync")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "locale": LocalizationLanguageResolver.bundleLanguageCodeFromIdentifier(LocalizationManager.shared.currentLocale.identifier),
            "timezone": TimeZone.current.identifier,
            "progress": requestedProgress,
            "offers": requestedOffers,
            "explicitConsent": consentAt > 0,
            "consentAt": consentAt,
            "capabilities": ["regionRoute": true, "reviewMistakes": true, "bonusRoute": true, "capitalsLink": true],
            "events": eventObjects
        ])
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let result = try? JSONDecoder().decode(SyncResponse.self, from: data),
              owner == AuthService.shared.authUsername, token == AuthService.shared.authToken else { return }
        if Int64(UserDefaults.standard.double(forKey: consentKey)) == consentAt { UserDefaults.standard.removeObject(forKey: consentKey) }
        // Acknowledging reads the latest queue, preserving games completed during the request.
        let remaining = outbox.acknowledge(result.accepted, owner: owner)
        if !syncAgain {
            if requestedProgress == UserDefaults.standard.bool(forKey: ProgressMailSync.preferenceKey) { UserDefaults.standard.set(result.progress, forKey: ProgressMailSync.preferenceKey) }
            if requestedOffers == UserDefaults.standard.bool(forKey: offersKey) { UserDefaults.standard.set(result.offers, forKey: offersKey) }
        }
        UserProfile.shared.applyLifecycleResults(owner: owner, rewards: result.rewards, completions: result.completions)
        if !remaining.isEmpty { ProgressMailSync.schedule() }
    }
    static func message(id: String? = nil) async -> Message? {
        guard let token = AuthService.shared.authToken, let owner = AuthService.shared.authUsername else { return nil }
        let requestedID = id ?? UserDefaults.standard.string(forKey: "lifecycle.pendingLink")
        let path = requestedID.flatMap { UUID(uuidString: $0) != nil ? "contacts/" + $0 : nil } ?? "message"
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/lifecycle/" + path)!)
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              owner == AuthService.shared.authUsername, token == AuthService.shared.authToken else { return nil }
        if (response as? HTTPURLResponse)?.statusCode == 404, requestedID != nil {
            UserDefaults.standard.removeObject(forKey: "lifecycle.pendingLink")
            return await message()
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let message = (try? JSONDecoder().decode(MessageResponse.self, from: data))?.message
        if message != nil { UserDefaults.standard.removeObject(forKey: "lifecycle.pendingLink") }
        return message
    }
    enum RequestFailure: Error { case unavailable }
    static func bonus(path: String, body: [String: Any]) async throws -> BonusState {
        guard let owner = AuthService.shared.authUsername, let token = AuthService.shared.authToken else { throw RequestFailure.unavailable }
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/lifecycle/bonus/" + path)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard owner == AuthService.shared.authUsername, token == AuthService.shared.authToken else { throw RequestFailure.unavailable }
        if (response as? HTTPURLResponse)?.statusCode == 409 { throw RequestFailure.unavailable }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let state = try JSONDecoder().decode(BonusState.self, from: data)
        if state.done == true { await sync() }
        return state
    }
    static func opened(_ id: String) async {
        guard let token = AuthService.shared.authToken else { return }
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/lifecycle/contacts/\(id)/action")!)
        request.httpMethod = "POST"
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }
}

@MainActor
struct LifecycleEventOutbox {
    let defaults: UserDefaults
    private func key(_ owner: String) -> String { "lifecycle.outbox.v1." + owner }
    func load(owner: String) -> [LifecycleService.Event] {
        guard let data = defaults.data(forKey: key(owner)) else { return [] }
        return (try? JSONDecoder().decode([LifecycleService.Event].self, from: data)) ?? []
    }
    func clear(owner: String) { defaults.removeObject(forKey: key(owner)) }
    private func save(_ events: [LifecycleService.Event], owner: String) {
        if let data = try? JSONEncoder().encode(events) { defaults.set(data, forKey: key(owner)) }
    }
    func append(_ event: LifecycleService.Event, owner: String, now: Date = Date()) {
        var queue = load(owner: owner)
        guard !queue.contains(where: { $0.id == event.id }) else { return }
        queue.append(event)
        let cutoff = Int64(now.addingTimeInterval(-28 * 86400).timeIntervalSince1970 * 1000)
        save(Array(queue.filter { $0.at >= cutoff }.suffix(1000)), owner: owner)
    }
    @discardableResult
    func acknowledge(_ accepted: [String], owner: String, now: Date = Date()) -> [LifecycleService.Event] {
        let ids = Set(accepted)
        let cutoff = Int64(now.addingTimeInterval(-28 * 86400).timeIntervalSince1970 * 1000)
        let remaining = load(owner: owner).filter { !ids.contains($0.id) && $0.at >= cutoff }
        save(remaining, owner: owner)
        return remaining
    }
}
