import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct MonthlyQuestsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showCelebration = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var safeTopInset: CGFloat = 0
    @StateObject private var questService = QuestService.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    private var screenWidth: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #else
        return 800 // Fallback для macOS
        #endif
    }
    
    var body: some View {
        ZStack(alignment: .top) {
                // Базовый фон под всем контентом, чтобы не было черных полос
                systemGroupedBackground
                    .ignoresSafeArea()

                // Градиентный фон шапки под статус-баром
                headerBackground

                VStack(spacing: 0) {
                    // Закрепленная шапка (контент)
                    headerSection

                    // Скроллируемый контент
                    ScrollView {
                        VStack(spacing: 0) {
                            // Ежедневные квесты
                            dailyQuestsSection

                            // Месячные квесты
                            monthlyQuestsSection
                        }
                        .padding(.top, 20) // Добавляем отступ сверху
                    }
                    .refreshable { await refreshQuestsContent() }
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(systemGroupedBackground)
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .padding(.top, -10) // Немного поднимаем для лучшего перехода
                }
            }
            // Считываем safe area inset сверху один раз на экране
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: SafeTopInsetKey.self, value: geo.safeAreaInsets.top)
                }
            )
            .onPreferenceChange(SafeTopInsetKey.self) { value in
                safeTopInset = value
            }
            // Keep header pinned and remove duplicate title above
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
            }
            .onDisappear {
                #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                #endif
        }
    }

    @MainActor
    private func refreshQuestsContent() async {
        questService.loadDailyQuests()
        userProfile.generateMonthlyQuests()
        userProfile.saveToStorage()
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Заголовок месяца
            HStack {
                VStack(alignment: .leading) {
                    Text(getCurrentMonthMissionTitle())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: "clock")
                        Text(daysLeftLabel())
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Персонаж
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 20)

                    Text("🎯")
                        .font(.system(size: 40))
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 8)
            .padding(.top, max(0, safeTopInset - (isIPad ? 72 : 24)))

            // Основной прогресс
            VStack(spacing: 10) {
                Text(localizationManager.localizedString("Заработай 40 очков квеста"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                // Progress bar
                ZStack(alignment: .leading) {
                    // Белая карточка
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                        .frame(height: 20)

                    // Серый бэк прогресса внутри
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 12)
                        .padding(.horizontal, 16)

                    // Полоска прогресса
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: progressWidth, height: 12)
                        .padding(.horizontal, 16)
                        .animation(.easeInOut(duration: 0.5), value: progressWidth)
                }

                HStack {
                    Text("\(Int(totalMonthlyProgress)) / 40")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .accessibilityLabel("monthly_progress_value")
                    Spacer()
                }
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.bottom, isIPad ? 24 : 20)
        }
        .frame(height: 148 + safeTopInset, alignment: .top)
    }

    private var headerBackground: some View {
        LinearGradient(
            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 185 + safeTopInset)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }
    
    private var progressWidth: CGFloat {
        let padding: CGFloat = isIPad ? 80 : 40 // Учитываем увеличенные отступы для iPad
        let width = screenWidth - padding
        return width * (totalMonthlyProgress / 40.0)
    }

    // Совокупный прогресс по месяцу из массива monthlyQuests (среднее по прогрессам * 40)
    private var totalMonthlyProgress: Double {
        let quests = userProfile.monthlyQuests
        guard !quests.isEmpty else { return 0 }
        let avg = quests.map { $0.isCompleted ? 1.0 : $0.progress }.reduce(0, +) / Double(quests.count)
        return (avg * 40.0).rounded()
    }

    // MARK: - Days left in current month (localized short label)
    private var daysLeftInMonth: Int {
        let today = Date()
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: today) else { return 0 }
        let day = calendar.component(.day, from: today)
        return max(0, range.count - day) // остаток дней до конца месяца
    }

    private func daysLeftLabel() -> String {
        let n = daysLeftInMonth
        let lang = LocalizationManager.shared.currentLocale.languageCode ?? Locale.current.languageCode ?? Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
        switch lang {
        case "ru":
            // 1 день, 2-4 дня, 5-20 дней, 21 день, 22-24 дня, 25-30 дней, 31 день
            let lastTwo = n % 100
            let last = n % 10
            let word: String
            if lastTwo >= 11 && lastTwo <= 14 {
                word = "дней"
            } else if last == 1 {
                word = "день"
            } else if (2...4).contains(last) {
                word = "дня"
            } else {
                word = "дней"
            }
            return "\(n) \(word)"
        case "uk":
            // 1 день, 2-4 дні, інше днів
            let lastTwo = n % 100
            let last = n % 10
            let word: String
            if lastTwo >= 11 && lastTwo <= 14 {
                word = "днів"
            } else if last == 1 {
                word = "день"
            } else if (2...4).contains(last) {
                word = "дні"
            } else {
                word = "днів"
            }
            return "\(n) \(word)"
        case "es":
            return "\(n) días"
        case "ca":
            return "\(n) dies"
        case "zh":
            return "剩余 \(n) 天"
        default:
            let word = (n == 1) ? "day" : "days"
            return "\(n) \(word) left"
        }
    }
    
    private var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.localizedString("ЕЖЕДНЕВНЫЕ КВЕСТЫ"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Image(systemName: "clock")
                    Text(LocalizationManager.shared.localizedString("10Ч"))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            }
                    .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.top, 16)
            
            // Ежедневные квесты (динамически)
            VStack(spacing: 12) {
                ForEach(questService.dailyQuests) { q in
                    DailyQuestRow(
                        title: q.title,
                        progress: q.progress,
                        target: q.target,
                        icon: q.icon,
                        isCompleted: q.isCompleted
                    )
                }
            }
                    .padding(.horizontal, isIPad ? 40 : 20)
        }
    }
    
    private var monthlyQuestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("МЕСЯЧНЫЕ ЦЕЛИ"))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                    .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.top, 16)
            
            LazyVStack(spacing: 12) {
                ForEach(userProfile.monthlyQuests) { quest in
                    MonthlyQuestRow(quest: quest)
                }
            }
                    .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helper Functions
    
    @MainActor
    private func getCurrentMonthMissionTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.currentLocale
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: Date()).capitalized
        return "\(monthName) Mission"
    }
}

// PreferenceKey для передачи safe area inset сверху
private struct SafeTopInsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct DailyQuestRow: View {
    let title: String
    let progress: Int
    let target: Int
    let icon: String
    let isCompleted: Bool
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCompleted ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * (isCompleted ? 1.0 : Double(progress) / Double(target)), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
                
                Text("\(progress) / \(target)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
    

}

struct MonthlyQuestRow: View {
    let quest: MonthlyQuest
    @EnvironmentObject var userProfile: UserProfile
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: quest.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(quest.color)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(quest.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Дополнительная информация для месячного XP квеста
                if quest.questType == .monthlyXP {
                    let daysWithXP = userProfile.getDaysWithXPInCurrentMonth()
                    let daysText = String(format: LocalizationManager.shared.localizedString("%d/7 дней активности"), daysWithXP)
                    Text(daysText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(daysWithXP >= 7 ? .green : .orange)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(quest.color)
                            .frame(width: geometry.size.width * (isQuestCompleted ? 1.0 : quest.progress), height: 8)
                            .animation(.easeInOut(duration: 0.5), value: quest.progress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(quest.currentValue) / \(quest.targetValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                        
                        Text("+\(quest.xpReward) XP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isQuestCompleted {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isQuestCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var isQuestCompleted: Bool {
        userProfile.isMonthlyXPQuestCompleted(quest)
    }
    
    private func monthlyProgressWidth(for quest: MonthlyQuest) -> CGFloat {
        let maxWidth: CGFloat = 180
        let progress = quest.isCompleted ? 1.0 : quest.progress
        return maxWidth * progress
    }
}

// Helper extension for corner radius
extension View {
    #if os(iOS)
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    #else
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    #endif
}

#if os(iOS)
typealias RectCorner = UIRectCorner
#else
enum RectCorner {
    case topLeft, topRight, bottomLeft, bottomRight, allCorners
}
#endif

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    #if os(iOS)
    var corners: UIRectCorner = .allCorners
    #else
    var corners: RectCorner = .allCorners
    #endif

    func path(in rect: CGRect) -> Path {
        #if os(iOS)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
        #else
        var path = Path()
        let topLeft = corners == .allCorners || corners == .topLeft
        let topRight = corners == .allCorners || corners == .topRight
        let bottomLeft = corners == .allCorners || corners == .bottomLeft
        let bottomRight = corners == .allCorners || corners == .bottomRight
        
        let topLeftRadius = topLeft ? radius : 0
        let topRightRadius = topRight ? radius : 0
        let bottomLeftRadius = bottomLeft ? radius : 0
        let bottomRightRadius = bottomRight ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY))
        if topRightRadius > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY + topRightRadius),
                       radius: topRightRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
        if bottomRightRadius > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY - bottomRightRadius),
                       radius: bottomRightRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
        if bottomLeftRadius > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY - bottomLeftRadius),
                       radius: bottomLeftRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }
        if topLeftRadius > 0 {
            path.addArc(center: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY + topLeftRadius),
                       radius: topLeftRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
        #endif
    }
}

#Preview {
    MonthlyQuestsView()
        .environmentObject(UserProfile.shared)
}
