import SwiftUI

struct AddFriendsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    @StateObject private var friendsService = FriendsService.shared
    @State private var friendCodeToAdd: String = ""
    @State private var friendUsernameToAdd: String = ""
    @State private var showCopyToast: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAddingFriend: Bool = false

    private var lm: LocalizationManager { LocalizationManager.shared }
    private var myFriendCode: String {
        if let serverCode = UserDefaults.standard.string(forKey: "user.serverFriendCode"), !serverCode.isEmpty {
            return serverCode
        }
        return friendsService.generateFriendCode(for: userProfile.username)
    }

    private var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Ваш код — герой-карточка
                    myCodeCard
                    // Добавить по коду
                    addByCodeCard
                    // Добавить по имени
                    addByUsernameCard
                    // Страна
                    countryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(systemBackground)
            .onChange(of: userProfile.selectedCountryCode) { newCode in
                Task { await syncSelectedCountryToServer(newCode) }
            }
            .navigationTitle(lm.localizedString("Добавить друзей"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .overlay(alignment: .bottom) {
                if showCopyToast {
                    toastView(text: lm.localizedString("Скопировано"), isError: false)
                }
                if showErrorToast {
                    toastView(text: errorMessage, isError: true)
                }
            }
        }
    }

    private var myCodeCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(lm.localizedString("Ваш код друга"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            HStack(spacing: 12) {
                Text(myFriendCode)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .textSelection(.enabled)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: {
                        #if os(iOS)
                        UIPasteboard.general.string = myFriendCode
                        #endif
                        showCopyToast = true
                    }) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Button(action: share) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.cyan)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.4), Color.cyan.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var addByCodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(lm.localizedString("Добавить по коду"), systemImage: "barcode")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            TextField(lm.localizedString("Введите код друга"), text: $friendCodeToAdd)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
            Button(action: { Task { await addFriendByCode() } }) {
                HStack {
                    if isAddingFriend { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    Text(isAddingFriend ? lm.localizedString("Добавляем...") : lm.localizedString("Добавить"))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(friendCodeToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingFriend)
            .opacity(friendCodeToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
    }

    private var addByUsernameCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(lm.localizedString("Add by username"), systemImage: "at")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            HStack(spacing: 0) {
                Text("@")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                TextField(lm.localizedString("Login without @"), text: $friendUsernameToAdd)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .padding(16)
                    .onChange(of: friendUsernameToAdd) { new in
                        let filtered = new.filter { $0 != "@" }
                        if filtered != new { friendUsernameToAdd = filtered }
                    }
            }
            .background(Color(.systemGray6))
            .cornerRadius(14)
            Button(action: { Task { await addFriendByUsername() } }) {
                HStack {
                    if isAddingFriend { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    Text(isAddingFriend ? lm.localizedString("Добавляем...") : lm.localizedString("Добавить"))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.cyan.opacity(0.9), .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(friendUsernameToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingFriend)
            .opacity(friendUsernameToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
    }

    private var countryCard: some View {
        NavigationLink(destination: CountryPickerView(selectedCode: Binding(
            get: { userProfile.selectedCountryCode },
            set: { userProfile.selectedCountryCode = $0 }
        ))) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 48, height: 48)
                    if let code = userProfile.selectedCountryCode {
                        Text(FriendsService.countryCodeToFlagEmoji(code))
                            .font(.system(size: 26))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(lm.localizedString("Ваша страна"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(userProfile.selectedCountryCode.map { countryName(for: $0) } ?? lm.localizedString("Флаг в профиле"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
    }

    private func toastView(text: String, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isError ? Color.red.opacity(0.9) : Color.black.opacity(0.78))
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.bottom, 32)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + (isError ? 2.2 : 1.2)) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if isError { showErrorToast = false } else { showCopyToast = false }
                    }
                }
            }
    }
    
    private func countryName(for code: String) -> String {
        let lang = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        return CountryDatabase.getLocalizedCountryData(for: code, language: lang)?.name
            ?? CountryDatabase.getCountryData(for: code)?.ru.name ?? code
    }

    private func share() {
        friendsService.shareProfile(for: userProfile, friendCode: myFriendCode)
    }

    private func syncSelectedCountryToServer(_ newCode: String?) async {
        guard let code = FriendsService.normalizeCountryCode(newCode), !code.isEmpty else { return }
        let userId = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }
        try? await DuelAPIService.shared.updateMyCountryCode(userId: userId, countryCode: code)
    }
    
    private func addFriendByCode() async {
        guard !isAddingFriend else { return }
        isAddingFriend = true
        defer { isAddingFriend = false }
        let result = await friendsService.addFriend(by: friendCodeToAdd, to: userProfile)
        await MainActor.run {
            switch result {
            case .success:
                friendCodeToAdd = ""
                presentationMode.wrappedValue.dismiss()
            case .alreadyFriends:
                errorMessage = LocalizationManager.shared.localizedString("Этот пользователь уже в друзьях.")
                showErrorToast = true
            case .cannotAddSelf:
                errorMessage = LocalizationManager.shared.localizedString("Нельзя добавить себя.")
                showErrorToast = true
            case .addFailed:
                errorMessage = LocalizationManager.shared.localizedString("Не удалось добавить друга. Проверьте код.")
                showErrorToast = true
            case .userNotFound, .noFriendCode:
                errorMessage = LocalizationManager.shared.localizedString("Не удалось добавить друга. Проверьте код.")
                showErrorToast = true
            }
        }
    }

    private func addFriendByUsername() async {
        guard !isAddingFriend else { return }
        isAddingFriend = true
        defer { isAddingFriend = false }
        let login = friendUsernameToAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = await friendsService.addFriend(byUsername: login, to: userProfile)
        await MainActor.run {
            switch result {
            case .success:
                friendUsernameToAdd = ""
                presentationMode.wrappedValue.dismiss()
            case .userNotFound:
                errorMessage = LocalizationManager.shared.localizedString("Пользователь «\(login)» не найден. Проверьте логин.")
                showErrorToast = true
            case .noFriendCode:
                errorMessage = LocalizationManager.shared.localizedString("У пользователя нет кода друга. Пусть зайдёт в приложение.")
                showErrorToast = true
            case .addFailed:
                errorMessage = LocalizationManager.shared.localizedString("Не удалось добавить в друзья. Попробуйте позже.")
                showErrorToast = true
            case .alreadyFriends:
                errorMessage = LocalizationManager.shared.localizedString("«\(login)» уже в друзьях.")
                showErrorToast = true
            case .cannotAddSelf:
                errorMessage = LocalizationManager.shared.localizedString("Нельзя добавить себя.")
                showErrorToast = true
            }
        }
    }
}

// MARK: - Выбор страны для отображения флага в профиле
struct CountryPickerView: View {
    @Binding var selectedCode: String?
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var searchText: String = ""

    private var sortedCountries: [(code: String, name: String)] {
        let lang = localizationManager.currentLocale.languageCode ?? "en"
        var seen = Set<String>()
        return CountryDatabase.allCountries
            .compactMap { loc -> (code: String, name: String)? in
                let code = loc.ru.code
                guard seen.insert(code).inserted else { return nil }
                let name = CountryDatabase.getLocalizedCountryData(for: code, language: lang)?.name ?? loc.ru.name
                return (code: code, name: name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private var filteredCountries: [(code: String, name: String)] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sortedCountries }
        return sortedCountries.filter {
            $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Поиск сверху страницы
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(LocalizationManager.shared.localizedString("Search"), text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            List {
                ForEach(filteredCountries, id: \.code) { item in
                    Button(action: {
                        selectedCode = FriendsService.normalizeCountryCode(item.code) ?? item.code
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(FriendsService.countryCodeToFlagEmoji(item.code))
                                .font(.system(size: 28))
                            Text(item.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCode == item.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(LocalizationManager.shared.localizedString("Ваша страна"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

