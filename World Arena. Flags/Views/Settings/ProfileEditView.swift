import SwiftUI
#if os(iOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
private struct ProfilePhotoCropIdent: Identifiable {
    let id = UUID()
    let image: UIImage
}
#endif

struct ProfileEditView: View {
    static let maxUsernameLength = 25

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var gameState: GameState
    @State private var tempUsername: String = ""
    @State private var selectedAvatar: String = "person.circle.fill"
    @State private var tempBirthday: Date? = nil
    @State private var showingAvatarEditor = false
    #if os(iOS)
    @State private var photoCropIdent: ProfilePhotoCropIdent?
    #endif
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

    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    private var birthdayDisplayFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = localizationManager.currentLocale
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar selection
                    VStack(spacing: 16) {
                        Text(LocalizationManager.shared.localizedString("Выберите аватар"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Button {
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            #endif
                            scheduleAvatarEditorPresentation()
                        } label: {
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
                                        .clipped()
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
                            .frame(width: 100, height: 100)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(LocalizationManager.shared.localizedString("Редактировать аватар"))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                        #if os(iOS)
                        if #available(iOS 16.0, *) {
                            ProfileEditPhotoPickSection(
                                localizationManager: localizationManager,
                                openAvatarEditor: scheduleAvatarEditorPresentation,
                                photoCropIdent: $photoCropIdent
                            )
                        } else {
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                scheduleAvatarEditorPresentation()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                    Text(localizationManager.localizedString("Редактировать аватар"))
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
                            .buttonStyle(.plain)
                        }
                        #else
                        Button(action: {
                            showingAvatarEditor = true
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
                        #endif
                    }
                    .padding(.horizontal, 20)
                    
                    profileInputCard(
                        icon: "person.text.rectangle.fill",
                        title: LocalizationManager.shared.localizedString("Имя пользователя")
                    ) {
                        TextField(LocalizationManager.shared.localizedString("Введите имя"), text: $tempUsername)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .onChange(of: tempUsername) { newValue in
                                if newValue.count > Self.maxUsernameLength {
                                    tempUsername = String(newValue.prefix(Self.maxUsernameLength))
                                }
                            }
                        Text("\(tempUsername.count)/\(Self.maxUsernameLength)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)

                    profileInputCard(
                        icon: "gift.fill",
                        title: LocalizationManager.shared.localizedString("День рождения")
                    ) {
                        Text(LocalizationManager.shared.localizedString("Birthday description F-bucks"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { tempBirthday ?? Calendar.current.date(bySetting: .day, value: 1, of: Date()) ?? Date() },
                                set: { tempBirthday = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .environment(\.locale, localizationManager.currentLocale)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let birthday = tempBirthday {
                            HStack {
                                Text(birthdayDisplayFormatter.string(from: birthday))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(LocalizationManager.shared.localizedString("Очистить")) {
                                    tempBirthday = nil
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    profileInputCard(
                        icon: "chart.bar.xaxis",
                        title: LocalizationManager.shared.localizedString("Статистика")
                    ) {
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
            tempBirthday = userProfile.birthday
        }
        #if os(iOS)
        .fullScreenCover(item: $photoCropIdent) { item in
            Group {
                if #available(iOS 16.0, *) {
                    ProfilePhotoCropSheet(
                        image: item.image,
                        onCancel: { photoCropIdent = nil },
                        onComplete: { data in
                            userProfile.customAvatarImageData = data
                            userProfile.avatar = "custom_photo"
                            userProfile.saveToStorage()
                            photoCropIdent = nil
                            let uid = userProfile.username
                            Task {
                                try? await DuelAPIService.shared.updateMyCustomPhoto(userId: uid, imageData: data)
                            }
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }
                    )
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .onAppear { photoCropIdent = nil }
                }
            }
        }
        #endif
        .sheet(isPresented: $showingAvatarEditor) {
            AvatarEditorView()
                .environmentObject(userProfile)
                .environmentObject(gameState)
        }
    }

    /// После fullScreenCover (кроп фото) и из‑за порядка модификаторов прямой sheet иногда не открывается — откладываем на следующий цикл runloop.
    private func scheduleAvatarEditorPresentation() {
        DispatchQueue.main.async {
            showingAvatarEditor = true
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
        userProfile.birthday = tempBirthday
        userProfile.saveToStorage()
        userProfile.checkAndAwardBirthdayBonusIfNeeded()
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

    private func profileInputCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#if os(iOS)
@available(iOS 16.0, *)
@MainActor
private struct ProfileEditPhotoPickSection: View {
    @ObservedObject var localizationManager: LocalizationManager
    let openAvatarEditor: () -> Void
    @Binding var photoCropIdent: ProfilePhotoCropIdent?
    @State private var photoPickerItem: PhotosPickerItem?

    private var titleEditAvatar: String {
        localizationManager.localizedString("Редактировать аватар")
    }

    var body: some View {
        let uploadPhotoTitle = localizationManager.localizedString("profile_upload_photo")
        HStack(spacing: 12) {
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                openAvatarEditor()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 17, weight: .semibold))
                    Text(titleEditAvatar)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.35, green: 0.45, blue: 1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.45), .cyan.opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
            }
            .buttonStyle(.plain)

            PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 17, weight: .semibold))
                    Text(uploadPhotoTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.28, blue: 0.95),
                                    Color(red: 0.25, green: 0.45, blue: 1),
                                    Color(red: 0.2, green: 0.75, blue: 0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .purple.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
        .onChange(of: photoPickerItem) { newItem in
            guard let newItem else { return }
            Task {
                await loadPickedItem(newItem)
            }
        }
    }

    private func loadPickedItem(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            photoCropIdent = ProfilePhotoCropIdent(image: ui)
            photoPickerItem = nil
        }
    }
}
#endif

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
        .environmentObject(GameState())
}
