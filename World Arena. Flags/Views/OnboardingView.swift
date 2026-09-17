import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Hook question (лёгкий «реальный» раунд, без сети — flagcdn + локализованные имена из БД)

private struct OnboardingHookQuestion {
    let correctISO2: String
    let distractorISO2: [String]

    static let `default` = OnboardingHookQuestion(correctISO2: "FR", distractorISO2: ["DE", "IT", "ES"])

    func shuffledOptions() -> [String] {
        ([correctISO2] + distractorISO2).shuffled()
    }

    static func flagURL(iso2: String) -> URL {
        URL(string: "https://flagcdn.com/w320/\(iso2.lowercased()).png")!
    }
}

private enum OnboardingSlide: Int, CaseIterable {
    case hook = 0
    case reward = 1
    case loop = 2
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) private var colorScheme

    /// iPad: крупнее типографика и узкие кнопки вариантов по центру.
    private var isPadHookLayout: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    @State private var currentPage = 0
    @State private var hookAnswered = false
    @State private var selectedWrongISO2: String?
    @State private var showLanguageSheet = false
    @State private var dismissLanguageHint = false
    @State private var ctaPulseScale: CGFloat = 1.0
    @State private var hookInteractionLocked = false

    private let hookQuestion = OnboardingHookQuestion.default
    @State private var optionOrder: [String] = OnboardingHookQuestion.default.shuffledOptions()

    private static let hasCompletedOnboardingKey = "onboarding.hasCompletedFullScreen.v2"

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
    }

    private var isLastSlide: Bool {
        currentPage == OnboardingSlide.loop.rawValue
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.45, blue: 0.98),
                Color(red: 0.55, green: 0.35, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundGradient: LinearGradient {
        let colors: [Color] = colorScheme == .dark
            ? [
                Color(red: 0.06, green: 0.06, blue: 0.18),
                Color(red: 0.1, green: 0.08, blue: 0.22),
                Color(red: 0.08, green: 0.1, blue: 0.25)
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(red: 0.9, green: 0.94, blue: 1.0),
                Color(red: 0.85, green: 0.9, blue: 1.0)
            ]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var effectiveLanguageButtonTitle: String {
        if gameState.selectedLanguage == .system {
            let code = localizationManager.currentBundleLanguageCode
            let name = Locale.current.localizedString(forIdentifier: code)
                ?? Locale.current.localizedString(forLanguageCode: code)
                ?? code
            return name
        }
        return gameState.selectedLanguage.displayName
    }

    private var shouldShowSystemLanguageHint: Bool {
        if dismissLanguageHint { return false }
        guard let saved = UserDefaults.standard.string(forKey: "selectedLanguage"), saved != GameState.Language.system.rawValue else {
            return false
        }
        let systemResolved = LocalizationLanguageResolver.resolveLanguageCode(saved: nil)
        let appResolved = localizationManager.currentBundleLanguageCode
        return appResolved != systemResolved
    }

    private var hintTargetLanguage: GameState.Language? {
        let systemResolved = LocalizationLanguageResolver.resolveLanguageCode(saved: nil)
        return Self.gameLanguage(fromBundleCode: systemResolved)
    }

    private static func gameLanguage(fromBundleCode code: String) -> GameState.Language? {
        let c = code.lowercased()
        if c.hasPrefix("en") { return .english }
        if c.hasPrefix("ru") { return .russian }
        if c.hasPrefix("es") { return .spanish }
        if c.hasPrefix("uk") { return .ukrainian }
        if c.hasPrefix("ca") { return .catalan }
        if c.hasPrefix("zh-hant") || c == "zh-tw" || c == "zh-hk" { return .chineseTraditional }
        if c.hasPrefix("zh") { return .chinese }
        if c.hasPrefix("de") { return .german }
        if c.hasPrefix("fr") { return .french }
        if c.hasPrefix("it") { return .italian }
        if c.hasPrefix("pt") { return .portugueseBrazil }
        if c.hasPrefix("pl") { return .polish }
        if c.hasPrefix("nl") { return .dutch }
        if c.hasPrefix("hi") { return .hindi }
        if c.hasPrefix("cs") { return .czech }
        if c.hasPrefix("sv") { return .swedish }
        if c.hasPrefix("ja") { return .japanese }
        if c.hasPrefix("ar") { return .arabic }
        if c.hasPrefix("bn") { return .bengali }
        if c.hasPrefix("hu") { return .hungarian }
        if c.hasPrefix("vi") { return .vietnamese }
        if c.hasPrefix("el") { return .greek }
        if c.hasPrefix("id") { return .indonesian }
        if c.hasPrefix("ko") { return .korean }
        if c.hasPrefix("ro") { return .romanian }
        if c.hasPrefix("th") { return .thai }
        if c.hasPrefix("ta") { return .tamil }
        if c.hasPrefix("te") { return .telugu }
        if c.hasPrefix("tr") { return .turkish }
        if c.hasPrefix("fil") { return .filipino }
        return nil
    }

    var body: some View {
        ZStack {
            // Без горизонтального offset: иначе при смене слайда «уезжает» градиент и справа видна полоса фона ZStack.
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    hookPage
                        .tag(OnboardingSlide.hook.rawValue)
                    rewardPage
                        .tag(OnboardingSlide.reward.rawValue)
                    loopPage
                        .tag(OnboardingSlide.loop.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.32), value: currentPage)

                bottomSection
            }
        }
        .onAppear {
            optionOrder = hookQuestion.shuffledOptions()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).prepare()
            #endif
        }
        .onChange(of: currentPage) { newPage in
            if newPage == OnboardingSlide.reward.rawValue && !hookAnswered {
                DispatchQueue.main.async { currentPage = OnboardingSlide.hook.rawValue }
            }
            if newPage == OnboardingSlide.loop.rawValue {
                ctaPulseScale = 1.0
                withAnimation(.easeInOut(duration: 0.88).repeatForever(autoreverses: true)) {
                    ctaPulseScale = 1.03
                }
            }
        }
        .sheet(isPresented: $showLanguageSheet) {
            OnboardingLanguagePickerSheet()
                .environmentObject(gameState)
                #if os(iOS)
                .modifier(OnboardingLanguageSheetChromeModifier())
                #endif
        }
    }

    // MARK: Top bar (язык + подсказка)

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    showLanguageSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("🌐")
                        Text(effectiveLanguageButtonTitle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            if shouldShowSystemLanguageHint, let target = hintTargetLanguage {
                Button {
                    Task { @MainActor in
                        await gameState.setLanguage(target)
                        dismissLanguageHint = true
                    }
                } label: {
                    Text(
                        String(
                            format: localizationManager.localizedString("onboarding_switch_language_hint"),
                            target.displayName
                        )
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accentGradient, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Page 1 — Hook

    private var hookPage: some View {
        OnboardingHookPageView(
            optionOrder: optionOrder,
            correctISO2: hookQuestion.correctISO2,
            selectedWrongISO2: selectedWrongISO2,
            interactionLocked: hookInteractionLocked,
            localizationManager: localizationManager,
            accentGradient: accentGradient,
            isPadLayout: isPadHookLayout,
            onSelect: { iso2 in
                handleHookSelection(iso2: iso2)
            }
        )
    }

    private func handleHookSelection(iso2: String) {
        guard !hookInteractionLocked else { return }
        hookInteractionLocked = true
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        if iso2 == hookQuestion.correctISO2 {
            selectedWrongISO2 = nil
        } else {
            selectedWrongISO2 = iso2
        }
        hookAnswered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                currentPage = OnboardingSlide.reward.rawValue
            }
        }
    }

    // MARK: Page 2 — Reward

    private var rewardPage: some View {
        OnboardingRewardPageView(
            localizationManager: localizationManager,
            accentGradient: accentGradient,
            wasWrong: selectedWrongISO2 != nil,
            correctCountryName: countryName(for: hookQuestion.correctISO2)
        )
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                if currentPage == OnboardingSlide.reward.rawValue {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage = OnboardingSlide.loop.rawValue
                    }
                }
            }
        }
    }

    // MARK: Page 3 — Loop

    private var loopPage: some View {
        OnboardingLoopPageView(
            localizationManager: localizationManager,
            accentGradient: accentGradient,
            isPadLayout: isPadHookLayout
        )
    }

    private func countryName(for iso2: String) -> String {
        let enFallback = CountryDatabase.getCountryData(for: iso2)?.en.name ?? iso2
        return localizationManager.localizedCountryDisplayName(iso2Code: iso2, englishFallback: enFallback)
    }

    // MARK: Bottom

    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageIndicator

            if isLastSlide {
                HStack {
                    Spacer(minLength: 0)
                    Button(action: finishOnboarding) {
                        Text(localizationManager.localizedString("onboarding_start_playing"))
                            .font(.system(size: isPadHookLayout ? 20 : 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: isPadHookLayout ? 520 : .infinity)
                            .frame(height: isPadHookLayout ? 60 : 56)
                            .background(accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .scaleEffect(ctaPulseScale)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
            } else {
                Text(localizationManager.localizedString("onboarding_swipe_hint"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .frame(height: 56)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 44)
        .padding(.top, 8)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingSlide.allCases, id: \.rawValue) { slide in
                let active = currentPage == slide.rawValue
                Group {
                    if active {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accentGradient)
                            .frame(width: 20, height: 6)
                    } else {
                        Circle()
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.28 : 0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentPage)
            }
        }
    }

    private func finishOnboarding() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        OnboardingView.markCompleted()
        NotificationCenter.default.post(name: Notification.Name("OnboardingDidFinish"), object: nil)
        withAnimation(.easeOut(duration: 0.35)) {
            isPresented = false
        }
    }

}

// MARK: - Hook page

private struct OnboardingHookPageView: View {
    let optionOrder: [String]
    let correctISO2: String
    let selectedWrongISO2: String?
    let interactionLocked: Bool
    let localizationManager: LocalizationManager
    let accentGradient: LinearGradient
    /// Узкие по ширине варианты по центру, крупнее шрифты.
    let isPadLayout: Bool
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var illustrationScale: CGFloat = 0.9
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0

    private var optionsColumnMaxWidth: CGFloat { isPadLayout ? 480 : .infinity }

    var body: some View {
        VStack(spacing: isPadLayout ? 26 : 20) {
            Spacer(minLength: 12)

            Text(localizationManager.localizedString("onboarding_hook_title"))
                .font(.system(size: isPadLayout ? 32 : 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .offset(y: titleOffset)
                .opacity(titleOpacity)

            Text(localizationManager.localizedString("onboarding_hook_subtitle"))
                .font(.system(size: isPadLayout ? 17 : 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .offset(y: titleOffset * 0.6)
                .opacity(titleOpacity)

            CachedAsyncImage(url: OnboardingHookQuestion.flagURL(iso2: correctISO2)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(flagPlaceholderFill)
                    .overlay { ProgressView() }
            }
            .frame(maxHeight: isPadLayout ? 200 : 140)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08), lineWidth: 1)
            )
            .shadow(color: flagCardShadowColor, radius: colorScheme == .dark ? 10 : 12, y: 6)
            .scaleEffect(illustrationScale)
            .padding(.horizontal, isPadLayout ? 48 : 36)

            VStack(spacing: isPadLayout ? 14 : 10) {
                ForEach(optionOrder, id: \.self) { iso2 in
                    hookOptionButton(iso2: iso2)
                }
            }
            .frame(maxWidth: optionsColumnMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            Spacer(minLength: 100)
        }
        .onAppear {
            illustrationScale = 0.9
            titleOffset = 20
            titleOpacity = 0
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                illustrationScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.38).delay(0.12)) {
                titleOffset = 0
                titleOpacity = 1
            }
        }
    }

    private var flagPlaceholderFill: Color {
        #if os(iOS)
        Color(UIColor.tertiarySystemFill)
        #elseif os(macOS)
        Color(nsColor: .quaternaryLabelColor).opacity(0.35)
        #else
        Color.gray.opacity(0.2)
        #endif
    }

    private var flagCardShadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.55)
            : Color.black.opacity(0.12)
    }

    private var optionFillColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.15)
        #endif
    }

    private func hookOptionButton(iso2: String) -> some View {
        let name = countryDisplayName(iso2: iso2)
        let isWrongSelected = selectedWrongISO2 == iso2
        let isCorrectSelected = interactionLocked && selectedWrongISO2 == nil && iso2 == correctISO2
        let showBorder = isWrongSelected || isCorrectSelected
        return Button {
            onSelect(iso2)
        } label: {
            Text(name)
                .font(.system(size: isPadLayout ? 20 : 17, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, isPadLayout ? 18 : 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(optionFillColor)
            )
            .overlay {
                if showBorder {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(accentGradient, lineWidth: 2.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(interactionLocked)
    }

    private func countryDisplayName(iso2: String) -> String {
        let enFallback = CountryDatabase.getCountryData(for: iso2)?.en.name ?? iso2
        return localizationManager.localizedCountryDisplayName(iso2Code: iso2, englishFallback: enFallback)
    }
}

// MARK: - Reward page

private struct OnboardingRewardPageView: View {
    let localizationManager: LocalizationManager
    let accentGradient: LinearGradient
    let wasWrong: Bool
    let correctCountryName: String

    @Environment(\.colorScheme) private var colorScheme

    @State private var illustrationScale: CGFloat = 0.9
    @State private var burst = false

    private var rewardGlowOpacity: Double {
        colorScheme == .dark ? 0.32 : 0.2
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .fill(accentGradient.opacity(rewardGlowOpacity))
                    .frame(width: burst ? 140 : 100, height: burst ? 140 : 100)
                    .blur(radius: 8)

                Image(systemName: wasWrong ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(accentGradient)
                    .scaleEffect(illustrationScale)
            }
            .padding(.vertical, 8)

            Text(
                wasWrong
                    ? String(format: localizationManager.localizedString("onboarding_reward_almost"), correctCountryName)
                    : localizationManager.localizedString("onboarding_reward_correct")
            )
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Text(localizationManager.localizedString("onboarding_reward_plus_one"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentGradient)

            Text(localizationManager.localizedString("onboarding_reward_streak"))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer(minLength: 100)
        }
        .onAppear {
            illustrationScale = 0.9
            burst = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                illustrationScale = 1.0
                burst = true
            }
        }
    }
}

// MARK: - Loop page

private struct OnboardingLoopPageView: View {
    let localizationManager: LocalizationManager
    let accentGradient: LinearGradient
    let isPadLayout: Bool

    @State private var illustrationScale: CGFloat = 0.9
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 18

    var body: some View {
        VStack(alignment: isPadLayout ? .center : .leading, spacing: isPadLayout ? 22 : 16) {
            Spacer(minLength: 20)

            Group {
                if isPadLayout {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(accentGradient)
                        .scaleEffect(illustrationScale)
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentGradient)
                            .scaleEffect(illustrationScale)
                        Spacer()
                    }
                }
            }

            VStack(alignment: isPadLayout ? .center : .leading, spacing: isPadLayout ? 16 : 12) {
                loopLine("onboarding_loop_line1")
                loopLine("onboarding_loop_line2")
                loopLine("onboarding_loop_line3")
            }
            .frame(maxWidth: isPadLayout ? 560 : .infinity)
            .padding(.horizontal, 32)
            .opacity(titleOpacity)
            .offset(y: titleOffset)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            illustrationScale = 0.9
            titleOpacity = 0
            titleOffset = 18
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                illustrationScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.38).delay(0.14)) {
                titleOpacity = 1
                titleOffset = 0
            }
        }
    }

    private func loopLine(_ key: String) -> some View {
        Group {
            if isPadLayout {
                HStack {
                    Spacer(minLength: 0)
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(accentGradient)
                        Text(localizationManager.localizedString(key))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 520, alignment: .leading)
                    Spacer(minLength: 0)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(accentGradient)
                    Text(localizationManager.localizedString(key))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Language sheet

private struct OnboardingLanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var search = ""

    private var filteredLanguages: [GameState.Language] {
        let base = GameState.Language.allCases.filter { $0 != .system }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return base }
        return base.filter {
            $0.displayName.lowercased().contains(q) || $0.rawValue.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(localizationManager.localizedString("onboarding_language_sheet_title"))
                .font(.headline)
                .padding(.top, 12)

            TextField(localizationManager.localizedString("onboarding_search_language"), text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredLanguages, id: \.self) { language in
                        Button {
                            Task { @MainActor in
                                await gameState.setLanguage(language)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if gameState.selectedLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #elseif os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
    }
}

#if os(iOS)
/// Детенты/blur для sheet языка — API с iOS 16+ / 16.4+, иначе обычный sheet.
private struct OnboardingLanguageSheetChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        } else if #available(iOS 16.0, *) {
            content
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
#endif

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(GameState())
}
