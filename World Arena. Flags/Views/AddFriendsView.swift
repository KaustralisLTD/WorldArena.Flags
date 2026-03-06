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
    
    private var myFriendCode: String {
        if let serverCode = UserDefaults.standard.string(forKey: "user.serverFriendCode"), !serverCode.isEmpty {
            return serverCode
        }
        return friendsService.generateFriendCode(for: userProfile.username)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizationManager.shared.localizedString("Ваш код друга"))) {
                    HStack {
                        Text(myFriendCode)
                            .font(.system(size: 16, weight: .semibold))
                            .textSelection(.enabled)
                        Spacer()
                        Button(action: { UIPasteboard.general.string = myFriendCode; showCopyToast = true }) {
                            Image(systemName: "doc.on.doc")
                        }
                        Button(action: share) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                
                Section(header: Text(LocalizationManager.shared.localizedString("Добавить по коду"))) {
                    TextField(LocalizationManager.shared.localizedString("Введите код друга"), text: $friendCodeToAdd)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                    Button(LocalizationManager.shared.localizedString("Добавить")) {
                        Task { await addFriendByCode() }
                    }
                    .disabled(friendCodeToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingFriend)
                }

                Section(header: Text(LocalizationManager.shared.localizedString("Добавить по имени (логину)"))) {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        TextField(LocalizationManager.shared.localizedString("Login without @"), text: $friendUsernameToAdd)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onChange(of: friendUsernameToAdd) { new in
                                let filtered = new.filter { $0 != "@" }
                                if filtered != new { friendUsernameToAdd = filtered }
                            }
                    }
                    Button(LocalizationManager.shared.localizedString("Добавить")) {
                        Task { await addFriendByUsername() }
                    }
                    .disabled(friendUsernameToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingFriend)
                }

                Section(header: Text(LocalizationManager.shared.localizedString("Ваша страна (флаг в профиле)")), footer: Text(LocalizationManager.shared.localizedString("Выберите страну — её флаг будет отображаться у вас в профиле у друзей."))) {
                    NavigationLink(destination: CountryPickerView(selectedCode: Binding(
                        get: { userProfile.selectedCountryCode },
                        set: { userProfile.selectedCountryCode = $0 }
                    ))) {
                        HStack {
                            if let code = userProfile.selectedCountryCode {
                                Text(FriendsService.countryCodeToFlagEmoji(code))
                                    .font(.system(size: 24))
                                Text(countryName(for: code))
                                    .foregroundColor(.primary)
                            } else {
                                Text(LocalizationManager.shared.localizedString("Не выбрано"))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .onChange(of: userProfile.selectedCountryCode) { newCode in
                Task {
                    await syncSelectedCountryToServer(newCode)
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("Добавить друзей"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showCopyToast {
                    Text(LocalizationManager.shared.localizedString("Скопировано"))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { showCopyToast = false } }
                        }
                }
                
                if showErrorToast {
                    Text(errorMessage)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showErrorToast = false } }
                        }
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
        friendsService.shareProfile(for: userProfile)
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
        .navigationTitle(LocalizationManager.shared.localizedString("Ваша страна"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: LocalizationManager.shared.localizedString("Search"))
    }
}

