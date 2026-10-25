import SwiftUI

struct FriendRequestItem: Decodable, Identifiable {
    let username: String
    let displayName: String
    var id: String { username }
}

@MainActor
final class FriendRequestsInbox: ObservableObject {
    static let shared = FriendRequestsInbox()
    @Published var requests: [FriendRequestItem] = []
    @Published var busy = false
    @Published var error: String?
    @Published var showInbox = false
    private var revision = 0
    private var loading = false
    private var owner: String?

    func refresh() async {
        let user = AuthService.shared.authUsername
        if owner != user { requests = []; owner = user }
        guard !loading, !busy, AuthService.shared.authToken != nil else { return }
        let currentRevision = revision
        loading = true
        defer { loading = false }
        do {
            let result = try await DuelAPIService.shared.fetchFriendRequests()
            guard owner == user, currentRevision == revision else { return }
            requests = result
        } catch { /* Keep the persistent inbox on transient network failures. */ }
    }

    func respond(_ item: FriendRequestItem, accept: Bool) async {
        guard !busy else { return }
        revision += 1
        busy = true; error = nil
        defer { busy = false }
        do {
            try await DuelAPIService.shared.respondToFriendRequest(sender: item.username, accept: accept)
            requests.removeAll { $0.id == item.id }
            if accept {
                let profile = UserProfile.shared
                let friends = try await DuelAPIService.shared.fetchMyFriends(userId: profile.username)
                profile.friends = friends.map { $0.toFriend() }
                profile.saveToStorage()
            }
        } catch { self.error = LocalizationManager.shared.localizedString("friends.requests.error") }
    }
}

struct FriendRequestsEntry: View {
    @ObservedObject private var inbox = FriendRequestsInbox.shared
    var body: some View {
        Button { inbox.showInbox = true } label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                Text(LocalizationManager.shared.localizedString("friends.requests.title"))
                Spacer()
                if !inbox.requests.isEmpty {
                    Text("\(inbox.requests.count)").bold().padding(7)
                        .background(Color.indigo.opacity(0.12), in: Capsule())
                }
                Image(systemName: "chevron.right")
            }
            .padding(16)
            .background(Color.indigo.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityIdentifier("friends.requests")
        .padding(.horizontal, 20)
    }
}

struct FriendRequestsView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var showAuth = false
    @ObservedObject private var inbox = FriendRequestsInbox.shared
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = LocalizationManager.shared
    private func text(_ key: String) -> String { language.localizedString(key) }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !auth.isAuthenticated {
                        Text(text("friends.requests.signin"))
                        Button(LocalizationManager.shared.localizedString("Login")) { showAuth = true }.buttonStyle(.borderedProminent)
                    } else if inbox.requests.isEmpty {
                        Image(systemName: "person.2.badge.gearshape").font(.system(size: 48)).foregroundColor(.indigo)
                        Text(text("friends.requests.empty")).foregroundColor(.secondary)
                    }
                    ForEach(inbox.requests) { item in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(item.displayName).font(.title3.bold())
                            Text("@\(item.username)").font(.subheadline).foregroundColor(.secondary)
                            Text(text("friends.requests.body"))
                            Button { Task { await inbox.respond(item, accept: true) } } label: {
                                Label(text("friends.requests.accept"), systemImage: "person.badge.plus")
                                    .frame(maxWidth: .infinity).padding(12)
                            }.buttonStyle(.borderedProminent)
                            Button(text("friends.requests.decline")) { Task { await inbox.respond(item, accept: false) } }
                                .frame(maxWidth: .infinity).padding(8)
                        }
                        .padding(20).background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                        .disabled(inbox.busy)
                    }
                    if let error = inbox.error { Text(error).foregroundColor(.red) }
                    if inbox.busy { ProgressView() }
                }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .navigationTitle(text("friends.requests.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(text("friends.requests.done")) { dismiss() } } }
            .task { await inbox.refresh() }
        }.navigationViewStyle(.stack)
            .fullScreenCover(isPresented: $showAuth, onDismiss: { Task { await inbox.refresh() } }) { AuthGatewayView() }
    }
}

struct FriendRequestsHomeNotice: View {
    @ObservedObject private var inbox = FriendRequestsInbox.shared
    var body: some View {
        if !inbox.requests.isEmpty { FriendRequestsEntry() }
    }
}
