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
    @State private var showFullNameAlert = false
    #if os(iOS)
    @State private var profileCardImage: UIImage?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #else
    @State private var profileCardImage: NSImage?
    #endif
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var safeTopInset: CGFloat = 0
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var containerSize: CGSize = .zero
    @Binding var selectedTab: Int
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
    
    private var isIPadLandscape: Bool {
        guard isIPad else { return false }
        #if os(iOS)
        if verticalSizeClass == .compact { return true }
        let size = containerSize.width > 0 ? containerSize : UIScreen.main.bounds.size
        return size.width > size.height
        #else
        return false
        #endif
    }
    
    private var headerHeightLandscape: CGFloat {
        // Высота под аватар 88pt, отступы и кнопки в одной строке
        124 + safeTopInset
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

    private var profileUsernameFontSize: CGFloat {
        if sizeCategory >= .accessibilityMedium, !isIPad { return 18 }
        return isIPad ? 26 : 22
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Базовый фон
            systemGroupedBackground
                .ignoresSafeArea()

            if isIPad {
                // iPad: скролл на весь экран, оверлей шапки через .overlay — тапы ниже шапки попадают в ScrollView
                Group {
                    if isIPadLandscape {
                        ZStack(alignment: .top) {
                            ScrollView {
                                ipadScrollContent
                            }
                            .refreshable {
                                await refreshProfileData()
                            }
                            .modifier(ProfileHideScrollContentBackgroundModifier())
                            .background(systemGroupedBackground)
                            ipadOverlayLandscape
                        }
                    } else {
                        ZStack(alignment: .top) {
                            ScrollView {
                                ipadScrollContent
                            }
                            .refreshable {
                                await refreshProfileData()
                            }
                            .modifier(ProfileHideScrollContentBackgroundModifier())
                            .background(systemGroupedBackground.ignoresSafeArea())
                            ipadOverlayPortrait
                        }
                    }
                }
            } else {
                if !isIPadLandscape { headerBackground }
                ScrollView {
                VStack(spacing: isIPad ? 24 : 20) {
                    statisticsSection
                    NavigationLink(destination: StatisticsView(isPushedFromProfile: true)) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: isIPad ? 24 : 22))
                                .foregroundColor(.green)
                            Text(localizationManager.localizedString("Статистика"))
                                .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: isIPad ? 18 : 16))
                        }
                        .padding(isIPad ? 16 : 14)
                        .background(systemGray6)
                        .cornerRadius(isIPad ? 16 : 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, isIPad ? 40 : 20)
                    addFriendsButton
                    overviewSection.padding(.top, 8)
                    friendStreaksSection
                    monthlyBadgesSection
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await refreshProfileData()
            }
            .padding(.top, contentTopInset)
            headerContent
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SafeTopInsetKeyProfile.self, value: geo.safeAreaInsets.top)
                    .preference(key: ProfileContainerSizeKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SafeTopInsetKeyProfile.self) { safeTopInset = $0 }
        .onPreferenceChange(ProfileContainerSizeKey.self) { containerSize = $0 }
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
            }
            .onDisappear {
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            #if os(iOS)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: profileShareActivityItems)
            }
            #endif
            .alert(localizationManager.localizedString("Name"), isPresented: $showFullNameAlert) {
                Button(localizationManager.localizedString("Close"), role: .cancel) { }
            } message: {
                Text(userProfile.username)
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
                StatisticRow(
                    icon: "🔥",
                    title: "\(userProfile.streak) " + LocalizationManager.shared.localizedString("дней"),
                    subtitle: LocalizationManager.shared.localizedString("Текущая серия"),
                    isIPad: isIPad
                )
                
                StatisticRow(
                    icon: flagForSelectedLanguage,
                    title: "\(userProfile.totalGamesPlayed * 10)",
                    subtitle: LocalizationManager.shared.localizedString("Всего изучено флагов"),
                    isIPad: isIPad
                )
                
                StatisticRow(
                    icon: "💎",
                    title: userProfile.currentLeague.localizedFullName,
                    subtitle: LocalizationManager.shared.localizedString("Текущая лига"),
                    isIPad: isIPad
                )
                
                StatisticRow(
                    icon: "⚡",
                    title: "\(userProfile.xp) " + LocalizationManager.shared.localizedString("XP"),
                    subtitle: LocalizationManager.shared.localizedString("Общий опыт"),
                    isIPad: isIPad
                )
                
                Button(action: {
                    showingFBucksInfo = true
                }) {
                    HStack(spacing: isIPad ? 20 : 16) {
                        FBucksChipView(count: userProfile.fBucks, size: .regular)
                        Spacer()
                        VStack(alignment: .trailing, spacing: isIPad ? 4 : 2) {
                            Text(LocalizationManager.shared.localizedString("F-Bucks"))
                                .font(.system(size: isIPad ? 16 : 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, isIPad ? 12 : 8)
                }
                .buttonStyle(PlainButtonStyle())

                // Глобальный рейтинг по странам и миру (мотивационный блок)
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("Global ranking by countries"))
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
                    Text(worldRankLine())
                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

                NavigationLink(destination: WorldProgressMapView().environmentObject(gameState)) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.35), Color.mint.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isIPad ? 52 : 46, height: isIPad ? 52 : 46)
                            Image(systemName: "map.fill")
                                .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationManager.shared.localizedString("Карта прогресса мира"))
                                .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text(LocalizationManager.shared.localizedString("Progress map subtitle"))
                                .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: isIPad ? 22 : 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green.opacity(0.9), .mint.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(isIPad ? 16 : 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(secondarySystemGroupedBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.5), Color.mint.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.green.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DuelSummaryView()
                        .environmentObject(gameState)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                        Text(LocalizationManager.shared.localizedString("Duel Summary"))
                            .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, isIPad ? 12 : 10)
                }
            }
            .padding(.horizontal, isIPad ? 40 : 20)
        }
    }
    
    @State private var showingAddFriends = false
    @State private var showingFBucksInfo = false
    @State private var showingCountryPicker = false

    private var addFriendsButton: some View {
        Button(action: {
            showingAddFriends = true
        }) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                
                Text(LocalizationManager.shared.localizedString("ДОБАВИТЬ ДРУЗЕЙ"))
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isIPad ? 18 : 16)
            .background(secondarySystemGroupedBackground)
            .cornerRadius(isIPad ? 16 : 12)
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, isIPad ? 40 : 20)
        .sheet(isPresented: $showingFBucksInfo) {
            FBucksInfoView()
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsView()
                .environmentObject(userProfile)
        }
        .sheet(isPresented: $showingCountryPicker) {
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
                .padding(.horizontal, 20)
            
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
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(userProfile.friends.prefix(5), id: \.id) { friend in
                            NavigationLink(destination: FriendProfileView(friend: friend, gameState: gameState)) {
                                FriendStreakCard(
                                    avatar: friend.displayAvatar,
                                    streak: friend.streak,
                                    isPlaceholder: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
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
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Отображаем первые 4 достижения из списка всех достижений
                    ForEach(Array(userProfile.allAchievementDefinitions.prefix(4).enumerated()), id: \.element.id) { index, achievementDef in
                        let isUnlocked = userProfile.isAchievementUnlocked(id: achievementDef.id)
                        MonthlyBadge(
                            icon: achievementDef.icon,
                            title: LocalizationManager.shared.localizedString(achievementDef.titleKey),
                            isUnlocked: isUnlocked
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

extension ProfileView {
    // MARK: - Закреплённая шапка (фон)
    private var headerBackground: some View {
        LinearGradient(
            colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: headerHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }

    private var headerHeight: CGFloat {
        // На iPad увеличиваем высоту шапки для лучшего отображения
        if isIPad {
            return 160 + safeTopInset
        }
        return 140 + safeTopInset
    }
    
    private var contentTopInset: CGFloat {
        headerHeight
    }

    /// Контент скролла для iPad (общий для альбомной и портретной).
    private var ipadScrollContent: some View {
        VStack(spacing: isIPad ? 24 : 20) {
            statisticsSection
            NavigationLink(destination: StatisticsView(isPushedFromProfile: true)) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: isIPad ? 24 : 22))
                        .foregroundColor(.green)
                    Text(localizationManager.localizedString("Статистика"))
                        .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: isIPad ? 18 : 16))
                }
                .padding(isIPad ? 16 : 14)
                .background(systemGray6)
                .cornerRadius(isIPad ? 16 : 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, isIPad ? 40 : 20)
            addFriendsButton
            overviewSection.padding(.top, 8)
            friendStreaksSection
            monthlyBadgesSection
        }
        .padding(.bottom, 100)
        .padding(.top, isIPadLandscape ? (headerHeightLandscape - 20) : (headerHeight - 28))
    }

    /// Оверлей для iPad альбомная: шапка рисуется, но не ловит тапы; тапы ниже шапки идут в ScrollView.
    private var ipadOverlayLandscape: some View {
        ZStack(alignment: .topLeading) {
            headerContentCompact
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Spacer(minLength: 0)
                    Button(action: { shareProfile() }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                            .padding(12)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                            .padding(12)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 24)
                .padding(.top, max(0, safeTopInset - 8))
                .frame(height: 56)
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: headerHeightLandscape)
        .ignoresSafeArea(.container, edges: .top)
    }

    /// Оверлей для iPad портрет: одна вью с фиксированной высотой.
    private var ipadOverlayPortrait: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .top) {
                headerBackground
                headerContentNoButtons
            }
            VStack(spacing: 0) {
                profileHeaderButtonsPortrait
                Spacer(minLength: 0)
            }
        }
        .frame(height: headerHeight)
    }

    /// Шапка для iPad альбомная: одна строка — аватар (2x), имя (2x), лига (2x), справа кнопки Поделиться и Настройки.
    private var headerContentCompact: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Color.white)
                    .frame(width: 84, height: 84)
                #if os(iOS)
                if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                } else if userProfile.avatar.starts(with: "custom_") {
                    Text("👤")
                        .font(.system(size: 40))
                } else {
                    Image(systemName: userProfile.avatar)
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                #else
                Text("👤")
                    .font(.system(size: 40))
                #endif
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(userProfile.username)
                        .font(.system(size: sizeCategory >= .accessibilityMedium ? 24 : 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { showFullNameAlert = true }
                    Image(systemName: userProfile.currentLeague.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("@\(userProfile.username.uppercased()) • \(profileJoinDateText)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                HStack(spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: userProfile.currentLeague.icon)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Text(userProfile.currentLeague.localizedFullName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Text("\(userProfile.friends.count)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.orange)
                        Text("\(userProfile.streak)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
            }
            Spacer(minLength: 16)
            Color.clear.frame(width: 100, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, max(0, safeTopInset - 16))
        .padding(.bottom, 16)
        .frame(height: headerHeightLandscape, alignment: .top)
        .background(
            ZStack {
                Color(red: 0.2, green: 0.6, blue: 0.85)
                LinearGradient(
                    colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }

    /// Только кнопки назад/Share/Settings для iPad портрет — отдельный слой
    private var profileHeaderButtonsPortrait: some View {
        HStack {
            #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let navigationController = window.rootViewController?.navigationController,
               navigationController.viewControllers.count > 1 {
                Button(action: { navigationController.popViewController(animated: true) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .padding(.leading, 20)
                .padding(.top, safeTopInset + 20)
            }
            #endif
            Spacer()
            Button(action: { shareProfile() }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 40)
        .padding(.top, max(0, safeTopInset - 52))
        .frame(height: 72)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Закреплённая шапка (контент, без кнопок — для iPad портрет)
    private var headerContentNoButtons: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 54, height: 54)
                    #if os(iOS)
                    if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else if userProfile.avatar.starts(with: "custom_") {
                        Text("👤")
                            .font(.system(size: 26))
                    } else {
                        Image(systemName: userProfile.avatar)
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    #else
                    Text("👤")
                        .font(.system(size: 22))
                    #endif
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(userProfile.username)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: userProfile.currentLeague.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("@\(userProfile.username.uppercased()) • \(formatJoinDate(userProfile.joinDate))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.leading, 12)
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, max(0, safeTopInset - 52))
            HStack(spacing: 40) {
                HStack(spacing: 10) {
                    Image(systemName: userProfile.currentLeague.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Text(userProfile.currentLeague.localizedFullName)
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: 14, weight: .semibold))
                }
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Text("\(userProfile.friends.count) " + LocalizationManager.shared.localizedString("Following"))
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: 14, weight: .semibold))
                }
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text("\(userProfile.streak) " + LocalizationManager.shared.localizedString("дней"))
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(height: headerHeight, alignment: .top)
        .allowsHitTesting(false)
    }

    // MARK: - Закреплённая шапка (контент, с оверлеем кнопок — только для телефона)
    private var headerContent: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                // Аватар
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: isIPad ? 56 : 46, height: isIPad ? 56 : 46)
                    Circle()
                        .fill(Color.white)
                        .frame(width: isIPad ? 54 : 44, height: isIPad ? 54 : 44)
                    #if os(iOS)
                    if userProfile.avatar == "custom_photo", let data = userProfile.customAvatarImageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: isIPad ? 50 : 40, height: isIPad ? 50 : 40)
                            .clipShape(Circle())
                    } else if userProfile.avatar.starts(with: "custom_") {
                        Text("👤")
                            .font(.system(size: isIPad ? 26 : 22))
                    } else {
                        Image(systemName: userProfile.avatar)
                            .font(.system(size: isIPad ? 24 : 20))
                            .foregroundColor(.blue)
                    }
                    #else
                    if userProfile.avatar.starts(with: "custom_") {
                        Text("👤")
                            .font(.system(size: 22))
                    } else {
                        Image(systemName: userProfile.avatar)
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    #endif
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(userProfile.username)
                            .font(.system(size: profileUsernameFontSize, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture { showFullNameAlert = true }
                        Image(systemName: userProfile.currentLeague.icon)
                            .font(.system(size: isIPad ? 14 : 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("@\(userProfile.username.uppercased()) • \(formatJoinDate(userProfile.joinDate))")
                        .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.leading, isIPad ? 12 : 8)
                .padding(.trailing, isIPad ? 0 : 72)

                Spacer()
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.top, max(0, safeTopInset - (isIPad ? 52 : 20)))
            .allowsHitTesting(false)

            // Нижняя карточка статов из хедера (лига, друзья, серия)
            HStack(spacing: isIPad ? 40 : 30) {
                HStack(spacing: isIPad ? 10 : 8) {
                    Image(systemName: userProfile.currentLeague.icon)
                        .foregroundColor(.white)
                        .font(.system(size: isIPad ? 14 : 12))
                    Text(userProfile.currentLeague.localizedFullName)
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                }
                HStack(spacing: isIPad ? 10 : 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.white)
                        .font(.system(size: isIPad ? 14 : 12))
                    Text("\(userProfile.friends.count) " + LocalizationManager.shared.localizedString("Following"))
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                }
                HStack(spacing: isIPad ? 10 : 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: isIPad ? 14 : 12))
                    Text("\(userProfile.streak) " + LocalizationManager.shared.localizedString("дней"))
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                }
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.bottom, isIPad ? 20 : 12)
            .allowsHitTesting(false)
        }
        .frame(height: headerHeight, alignment: .top)
        .allowsHitTesting(false)
        .overlay(
            VStack(spacing: 0) {
                HStack {
                    #if os(iOS)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let navigationController = window.rootViewController?.navigationController,
                       navigationController.viewControllers.count > 1 {
                        Button(action: {
                            navigationController.popViewController(animated: true)
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                                .padding(8)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, safeTopInset + 20)
                    }
                    #endif
                    Spacer()
                    Button(action: { shareProfile() }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .font(.system(size: isIPad ? 20 : 18))
                            .padding(isIPad ? 10 : 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: isIPad ? 20 : 18))
                            .padding(isIPad ? 10 : 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.top, max(0, safeTopInset - (isIPad ? 52 : 20)))
                .frame(height: 72)
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .frame(height: headerHeight),
            alignment: .top
        )
    }
}

// MARK: - Share Profile Functions
extension ProfileView {
    // MARK: - Professional ranking model (country + world)
    // Позиция зависит от качества профиля и оценочного размера активной аудитории:
    // население страны * смартфоны * доля мобильных игроков * доля онлайн-игроков.
    fileprivate func countryRankLine(code: String) -> String {
        let upper = code.uppercased()
        let flag = FriendsService.countryCodeToFlagEmoji(upper)
        let rank = computedCountryRank(for: upper)
        let format = LocalizationManager.shared.localizedString("Country rank line")
        return String(format: format, flag, rank, LocalizationManager.shared.localizedString(countryNameByCode(upper)))
    }

    fileprivate func worldRankLine() -> String {
        let rank = computedWorldRank()
        let format = LocalizationManager.shared.localizedString("World rank line")
        return String(format: format, rank)
    }

    private func computedCountryRank(for countryCode: String) -> Int {
        let pool = max(5_000, estimatedActivePlayers(for: countryCode))
        let p = adjustedPercentile(seedSalt: "COUNTRY_\(countryCode)")
        return max(1, Int((1.0 - p) * Double(pool)) + 1)
    }

    private func computedWorldRank() -> Int {
        let worldPool = max(2_000_000, Self.estimatedWorldActivePlayers)
        let p = adjustedPercentile(seedSalt: "WORLD")
        return max(1, Int((1.0 - p) * Double(worldPool)) + 1)
    }

    private func adjustedPercentile(seedSalt: String) -> Double {
        let base = basePerformancePercentile()
        // Небольшой стабильный сдвиг, чтобы игроки с одинаковыми метриками не имели один и тот же rank.
        let jitter = (Double(stableSeed(seedSalt) % 1000) / 1000.0 - 0.5) * 0.028
        return min(0.995, max(0.01, base + jitter))
    }

    private func basePerformancePercentile() -> Double {
        let accuracy = min(1.0, max(0.0, userProfile.accuracy / 100.0))
        let xpNorm = min(1.0, log1p(Double(max(0, userProfile.xp))) / log1p(120_000.0))
        let gamesNorm = min(1.0, log1p(Double(max(0, userProfile.totalGamesPlayed))) / log1p(4_000.0))
        let streakNorm = min(1.0, log1p(Double(max(0, userProfile.streak))) / log1p(365.0))
        let leagueNorm = min(1.0, max(0.0, Double(leagueTierIndex(userProfile.currentLeague)) / 5.0))
        let consistency = min(1.0, accuracy * (0.62 + 0.38 * gamesNorm))

        var skill =
            0.34 * accuracy +
            0.24 * xpNorm +
            0.14 * gamesNorm +
            0.12 * streakNorm +
            0.16 * leagueNorm

        // За регулярную игру добавляем мягкий буст.
        skill += min(0.08, Double(userProfile.totalGamesPlayed) / 5_000.0) * consistency
        skill = min(1.0, max(0.0, skill))

        // Нелинейная кривая приближена к поведению популярных leaderboard-аппов.
        return 0.02 + pow(skill, 1.35) * 0.965
    }

    private func leagueTierIndex(_ league: League) -> Int {
        switch league {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        case .diamond: return 4
        case .master: return 5
        }
    }

    private func stableSeed(_ salt: String) -> Int {
        let raw = "\(userProfile.username)|\(Int(userProfile.joinDate.timeIntervalSince1970))|\(salt)"
        return raw.unicodeScalars.reduce(17) { ($0 &* 31) &+ Int($1.value) } & Int.max
    }

    private func estimatedActivePlayers(for countryCode: String) -> Int {
        let profile = digitalProfile(for: countryCode)
        let population = estimatedPopulation(for: countryCode)
        // App-interest factor: какая доля mobile аудитории играет именно в квиз/edutainment.
        let appInterest = 0.0022
        let estimated = Double(population) * profile.smartphone * profile.mobileGamers * profile.onlineGamers * appInterest
        return max(5_000, Int(estimated.rounded()))
    }

    private func estimatedPopulation(for countryCode: String) -> Int {
        if let predefined = countryPopulationOverrides[countryCode] {
            return predefined
        }
        guard let country = CountryDatabase.getCountryData(for: countryCode) else {
            return 12_000_000
        }
        let digits = country.en.population.filter { $0.isNumber }
        if let parsed = Int(digits), parsed > 100_000 {
            return parsed
        }
        return 12_000_000
    }

    private func digitalProfile(for countryCode: String) -> (smartphone: Double, mobileGamers: Double, onlineGamers: Double) {
        if let value = Self.countryDigitalOverrides[countryCode] {
            return value
        }
        // Базовый мировой профиль для стран без точного коэффициента.
        return (0.69, 0.56, 0.74)
    }

    private static let estimatedWorldActivePlayers: Int = {
        let appInterest = 0.0022
        var uniqueCodes = Set<String>()
        var total = 0.0

        for country in CountryDatabase.allCountries {
            let code = country.en.code.uppercased()
            guard !uniqueCodes.contains(code) else { continue }
            uniqueCodes.insert(code)

            let digits = country.en.population.filter { $0.isNumber }
            let population = Int(digits) ?? 12_000_000
            let profile = countryDigitalOverrides[code] ?? (0.69, 0.56, 0.74)
            total += Double(population) * profile.smartphone * profile.mobileGamers * profile.onlineGamers * appInterest
        }
        return max(2_000_000, Int(total.rounded()))
    }()

    private var countryPopulationOverrides: [String: Int] {
        [
            "US": 334_000_000, "CN": 1_410_000_000, "IN": 1_430_000_000, "BR": 203_000_000,
            "ID": 278_000_000, "PK": 241_000_000, "NG": 223_000_000, "BD": 173_000_000,
            "RU": 146_000_000, "JP": 123_000_000, "MX": 129_000_000, "PH": 117_000_000,
            "VN": 100_000_000, "TR": 86_000_000, "DE": 84_000_000, "FR": 68_000_000,
            "GB": 68_000_000, "IT": 59_000_000, "ES": 48_000_000, "UA": 37_000_000,
            "PL": 38_000_000, "NL": 18_000_000, "CA": 40_000_000, "AU": 27_000_000,
            "SE": 10_500_000, "NO": 5_500_000, "CH": 8_900_000, "BE": 11_700_000
        ]
    }

    private static let countryDigitalOverrides: [String: (smartphone: Double, mobileGamers: Double, onlineGamers: Double)] = [
        "US": (0.90, 0.62, 0.86), "CA": (0.89, 0.61, 0.85), "GB": (0.91, 0.60, 0.87),
        "DE": (0.89, 0.58, 0.84), "FR": (0.87, 0.57, 0.83), "IT": (0.85, 0.56, 0.82),
        "ES": (0.88, 0.57, 0.83), "NL": (0.92, 0.60, 0.88), "PL": (0.82, 0.55, 0.79),
        "SE": (0.93, 0.59, 0.89), "NO": (0.94, 0.58, 0.90), "CH": (0.92, 0.57, 0.88),
        "BE": (0.90, 0.57, 0.85), "UA": (0.75, 0.53, 0.71), "RU": (0.79, 0.55, 0.73),
        "TR": (0.79, 0.57, 0.75), "CN": (0.77, 0.64, 0.74), "JP": (0.88, 0.53, 0.86),
        "KR": (0.95, 0.64, 0.93), "IN": (0.54, 0.62, 0.60), "ID": (0.69, 0.66, 0.71),
        "PH": (0.71, 0.67, 0.73), "VN": (0.74, 0.65, 0.74), "TH": (0.77, 0.64, 0.76),
        "MY": (0.84, 0.62, 0.82), "SG": (0.94, 0.61, 0.91), "BR": (0.81, 0.63, 0.77),
        "MX": (0.76, 0.61, 0.73), "AR": (0.80, 0.58, 0.76), "CL": (0.83, 0.57, 0.79),
        "CO": (0.74, 0.60, 0.72), "SA": (0.91, 0.58, 0.88), "AE": (0.96, 0.60, 0.93),
        "EG": (0.65, 0.58, 0.63), "NG": (0.45, 0.55, 0.50), "ZA": (0.69, 0.56, 0.68),
        "AU": (0.91, 0.60, 0.86)
    ]

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

        if let apiFriends = try? await DuelAPIService.shared.fetchMyFriends(userId: userId) {
            let oldByUsername = Dictionary(uniqueKeysWithValues: userProfile.friends.map { ($0.username, $0) })
            userProfile.friends = apiFriends.map { api in
                let mapped = api.toFriend()
                if let old = oldByUsername[api.username] {
                    return Friend(
                        id: old.id,
                        username: mapped.username,
                        displayName: api.displayName ?? mapped.displayName,
                        avatar: mapped.avatar,
                        countryCode: mapped.countryCode,
                        level: mapped.level,
                        xp: mapped.xp,
                        streak: mapped.streak,
                        isOnline: old.isOnline,
                        joinDate: old.joinDate
                    )
                }
                return mapped
            }
        }

        if let incoming = try? await DuelAPIService.shared.fetchIncomingChallenges(userId: userId) {
            let existingIds = Set(userProfile.incomingDuelChallenges.map(\.id))
            let newOnes = incoming
                .compactMap { $0.toDuelChallenge(opponentId: userId, opponentName: userId) }
                .filter { !existingIds.contains($0.id) }
            if !newOnes.isEmpty {
                userProfile.incomingDuelChallenges.append(contentsOf: newOnes)
            }
        }

        // Лёгкий тик лиги и переоценка достижений, чтобы карточки на профиле были актуальны.
        LeaguesService.shared.tickCompetitors(for: userProfile.currentLeague)
        userProfile.evaluateAchievementsAndUnlock()
        userProfile.saveToStorage()
    }

    private func generateProfileURL() -> String {
        return "https://worldarena.games/profile/\(userProfile.username)"
    }
    
    #if os(iOS)
    private func shareProfile() {
        generateProfileCard { image in
            DispatchQueue.main.async {
                self.profileCardImage = image
                self.showingShareSheet = true
                let key = "profileShareCount"
                let c = UserDefaults.standard.integer(forKey: key)
                UserDefaults.standard.set(c + 1, forKey: key)
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
        let link = ShareService.shared.appStoreURL?.absoluteString ?? "World Arena Flags"
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
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 600))
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [UIColor.systemBlue.cgColor, UIColor.systemCyan.cgColor] as CFArray,
                                    locations: [0.0, 1.0])!
            
            cgContext.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: 400, y: 600),
                                       options: [])
            
            // White card background
            cgContext.setFillColor(UIColor.white.cgColor)
            let cardRect = CGRect(x: 20, y: 80, width: 360, height: 440)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
            cgContext.addPath(path.cgPath)
            cgContext.fillPath()
            
            // Avatar circle
            cgContext.setFillColor(UIColor.systemBlue.withAlphaComponent(0.2).cgColor)
            let avatarRect = CGRect(x: 150, y: 120, width: 100, height: 100)
            cgContext.fillEllipse(in: avatarRect)
            
            // Avatar
            let avatarText = self.userProfile.avatar.starts(with: "custom_") ? "👨‍💻" : "👤"
            let avatarFont = UIFont.systemFont(ofSize: 50)
            let avatarAttributes = [NSAttributedString.Key.font: avatarFont]
            let avatarSize = avatarText.size(withAttributes: avatarAttributes)
            let avatarPoint = CGPoint(x: 200 - avatarSize.width/2, y: 145)
            avatarText.draw(at: avatarPoint, withAttributes: avatarAttributes)
            
            // Username
            let usernameText = userProfile.username
            let usernameFont = UIFont.boldSystemFont(ofSize: 24)
            let usernameAttributes = [
                NSAttributedString.Key.font: usernameFont,
                NSAttributedString.Key.foregroundColor: UIColor.label
            ]
            let usernameSize = usernameText.size(withAttributes: usernameAttributes)
            let usernamePoint = CGPoint(x: 200 - usernameSize.width/2, y: 240)
            usernameText.draw(at: usernamePoint, withAttributes: usernameAttributes)
            
            // Stats
            let statsText = String(
                format: LocalizationManager.shared.localizedString("Level %d • %d XP • %d-day streak"),
                userProfile.level, userProfile.xp, userProfile.streak
            )
            let statsFont = UIFont.systemFont(ofSize: 14)
            let statsAttributes = [
                NSAttributedString.Key.font: statsFont,
                NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
            ]
            let statsSize = statsText.size(withAttributes: statsAttributes)
            let statsPoint = CGPoint(x: 200 - statsSize.width/2, y: 275)
            statsText.draw(at: statsPoint, withAttributes: statsAttributes)
            
            // QR Code
            if let qrImage = generateQRCode(from: generateProfileURL()) {
                let qrRect = CGRect(x: 300, y: 320, width: 60, height: 60)
                qrImage.draw(in: qrRect)
            }
            
            // App branding
            let appText = "World Arena Flags"
            let appFont = UIFont.boldSystemFont(ofSize: 16)
            let appAttributes = [
                NSAttributedString.Key.font: appFont,
                NSAttributedString.Key.foregroundColor: UIColor.systemBlue
            ]
            let appSize = appText.size(withAttributes: appAttributes)
            let appPoint = CGPoint(x: 200 - appSize.width/2, y: 320)
            appText.draw(at: appPoint, withAttributes: appAttributes)
            
            // URL
            let urlText = "worldarena.games"
            let urlFont = UIFont.systemFont(ofSize: 12)
            let urlAttributes = [
                NSAttributedString.Key.font: urlFont,
                NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel
            ]
            let urlSize = urlText.size(withAttributes: urlAttributes)
            let urlPoint = CGPoint(x: 200 - urlSize.width/2, y: 350)
            urlText.draw(at: urlPoint, withAttributes: urlAttributes)
        }
        
        completion(image)
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
    let title: String
    let subtitle: String
    var isIPad: Bool = false
    
    var body: some View {
        HStack(spacing: isIPad ? 20 : 16) {
            Text(icon)
                .font(.system(size: isIPad ? 28 : 24))
                .frame(width: isIPad ? 48 : 40)
            
            VStack(alignment: .leading, spacing: isIPad ? 4 : 2) {
                Text(title)
                    .font(.system(size: isIPad ? 20 : 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: isIPad ? 16 : 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, isIPad ? 12 : 8)
    }
}

struct FriendStreakCard: View {
    let avatar: String
    let streak: Int
    let isPlaceholder: Bool
    
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
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(avatar)
                        .font(.system(size: 24))
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                    
                    Text("\(streak)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct MonthlyBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if isUnlocked {
                    if icon.contains(".") {
                        // Если иконка содержит точку, это системная иконка SF Symbols
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    } else {
                        // Эмодзи или текст
                        Text(icon)
                            .font(.system(size: 24))
                    }
                } else {
                    // Для заблокированных ачивментов всегда показываем замочек
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
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

struct DuelSummaryView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var filter: DuelHistoryFilter = .all
    #if os(iOS)
    @State private var showShareSheet = false
    #endif

    private enum DuelHistoryFilter: Int, CaseIterable {
        case all
        case wins
        case losses
    }

    private var filteredHistory: [DuelHistoryEntry] {
        switch filter {
        case .all: return gameState.duelHistory
        case .wins: return gameState.duelHistory.filter(\.iWon)
        case .losses: return gameState.duelHistory.filter { !$0.iWon }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $filter) {
                Text(localizationManager.localizedString("All")).tag(DuelHistoryFilter.all)
                Text(localizationManager.localizedString("Wins")).tag(DuelHistoryFilter.wins)
                Text(localizationManager.localizedString("Losses")).tag(DuelHistoryFilter.losses)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                if filteredHistory.isEmpty {
                    Text(localizationManager.localizedString("No duel history yet"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredHistory) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.iWon ? "✅ \(localizationManager.localizedString("Victory"))" : "⚔️ \(localizationManager.localizedString("Defeat"))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(item.iWon ? .green : .orange)
                                Spacer()
                                Text(dateFormatter.string(from: item.playedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(localizationManager.localizedString("Opponent")): \(item.opponentName)")
                                .font(.system(size: 15, weight: .semibold))
                            Text("\(localizationManager.localizedString("Score")): \(item.myScore) : \(item.opponentScore)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(localizationManager.localizedString("Duel Summary"))
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(localizationManager.localizedString("Share")) {
                    showShareSheet = true
                }
                .disabled(filteredHistory.isEmpty)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [makeShareText()])
        }
        #endif
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

// Computed property to get flag for selected language
@MainActor
private var flagForSelectedLanguage: String {
    let languageCode = LocalizationManager.shared.currentLocale.languageCode ?? "en"
    switch languageCode {
    case "ru": return "🇷🇺"
    case "en": return "🇺🇸"
    case "es": return "🇪🇸"
    case "uk": return "🇺🇦"
    case "ca": return "🇪🇸" // Catalan uses Spanish flag
    case "zh": return "🇨🇳"
    case "de": return "🇩🇪"
    case "fr": return "🇫🇷"
    case "it": return "🇮🇹"
    case "pt": return "🇧🇷"
    case "pl": return "🇵🇱"
    case "nl": return "🇳🇱"
    default: return "🇺🇸"
    }
}

#Preview {
    ProfileView(selectedTab: .constant(0))
        .environmentObject(UserProfile.shared)
}
