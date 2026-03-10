import Foundation
import LocalAuthentication

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isGuestMode = true
    @Published private(set) var authEmail: String?
    @Published private(set) var authUsername: String?
    @Published var biometricEnabled = false {
        didSet { UserDefaults.standard.set(biometricEnabled, forKey: Self.biometricEnabledKey) }
    }

    private(set) var authToken: String?

    private static let tokenKey = "auth.token.v1"
    private static let emailKey = "auth.email.v1"
    private static let usernameKey = "auth.username.v1"
    private static let biometricEnabledKey = "auth.biometric.enabled.v1"

    private init() {
        authToken = UserDefaults.standard.string(forKey: Self.tokenKey)
        authEmail = UserDefaults.standard.string(forKey: Self.emailKey)
        authUsername = UserDefaults.standard.string(forKey: Self.usernameKey)
        biometricEnabled = UserDefaults.standard.bool(forKey: Self.biometricEnabledKey)
        isAuthenticated = (authToken?.isEmpty == false)
        isGuestMode = !isAuthenticated
    }

    func register(email: String, password: String, username: String?) async throws {
        let result = try await DuelAPIService.shared.authRegister(email: email, password: password, username: username)
        applyAuth(response: result)
        if result.awardedRegistrationBonus {
            UserProfile.shared.addFBucks(3, reason: .registrationBonus)
        }
    }

    func login(email: String, password: String) async throws {
        let result = try await DuelAPIService.shared.authLogin(email: email, password: password)
        applyAuth(response: result)
    }

    func loginWithSocial(provider: String, providerUserId: String, email: String?, displayName: String?) async throws {
        let result = try await DuelAPIService.shared.authSocialLogin(
            provider: provider,
            providerUserId: providerUserId,
            email: email,
            displayName: displayName
        )
        applyAuth(response: result)
        if result.awardedRegistrationBonus {
            UserProfile.shared.addFBucks(3, reason: .registrationBonus)
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let token = authToken else {
            throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        try await DuelAPIService.shared.authChangePassword(token: token, currentPassword: currentPassword, newPassword: newPassword)
    }

    /// Возвращает true, если письмо с кодом отправлено; false — аккаунта с таким email нет.
    func requestPasswordReset(email: String) async throws -> Bool {
        try await DuelAPIService.shared.authRequestPasswordReset(email: email)
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        try await DuelAPIService.shared.authConfirmPasswordReset(email: email, code: code, newPassword: newPassword)
    }

    func logoutToGuest() {
        authToken = nil
        authEmail = nil
        authUsername = nil
        isAuthenticated = false
        isGuestMode = true
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        UserDefaults.standard.removeObject(forKey: Self.usernameKey)
    }

    func unlockWithBiometrics() async -> Bool {
        guard biometricEnabled, authToken != nil else { return false }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        let reason = LocalizationManager.shared.localizedString("Biometric login prompt")
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private func applyAuth(response: AuthResponse) {
        authToken = response.token
        authEmail = response.user.email
        authUsername = response.user.username
        isAuthenticated = true
        isGuestMode = false

        UserDefaults.standard.set(response.token, forKey: Self.tokenKey)
        UserDefaults.standard.set(response.user.email, forKey: Self.emailKey)
        UserDefaults.standard.set(response.user.username, forKey: Self.usernameKey)
        if let friendCode = response.user.friendCode {
            UserDefaults.standard.set(friendCode, forKey: "user.serverFriendCode")
        }

        // Синхронизируем локальный профиль с серверным пользователем
        UserProfile.shared.username = response.user.username
        UserProfile.shared.saveToStorage()
    }
}

