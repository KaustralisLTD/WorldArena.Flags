import SwiftUI
import CoreImage.CIFilterBuiltins
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var gameState: GameState
    @State private var showingSettings = false
    @State private var showingShareSheet = false
    @State private var verifiedProfileShareURL: URL?
    @State private var profileShareFailed = false
    /// Редактирование профиля (имя, день рождения, аватар) — тап по аватарке в шапке.
    @State private var showingUserProfileEdit = false
    @State private var showFullNameAlert = false
    #if os(iOS)
    @State private var profileCardImage: UIImage?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #else
    @State private var profileCardImage: NSImage?
    #endif
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.sizeCategory) private var sizeCategory
    @Binding var selectedTab: Int
    @State private var lightweightFriendsSyncTask: Task<Void, Never>?
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return false
        #endif
    }
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var systemGray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
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
        ZStack(alignment: .top) {
            // Базовый фон
            systemGroupedBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        profileHero
                            .background(profileGradient.ignoresSafeArea(.container, edges: .top))
                        VStack(spacing: 24) {
                            statisticsSection
                            overviewSection
                            FriendRequestsEntry()
                            addFriendsButton.appGuideTarget("friends")
                            AppGuideReplay()
                            CountryFactsSettingsEntry()
                            monthlyBadgesSection
                        }
                        .frame(maxWidth: 1040)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 32)
                }
                .overlay(alignment: .top) {
                    profileGradient
                        .frame(height: geometry.safeAreaInsets.top)
                        .offset(y: -geometry.safeAreaInsets.top)
                        .allowsHitTesting(false)
                }
                .accessibilityIdentifier("profile.scroll")
                .refreshable { await refreshProfileData() }
                .modifier(ProfileHideScrollContentBackgroundModifier())
            }
        }
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        #endif
            .onAppear {
                // Прозрачный навбар и без тени
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                // Дополнительно скрываем кнопку "Назад" для iOS 15.6
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
                    }
                }
                #endif
                userProfile.evaluateAchievementsAndUnlock()
                Task { await refreshProfileData() }
                startLightweightFriendsSync()
            }
            .onDisappear {
                lightweightFriendsSyncTask?.cancel()
                lightweightFriendsSyncTask = nil
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .sheetOrFullScreenOnIPad(isPresented: $showingSettings) {
                SettingsView()
            }
            #if os(iOS)
            .sheetOrFullScreenOnIPad(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: profileShareActivityItems)
            }
            .sheetOrFullScreenOnIPad(isPresented: $showingUserProfileEdit) {
                ProfileEditView()
                    .environmentObject(userProfile)
                    .environmentObject(gameState)
            }
            #endif
            .alert(localizationManager.localizedString("Server Error"), isPresented: $profileShareFailed) {
                Button(localizationManager.localizedString("OK"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("Server error. Try again."))
            }
            .alert(localizationManager.localizedString("Name"), isPresented: $showFullNameAlert) {
                Button(localizationManager.localizedString("Close"), role: .cancel) { }
            } message: {
                Text(userProfile.username)
            }
    }

    private func startLightweightFriendsSync() {
        lightweightFriendsSyncTask?.cancel()
        lightweightFriendsSyncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                if Task.isCancelled { break }
                await refreshFriendsLightweight()
            }
        }
    }

    // Старый блок хедера больше не используется
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            Text(LocalizationManager.shared.localizedString("ОБЗОР"))
                .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, isIPad ? 40 : 20)
            
            VStack(spacing: isIPad ? 16 : 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: sizeCategory.isAccessibilityCategory ? 1 : (isIPad ? 4 : 2)), spacing: 12) {
                StatisticRow(icon: "", iconImageName: "StatDayStreak", systemImageName: "flame.fill", title: "\(userProfile.streak) " + LocalizationManager.shared.localizedString("дней"), subtitle: LocalizationManager.shared.localizedString("Текущая серия"), isIPad: isIPad)
                    .modifier(StreakCalendarLink())
                StatisticRow(icon: "", systemImageName: "flag.checkered", title: "\(userProfile.totalGamesPlayed)", subtitle: localizationManager.localizedString("Всего игр"), isIPad: isIPad)
                StatisticRow(icon: "", systemImageName: "scope", title: "\(Int(userProfile.accuracy))%", subtitle: localizationManager.localizedString("Accuracy"), isIPad: isIPad)
                Button { showingAddFriends = true } label: {
                    StatisticRow(icon: "", systemImageName: "person.2.fill", title: "\(userProfile.friends.count)", subtitle: localizationManager.localizedString("Following"), isIPad: isIPad)
                }
                .buttonStyle(.plain)
                
                }

                // Глобальный рейтинг по странам и миру (мотивационный блок)
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("ranking.motivational.title"))
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button(action: { showingCountryPicker = true }) {
                        HStack(spacing: 8) {
                            Text(countryRankLine(code: userProfile.selectedCountryCode ?? "US"))
                                .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                                .foregroundColor(.blue.opacity(0.85))
                        }
                    }
                    .buttonStyle(.plain)
                    Text(LocalizationManager.shared.localizedString("ranking.motivational.explanation"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(worldRankLine())
                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(secondarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isIPad && !sizeCategory.isAccessibilityCategory ? 2 : 1), spacing: 12) {
                // Navigation destinations
                profileOverviewCard(
                    iconName: "IconWorldProgressMap",
                    title: LocalizationManager.shared.localizedString("Карта прогресса мира"),
                    subtitle: LocalizationManager.shared.localizedString("Progress map subtitle"),
                    destination: { WorldProgressMapView().environmentObject(gameState) }
                )
                profileOverviewCard(
                    iconName: "IconDuelSummary",
                    title: LocalizationManager.shared.localizedString("Duel Summary"),
                    subtitle: LocalizationManager.shared.localizedString("Duel Summary subtitle"),
                    destination: { DuelSummaryView().environmentObject(gameState).environmentObject(userProfile) }
                )
                profileOverviewCard(
                    iconName: "IconStatistics",
                    title: LocalizationManager.shared.localizedString("Статистика"),
                    subtitle: LocalizationManager.shared.localizedString("Accuracy") + " · " + LocalizationManager.shared.localizedString("Best Score"),
                    destination: { StatisticsView(isPushedFromProfile: true) }
                )
                // F-Bucks в том же формате карточки, по тапу — страница о F-Bucks
                profileOverviewCardFBucks()
                }
            }
            .padding(.horizontal, isIPad ? 40 : 20)
        }
    }

    /// Размер миниатюры в карточках (чуть уменьшен, чтобы визуально не доминировать)
    private var profileCardIconSize: (w: CGFloat, h: CGFloat) { isIPad ? (48, 48) : (42, 42) }

    /// Карточка одного размера для World Progress Map / Duel Summary / Statistics
    private func profileOverviewCard<Destination: View>(
        iconName: String,
        title: String,
        subtitle: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                ProfileFeatureIcon(name: iconName)
                    .frame(width: profileCardIconSize.w, height: profileCardIconSize.h)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(isIPad ? 16 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isIPad ? 84 : 74)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(secondarySystemGroupedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Карточка F-Bucks в том же формате, по тапу — sheet о F-Bucks
    private func profileOverviewCardFBucks() -> some View {
        Button(action: { showingFBucksInfo = true }) {
            HStack(spacing: 14) {
                Image("FBucksLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: profileCardIconSize.w, height: profileCardIconSize.h)
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("F-Bucks"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(LocalizationManager.shared.localizedString("F-Bucks subtitle"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(isIPad ? 16 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isIPad ? 84 : 74)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(secondarySystemGroupedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @State private var showingAddFriends = false
    @State private var showingFBucksInfo = false
    @State private var showingCountryPicker = false

    private var addFriendsButton: some View {
        Button(action: {
            showingAddFriends = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                Text(LocalizationManager.shared.localizedString("ДОБАВИТЬ ДРУЗЕЙ"))
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
            }
            .foregroundColor(.indigo)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.indigo.opacity(0.08))
            .cornerRadius(isIPad ? 16 : 12)
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                    .stroke(Color.indigo.opacity(0.10), lineWidth: 1)
            )
        }
        .padding(.horizontal, isIPad ? 40 : 20)
        .sheetOrFullScreenOnIPad(isPresented: $showingFBucksInfo) {
            FBucksInfoView()
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingAddFriends) {
            AddFriendsView()
                .environmentObject(userProfile)
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingCountryPicker) {
            NavigationView {
                CountryPickerView(selectedCode: Binding(
                    get: { userProfile.selectedCountryCode },
                    set: { userProfile.selectedCountryCode = $0 }
                ))
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("СЕРИИ ДРУЗЕЙ"))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, isIPad ? 40 : 20)
            
            if userProfile.friends.isEmpty {
                VStack(spacing: 6) { // Сделали еще более компактно
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 24)) // Уменьшили размер иконки
                        .foregroundColor(.secondary)
                    Text(LocalizationManager.shared.localizedString("У вас пока нет друзей"))
                        .font(.system(size: 14, weight: .medium)) // Уменьшили размер текста
                        .foregroundColor(.secondary)
                    Text(LocalizationManager.shared.localizedString("Добавьте друзей, чтобы видеть их серии"))
                        .font(.system(size: 12)) // Уменьшили размер текста
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) // Сделали еще более компактно
                .padding(.horizontal, isIPad ? 40 : 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(userProfile.friends, id: \.id) { friend in
                            NavigationLink(destination: FriendProfileView(friend: friend, gameState: gameState)) {
                                FriendStreakCard(friend: friend, isPlaceholder: false)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                }
            }
        }
    }
    
    private var friendStreaksSection: some View {
        EmptyView() // Already included in overviewSection
    }
    
    private var monthlyBadgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink(destination: AchievementsView().environmentObject(userProfile)) {
                HStack {
                    Text(LocalizationManager.shared.localizedString("МЕСЯЧНЫЕ ДОСТИЖЕНИЯ"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    // Только открытые достижения (до 4 шт.), цветные
                    ForEach(Array(userProfile.allAchievementDefinitions.filter { userProfile.isAchievementUnlocked(id: $0.id) }.prefix(4)), id: \.id) { achievementDef in
                        MonthlyBadge(
                            definition: achievementDef,
                            title: LocalizationManager.shared.localizedString(achievementDef.titleKey),
                            isUnlocked: true
                        )
                    }
                }
                .padding(.horizontal, isIPad ? 40 : 20)
            }
        }
    }
}

extension ProfileView {
    /// Аватар с бейджем лиги в правом верхнем углу. Квадрат с закруглением.
    private func profileAvatarWithLeagueBadge(size: CGFloat, innerSize: CGFloat) -> some View {
        let cornerRadius = size * 0.22
        let avatarPlate = ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: cornerRadius - 2)
                    .fill(Color.white)
                    .frame(width: size - 4, height: size - 4)
                #if os(iOS)
                if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: innerSize, height: innerSize)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 4))
                } else if userProfile.avatar.starts(with: "custom_") {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: userProfile.avatar)
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.blue)
                }
                #else
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.secondary)
                #endif
        }
        .contentShape(Rectangle())
        return ZStack(alignment: .topTrailing) {
            avatarPlate
            Image(userProfile.currentLeague.imageAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: max(32, size * 0.22), height: max(32, size * 0.22))
                .background(Circle().fill(Color.blue))
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: 4, y: -4)
        }
    }

    private var profileGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.13, green: 0.32, blue: 0.86), Color(red: 0.32, green: 0.22, blue: 0.75)],
                       startPoint: .leading, endPoint: .trailing)
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Text(localizationManager.localizedString("Профиль"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer(minLength: 8)
                Button(action: shareProfile) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .accessibilityLabel(localizationManager.localizedString("Share Result"))
                .accessibilityIdentifier("profile.share")
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .accessibilityLabel(localizationManager.localizedString("Settings"))
                .accessibilityIdentifier("profile.settings")
            }
            if isIPad && horizontalSizeClass == .regular && !sizeCategory.isAccessibilityCategory {
                HStack(spacing: 24) {
                    heroAvatar
                    heroIdentity
                    heroLeagueStatus.frame(width: 280)
                }
            } else {
                if sizeCategory.isAccessibilityCategory {
                    heroAvatar
                    heroIdentity
                } else {
                    HStack(alignment: .center, spacing: 20) {
                        heroAvatar
                        heroIdentity
                    }
                }
                heroLeagueStatus
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, isIPad ? 40 : 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(maxWidth: 1040)
        .frame(maxWidth: .infinity)
    }

    private var heroLeagueStatus: some View {
        Button {
            selectedTab = gameState.isPremium ? 3 : 2
        } label: {
        Group {
            if sizeCategory.isAccessibilityCategory {
                VStack(alignment: .leading, spacing: 12) {
                    Image(userProfile.currentLeague.imageAssetName)
                        .resizable().scaledToFit().frame(width: 38, height: 38)
                    Text(userProfile.currentLeague.localizedFullName)
                        .font(.subheadline.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(userProfile.xp) XP")
                        .font(.subheadline).monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    Image(userProfile.currentLeague.imageAssetName)
                        .resizable().scaledToFit().frame(width: 38, height: 38)
                    Text(userProfile.currentLeague.localizedFullName)
                        .font(.subheadline.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .accessibilityHidden(true)
                    Text("\(userProfile.xp) XP")
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.league")
        .accessibilityHint(localizationManager.localizedString("home.goal.open_league"))
    }

    private var heroAvatar: some View {
        Button { showingUserProfileEdit = true } label: {
            profileAvatarWithLeagueBadge(size: isIPad ? 104 : 84, innerSize: isIPad ? 94 : 74)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.indigo)
                        .frame(width: 26, height: 26)
                        .background(.white, in: Circle())
                        .offset(x: 5, y: 5)
                }
        }
        .accessibilityLabel(localizationManager.localizedString("Редактировать аватар"))
        .accessibilityIdentifier("profile.avatar")
    }

    private var heroIdentity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(userProfile.username)
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("profile.name")
            Text("@\(userProfile.username)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1).truncationMode(.middle)
            Text(profileJoinDateText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("profile.joinDate")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Share Profile Functions
extension ProfileView {
    // MARK: - Professional ranking model (country + world)
    // Позиция зависит от качества профиля и оценочного размера активной аудитории:
    // население страны * смартфоны * доля мобильных игроков * доля онлайн-игроков.
    /// Локализованный формат **Country rank line**: аргументы строго в порядке **флаг (String), ранг (Int), страна (String)** → плейсхолдеры `%@`, `%d` или `%lld`, `%@` (как в `en`: «%@ You are #%d in %@»).
    fileprivate func countryRankLine(code: String) -> String {
        let upper = code.uppercased()
        let flag = FriendsService.countryCodeToFlagEmoji(upper)
        let rank = MotivationalRanking.countryRank(for: userProfile.motivationalRankInputs(league: userProfile.currentLeague), countryCode: upper)
        let format = LocalizationManager.shared.localizedString("Country rank line")
        return String(format: format, flag, rank, LocalizationManager.shared.localizedString(countryNameByCode(upper)))
    }

    fileprivate func worldRankLine() -> String {
        let rank = MotivationalRanking.worldRank(for: userProfile.motivationalRankInputs(league: userProfile.currentLeague))
        let format = LocalizationManager.shared.localizedString("World rank line")
        return String(format: format, rank)
    }

    private func countryNameByCode(_ code: String) -> String {
        let upper = code.uppercased()
        let lang = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        return CountryDatabase.getLocalizedCountryData(for: upper, language: lang)?.name
            ?? CountryDatabase.getCountryData(for: upper)?.ru.name
            ?? upper
    }

    @MainActor
    fileprivate func refreshProfileData() async {
        let userId = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }

        if let selfRow = try? await DuelAPIService.shared.fetchUserByUsername(userId) {
            userProfile.serverWorldRank = selfRow.worldRank
        }

        if let apiFriends = try? await DuelAPIService.shared.fetchMyFriends(userId: userId) {
            // Дедупликация по username, чтобы не крашить при Dictionary(uniqueKeysWithValues:) и двойных друзьях
            var seenUsernames = Set<String>()
            let uniqueExisting = userProfile.friends.filter { seenUsernames.insert($0.username.lowercased()).inserted }
            let oldByUsername = Dictionary(uniqueKeysWithValues: uniqueExisting.map { ($0.username, $0) })
            var result: [Friend] = []
            var seenApi = Set<String>()
            for api in apiFriends {
                guard seenApi.insert(api.username.lowercased()).inserted else { continue }
                let mapped = api.toFriend()
                if let old = oldByUsername[api.username] {
                    result.append(Friend(
                        id: old.id,
                        username: mapped.username,
                        displayName: api.displayName ?? mapped.displayName,
                        avatar: mapped.avatar,
                        avatarPhotoBase64: mapped.avatarPhotoBase64 ?? old.avatarPhotoBase64,
                        countryCode: mapped.countryCode,
                        level: mapped.level,
                        xp: mapped.xp,
                        streak: mapped.streak,
                        totalGamesPlayed: mapped.totalGamesPlayed,
                        correctAnswers: mapped.correctAnswers,
                        isOnline: old.isOnline,
                        joinDate: api.joinDateFromServer ?? old.joinDate,
                        playedToday: mapped.playedToday,
                        birthday: mapped.birthday ?? old.birthday,
                        achievements: mapped.achievements,
                        worldRankFromServer: mapped.worldRankFromServer
                    ))
                } else {
                    result.append(mapped)
                }
            }
            userProfile.friends = result
        }

        if let incoming = try? await DuelAPIService.shared.fetchIncomingChallenges(userId: userId) {
            userProfile.reconcileIncomingDuelInvites(incoming.compactMap { $0.toDuelChallenge(opponentId: userId, opponentName: userId) })
        }

        // Лёгкий тик лиги и переоценка достижений, чтобы карточки на профиле были актуальны.
        LeaguesService.shared.tickCompetitors(for: userProfile.currentLeague)
        userProfile.evaluateAchievementsAndUnlock()
        userProfile.saveToStorage()
    }

    @MainActor
    private func refreshFriendsLightweight() async {
        let userId = userProfile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }
        if let selfRow = try? await DuelAPIService.shared.fetchUserByUsername(userId) {
            userProfile.serverWorldRank = selfRow.worldRank
        }
        guard let apiFriends = try? await DuelAPIService.shared.fetchMyFriends(userId: userId) else { return }
        let oldFriends = userProfile.friends
        var usedOldIds = Set<UUID>()

        var merged: [Friend] = []
        var seen = Set<String>()
        var changed = false

        for api in apiFriends {
            let key = api.username.lowercased()
            guard seen.insert(key).inserted else { continue }
            let mapped = api.toFriend()
            if let old = bestMatchingFriend(for: api, in: oldFriends, excluding: usedOldIds) {
                usedOldIds.insert(old.id)
                let updated = Friend(
                    id: old.id,
                    username: mapped.username,
                    displayName: api.displayName ?? mapped.displayName,
                    avatar: mapped.avatar,
                    avatarPhotoBase64: mapped.avatarPhotoBase64 ?? old.avatarPhotoBase64,
                    countryCode: mapped.countryCode,
                    level: mapped.level,
                    xp: mapped.xp,
                    streak: mapped.streak,
                    totalGamesPlayed: mapped.totalGamesPlayed,
                    correctAnswers: mapped.correctAnswers,
                    isOnline: old.isOnline,
                    joinDate: api.joinDateFromServer ?? old.joinDate,
                    playedToday: mapped.playedToday,
                    birthday: mapped.birthday ?? old.birthday,
                    achievements: mapped.achievements,
                    worldRankFromServer: api.worldRank
                )
                if friendDataChanged(old: old, new: updated) { changed = true }
                merged.append(updated)
            } else {
                changed = true
                merged.append(mapped)
            }
        }

        if merged.count != userProfile.friends.count { changed = true }
        guard changed else { return }
        userProfile.friends = merged
        userProfile.saveToStorage()
    }

    private func bestMatchingFriend(for api: FriendFromAPI, in oldFriends: [Friend], excluding used: Set<UUID>) -> Friend? {
        let apiUsername = api.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiDisplay = (api.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let apiUsernameNorm = canonicalFriendIdentity(apiUsername)
        let apiDisplayNorm = canonicalFriendIdentity(apiDisplay)

        if let exact = oldFriends.first(where: { !used.contains($0.id) && $0.username.caseInsensitiveCompare(apiUsername) == .orderedSame }) {
            return exact
        }
        if let byDisplay = oldFriends.first(where: {
            !used.contains($0.id)
            && !$0.displayNameOrUsername.isEmpty
            && $0.displayNameOrUsername.caseInsensitiveCompare(apiDisplay) == .orderedSame
        }) {
            return byDisplay
        }
        if let byNormalized = oldFriends.first(where: {
            !used.contains($0.id)
            && (canonicalFriendIdentity($0.username) == apiUsernameNorm
                || canonicalFriendIdentity($0.displayNameOrUsername) == apiUsernameNorm
                || (!apiDisplayNorm.isEmpty
                    && (canonicalFriendIdentity($0.username) == apiDisplayNorm
                        || canonicalFriendIdentity($0.displayNameOrUsername) == apiDisplayNorm)))
        }) {
            return byNormalized
        }
        return nil
    }

    private func canonicalFriendIdentity(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        s = s.replacingOccurrences(of: "[-_ ]?\\d+$", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[^a-zа-яёіїєґ0-9]", with: "", options: .regularExpression)
        return s
    }

    private func friendDataChanged(old: Friend, new: Friend) -> Bool {
        old.displayName != new.displayName
        || old.avatar != new.avatar
        || old.avatarPhotoBase64 != new.avatarPhotoBase64
        || old.countryCode != new.countryCode
        || old.level != new.level
        || old.xp != new.xp
        || old.streak != new.streak
        || old.playedToday != new.playedToday
        || old.birthday != new.birthday
        || old.achievements != new.achievements
        || old.totalGamesPlayed != new.totalGamesPlayed
        || old.correctAnswers != new.correctAnswers
        || old.joinDate != new.joinDate
        || old.worldRankFromServer != new.worldRankFromServer
    }

    private func generateProfileURL() -> String {
        return (verifiedProfileShareURL ?? ShareService.shared.profileURL(username: AuthService.shared.authUsername ?? userProfile.username)).absoluteString
    }
    
    #if os(iOS)
    private func shareProfile() {
        Task { @MainActor in
            await FriendsService.shared.syncServerFriendCode(for: userProfile, maxAttempts: 1)
            let name = AuthService.shared.authUsername ?? userProfile.username
            if let remote = try? await DuelAPIService.shared.fetchUserByUsername(name), !remote.friendCode.isEmpty {
                verifiedProfileShareURL = ShareService.shared.profileURL(username: remote.friendCode)
            } else {
                profileShareFailed = true
                return
            }
            generateProfileCard { image in
                profileCardImage = image
                showingShareSheet = true
                let key = "profileShareCount"
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
                userProfile.evaluateAchievementsAndUnlock()
            }
        }
    }

    /// Картинка с QR + рекламный текст для шаринга (собирается при открытии sheet).
    private var profileShareActivityItems: [Any] {
        let promo = makeProfileShareMessage()
        if let img = profileCardImage {
            return [img, promo]
        }
        return [promo]
    }

    /// Тот же рекламный текст, что и при шаринге со страницы Статистика (скрин + QR и текст).
    private func makeProfileShareMessage() -> String {
        let format = LocalizationManager.shared.localizedString("Statistics Share Promo")
        let link = generateProfileURL()
        return String(format: format, userProfile.bestScore, userProfile.accuracy, userProfile.totalGamesPlayed, link)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    private func generateProfileCard(completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: generateProfileURL()) else { completion(nil); return }
        completion(ProfileShareBanner.render(username: userProfile.username,
            level: userProfile.level, xp: userProfile.xp, streak: userProfile.streak, url: url))
    }

    #else
    private func shareProfile() {
        // macOS implementation would go here
    }
    
    private func generateQRCode(from string: String) -> NSImage? {
        // macOS implementation would go here
        return nil
    }
    
    private func generateProfileCard(completion: @escaping (NSImage?) -> Void) {
        // macOS implementation would go here
        completion(nil)
    }
    #endif
    fileprivate func formatJoinDate(_ date: Date) -> String {
        let year = Calendar.current.component(.year, from: date)
        let format = LocalizationManager.shared.localizedString("Joined in %@")
        return String(format: format, String(year))
    }
}

extension ProfileView {
    /// Текст даты присоединения для шапки; если нет данных — текущий год (напр. 2026).
    private var profileJoinDateText: String {
        let s = formatJoinDate(userProfile.joinDate)
        if s.isEmpty { return String(Calendar.current.component(.year, from: Date())) }
        return s
    }
}

struct StatisticRow: View {
    let icon: String
    /// Миниатюра из Assets (если задана — показывается вместо emoji)
    var iconImageName: String? = nil
    /// SF Symbol (если задан — показывается вместо emoji)
    var systemImageName: String? = nil
    let title: String
    let subtitle: String
    var isIPad: Bool = false

    private var iconSize: CGFloat { isIPad ? 28 : 24 }
    private var iconFrame: CGFloat { isIPad ? 36 : 30 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let name = iconImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconFrame, height: iconFrame)
                } else if let sys = systemImageName {
                    Image(systemName: sys)
                        .foregroundStyle(.indigo)
                        .font(.system(size: iconSize, weight: .semibold))
                        .frame(width: iconFrame, height: iconFrame)
                } else {
                    Text(icon)
                        .font(.system(size: iconSize))
                        .frame(width: iconFrame, height: iconFrame)
                }
            }

            VStack(alignment: .leading, spacing: isIPad ? 4 : 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
            }


        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct FriendStreakCard: View {
    let friend: Friend?
    let isPlaceholder: Bool

    /// Миниатюра аватара друга: в круге флаг (по countryCode) или эмодзи; при отсутствии аватара — флаг.
    var body: some View {
        VStack(spacing: 8) {
            if isPlaceholder {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                )
            } else if let f = friend {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    #if os(iOS)
                    if let data = f.remotePhotoAvatarData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Text(f.displayAvatar)
                            .font(.system(size: 24))
                    }
                    #else
                    Text(f.displayAvatar)
                        .font(.system(size: 24))
                    #endif
                }
                Text(f.displayNameOrUsername)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 70)
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                    Text("\(f.streak)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct MonthlyBadge: View {
    private let definition: AchievementDefinition?
    private let icon: String
    let title: String
    let isUnlocked: Bool

    init(definition: AchievementDefinition? = nil, icon: String = "star.fill", title: String, isUnlocked: Bool) {
        self.definition = definition
        self.icon = icon
        self.title = title
        self.isUnlocked = isUnlocked
    }

    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let def = definition, let asset = def.imageAssetName, isUnlocked {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .saturation(1)
                        .background(Circle().fill(secondarySystemGroupedBackground))
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(isUnlocked ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)

                    if isUnlocked {
                        if icon.contains(".") {
                            Image(systemName: icon)
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        } else {
                            Text(icon)
                                .font(.system(size: 24))
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
            }
            .shadow(color: isUnlocked ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// Элемент списка: завершённая дуэль или ожидающая результата
private enum DuelSummaryRow: Identifiable {
    case completed(DuelHistoryEntry)
    case pending(DuelChallenge)

    var id: String {
        switch self {
        case .completed(let e): return "c-\(e.id)"
        case .pending(let c): return "p-\(c.id)"
        }
    }

    var sortDate: Date {
        switch self {
        case .completed(let e): return e.playedAt
        case .pending(let c): return c.createdAt
        }
    }
}

struct DuelSummaryView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var syncFailed = false
    @State private var isRefreshingDuels = false
    @State private var reminderNotice: String?
    @State private var actionError: String?
    @State private var filter: DuelHistoryFilter = .all
    @State private var selectedOpponent: String? = nil
    @State private var acceptingIncomingChallengeId: String? = nil
    @State private var remindingChallengeId: String? = nil
    @State private var showingOutOfLives = false
    @State private var showDuelPremium = false
    @State private var processedExpiredChallengeIds: Set<String> = []
    private let duelSummaryAutoRefresh = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    private struct PendingUserProfileLink: Identifiable {
        let id = UUID()
        let friendCode: String
    }
    @State private var pendingUserProfileLink: PendingUserProfileLink? = nil
    #if os(iOS)
    @State private var showShareSheet = false
    #endif

    private enum DuelHistoryFilter: Int, CaseIterable {
        case all
        case wins
        case losses
    }

    private var filteredHistory: [DuelHistoryEntry] {
        let base: [DuelHistoryEntry]
        switch filter {
        case .all: base = dedupedCompletedHistory(gameState.duelHistory)
        case .wins: base = dedupedCompletedHistory(gameState.duelHistory.filter(\.iWon))
        case .losses: base = dedupedCompletedHistory(gameState.duelHistory.filter { !$0.iWon })
        }
        guard let selected = selectedOpponent, !selected.isEmpty else { return base }
        return base.filter { resolvedOpponentName(for: $0) == selected }
    }

    private var opponentFilterOptions: [String] {
        var names = Set(dedupedCompletedHistory(gameState.duelHistory).map { resolvedOpponentName(for: $0) })
        for challenge in userProfile.outgoingDuelChallenges where challenge.status == .pending || challenge.status == .challengerCompleted {
            names.insert(challenge.opponentName)
        }
        for challenge in userProfile.incomingDuelChallenges where challenge.status == .pending || challenge.status == .challengerCompleted {
            if !DuelInviteSuppression.isDeclined(challenge.id) {
                names.insert(challenge.challengerName)
            }
        }
        return names.sorted()
    }

    /// Для таба «Усі»: завершённые + исходящие, где ждём результат (соперник ещё не сыграл)
    private var allRows: [DuelSummaryRow] {
        var rows: [DuelSummaryRow] = dedupedCompletedHistory(gameState.duelHistory).map { .completed($0) }
        let now = Date()
        let waiting = userProfile.outgoingDuelChallenges.filter { c in
            if c.status == .pending { return true }
            if c.status == .challengerCompleted {
                return now.timeIntervalSince(c.createdAt) < Self.duelExpirySeconds
            }
            return false
        }
        rows.append(contentsOf: waiting.map { .pending($0) })

        let incomingWaiting = userProfile.incomingDuelChallenges.filter { c in
            (c.status == .pending || c.status == .opponentCompleted || c.status == .challengerCompleted)
                && now.timeIntervalSince(c.createdAt) < Self.duelExpirySeconds
                && !DuelInviteSuppression.isDeclined(c.id)
        }
        rows.append(contentsOf: incomingWaiting.map { .pending($0) })

        // Один duel challenge = одна карточка (без дублей по id).
        var seenPending = Set<String>()
        let deduped = rows.filter { row in
            switch row {
            case .completed:
                return true
            case .pending(let c):
                if seenPending.contains(c.id) { return false }
                seenPending.insert(c.id)
                return true
            }
        }

        let sorted = deduped.sorted { $0.sortDate > $1.sortDate }
        guard let selected = selectedOpponent, !selected.isEmpty else { return sorted }
        return sorted.filter { row in
            switch row {
            case .completed(let entry): return resolvedOpponentName(for: entry) == selected
            case .pending(let challenge): return pendingOpponentDisplayName(challenge) == selected
            }
        }
    }

    private func pendingOpponentDisplayName(_ challenge: DuelChallenge) -> String {
        if userProfile.incomingDuelChallenges.contains(where: { $0.id == challenge.id }) {
            return challenge.challengerName
        }
        return challenge.opponentName
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            // Табы с иконками
            HStack(spacing: 12) {
                ForEach([DuelHistoryFilter.all, .wins, .losses], id: \.rawValue) { tab in
                    duelTabButton(tab: tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            duelOpponentFilterBar
                .padding(.bottom, 6)

            if let reminderNotice {
                Text(reminderNotice).font(.subheadline).padding(16).accessibilityIdentifier("duel.reminder.feedback")
            }
            if syncFailed {
                HStack {
                    Label(localizationManager.localizedString("Server Error"), systemImage: "wifi.exclamationmark")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(localizationManager.localizedString("Try Again")) {
                        Task { await refreshDuelContent() }
                    }
                }.padding(16)
            }
            if filter == .all {
                duelAllList
            } else {
                duelCompletedList
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(localizationManager.localizedString("duel.challenges.title"))
        .alert(localizationManager.localizedString("duel.error.alert.title"), isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button(localizationManager.localizedString("OK"), role: .cancel) { actionError = nil }
        } message: { Text(actionError ?? "") }
        .onAppear {
            guard !isRefreshingDuels else { return }
        isRefreshingDuels = true
        defer { isRefreshingDuels = false }
        _ = gameState.assignWinsForExpiredOutgoingDuels(profile: userProfile)
            _ = gameState.assignWinsForExpiredIncomingDuels(profile: userProfile)
            Task { await refreshDuelContent() }
        }
        .onChange(of: gameState.requestOutOfLivesAlert) { if $0 { gameState.requestOutOfLivesAlert = false; showingOutOfLives = true } }
        .onReceive(duelSummaryAutoRefresh) { _ in
            Task { await refreshDuelContent() }
        }
        .alert(LocalizationManager.shared.localizedString("Out of lives"), isPresented: $showingOutOfLives) {
            Button(LocalizationManager.shared.localizedString("OK"), role: .cancel) { showingOutOfLives = false }
            Button(LocalizationManager.shared.localizedString("Go Premium")) {
                showingOutOfLives = false
                showDuelPremium = true
            }
        } message: {
            Text(LocalizationManager.shared.localizedString("Unfortunately you ran out of lives this time. Try again or come back later."))
        }
        .modifier(PremiumPresentationModifier(showPremium: $showDuelPremium, gameState: gameState))
        .sheetItemOrFullScreenOnIPad(item: $pendingUserProfileLink) { link in
            ProfileByLinkView(friendCode: link.friendCode, gameState: gameState)
                .environmentObject(userProfile)
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(localizationManager.localizedString("Share")) {
                    showShareSheet = true
                }
                .disabled(filteredHistory.isEmpty)
            }
        }
        .sheetOrFullScreenOnIPad(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [makeShareText()])
        }
        #endif
    }

    private var duelOpponentFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedOpponent = nil }) {
                    Text(localizationManager.localizedString("All"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedOpponent == nil ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selectedOpponent == nil ? Color.blue : Color.blue.opacity(0.14)))
                }
                .buttonStyle(.plain)

                ForEach(opponentFilterOptionsOrdered, id: \.self) { opponent in
                    Button(action: { selectedOpponent = opponent }) {
                        Text(opponent)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedOpponent == opponent ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(selectedOpponent == opponent ? Color.blue : Color.blue.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var opponentFilterOptionsOrdered: [String] {
        guard let selected = selectedOpponent, !selected.isEmpty else { return opponentFilterOptions }
        if opponentFilterOptions.contains(selected) {
            return [selected] + opponentFilterOptions.filter { $0 != selected }
        } else {
            return [selected] + opponentFilterOptions
        }
    }

    @ViewBuilder
    private func duelTabButton(tab: DuelHistoryFilter) -> some View {
        let isSelected = filter == tab
        let (icon, label, color): (String, String, Color) = {
            switch tab {
            case .all:
                return ("list.bullet.clipboard.fill", localizationManager.localizedString("All"), .blue)
            case .wins:
                return ("trophy.fill", localizationManager.localizedString("Wins"), .green)
            case .losses:
                return ("flame.fill", localizationManager.localizedString("Losses"), .orange)
            }
        }()
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { filter = tab } }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    private var duelAllList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if allRows.isEmpty {
                    Text(localizationManager.localizedString("No duel history yet"))
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(allRows) { row in
                        switch row {
                        case .completed(let item):
                            duelCompletedCard(entry: item)
                        case .pending(let challenge):
                            duelPendingCard(challenge: challenge)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .refreshable { await refreshDuelContent() }
    }

    private var duelCompletedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredHistory.isEmpty {
                    Text(localizationManager.localizedString("No duel history yet"))
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(filteredHistory) { item in
                        duelCompletedCard(entry: item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .refreshable { await refreshDuelContent() }
    }

    private func refreshDuelContent() async {
        _ = gameState.assignWinsForExpiredOutgoingDuels(profile: userProfile)
        _ = gameState.assignWinsForExpiredIncomingDuels(profile: userProfile)
        let outgoingOK = await gameState.syncOutgoingDuelsWithServer(profile: userProfile)
        let incomingOK = await gameState.syncIncomingDuelsWithServer(profile: userProfile)
        syncFailed = !outgoingOK || !incomingOK
    }

    private func duelCompletedCard(entry: DuelHistoryEntry) -> some View {
        HStack(spacing: 14) {
            Image(systemName: entry.iWon ? "trophy.fill" : "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: entry.iWon ? [.yellow, .orange] : [.orange, .red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.iWon ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.iWon ? localizationManager.localizedString("Victory") : localizationManager.localizedString("Defeat"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(entry.iWon ? .green : .orange)
                    Spacer()
                    Text(dateFormatter.string(from: entry.playedAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Text("\(localizationManager.localizedString("You")) · @\(userProfile.username) vs \(resolvedOpponentName(for: entry))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text("\(localizationManager.localizedString("You")): \(entry.myScore)  •  \(resolvedOpponentName(for: entry)): \(entry.opponentScore)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                if entry.showsTieTimeBreakdown, let myT = entry.myTimeMs, let rT = entry.rivalTimeMs {
                    DuelHistoryTieTimesLine(myTimeMs: myT, rivalTimeMs: rT, compact: true)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(entry.iWon ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
        .contextMenu {
            Button {
                selectedOpponent = resolvedOpponentName(for: entry)
                filter = .all
            } label: {
                Label(localizationManager.localizedString("Filter by name"), systemImage: "line.3.horizontal.decrease.circle")
            }
            Button {
                openUserProfileByUsername(resolvedOpponentName(for: entry))
            } label: {
                Label(localizationManager.localizedString("Профиль пользователя"), systemImage: "person.crop.circle")
            }
        }
        .onTapGesture {
            selectedOpponent = resolvedOpponentName(for: entry)
            filter = .all
        }
    }

    private static let duelExpirySeconds: TimeInterval = 24 * 3600

    private func duelPendingCard(challenge: DuelChallenge) -> some View {
        let isIncoming = userProfile.incomingDuelChallenges.contains(where: { $0.id == challenge.id })
        let displayOpponent = pendingOpponentDisplayName(challenge)
        let mySubmittedScore = isIncoming ? challenge.opponentScore : challenge.challengerScore
        let rivalSubmittedScore = isIncoming ? challenge.challengerScore : challenge.opponentScore
        let yourScore = mySubmittedScore.map(String.init) ?? "—"
        let rivalScore = rivalSubmittedScore.map(String.init) ?? "—"
        
        let scoreText: String = {
            switch challenge.status {
            case .challengerCompleted, .opponentCompleted:
                return "\(localizationManager.localizedString("You")): \(yourScore) • \(displayOpponent): \(rivalScore)"
            default:
                return localizationManager.localizedString("Waiting for opponent")
            }
        }()
        
        let waitingForResult = mySubmittedScore != nil
        return TimelineView(.periodic(from: Date(), by: 60)) { context in
            let now = context.date
            let elapsed = now.timeIntervalSince(challenge.createdAt)
            let remaining = max(0, Self.duelExpirySeconds - elapsed)
            let isExpired = remaining <= 0
            
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let countdownText = remaining > 0
                ? String(format: localizationManager.localizedString("Duel time left format"), hours, minutes)
                : localizationManager.localizedString("Duel time expired")
            HStack(spacing: 14) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.12))
                    )
                    .onTapGesture {
                        selectedOpponent = displayOpponent
                        filter = .all
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(waitingForResult
                         ? localizationManager.localizedString("Waiting for result")
                         : (isIncoming ? localizationManager.localizedString("duel_invite_popup_title") : localizationManager.localizedString("Waiting for opponent")))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                    Text("\(localizationManager.localizedString("You")) · @\(userProfile.username) vs \(displayOpponent)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(scoreText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(dateFormatter.string(from: challenge.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    Text(countdownText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(remaining > 0 ? .blue : .orange)
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    selectedOpponent = displayOpponent
                    filter = .all
                }
                Spacer(minLength: 8)

                if !isExpired {
                    if isIncoming && (challenge.status == .pending || challenge.status == .challengerCompleted) {
                        Button {
                            Task { await acceptIncomingDuelFromSummary(challenge) }
                        } label: {
                            HStack(spacing: 8) {
                                Text("⚔︎")
                                    .font(.system(size: 14, weight: .bold))
                                Text(localizationManager.localizedString("Start duel"))
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [Color.green, Color.teal], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(acceptingIncomingChallengeId == challenge.id)
                    } else {
                        Button {
                            Task { await remindOutgoingDuelFromSummary(challenge) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.2.circlepath")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(localizationManager.localizedString("Remind"))
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.purple)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(remindingChallengeId == challenge.id)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.35), lineWidth: 1)
            )
            .onAppear {
                // Когда истёк лимит сразу при рендере — обработаем один раз.
                guard isExpired else { return }
                guard !processedExpiredChallengeIds.contains(challenge.id) else { return }
                processedExpiredChallengeIds.insert(challenge.id)
                Task { @MainActor in
                    _ = gameState.assignWinsForExpiredOutgoingDuels(profile: userProfile)
                    _ = gameState.assignWinsForExpiredIncomingDuels(profile: userProfile)
                }
            }
            .onChange(of: isExpired) { expired in
                // Когда истёк лимит позже — обработаем в момент смены.
                guard expired else { return }
                guard !processedExpiredChallengeIds.contains(challenge.id) else { return }
                processedExpiredChallengeIds.insert(challenge.id)
                Task { @MainActor in
                    _ = gameState.assignWinsForExpiredOutgoingDuels(profile: userProfile)
                    _ = gameState.assignWinsForExpiredIncomingDuels(profile: userProfile)
                }
            }
            .contextMenu {
                Button {
                    selectedOpponent = displayOpponent
                    filter = .all
                } label: {
                    Label(localizationManager.localizedString("Filter by name"), systemImage: "line.3.horizontal.decrease.circle")
                }
                Button {
                    openUserProfileFromChallenge(challenge, isIncoming: isIncoming, displayOpponent: displayOpponent)
                } label: {
                    Label(localizationManager.localizedString("Профиль пользователя"), systemImage: "person.crop.circle")
                }
            }
        }
    }

    private func acceptIncomingDuelFromSummary(_ challenge: DuelChallenge) async {
        guard acceptingIncomingChallengeId != challenge.id else { return }
        acceptingIncomingChallengeId = challenge.id
        defer { acceptingIncomingChallengeId = nil }

        do {
            let result = try await DuelAPIService.shared.acceptChallenge(
                challengeId: challenge.id,
                userId: userProfile.username
            )
            await MainActor.run {
                gameState.selectedPlayMode = .duel
                if let setup = result.duelSetup {
                    gameState.applyDuelSetupFromServer(setup)
                } else if
                    let regions = challenge.duelRegions,
                    let difficulty = challenge.duelDifficulty,
                    let gameMode = challenge.duelGameMode {
                    gameState.applyDuelSetupFromServer(
                        .init(
                            regions: regions,
                            difficulty: difficulty,
                            gameMode: gameMode,
                            questionsCount: challenge.duelQuestionsCount ?? 0,
                            optionsCount: challenge.duelOptionsCount ?? 0
                        )
                    )
                }

                gameState.duelQuestionsPayload = result.duelSetup?.questionsPayload ?? challenge.duelQuestionsPayload
                gameState.duelSeed = result.seed
                gameState.duelChallengeId = challenge.id
                gameState.duelOpponentId = challenge.challengerId
                gameState.duelRoleIsChallenger = false
                gameState.duelChallengerName = result.challengerName
                gameState.duelOpponentName = userProfile.username
                // Не удаляем incoming-челлендж: он нужен для появления дуэли в «Сводке Дуэлей» (ожидание результата)
                DuelInviteSuppression.markAccepted(challenge.id)
            }

            await gameState.startNewGameWithCurrentRegions()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func openUserProfileByUsername(_ username: String) {
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !u.isEmpty else { return }
        let normalized = canonicalFriendIdentity(u)
        var candidates: [String] = [u]
        if let friend = userProfile.friends.first(where: {
            canonicalFriendIdentity($0.username) == normalized
            || canonicalFriendIdentity($0.displayNameOrUsername) == normalized
            || $0.displayNameOrUsername.caseInsensitiveCompare(u) == .orderedSame
        }) {
            candidates.append(friend.username)
            candidates.append(friend.displayNameOrUsername)
        }
        candidates = Array(Set(candidates.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }))
        Task {
            for candidate in candidates {
                do {
                    if let apiUser = try await DuelAPIService.shared.fetchUserByUsername(candidate) {
                        await MainActor.run {
                            pendingUserProfileLink = PendingUserProfileLink(friendCode: apiUser.friendCode)
                        }
                        return
                    }
                } catch {
                    continue
                }
            }
            print("[DuelSummary] openUserProfileByUsername failed, candidates=", candidates)
        }
    }

    private func openUserProfileFromChallenge(_ challenge: DuelChallenge, isIncoming: Bool, displayOpponent: String) {
        let candidatesRaw: [String] = isIncoming
            ? [challenge.challengerId, challenge.challengerName, displayOpponent]
            : [challenge.opponentId, challenge.opponentName, displayOpponent]
        let candidates = Array(Set(candidatesRaw
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }))

        guard !candidates.isEmpty else { return }
        Task {
            for candidate in candidates {
                do {
                    if let apiUser = try await DuelAPIService.shared.fetchUserByUsername(candidate) {
                        await MainActor.run {
                            pendingUserProfileLink = PendingUserProfileLink(friendCode: apiUser.friendCode)
                        }
                        return
                    }
                } catch {
                    continue
                }
            }
            print("[DuelSummary] openUserProfileFromChallenge failed, challengeId=", challenge.id, "candidates=", candidates)
        }
    }

    private func dedupedCompletedHistory(_ history: [DuelHistoryEntry]) -> [DuelHistoryEntry] {
        var byChallenge = Set<String>()
        var byComposite = Set<String>()
        var result: [DuelHistoryEntry] = []
        for item in history.sorted(by: { $0.playedAt > $1.playedAt }) {
            if let cid = item.duelChallengeId, !cid.isEmpty {
                if byChallenge.contains(cid) { continue }
                byChallenge.insert(cid)
                result.append(item)
                continue
            }
            let minuteBucket = Int(item.playedAt.timeIntervalSince1970 / 60.0)
            let key = "\(canonicalFriendIdentity(item.opponentName))|\(item.myScore)|\(item.opponentScore)|\(item.iWon ? 1 : 0)|\(minuteBucket)"
            if byComposite.contains(key) { continue }
            byComposite.insert(key)
            result.append(item)
        }
        return result
    }

    private func resolvedOpponentName(for entry: DuelHistoryEntry) -> String {
        let raw = entry.opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = canonicalFriendIdentity(raw)
        if let friend = userProfile.friends.first(where: {
            canonicalFriendIdentity($0.username) == normalized
            || canonicalFriendIdentity($0.displayNameOrUsername) == normalized
            || $0.displayNameOrUsername.caseInsensitiveCompare(raw) == .orderedSame
        }) {
            return friend.displayNameOrUsername
        }
        return raw
    }

    private func canonicalFriendIdentity(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        s = s.replacingOccurrences(of: "[-_ ]?\\d+$", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[^a-zа-яёіїєґ0-9]", with: "", options: .regularExpression)
        return s
    }

    private func remindOutgoingDuelFromSummary(_ challenge: DuelChallenge) async {
        guard remindingChallengeId == nil else { return }
        remindingChallengeId = challenge.id
        defer { remindingChallengeId = nil }

        do {
            let result = try await DuelAPIService.shared.remindChallengeResult(challengeId: challenge.id, userId: AuthService.shared.authUsername ?? userProfile.username)
            let key: String
            if result.throttled == true { key = "duel.reminder.cooldown" }
            else if result.reason == "notifications_disabled" { key = "duel.reminder.disabled" }
            else if result.reason == "no_device_token" { key = "duel.reminder.no_device" }
            else if result.pushSent == true { key = "duel.reminder.sent" }
            else { key = "Server error. Try again." }
            reminderNotice = localizationManager.localizedString(key)
        } catch {
            actionError = error is URLError ? localizationManager.localizedString("duel.network.error") : error.localizedDescription
            print("[DuelSummary] remind outgoing failed:", error, "challengeId=", challenge.id)
        }
    }

    private func makeShareText() -> String {
        var lines: [String] = [localizationManager.localizedString("Duel Summary Share Header")]
        for item in filteredHistory.prefix(10) {
            let status = item.iWon ? localizationManager.localizedString("Victory") : localizationManager.localizedString("Defeat")
            lines.append("• \(status) — \(item.opponentName): \(item.myScore):\(item.opponentScore)")
        }
        if let url = ShareService.shared.appStoreURL {
            lines.append("")
            lines.append(url.absoluteString)
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - ShareSheet
#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// Extension и RoundedCorner определены в MonthlyQuestsView.swift

// Safe area inset key для ProfileView
private struct SafeTopInsetKeyProfile: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ProfileContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct ProfileHideScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

// Мини-флаг выбранной пользователем страны (Your country)
@MainActor
private var flagForSelectedCountry: String {
    guard let code = UserProfile.shared.selectedCountryCode?.trimmingCharacters(in: .whitespacesAndNewlines),
          !code.isEmpty else { return "🏳️" }
    return FriendsService.countryCodeToFlagEmoji(code)
}

#Preview {
    ProfileView(selectedTab: .constant(0))
        .environmentObject(UserProfile.shared)
}

/// Lightweight vector icons: consistent silhouette and legible at small sizes.
struct ProfileFeatureIcon: View {
    let name: String
    private var tint: Color {
        name == "IconWorldProgressMap" ? .teal : name == "IconDuelSummary" ? .indigo : .blue
    }
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.85), tint], startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                if name == "IconDuelSummary" {
                    HStack(spacing: -side * 0.08) {
                        Image(systemName: "flag.fill").rotationEffect(.degrees(-16))
                        Image(systemName: "flag.fill").scaleEffect(x: -1, y: 1).rotationEffect(.degrees(16))
                    }
                    .font(.system(size: side * 0.39, weight: .semibold))
                } else {
                    Image(systemName: name == "IconWorldProgressMap" ? "globe.europe.africa.fill" : "chart.bar.fill")
                        .font(.system(size: side * 0.53, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
