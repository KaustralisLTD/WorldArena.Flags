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
    @State private var showingLoginInfoSheet = false
    @State private var isUpdateAvailable = false
    @AppStorage(GameHomeLayoutVariant.storageKey) private var homeLayoutRaw: Int = GameHomeLayoutVariant.quickStart.rawValue

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
                                hasArrow: true,
                                subtitle: authService.authEmail ?? authService.authUsername
                            ) {
                                showingLoginInfoSheet = true
                            }

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

                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizationManager.shared.localizedString("home.layout.section"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            Picker("", selection: $homeLayoutRaw) {
                                Text(GameHomeLayoutVariant.classic.title).tag(GameHomeLayoutVariant.classic.rawValue)
                                Text(GameHomeLayoutVariant.quickStart.title).tag(GameHomeLayoutVariant.quickStart.rawValue)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        
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
        .sheetOrFullScreenOnIPad(isPresented: $showingProfile) {
            ProfileEditView()
                .environmentObject(userProfile)
                .environmentObject(gameState)
        }
        // fullScreenCover: вложенный .sheet(Настройки) + .sheet(вход) на iPhone при фокусе в поле почты
        // иногда срывает верхний sheet; полноэкранный вход стабильнее с клавиатурой.
        .fullScreenCover(isPresented: $showingAuth) {
            AuthGatewayView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingResetPassword) {
            ResetPasswordView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingLoginInfoSheet) {
            LoginInfoSheet(
                email: authService.authEmail ?? authService.authUsername ?? "—",
                lastLoginAt: authService.lastLoginAt,
                username: authService.authUsername ?? "—",
                currentSessionToken: authService.authToken,
                onLogout: {
                    showingLoginInfoSheet = false
                    signOut()
                }
            )
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingNotifications) {
            NotificationSettingsView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingPrivacy) {
            PrivacySettingsView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingHelp) {
            HelpCenterView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingLanguageSelection) {
            LanguageSelectionView()
                .environmentObject(gameState)
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingThemeSelection) {
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

private struct LoginInfoSheet: View {
    let email: String
    let lastLoginAt: Date?
    let username: String
    let currentSessionToken: String?
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isLoadingSessions = true
    @State private var sessions: [AuthSessionFromAPI] = []
    @State private var sessionsError: String?

    private var lm: LocalizationManager { LocalizationManager.shared }

    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    private var groupedBg: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    private var formattedLastLogin: String {
        guard let dt = lastLoginAt else { return "—" }
        let df = DateFormatter()
        df.locale = lm.currentLocale
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: dt)
    }

    private var otherSessions: [AuthSessionFromAPI] {
        guard let t = currentSessionToken?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return sessions }
        return sessions.filter { $0.token != t }
    }

    private var hasCurrentSessionToken: Bool {
        !(currentSessionToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(email)
                        .font(.system(size: 16, weight: .semibold))

                    HStack {
                        Text(lm.localizedString("Last login"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedLastLogin)
                            .foregroundColor(.primary)
                    }
                    .font(.system(size: 14))

                    Divider().padding(.vertical, 4)

                    Text(lm.localizedString("Active sessions"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.top, 4)

                    if isLoadingSessions {
                        HStack { ProgressView() }
                            .padding(.top, 6)
                            .frame(maxWidth: .infinity)
                    } else if let err = sessionsError, !err.isEmpty {
                        Text(err)
                            .foregroundColor(.red)
                    } else if sessions.isEmpty {
                        Text("—")
                            .foregroundColor(.secondary)
                    } else {
                        #if os(iOS)
                        Group {
                            if hasCurrentSessionToken {
                                sessionSectionTitle(lm.localizedString("This device"))
                                currentDeviceSessionCard
                                if !otherSessions.isEmpty {
                                    sessionSectionTitle(lm.localizedString("Other sessions"))
                                    ForEach(otherSessions, id: \.token) { session in
                                        sessionRow(session)
                                    }
                                }
                            } else {
                                ForEach(sessions, id: \.token) { session in
                                    sessionRow(session)
                                }
                            }
                        }
                        #else
                        ForEach(sessions, id: \.token) { session in
                            sessionRow(session)
                        }
                        #endif
                    }

                    Button {
                        onLogout()
                    } label: {
                        Text(lm.localizedString("Sign out"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(secondarySystemGroupedBackground)
                            .cornerRadius(12)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(groupedBg)
            .navigationTitle(lm.localizedString("Logged in"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.localizedString("Close")) { dismiss() }
                }
            }
        }
        .task(id: username) {
            await loadSessions()
        }
    }

    @ViewBuilder
    private func sessionSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.top, 8)
    }

    #if os(iOS)
    @ViewBuilder
    private var currentDeviceSessionCard: some View {
        let subtitle = currentOnlineSubtitle()
        sessionCardContent(
            iconName: sessionIconName(deviceModelLine: DeviceSessionMetadata.marketingDeviceName),
            title: DeviceSessionMetadata.marketingDeviceName,
            line2: DeviceSessionMetadata.appVersionLine,
            line3: subtitle
        )
    }
    #endif

    private func currentOnlineSubtitle() -> String {
        #if os(iOS)
        // Для текущего устройства не показываем "примерную" страну из региональных настроек ОС,
        // чтобы не вводить пользователя в заблуждение.
        return lm.localizedString("Session online")
        #else
        return ""
        #endif
    }

    private func sessionIconName(deviceModelLine: String) -> String {
        let m = deviceModelLine.lowercased()
        if m.contains("ipad") { return "ipad" }
        if m.contains("mac") || m.contains("simulator") { return "laptopcomputer" }
        return "iphone"
    }

    @ViewBuilder
    private func sessionRow(_ session: AuthSessionFromAPI) -> some View {
        let title = session.deviceModel ?? lm.localizedString("Other device")
        let line2 = session.appVersion ?? "—"
        let line3: String = {
            if let loc = DeviceSessionMetadata.localizedSessionLocationLabel(
                session.locationLabel,
                countryCode: session.locationCountryCode,
                appLocale: lm.currentLocale
            ) {
                return "\(loc) • \(format(session.createdAt))"
            }
            return format(session.createdAt)
        }()
        sessionCardContent(
            iconName: sessionIconName(deviceModelLine: title),
            title: title,
            line2: line2,
            line3: line3
        )
    }

    private func sessionCardContent(iconName: String, title: String, line2: String, line3: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text(line2)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(line3)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let df = DateFormatter()
        df.locale = lm.currentLocale
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func loadSessions() async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              username != "—" else {
            isLoadingSessions = false
            sessions = []
            return
        }
        isLoadingSessions = true
        sessionsError = nil
        do {
            sessions = try await DuelAPIService.shared.fetchAuthSessions(userId: username)
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        } catch {
            let msg = error.localizedDescription
            // Сервер может быть ещё без нового endpoint /api/v1/auth/sessions.
            // В этом случае не показываем красную ошибку пользователю.
            if msg.contains("Cannot GET /api/v1/auth/sessions") || msg.contains("/auth/sessions") {
                sessions = []
                sessionsError = nil
            } else {
                sessionsError = msg
            }
        }
        isLoadingSessions = false
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
