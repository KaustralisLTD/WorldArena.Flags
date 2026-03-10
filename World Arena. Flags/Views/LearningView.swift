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
                    
                    // Основной контент
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Континенты
                            continentsSection
                            
                            // Статистика флагов
                            flagStatisticsSection
                            
                            // Интересные факты
                            factsSection
                        }
                        .padding(.horizontal, isIPad ? 40 : 20)
                        .padding(.top, isIPad ? 28 : 20)
                        .padding(.bottom, isIPad ? 120 : 120)
                        .frame(maxWidth: .infinity)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 28 : 20, style: .continuous)
                            .fill(.background)
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isIPad ? 28 : 20, style: .continuous))
                    .padding(.top, isIPad ? -24 : -20)
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
    
    // MARK: - Header
    private var headerBackground: some View {
        ZStack {
            // Красивый градиентный фон
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.9),
                    Color.cyan.opacity(0.8),
                    Color.blue.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: headerHeight)
            .overlay(
                // Добавляем декоративные элементы
                ZStack {
                    // Круги для декора
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .offset(x: -50, y: -30)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                        .offset(x: 60, y: 20)
                    
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 60, height: 60)
                        .offset(x: -30, y: 60)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .ignoresSafeArea(.container, edges: .top)
            
            // Заголовок с улучшенным дизайном (на iPad поднят выше, чтобы всё помещалось)
            VStack(spacing: isIPad ? 16 : 12) {
                Spacer()
                    .frame(height: isIPad ? 8 : 20)
                
                // Иконка книги
                Image(systemName: "book.fill")
                    .font(.system(size: isIPad ? 40 : 32, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                Text(localizationManager.localizedString("Обучение"))
                    .font(.system(size: isIPad ? 38 : 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text(localizationManager.localizedString("Изучай флаги и страны мира"))
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            .frame(height: headerHeight)
            .padding(.horizontal, isIPad ? 48 : 20)
        }
    }
    
    private var headerHeight: CGFloat { (isIPad ? 260 : 240) + safeTopInset }
    
    private var contentTopInset: CGFloat {
        max(0, headerHeight - 80) // Убрали черную подложку полностью
    }
    
    // MARK: - Sections
    private var continentsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            HStack {
                Text(localizationManager.localizedString("Континенты"))
                    .font(.system(size: isIPad ? 24 : 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()

                HStack(spacing: 8) {
                    NavigationLink(destination: WorldProgressMapView().environmentObject(gameState)) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                            Text(localizationManager.localizedString("КАРТА ПРОГРЕССА"))
                                .font(.system(size: isIPad ? 15 : 13, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, isIPad ? 14 : 10)
                        .padding(.vertical, isIPad ? 10 : 6)
                        .background(Color.green.opacity(0.14))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Кнопка "ВСЕ СТРАНЫ"
                    NavigationLink(destination: AllCountriesView()) {
                        HStack(spacing: 6) {
                            Text(localizationManager.localizedString("ВСЕ СТРАНЫ"))
                                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.right")
                                .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, isIPad ? 16 : 12)
                        .padding(.vertical, isIPad ? 10 : 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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
                LearningStatCard(title: "Самый популярный цвет", value: "Красный", icon: "🔴", color: .red)
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
                FactCard(
                    title: "Самый старый флаг",
                    description: "Флаг Дании используется с 1219 года",
                    emoji: "🇩🇰"
                )
                
                FactCard(
                    title: "Единственный квадратный флаг",
                    description: "У Швейцарии единственный квадратный флаг в мире",
                    emoji: "🇨🇭"
                )
                
                FactCard(
                    title: "Самый сложный флаг",
                    description: "У Бутана на флаге изображен дракон",
                    emoji: "🇧🇹"
                )
                
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
