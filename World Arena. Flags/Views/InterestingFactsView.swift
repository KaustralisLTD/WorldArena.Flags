import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct InterestingFactsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var safeTopInset: CGFloat = 0
    @State private var slidesMode = false
    @State private var slideIndex = 0

    private var listScrollBackgroundColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(NSColor.textBackgroundColor)
        #endif
    }

    private var facts: [InterestingFact] {
        (1...InterestingFactsData.factCount).map { index in
            let key = String(format: "FACT_%02d", index)
            return InterestingFact(
                title: localizationManager.localizedString("\(key)_TITLE"),
                description: localizationManager.localizedString("\(key)_DESC"),
                emoji: InterestingFactsData.emoji(forFactIndex: index)
            )
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Color.appGradientColors(for: themeManager.colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if slidesMode {
                slidesModeContent
            } else {
                listModeContent
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .background(GeometryReader { geometry in
            Color.clear
                .preference(key: SafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
        })
        .onPreferenceChange(SafeTopInsetKey.self) { value in
            safeTopInset = value
        }
    }

    // MARK: - List mode

    private var listModeContent: some View {
        VStack(spacing: 0) {
            listHeader

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                        FactDetailCard(fact: fact, number: index + 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(listScrollBackgroundColor)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, y: -4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .offset(y: -12)
        }
    }

    private var listHeader: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.22))
                        .clipShape(Circle())
                }
                .padding(.top, 2)

                VStack(spacing: 10) {
                    Text(localizationManager.localizedString("Интересные факты"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(.white, .yellow.opacity(0.9))
                        .symbolRenderingMode(.palette)

                    Text("\(facts.count) \(localizationManager.localizedString("фактов о флагах и странах"))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Button {
                        slideIndex = 0
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            slidesMode = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(localizationManager.localizedString("Interesting facts study slides"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.22))
                                .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)

                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, max(safeTopInset, 12))
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [Color.cyan.opacity(0.88), Color.blue.opacity(0.72), Color.purple.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: [.top, .horizontal])
        }
    }

    // MARK: - Slides mode

    /// Верхняя панель вынесена из overlay ZStack — иначе на части устройств она визуально «плывёт» к центру.
    private var slidesModeContent: some View {
        VStack(spacing: 0) {
            slidesHeaderChrome
            ZStack {
                TabView(selection: $slideIndex) {
                    ForEach(0..<facts.count, id: \.self) { i in
                        InterestingFactSlidePage(
                            fact: facts[i],
                            index: i + 1,
                            total: facts.count,
                            themeColors: Color.appGradientColors(for: themeManager.colorScheme)
                        )
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(alignment: .center) {
                    slideChevron(direction: -1)
                    Spacer(minLength: 0)
                    slideChevron(direction: 1)
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    /// Полоса под статус-бар: материал + нижняя граница — панель всегда сверху, не наезжает на текст слайда.
    private var slidesHeaderChrome: some View {
        VStack(spacing: 0) {
            slidesTopBar
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.1))
                .frame(height: 1)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var slidesTopBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                    slidesMode = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 15, weight: .semibold))
                    Text(localizationManager.localizedString("Interesting facts back to list"))
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Text("\(slideIndex + 1) / \(facts.count)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, max(safeTopInset, 12))
        .padding(.bottom, 10)
    }

    private func slideChevron(direction: Int) -> some View {
        let canGo = direction < 0 ? slideIndex > 0 : slideIndex < facts.count - 1
        return Button {
            guard canGo else { return }
            withAnimation(.easeInOut(duration: 0.28)) {
                slideIndex += direction
            }
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .disabled(!canGo)
        .opacity(canGo ? 1 : 0.28)
    }
}

// MARK: - Full-screen slide page

private struct InterestingFactSlidePage: View {
    let fact: InterestingFact
    let index: Int
    let total: Int
    let themeColors: [Color]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        themeColors.first?.opacity(0.55) ?? .blue.opacity(0.5),
                        Color.black.opacity(0.35),
                        themeColors.last?.opacity(0.45) ?? .purple.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 0) {
                    // Верхняя панель — снаружи TabView; здесь только отступ контента от области слайда
                    Spacer(minLength: 12)

                    Text(fact.emoji)
                        .font(.system(size: min(geo.size.width * 0.18, 88)))
                        .padding(.bottom, 16)

                    Text(fact.title)
                        .font(.system(size: min(geo.size.width * 0.055, 24), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)

                    ScrollView(showsIndicators: false) {
                        Text(fact.description)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 28)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                    }
                    .frame(maxHeight: geo.size.height * 0.42)

                    Spacer(minLength: geo.safeAreaInsets.bottom + 20)

                    slideProgressBar(trackWidth: max(0, geo.size.width - 80), index: index, total: total)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(edges: [.bottom])
    }

    private func slideProgressBar(trackWidth: CGFloat, index: Int, total: Int) -> some View {
        let progress = CGFloat(index) / CGFloat(max(total, 1))
        let fillW = max(10, trackWidth * progress)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: trackWidth, height: 5)
            Capsule()
                .fill(Color.white)
                .frame(width: fillW, height: 5)
        }
        .frame(width: trackWidth, height: 5)
    }
}

// MARK: - FactDetailCard

struct FactDetailCard: View {
    let fact: InterestingFact
    let number: Int

    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)

                Spacer()

                Text(fact.emoji)
                    .font(.system(size: 30))
            }

            Text(fact.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text(fact.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - InterestingFact Model

struct InterestingFact {
    let title: String
    let description: String
    let emoji: String
}

// MARK: - Facts Data (68 facts, key-based localization)

enum InterestingFactsData {
    static let factCount = 68
    /// Подрегиональные флаги GB (iOS отображает как 🏴󠁧󠁢󠁷󠁬󠁳󠁿 / 🏴󠁧󠁢󠁳󠁣󠁴󠁿).
    private static let flagWales = "\u{1F3F4}\u{E0067}\u{E0062}\u{E0077}\u{E006C}\u{E0073}\u{E007F}"
    private static let flagScotland = "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}"

    /// Ровно по одному символу на факт FACT_01…FACT_68 (содержание строк локализации в ru/en).
    private static let factEmojis: [String] = [
        "🇩🇰", "🇨🇭", "🇳🇵", "🇯🇲", "🇸🇦", "🇸🇸", "🇲🇿", "🇷🇴", "🇺🇦", "🇱🇾",
        "🇨🇾", "🇩🇴", "🔴", "🇸🇦", "🇹🇭", "🇵🇾", "🏅", "🇲🇽", "🇲🇨", "🇺🇸",
        "🇬🇱", "✝️", "🇫🇷", "☪️", "☀️", "🇱🇧", "🇶🇦", "🌎", "🌈", "🇰🇭",
        "⚔️", "🇱🇰", "🇯🇲", "🦅", "🇦🇶", "⭐", "🇸🇬", "🌍", "🏝️", "🕰️",
        "🇲🇰", "🇧🇿", "🇪🇨", "🇧🇴", "🇧🇷", "🇨🇦", "🇬🇧", "🇯🇵", "🇮🇳", "🇦🇺",
        "🇳🇿", "🇰🇷", "🇵🇹", "🇦🇱", "🇰🇪", flagWales, flagScotland, "🇬🇱", "🇪🇹", "🇸🇪",
        "🇫🇷", "🇺🇳", "🇪🇺", "🏅", "🇻🇦", "🇳🇷", "🇹🇲", "🇦🇫"
    ]

    static func emoji(forFactIndex index: Int) -> String {
        let i = index - 1
        guard i >= 0, i < factEmojis.count, factEmojis.count == factCount else { return "🏳️" }
        return factEmojis[i]
    }

    static func factTitleKey(_ index: Int) -> String { "FACT_\(String(format: "%02d", index))_TITLE" }
    static func factDescKey(_ index: Int) -> String { "FACT_\(String(format: "%02d", index))_DESC" }
}

// MARK: - SafeTopInsetKey

private struct SafeTopInsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    InterestingFactsView()
}
