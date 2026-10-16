import SwiftUI
import MapKit

struct FBucksFirstRewardCard: View {
    @AppStorage("education.fbucks.pending") private var pending = false
    @AppStorage("education.fbucks.seen") private var seen = false
    @State private var showShop = false
    private func text(_ key: String) -> String { LocalizationManager.shared.localizedString("education.fbucks." + key) }
    var body: some View {
        Group {
            if pending && !seen {
                VStack(alignment: .leading, spacing: 14) {
                    Label(text("title"), systemImage: "sparkles").font(.headline)
                    Text(text("body"))
                    Button(text("shop")) { showShop = true }.buttonStyle(.borderedProminent).accessibilityIdentifier("education.fbucks.openShop")
                    Button(text("done")) { seen = true; pending = false }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
            }
        }
        .sheet(isPresented: $showShop, onDismiss: { seen = true; pending = false }) { FBucksInfoView(initialTab: 3) }
    }
}
struct CountryFactsSettingsEntry: View {
    @State private var show = false
    var body: some View {
        Button { show = true } label: {
            Label(LocalizationManager.shared.localizedString("facts.settings"), systemImage: "globe")
                .frame(maxWidth: .infinity).padding(16)
        }.buttonStyle(.bordered).padding(.horizontal, 20)
            .sheet(isPresented: $show) { CountryFactsSettings() }
    }
}
struct CountryFactsSettings: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("facts.capital") private var capital = true
    @AppStorage("facts.population") private var population = true
    @AppStorage("facts.area") private var area = true
    @AppStorage("facts.region") private var region = true
    @AppStorage("facts.map") private var map = false
    private func text(_ key: String) -> String { LocalizationManager.shared.localizedString("facts." + key) }
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text(text("explanation"))) {
                    Toggle(text("capital"), isOn: $capital)
                    Toggle(text("population"), isOn: $population)
                    Toggle(text("area"), isOn: $area)
                    Toggle(text("region"), isOn: $region)
                    Toggle(text("map"), isOn: $map)
                }
            }.navigationTitle(text("settings")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(LocalizationManager.shared.localizedString("friends.requests.done")) { dismiss() } } }
        }.navigationViewStyle(.stack)
    }
}
/// Static imagery keeps MapKit's interactive view out of the flipping quiz card.
struct CountryFactMap: View {
    let coordinates: [Double]?
    @Environment(\.colorScheme) private var colorScheme
    @State private var snapshot: UIImage?
    @State private var snapshotter: MKMapSnapshotter?
    @State private var requestID = UUID()

    private var coordinate: CLLocationCoordinate2D? {
        guard let coordinates, coordinates.count >= 2,
              coordinates[0].isFinite, coordinates[1].isFinite,
              (-90...90).contains(coordinates[0]),
              (-180...180).contains(coordinates[1]) else { return nil }
        return CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1])
    }

    var body: some View {
        if let coordinate {
            GeometryReader { geometry in
                ZStack {
                    Color(uiColor: .tertiarySystemFill)
                    if let snapshot {
                        Image(uiImage: snapshot).resizable().scaledToFit()
                    } else {
                        Image(systemName: "map").font(.title2).foregroundStyle(.secondary)
                    }
                }
                .task(id: "\(coordinate.latitude):\(coordinate.longitude):\(geometry.size.width):\(colorScheme)") {
                    loadSnapshot(coordinate: coordinate, size: geometry.size)
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LocalizationManager.shared.localizedString("facts.map"))
            .accessibilityIdentifier("quiz.countryMap")
            .onDisappear {
                // Invalidate before cancellation: an old completion must never update a new card.
                requestID = UUID()
                snapshotter?.cancel()
                snapshotter = nil
            }
        }
    }

    @MainActor
    private func loadSnapshot(coordinate: CLLocationCoordinate2D, size: CGSize) {
        let id = UUID()
        requestID = id
        snapshotter?.cancel()
        snapshot = nil
        guard size.width.isFinite, size.width > 0 else { return }
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25))
        options.size = CGSize(width: min(size.width, 720), height: 130)
        options.scale = 2
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let renderer = MKMapSnapshotter(options: options)
        snapshotter = renderer
        renderer.start { result, _ in
            guard requestID == id else { return }
            snapshot = result?.image
            snapshotter = nil
        }
    }
}
