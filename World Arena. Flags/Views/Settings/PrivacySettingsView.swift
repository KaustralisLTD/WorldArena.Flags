import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PrivacySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var profileVisibility = true
    @State private var statisticsVisibility = true
    @State private var friendRequestsEnabled = true
    @State private var dataCollection = false
    @State private var crashReports = true
    @State private var showingDataPolicy = false
    @State private var showingTerms = false
    
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
                    // Profile privacy
                    settingsSection(title: LocalizationManager.shared.localizedString("Приватность профиля")) {
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Публичный профиль"),
                            icon: "person.circle",
                            isOn: $profileVisibility
                        )
                        
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Показывать статистику"),
                            icon: "chart.bar",
                            isOn: $statisticsVisibility
                        )
                        
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Заявки в друзья"),
                            icon: "person.badge.plus",
                            isOn: $friendRequestsEnabled
                        )
                    }
                    
                    // Data collection
                    settingsSection(title: LocalizationManager.shared.localizedString("Сбор данных")) {
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Аналитика использования"),
                            icon: "chart.pie",
                            isOn: $dataCollection
                        )
                        
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Отчеты о сбоях"),
                            icon: "exclamationmark.triangle",
                            isOn: $crashReports
                        )
                    }
                    
                    // Data management
                    settingsSection(title: LocalizationManager.shared.localizedString("Управление данными")) {
                        SettingsActionRow(
                            title: LocalizationManager.shared.localizedString("Политика конфиденциальности"),
                            subtitle: LocalizationManager.shared.localizedString("Ознакомьтесь с нашей политикой конфиденциальности"),
                            icon: "doc.text"
                        ) {
                            showingDataPolicy = true
                        }
                        
                        SettingsActionRow(
                            title: LocalizationManager.shared.localizedString("Условия использования"),
                            subtitle: LocalizationManager.shared.localizedString("Прочитайте наши условия использования"),
                            icon: "doc.plaintext"
                        ) {
                            showingTerms = true
                        }
                        
                        SettingsActionRow(
                            title: LocalizationManager.shared.localizedString("Экспорт данных"),
                            subtitle: LocalizationManager.shared.localizedString("Скачать копию ваших данных"),
                            icon: "square.and.arrow.up"
                        ) {
                            exportUserData()
                        }
                        
                        SettingsActionRow(
                            title: LocalizationManager.shared.localizedString("Удалить все данные"),
                            subtitle: LocalizationManager.shared.localizedString("Безвозвратно удалить все ваши данные"),
                            icon: "trash",
                            isDestructive: true
                        ) {
                            deleteAllUserData()
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Приватность"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        savePrivacySettings()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        savePrivacySettings()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #endif
            }
            .sheet(isPresented: $showingDataPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTerms) {
                TermsOfServiceView()
            }
        }
        .onAppear {
            loadPrivacySettings()
        }
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
    
    private func loadPrivacySettings() {
        profileVisibility = UserDefaults.standard.bool(forKey: "profileVisibility")
        statisticsVisibility = UserDefaults.standard.bool(forKey: "statisticsVisibility")
        friendRequestsEnabled = UserDefaults.standard.bool(forKey: "friendRequestsEnabled")
        dataCollection = UserDefaults.standard.bool(forKey: "dataCollection")
        crashReports = UserDefaults.standard.bool(forKey: "crashReports")
    }
    
    private func savePrivacySettings() {
        UserDefaults.standard.set(profileVisibility, forKey: "profileVisibility")
        UserDefaults.standard.set(statisticsVisibility, forKey: "statisticsVisibility")
        UserDefaults.standard.set(friendRequestsEnabled, forKey: "friendRequestsEnabled")
        UserDefaults.standard.set(dataCollection, forKey: "dataCollection")
        UserDefaults.standard.set(crashReports, forKey: "crashReports")
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func exportUserData() {
        // Создать и экспортировать данные пользователя
        let userData = """
        World Arena Flags - Экспорт данных пользователя
        
        Профиль:
        - Имя: \(UserProfile.shared.username)
        - Уровень: \(UserProfile.shared.level)
        - Опыт: \(UserProfile.shared.xp)
        - Серия: \(UserProfile.shared.streak)
        - Лига: \(UserProfile.shared.currentLeague.rawValue)
        
        Статистика:
        - Всего игр: \(UserProfile.shared.totalGamesPlayed)
        - Правильных ответов: \(UserProfile.shared.correctAnswers)
        - Точность: \(String(format: "%.1f%%", UserProfile.shared.accuracy))
        
        Дата экспорта: \(Date())
        """
        
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [userData], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        #else
        print("Export not available on macOS")
        #endif
    }
    
    private func deleteAllUserData() {
        #if os(iOS)
        // Показать подтверждение удаления
        let alert = UIAlertController(
            title: LocalizationManager.shared.localizedString("Удалить все данные"),
            message: LocalizationManager.shared.localizedString("Это действие нельзя отменить. Все ваши достижения, статистика и настройки будут удалены навсегда."),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LocalizationManager.shared.localizedString("Отмена"), style: .cancel))
        alert.addAction(UIAlertAction(title: LocalizationManager.shared.localizedString("Удалить"), style: .destructive) { _ in
            // Удалить все данные пользователя
            UserDefaults.standard.removeObject(forKey: "profileVisibility")
            UserDefaults.standard.removeObject(forKey: "statisticsVisibility")
            UserDefaults.standard.removeObject(forKey: "friendRequestsEnabled")
            UserDefaults.standard.removeObject(forKey: "dataCollection")
            UserDefaults.standard.removeObject(forKey: "crashReports")
            
            // Сбросить профиль пользователя
            let userProfile = UserProfile.shared
            userProfile.username = LocalizationManager.shared.localizedString("Player")
            userProfile.level = 1
            userProfile.xp = 0
            userProfile.streak = 0
            userProfile.totalGamesPlayed = 0
            userProfile.correctAnswers = 0
            userProfile.totalAnswers = 0
            userProfile.achievements.removeAll()
            userProfile.friends.removeAll()
            
            self.presentationMode.wrappedValue.dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
        #else
        // Для macOS просто удаляем данные без подтверждения
        UserDefaults.standard.removeObject(forKey: "profileVisibility")
        UserDefaults.standard.removeObject(forKey: "statisticsVisibility")
        UserDefaults.standard.removeObject(forKey: "friendRequestsEnabled")
        UserDefaults.standard.removeObject(forKey: "dataCollection")
        UserDefaults.standard.removeObject(forKey: "crashReports")
        
        let userProfile = UserProfile.shared
        userProfile.username = LocalizationManager.shared.localizedString("Player")
        userProfile.level = 1
        userProfile.xp = 0
        userProfile.streak = 0
        userProfile.totalGamesPlayed = 0
        userProfile.correctAnswers = 0
        userProfile.totalAnswers = 0
        userProfile.achievements.removeAll()
        userProfile.friends.removeAll()
        
        presentationMode.wrappedValue.dismiss()
        #endif
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isDestructive = isDestructive
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
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(secondarySystemGroupedBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    PrivacySettingsView()
}
