import SwiftUI
import UIKit

struct StatisticsView: View {
    var isPushedFromProfile: Bool = false
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingClearAlert = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private func localized(_ key: String) -> String {
        localizationManager.localizedString(key)
    }

    var body: some View {
        GeometryReader { geometry in
            let phone = UIDevice.current.userInterfaceIdiom == .phone
            let wide = geometry.size.width >= 700
            let columns = sizeCategory.isAccessibilityCategory ? 1 : (wide ? 3 : 2)
            ScrollView {
                VStack(spacing: wide ? 24 : 16) {
                    header(wide: wide, topInset: phone ? geometry.safeAreaInsets.top : nil)
                        .padding(.horizontal, phone ? -(wide ? 32 : 20) : 0)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns), spacing: 14) {
                        metric("games", image: "StatTotalGames", title: "Total Games", value: "\(userProfile.totalGamesPlayed)", color: .blue)
                        metric("best", image: "StatBestScore", title: "Best Score", value: "\(userProfile.bestScore)", color: .orange)
                        metric("correct", image: "StatCorrectAnswer", title: "Correct Answers", value: "\(userProfile.correctAnswers)", color: .green)
                        metric("accuracy", image: "StatAccuracy", title: "Accuracy", value: String(format: "%.1f%%", min(100, max(0, userProfile.accuracy))), color: .purple)
                        metric("streak", image: "StatDayStreak", title: "Current Streak", value: "\(userProfile.streak)", unit: localized("days"), color: .red)
                        metric("fbucks", image: "FBucksLogo", title: "F-Bucks", value: "\(userProfile.fBucks)", color: .blue)
                    }
                    duelSummary
                    actions
                }
                .frame(maxWidth: 1000)
                .padding(.horizontal, wide ? 32 : 20)
                .padding(.top, phone ? 0 : 16)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.container, edges: phone ? .top : [])
            .accessibilityIdentifier("statistics.scroll")
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if isPushedFromProfile, let nav = findNavigationController() {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        .alert(isPresented: $showingClearAlert) {
            Alert(
                title: Text(localized("Clear Statistics")),
                message: Text(localized("Are you sure you want to clear all statistics?")),
                primaryButton: .destructive(Text(localized("Clear"))) {
                    userProfile.totalGamesPlayed = 0
                    userProfile.correctAnswers = 0
                    userProfile.totalAnswers = 0
                    userProfile.bestScore = 0
                    userProfile.streak = 0
                    userProfile.saveToStorage()
                },
                secondaryButton: .cancel(Text(localized("Cancel")))
            )
        }
        .sheetOrFullScreenOnIPad(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private func header(wide: Bool, topInset: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isPushedFromProfile {
                Button(action: { dismiss() }) {
                    Label(localized("Back"), systemImage: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("statistics.back")
            }
            HStack(spacing: 16) {
                Image("IconStatistics")
                    .resizable().scaledToFit()
                    .frame(width: wide ? 80 : 60, height: wide ? 80 : 60)
                    .accessibilityHidden(true)
                Text(localized("Statistics"))
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("statistics.title")
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(.white)
        .padding(wide ? 28 : 20)
        .padding(.horizontal, topInset != nil ? (wide ? 32 : 20) : 0)
        .padding(.top, topInset.map { $0 + 16 } ?? 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0.18, green: 0.36, blue: 0.85), Color(red: 0.48, green: 0.30, blue: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: topInset == nil ? 24 : 0, style: .continuous))
    }

    private func metric(_ id: String, image: String, title: String, value: String, unit: String? = nil, color: Color) -> some View {
        StatisticsMetricCard(image: image, title: localized(title), value: value, unit: unit, accent: color)
            .accessibilityIdentifier("statistics.metric." + id)
    }

    private var duelSummary: some View {
        NavigationLink {
            DuelSummaryView()
                .environmentObject(gameState)
                .environmentObject(userProfile)
        } label: {
            HStack(spacing: 14) {
                Image("IconDuelSummary")
                    .resizable().scaledToFit().frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(localized("Duel Summary"))
                        .font(.headline)
                    Text("\(gameState.duelHistory.count) / \(gameState.duelHistory.filter(\.iWon).count)")
                        .font(.title2.bold()).monospacedDigit()
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("statistics.duels")
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(action: shareStatistics) {
                Label(localized("Share Result"), systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityIdentifier("statistics.share")
            Button(role: .destructive, action: { showingClearAlert = true }) {
                Label(localized("Clear Statistics"), systemImage: "trash")
                    .font(.subheadline.weight(.medium))
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .accessibilityIdentifier("statistics.clear")
        }
        .buttonStyle(.plain)
    }
}

private struct StatisticsMetricCard: View {
    let image: String
    let title: String
    let value: String
    let unit: String?
    let accent: Color

    private var compact: Bool { UIDevice.current.userInterfaceIdiom == .phone }

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: compact ? 6 : 10) {
            Image(image)
                .resizable().scaledToFit()
                .frame(width: compact ? 42 : 48, height: compact ? 42 : 48)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(compact ? .center : .leading)
                .frame(minHeight: compact ? 34 : 40, alignment: compact ? .center : .topLeading)
                .fixedSize(horizontal: false, vertical: true)
            if compact {
                (Text(value).font(.title.bold()) + Text(unit.map { " " + $0 } ?? "").font(.caption))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.largeTitle.bold()).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(unit ?? " ")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(unit == nil)
                }
            }
        }
        .padding(compact ? 12 : 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: compact ? .center : .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            Circle().fill(accent.opacity(0.65)).frame(width: 6, height: 6).padding(compact ? 14 : 20)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension StatisticsView {
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
