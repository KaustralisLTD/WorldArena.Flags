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
    let countryCode: String
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
                .task(id: "\(countryCode):\(coordinate.latitude):\(coordinate.longitude):\(geometry.size.width):\(colorScheme)") {
                    loadSnapshot(coordinate: coordinate, size: geometry.size)
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LocalizationManager.shared.localizedString("facts.map"))
            .accessibilityIdentifier("quiz.countryMap")
            .accessibilityValue(snapshot == nil ? "loading" : "ready")
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
        let polygons = CountryFactBoundaries.polygons(for: countryCode)
        if let rect = CountryFactBoundaries.focusRect(polygons: polygons, near: coordinate) {
            // Match the image aspect ratio so tall and small countries stay fully visible.
            let aspect = min(size.width, 720) / 130
            let width = max(rect.size.width * 1.3, rect.size.height * 1.3 * aspect, 3000)
            let height = max(rect.size.height * 1.3, width / aspect)
            options.mapRect = MKMapRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
        } else {
            options.region = MKCoordinateRegion(center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3))
        }
        options.size = CGSize(width: min(size.width, 720), height: 130)
        options.scale = 2
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let renderer = MKMapSnapshotter(options: options)
        snapshotter = renderer
        renderer.start { result, _ in
            guard requestID == id else { return }
            if let result {
                snapshot = CountryFactBoundaries.draw(polygons: polygons, on: result)
            }
            snapshotter = nil
        }
    }
}

// Natural Earth 1:50m Admin 0 polygons, bundled for offline boundary lookup.
// Rings retain their holes and detached islands; only the selected country is drawn.
enum CountryFactBoundaries {
    typealias Polygon = [[[Double]]]
    private static let countries: [String: [Polygon]] = {
        guard let url = Bundle.main.url(forResource: "country-boundaries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [Polygon]].self, from: data) else { return [:] }
        return decoded
    }()
    static func polygons(for code: String) -> [Polygon] {
        countries[code == "XKX" ? "KOS" : code.uppercased()] ?? []
    }
    static func focusRect(polygons: [Polygon], near center: CLLocationCoordinate2D) -> MKMapRect? {
        let anchor = MKMapPoint(center)
        let worldWidth = MKMapRect.world.size.width
        let rects = polygons.compactMap { polygon -> MKMapRect? in
            guard let ring = polygon.first, !ring.isEmpty else { return nil }
            var rect = MKMapRect.null
            for pair in ring where pair.count >= 2 {
                var point = MKMapPoint(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
                // Keep countries crossing the date line in one continuous viewport.
                point.x += ((anchor.x - point.x) / worldWidth).rounded() * worldWidth
                rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
            }
            return rect.isNull ? nil : rect
        }
        // Focus the main territory near the country's coordinates rather than
        // zooming out to encompass overseas possessions on other continents.
        return rects.min { a, b in
            func distance(_ r: MKMapRect) -> Double {
                let dx = max(r.minX - anchor.x, 0, anchor.x - r.maxX)
                let dy = max(r.minY - anchor.y, 0, anchor.y - r.maxY)
                return dx * dx + dy * dy
            }
            return distance(a) < distance(b)
        }
    }
    static func draw(polygons: [Polygon], on snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = snapshot.image.scale
        return UIGraphicsImageRenderer(size: snapshot.image.size, format: format).image { context in
            snapshot.image.draw(at: .zero)
            let cg = context.cgContext
            cg.setFillColor(UIColor.systemBlue.withAlphaComponent(0.22).cgColor)
            cg.setStrokeColor(UIColor.systemBlue.cgColor)
            cg.setLineWidth(2)
            cg.setLineJoin(.round)
            for polygon in polygons {
                let path = CGMutablePath()
                for ring in polygon {
                    var previous: CGPoint?
                    for pair in ring where pair.count >= 2 {
                        var point = snapshot.point(for: CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
                        let origin = snapshot.point(for: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        let east = snapshot.point(for: CLLocationCoordinate2D(latitude: 0, longitude: 1))
                        let worldPixels = abs(east.x - origin.x) * 360
                        if worldPixels.isFinite && worldPixels > 0 {
                            point.x += ((snapshot.image.size.width / 2 - point.x) / worldPixels).rounded() * worldPixels
                        }
                        if previous == nil { path.move(to: point) }
                        else { path.addLine(to: point) }
                        previous = point
                    }
                    path.closeSubpath()
                }
                cg.addPath(path)
                cg.drawPath(using: .eoFillStroke)
            }
        }
    }
}
