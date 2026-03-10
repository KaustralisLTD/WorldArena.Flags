import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ProfileEditView: View {
    static let maxUsernameLength = 25

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    @State private var tempUsername: String = ""
    @State private var selectedAvatar: String = "person.circle.fill"
    @State private var showingAvatarEditor = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private let availableAvatars = [
        "person.circle.fill",
        "face.smiling",
        "face.dashed",
        "graduationcap.fill",
        "crown.fill",
        "star.fill",
        "heart.fill",
        "gamecontroller.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar selection
                    VStack(spacing: 16) {
                        Text(LocalizationManager.shared.localizedString("Выберите аватар"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            #if os(iOS)
                            if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: selectedAvatar)
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                            #else
                            Image(systemName: selectedAvatar)
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            #endif
                        }
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Button(action: {
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            #endif
                            DispatchQueue.main.async {
                                showingAvatarEditor = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                Text(LocalizationManager.shared.localizedString("Редактировать аватар"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Username edit
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationManager.shared.localizedString("Имя пользователя"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField(LocalizationManager.shared.localizedString("Введите имя"), text: $tempUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16))
                            .onChange(of: tempUsername) { newValue in
                                if newValue.count > Self.maxUsernameLength {
                                    tempUsername = String(newValue.prefix(Self.maxUsernameLength))
                                }
                            }
                        Text("\(tempUsername.count)/\(Self.maxUsernameLength)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Stats (read-only)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationManager.shared.localizedString("Статистика"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            StatRow(title: LocalizationManager.shared.localizedString("Уровень"), value: "\(userProfile.level)")
                            StatRow(title: LocalizationManager.shared.localizedString("Опыт"), value: "\(userProfile.xp) XP")
                            StatRow(title: LocalizationManager.shared.localizedString("Серия дней"), value: "\(userProfile.streak)")
                            StatRow(title: LocalizationManager.shared.localizedString("Всего игр"), value: "\(userProfile.totalGamesPlayed)")
                            StatRow(title: LocalizationManager.shared.localizedString("Точность"), value: String(format: "%.1f%%", userProfile.accuracy))
                            StatRow(title: LocalizationManager.shared.localizedString("Текущая лига"), value: userProfile.currentLeague.localizedName)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Профиль"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString("Отмена")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Сохранить")) {
                        saveProfile()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.localizedString("Отмена")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationManager.shared.localizedString("Сохранить")) {
                        saveProfile()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #endif
            }
        }
        .onAppear {
            tempUsername = userProfile.username
            selectedAvatar = userProfile.avatar
        }
        .sheet(isPresented: $showingAvatarEditor) {
            AvatarEditorView()
                .environmentObject(userProfile)
        }
    }
    
    private func saveProfile() {
        let trimmed = String(tempUsername.prefix(Self.maxUsernameLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = trimmed.isEmpty ? LocalizationManager.shared.localizedString("Player") : trimmed
        userProfile.username = newName
        // сохраняем только если выбран системный значок; кастомное фото оставляем
        if userProfile.avatar != "custom_photo" {
            userProfile.avatar = selectedAvatar
        }
        userProfile.saveToStorage()
        // Обновить отображаемое имя на сервере — у друзей при следующей загрузке списка будет новое имя
        Task {
            _ = try? await DuelAPIService.shared.updateMyDisplayName(userId: userProfile.username, displayName: newName)
        }
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        presentationMode.wrappedValue.dismiss()
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(UserProfile.shared)
}
