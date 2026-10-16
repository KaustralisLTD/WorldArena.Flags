import SwiftUI

struct ContinentDetailView: View {
    let continentName: String
    let continentEmoji: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var safeTopInset: CGFloat = 0
    @State private var selectedFilter: LearningCountryFilter = .all
    @State private var searchQuery: String = ""
    @State private var debouncedSearchQuery: String = ""
    @State private var searchDebounceWork: DispatchWorkItem?

    private var baseCountriesSorted: [CountryInfo] {
        countriesForContinent(continentName).sorted {
            let lhs = getLocalizedCountryName($0.code, $0.name)
            let rhs = getLocalizedCountryName($1.code, $1.name)
            let order = lhs.compare(rhs, options: .caseInsensitive, locale: localizationManager.currentLocale)
            return order == .orderedSame ? $0.code < $1.code : order == .orderedAscending
        }
    }

    private var filteredByFilter: [CountryInfo] {
        LearningCountryProgressLogic.applyFilter(baseCountriesSorted, filter: selectedFilter, gameState: gameState)
    }

    private var displayedCountries: [CountryInfo] {
        filteredByFilter.filter { LearningCountryProgressLogic.searchMatches(country: $0, query: debouncedSearchQuery) }
    }

    private var alphabetSections: [(String, [CountryInfo])] {
        let grouped = Dictionary(grouping: displayedCountries) { country in
            let localizedName = getLocalizedCountryName(country.code, country.name)
            return String(localizedName.prefix(1).uppercased())
        }
        return grouped.sorted { LearningAlphabetOrder.precedes($0.key, $1.key, locale: localizationManager.currentLocale) }
    }

    private var studiedCount: Int {
        LearningCountryProgressLogic.studiedCount(in: baseCountriesSorted, gameState: gameState)
    }

    private var totalCount: Int { baseCountriesSorted.count }

    private var listEmptyContent: (title: String, message: String, actionTitle: String?, action: (() -> Void)?)? {
        guard displayedCountries.isEmpty else { return nil }
        let q = debouncedSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            return (
                localizationManager.localizedString("learning.empty.search.title"),
                localizationManager.localizedString("learning.empty.search.subtitle"),
                localizationManager.localizedString("learning.empty.search.reset"),
                {
                    searchQuery = ""
                    debouncedSearchQuery = ""
                }
            )
        }
        switch selectedFilter {
        case .unlearned:
            return (
                localizationManager.localizedString("learning.empty.unlearned.title"),
                localizationManager.localizedString("learning.empty.unlearned.message"),
                nil,
                nil
            )
        case .difficult:
            return (
                localizationManager.localizedString("learning.empty.difficult.title"),
                localizationManager.localizedString("learning.empty.difficult.message"),
                nil,
                nil
            )
        case .favorites:
            return (
                localizationManager.localizedString("learning.empty.favorites.title"),
                localizationManager.localizedString("learning.empty.favorites.message"),
                nil,
                nil
            )
        case .all:
            return nil
        }
    }

    private var systemGroupedBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    var body: some View {
        ZStack(alignment: .top) {
            systemGroupedBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                VStack(spacing: 0) {
                    LearningProgressSummaryView(studied: studiedCount, total: totalCount)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)

                    LearningSearchBarView(text: $searchQuery)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                        .onChange(of: searchQuery) { newValue in
                            searchDebounceWork?.cancel()
                            let work = DispatchWorkItem { debouncedSearchQuery = newValue }
                            searchDebounceWork = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
                        }

                    LearningFiltersChipsView(selected: $selectedFilter, useEqualWidthLayout: true)
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(systemGroupedBackground)

                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        ScrollView {
                            LazyVStack(spacing: 4, pinnedViews: [.sectionHeaders]) {
                                Color.clear
                                    .frame(height: 1)
                                    .id("learningListTop")

                                if let empty = listEmptyContent {
                                    LearningEmptyStateView(
                                        title: empty.title,
                                        message: empty.message,
                                        actionTitle: empty.actionTitle,
                                        action: empty.action
                                    )
                                } else {
                                    ForEach(alphabetSections, id: \.0) { letter, countries in
                                        Section(header:
                                            HStack {
                                                Text(letter)
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                Spacer()
                                            }
                                            .background(Color(UIColor.systemGroupedBackground))
                                            .id(letter)
                                        ) {
                                            ForEach(countries, id: \.code) { country in
                                                CountryCard(
                                                    country: country,
                                                    navigationCountryCodes: baseCountriesSorted.map(\.code)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                            .padding(.trailing, 36)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(systemGroupedBackground)
                                .ignoresSafeArea(.container, edges: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .padding(.top, -10)

                        VStack {
                            Spacer().frame(height: alphabetIndexTopOffset)
                            AlphabetIndex(
                                letters: alphabetSections.map(\.0),
                                onLetterTapped: { letter in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo(letter, anchor: .top)
                                    }
                                }
                            )
                            Spacer()
                        }
                        .padding(.trailing, 8)
                    }
                    .onChange(of: selectedFilter) { _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("learningListTop", anchor: .top)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameState.reloadCountryLearningProgressFromStorage()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical), horizontal > 70 else { return }
                    dismiss()
                }
        )
        .background(GeometryReader { geometry in
            Color.clear
                .preference(key: SafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
        })
        .onPreferenceChange(SafeTopInsetKey.self) { value in
            safeTopInset = value
        }
    }

    private var alphabetIndexTopOffset: CGFloat { 22 }

    /// Та же геометрия шапки, что и на экране «Все страны».
    private var headerHeight: CGFloat {
        let safe = max(safeTopInset, 44)
        return safe + 56
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            Text(continentEmoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 4) {
                Text(localizationManager.localizedString(continentName))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("\(totalCount) \(localizationManager.localizedString("стран"))")
                    .font(.subheadline).opacity(0.9)
            }
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(.container, edges: .top))
    }

    // MARK: - Countries Data (из CountryDatabase + country_regions.json)
    private func countriesForContinent(_ continent: String) -> [CountryInfo] {
        CountryLearningCatalog.countries(forContinentName: continent)
            .sorted { $0.name < $1.name }
    }
}

// MARK: - CountryCard
struct CountryCard: View {
    let country: CountryInfo
    let navigationCountryCodes: [String]
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        NavigationLink(
            destination: CountryDetailView(
                countryCode: country.code,
                countryName: getLocalizedCountryName(country.code, country.name),
                flagEmoji: country.flag,
                navigationCountryCodes: navigationCountryCodes
            )
            .environmentObject(gameState)
        ) {
            HStack(spacing: 8) {
                // Официальный флаг страны
                FlagImageView(countryCode: country.code, flagEmoji: country.flag)
                
                VStack(alignment: .leading, spacing: 1) { // Уменьшили отступ между элементами
                    Text(getLocalizedCountryName(country.code, country.name))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !country.capital.isEmpty {
                        Text("\(localizationManager.localizedString("Столица")): \(getLocalizedCapitalName(country.code, country.capital))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 6) // Уменьшили горизонтальные отступы
            .padding(.vertical, 1) // Минимальные вертикальные отступы  
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(8) // Уменьшили радиус скругления
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1) // Уменьшили тень
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FlagImageView
struct FlagImageView: View {
    let countryCode: String
    let flagEmoji: String
    
    var body: some View {
        AllCountriesFlagImageView(countryCode: countryCode, flagEmoji: flagEmoji)
            .frame(width: 120, height: 80)
    }
}

// MARK: - CountryInfo Model
struct CountryInfo {
    let name: String
    let flag: String
    let capital: String
    let code: String
}

// MARK: - AlphabetIndex
struct AlphabetIndex: View {
    let letters: [String]
    let onLetterTapped: (String) -> Void
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(letters, id: \.self) { letter in
                Button(action: {
                    onLetterTapped(letter)
                }) {
                    Text(letter)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 26, height: 20)
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Localization (единый источник: CountryDatabase; язык по приложению, по умолчанию en — чтобы не проскакивали русские названия в англоязычной версии)
@MainActor
private func getLocalizedCountryName(_ countryCode: String, _ fallbackName: String) -> String {
    let lang = LocalizationManager.shared.currentBundleLanguageCode
    let effectiveLang = lang.isEmpty ? "en" : lang
    let localized = CountryDatabase.getLocalizedCountryName(for: countryCode, language: effectiveLang, fallback: fallbackName)
    if localized != fallbackName || effectiveLang == "ru" { return localized }
    if let byLocale = Locale(identifier: effectiveLang).localizedString(forRegionCode: countryCode.uppercased()) {
        return byLocale
    }
    if let enName = Locale(identifier: "en").localizedString(forRegionCode: countryCode.uppercased()) {
        return enName
    }
    return localized
}

@MainActor
private func getLocalizedCapitalName(_ countryCode: String, _ fallbackCapital: String) -> String {
    let lang = LocalizationManager.shared.currentBundleLanguageCode
    let effectiveLang = lang.isEmpty ? "en" : lang
    // В исходных массивах fallbackCapital часто на русском. Для любых языков кроме ru
    // берём fallback из базы на английском, чтобы не проскакивали русские столицы.
    let effectiveFallback: String = (effectiveLang == "ru")
        ? fallbackCapital
        : CountryDatabase.getLocalizedCapitalName(for: countryCode, language: "en", fallback: fallbackCapital)
    return CountryDatabase.getLocalizedCapitalName(for: countryCode, language: effectiveLang, fallback: effectiveFallback)
}

// MARK: - Localized Alphabet Functions
@MainActor
private func getLocalizedAlphabet() -> [String] {
    let currentLanguage = LocalizationManager.shared.currentBundleLanguageCode
    let lang = currentLanguage.isEmpty ? "en" : currentLanguage
    
    switch lang {
    case "en":
        return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    case "es":
        return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    case "uk":
        return ["А", "Б", "В", "Г", "Д", "Е", "Є", "Ж", "З", "И", "І", "Ї", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ь", "Ю", "Я"]
    case "ca":
        return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    case "zh":
        return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    default: // "ru"
        return ["А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"]
    }
}

// MARK: - SafeTopInsetKey
private struct SafeTopInsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    ContinentDetailView(continentName: "Европа", continentEmoji: "🇪🇺")
        .environmentObject(GameState())
}
