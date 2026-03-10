import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var themeManager: AppThemeManager
    @ObservedObject private var authService = AuthService.shared
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    @State private var showingDeleteAccount = false
    @State private var showingProfile = false
    @State private var showingNotifications = false
    @State private var showingPrivacy = false
    @State private var showingHelp = false
    @State private var showingLanguageSelection = false
    @State private var showingThemeSelection = false
    @State private var showingPremium = false
    @State private var showingAuth = false
    @State private var showingChangePassword = false
    @State private var showingResetPassword = false
    @State private var isUpdateAvailable = false
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Account section
                    settingsSection(title: LocalizationManager.shared.localizedString("Аккаунт")) {
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Профиль пользователя"),
                            icon: "person.circle",
                            hasArrow: true
                        ) {
                            showingProfile = true
                        }
                        
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Уведомления"),
                            icon: "bell",
                            hasArrow: true
                        ) {
                            showingNotifications = true
                        }
                        
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Приватность"),
                            icon: "lock.shield",
                            hasArrow: true
                        ) {
                            showingPrivacy = true
                        }

                        if authService.isGuestMode {
                            SettingsRow(
                                title: LocalizationManager.shared.localizedString("Login / Register"),
                                icon: "person.badge.key",
                                hasArrow: true
                            ) {
                                showingAuth = true
                            }
                        } else {
                            SettingsRow(
                                title: LocalizationManager.shared.localizedString("Logged in"),
                                icon: "person.crop.circle.badge.checkmark",
                                hasArrow: false,
                                subtitle: authService.authEmail ?? authService.authUsername
                            ) { }

                            SettingsRow(
                                title: LocalizationManager.shared.localizedString("Change password"),
                                icon: "key.fill",
                                hasArrow: true
                            ) {
                                showingChangePassword = true
                            }

                            SettingsRow(
                                title: LocalizationManager.shared.localizedString("Reset password"),
                                icon: "envelope.badge",
                                hasArrow: true
                            ) {
                                showingResetPassword = true
                            }

                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Use Face ID / Touch ID"),
                                icon: "faceid",
                                isOn: $authService.biometricEnabled
                            )
                        }
                    }
                    
                    // Subscription section
                    settingsSection(title: LocalizationManager.shared.localizedString("Премиум")) {
                        VStack(alignment: .leading, spacing: 8) {
                        SettingsRow(
                            title: gameState.isPremium ? 
                                LocalizationManager.shared.localizedString("Управление подпиской") :
                                LocalizationManager.shared.localizedString("World Arena Premium"),
                                icon: "crown.fill",
                                hasArrow: true
                            ) {
                                showingPremium = true
                            }
                            
                            if gameState.isPremium {
                                PremiumActiveView()
                                    .padding(.leading, 40)
                            } else {
                                Text(LocalizationManager.shared.localizedString("Базовый пакет"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 40)
                            }
                        }
                        
                        if !gameState.isPremium {
                            Button(action: {
                                showingPremium = true
                            }) {
                                Text(LocalizationManager.shared.localizedString("Go Premium"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                    }
                    
                    // Support section
                    settingsSection(title: LocalizationManager.shared.localizedString("Поддержка")) {
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Центр помощи"),
                            icon: "questionmark.circle",
                            hasArrow: true
                        ) {
                            showingHelp = true
                        }
                        
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Обратная связь"),
                            icon: "envelope",
                            hasArrow: true
                        ) {
                            sendFeedback()
                        }
                    }
                    
                    // App settings
                    settingsSection(title: LocalizationManager.shared.localizedString("Настройки приложения")) {
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Язык игры"),
                            icon: "globe",
                            hasArrow: true,
                            subtitle: gameState.selectedLanguage.displayName
                        ) {
                            showingLanguageSelection = true
                        }
                        
                        SettingsRow(
                            title: LocalizationManager.shared.localizedString("Тема"),
                            icon: "paintbrush",
                            hasArrow: true,
                            subtitle: NSLocalizedString(themeManager.selectedTheme.localizationKey, comment: "")
                        ) {
                            showingThemeSelection = true
                        }
                        
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Звуковые эффекты"),
                            icon: "speaker.wave.2",
                            isOn: $soundEnabled
                        )
                        
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Вибрация"),
                            icon: "iphone.radiowaves.left.and.right",
                            isOn: $hapticEnabled
                        )
                        
                        versionRow
                        
                        if let url = appStoreURL {
                            SettingsRow(
                                title: LocalizationManager.shared.localizedString("Проверить обновления"),
                                icon: "arrow.down.circle",
                                hasArrow: true
                            ) { openAppStore(url: url) }
                        }
                    }
                    
                    if !authService.isGuestMode {
                        Button(action: {
                            signOut()
                        }) {
                            Text(LocalizationManager.shared.localizedString("Sign out"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(secondarySystemGroupedBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Delete account
                    Button(action: {
                        showingDeleteAccount = true
                    }) {
                        Text(LocalizationManager.shared.localizedString("Удалить аккаунт"))
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .underline()
                    }
                    .padding(.top, 16)
                    .alert(LocalizationManager.shared.localizedString("Удалить аккаунт"), isPresented: $showingDeleteAccount) {
                        Button(LocalizationManager.shared.localizedString("Отмена"), role: .cancel) {}
                        Button(LocalizationManager.shared.localizedString("Удалить"), role: .destructive) {}
                    } message: {
                        Text(LocalizationManager.shared.localizedString("Это действие нельзя отменить. Все ваши данные будут удалены навсегда."))
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Настройки"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #endif
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileEditView()
                .environmentObject(userProfile)
        }
        .sheet(isPresented: $showingAuth) {
            AuthGatewayView()
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpCenterView()
        }
                    .sheet(isPresented: $showingLanguageSelection) {
                LanguageSelectionView()
                    .environmentObject(gameState)
            }
            .sheet(isPresented: $showingThemeSelection) {
                ThemeSelectionView()
                    .environmentObject(themeManager)
            }
            .modifier(SettingsPremiumModifier(showingPremium: $showingPremium, gameState: gameState))
            .task {
                await checkForUpdates()
            }
    }
    
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    /// URL страницы в App Store. Добавьте в Info.plist ключ AppStoreID (строка с Apple ID приложения).
    private var appStoreURL: URL? {
        guard let id = Bundle.main.infoDictionary?["AppStoreID"] as? String, !id.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(id)")
    }

    private var isRunningViaTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    private var isIPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var versionRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.localizedString("Version"))
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Text(appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isUpdateAvailable {
                Button(LocalizationManager.shared.localizedString("Update")) {
                    openUpdateDestination()
                }
                .font(.system(size: isIPad ? 15 : 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, isIPad ? 14 : 12)
                .padding(.vertical, isIPad ? 9 : 7)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.7)
                )
                .cornerRadius(10)
                .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(secondarySystemGroupedBackground)
    }

    private func openAppStore(url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func openUpdateDestination() {
        #if os(iOS)
        if isRunningViaTestFlight, let tfURL = URL(string: "itms-beta://") {
            UIApplication.shared.open(tfURL)
            return
        }
        #endif
        if let url = appStoreURL {
            openAppStore(url: url)
        }
    }

    private func checkForUpdates() async {
        if isRunningViaTestFlight {
            await MainActor.run { isUpdateAvailable = true }
            return
        }

        guard let id = Bundle.main.infoDictionary?["AppStoreID"] as? String, !id.isEmpty else { return }
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let results = json["results"] as? [[String: Any]],
                let first = results.first,
                let storeVersion = first["version"] as? String
            else { return }

            let needsUpdate = compareVersions(storeVersion, appVersion) == .orderedDescending
            await MainActor.run { isUpdateAvailable = needsUpdate }
        } catch {
            // Ignore lookup failures silently.
        }
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.compare(rhs, options: .numeric)
    }

    // MARK: - Functions
    private func sendFeedback() {
        // Открыть почтовый клиент с локализованной темой
        let subjectRaw = LocalizationManager.shared.localizedString("Обратная связь по World Arena Flags")
        let subject = subjectRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subjectRaw
        if let url = URL(string: "mailto:support@worldarena.games?subject=\(subject)") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
    
    private func signOut() {
        authService.logoutToGuest()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteAccount() {
        // Удалить аккаунт (в реальном приложении это должно быть подтверждено сервером)
        signOut()
    }
    
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            VStack(spacing: 1) {
                content()
            }
            .background(secondarySystemGroupedBackground)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Methods
    private func restoreSubscription() {
        Task {
            await StoreManager.shared.restorePurchases()
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let hasArrow: Bool
    let subtitle: String?
    let action: () -> Void
    
    init(title: String, icon: String, hasArrow: Bool, subtitle: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.hasArrow = hasArrow
        self.subtitle = subtitle
        self.action = action
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(secondarySystemGroupedBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(secondarySystemGroupedBackground)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserProfile.shared)
        .environmentObject(GameState())
}

// MARK: - Premium Active View
struct PremiumActiveView: View {
    var body: some View {
        HStack(spacing: 8) {
            // Статичная иконка короны с градиентом
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Текст статуса
            Text(LocalizationManager.shared.localizedString("Премиум подписка активна"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
            
            Spacer()
            
            // Статичная иконка проверки
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
}
