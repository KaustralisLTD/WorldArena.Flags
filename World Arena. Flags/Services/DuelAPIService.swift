import Foundation

/// Клиент API дуэлей на flags.worldarena.games
final class DuelAPIService {
    static let shared = DuelAPIService()
    
    private let baseURL = "https://flags.worldarena.games/api/v1"
    private let session: URLSession

    /// Значение для заголовка Accept-Language по коду языка (es, uk, pt-BR и т.д.).
    private static func acceptLanguageValue(localeCode: String?) -> String {
        let code = (localeCode ?? UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.languageCode ?? "en").lowercased()
        if code.isEmpty || code == "system" { return Locale.current.languageCode.map { "\($0),en;q=0.9" } ?? "en" }
        if code.hasPrefix("pt") { return "pt-BR,en;q=0.9" }
        if code == "zh-hant" { return "zh-Hant,en;q=0.9" }
        return "\(code),en;q=0.9"
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    struct DuelSetup: Sendable {
        let regions: [String]
        let difficulty: String
        let gameMode: Int
        let questionsCount: Int
        let optionsCount: Int
        let questionsPayload: [DuelQuestionPayloadItem]?

        init(
            regions: [String],
            difficulty: String,
            gameMode: Int,
            questionsCount: Int,
            optionsCount: Int,
            questionsPayload: [DuelQuestionPayloadItem]? = nil
        ) {
            self.regions = regions
            self.difficulty = difficulty
            self.gameMode = gameMode
            self.questionsCount = questionsCount
            self.optionsCount = optionsCount
            self.questionsPayload = questionsPayload
        }
    }
    
    /// Создать вызов на дуэль (вызывающий отправляет на сервер)
    func createChallenge(
        opponentId: String,
        opponentName: String,
        seed: Int,
        challengerName: String,
        challengerId: String,
        duelSetup: DuelSetup
    ) async throws -> String {
        let url = URL(string: "\(baseURL)/duel/challenge")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(challengerId, forHTTPHeaderField: "X-User-Id")
        let body: [String: Any] = [
            "opponentId": opponentId,
            "seed": seed,
            "challengerName": challengerName,
            "duelRegions": duelSetup.regions,
            "duelDifficulty": duelSetup.difficulty,
            "duelGameMode": duelSetup.gameMode,
            "duelQuestionsCount": duelSetup.questionsCount,
            "duelOptionsCount": duelSetup.optionsCount,
            "duelQuestionsPayload": (duelSetup.questionsPayload ?? []).map { item in
                [
                    "correctCountryId": item.correctCountryId,
                    "optionCountryIds": item.optionCountryIds
                ]
            }
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

    /// Входящие дуэли для синхронизации (включая opponent_completed/completed)
    func fetchIncomingChallengesForSync(userId: String) async throws -> [DuelChallengeFromAPI] {
        var components = URLComponents(string: "\(baseURL)/duel/incoming-sync")!
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
    
    /// Принять вызов (получить seed и данные).
    /// userId отправляем в X-User-Id для корректной серверной диагностики/валидации.
    func acceptChallenge(
        challengeId: String,
        userId: String? = nil
    ) async throws -> (seed: Int, challengerName: String, challengerScore: Int?, duelSetup: DuelSetup?) {
        let url = URL(string: "\(baseURL)/duel/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let userId, !userId.isEmpty {
            request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        }
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
        let questionsPayload: [DuelQuestionPayloadItem]? = {
            guard let raw = json?["duelQuestionsPayload"] as? [[String: Any]] else { return nil }
            return raw.compactMap { item in
                guard
                    let correct = item["correctCountryId"] as? String,
                    let options = item["optionCountryIds"] as? [String],
                    !correct.isEmpty,
                    !options.isEmpty
                else { return nil }
                return DuelQuestionPayloadItem(correctCountryId: correct, optionCountryIds: options)
            }
        }()
        let setup: DuelSetup? = {
            guard
                let regions = json?["duelRegions"] as? [String],
                let difficulty = json?["duelDifficulty"] as? String,
                let gameMode = json?["duelGameMode"] as? Int
            else { return nil }
            return DuelSetup(
                regions: regions,
                difficulty: difficulty,
                gameMode: gameMode,
                questionsCount: json?["duelQuestionsCount"] as? Int ?? 0,
                optionsCount: json?["duelOptionsCount"] as? Int ?? 0,
                questionsPayload: questionsPayload
            )
        }()
        return (seed, name, score, setup)
    }

    /// Отклонить входящий вызов.
    func declineChallenge(challengeId: String, userId: String) async throws {
        let url = URL(string: "\(baseURL)/duel/decline")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["challengeId": challengeId])

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError("decline failed")
        }
    }

    /// Remind отправляет push-сообщение сопернику ещё раз.
    /// Сервер вернёт 409, если результат уже доступен.
    func remindChallenge(challengeId: String, userId: String) async throws -> String {
        let url = URL(string: "\(baseURL)/duel/remind")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["challengeId": challengeId])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DuelAPIError.serverError("remind failed")
        }
        guard (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "remind failed")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["status"] as? String ?? "pending"
    }
    
    /// Отправить результат (challenger или opponent). `elapsedMs` — время прохождения дуэли для ничьи по очкам (сервер).
    func submitScore(challengeId: String, score: Int, side: String, elapsedMs: Int? = nil) async throws -> DuelSubmitResult {
        let url = URL(string: "\(baseURL)/duel/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["challengeId": challengeId, "score": score, "side": side]
        if let ms = elapsedMs { body["elapsedMs"] = ms }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return DuelSubmitResult(
            status: json?["status"] as? String,
            winner: json?["winner"] as? String,
            challengerScore: json?["challengerScore"] as? Int,
            opponentScore: json?["opponentScore"] as? Int,
            challengerTimeMs: json?["challengerTimeMs"] as? Int,
            opponentTimeMs: json?["opponentTimeMs"] as? Int
        )
    }

    /// Исходящие дуэли (я — challenger): актуальные счёт и статус с сервера, чтобы убрать «Waiting for result».
    func fetchOutgoingChallenges(userId: String) async throws -> [DuelOutgoingChallengeFromAPI] {
        var components = URLComponents(string: "\(baseURL)/duel/outgoing")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        var request = URLRequest(url: components.url!)
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = json?["challenges"] as? [[String: Any]] ?? []
        return list.compactMap { DuelOutgoingChallengeFromAPI(from: $0) }
    }

    /// Удалить друга на сервере (и локально после успеха).
    func removeFriend(myUserId: String, friendUsername: String) async throws {
        let url = URL(string: "\(baseURL)/friends/remove")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(myUserId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["friendUsername": friendUsername])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
    }
    
    /// Зарегистрировать пользователя; возвращает friendCode с сервера (сохранять и показывать в «Добавить друзей») и место в мире из БД.
    func registerUser(userId: String, username: String, deviceToken: String?, stats: [String: Any]? = nil, countryCode: String? = nil) async throws -> (friendCode: String?, worldRank: Int?) {
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
        let code = json?["friendCode"] as? String
        let worldRank: Int?
        if let w = json?["worldRank"] as? Int {
            worldRank = w
        } else if let n = json?["worldRank"] as? NSNumber {
            worldRank = n.intValue
        } else {
            worldRank = nil
        }
        return (code, worldRank)
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

    /// Загруженное фото профиля (без avatarConfig) — PATCH только avatar + customAvatarBase64.
    func updateMyCustomPhoto(userId: String, imageData: Data) async throws {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let payload: [String: Any] = [
            "avatar": "custom_photo",
            "customAvatarBase64": imageData.base64EncodedString()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError("update custom photo failed")
        }
    }

    /// Обновить avatarConfig на сервере.
    func updateMyAvatarConfig(
        userId: String,
        config: AvatarConfiguration,
        avatar: String? = nil,
        customAvatarImageData: Data? = nil
    ) async throws {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let avatarConfig: [String: Any] = [
            "skinTone": config.skinTone.rawValue,
            "backgroundColor": config.backgroundColor.rawValue,
            "clothingColor": config.clothingColor.rawValue,
            "hairColor": config.hairColor.rawValue,
            "eyeColor": config.eyeColor.rawValue,
            "glassesColor": config.glassesColor?.rawValue as Any,
            "facialHairColor": config.facialHairColor?.rawValue as Any,
            "headwearColor": config.headwearColor?.rawValue as Any,
            "bodyStyle": config.bodyStyle.rawValue,
            "expression": config.expression.rawValue,
            "hairstyle": config.hairstyle.rawValue,
            "glassesStyle": config.glassesStyle.rawValue,
            "facialHairStyle": config.facialHairStyle.rawValue,
            "headwearStyle": config.headwearStyle.rawValue,
            "clothingStyle": config.clothingStyle.rawValue
        ]
        var payload: [String: Any] = ["avatarConfig": avatarConfig]
        if let avatar {
            payload["avatar"] = avatar
        }
        if let data = customAvatarImageData {
            payload["customAvatarBase64"] = data.base64EncodedString()
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError("update avatarConfig failed")
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

    // MARK: - Birthday gift

    struct BirthdayGiftFromAPI {
        let giverUsername: String
        let type: String
        let year: Int

        init?(from json: [String: Any]) {
            guard
                let giver = json["giverUsername"] as? String,
                let type = json["type"] as? String,
                let year = json["year"] as? Int
            else { return nil }
            self.giverUsername = giver
            self.type = type
            self.year = year
        }
    }

    /// Отправить подарок ко дню рождения другу.
    /// type: "xpBoost" или "fBucks" (сервер валидирует строку).
    func sendBirthdayGift(fromUsername: String, toUsername: String, type: String) async throws {
        let trimmedFrom = fromUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = toUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty, !trimmedTo.isEmpty else { return }
        let url = URL(string: "\(baseURL)/friends/\(trimmedTo)/birthday-gift")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedFrom, forHTTPHeaderField: "X-User-Id")
        let body: [String: Any] = ["type": type]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DuelAPIError.invalidResponse
        }
        if (200...299).contains(http.statusCode) { return }
        if http.statusCode == 400 || http.statusCode == 409 {
            if
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let errorMessage = json["error"] as? String
            {
                throw DuelAPIError.serverError(errorMessage)
            }
            throw DuelAPIError.serverError("birthday_gift_bad_request")
        }
        if http.statusCode == 404 {
            throw DuelAPIError.serverError("birthday_friend_not_found")
        }
        throw DuelAPIError.serverError("HTTP \(http.statusCode)")
    }

    /// Получить входящие подарки ко дню рождения (для текущего пользователя).
    func fetchBirthdayGiftsInbox(userId: String) async throws -> [BirthdayGiftFromAPI] {
        var components = URLComponents(string: "\(baseURL)/birthday-gifts/inbox")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        var request = URLRequest(url: components.url!)
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = json?["gifts"] as? [[String: Any]] ?? []
        return list.compactMap { BirthdayGiftFromAPI(from: $0) }
    }

    /// Пометить входящие подарки как обработанные (чтобы не применить повторно).
    func consumeBirthdayGifts(userId: String) async throws {
        let url = URL(string: "\(baseURL)/birthday-gifts/consume")!
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

    private static func mergeAuthClientInfo(into body: inout [String: Any]) {
        #if os(iOS)
        let info = DeviceSessionMetadata.clientInfoForAuth
        if !info.isEmpty {
            body["clientInfo"] = info
        }
        #endif
    }

    // MARK: - Auth
    func authRegister(email: String, password: String, username: String?, localeCode: String? = nil) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
        var body: [String: Any] = ["email": email, "password": password]
        if let username, !username.isEmpty { body["username"] = username }
        Self.mergeAuthClientInfo(into: &body)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authLogin(email: String, password: String, localeCode: String? = nil) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
        var loginBody: [String: Any] = ["email": email, "password": password]
        Self.mergeAuthClientInfo(into: &loginBody)
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authSocialLogin(provider: String, providerUserId: String, email: String?, displayName: String?, localeCode: String? = nil) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/social-login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
        var body: [String: Any] = [
            "provider": provider,
            "providerUserId": providerUserId
        ]
        if let email, !email.isEmpty { body["email"] = email }
        if let displayName, !displayName.isEmpty { body["displayName"] = displayName }
        Self.mergeAuthClientInfo(into: &body)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let parsed = AuthResponse(from: json) else { throw DuelAPIError.invalidResponse }
        return parsed
    }

    func authChangePassword(token: String, currentPassword: String, newPassword: String, localeCode: String? = nil) async throws {
        let url = URL(string: "\(baseURL)/auth/change-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
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
    func authRequestPasswordReset(email: String, localeCode: String? = nil) async throws -> Bool {
        let url = URL(string: "\(baseURL)/auth/reset-password/request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
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

    func authConfirmPasswordReset(email: String, code: String, newPassword: String, localeCode: String? = nil) async throws {
        let url = URL(string: "\(baseURL)/auth/reset-password/confirm")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.acceptLanguageValue(localeCode: localeCode), forHTTPHeaderField: "Accept-Language")
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

    func fetchAuthSessions(userId: String) async throws -> [AuthSessionFromAPI] {
        let escaped = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
        let primaryURL = URL(string: "\(baseURL)/auth/sessions?userId=\(escaped)")!
        func parseSessions(_ data: Data) -> [AuthSessionFromAPI] {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let sessionsJson = (json?["sessions"] as? [[String: Any]]) ?? []
            return sessionsJson.compactMap { AuthSessionFromAPI(from: $0) }
        }

        var request = URLRequest(url: primaryURL)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return parseSessions(data)
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        // Fallback: если на сервере reverse-proxy срезает /api/v1, пробуем legacy-путь /auth/sessions.
        if body.contains("Cannot GET /api/v1/auth/sessions") {
            let hostBase = baseURL.replacingOccurrences(of: "/api/v1", with: "")
            let fallbackURL = URL(string: "\(hostBase)/auth/sessions?userId=\(escaped)")!
            request = URLRequest(url: fallbackURL)
            let (fallbackData, fallbackResponse) = try await session.data(for: request)
            guard let fallbackHttp = fallbackResponse as? HTTPURLResponse, (200...299).contains(fallbackHttp.statusCode) else {
                throw DuelAPIError.serverError(String(data: fallbackData, encoding: .utf8) ?? "")
            }
            return parseSessions(fallbackData)
        }

        throw DuelAPIError.serverError(body)
    }

    func submitTimeChallengeResult(
        userId: String,
        score: Int,
        correctAnswers: Int,
        totalAnswers: Int,
        bestCombo: Int,
        durationSec: Int
    ) async throws -> TimeChallengeSubmitResult {
        let url = URL(string: "\(baseURL)/time-challenge/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "score": score,
            "correctAnswers": correctAnswers,
            "totalAnswers": totalAnswers,
            "bestCombo": bestCombo,
            "durationSec": durationSec
        ])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DuelAPIError.serverError(String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return TimeChallengeSubmitResult(
            dailyRank: json?["dailyRank"] as? Int,
            weeklyRank: json?["weeklyRank"] as? Int
        )
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

struct AuthSessionFromAPI: Sendable {
    let token: String
    let createdAt: Date?
    let expiresAt: Date?
    let deviceModel: String?
    let appVersion: String?
    let locationLabel: String?
    let locationCountryCode: String?

    init?(from json: [String: Any]) {
        guard let token = json["token"] as? String else { return nil }
        self.token = token

        func parseDate(_ raw: Any?) -> Date? {
            guard let s = raw as? String else { return nil }
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df.date(from: s)
        }

        self.createdAt = parseDate(json["createdAt"])
        self.expiresAt = parseDate(json["expiresAt"])
        func str(_ k: String) -> String? {
            guard let v = json[k] as? String else { return nil }
            let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        self.deviceModel = str("deviceModel") ?? str("device_model")
        self.appVersion = str("appVersion") ?? str("app_version")
        self.locationLabel = str("locationLabel") ?? str("location_label")
        self.locationCountryCode = str("locationCountryCode") ?? str("location_country_code")
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
    /// true если друг уже играл сегодня (тогда показываем огонёк и дни, а не кнопку «Напомнить»).
    let playedToday: Bool
    /// Регистрация на сервере (мс с 1970) — тот же anchor, что у `UserProfile.joinDate`, для совпадения рангов.
    let joinDateFromServer: Date?
    let totalGamesPlayed: Int
    let correctAnswers: Int
    /// День рождения (если сервер отдаёт; для пушей и баннера «Поздравьте друга»).
    let birthday: Date?
    /// Фото-аватар (если пользователь использует custom photo).
    let avatarPhotoBase64: String?
    let avatar: String?
    let achievements: [String]
    /// Место в мире по XP из БД (если сервер отдал).
    let worldRank: Int?

    init?(from json: [String: Any]) {
        guard let username = json["username"] as? String else { return nil }
        self.username = username
        self.displayName = json["displayName"] as? String
        self.friendCode = (json["friendCode"] as? String) ?? ""
        self.countryCode = (json["countryCode"] as? String) ?? (json["country_code"] as? String)
        self.level = json["level"] as? Int ?? 1
        self.xp = json["xp"] as? Int ?? 0
        self.streak = json["streak"] as? Int ?? 0
        self.playedToday = json["playedToday"] as? Bool ?? false
        if let n = json["createdAt"] as? NSNumber {
            self.joinDateFromServer = Date(timeIntervalSince1970: n.doubleValue / 1000.0)
        } else {
            self.joinDateFromServer = nil
        }
        self.totalGamesPlayed = (json["totalGamesPlayed"] as? Int)
            ?? (json["total_games_played"] as? Int) ?? 0
        self.correctAnswers = (json["correctAnswers"] as? Int)
            ?? (json["correct_answers"] as? Int) ?? 0
        self.avatarPhotoBase64 = json["avatarPhotoBase64"] as? String
        self.avatar = json["avatar"] as? String
        self.achievements = json["achievements"] as? [String] ?? []
        if let w = json["worldRank"] as? Int {
            self.worldRank = w
        } else if let n = json["worldRank"] as? NSNumber {
            self.worldRank = n.intValue
        } else {
            self.worldRank = nil
        }
        if let ms = json["birthday"] as? Double {
            self.birthday = Date(timeIntervalSince1970: ms / 1000)
        } else if let iso = json["birthday"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            self.birthday = formatter.date(from: iso)
        } else {
            self.birthday = nil
        }
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
            avatar: avatar ?? avatarEmoji,
            avatarPhotoBase64: avatarPhotoBase64,
            countryCode: code,
            level: level,
            xp: xp,
            streak: streak,
            totalGamesPlayed: totalGamesPlayed,
            correctAnswers: correctAnswers,
            isOnline: false,
            joinDate: joinDateFromServer ?? Date(),
            playedToday: playedToday,
            birthday: birthday,
            achievements: achievements,
            worldRankFromServer: worldRank
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

/// Ответ POST `/duel/submit`
struct DuelSubmitResult: Sendable {
    let status: String?
    let winner: String?
    let challengerScore: Int?
    let opponentScore: Int?
    let challengerTimeMs: Int?
    let opponentTimeMs: Int?
}

struct TimeChallengeSubmitResult: Sendable {
    let dailyRank: Int?
    let weeklyRank: Int?
}

/// Исходящая дуэль с сервера (синхронизация статуса у challenger).
struct DuelOutgoingChallengeFromAPI: Sendable {
    let id: String
    let challengerName: String
    let opponentName: String
    let seed: Int
    let createdAt: String
    let challengerScore: Int?
    let opponentScore: Int?
    let challengerTimeMs: Int?
    let opponentTimeMs: Int?
    let status: String
    let winner: String?

    init?(from json: [String: Any]) {
        guard let id = json["id"] as? String, let seed = json["seed"] as? Int else { return nil }
        self.id = id
        self.challengerName = (json["challengerName"] as? String) ?? ""
        self.opponentName = (json["opponentName"] as? String) ?? ""
        self.seed = seed
        self.createdAt = (json["createdAt"] as? String) ?? ""
        self.challengerScore = json["challengerScore"] as? Int
        self.opponentScore = json["opponentScore"] as? Int
        self.challengerTimeMs = json["challengerTimeMs"] as? Int
        self.opponentTimeMs = json["opponentTimeMs"] as? Int
        self.status = (json["status"] as? String) ?? "pending"
        self.winner = json["winner"] as? String
    }
}

struct DuelChallengeFromAPI {
    let id: String
    let challengerId: String
    let challengerName: String
    let seed: Int
    let createdAt: String
    let challengerScore: Int?
    let opponentScore: Int?
    let challengerTimeMs: Int?
    let opponentTimeMs: Int?
    let winner: String?
    let status: String
    let duelSetup: DuelAPIService.DuelSetup?
    
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
        self.opponentScore = json["opponentScore"] as? Int
        self.challengerTimeMs = json["challengerTimeMs"] as? Int
        self.opponentTimeMs = json["opponentTimeMs"] as? Int
        self.winner = json["winner"] as? String
        self.status = (json["status"] as? String) ?? "pending"
        let payloadItems: [DuelQuestionPayloadItem]? = {
            guard let raw = json["duelQuestionsPayload"] as? [[String: Any]] else { return nil }
            return raw.compactMap { item -> DuelQuestionPayloadItem? in
                guard
                    let correct = item["correctCountryId"] as? String,
                    let options = item["optionCountryIds"] as? [String]
                else { return nil }
                return DuelQuestionPayloadItem(correctCountryId: correct, optionCountryIds: options)
            }
        }()
        if let regions = json["duelRegions"] as? [String],
           let difficulty = json["duelDifficulty"] as? String,
           let gameMode = json["duelGameMode"] as? Int {
            self.duelSetup = .init(
                regions: regions,
                difficulty: difficulty,
                gameMode: gameMode,
                questionsCount: json["duelQuestionsCount"] as? Int ?? 0,
                optionsCount: json["duelOptionsCount"] as? Int ?? 0,
                questionsPayload: payloadItems
            )
        } else {
            self.duelSetup = nil
        }
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
        case "pending", "accepted": statusEnum = .pending
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
            opponentScore: opponentScore,
            status: statusEnum,
            duelRegions: duelSetup?.regions,
            duelDifficulty: duelSetup?.difficulty,
            duelGameMode: duelSetup?.gameMode,
            duelQuestionsCount: duelSetup?.questionsCount,
            duelOptionsCount: duelSetup?.optionsCount,
            duelQuestionsPayload: duelSetup?.questionsPayload
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
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let code = json["errorCode"] as? String {
                    let localized = NSLocalizedString(code, comment: "API error code")
                    if localized != code { return localized }
                }
                if let err = json["error"] as? String { return err }
            }
            if !message.isEmpty, message.count < 300 { return message }
            return NSLocalizedString("Server error. Try again.", comment: "DuelAPIError fallback")
        case .invalidResponse:
            return NSLocalizedString("Invalid server response.", comment: "DuelAPIError")
        }
    }
}
