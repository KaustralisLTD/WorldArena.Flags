import SwiftUI

struct NotificationCountBadge: View {
    let count: Int
    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : String(count))
                .font(.caption2.bold()).monospacedDigit().foregroundColor(.white)
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(Color.red, in: Capsule())
                .accessibilityLabel(String(count))
        }
    }
}

struct MyNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var inbox = NotificationService.shared
    @ObservedObject private var language = LocalizationManager.shared
    @State private var filter = 0
    @State private var selected: AppNotificationLogItem?
    @State private var openDuelsAfterDetail = false
    @EnvironmentObject private var gameState: GameState
    private func tr(_ key: String) -> String { language.localizedString(key) }
    private var visible: [AppNotificationLogItem] {
        inbox.inboxItems.filter { item in
            switch filter {
            case 1: return item.isUnread
            case 2: return item.isDuel
            case 3: return item.kind == "progress" || (item.id.hasPrefix("level_") || item.details?.level != nil) || (item.id.hasPrefix("league_") || item.details?.league != nil) || item.id.hasPrefix("achievement_") || item.achievementDefinition != nil
            default: return true
            }
        }
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill").font(.title2).foregroundColor(.blue)
                            .frame(width: 52, height: 52).background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tr("inbox.subtitle")).font(.headline)
                            Text(tr("inbox.explanation")).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                        NotificationCountBadge(count: inbox.unreadCount).accessibilityIdentifier("inbox.count")
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(["All", "inbox.unread", "Duel", "Достижения"].enumerated()), id: \.offset) { index, key in
                                Button { filter = index } label: {
                                    Text(tr(key)).font(.subheadline.weight(.semibold)).padding(.horizontal, 16).padding(.vertical, 10)
                                        .foregroundColor(filter == index ? .white : .primary)
                                        .background(filter == index ? Color.blue : Color(UIColor.secondarySystemGroupedBackground), in: Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    if inbox.inboxRefreshFailed {
                        Label(tr("inbox.cached"), systemImage: "arrow.clockwise").font(.caption).foregroundColor(.secondary)
                    }
                    if visible.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle").font(.system(size: 42)).foregroundColor(.teal)
                            Text(tr("inbox.empty")).font(.headline)
                        }.frame(maxWidth: .infinity).padding(.vertical, 54)
                    }
                    LazyVStack(spacing: 12) {
                        ForEach(visible) { item in
                            Button {
                                inbox.markRead(ids: [item.id]); selected = enriched(item)
                            } label: { notificationCard(item) }.buttonStyle(.plain)
                            .accessibilityIdentifier("inbox.item." + item.id)
                        }
                    }
                }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(tr("My notifications"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(tr("Close")) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { inbox.markRead(ids: inbox.inboxItems.map(\.id)) } label: { Image(systemName: "checkmark.circle") }
                        .accessibilityLabel(tr("inbox.readAll")).accessibilityIdentifier("inbox.readAll").disabled(inbox.unreadCount == 0)
                }
            }
            .refreshable { await inbox.refreshInbox() }
            .sheet(item: $selected, onDismiss: {
                if openDuelsAfterDetail {
                    openDuelsAfterDetail = false
                    dismiss()
                    NotificationCenter.default.post(name: Notification.Name("OpenDuelSummary"), object: nil)
                }
            }) { item in
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if item.kind == "duel_result" {
                                DuelInboxResultContent(item: item) { openDuelsAfterDetail = true; selected = nil }
                            } else {
                            InboxCelebrationArtwork(item: item).frame(height: 210)
                            Text(item.displayTitle).font(.title2.bold())
                            if let date=item.date { Text(dateText(date)).font(.caption).foregroundColor(.secondary) }
                            Text(item.displayBody).font(.body).fixedSize(horizontal: false, vertical: true)
                            if let detail = item.details {
                                HStack(spacing: 12) {
                                    if let rank = detail.rank { metric(tr("inbox.rank"), "#" + String(rank)) }
                                    if let level = detail.level { metric(tr("Уровень"), String(level)) }
                                    if let xp = detail.xp { metric("XP", String(xp)) }
                                    if let score = detail.myScore { metric(tr("You"), String(score)) }
                                    if let score = detail.opponentScore { metric(detail.opponentName ?? tr("Duel"), String(score)) }
                                }
                            }
                            Text(tr(contextKey(item))).font(.body).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            if (item.id.hasPrefix("league_") || item.details?.league != nil) || (item.id.hasPrefix("level_") || item.details?.level != nil) || item.id.hasPrefix("achievement_") || item.achievementDefinition != nil {
                                Button(tr("inbox.progressCTA")) {
                                    selected = nil; dismiss()
                                    NotificationService.shared.pendingLeague = (item.id.hasPrefix("league_") || item.details?.league != nil)
                                    if !(item.id.hasPrefix("league_") || item.details?.league != nil) { NotificationCenter.default.post(name: Notification.Name("OpenAchievements"), object: nil) }
                                }.buttonStyle(.borderedProminent)
                            }
                            }
                            if item.isDuel && item.kind != "duel_result" {
                                Button(tr("Duel Summary")) {
                                    openDuelsAfterDetail = true; selected = nil
                                }.buttonStyle(.borderedProminent)
                            } else if item.kind == "lifecycle", let target=item.target {
                                Button(tr("inbox.open")) {
                                    selected=nil; dismiss()
                                    UserDefaults.standard.set(target,forKey:"lifecycle.pendingLink")
                                    NotificationCenter.default.post(name:Notification.Name("OpenLifecycleCampaign"),object:target)
                                }.buttonStyle(.borderedProminent)
                            }
                        }.padding(24).frame(maxWidth: 700,alignment: .leading).frame(maxWidth: .infinity)
                    }.toolbar { ToolbarItem(placement:.cancellationAction) { Button(tr("Close")) { selected=nil } } }
                }.navigationViewStyle(.stack)
            }
        }.navigationViewStyle(.stack)
        .environment(\.layoutDirection, language.currentBundleLanguageCode == "ar" ? .rightToLeft : .leftToRight)
        .task { await inbox.refreshInbox() }
    }
    private func enriched(_ item: AppNotificationLogItem) -> AppNotificationLogItem {
        guard item.kind == "duel_result", let target = item.target,
              let result = gameState.duelHistory.first(where: { $0.duelChallengeId == target }) else { return item }
        var copy = item
        var details = item.details ?? .init()
        details.opponentName = result.opponentName
        details.myScore = result.myScore
        details.opponentScore = result.opponentScore
        details.iWon = result.iWon
        details.myTimeMs = result.myTimeMs ?? details.myTimeMs
        details.opponentTimeMs = result.rivalTimeMs ?? details.opponentTimeMs
        copy.details = details
        return copy
    }
    private func dateText(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date:.abbreviated,time:.shortened).locale(Locale(identifier:language.currentBundleLanguageCode)))
    }
    private func contextKey(_ item: AppNotificationLogItem) -> String {
        if (item.id.hasPrefix("league_") || item.details?.league != nil) { return "inbox.leagueStory" }
        if (item.id.hasPrefix("level_") || item.details?.level != nil) { return "inbox.levelStory" }
        if item.achievementDefinition != nil || item.id.hasPrefix("achievement_") { return "inbox.achievementStory" }
        if item.isDuel { return "inbox.duelStory" }
        return "inbox.messageStory"
    }
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
    private func icon(_ item: AppNotificationLogItem) -> String {
        if (item.id.hasPrefix("league_") || item.details?.league != nil) { return "trophy.fill" }
        if (item.id.hasPrefix("level_") || item.details?.level != nil) { return "star.circle.fill" }
        if item.id.hasPrefix("achievement_") { return "medal.fill" }
        if item.kind == "duel_result" { return "trophy.fill" }
        if item.isDuel { return "person.2.fill" }
        if item.kind == "progress" { return "star.fill" }
        if item.kind == "lifecycle" { return "globe.europe.africa.fill" }
        return "envelope.fill"
    }
    private func notificationCard(_ item: AppNotificationLogItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            if let achievement = item.achievementDefinition {
                NotificationAchievementIcon(definition: achievement).frame(width: 64, height: 64)
            } else if item.kind == "duel_result" {
                DuelOutcomeBadge(won: item.details?.iWon).frame(width: 64, height: 64)
            } else {
                Image(systemName: icon(item)).font(.title3).foregroundColor(item.isUnread ? .blue : .secondary)
                    .frame(width:44,height:44).background(Color.blue.opacity(item.isUnread ? 0.12 : 0.04),in:RoundedRectangle(cornerRadius:14))
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment:.firstTextBaseline) {
                    Text(item.displayTitle).font(.headline).foregroundColor(.primary)
                    Spacer(minLength: 6)
                    if item.isUnread { Circle().fill(Color.blue).frame(width:8,height:8).accessibilityLabel(tr("inbox.unread")) }
                }
                Text(item.displayBody).font(.subheadline).foregroundColor(.secondary).lineLimit(3)
                if let date=item.date { Text(dateText(date)).font(.caption).foregroundColor(.secondary) }
            }
        }.padding(16).frame(maxWidth:.infinity,alignment:.leading)
            .background(Color(UIColor.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:20))
            .overlay(RoundedRectangle(cornerRadius:20).stroke(item.isUnread ? Color.blue.opacity(0.3) : .clear,lineWidth:1))
    }
}

struct InboxCelebrationArtwork: View {
    let item: AppNotificationLogItem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    private var symbol: String {
        if (item.id.hasPrefix("league_") || item.details?.league != nil) || item.kind == "duel_result" { return "trophy.fill" }
        if (item.id.hasPrefix("level_") || item.details?.level != nil) { return "star.circle.fill" }
        if item.id.hasPrefix("achievement_") { return "medal.fill" }
        return item.isDuel ? "person.2.fill" : "globe.europe.africa.fill"
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [Color(red: 0.03, green: 0.10, blue: 0.23), Color(red: 0.04, green: 0.31, blue: 0.37)], startPoint: .topLeading, endPoint: .bottomTrailing))
            ForEach(0..<10) { i in
                Image(systemName: i.isMultiple(of: 2) ? "sparkle" : "circle.fill")
                    .font(.system(size: CGFloat(7 + i % 3 * 4))).foregroundColor(i.isMultiple(of: 3) ? .yellow : .cyan.opacity(0.65))
                    .offset(x: CGFloat((i * 73) % 300 - 150), y: CGFloat((i * 43) % 150 - 75))
                    .opacity(appeared ? 1 : 0).accessibilityHidden(true)
            }
            Group {
                if let achievement = item.achievementDefinition {
                    NotificationAchievementIcon(definition: achievement).frame(width: 136, height: 136)
                } else {
                    Image(systemName: symbol).font(.system(size: 76, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.white, .yellow, .orange], startPoint: .top, endPoint: .bottom))
                }
            }.shadow(color: .yellow.opacity(0.25), radius: 18).scaleEffect(appeared ? 1 : 0.92)
        }.onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.easeOut(duration: 0.45)) { appeared = true } }
        }.accessibilityHidden(true)
    }
}

/// The exact asset or badge used by the achievement collection, in its earned state.
struct NotificationAchievementIcon: View {
    let definition: AchievementDefinition
    var body: some View {
        Group {
            if let asset = definition.imageAssetName {
                Image(asset).resizable().scaledToFit().clipShape(Circle())
            } else {
                JourneyAchievementBadge(definition: definition, unlocked: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LocalizationManager.shared.localizedString(definition.titleKey))
        .accessibilityIdentifier("inbox.achievement.artwork." + definition.id)
    }
}
