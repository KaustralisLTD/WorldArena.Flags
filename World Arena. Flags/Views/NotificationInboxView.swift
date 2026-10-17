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
    private func tr(_ key: String) -> String { language.localizedString(key) }
    private var visible: [AppNotificationLogItem] {
        inbox.inboxItems.filter { item in
            switch filter {
            case 1: return item.isUnread
            case 2: return item.isDuel
            case 3: return item.kind == "progress"
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
                                inbox.markRead(ids: [item.id]); selected = item
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
            .sheet(item: $selected) { item in
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Image(systemName: icon(item)).font(.largeTitle).foregroundColor(.blue)
                            Text(item.displayTitle).font(.title2.bold())
                            if let date=item.date { Text(dateText(date)).font(.caption).foregroundColor(.secondary) }
                            Text(item.displayBody).font(.body).fixedSize(horizontal: false, vertical: true)
                            if item.isDuel {
                                Button(tr("Duel Summary")) {
                                    selected=nil; dismiss()
                                    NotificationService.shared.pendingDuelIsResult = item.kind == "duel_result"
                                    NotificationService.shared.pendingDuelID = item.target ?? "inbox"
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
        .task { await inbox.refreshInbox() }
    }
    private func dateText(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date:.abbreviated,time:.shortened).locale(Locale(identifier:language.currentBundleLanguageCode)))
    }
    private func icon(_ item: AppNotificationLogItem) -> String {
        if item.kind == "duel_result" { return "trophy.fill" }
        if item.isDuel { return "person.2.fill" }
        if item.kind == "progress" { return "star.fill" }
        if item.kind == "lifecycle" { return "globe.europe.africa.fill" }
        return "envelope.fill"
    }
    private func notificationCard(_ item: AppNotificationLogItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon(item)).font(.title3).foregroundColor(item.isUnread ? .blue : .secondary)
                .frame(width:44,height:44).background(Color.blue.opacity(item.isUnread ? 0.12 : 0.04),in:RoundedRectangle(cornerRadius:14))
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
