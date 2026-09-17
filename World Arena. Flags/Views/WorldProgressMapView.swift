import SwiftUI
import MapKit

struct WorldProgressMapView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
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
    /// Язык карты применён до первого рендера Map, чтобы подпись «Карты»/«Правовые документы» была на выбранном языке.
    @State private var mapLocaleApplied = false
    @State private var toastText: String = ""
    @State private var showToast = false
    @State private var showMasteredHint = false
    private struct BadgeUnlock: Identifiable {
        let id = UUID()
        let continentTitle: String
    }
    @State private var badgeUnlocked: BadgeUnlock? = nil
    @AppStorage("learning.masteredContinents.v1") private var masteredContinentsRaw: String = ""
    /// Сохранённое значение AppleLanguages до входа на экран карты (для восстановления при уходе).
    @State private var savedAppleLanguages: [String]?

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
        filteredCountries.compactMap { country in
            guard let coordinate = coordinate(for: country) else { return nil }
            return CountryPoint(
                id: country.id,
                country: country,
                coordinate: coordinate
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

    private var pageBackground: some View {
        Group {
            if colorScheme == .light {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.98, blue: 1.0),
                        Color(red: 0.90, green: 0.93, blue: 0.98),
                        Color(red: 0.86, green: 0.91, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.12, green: 0.17, blue: 0.29)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var continentProgress: [ContinentProgress] {
        let grouped = Dictionary(grouping: worldCountries, by: continentKey(for:))
        let order = [
            "Europe",
            "Asia",
            "Africa",
            "North America",
            "South America",
            "Oceania"
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
                title: localizedContinentName(key),
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
                    if mapLocaleApplied {
                        mapCard
                    } else {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.black.opacity(0.24))
                            .frame(height: 370)
                            .overlay(ProgressView().tint(colorScheme == .light ? Color.accentColor : .white))
                    }
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
        .environment(\.locale, localizationManager.currentLocale)
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle(localizationManager.localizedString("World Progress Map"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorldCountries()
        }
        .onAppear {
            gameState.reloadCountryLearningProgressFromStorage()
            gameState.refreshWeeklyChallengeCount()
            LocalProgressICloudMirror.pushString(masteredContinentsRaw, forKey: LocalProgressICloudMirror.keyMasteredContinents)
            if !mapLocaleApplied {
                applyMapLanguage()
                mapLocaleApplied = true
            }
        }
        .onDisappear {
            restoreMapLanguage()
        }
        .onChange(of: gameState.isNavigatingToGame) { navigating in
            if !navigating {
                gameState.refreshWeeklyChallengeCount()
            }
        }
        .onChange(of: gameState.countryLearningProgress) { _ in
            evaluateContinentMasterUnlocks()
        }
        .onChange(of: masteredContinentsRaw) { _ in
            LocalProgressICloudMirror.pushString(masteredContinentsRaw, forKey: LocalProgressICloudMirror.keyMasteredContinents)
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
                .foregroundColor(colorScheme == .light ? Color(red: 0.06, green: 0.12, blue: 0.28) : .white)
            Text(localizationManager.localizedString("Tap a country to see your correct and wrong answers"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .light ? Color(red: 0.2, green: 0.24, blue: 0.38) : .white.opacity(0.85))
            Text(localizationManager.localizedString("Greener country means better mastery"))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(colorScheme == .light ? Color(red: 0.0, green: 0.45, blue: 0.32) : .green.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    colorScheme == .light
                        ? LinearGradient(
                            colors: [Color.white, Color(red: 0.93, green: 0.96, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.cyan.opacity(0.32), Color.blue.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    colorScheme == .light ? Color.blue.opacity(0.14) : Color.white.opacity(0.22),
                    lineWidth: 1
                )
        )
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.06) : .clear, radius: 12, x: 0, y: 4)
    }

    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.black.opacity(0.24))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.16), lineWidth: 1)

            if isLoading {
                ProgressView()
                    .tint(colorScheme == .light ? Color.accentColor : .white)
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
                                        .stroke(colorScheme == .light ? Color.black.opacity(0.2) : Color.white.opacity(0.8), lineWidth: 1)
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
                        .foregroundColor(
                            selectedTab == tab
                                ? Color.white
                                : (colorScheme == .light ? Color(red: 0.12, green: 0.18, blue: 0.42) : Color.white.opacity(0.88))
                        )
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    selectedTab == tab
                                        ? LinearGradient(
                                            colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.08, green: 0.32, blue: 0.82)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: colorScheme == .light
                                                ? [Color(UIColor.secondarySystemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)]
                                                : [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    selectedTab == tab
                                        ? Color.clear
                                        : (colorScheme == .light ? Color.blue.opacity(0.12) : Color.white.opacity(0.12)),
                                    lineWidth: 1
                                )
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
                        .foregroundColor(
                            mapFilter == filter
                                ? (colorScheme == .light ? Color.white : Color.white)
                                : (colorScheme == .light ? Color(red: 0.14, green: 0.2, blue: 0.38) : Color.white.opacity(0.9))
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    mapFilter == filter
                                        ? LinearGradient(
                                            colors: [Color(red: 0.2, green: 0.55, blue: 0.42), Color(red: 0.1, green: 0.48, blue: 0.55)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            colors: colorScheme == .light
                                                ? [Color(UIColor.secondarySystemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)]
                                                : [Color.white.opacity(0.09), Color.white.opacity(0.09)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    mapFilter == filter ? Color.clear : (colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.1)),
                                    lineWidth: 1
                                )
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
                        .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
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
                    .fill(colorScheme == .light ? Color(UIColor.secondarySystemGroupedBackground) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.16), lineWidth: 1)
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
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
                Spacer()
                Text("\(current)/\(goal)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.95))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.white.opacity(0.12))
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
                .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .light ? Color(UIColor.secondarySystemGroupedBackground) : Color.black.opacity(0.25))
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
                .foregroundColor(colorScheme == .light ? Color.primary : Color.white)

            if weakCountries.isEmpty {
                Text(localizationManager.localizedString("No weak countries yet"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.75))
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(weakCountries.prefix(20).enumerated()), id: \.element.id) { idx, country in
                    let p = gameState.progressForCountry(code3: country.id)
                    HStack(spacing: 10) {
                        Text("#\(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.75))
                            .frame(width: 24, alignment: .leading)
                        Text(country.flagEmoji)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizationManager.localizedCountryName(country))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
                            Text("\(localizationManager.localizedString("Wrong")) \(p.wrong) • \(localizationManager.localizedString("Correct")) \(p.correct)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.75))
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
                            .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.white.opacity(0.06))
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .light ? Color(UIColor.secondarySystemGroupedBackground) : Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var continentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("Continent Mastery"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.white)

            ForEach(continentProgress) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
                        Spacer()
                        if item.isMastered {
                            Text(String(format: localizationManager.localizedString("%@ Master"), item.title))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("\(Int((item.completion * 100).rounded()))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.86))
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.white.opacity(0.12))
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
                        .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.8))

                        HStack(spacing: 4) {
                            Text(
                                String(
                                    format: localizationManager.localizedString("Mastered %d of %d countries"),
                                    item.masteredCountries,
                                    item.totalCountries
                                )
                            )
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.7))
                            Button {
                                showMasteredHint = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(colorScheme == .light ? Color.secondary : Color.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.white.opacity(0.05))
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .light ? Color(UIColor.secondarySystemGroupedBackground) : Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.16), lineWidth: 1)
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
                .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.95))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .light ? Color(UIColor.tertiarySystemFill) : Color.white.opacity(0.07))
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
        guard p.total > 0 else {
            return colorScheme == .light ? Color.primary.opacity(0.2) : Color.white.opacity(0.24)
        }
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

    private func continentKey(for country: Country) -> String {
        if country.region == "Europe" { return "Europe" }
        if country.region == "Asia" { return "Asia" }
        if country.region == "Africa" { return "Africa" }
        if country.region == "Oceania" { return "Oceania" }
        if country.region == "Americas" {
            if country.subregion == "South America" {
                return "South America"
            }
            return "North America"
        }
        return "Europe"
    }

    private func localizedContinentName(_ key: String) -> String {
        switch key {
        case "Europe": return localizationManager.localizedString("Европа")
        case "Asia": return localizationManager.localizedString("Азия")
        case "Africa": return localizationManager.localizedString("Африка")
        case "North America": return localizationManager.localizedString("Северная Америка")
        case "South America": return localizationManager.localizedString("Южная Америка")
        case "Oceania": return localizationManager.localizedString("Океания")
        default: return key
        }
    }

    private func coordinate(for country: Country) -> CLLocationCoordinate2D? {
        guard let latlng = country.latlng, latlng.count == 2,
              latlng[0].isFinite, latlng[1].isFinite else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        // Missing data must never produce a made-up location on the map.
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }

    private var masterToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.yellow)
            Text(toastText)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
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
                .stroke(colorScheme == .light ? Color.black.opacity(0.1) : Color.white.opacity(0.32), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(colorScheme == .light ? 0.12 : 0.25), radius: 12, x: 0, y: 8)
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
        let localized = localizedContinentName(first)
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

    /// Устанавливает язык карты MapKit по выбранному в приложении (подписи на карте в нужной локали).
    private func applyMapLanguage() {
        savedAppleLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages")
        let mapLocale = localizationManager.mapKitLocaleIdentifier
        UserDefaults.standard.set([mapLocale], forKey: "AppleLanguages")
    }

    /// Восстанавливает AppleLanguages после ухода с экрана карты, чтобы не влиять на остальное приложение.
    private func restoreMapLanguage() {
        if let saved = savedAppleLanguages {
            UserDefaults.standard.set(saved, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        savedAppleLanguages = nil
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

