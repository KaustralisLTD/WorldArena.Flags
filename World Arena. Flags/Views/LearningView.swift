import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LearningView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var safeTopInset: CGFloat = 0
    @State private var selectedContinent: String? = nil
    @State private var showingFacts = false
    
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad || horizontalSizeClass == .regular
        #else
        return horizontalSizeClass == .regular
        #endif
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон
                LinearGradient(
                    colors: Color.appGradientColors(for: themeManager.colorScheme),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Закреплённая шапка
                    headerBackground
                    
                    // Основной контент (без отступа от шапки, в тёмной теме фон как у экрана)
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            continentsSection
                            flagStatisticsSection
                            factsSection
                        }
                        .padding(.horizontal, isIPad ? 40 : 20)
                        .padding(.top, isIPad ? 16 : 12)
                        .padding(.bottom, isIPad ? 120 : 120)
                        .frame(maxWidth: .infinity)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 28 : 20, style: .continuous)
                            .fill(learningContentBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPad ? 28 : 20, style: .continuous)
                                    .stroke(Color.primary.opacity(themeManager.colorScheme == .dark ? 0.15 : 0.08), lineWidth: 1)
                            )
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isIPad ? 28 : 20, style: .continuous))
                    .padding(.top, isIPad ? -32 : -28)
                }
            }
            .frame(maxWidth: .infinity)
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: SafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
            })
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                // Обновляем при изменении ориентации
            }
            #endif
            .onPreferenceChange(SafeTopInsetKey.self) { value in
                safeTopInset = value
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        #endif
    }
    
    // MARK: - Header (фиксированная высота без «поплывания»)
    private static let headerBaseHeight: CGFloat = 200
    private var headerHeight: CGFloat { Self.headerBaseHeight + safeTopInset }

    private var headerBackground: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.92),
                    Color.cyan.opacity(0.82),
                    Color.blue.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: headerHeight)
            .overlay(
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                        .offset(x: -60, y: -20)
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 70, height: 70)
                        .blur(radius: 15)
                        .offset(x: 70, y: 30)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .ignoresSafeArea(.container, edges: .top)

            VStack(spacing: isIPad ? 14 : 10) {
                Image(systemName: "book.fill")
                    .font(.system(size: isIPad ? 36 : 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .symbolRenderingMode(.hierarchical)
                Text(localizationManager.localizedString("Обучение"))
                    .font(.system(size: isIPad ? 34 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(localizationManager.localizedString("Изучай флаги и страны мира"))
                    .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, safeTopInset + (isIPad ? 20 : 16))
            .padding(.horizontal, isIPad ? 48 : 24)
            .frame(height: headerHeight, alignment: .top)
        }
    }
    
    private var contentTopInset: CGFloat {
        max(0, headerHeight - 80)
    }

    /// Фон блока контента: в тёмной теме — как основной экран (без белого), в светлой — системный.
    private var learningContentBackground: Color {
        themeManager.colorScheme == .dark
            ? Color(red: 0.06, green: 0.06, blue: 0.18)
            : Color(UIColor.systemGroupedBackground).opacity(0.96)
    }
    
    // MARK: - Sections
    private var continentsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 18 : 14) {
            Text(localizationManager.localizedString("Континенты"))
                .font(.system(size: isIPad ? 22 : 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                NavigationLink(destination: WorldProgressMapView().environmentObject(gameState)) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(localizationManager.localizedString("КАРТА ПРОГРЕССА"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: AllCountriesView()) {
                    HStack(spacing: 6) {
                        Text(localizationManager.localizedString("ВСЕ СТРАНЫ"))
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer(minLength: 0)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: isIPad ? 4 : (horizontalSizeClass == .regular ? 3 : 2)), spacing: isIPad ? 20 : 16) {
                NavigationLink(destination: ContinentDetailView(continentName: "Европа", continentEmoji: "🇪🇺")) {
                    ContinentCard(name: "Европа", emoji: "🇪🇺", countries: 44, description: "Самый маленький континент")
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ContinentDetailView(continentName: "Азия", continentEmoji: "🌏")) {
                    ContinentCard(name: "Азия", emoji: "🌏", countries: 48, description: "Самый большой континент")
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ContinentDetailView(continentName: "Африка", continentEmoji: "🌍")) {
                    ContinentCard(name: "Африка", emoji: "🌍", countries: 54, description: "Колыбель человечества")
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ContinentDetailView(continentName: "Северная Америка", continentEmoji: "🌎")) {
                    ContinentCard(name: "Северная Америка", emoji: "🌎", countries: 23, description: "Новый свет")
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ContinentDetailView(continentName: "Южная Америка", continentEmoji: "🌎")) {
                    ContinentCard(name: "Южная Америка", emoji: "🌎", countries: 12, description: "Земля контрастов")
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ContinentDetailView(continentName: "Океания", continentEmoji: "🏝️")) {
                    ContinentCard(name: "Океания", emoji: "🏝️", countries: 14, description: "Острова Тихого океана")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var flagStatisticsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            Text(localizationManager.localizedString("Статистика флагов"))
                .font(.system(size: isIPad ? 24 : 20, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: isIPad ? 4 : 2), spacing: isIPad ? 20 : 16) {
                LearningStatCard(title: "Всего стран", value: "195", icon: "🌍", color: .blue)
                LearningStatCard(title: "Цветов на флагах", value: "12", icon: "🎨", color: .green)
                LearningStatCard(title: "Самый популярный цвет", value: localizationManager.localizedString("Red"), icon: "🔴", color: .red)
                LearningStatCard(title: "Флагов с крестом", value: "29", icon: "✝️", color: .purple)
            }
        }
    }
    
    private var factsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            // Кликабельный заголовок "Интересные факты"
            NavigationLink(destination: InterestingFactsView()) {
                HStack {
                    Text(localizationManager.localizedString("Интересные факты"))
                        .font(.system(size: isIPad ? 24 : 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: isIPad ? 16 : 12) {
                ForEach(Array(learningFactsPreview.enumerated()), id: \.offset) { _, fact in
                    FactCard(
                        title: fact.title,
                        description: fact.description,
                        emoji: fact.emoji
                    )
                }
                
                // Кнопка "More facts"
                NavigationLink(destination: InterestingFactsView()) {
                    HStack {
                        Text(localizationManager.localizedString("More facts"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var learningFactsPreview: [(title: String, description: String, emoji: String)] {
        (1...3).map { i in
            (
                localizationManager.localizedString(InterestingFactsData.factTitleKey(i)),
                localizationManager.localizedString(InterestingFactsData.factDescKey(i)),
                InterestingFactsData.emoji(forFactIndex: i)
            )
        }
    }
}

// MARK: - Components
struct ContinentCard: View {
    let name: String
    let emoji: String
    let countries: Int
    let description: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 40))
            
            Text(localizationManager.localizedString(name))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("\(countries) \(localizationManager.localizedString("стран"))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(localizationManager.localizedString(description))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct LearningStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 30))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(localizationManager.localizedString(title))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FactCard: View {
    let title: String
    let description: String
    let emoji: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(localizationManager.localizedString(title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(localizationManager.localizedString(description))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
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
    LearningView()
        .environmentObject(GameState())
}
