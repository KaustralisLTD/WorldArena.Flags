import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif

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
            
            GeometryReader { geometry in
            ScrollView {
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
                        
                        // Уникальная миниатюра огня как в Профиле (StatDayStreak), иначе SF Symbol с оранжевым цветом
                        Group {
                            #if os(iOS)
                            if UIImage(named: "StatDayStreak") != nil {
                                Image("StatDayStreak")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(Color.orange)
                            } else {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(Color.orange)
                            }
                            #else
                            Image(systemName: "flame.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color.orange)
                            #endif
                        }
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
                        Text(localizationManager.localizedString("home.daily.tomorrow"))
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
                .padding(.horizontal, 32)
                .frame(maxWidth: 640)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 960)
            .frame(minHeight: geometry.size.height)
            .frame(maxWidth: .infinity)
            }
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
struct StreakCalendarLink: ViewModifier {
    @State private var presented = false
    func body(content: Content) -> some View {
        Button { presented = true } label: { content }
            .buttonStyle(.plain)
            .accessibilityIdentifier("streak.calendar.open")
            .sheetOrFullScreenOnIPad(isPresented: $presented) {
                StreakCalendarView().environmentObject(UserProfile.shared)
            }
    }
}

struct StreakCalendarView: View {
    @EnvironmentObject private var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var gifts = StreakFreezeGifts.shared
    @State private var month = Date()
    @State private var selectedDay: Date?
    private var calendar: Calendar {
        var value = Calendar.current
        value.locale = loc.currentLocale
        return value
    }
    private func tr(_ key: String) -> String { loc.localizedString(key) }
    private var monthStart: Date { calendar.dateInterval(of: .month, for: month)!.start }
    private var days: [Date?] {
        let offset = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: offset) + (calendar.range(of: .day, in: .month, for: month) ?? 1..<1).map {
            calendar.date(byAdding: .day, value: $0 - 1, to: monthStart)
        }
    }
    private func status(_ day: Date) -> String {
        if profile.hasPlayedOnDate(day) { return "streak.calendar.played" }
        if profile.isFrozen(day) { return "streak.calendar.frozen" }
        if calendar.startOfDay(for: day) < calendar.startOfDay(for: Date()), day >= calendar.startOfDay(for: profile.joinDate) { return "streak.calendar.missed" }
        return "streak.calendar.open_day"
    }
    private func color(_ day: Date) -> Color {
        switch status(day) {
        case "streak.calendar.played": return .orange
        case "streak.calendar.frozen": return .cyan
        default: return .secondary
        }
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill").font(.system(size: 48)).foregroundColor(.orange)
                        Text("\(profile.streak)").font(.system(size: 42, weight: .bold, design: .rounded)).monospacedDigit()
                        Text(tr("Текущая серия")).foregroundColor(.secondary)
                    }
                    VStack(spacing: 16) {
                        HStack {
                            Button { month = calendar.date(byAdding: .month, value: -1, to: month)! } label: {
                                Image(systemName: "chevron.left").frame(width: 44, height: 44)
                            }.accessibilityLabel(tr("streak.calendar.previous"))
                            Spacer()
                            Text(month.formatted(.dateTime.month(.wide).year().locale(loc.currentLocale))).font(.headline)
                            Spacer()
                            Button { month = calendar.date(byAdding: .month, value: 1, to: month)! } label: {
                                Image(systemName: "chevron.right").frame(width: 44, height: 44)
                            }.disabled(calendar.isDate(month, equalTo: Date(), toGranularity: .month))
                                .accessibilityLabel(tr("streak.calendar.next"))
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                Text(calendar.shortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7])
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                                if let day {
                                    Button { selectedDay = day } label: {
                                        VStack(spacing: 2) {
                                            Text("\(calendar.component(.day, from: day))").font(.subheadline.weight(.semibold))
                                            Image(systemName: profile.hasPlayedOnDate(day) ? "checkmark" : (profile.isFrozen(day) ? "snowflake" : "minus"))
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundColor(color(day))
                                        .background(color(day).opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(calendar.isDateInToday(day) ? Color.accentColor : .clear, lineWidth: 1.5))
                                    }.buttonStyle(.plain)
                                        .accessibilityLabel(day.formatted(date: .complete, time: .omitted) + ", " + tr(status(day)))
                                } else { Color.clear.frame(height: 44) }
                            }
                        }
                        if let day = selectedDay {
                            Text(day.formatted(date: .abbreviated, time: .omitted) + " · " + tr(status(day)))
                                .font(.subheadline).foregroundColor(color(day))
                        }
                        HStack {
                            Label(tr("streak.calendar.played"), systemImage: "checkmark").foregroundColor(.orange)
                            Label(tr("streak.calendar.frozen"), systemImage: "snowflake").foregroundColor(.cyan)
                        }.font(.caption).frame(maxWidth: .infinity)
                    }
                    .padding(16).background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label(tr("streak.freeze.title"), systemImage: "snowflake").font(.headline)
                            Spacer()
                            Text("\(profile.streakFreezes) / \(UserProfile.freezeCapacity)").bold().monospacedDigit()
                        }
                        Text(tr("streak.freeze.explanation")).font(.subheadline).foregroundColor(.secondary)
                        Text("F-Bucks: \(profile.fBucks)").font(.subheadline.bold())
                        Button { _ = profile.buyStreakFreeze(); Task { await gifts.sync(profile: profile) } } label: {
                            Text(tr("Купить") + " · \(UserProfile.freezePrice) F-Bucks")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.borderedProminent)
                            .disabled(profile.pendingFreezeGiftID != nil || profile.streakFreezes >= UserProfile.freezeCapacity || profile.fBucks < UserProfile.freezePrice)
                            .accessibilityIdentifier("streak.freeze.buy")
                        if profile.canRepairYesterdayWithFreeze {
                            Button { _ = profile.repairYesterdayWithFreeze(); Task { await gifts.sync(profile: profile) } } label: {
                                Label(tr("streak.freeze.repair"), systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }.buttonStyle(.bordered).disabled(profile.streakFreezes == 0)
                        }
                    }.padding(20).background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 14) {
                        Text(tr("streak.freeze.friends")).font(.headline)
                        if let key = gifts.messageKey { Text(tr(key)).font(.subheadline).foregroundColor(.secondary) }
                        if gifts.friends.isEmpty && gifts.messageKey == nil {
                            Text(tr("streak.freeze.no_friends")).font(.subheadline).foregroundColor(.secondary)
                        }
                        ForEach(gifts.friends) { friend in
                            HStack {
                                Text(friend.displayName).font(.subheadline.weight(.semibold))
                                Spacer()
                                Button { Task { await gifts.send(to: friend, profile: profile) } } label: {
                                    Label(tr("streak.freeze.give"), systemImage: "gift.fill")
                                }.buttonStyle(.bordered)
                                    .disabled(gifts.busy || profile.streakFreezes == 0 || profile.pendingFreezeGiftID != nil)
                            }
                        }
                        if gifts.messageKey == "streak.freeze.retry" {
                            Button(tr("Retry")) { Task { await gifts.sync(profile: profile) } }.disabled(gifts.busy)
                        }
                        if gifts.busy { ProgressView() }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))

                }
                .padding(20).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(tr("streak.calendar.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(tr("Close")) { dismiss() }.accessibilityIdentifier("streak.calendar.close") } }
        }
        .navigationViewStyle(.stack)
        .task { profile.reconcileStreakFreezes(); await gifts.sync(profile: profile) }
    }
}

@MainActor
final class StreakFreezeGifts: ObservableObject {
    static let shared = StreakFreezeGifts()
    struct Recipient: Decodable, Identifiable {
        let username: String
        let displayName: String
        var id: String { username }
    }
    private struct Gift: Decodable { let id: String; let sender: String }
    private struct Inbox: Decodable { let gifts: [Gift]; let friends: [Recipient] }
    private struct GiftResult: Decodable { let status: String }
    @Published var friends: [Recipient] = []
    @Published var busy = false
    @Published var messageKey: String?

    private func request<T: Decodable>(_ route: String, body: [String: Any], token: String) async throws -> T {
        var request = URLRequest(url: URL(string: "https://flags.worldarena.games/api/v1/streak-freezes/" + route)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func send(to recipient: Recipient, profile: UserProfile) async {
        guard !busy, profile.streakFreezes > 0, profile.pendingFreezeGiftID == nil,
              AuthService.shared.authToken != nil else { return }
        profile.pendingFreezeGiftID = UUID().uuidString
        profile.pendingFreezeGiftRecipient = recipient.username
        profile.streakFreezes -= 1 // Reserve before the request; retries reuse the persisted ID.
        profile.saveToStorage()
        await sync(profile: profile)
    }

    func sync(profile: UserProfile) async {
        guard !busy else { return }
        guard let token = AuthService.shared.authToken else {
            friends = []; messageKey = "streak.freeze.signin"; return
        }
        let account = profile.username
        busy = true
        messageKey = nil
        defer { busy = false }
        do {
            if let id = profile.pendingFreezeGiftID, let recipient = profile.pendingFreezeGiftRecipient {
                let result: GiftResult = try await request("gift", body: ["id": id, "recipient": recipient], token: token)
                guard profile.username == account else { return }
                if result.status != "accepted" {
                    profile.streakFreezes += 1 // Server stores the rejection, so a retry cannot later send this gift.
                    messageKey = "streak.freeze.unavailable"
                } else { messageKey = "streak.freeze.sent" }
                profile.pendingFreezeGiftID = nil
                profile.pendingFreezeGiftRecipient = nil
                profile.saveToStorage()
            }
            let inbox: Inbox = try await request("sync", body: ["count": profile.streakFreezes, "received": Array(profile.freezeGiftReceipts.suffix(500))], token: token)
            guard profile.username == account else { return }
            friends = inbox.friends
            for gift in inbox.gifts where !profile.freezeGiftReceipts.contains(gift.id) {
                guard profile.streakFreezes < UserProfile.freezeCapacity else { break }
                profile.freezeGiftReceipts.insert(gift.id)
                profile.streakFreezes += 1
            }
            profile.saveToStorage()
            if !inbox.gifts.isEmpty {
                let _: Inbox = try await request("sync", body: ["count": profile.streakFreezes, "received": Array(profile.freezeGiftReceipts.suffix(500))], token: token)
            }
        } catch {
            if profile.username == account { messageKey = "streak.freeze.retry" }
        }
    }
}
