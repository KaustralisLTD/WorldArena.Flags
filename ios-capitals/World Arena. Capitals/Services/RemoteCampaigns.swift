import SwiftUI

struct RemoteCampaign: Decodable, Identifiable {
    struct Copy: Decodable { let title: String; let body: String; let button: String }
    let id: String
    let copy: [String: Copy]
    let action: String
    let url: String?
    let dismissible: Bool
    func localized() -> Copy? {
        let code = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.languageCode ?? "en"
        return copy[code] ?? copy[code.components(separatedBy: "-").first ?? "en"] ?? copy["en"]
    }
}

struct RemoteCampaignBanner: View {
    @State private var campaigns: [RemoteCampaign] = []
    @State private var dismissed = Set(UserDefaults.standard.stringArray(forKey: "campaigns.dismissed") ?? [])
    @State private var showMap = false
    @State private var showWeakCountries = false
    @State private var showBonus = false
    @State private var showDuels = false
    @State private var personal: LifecycleService.Message?
    @State private var campaignClock = Date()
    @EnvironmentObject private var gameState: GameState
    @Environment(\.openURL) private var openURL
    @ObservedObject private var language = LocalizationManager.shared
    var body: some View {
        Group {
            if let message = personal, !dismissed.contains(message.id), message.action != "bonus" || Calendar.current.component(.hour, from: campaignClock) < 16 {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        Text(message.title).font(.title3.bold())
                        Spacer()
                        Button {
                            dismissed.insert(message.id)
                            UserDefaults.standard.set(Array(dismissed), forKey: "campaigns.dismissed")
                        } label: { Image(systemName: "xmark").padding(6) }.accessibilityLabel(language.localizedString("Close"))
                    }
                    Text(message.body).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(message.facts.enumerated()), id: \.offset) { _, fact in
                        Text(fact.label + "  " + fact.value).font(.headline)
                    }
                    Button(message.button) {
                        open(message)
                    }.buttonStyle(.borderedProminent).tint(.teal)
                        .disabled(message.action == "bonus" && Calendar.current.component(.hour, from: campaignClock) < 12)
                }.padding(22).foregroundColor(.white)
                    .background(Color(red: 0.035, green: 0.11, blue: 0.17))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            } else if let campaign = campaigns.first(where: { !dismissed.contains($0.id) }), let copy = campaign.localized() {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Image(systemName: campaign.action == "map" ? "map.fill" : "sparkles").foregroundColor(.cyan)
                        Text(copy.title).font(.headline)
                        Spacer()
                        if campaign.dismissible {
                            Button {
                                dismissed.insert(campaign.id)
                                UserDefaults.standard.set(Array(dismissed), forKey: "campaigns.dismissed")
                            } label: { Image(systemName: "xmark").padding(6) }
                            .accessibilityLabel(language.localizedString("Close"))
                        }
                    }
                    Text(copy.body).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    Button(copy.button) {
                        if campaign.action == "map" { showWeakCountries = false; showMap = true }
                        else if let value = campaign.url, let url = URL(string: value), url.scheme == "https",
                            let host = url.host, ["capital.worldarena.games", "flags.worldarena.games", "worldarena.games", "apps.apple.com"].contains(host) {
                            openURL(url)
                        }
                    }.font(.subheadline.bold()).padding(.vertical, 8)
                }
                .padding(20).foregroundColor(.white)
                .background(LinearGradient(colors: [Color(red: 0.03, green: 0.08, blue: 0.18), Color(red: 0.02, green: 0.25, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
        .sheet(isPresented: $showMap) { NavigationView {
            WorldProgressMapView(showWeakCountries: showWeakCountries).toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.localizedString("Close")) { showMap = false }
                }
            }
        } }
        .sheet(isPresented: $showBonus) {
            if let personal { LifecycleBonusView(contactID: personal.id) }
        }
        .sheet(isPresented: $showDuels) { DuelSummaryView().environmentObject(UserProfile.shared) }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { campaignClock = $0 }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenLifecycleCampaign"))) { note in
            guard let id = note.object as? String else { return }
            Task {
                personal = await LifecycleService.message(id: id)
                if let personal, personal.id == id { open(personal) }
            }
        }
        .task {
            await LifecycleService.sync()
            let pendingID = UserDefaults.standard.string(forKey: "lifecycle.pendingLink")
            personal = await LifecycleService.message()
            if let personal, personal.id == pendingID { open(personal) }
            guard let url = URL(string: "https://capital.worldarena.games/api/v1/campaigns") else { return }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
                campaigns = try JSONDecoder().decode([RemoteCampaign].self, from: data)
            } catch { /* Optional content: the game remains usable offline. */ }
        }
    }
    private func open(_ message: LifecycleService.Message) {
        guard !gameState.isGameInProgress else {
            UserDefaults.standard.set(message.id, forKey: "lifecycle.pendingLink")
            return
        }
        Task { await LifecycleService.opened(message.id) }
        switch message.action {
        case "bonus":
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 12 && hour < 16 { showBonus = true }
        case "duels": showDuels = true
        case "flags": openURL(URL(string: "https://flags.worldarena.games")!)
        case "mistakes": showWeakCountries = true; showMap = true
        default: showWeakCountries = false; showMap = true
        }
    }
}

@MainActor
enum ProgressMailSync {
    static var preferenceKey: String { "progressEmailEnabled." + (AuthService.shared.authUsername ?? "guest") }
    private static var pendingSync: Task<Void, Never>?
    static func schedule() {
        pendingSync?.cancel()
        pendingSync = Task {
            do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { return }
            await sync()
        }
    }
    static func sync(explicitConsent: Bool = false) async {
        await LifecycleService.sync(explicitConsent: explicitConsent)
    }
}
