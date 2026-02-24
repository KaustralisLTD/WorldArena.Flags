import SwiftUI
import Foundation

struct StreakView: View {
    let currentStreak: Int
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var flameScale: CGFloat = 0.5
    @State private var numberScale: CGFloat = 0.8
    @State private var showWeekTracker = false
    @State private var showButton = false
    @State private var flameGlow: Double = 0
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var userProfile = UserProfile.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Streak section
                VStack(spacing: 20) {
                    // Flame icon
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.orange.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(flameGlow)
                        
                        // Flame
                        Text("🔥")
                            .font(.system(size: 80))
                            .scaleEffect(flameScale)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                                value: flameScale
                            )
                    }
                    
                    // Streak number
                    VStack(spacing: 8) {
                        Text("\(currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .scaleEffect(numberScale)
                        
                        Text(localizationManager.localizedString("day streak"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                // Weekly tracker
                VStack(spacing: 16) {
                    Text(localizationManager.localizedString("This Week"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(Array(weekDaysWithInfo.enumerated()), id: \.offset) { index, dayInfo in
                            VStack(spacing: 8) {
                                Text(dayInfo.shortName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Circle()
                                    .fill(dayInfo.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        dayInfo.icon
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .scaleEffect(showWeekTracker ? 1 : 0.5)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.6)
                                        .delay(Double(index) * 0.1),
                                        value: showWeekTracker
                                    )
                            }
                        }
                    }
                }
                .opacity(showWeekTracker ? 1 : 0)
                .offset(y: showWeekTracker ? 0 : 30)
                
                // Motivational message
                VStack(spacing: 8) {
                    Text(motivationalMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if missedDaysThisWeek > 0 {
                        Text(localizationManager.localizedString("Don't break the chain! Come back tomorrow!"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .opacity(showWeekTracker ? 1 : 0)
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    HStack {
                        Text(localizationManager.localizedString("CONTINUE"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.8)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekStartsOnSunday: Bool {
        // Определяем начало недели на основе локали пользователя
        let locale = Locale.current
        let regionCode: String
        
        if #available(iOS 16.0, *) {
            regionCode = locale.region?.identifier ?? "US"
        } else {
            regionCode = locale.regionCode ?? "US"
        }
        
        // США, Канада, Япония, Израиль и некоторые другие страны начинают неделю с воскресенья
        let sundayStartCountries = ["US", "CA", "JP", "IL", "BR", "PH", "TW", "HK", "MO", "TH"]
        
        return sundayStartCountries.contains(regionCode)
    }
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Настраиваем календарь на основе региона
        var adjustedCalendar = calendar
        adjustedCalendar.firstWeekday = weekStartsOnSunday ? 1 : 2 // 1 = воскресенье, 2 = понедельник
        
        // Находим начало текущей недели
        guard let startOfWeek = adjustedCalendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        // Создаем массив дат для текущей недели
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = adjustedCalendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private var weekDaysWithInfo: [DayInfo] {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        
        return currentWeekDates.map { date in
            let shortName = String(dateFormatter.string(from: date).prefix(2))
            let dayStatus = getDayStatus(for: date, today: today)
            
                            return DayInfo(
                    date: date,
                    shortName: shortName,
                    status: dayStatus,
                    color: colorForStatus(dayStatus),
                    icon: iconForStatus(dayStatus)
                )
        }
    }
    
    private func getDayStatus(for date: Date, today: Date) -> DayStatus {
        let calendar = Calendar.current
        
        // Сравниваем даты
        let comparison = calendar.compare(date, to: today, toGranularity: .day)
        
        switch comparison {
        case .orderedDescending:
            // Будущий день
            return .future
        case .orderedSame:
            // Сегодня - проверяем, играл ли пользователь
            return userProfile.hasPlayedToday ? .completed : .current
        case .orderedAscending:
            // Прошедший день - проверяем, играл ли пользователь в этот день
            if userProfile.hasPlayedOnDate(date) {
                return .completed
            } else {
                return .missed
            }
        }
    }
    
    private func colorForStatus(_ status: DayStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .current:
            return .orange
        case .missed:
            return .red
        case .future:
            return Color.gray.opacity(0.3)
        }
    }
    
    private func iconForStatus(_ status: DayStatus) -> Image {
        switch status {
        case .completed:
            return Image(systemName: "checkmark")
        case .current:
            return Image(systemName: "play.fill")
        case .missed:
            return Image(systemName: "xmark")
        case .future:
            return Image(systemName: "circle")
        }
    }
    
    private var missedDaysThisWeek: Int {
        weekDaysWithInfo.filter { $0.status == .missed }.count
    }
    
    private var motivationalMessage: String {
        if currentStreak >= 7 {
            return localizationManager.localizedString("Incredible streak! You're on fire!")
        } else if currentStreak >= 3 {
            return localizationManager.localizedString("Great job! Keep the momentum going!")
        } else if currentStreak == 0 && missedDaysThisWeek > 0 {
            return localizationManager.localizedString("Time to restart your streak! You can do it!")
        } else {
            return localizationManager.localizedString("Nice start! Build your streak day by day!")
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
            flameScale = 1.0
            numberScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.5).delay(0.5)) {
            flameGlow = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            showWeekTracker = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            showButton = true
        }
    }
}

// MARK: - Supporting Types

enum DayStatus {
    case completed  // День пройден (зеленая галочка)
    case current    // Сегодня (оранжевая кнопка play)
    case missed     // День пропущен (красный крестик)
    case future     // Будущий день (серый, пустой)
}

struct DayInfo {
    let date: Date
    let shortName: String
    let status: DayStatus
    let color: Color
    let icon: Image
}

#Preview {
    StreakView(
        currentStreak: 5,
        onContinue: {}
    )
}