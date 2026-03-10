import Foundation

/// Клиент API дуэлей на flags.worldarena.games
final class DuelAPIService {
    static let shared = DuelAPIService()
    
    private let baseURL = "https://flags.worldarena.games/api/v1"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }
    
    /// Создать вызов на дуэль (вызывающий отправляет на сервер)
    func createChallenge(opponentId: String, opponentName: String, seed: Int, challengerName: String, challengerId: String) async throws -> String {
        let url = URL(string: "\(baseURL)/duel/challenge")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(challengerId, forHTTPHeaderField: "X-User-Id")
        let body: [String: Any] = [
            "opponentId": opponentId,
            "seed": seed,
            "challengerName": challengerName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let challengeId = json?["challengeId"] as? String else {
            throw DuelAPIError.invalidResponse
        }
        return challengeId
    }
    
    /// Входящие вызовы для текущего пользователя
    func fetchIncomingChallenges(userId: String) async throws -> [DuelChallengeFromAPI] {
        var components = URLComponents(string: "\(baseURL)/duel/incoming")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        var request = URLRequest(url: components.url!)
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = json?["challenges"] as? [[String: Any]] ?? []
        return list.compactMap { DuelChallengeFromAPI(from: $0) }
    }
    
    /// Принять вызов (получить seed и данные)
    func acceptChallenge(challengeId: String) async throws -> (seed: Int, challengerName: String, challengerScore: Int?) {
        let url = URL(string: "\(baseURL)/duel/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["challengeId": challengeId])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let seed = json?["seed"] as? Int, let name = json?["challengerName"] as? String else {
            throw DuelAPIError.invalidResponse
        }
        let score = json?["challengerScore"] as? Int
        return (seed, name, score)
    }
    
    /// Отправить результат (challenger или opponent).
    /// Возвращает winner: "challenger" | "opponent" | nil и, если доступны, оба счёта.
    func submitScore(challengeId: String, score: Int, side: String) async throws -> (winner: String?, challengerScore: Int?, opponentScore: Int?) {
        let url = URL(string: "\(baseURL)/duel/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["challengeId": challengeId, "score": score, "side": side]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (
            winner: json?["winner"] as? String,
            challengerScore: json?["challengerScore"] as? Int,
            opponentScore: json?["opponentScore"] as? Int
        )
    }
    
    /// Зарегистрировать пользователя; возвращает friendCode с сервера (сохранять и показывать в «Добавить друзей»).
    func registerUser(userId: String, username: String, deviceToken: String?, stats: [String: Any]? = nil, countryCode: String? = nil) async throws -> String? {
        let url = URL(string: "\(baseURL)/users/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["userId": userId, "username": username]
        if let token = deviceToken { body["deviceToken"] = token }
        if let stats = stats { body["stats"] = stats }
        if let cc = countryCode, !cc.isEmpty { body["countryCode"] = cc }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "register failed")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["friendCode"] as? String
    }

    /// Найти пользователя по коду друга (для добавления в друзья).
    func fetchUserByCode(_ code: String) async throws -> FriendFromAPI? {
        let encoded = code.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? code
        let url = URL(string: "\(baseURL)/users/by-code/\(encoded)")!
        let (data, response) = try await session.data(for: URLRequest(url: url))
        guard let http = response as? HTTPURLResponse else { return nil }
        if http.statusCode == 404 { return nil }
        guard http.statusCode == 200 else { throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "") }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return FriendFromAPI(from: json ?? [:])
    }

    /// Найти пользователя по логину (имени) для добавления в друзья.
    func fetchUserByUsername(_ username: String) async throws -> FriendFromAPI? {
        let encoded = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let url = URL(string: "\(baseURL)/users/by-username/\(encoded)")!
        let (data, response) = try await session.data(for: URLRequest(url: url))
        guard let http = response as? HTTPURLResponse else { return nil }
        if http.statusCode == 404 { return nil }
        guard http.statusCode == 200 else { throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "") }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return FriendFromAPI(from: json ?? [:])
    }

    /// Добавить друга по коду на сервере и получить данные друга.
    func addFriend(myUserId: String, friendCode: String) async throws -> FriendFromAPI? {
        let url = URL(string: "\(baseURL)/friends/add")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(myUserId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["friendCode": friendCode])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let friendJson = json?["friend"] as? [String: Any]
        return friendJson.flatMap { FriendFromAPI(from: $0) }
    }

    /// Обновить отображаемое имя на сервере (у друзей при следующей загрузке списка будет новое имя).
    func updateMyDisplayName(userId: String, displayName: String) async throws {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["displayName": displayName])
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError("update display name failed")
        }
    }

    /// Обновить код страны на сервере (чтобы у друзей обновлялся флаг).
    func updateMyCountryCode(userId: String, countryCode: String) async throws {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["countryCode": countryCode])
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError("update countryCode failed")
        }
    }

    /// Список друзей с сервера (для синхронизации).
    func fetchMyFriends(userId: String) async throws -> [FriendFromAPI] {
        var components = URLComponents(string: "\(baseURL)/users/me/friends")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        var request = URLRequest(url: components.url!)
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = json?["friends"] as? [[String: Any]] ?? []
        return list.compactMap { FriendFromAPI(from: $0) }
    }

    /// Отправить напоминание другу (nudge). phraseId — индекс мотивационной фразы (0..<N) для отображения у получателя на его языке.
    func sendNudge(fromUsername: String, toUsername: String, phraseId: Int) async throws {
        let url = URL(string: "\(baseURL)/nudge")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(fromUsername, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "toUsername": toUsername,
            "phraseId": phraseId
        ])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
    }

    /// Получить непрочитанные напоминания для пользователя.
    func fetchNudgeInbox(userId: String) async throws -> [NudgeFromAPI] {
        var components = URLComponents(string: "\(baseURL)/nudge/inbox")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        var request = URLRequest(url: components.url!)
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = json?["nudges"] as? [[String: Any]] ?? []
        return list.compactMap { NudgeFromAPI(from: $0) }
    }

    /// Отметить все напоминания как прочитанные.
    func markNudgesRead(userId: String) async throws {
        let url = URL(string: "\(baseURL)/nudge/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["userId": userId])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
    }

    // MARK: - Auth
    func authRegister(email: String, password: String, username: String?) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["email": email, "password": password]
        if let username, !username.isEmpty { body["username"] = username }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authLogin(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authSocialLogin(provider: String, providerUserId: String, email: String?, displayName: String?) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/social-login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "provider": provider,
            "providerUserId": providerUserId
        ]
        if let email, !email.isEmpty { body["email"] = email }
        if let displayName, !displayName.isEmpty { body["displayName"] = displayName }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authChangePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/auth/change-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
    }

    /// Возвращает true, если письмо с кодом отправлено; false — аккаунта с таким email нет.
    func authRequestPasswordReset(email: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/auth/reset-password/request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[Auth] reset-password/request failed HTTP \(code): \(body.prefix(500))")
            throw DuelAPIError.serverError(body)
        }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        return (json?["emailSent"] as? Bool) ?? false
    }

    func authConfirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/auth/reset-password/confirm")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
    }
}

struct AuthUserFromAPI {
    let username: String
    let email: String?
    let friendCode: String?

    init?(from json: [String: Any]) {
        guard let username = json["username"] as? String else { return nil }
        self.username = username
        self.email = json["email"] as? String
        self.friendCode = json["friendCode"] as? String
    }
}

struct AuthResponse {
    let token: String
    let user: AuthUserFromAPI
    let awardedRegistrationBonus: Bool

    init?(from json: [String: Any]) {
        guard let token = json["token"] as? String,
              let userJson = json["user"] as? [String: Any],
              let user = AuthUserFromAPI(from: userJson) else { return nil }
        self.token = token
        self.user = user
        self.awardedRegistrationBonus = (json["awardedRegistrationBonus"] as? Bool) ?? false
    }
}

/// Напоминание из inbox (кто напомнил, phraseId для локализованной фразы).
struct NudgeFromAPI {
    let id: String
    let fromUsername: String
    let phraseId: Int
    let createdAt: String?

    init?(from json: [String: Any]) {
        guard let id = json["id"] as? String,
              let fromUsername = json["fromUsername"] as? String,
              let phraseId = json["phraseId"] as? Int else { return nil }
        self.id = id
        self.fromUsername = fromUsername
        self.phraseId = min(14, max(0, phraseId))
        self.createdAt = json["createdAt"] as? String
    }

    /// Ключ локализации: nudge_phrase_1 ... nudge_phrase_15
    var phraseLocalizationKey: String { "nudge_phrase_\(phraseId + 1)" }
}

/// Пользователь/друг, полученный с API (по коду или из списка друзей).
struct FriendFromAPI {
    let username: String
    let displayName: String?
    let friendCode: String
    let countryCode: String?
    let level: Int
    let xp: Int
    let streak: Int

    init?(from json: [String: Any]) {
        guard let username = json["username"] as? String else { return nil }
        self.username = username
        self.displayName = json["displayName"] as? String
        self.friendCode = (json["friendCode"] as? String) ?? ""
        self.countryCode = (json["countryCode"] as? String) ?? (json["country_code"] as? String)
        self.level = json["level"] as? Int ?? 1
        self.xp = json["xp"] as? Int ?? 0
        self.streak = json["streak"] as? Int ?? 0
    }

    /// Приводит код страны к 2 буквам (API может вернуть alpha-3, напр. UKR).
    private static func normalizeCountryCode(_ raw: String?) -> String? {
        guard let s = raw?.uppercased(), !s.isEmpty else { return nil }
        if s.count == 2 { return s }
        if s.count == 3 {
            let alpha3To2: [String: String] = [
                "UKR": "UA", "RUS": "RU", "USA": "US", "SWE": "SE", "DEU": "DE", "GBR": "GB",
                "FRA": "FR", "ITA": "IT", "ESP": "ES", "POL": "PL", "BLR": "BY", "KAZ": "KZ"
            ]
            return alpha3To2[s] ?? nil
        }
        return nil
    }

    func toFriend() -> Friend {
        let avatarEmoji: String
        let code: String?
        if let twoLetter = Self.normalizeCountryCode(countryCode) {
            avatarEmoji = Self.countryCodeToFlagEmoji(twoLetter)
            code = twoLetter
        } else {
            let initial = String((displayName ?? username).prefix(1)).uppercased()
            let emojiMap: [String: String] = [
                "A": "🇦🇷", "B": "🇧🇷", "C": "🇨🇦", "D": "🇩🇰", "E": "🇪🇸", "F": "🇫🇷",
                "G": "🇩🇪", "H": "🇭🇷", "I": "🇮🇹", "J": "🇯🇵", "K": "🇰🇷", "L": "🇱🇺",
                "M": "🇲🇽", "N": "🇳🇱", "O": "🇳🇴", "P": "🇵🇱", "Q": "🇶🇦", "R": "🇷🇺",
                "S": "🇸🇪", "T": "🇹🇷", "U": "🇺🇸", "V": "🇻🇳", "W": "🇬🇧", "X": "🇨🇳",
                "Y": "🇾🇪", "Z": "🇿🇦"
            ]
            avatarEmoji = emojiMap[initial] ?? "👤"
            code = nil
        }
        return Friend(
            id: UUID(),
            username: username,
            displayName: displayName,
            avatar: avatarEmoji,
            countryCode: code,
            level: level,
            xp: xp,
            streak: streak,
            isOnline: false,
            joinDate: Date()
        )
    }

    /// Региональные индикаторы: две буквы кода страны -> флаг-эмодзи (например US -> 🇺🇸)
    static func countryCodeToFlagEmoji(_ code: String) -> String {
        let u = code.uppercased()
        guard u.count == 2 else { return "🏳️" }
        let scalars = Array(u.unicodeScalars)
        guard scalars.count == 2,
              let a = Unicode.Scalar(0x1F1E6 - 0x41 + scalars[0].value),
              let b = Unicode.Scalar(0x1F1E6 - 0x41 + scalars[1].value) else { return "🏳️" }
        return String(a) + String(b)
    }
}

struct DuelChallengeFromAPI {
    let id: String
    let challengerId: String
    let challengerName: String
    let seed: Int
    let createdAt: String
    let challengerScore: Int?
    let status: String
    
    init?(from json: [String: Any]) {
        guard let id = json["id"] as? String,
              let challengerId = json["challengerId"] as? String,
              let challengerName = json["challengerName"] as? String,
              let seed = json["seed"] as? Int else { return nil }
        self.id = id
        self.challengerId = challengerId
        self.challengerName = challengerName
        self.seed = seed
        self.createdAt = (json["createdAt"] as? String) ?? ""
        self.challengerScore = json["challengerScore"] as? Int
        self.status = (json["status"] as? String) ?? "pending"
    }
    
    func toDuelChallenge(opponentId: String, opponentName: String) -> DuelChallenge? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: createdAt)
        if date == nil {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            date = fallback.date(from: createdAt)
        }
        let dateResolved = date ?? Date()
        let statusEnum: DuelChallenge.Status
        switch status {
        case "pending": statusEnum = .pending
        case "challenger_completed": statusEnum = .challengerCompleted
        case "opponent_completed": statusEnum = .opponentCompleted
        case "completed": statusEnum = .completed
        default: statusEnum = .pending
        }
        return DuelChallenge(
            id: id,
            challengerId: challengerId,
            challengerName: challengerName,
            opponentId: opponentId,
            opponentName: opponentName,
            seed: seed,
            createdAt: dateResolved,
            challengerScore: challengerScore,
            opponentScore: nil,
            status: statusEnum
        )
    }
}

enum DuelAPIError: Error, LocalizedError {
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            if let data = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? String { return err }
            if !message.isEmpty, message.count < 300 { return message }
            return NSLocalizedString("Server error. Try again.", comment: "DuelAPIError fallback")
        case .invalidResponse:
            return NSLocalizedString("Invalid server response.", comment: "DuelAPIError")
        }
    }
}
