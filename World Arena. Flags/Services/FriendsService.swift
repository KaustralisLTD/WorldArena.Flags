import Foundation
import SwiftUI

class FriendsService: ObservableObject {
    static let shared = FriendsService()

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

    private init() {}
    
    // MARK: - Friend Code Generation
    func generateFriendCode(for username: String) -> String {
        // Создаем уникальный код на основе имени пользователя
        let base = username.uppercased().replacingOccurrences(of: " ", with: "")
        let timestamp = Int(Date().timeIntervalSince1970)
        let hash = String(format: "%X", timestamp % 0xFFFF)
        return String(base.prefix(8)) + hash
    }
    
    // MARK: - Add Friend Result
    enum AddFriendResult {
        case success
        case userNotFound
        case noFriendCode
        case addFailed
        case alreadyFriends
        case cannotAddSelf
    }

    // MARK: - Add Friend Logic (через API: код друга выдаётся сервером при регистрации)
    @MainActor
    func addFriend(by code: String, to userProfile: UserProfile) async -> AddFriendResult {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else { return .addFailed }
        if userProfile.friends.contains(where: { $0.username.lowercased() == normalized.lowercased() }) {
            return .alreadyFriends
        }
        if normalized.uppercased() == userProfile.username.uppercased().replacingOccurrences(of: " ", with: "") {
            return .cannotAddSelf
        }
        let myId = userProfile.username
        guard !myId.isEmpty else { return .addFailed }
        guard let friendFromAPI = try? await DuelAPIService.shared.addFriend(myUserId: myId, friendCode: normalized) else {
            return .addFailed
        }
        let newFriend = friendFromAPI.toFriend()
        userProfile.friends.append(newFriend)
        userProfile.saveToStorage()
        return .success
    }

    /// Добавить друга по логину (имени): ищем пользователя по имени, получаем его friendCode, добавляем по коду.
    @MainActor
    func addFriend(byUsername username: String, to userProfile: UserProfile) async -> AddFriendResult {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return .addFailed }
        if userProfile.friends.contains(where: { $0.username.lowercased() == normalized.lowercased() }) {
            return .alreadyFriends
        }
        if normalized.lowercased() == userProfile.username.lowercased() {
            return .cannotAddSelf
        }
        let myId = userProfile.username
        guard !myId.isEmpty else { return .addFailed }
        do {
            guard let found = try await DuelAPIService.shared.fetchUserByUsername(normalized) else {
                return .userNotFound
            }
            guard !found.friendCode.isEmpty else {
                return .noFriendCode
            }
            return await addFriend(by: found.friendCode, to: userProfile)
        } catch {
            return .userNotFound
        }
    }
    
    private func createFriendFromCode(_ code: String) -> Friend {
        // Извлекаем имя из кода (первые 8 символов)
        let namePart = String(code.prefix(8))
        let displayName = namePart.replacingOccurrences(of: " ", with: "")
        
        // Создаем аватар на основе имени
        let initial = displayName.prefix(1).uppercased()
        let avatarEmoji = getAvatarForInitial(initial)
        
        // Генерируем более реалистичные данные
        let level = Int.random(in: 1...30)
        let xp = level * Int.random(in: 80...120) + Int.random(in: 0...500)
        let streak = Int.random(in: 0...100)
        
        // Более реалистичная дата регистрации (от 1 дня до 2 лет назад)
        let daysAgo = Int.random(in: 1...730)
        let joinDate = Date().addingTimeInterval(-Double(daysAgo * 24 * 3600))
        
        return Friend(
            id: UUID(),
            username: displayName,
            displayName: nil,
            avatar: avatarEmoji,
            level: level,
            xp: xp,
            streak: streak,
            isOnline: Bool.random(),
            joinDate: joinDate
        )
    }
    
    private func getAvatarForInitial(_ initial: String) -> String {
        // Создаем аватар на основе первой буквы имени
        let emojiMap: [String: String] = [
            "A": "🇦🇷", "B": "🇧🇷", "C": "🇨🇦", "D": "🇩🇰", "E": "🇪🇸", "F": "🇫🇷",
            "G": "🇩🇪", "H": "🇭🇷", "I": "🇮🇹", "J": "🇯🇵", "K": "🇰🇷", "L": "🇱🇺",
            "M": "🇲🇽", "N": "🇳🇱", "O": "🇳🇴", "P": "🇵🇱", "Q": "🇶🇦", "R": "🇷🇺",
            "S": "🇸🇪", "T": "🇹🇷", "U": "🇺🇸", "V": "🇻🇳", "W": "🇬🇧", "X": "🇨🇳",
            "Y": "🇾🇪", "Z": "🇿🇦"
        ]
        
        return emojiMap[initial] ?? "👤"
    }
    
    // MARK: - Profile URL Generation
    func generateProfileURL(for username: String) -> String {
        let friendCode = generateFriendCode(for: username)
        return "https://worldarena.games/profile/\(friendCode)"
    }
    
    // MARK: - Share Profile
    @MainActor
    func shareProfile(for userProfile: UserProfile) {
        #if os(iOS)
        let profileURL = generateProfileURL(for: userProfile.username)
        let shareText = "\(LocalizationManager.shared.localizedString("Мой профиль в World Arena Flags")): \(profileURL)"
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        #else
        // macOS implementation would go here
        #endif
    }
}

// MARK: - Friend Model Extension
extension Friend {
    var profileURL: String {
        return "https://worldarena.games/profile/\(username.uppercased().replacingOccurrences(of: " ", with: ""))"
    }

    /// Флаг-эмодзи по коду страны (RU -> 🇷🇺) или текущий avatar
    var displayAvatar: String {
        if let code = countryCode, code.count == 2 {
            return FriendsService.countryCodeToFlagEmoji(code)
        }
        if avatar.hasPrefix("custom_") {
            return "👤"
        }
        return avatar
    }

    var avatarDisplay: String {
        if avatar.hasPrefix("custom_") {
            return "👤" // Fallback для кастомных аватаров
        }
        return avatar
    }
}
