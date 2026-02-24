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
    #if os(iOS)
    @State private var profileCardImage: UIImage?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #else
    @State private var profileCardImage: NSImage?
    #endif
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var safeTopInset: CGFloat = 0
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
                            .modifier(ProfileHideScrollContentBackgroundModifier())
                            .background(systemGroupedBackground)
                            ipadOverlayLandscape
                        }
                    } else {
                        ZStack(alignment: .top) {
                            ScrollView {
                                ipadScrollContent
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
            }
            .padding(.horizontal, isIPad ? 40 : 20)
        }
    }
    
    @State private var showingAddFriends = false
    @State private var showingFBucksInfo = false

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
                Text(userProfile.username)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
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
                    Text(userProfile.username)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
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
                    Text(userProfile.username)
                        .font(.system(size: isIPad ? 26 : 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("@\(userProfile.username.uppercased()) • \(formatJoinDate(userProfile.joinDate))")
                        .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.leading, isIPad ? 12 : 8) // Добавляем отступ для выравнивания с кнопкой

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
    default: return "🇺🇸"
    }
}

#Preview {
    ProfileView(selectedTab: .constant(0))
        .environmentObject(UserProfile.shared)
}
