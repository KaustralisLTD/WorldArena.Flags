import SwiftUI

// MARK: - Localization (единый источник: CountryDatabase + доп. словари для de, fr, it, pl, nl, pt)
@MainActor
private func getLocalizedCountryName(_ countryCode: String, _ fallbackName: String) -> String {
    let lang = LocalizationManager.shared.currentLocale.languageCode ?? "ru"
    let localized = CountryDatabase.getLocalizedCountryName(for: countryCode, language: lang, fallback: fallbackName)
    if localized != fallbackName || lang == "ru" { return localized }
    if let byLocale = Locale(identifier: lang).localizedString(forRegionCode: countryCode.uppercased()) {
        return byLocale
    }
    if let enName = Locale(identifier: "en").localizedString(forRegionCode: countryCode.uppercased()) {
        return enName
    }
    return localized
}

// MARK: - English Names
private func getEnglishCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        // Europe
        "AT": "Austria", "AL": "Albania", "AD": "Andorra", "AM": "Armenia", "AZ": "Azerbaijan",
        "BY": "Belarus", "BE": "Belgium", "BA": "Bosnia and Herzegovina", "BG": "Bulgaria",
        "HR": "Croatia", "CY": "Cyprus", "CZ": "Czech Republic", "DK": "Denmark", "EE": "Estonia",
        "FI": "Finland", "FR": "France", "GE": "Georgia", "DE": "Germany", "GR": "Greece",
        "HU": "Hungary", "IS": "Iceland", "IE": "Ireland", "IT": "Italy", "XK": "Kosovo",
        "LV": "Latvia", "LI": "Liechtenstein", "LT": "Lithuania", "LU": "Luxembourg",
        "MT": "Malta", "MD": "Moldova", "MC": "Monaco", "ME": "Montenegro", "NL": "Netherlands",
        "MK": "North Macedonia", "NO": "Norway", "PL": "Poland", "PT": "Portugal", "RO": "Romania",
        "RU": "Russia", "SM": "San Marino", "RS": "Serbia", "SK": "Slovakia", "SI": "Slovenia",
        "ES": "Spain", "SE": "Sweden", "CH": "Switzerland", "TR": "Turkey", "UA": "Ukraine",
        "GB": "United Kingdom", "VA": "Vatican City",
        
        // Asia
        "AF": "Afghanistan", "BH": "Bahrain", "BD": "Bangladesh", "BT": "Bhutan", "BN": "Brunei",
        "KH": "Cambodia", "CN": "China", "IN": "India", "ID": "Indonesia", "IR": "Iran",
        "IQ": "Iraq", "IL": "Israel", "JP": "Japan", "JO": "Jordan", "KZ": "Kazakhstan",
        "KW": "Kuwait", "KG": "Kyrgyzstan", "LA": "Laos", "LB": "Lebanon", "MY": "Malaysia",
        "MV": "Maldives", "MN": "Mongolia", "MM": "Myanmar", "NP": "Nepal", "OM": "Oman",
        "PK": "Pakistan", "PH": "Philippines", "QA": "Qatar", "SA": "Saudi Arabia", "SG": "Singapore",
        "LK": "Sri Lanka", "SY": "Syria", "TW": "Taiwan", "TJ": "Tajikistan", "TH": "Thailand",
        "TL": "Timor-Leste", "AE": "United Arab Emirates", "UZ": "Uzbekistan", "VN": "Vietnam", "YE": "Yemen",
        "KP": "North Korea", "PS": "Palestine", "TM": "Turkmenistan", "KR": "South Korea",
        
        // Africa
        "DZ": "Algeria", "AO": "Angola", "BJ": "Benin", "BW": "Botswana", "BF": "Burkina Faso",
        "BI": "Burundi", "CM": "Cameroon", "CV": "Cape Verde", "CF": "Central African Republic",
        "TD": "Chad", "KM": "Comoros", "CG": "Republic of the Congo", "CD": "Democratic Republic of the Congo",
        "CI": "Ivory Coast", "DJ": "Djibouti", "EG": "Egypt", "GQ": "Equatorial Guinea", "ER": "Eritrea",
        "ET": "Ethiopia", "GA": "Gabon", "GM": "Gambia", "GH": "Ghana", "GN": "Guinea",
        "GW": "Guinea-Bissau", "KE": "Kenya", "LS": "Lesotho", "LR": "Liberia", "LY": "Libya",
        "MG": "Madagascar", "MW": "Malawi", "ML": "Mali", "MR": "Mauritania", "MU": "Mauritius",
        "MA": "Morocco", "MZ": "Mozambique", "NA": "Namibia", "NE": "Niger", "NG": "Nigeria",
        "RW": "Rwanda", "ST": "São Tomé and Príncipe", "SN": "Senegal", "SC": "Seychelles",
        "SL": "Sierra Leone", "SO": "Somalia", "ZA": "South Africa", "SS": "South Sudan",
        "SD": "Sudan", "SZ": "Eswatini", "TZ": "Tanzania", "TG": "Togo", "TN": "Tunisia",
        "UG": "Uganda", "ZM": "Zambia", "ZW": "Zimbabwe",
        
        // Americas
        "AR": "Argentina", "BO": "Bolivia", "BR": "Brazil", "CL": "Chile", "CO": "Colombia",
        "EC": "Ecuador", "GY": "Guyana", "PY": "Paraguay", "PE": "Peru", "SR": "Suriname",
        "UY": "Uruguay", "VE": "Venezuela", "CA": "Canada", "MX": "Mexico", "US": "United States",
        "AG": "Antigua and Barbuda", "BS": "Bahamas", "BB": "Barbados", "BZ": "Belize",
        "CR": "Costa Rica", "CU": "Cuba", "DM": "Dominica", "DO": "Dominican Republic",
        "SV": "El Salvador", "GD": "Grenada", "GT": "Guatemala", "HT": "Haiti", "HN": "Honduras",
        "JM": "Jamaica", "NI": "Nicaragua", "PA": "Panama", "KN": "Saint Kitts and Nevis",
        "LC": "Saint Lucia", "VC": "Saint Vincent and the Grenadines", "TT": "Trinidad and Tobago",
        
        // Oceania
        "AU": "Australia", "FJ": "Fiji", "KI": "Kiribati", "MH": "Marshall Islands",
        "FM": "Micronesia", "NR": "Nauru", "NZ": "New Zealand", "PW": "Palau", "PG": "Papua New Guinea",
        "WS": "Samoa", "SB": "Solomon Islands", "TO": "Tonga", "TV": "Tuvalu", "VU": "Vanuatu"
    ]
    return names[code]
}

// MARK: - Spanish Names
private func getSpanishCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        // Europe
        "AT": "Austria", "AL": "Albania", "AD": "Andorra", "AM": "Armenia", "AZ": "Azerbaiyán",
        "BY": "Bielorrusia", "BE": "Bélgica", "BA": "Bosnia y Herzegovina", "BG": "Bulgaria",
        "HR": "Croacia", "CY": "Chipre", "CZ": "República Checa", "DK": "Dinamarca", "EE": "Estonia",
        "FI": "Finlandia", "FR": "Francia", "GE": "Georgia", "DE": "Alemania", "GR": "Grecia",
        "HU": "Hungría", "IS": "Islandia", "IE": "Irlanda", "IT": "Italia", "XK": "Kosovo",
        "LV": "Letonia", "LI": "Liechtenstein", "LT": "Lituania", "LU": "Luxemburgo",
        "MT": "Malta", "MD": "Moldavia", "MC": "Mónaco", "ME": "Montenegro", "NL": "Países Bajos",
        "MK": "Macedonia del Norte", "NO": "Noruega", "PL": "Polonia", "PT": "Portugal", "RO": "Rumania",
        "RU": "Rusia", "SM": "San Marino", "RS": "Serbia", "SK": "Eslovaquia", "SI": "Eslovenia",
        "ES": "España", "SE": "Suecia", "CH": "Suiza", "TR": "Turquía", "UA": "Ucrania",
        "GB": "Reino Unido", "VA": "Ciudad del Vaticano",
        
        // Asia
        "AF": "Afganistán", "BH": "Baréin", "BD": "Bangladés", "BT": "Bután", "BN": "Brunéi",
        "KH": "Camboya", "CN": "China", "IN": "India", "ID": "Indonesia", "IR": "Irán",
        "IQ": "Irak", "IL": "Israel", "JP": "Japón", "JO": "Jordania", "KZ": "Kazajistán",
        "KW": "Kuwait", "KG": "Kirguistán", "LA": "Laos", "LB": "Líbano", "MY": "Malasia",
        "MV": "Maldivas", "MN": "Mongolia", "MM": "Myanmar", "NP": "Nepal", "OM": "Omán",
        "PK": "Pakistán", "PH": "Filipinas", "QA": "Catar", "SA": "Arabia Saudita", "SG": "Singapur",
        "LK": "Sri Lanka", "SY": "Siria", "TW": "Taiwán", "TJ": "Tayikistán", "TH": "Tailandia",
        "TL": "Timor Oriental", "AE": "Emiratos Árabes Unidos", "UZ": "Uzbekistán", "VN": "Vietnam", "YE": "Yemen",
        "KP": "Corea del Norte", "PS": "Palestina", "TM": "Turkmenistán", "KR": "Corea del Sur",
        
        // Africa
        "DZ": "Argelia", "AO": "Angola", "BJ": "Benín", "BW": "Botsuana", "BF": "Burkina Faso",
        "BI": "Burundi", "CM": "Camerún", "CV": "Cabo Verde", "CF": "República Centroafricana",
        "TD": "Chad", "KM": "Comoras", "CG": "República del Congo", "CD": "República Democrática del Congo",
        "CI": "Costa de Marfil", "DJ": "Yibuti", "EG": "Egipto", "GQ": "Guinea Ecuatorial", "ER": "Eritrea",
        "ET": "Etiopía", "GA": "Gabón", "GM": "Gambia", "GH": "Ghana", "GN": "Guinea",
        "GW": "Guinea-Bisáu", "KE": "Kenia", "LS": "Lesoto", "LR": "Liberia", "LY": "Libia",
        "MG": "Madagascar", "MW": "Malaui", "ML": "Malí", "MR": "Mauritania", "MU": "Mauricio",
        "MA": "Marruecos", "MZ": "Mozambique", "NA": "Namibia", "NE": "Níger", "NG": "Nigeria",
        "RW": "Ruanda", "ST": "Santo Tomé y Príncipe", "SN": "Senegal", "SC": "Seychelles",
        "SL": "Sierra Leona", "SO": "Somalia", "ZA": "Sudáfrica", "SS": "Sudán del Sur",
        "SD": "Sudán", "SZ": "Esuatini", "TZ": "Tanzania", "TG": "Togo", "TN": "Túnez",
        "UG": "Uganda", "ZM": "Zambia", "ZW": "Zimbabue",
        
        // Americas
        "AR": "Argentina", "BO": "Bolivia", "BR": "Brasil", "CL": "Chile", "CO": "Colombia",
        "EC": "Ecuador", "GY": "Guyana", "PY": "Paraguay", "PE": "Perú", "SR": "Surinam",
        "UY": "Uruguay", "VE": "Venezuela", "CA": "Canadá", "MX": "México", "US": "Estados Unidos",
        "AG": "Antigua y Barbuda", "BS": "Bahamas", "BB": "Barbados", "BZ": "Belice",
        "CR": "Costa Rica", "CU": "Cuba", "DM": "Dominica", "DO": "República Dominicana",
        "SV": "El Salvador", "GD": "Granada", "GT": "Guatemala", "HT": "Haití", "HN": "Honduras",
        "JM": "Jamaica", "NI": "Nicaragua", "PA": "Panamá", "KN": "San Cristóbal y Nieves",
        "LC": "Santa Lucía", "VC": "San Vicente y las Granadinas", "TT": "Trinidad y Tobago",
        
        // Oceania
        "AU": "Australia", "FJ": "Fiyi", "KI": "Kiribati", "MH": "Islas Marshall",
        "FM": "Micronesia", "NR": "Nauru", "NZ": "Nueva Zelanda", "PW": "Palaos", "PG": "Papúa Nueva Guinea",
        "WS": "Samoa", "SB": "Islas Salomón", "TO": "Tonga", "TV": "Tuvalu", "VU": "Vanuatu"
    ]
    return names[code]
}

// MARK: - Ukrainian Names
private func getUkrainianCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "Австрія", "AL": "Албанія", "DE": "Німеччина", "FR": "Франція", "ES": "Іспанія",
        "IT": "Італія", "GB": "Велика Британія", "RU": "Росія", "UA": "Україна"
    ]
    return names[code]
}

// MARK: - Catalan Names
private func getCatalanCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "Àustria", "AL": "Albània", "DE": "Alemanya", "FR": "França", "ES": "Espanya",
        "IT": "Itàlia", "GB": "Regne Unit", "RU": "Rússia", "UA": "Ucraïna"
    ]
    return names[code]
}

// MARK: - Chinese Names
private func getChineseCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "奥地利", "AL": "阿尔巴尼亚", "DE": "德国", "FR": "法国", "ES": "西班牙",
        "IT": "意大利", "GB": "英国", "RU": "俄国", "UA": "乌克兰"
    ]
    return names[code]
}

struct AllCountriesView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var safeTopInset: CGFloat = 0
    @State private var selectedFilter: LearningCountryFilter = .all
    @State private var searchQuery: String = ""
    @State private var debouncedSearchQuery: String = ""
    @State private var searchDebounceWork: DispatchWorkItem?

    private var allCountries: [CountryInfo] {
        CountryLearningCatalog.allCountryInfos.sorted { $0.name < $1.name }
    }

    private var filteredByFilter: [CountryInfo] {
        LearningCountryProgressLogic.applyFilter(allCountries, filter: selectedFilter, gameState: gameState)
    }

    private var displayedCountries: [CountryInfo] {
        filteredByFilter.filter { LearningCountryProgressLogic.searchMatches(country: $0, query: debouncedSearchQuery) }
    }

    private var alphabetSections: [(String, [CountryInfo])] {
        let grouped = Dictionary(grouping: displayedCountries) { country in
            let localizedName = getLocalizedCountryName(country.code, country.name)
            return String(localizedName.prefix(1).uppercased())
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private var studiedCount: Int {
        LearningCountryProgressLogic.studiedCount(in: allCountries, gameState: gameState)
    }

    private var totalCount: Int { allCountries.count }

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
                // Фиксированно под шапкой: прогресс, поиск, фильтры на всю ширину (скроллится только список).
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
                                                AllCountriesCard(
                                                    country: country,
                                                    navigationCountryCodes: displayedCountries.map(\.code)
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
                            AllCountriesAlphabetIndex(
                                letters: alphabetSections.map { $0.0 },
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
        .navigationBarBackButtonHidden(false)
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
                .preference(key: AllCountriesSafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
        })
        .onPreferenceChange(AllCountriesSafeTopInsetKey.self) { value in
            safeTopInset = value
        }
        .onAppear {
            gameState.reloadCountryLearningProgressFromStorage()
        }
    }
    
    // MARK: - Header (как на странице Лиг: компактно, от верха, без прозрачности)
    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: headerHeight)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .ignoresSafeArea(.container, edges: .top)

            VStack(spacing: 10) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localizationManager.localizedString("Все страны"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(allCountries.count) \(localizationManager.localizedString("стран"))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.leading, 8)
                    Spacer()
                    Image(systemName: "globe")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 20)
                .padding(.top, max(safeTopInset, 44) + 8)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(height: headerHeight)
    }

    /// Смещение алфавита: только список в ScrollView (прогресс/поиск/фильтры вынесены в шапку).
    private var alphabetIndexTopOffset: CGFloat { 22 }

    private var headerHeight: CGFloat {
        let safe = max(safeTopInset, 44)
        return safe + 96
    }
}

// MARK: - AllCountriesCard
struct AllCountriesCard: View {
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
                AllCountriesFlagImageView(countryCode: country.code, flagEmoji: country.flag)
                    .frame(width: 80, height: 53) // Оптимальный размер флага
                
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
                
                // Стрелка для навигации
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
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

// MARK: - AllCountriesFlagImageView
struct AllCountriesFlagImageView: View {
    let countryCode: String
    let flagEmoji: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            
            // Пока используем эмодзи, но в рамке как официальный флаг
            Text(flagEmoji)
                .font(.system(size: 28))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - AllCountriesAlphabetIndex
struct AllCountriesAlphabetIndex: View {
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

// MARK: - Localization Helper Functions for Capitals
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

private func getSpanishCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Viena", "AL": "Tirana", "AD": "Andorra la Vieja", "AM": "Ereván", "AZ": "Bakú",
        "BY": "Minsk", "BE": "Bruselas", "BA": "Sarajevo", "BG": "Sofía", "HR": "Zagreb",
        "CY": "Nicosia", "CZ": "Praga", "DK": "Copenhague", "EE": "Tallin", "FI": "Helsinki",
        "FR": "París", "GE": "Tiflis", "DE": "Berlín", "GR": "Atenas", "HU": "Budapest",
        "IS": "Reikiavik", "IE": "Dublín", "IT": "Roma", "XK": "Pristina", "LV": "Riga",
        "LI": "Vaduz", "LT": "Vilna", "LU": "Luxemburgo", "MT": "La Valeta", "MD": "Chisináu",
        "MC": "Mónaco", "ME": "Podgorica", "NL": "Ámsterdam", "MK": "Skopie", "NO": "Oslo",
        "PL": "Varsovia", "PT": "Lisboa", "RO": "Bucarest", "RU": "Moscú", "SM": "San Marino",
        "RS": "Belgrado", "SK": "Bratislava", "SI": "Liubliana", "ES": "Madrid", "SE": "Estocolmo",
        "CH": "Berna", "TR": "Ankara", "UA": "Kiev", "GB": "Londres", "VA": "Ciudad del Vaticano"
    ]
    return capitals[code]
}

private func getUkrainianCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Відень", "AL": "Тирана", "AD": "Андорра-ла-Велья", "AM": "Єреван", "AZ": "Баку",
        "BY": "Мінськ", "BE": "Брюссель", "BA": "Сараєво", "BG": "Софія", "HR": "Загреб",
        "CY": "Нікосія", "CZ": "Прага", "DK": "Копенгаген", "EE": "Таллінн", "FI": "Гельсінкі",
        "FR": "Париж", "GE": "Тбілісі", "DE": "Берлін", "GR": "Афіни", "HU": "Будапешт",
        "IS": "Рейк'явік", "IE": "Дублін", "IT": "Рим", "XK": "Приштина", "LV": "Рига",
        "LI": "Вадуц", "LT": "Вільнюс", "LU": "Люксембург", "MT": "Валлетта", "MD": "Кишинів",
        "MC": "Монако", "ME": "Подгориця", "NL": "Амстердам", "MK": "Скоп'є", "NO": "Осло",
        "PL": "Варшава", "PT": "Лісабон", "RO": "Бухарест", "RU": "Москва", "SM": "Сан-Марино",
        "RS": "Белград", "SK": "Братислава", "SI": "Любляна", "ES": "Мадрид", "SE": "Стокгольм",
        "CH": "Берн", "TR": "Анкара", "UA": "Київ", "GB": "Лондон", "VA": "Ватикан"
    ]
    return capitals[code]
}

private func getCatalanCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Viena", "AL": "Tirana", "AD": "Andorra la Vella", "AM": "Erevan", "AZ": "Bakú",
        "BY": "Minsk", "BE": "Brussel·les", "BA": "Sarajevo", "BG": "Sofia", "HR": "Zagreb",
        "CY": "Nicòsia", "CZ": "Praga", "DK": "Copenhaguen", "EE": "Tallinn", "FI": "Hèlsinki",
        "FR": "París", "GE": "Tbilissi", "DE": "Berlín", "GR": "Atenes", "HU": "Budapest",
        "IS": "Reykjavík", "IE": "Dublín", "IT": "Roma", "XK": "Pristina", "LV": "Riga",
        "LI": "Vaduz", "LT": "Vílnius", "LU": "Luxemburg", "MT": "La Valeta", "MD": "Chișinău",
        "MC": "Mònaco", "ME": "Podgorica", "NL": "Amsterdam", "MK": "Skopje", "NO": "Oslo",
        "PL": "Varsòvia", "PT": "Lisboa", "RO": "Bucarest", "RU": "Moscou", "SM": "San Marino",
        "RS": "Belgrad", "SK": "Bratislava", "SI": "Ljubljana", "ES": "Madrid", "SE": "Estocolm",
        "CH": "Berna", "TR": "Ankara", "UA": "Kíev", "GB": "Londres", "VA": "Ciutat del Vaticà"
    ]
    return capitals[code]
}

private func getChineseCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "维也纳", "AL": "地拉那", "AD": "安道尔城", "AM": "埃里温", "AZ": "巴库",
        "BY": "明斯克", "BE": "布鲁塞尔", "BA": "萨拉热窝", "BG": "索非亚", "HR": "萨格勒布",
        "CY": "尼科西亚", "CZ": "布拉格", "DK": "哥本哈根", "EE": "塔林", "FI": "赫尔辛基",
        "FR": "巴黎", "GE": "第比利斯", "DE": "柏林", "GR": "雅典", "HU": "布达佩斯",
        "IS": "雷克雅未克", "IE": "都柏林", "IT": "罗马", "XK": "普里什蒂纳", "LV": "里加",
        "LI": "瓦杜兹", "LT": "维尔纽斯", "LU": "卢森堡", "MT": "瓦莱塔", "MD": "基希讷乌",
        "MC": "摩纳哥", "ME": "波德戈里察", "NL": "阿姆斯特丹", "MK": "斯科普里", "NO": "奥斯陆",
        "PL": "华沙", "PT": "里斯本", "RO": "布加勒斯特", "RU": "莫斯科", "SM": "圣马力诺",
        "RS": "贝尔格莱德", "SK": "布拉迪斯拉发", "SI": "卢布尔雅那", "ES": "马德里", "SE": "斯德哥尔摩",
        "CH": "伯尔尼", "TR": "安卡拉", "UA": "基辅", "GB": "伦敦", "VA": "梵蒂冈城"
    ]
    return capitals[code]
}

// MARK: - AllCountriesSafeTopInsetKey
private struct AllCountriesSafeTopInsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    AllCountriesView()
        .environmentObject(GameState())
}
