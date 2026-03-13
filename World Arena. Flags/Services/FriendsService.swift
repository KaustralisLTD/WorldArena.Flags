import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

class FriendsService: ObservableObject {
    static let shared = FriendsService()

    /// Нормализация кода страны к alpha-2 (UA, SE). Принимает также alpha-3 (UKR, SWE).
    static func normalizeCountryCode(_ raw: String?) -> String? {
        guard let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !s.isEmpty else { return nil }
        if s.count == 2 { return s }
        if s.count == 3 {
            let alpha3To2: [String: String] = [
                "UKR": "UA", "RUS": "RU", "USA": "US", "SWE": "SE", "DEU": "DE", "GBR": "GB",
                "FRA": "FR", "ITA": "IT", "ESP": "ES", "POL": "PL", "BLR": "BY", "KAZ": "KZ",
                "CAN": "CA", "AUS": "AU", "JPN": "JP", "CHN": "CN", "TUR": "TR", "BRA": "BR"
            ]
            return alpha3To2[s]
        }
        return nil
    }

    /// Региональные индикаторы: две буквы кода страны -> флаг-эмодзи (например US -> 🇺🇸)
    static func countryCodeToFlagEmoji(_ code: String) -> String {
        guard let u = normalizeCountryCode(code), u.count == 2 else { return "🏳️" }
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
            .replacingOccurrences(of: "@", with: "")
        guard !normalized.isEmpty else { return .addFailed }
        if userProfile.friends.contains(where: {
            $0.username.lowercased() == normalized.lowercased() ||
            ($0.displayName?.lowercased() == normalized.lowercased())
        }) {
            return .alreadyFriends
        }
        if normalized.lowercased() == userProfile.username.lowercased() {
            return .cannotAddSelf
        }
        let myId = userProfile.username
        guard !myId.isEmpty else { return .addFailed }
        do {
            guard let found = try await DuelAPIService.shared.fetchUserByUsername(normalized) else {
                // Fallback: в некоторых окружениях сервер может принимать логин напрямую в addFriend.
                let fallback = await addFriend(by: normalized, to: userProfile)
                return fallback == .addFailed ? .userNotFound : fallback
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

    /// URL профиля по коду друга (серверный код — для шаринга).
    func profileURL(friendCode: String) -> String {
        "https://worldarena.games/profile/\(friendCode)"
    }

    // MARK: - Share Profile (картинка с фото/статами + ссылка; по ссылке — в приложение или в магазин)
    @MainActor
    func shareProfile(for userProfile: UserProfile, friendCode: String? = nil) {
        #if os(iOS)
        let code = friendCode ?? generateFriendCode(for: userProfile.username)
        let profileURL = profileURL(friendCode: code)
        let format = LocalizationManager.shared.localizedString("Statistics Share Promo")
        let accuracy = userProfile.totalAnswers > 0
            ? min(100.0, max(0.0, Double(userProfile.correctAnswers) / Double(userProfile.totalAnswers) * 100.0))
            : 0.0
        let appLink = ShareService.shared.appStoreURL?.absoluteString ?? "https://apps.apple.com/app/world-arena-flags/id6744296834"
        let promoText = String(format: format, userProfile.bestScore, accuracy, userProfile.totalGamesPlayed, appLink)
        let shareText = "\(promoText)\n\n\(LocalizationManager.shared.localizedString("My Profile Share Title")): \(profileURL)"

        generateProfileShareImage(userProfile: userProfile, profileURL: profileURL) { [weak self] image in
            DispatchQueue.main.async {
                var items: [Any] = [shareText]
                if let image { items.insert(image, at: 0) }
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let top = self?.topViewController() {
                    if let pop = activityVC.popoverPresentationController {
                        pop.sourceView = top.view
                        pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
                        pop.permittedArrowDirections = []
                    }
                    top.present(activityVC, animated: true)
                }
            }
        }
        #else
        // macOS
        #endif
    }

    #if os(iOS)
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController? = {
            if let base { return base }
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            return scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController
        }()
        if let nav = root as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = root as? UITabBarController { return topViewController(base: tab.selectedViewController) }
        if let presented = root?.presentedViewController { return topViewController(base: presented) }
        return root
    }

    /// Рисует карточку для шаринга: аватар (или фото), имя, статы, QR со ссылкой на профиль.
    private func generateProfileShareImage(userProfile: UserProfile, profileURL: String, completion: @escaping (UIImage?) -> Void) {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemCyan.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            cg.setFillColor(UIColor.white.cgColor)
            let cardRect = CGRect(x: 20, y: 80, width: 360, height: 440)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
            cg.addPath(path.cgPath)
            cg.fillPath()

            let avatarRect = CGRect(x: 150, y: 120, width: 100, height: 100)
            if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                let cornerRadius: CGFloat = 50
                cg.saveGState()
                let clipPath = UIBezierPath(roundedRect: avatarRect, cornerRadius: cornerRadius)
                clipPath.addClip()
                ui.draw(in: avatarRect)
                cg.restoreGState()
            } else {
                cg.setFillColor(UIColor.systemBlue.withAlphaComponent(0.2).cgColor)
                cg.fillEllipse(in: avatarRect)
                let avatarText = userProfile.avatar.starts(with: "custom_") ? "👤" : "👤"
                let font = UIFont.systemFont(ofSize: 50)
                let attrs: [NSAttributedString.Key: Any] = [.font: font]
                let sz = avatarText.size(withAttributes: attrs)
                let pt = CGPoint(x: avatarRect.midX - sz.width / 2, y: avatarRect.midY - sz.height / 2)
                (avatarText as NSString).draw(at: pt, withAttributes: attrs)
            }

            let usernameFont = UIFont.boldSystemFont(ofSize: 24)
            let usernameAttrs: [NSAttributedString.Key: Any] = [.font: usernameFont, .foregroundColor: UIColor.label]
            let usernameSz = userProfile.username.size(withAttributes: usernameAttrs)
            (userProfile.username as NSString).draw(at: CGPoint(x: 200 - usernameSz.width / 2, y: 240), withAttributes: usernameAttrs)

            let statsFormat = LocalizationManager.shared.localizedString("Level %d • %d XP • %d-day streak")
            let statsText = String(format: statsFormat, userProfile.level, userProfile.xp, userProfile.streak)
            let statsFont = UIFont.systemFont(ofSize: 14)
            let statsAttrs: [NSAttributedString.Key: Any] = [.font: statsFont, .foregroundColor: UIColor.secondaryLabel]
            let statsSz = statsText.size(withAttributes: statsAttrs)
            (statsText as NSString).draw(at: CGPoint(x: 200 - statsSz.width / 2, y: 275), withAttributes: statsAttrs)

            if let qr = qrImage(from: profileURL) {
                qr.draw(in: CGRect(x: 170, y: 320, width: 60, height: 60))
            }
            let appFont = UIFont.boldSystemFont(ofSize: 16)
            let appAttrs: [NSAttributedString.Key: Any] = [.font: appFont, .foregroundColor: UIColor.systemBlue]
            let appText = "World Arena Flags"
            let appSz = appText.size(withAttributes: appAttrs)
            (appText as NSString).draw(at: CGPoint(x: 200 - appSz.width / 2, y: 390), withAttributes: appAttrs)
            let urlFont = UIFont.systemFont(ofSize: 12)
            let urlAttrs: [NSAttributedString.Key: Any] = [.font: urlFont, .foregroundColor: UIColor.tertiaryLabel]
            let urlText = "worldarena.games"
            let urlSz = urlText.size(withAttributes: urlAttrs)
            (urlText as NSString).draw(at: CGPoint(x: 200 - urlSz.width / 2, y: 415), withAttributes: urlAttrs)
        }
        completion(image)
    }

    private func qrImage(from string: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        guard let output = filter.outputImage?.transformed(by: transform),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    #endif
}

// MARK: - Friend Model Extension
extension Friend {
    var profileURL: String {
        return "https://worldarena.games/profile/\(username.uppercased().replacingOccurrences(of: " ", with: ""))"
    }

    /// Флаг-эмодзи по коду страны (RU -> 🇷🇺) или текущий avatar
    var displayAvatar: String {
        if let code = FriendsService.normalizeCountryCode(countryCode) {
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
