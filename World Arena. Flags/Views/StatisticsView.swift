import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct StatisticsView: View {
    /// true при переходе из Profile по NavigationLink — показываем кнопку «Назад» и разрешаем свайп назад
    var isPushedFromProfile: Bool = false
    
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var containerSize: CGSize = .zero
    @State private var showingClearAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return horizontalSizeClass == .regular
        #endif
    }
    
    private var isIPadLandscape: Bool {
        guard isIPad else { return false }
        if verticalSizeClass == .compact { return true }
        #if os(iOS)
        let size = containerSize.width > 0 ? containerSize : UIScreen.main.bounds.size
        #else
        let size = containerSize
        #endif
        return size.width > size.height
    }
    
    private var isCompactPhone: Bool {
        #if os(iOS)
        guard !isIPad else { return false }
        let size = containerSize.width > 0 ? containerSize : UIScreen.main.bounds.size
        return size.height <= 880
        #else
        return false
        #endif
    }
    
    @State private var animateCards = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var safeTopInset: CGFloat = 0
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    /// Контент скролла для iPad альбомная (компактная сетка и кнопки)
    private var statisticsScrollContentLandscape: some View {
        let gridCols: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: 20) {
            LazyVGrid(columns: gridCols, spacing: 14) {
                StatisticCard(icon: "🎮", title: LocalizationManager.shared.localizedString("Total Games"), value: "\(userProfile.totalGamesPlayed)", color: .blue, isLarge: false, compactForLandscape: true)
                StatisticCard(icon: "🏆", title: LocalizationManager.shared.localizedString("Best Score"), value: "\(userProfile.bestScore)", color: .orange, isLarge: false, compactForLandscape: true)
                StatisticCard(icon: "✅", title: LocalizationManager.shared.localizedString("Correct Answers"), value: "\(userProfile.correctAnswers)", color: .green, isLarge: false, compactForLandscape: true)
                StatisticCard(icon: "🎯", title: LocalizationManager.shared.localizedString("Accuracy"), value: String(format: "%.1f%%", min(100.0, max(0.0, userProfile.accuracy))), color: .purple, isLarge: false, compactForLandscape: true, reduceValueForLargeText: true)
                StatisticCard(icon: "🔥", title: LocalizationManager.shared.localizedString("Current Streak"), value: "\(userProfile.streak) \(localizationManager.localizedString("days"))", color: .red, isLarge: false, compactForLandscape: true, reduceValueForLargeText: true)
                StatisticCard(icon: "💰", title: LocalizationManager.shared.localizedString("F-Bucks"), value: "\(userProfile.fBucks)", color: .yellow, isLarge: false, compactForLandscape: true)
            }
            .padding(.top, 0)
            .padding(.horizontal, 24)
            VStack(spacing: 14) {
                Button(action: shareStatistics) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(localizationManager.localizedString("Share Result"))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: 260)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                Button(action: { showingClearAlert = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text(LocalizationManager.shared.localizedString("Clear"))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: 260)
                    .background(LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .shadow(color: .red.opacity(0.35), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.top, 20)
            .scaleEffect(animateCards ? 1.0 : 0.8)
            .opacity(animateCards ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(systemGroupedBackground.ignoresSafeArea(edges: .top))
        .padding(.top, headerHeight)
        .padding(.bottom, 28)
    }

    var body: some View {
        ZStack(alignment: .top) {
                systemGroupedBackground
                    .ignoresSafeArea()

                if !isIPadLandscape { headerBackground }

                if isIPadLandscape {
                    // iPad альбомная: ScrollView на весь экран, шапка оверлеем — нет белого слоя между шапкой и контентом
                    ZStack(alignment: .top) {
                        ScrollView {
                            statisticsScrollContentLandscape
                        }
                        .modifier(HideScrollContentBackgroundModifier())
                        .background(systemGroupedBackground.ignoresSafeArea())
                        headerSectionCompact
                    }
                } else {
                    ZStack(alignment: .top) {
                        ScrollView {
                    let compact = isCompactPhone
                    let compactHeightMultiplier: CGFloat = compact ? 1.5 : 1.0
                    let gridCols: [GridItem] = compact
                        ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        : [GridItem(.flexible()), GridItem(.flexible())]
                    let stackSpacing: CGFloat = compact ? 20 : (horizontalSizeClass == .regular ? 30 : 20)
                    let gridSpacing: CGFloat = compact ? 14 : (horizontalSizeClass == .regular ? 20 : 15)
                    VStack(spacing: stackSpacing) {
                        // Статистические карточки
                        LazyVGrid(columns: gridCols, spacing: gridSpacing) {
                        StatisticCard(
                            icon: "🎮",
                            title: LocalizationManager.shared.localizedString("Total Games"),
                            value: "\(userProfile.totalGamesPlayed)",
                            color: .blue,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier
                        )
                        StatisticCard(
                            icon: "🏆",
                            title: LocalizationManager.shared.localizedString("Best Score"),
                            value: "\(userProfile.bestScore)",
                            color: .orange,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier
                        )
                        StatisticCard(
                            icon: "✅",
                            title: LocalizationManager.shared.localizedString("Correct Answers"),
                            value: "\(userProfile.correctAnswers)",
                            color: .green,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier
                        )
                        StatisticCard(
                            icon: "🎯",
                            title: LocalizationManager.shared.localizedString("Accuracy"),
                            value: String(format: "%.1f%%", min(100.0, max(0.0, userProfile.accuracy))),
                            color: .purple,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier,
                            reduceValueForLargeText: true
                        )
                        StatisticCard(
                            icon: "🔥",
                            title: LocalizationManager.shared.localizedString("Current Streak"),
                            value: "\(userProfile.streak) \(localizationManager.localizedString("days"))",
                            color: .red,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier,
                            reduceValueForLargeText: true
                        )
                        StatisticCard(
                            icon: "💰",
                            title: LocalizationManager.shared.localizedString("F-Bucks"),
                            value: "\(userProfile.fBucks)",
                            color: .yellow,
                            isLarge: horizontalSizeClass == .regular && !compact,
                            compactForLandscape: compact,
                            compactHeightMultiplier: compactHeightMultiplier
                        )
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                        }
                        .padding(.top, compact ? 8 : 4)
                        .padding(.horizontal, compact ? 24 : (horizontalSizeClass == .regular ? 40 : 20))

                    // Кнопки управления
                    VStack(spacing: compact ? 14 : (horizontalSizeClass == .regular ? 20 : 15)) {
                        Button(action: shareStatistics) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text(localizationManager.localizedString("Share Result"))
                            }
                            .font(.system(size: compact ? 16 : (horizontalSizeClass == .regular ? 22 : 17), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(compact ? 14 : (horizontalSizeClass == .regular ? 20 : 15))
                            .frame(maxWidth: compact ? 260 : (horizontalSizeClass == .regular ? 300 : 200))
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(compact ? 16 : (horizontalSizeClass == .regular ? 20 : 15))
                            .shadow(color: .blue.opacity(0.3), radius: compact ? 8 : 10, x: 0, y: compact ? 4 : 5)
                        }
                        Button(action: { showingClearAlert = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text(LocalizationManager.shared.localizedString("Clear"))
                            }
                            .font(.system(size: compact ? 16 : (horizontalSizeClass == .regular ? 22 : 17), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(compact ? 14 : (horizontalSizeClass == .regular ? 20 : 15))
                            .frame(maxWidth: compact ? 260 : (horizontalSizeClass == .regular ? 300 : 200))
                            .background(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(compact ? 16 : (horizontalSizeClass == .regular ? 20 : 15))
                            .shadow(color: .red.opacity(0.35), radius: compact ? 8 : 10, x: 0, y: compact ? 4 : 5)
                        }
                    }
                    .padding(.top, compact ? 20 : (horizontalSizeClass == .regular ? 30 : 20))
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0.0)
                    }
                .padding(.bottom, compact ? 10 : (horizontalSizeClass == .regular ? 40 : 20))
            }
            .padding(.top, contentTopInset)
                        headerContent
                    }
                }
                if isPushedFromProfile {
                    backButtonOverlay
                        .zIndex(20)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: SafeTopInsetKeyStats.self, value: geo.safeAreaInsets.top)
                        .preference(key: ContainerSizeKeyStats.self, value: geo.size)
                }
            )
            .onPreferenceChange(SafeTopInsetKeyStats.self) { safeTopInset = $0 }
            .onPreferenceChange(ContainerSizeKeyStats.self) { containerSize = $0 }
            #if os(iOS)
            // Всегда скрываем системный nav bar: заголовок и «Назад» только в нашей шапке, без дублирования и без прыжка по высоте
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            // При переходе из Профиля оставляем таб-бар видимым (API доступен с iOS 16)
            .modifier(TabBarVisibleWhenPushedModifier(visible: isPushedFromProfile))
            #endif
            .onAppear {
                #if os(iOS)
                if !isPushedFromProfile {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.backgroundEffect = nil
                    appearance.backgroundColor = .clear
                    appearance.shadowColor = .clear
                    UINavigationBar.appearance().standardAppearance = appearance
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
                }
                if isPushedFromProfile, let nav = findNavigationController() {
                    nav.interactivePopGestureRecognizer?.isEnabled = true
                    nav.interactivePopGestureRecognizer?.delegate = nil
                }
                #endif
            }
            .onDisappear {
                #if os(iOS)
                if !isPushedFromProfile {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithDefaultBackground()
                    UINavigationBar.appearance().standardAppearance = appearance
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
                }
                #endif
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text(LocalizationManager.shared.localizedString("Clear Statistics")),
                    message: Text(LocalizationManager.shared.localizedString("Are you sure you want to clear all statistics?")),
                    primaryButton: .destructive(Text(LocalizationManager.shared.localizedString("Clear"))) {
                        userProfile.totalGamesPlayed = 0
                        userProfile.correctAnswers = 0
                        userProfile.totalAnswers = 0
                        userProfile.bestScore = 0
                        userProfile.streak = 0
                        userProfile.saveToStorage()
                    },
                    secondaryButton: .cancel(Text(LocalizationManager.shared.localizedString("Cancel")))
                )
            }
            .onAppear {
                // Анимация появления
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animateCards = true
                }
        }
        .sheet(isPresented: $showingShareSheet) { ShareSheet(activityItems: shareItems) }
    }
    

}

// Градиентный фон шапки
private extension StatisticsView {
    var headerBackground: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: headerHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }

    var headerHeight: CGFloat {
        if isIPadLandscape { return 92 + safeTopInset }
        if isCompactPhone { return 142 + safeTopInset }
        return (horizontalSizeClass == .regular ? 200 : 160) + safeTopInset
    }

    var contentTopInset: CGFloat {
        if isIPadLandscape { return 0 }
        return max(0, headerHeight - 60)
    }

    /// Шапка для iPad альбомная: градиент и контент (📊 + «Статистика») по центру
    var headerSectionCompact: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 8) {
                Text("📊")
                    .font(.system(size: 48))
                Text(localizationManager.localizedString("Statistics"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, max(0, safeTopInset - 24))
        }
        .padding(.bottom, 12)
        .frame(height: 92 + safeTopInset, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }

    var headerContent: some View {
        let compact = isIPadLandscape
        return VStack(spacing: compact ? 2 : 2) {
            VStack(spacing: compact ? 4 : 4) {
                Text("📊")
                    .font(.system(size: compact ? 26 : (horizontalSizeClass == .regular ? 48 : 36)))
                Text(localizationManager.localizedString("Statistics"))
                    .font(.system(size: compact ? 15 : (horizontalSizeClass == .regular ? 24 : 20), weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, compact ? max(0, safeTopInset - 6) : max(0, safeTopInset + 2))
            .frame(height: headerHeight, alignment: .top)
        }
        .frame(height: headerHeight)
        .clipped()
    }

    @ViewBuilder
    var backButtonOverlay: some View {
        #if os(iOS)
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.leading, isIPadLandscape ? 12 : 20)
            .padding(.top, isIPadLandscape ? max(0, safeTopInset - 8) : max(0, safeTopInset - 6))
            Spacer(minLength: 0)
        }
        .frame(height: isIPadLandscape ? (92 + safeTopInset) : headerHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        #endif
    }

    #if os(iOS)
    func findNavigationController() -> UINavigationController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? windowScene.windows.first?.rootViewController else { return nil }
        return findNavigationController(in: root)
    }

    func findNavigationController(in vc: UIViewController?) -> UINavigationController? {
        guard let vc else { return nil }
        if let nav = vc as? UINavigationController { return nav }
        if let tab = vc as? UITabBarController {
            return findNavigationController(in: tab.selectedViewController) ?? findNavigationController(in: tab.viewControllers?.first)
        }
        if let split = vc as? UISplitViewController {
            return findNavigationController(in: split.viewControllers.last) ?? findNavigationController(in: split.viewControllers.first)
        }
        if let presented = vc.presentedViewController {
            return findNavigationController(in: presented)
        }
        for child in vc.children {
            if let nav = findNavigationController(in: child) { return nav }
        }
        return nil
    }
    #endif
}

// Прямоугольник со скруглением только снизу (iOS 15)
private struct BottomRoundedRect: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2, rect.width / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: true)
        path.closeSubpath()
        return path
    }
}

// Скрывает фон контента ScrollView на iOS 16+ (для устранения белой полосы)
private struct HideScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

// Модификатор видимости таб-бара (API .toolbar(for: .tabBar) доступен с iOS 16)
private struct TabBarVisibleWhenPushedModifier: ViewModifier {
    let visible: Bool
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.toolbar(visible ? .visible : .automatic, for: .tabBar)
        } else {
            content
        }
    }
}

// Safe area inset key
private struct SafeTopInsetKeyStats: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Container size for iPad landscape detection
private struct ContainerSizeKeyStats: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Поделиться статистикой
private extension StatisticsView {
    func shareStatistics() {
        var items: [Any] = []
        if let screenshot = captureScreenshot() { items.append(screenshot) }
        let message = makeStatisticsMessage()
        items.append(message)
        // Пытаемся показать напрямую через topViewController; если не удалось — откроем через .sheet
        if !presentShareController(items: items) {
            shareItems = items
            showingShareSheet = true
        }
    }

    func makeStatisticsMessage() -> String {
        let format = localizationManager.localizedString("Statistics Share Promo")
        let link = ShareService.shared.appStoreURL?.absoluteString ?? "World Arena Flags"
        return String(format: format, userProfile.bestScore, userProfile.accuracy, userProfile.totalGamesPlayed, link)
    }

    #if os(iOS)
    func captureScreenshot() -> UIImage? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { ctx in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    @discardableResult
    func presentShareController(items: [Any]) -> Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else { return false }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = controller.popoverPresentationController {
            pop.sourceView = root.view
            pop.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        root.present(controller, animated: true)
        return true
    }
    #else
    func captureScreenshot() -> NSImage? {
        return nil
    }
    
    @discardableResult
    func presentShareController(items: [Any]) -> Bool {
        return false
    }
    #endif
}

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let isLarge: Bool
    var compactForLandscape: Bool = false
    var compactHeightMultiplier: CGFloat = 1.0
    var reduceValueForLargeText: Bool = false
    @State private var animateValue = false
    @Environment(\.sizeCategory) private var sizeCategory

    private var isAccessibilityLargeText: Bool {
        sizeCategory.isAccessibilityCategory || sizeCategory >= .extraExtraLarge
    }

    private var iconSize: CGFloat {
        if compactForLandscape { return 32 }
        return isLarge ? 50 : 35
    }
    private var titleSize: CGFloat {
        if compactForLandscape { return 13 }
        return isLarge ? 18 : 12
    }
    private var valueSize: CGFloat {
        var base: CGFloat
        if compactForLandscape { base = 32 }
        else { base = isLarge ? 28 : 22 }
        return (isAccessibilityLargeText && reduceValueForLargeText) ? base * 0.5 : base
    }
    private var cardPadding: CGFloat {
        if compactForLandscape { return 14 }
        return isLarge ? 25 : 20
    }
    private var cardHeight: CGFloat {
        if compactForLandscape { return 112 * compactHeightMultiplier }
        return isLarge ? 180 : 140
    }
    private var cornerRadius: CGFloat {
        if compactForLandscape { return 16 }
        return isLarge ? 20 : 15
    }
    
    var body: some View {
        VStack(spacing: compactForLandscape ? 6 : (isLarge ? 15 : 10)) {
            Text(icon)
                .font(.system(size: iconSize))
                .scaleEffect(animateValue ? 1.2 : 1.0)
            Text(title)
                .font(.system(size: titleSize, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(value)
                .font(.system(size: valueSize, weight: .bold, design: .default))
                .foregroundColor(color)
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.35), radius: compactForLandscape ? 8 : 10, x: 0, y: compactForLandscape ? 4 : 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.5), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateValue = true
            }
        }
    }
} 