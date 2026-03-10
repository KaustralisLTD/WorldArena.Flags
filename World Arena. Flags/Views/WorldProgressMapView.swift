import SwiftUI
import MapKit

struct WorldProgressMapView: View {
    @EnvironmentObject private var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var worldCountries: [Country] = []
    @State private var selectedCountry: Country?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 18, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
    )
    @State private var isLoading = true
    @State private var selectedTab: DisplayTab = .map
    @State private var mapFilter: MapFilter = .all
    @State private var toastText: String = ""
    @State private var showToast = false
    @State private var showMasteredHint = false
    private struct BadgeUnlock: Identifiable {
        let id = UUID()
        let continentTitle: String
    }
    @State private var badgeUnlocked: BadgeUnlock? = nil
    @AppStorage("learning.masteredContinents.v1") private var masteredContinentsRaw: String = ""

    private enum DisplayTab: String, CaseIterable, Identifiable {
        case map = "Map"
        case weak = "Weak countries"
        var id: String { rawValue }
    }

    private enum MapFilter: String, CaseIterable, Identifiable {
        case all = "All countries"
        case weak = "Only weak"
        case mastered = "Only mastered"
        var id: String { rawValue }
    }

    private struct CountryPoint: Identifiable {
        let id: String
        let country: Country
        let coordinate: CLLocationCoordinate2D
    }

    private struct ContinentProgress: Identifiable {
        let id: String
        let title: String
        let totalCountries: Int
        let answeredCountries: Int
        let masteredCountries: Int

        /// Доля освоенных стран (для процента и прогресс-бара).
        var completion: Double {
            guard totalCountries > 0 else { return 0 }
            return Double(masteredCountries) / Double(totalCountries)
        }

        var isMastered: Bool {
            totalCountries > 0 && masteredCountries == totalCountries
        }
    }

    private var filteredCountries: [Country] {
        switch mapFilter {
        case .all:
            return worldCountries
        case .weak:
            return worldCountries.filter { isWeak(country: $0) }
        case .mastered:
            return worldCountries.filter { isMastered(country: $0) }
        }
    }

    private var points: [CountryPoint] {
        filteredCountries.map { country in
            CountryPoint(
                id: country.id,
                country: country,
                coordinate: coordinate(for: country)
            )
        }
    }

    private var weakCountries: [Country] {
        worldCountries
            .filter { gameState.progressForCountry(code3: $0.id).total >= 3 }
            .sorted { lhs, rhs in
                let lp = gameState.progressForCountry(code3: lhs.id)
                let rp = gameState.progressForCountry(code3: rhs.id)
                let lScore = Double(lp.wrong * 2 + max(0, lp.wrong - lp.correct)) + (1.0 - lp.accuracy) * 30.0
                let rScore = Double(rp.wrong * 2 + max(0, rp.wrong - rp.correct)) + (1.0 - rp.accuracy) * 30.0
                if lScore == rScore { return lp.total > rp.total }
                return lScore > rScore
            }
    }

    private var continentProgress: [ContinentProgress] {
        let grouped = Dictionary(grouping: worldCountries, by: continentName(for:))
        let order = [
            "Европа",
            "Азия",
            "Африка",
            "Северная Америка",
            "Южная Америка",
            "Океания"
        ]

        return order.compactMap { key in
            guard let countries = grouped[key], !countries.isEmpty else { return nil }
            var answered = 0
            var mastered = 0
            for country in countries {
                let p = gameState.progressForCountry(code3: country.id)
                if p.total > 0 { answered += 1 }
                if p.total >= 3 && p.accuracy >= 0.8 { mastered += 1 }
            }
            return ContinentProgress(
                id: key,
                title: localizationManager.localizedString(key),
                totalCountries: countries.count,
                answeredCountries: answered,
                masteredCountries: mastered
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                tabSelector
                if selectedTab == .map {
                    filtersRow
                    mapCard
                    selectedCountryCard
                } else {
                    weeklyChallengeCard
                    startWeakTrainingButton
                    weakCountriesCard
                }
                continentsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.12, green: 0.17, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(localizationManager.localizedString("World Progress Map"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorldCountries()
        }
        .onAppear {
            gameState.reloadCountryLearningProgressFromStorage()
            gameState.refreshWeeklyChallengeCount()
        }
        .onChange(of: gameState.isNavigatingToGame) { navigating in
            if !navigating {
                gameState.refreshWeeklyChallengeCount()
            }
        }
        .onChange(of: gameState.countryLearningProgress) { _ in
            evaluateContinentMasterUnlocks()
        }
        .overlay(alignment: .top) {
            if showToast {
                masterToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .fullScreenCover(item: $badgeUnlocked) { item in
            ContinentMasterBadgeView(continentTitle: item.continentTitle) {
                badgeUnlocked = nil
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationManager.localizedString("World Progress Map"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(localizationManager.localizedString("Tap a country to see your correct and wrong answers"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Text(localizationManager.localizedString("Greener country means better mastery"))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.green.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.32), Color.blue.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }

    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.24))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Map(coordinateRegion: $region, annotationItems: points) { point in
                    MapAnnotation(coordinate: point.coordinate) {
                        Button {
                            selectedCountry = point.country
                        } label: {
                            Circle()
                                .fill(countryColor(for: point.country))
                                .frame(width: markerSize(for: point.country), height: markerSize(for: point.country))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                )
                                .shadow(color: countryColor(for: point.country).opacity(0.6), radius: 6, x: 0, y: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .frame(height: 370)
    }

    private var tabSelector: some View {
        HStack(spacing: 10) {
            ForEach(DisplayTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(localizationManager.localizedString(tab.rawValue))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedTab == tab ? .black : .white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTab == tab ? Color.green.opacity(0.9) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filtersRow: some View {
        HStack(spacing: 8) {
            ForEach(MapFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mapFilter = filter
                        if let selected = selectedCountry, !filteredCountries.contains(selected) {
                            selectedCountry = filteredCountries.first
                        }
                    }
                } label: {
                    Text(localizationManager.localizedString(filter.rawValue))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(mapFilter == filter ? .black : .white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(mapFilter == filter ? Color.mint.opacity(0.92) : Color.white.opacity(0.09))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var selectedCountryCard: some View {
        if let country = selectedCountry, filteredCountries.contains(country) {
            let progress = gameState.progressForCountry(code3: country.id)
            let accuracy = Int((progress.accuracy * 100).rounded())
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(country.flagEmoji) \(localizationManager.localizedCountryName(country))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(accuracy)%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green.opacity(0.95))
                }
                HStack(spacing: 12) {
                    statPill(
                        title: localizationManager.localizedString("Correct"),
                        value: "\(progress.correct)",
                        color: .green
                    )
                    statPill(
                        title: localizationManager.localizedString("Wrong"),
                        value: "\(progress.wrong)",
                        color: .red
                    )
                    statPill(
                        title: localizationManager.localizedString("Total"),
                        value: "\(progress.total)",
                        color: .blue
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
        }
    }

    private var weeklyChallengeCard: some View {
        let goal = GameState.weeklyChallengeGoal
        let current = gameState.weeklyChallengeSessionsThisWeek
        let progress = goal > 0 ? min(1.0, Double(current) / Double(goal)) : 0.0
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                Text(localizationManager.localizedString("Weekly challenge"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(current)/\(goal)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.9), .yellow.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)
            Text(localizationManager.localizedString("Weak country sessions this week"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    private var startWeakTrainingButton: some View {
        Button {
            let ids = Set(weakCountries.prefix(30).map(\.id))
            guard !ids.isEmpty else { return }
            gameState.weakCountryIdsForTraining = ids
            gameState.selectedRegions = [.all]
            Task {
                await gameState.startNewGameWithCurrentRegions()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                Text(localizationManager.localizedString("Start Weak Countries Training"))
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.mint, Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(weakCountries.isEmpty || gameState.isStartingNewGame)
    }

    private var weakCountriesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("TOP weak countries for review"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            if weakCountries.isEmpty {
                Text(localizationManager.localizedString("No weak countries yet"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(weakCountries.prefix(20).enumerated()), id: \.element.id) { idx, country in
                    let p = gameState.progressForCountry(code3: country.id)
                    HStack(spacing: 10) {
                        Text("#\(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: 24, alignment: .leading)
                        Text(country.flagEmoji)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizationManager.localizedCountryName(country))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(localizationManager.localizedString("Wrong")) \(p.wrong) • \(localizationManager.localizedString("Correct")) \(p.correct)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                        Text("\(Int((p.accuracy * 100).rounded()))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(p.accuracy < 0.5 ? .red.opacity(0.95) : .yellow.opacity(0.95))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var continentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("Continent Mastery"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            ForEach(continentProgress) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if item.isMastered {
                            Text(String(format: localizationManager.localizedString("%@ Master"), item.title))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("\(Int((item.completion * 100).rounded()))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.86))
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.75), Color.mint.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * item.completion)
                        }
                    }
                    .frame(height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            String(
                                format: localizationManager.localizedString("Answered %d of %d countries"),
                                item.answeredCountries,
                                item.totalCountries
                            )
                        )
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 4) {
                            Text(
                                String(
                                    format: localizationManager.localizedString("Mastered %d of %d countries"),
                                    item.masteredCountries,
                                    item.totalCountries
                                )
                            )
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            Button {
                                showMasteredHint = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .alert(localizationManager.localizedString("How is Mastered calculated?"), isPresented: $showMasteredHint) {
            Button(localizationManager.localizedString("CONTINUE"), role: .cancel) { }
        } message: {
            Text(localizationManager.localizedString("Mastered explanation"))
        }
    }

    private func statPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.95))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
    }

    private func markerSize(for country: Country) -> CGFloat {
        let p = gameState.progressForCountry(code3: country.id)
        if p.total == 0 { return 7 }
        if p.total < 5 { return 8 }
        if p.total < 15 { return 9 }
        return 10
    }

    private func countryColor(for country: Country) -> Color {
        let p = gameState.progressForCountry(code3: country.id)
        guard p.total > 0 else { return Color.white.opacity(0.24) }
        let t = min(1.0, max(0.0, p.accuracy))
        return Color(
            red: 0.15 * (1.0 - t),
            green: 0.45 + 0.55 * t,
            blue: 0.20 + 0.15 * t
        )
    }

    private func isMastered(country: Country) -> Bool {
        let p = gameState.progressForCountry(code3: country.id)
        return p.total >= 3 && p.accuracy >= 0.8
    }

    private func isWeak(country: Country) -> Bool {
        let p = gameState.progressForCountry(code3: country.id)
        return p.total >= 3 && (p.accuracy < 0.6 || p.wrong > p.correct)
    }

    private func continentName(for country: Country) -> String {
        if country.region == "Europe" { return "Европа" }
        if country.region == "Asia" { return "Азия" }
        if country.region == "Africa" { return "Африка" }
        if country.region == "Oceania" { return "Океания" }
        if country.region == "Americas" {
            if country.subregion == "South America" {
                return "Южная Америка"
            }
            return "Северная Америка"
        }
        return "Европа"
    }

    private func coordinate(for country: Country) -> CLLocationCoordinate2D {
        if let latlng = country.latlng, latlng.count >= 2 {
            return CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        }
        return fallbackCoordinate(for: country)
    }

    private func fallbackCoordinate(for country: Country) -> CLLocationCoordinate2D {
        let center: (Double, Double)
        switch continentName(for: country) {
        case "Европа": center = (52, 15)
        case "Азия": center = (28, 90)
        case "Африка": center = (4, 21)
        case "Северная Америка": center = (38, -100)
        case "Южная Америка": center = (-14, -60)
        case "Океания": center = (-23, 135)
        default: center = (20, 0)
        }
        let seed = stableSeed(country.id)
        let latOffset = Double((seed % 1700) - 850) / 100.0
        let lonOffset = Double(((seed / 1700) % 2500) - 1250) / 100.0
        return CLLocationCoordinate2D(
            latitude: max(-80, min(80, center.0 + latOffset)),
            longitude: max(-179, min(179, center.1 + lonOffset))
        )
    }

    private func stableSeed(_ source: String) -> Int {
        source.unicodeScalars.reduce(19) { ($0 &* 31) &+ Int($1.value) } & Int.max
    }

    private var masterToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.yellow)
            Text(toastText)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.94), Color.mint.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private func evaluateContinentMasterUnlocks() {
        var unlocked = Set(masteredContinentsRaw.split(separator: ",").map(String.init))
        var newUnlocks: [String] = []
        for item in continentProgress where item.isMastered {
            if !unlocked.contains(item.id) {
                unlocked.insert(item.id)
                newUnlocks.append(item.id)
            }
        }
        guard !newUnlocks.isEmpty else { return }
        masteredContinentsRaw = unlocked.sorted().joined(separator: ",")

        let first = newUnlocks[0]
        let localized = localizationManager.localizedString(first)
        let format = localizationManager.localizedString("%@ Master unlocked")
        toastText = String(format: format, localized)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
        badgeUnlocked = BadgeUnlock(continentTitle: localized)
    }

    @MainActor
    private func loadWorldCountries() async {
        isLoading = true
        do {
            worldCountries = try await gameState.fetchCountries(for: [.all])
            if selectedCountry == nil {
                selectedCountry = worldCountries.first
            }
            evaluateContinentMasterUnlocks()
        } catch {
            worldCountries = []
        }
        isLoading = false
    }
}

