import Foundation
import LocalAuthentication

/// Данные для восстановления сессии по биометрии после выхода (хранятся в Keychain).
private struct BiometricRestoreData: Codable {
    let token: String
    let email: String
    let username: String
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isGuestMode = true
    @Published private(set) var authEmail: String?
    @Published private(set) var authUsername: String?
    @Published var biometricEnabled = false {
        didSet {
            UserDefaults.standard.set(biometricEnabled, forKey: Self.biometricEnabledKey)
            if biometricEnabled, let t = authToken, let e = authEmail, let u = authUsername {
                saveBiometricRestore(token: t, email: e, username: u)
            } else if !biometricEnabled {
                KeychainStorage.remove(forKey: Self.biometricRestoreKey)
            }
        }
    }

    private(set) var authToken: String?

    private static let tokenKey = "auth.token.v1"
    private static let emailKey = "auth.email.v1"
    private static let usernameKey = "auth.username.v1"
    private static let biometricEnabledKey = "auth.biometric.enabled.v1"
    private static let biometricRestoreKey = "auth.biometric.restore.v1"

    private init() {
        authToken = UserDefaults.standard.string(forKey: Self.tokenKey)
        authEmail = UserDefaults.standard.string(forKey: Self.emailKey)
        authUsername = UserDefaults.standard.string(forKey: Self.usernameKey)
        biometricEnabled = UserDefaults.standard.bool(forKey: Self.biometricEnabledKey)
        isAuthenticated = (authToken?.isEmpty == false)
        isGuestMode = !isAuthenticated
    }

    /// Есть ли сохранённые данные для входа по биометрии (после выхода).
    var hasBiometricRestoreAvailable: Bool {
        biometricEnabled && loadBiometricRestore() != nil
    }

    private func saveBiometricRestore(token: String, email: String, username: String) {
        let data = BiometricRestoreData(token: token, email: email, username: username)
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        _ = KeychainStorage.save(data: encoded, forKey: Self.biometricRestoreKey)
    }

    private func loadBiometricRestore() -> BiometricRestoreData? {
        guard let data = KeychainStorage.load(forKey: Self.biometricRestoreKey),
              let decoded = try? JSONDecoder().decode(BiometricRestoreData.self, from: data) else { return nil }
        return decoded
    }

    func register(email: String, password: String, username: String?) async throws {
        let locale = LocalizationManager.shared.apiLanguageCode
        let result = try await DuelAPIService.shared.authRegister(email: email, password: password, username: username, localeCode: locale)
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
        let locale = LocalizationManager.shared.apiLanguageCode
        let result = try await DuelAPIService.shared.authSocialLogin(
            provider: provider,
            providerUserId: providerUserId,
            email: email,
            displayName: displayName,
            localeCode: locale
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
        let locale = LocalizationManager.shared.apiLanguageCode
        try await DuelAPIService.shared.authChangePassword(token: token, currentPassword: currentPassword, newPassword: newPassword, localeCode: locale)
    }

    /// Возвращает true, если письмо с кодом отправлено; false — аккаунта с таким email нет.
    func requestPasswordReset(email: String) async throws -> Bool {
        try await DuelAPIService.shared.authRequestPasswordReset(email: email)
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        let locale = LocalizationManager.shared.apiLanguageCode
        try await DuelAPIService.shared.authConfirmPasswordReset(email: email, code: code, newPassword: newPassword, localeCode: locale)
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
        // Keychain с данными для биометрии не удаляем — при следующем входе будет опция «Вход по биометрии»
    }

    /// Вход по биометрии: проверка лица/пальца, затем восстановление сессии из Keychain (работает и после выхода).
    func unlockWithBiometrics() async -> Bool {
        guard biometricEnabled else { return false }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        let reason = LocalizationManager.shared.localizedString("Biometric login prompt")
        let success = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { ok, _ in
                continuation.resume(returning: ok)
            }
        }
        guard success else { return false }
        if let token = authToken, !token.isEmpty {
            return true
        }
        guard let restore = loadBiometricRestore() else { return false }
        authToken = restore.token
        authEmail = restore.email
        authUsername = restore.username
        isAuthenticated = true
        isGuestMode = false
        UserDefaults.standard.set(restore.token, forKey: Self.tokenKey)
        UserDefaults.standard.set(restore.email, forKey: Self.emailKey)
        UserDefaults.standard.set(restore.username, forKey: Self.usernameKey)
        UserProfile.shared.username = restore.username
        UserProfile.shared.saveToStorage()
        return true
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
        if biometricEnabled {
            saveBiometricRestore(token: response.token, email: response.user.email ?? "", username: response.user.username)
        }

        UserProfile.shared.username = response.user.username
        UserProfile.shared.saveToStorage()
    }
}

