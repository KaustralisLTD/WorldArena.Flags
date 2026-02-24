import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var dailyReminders = true
    @State private var streakReminders = true
    @State private var achievementNotifications = true
    @State private var leagueNotifications = true
    @State private var friendsNotifications = false
    @State private var reminderTime = Date()
    
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
                    // Main toggle
                    settingsSection(title: LocalizationManager.shared.localizedString("Основные уведомления")) {
                        SettingsToggleRow(
                            title: LocalizationManager.shared.localizedString("Уведомления"),
                            icon: "bell",
                            isOn: $notificationsEnabled
                        )
                    }
                    
                    if notificationsEnabled {
                        // Game reminders
                        settingsSection(title: LocalizationManager.shared.localizedString("Напоминания об игре")) {
                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Ежедневные напоминания"),
                                icon: "calendar",
                                isOn: $dailyReminders
                            )
                            
                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Напоминания о серии"),
                                icon: "flame",
                                isOn: $streakReminders
                            )
                        }
                        
                        // Reminder time
                        if dailyReminders {
                            settingsSection(title: LocalizationManager.shared.localizedString("Время напоминания")) {
                                DatePicker(
                                    LocalizationManager.shared.localizedString("Время"),
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                #if os(iOS)
                                .datePickerStyle(.wheel)
                                #endif
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Achievement notifications
                        settingsSection(title: LocalizationManager.shared.localizedString("Достижения и прогресс")) {
                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Достижения"),
                                icon: "trophy",
                                isOn: $achievementNotifications
                            )
                            
                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Лиги"),
                                icon: "crown",
                                isOn: $leagueNotifications
                            )
                        }
                        
                        // Social notifications
                        settingsSection(title: LocalizationManager.shared.localizedString("Социальные уведомления")) {
                            SettingsToggleRow(
                                title: LocalizationManager.shared.localizedString("Друзья"),
                                icon: "person.2",
                                isOn: $friendsNotifications
                            )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Уведомления"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        saveSettings()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        saveSettings()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #endif
            }
        }
        .onAppear {
            loadCurrentSettings()
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
    
    private func loadCurrentSettings() {
        // Загрузить текущие настройки из UserDefaults или другого хранилища
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func saveSettings() {
        // Сохранить настройки
        if notificationsEnabled {
            requestNotificationPermission()
        }
        
        // Сохранить в UserDefaults
        UserDefaults.standard.set(dailyReminders, forKey: "dailyReminders")
        UserDefaults.standard.set(streakReminders, forKey: "streakReminders")
        UserDefaults.standard.set(achievementNotifications, forKey: "achievementNotifications")
        UserDefaults.standard.set(leagueNotifications, forKey: "leagueNotifications")
        UserDefaults.standard.set(friendsNotifications, forKey: "friendsNotifications")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // Настроить локальные уведомления
                scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        // Запланировать уведомления на основе настроек пользователя
        if dailyReminders {
            let content = UNMutableNotificationContent()
            content.title = LocalizationManager.shared.localizedString("World Arena Flags")
            content.body = LocalizationManager.shared.localizedString("Время изучать флаги! Не забудьте поддержать свою серию 🔥")
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}



#Preview {
    NotificationSettingsView()
}
