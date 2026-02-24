import SwiftUI

struct ContinentDetailView: View {
    let continentName: String
    let continentEmoji: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var safeTopInset: CGFloat = 0
    
    private var sortedCountries: [CountryInfo] {
        countriesForContinent(continentName).sorted { $0.name < $1.name }
    }
    
    private var alphabetSections: [(String, [CountryInfo])] {
        let grouped = Dictionary(grouping: sortedCountries) { country in
            let localizedName = getLocalizedCountryName(country.code, country.name)
            return String(localizedName.prefix(1).uppercased())
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: Color.appGradientColors(for: themeManager.colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Закреплённая шапка
                headerBackground
                
                // Основной контент с алфавитным указателем
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        ScrollView {
                            LazyVStack(spacing: 4, pinnedViews: [.sectionHeaders]) { // Уменьшили отступы между карточками
                                ForEach(alphabetSections, id: \.0) { letter, countries in
                                    Section(header: 
                                        HStack {
                                            Text(letter)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                            Spacer()
                                        }
                                        .background(Color(UIColor.systemGroupedBackground))
                                        .id(letter)
                                    ) {
                                        ForEach(countries, id: \.code) { country in
                                            CountryCard(country: country)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 0) // Убрали отступ сверху, чтобы белый блок сразу начинался после шапки
                            .padding(.bottom, 100)
                            .padding(.trailing, 40) // Добавляем отступ справа для алфавитного указателя
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.background)
                                .ignoresSafeArea(.container, edges: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .offset(y: -20) // Смещаем белый блок вверх, чтобы убрать серый отступ
                        
                        // Алфавитный указатель справа (поверх контента)
                        VStack {
                            Spacer()
                            AlphabetIndex(
                                letters: getLocalizedAlphabet(),
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
                }
            }
        }
        .navigationBarHidden(true)
        .background(GeometryReader { geometry in
            Color.clear
                .preference(key: SafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
        })
        .onPreferenceChange(SafeTopInsetKey.self) { value in
            safeTopInset = value
        }
    }
    
    // MARK: - Header (флаг и название в одну линию со стрелкой назад)
    private var headerBackground: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: headerHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .ignoresSafeArea(.container, edges: .top)
            
            // Верхняя строка: стрелка назад и флаг + название континента в одну линию
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Text(continentEmoji)
                        .font(.system(size: 28))
                    Text(localizationManager.localizedString(continentName))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, safeTopInset + 8)
                Text("\(countriesForContinent(continentName).count) \(localizationManager.localizedString("стран"))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
            .frame(height: headerHeight)
        }
    }
    
    /// Высота шапки: заливка захватывает и строку с «44 країн», чтобы описание не уходило под контент.
    /// Увеличена высота, чтобы заливка фона была ниже и захватывала больше пространства
    private var headerHeight: CGFloat { 150 + safeTopInset }
    
    private var contentTopInset: CGFloat {
        max(0, headerHeight - 20) // Убрали черный отступ
    }
    
    // MARK: - Countries Data
    private func countriesForContinent(_ continent: String) -> [CountryInfo] {
        switch continent {
        case "Европа":
            return europeCountries.sorted { $0.name < $1.name }
        case "Азия":
            return asiaCountries.sorted { $0.name < $1.name }
        case "Африка":
            return africaCountries.sorted { $0.name < $1.name }
        case "Северная Америка":
            return northAmericaCountries.sorted { $0.name < $1.name }
        case "Южная Америка":
            return southAmericaCountries.sorted { $0.name < $1.name }
        case "Океания":
            return oceaniaCountries.sorted { $0.name < $1.name }
        default:
            return []
        }
    }
}

// MARK: - CountryCard
struct CountryCard: View {
    let country: CountryInfo
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationLink(destination: CountryDetailView(countryCode: country.code, countryName: getLocalizedCountryName(country.code, country.name), flagEmoji: country.flag)) {
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            
            // Флаг масштабируется под размер контейнера
            GeometryReader { geometry in
                Text(flagEmoji)
                    .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.6))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .frame(width: 120, height: 80) // Размер подложки
    }
}

// MARK: - CountryInfo Model
struct CountryInfo {
    let name: String
    let flag: String
    let capital: String
    let code: String
}

// MARK: - Countries Data
private let europeCountries: [CountryInfo] = [
    CountryInfo(name: "Австрия", flag: "🇦🇹", capital: "Вена", code: "AT"),
    CountryInfo(name: "Албания", flag: "🇦🇱", capital: "Тирана", code: "AL"),
    CountryInfo(name: "Андорра", flag: "🇦🇩", capital: "Андорра-ла-Велья", code: "AD"),
    CountryInfo(name: "Беларусь", flag: "🇧🇾", capital: "Минск", code: "BY"),
    CountryInfo(name: "Бельгия", flag: "🇧🇪", capital: "Брюссель", code: "BE"),
    CountryInfo(name: "Болгария", flag: "🇧🇬", capital: "София", code: "BG"),
    CountryInfo(name: "Босния и Герцеговина", flag: "🇧🇦", capital: "Сараево", code: "BA"),
    CountryInfo(name: "Ватикан", flag: "🇻🇦", capital: "Ватикан", code: "VA"),
    CountryInfo(name: "Великобритания", flag: "🇬🇧", capital: "Лондон", code: "GB"),
    CountryInfo(name: "Венгрия", flag: "🇭🇺", capital: "Будапешт", code: "HU"),
    CountryInfo(name: "Германия", flag: "🇩🇪", capital: "Берлин", code: "DE"),
    CountryInfo(name: "Греция", flag: "🇬🇷", capital: "Афины", code: "GR"),
    CountryInfo(name: "Дания", flag: "🇩🇰", capital: "Копенгаген", code: "DK"),
    CountryInfo(name: "Ирландия", flag: "🇮🇪", capital: "Дублин", code: "IE"),
    CountryInfo(name: "Исландия", flag: "🇮🇸", capital: "Рейкьявик", code: "IS"),
    CountryInfo(name: "Испания", flag: "🇪🇸", capital: "Мадрид", code: "ES"),
    CountryInfo(name: "Италия", flag: "🇮🇹", capital: "Рим", code: "IT"),
    CountryInfo(name: "Кипр", flag: "🇨🇾", capital: "Никосия", code: "CY"),
    CountryInfo(name: "Латвия", flag: "🇱🇻", capital: "Рига", code: "LV"),
    CountryInfo(name: "Литва", flag: "🇱🇹", capital: "Вильнюс", code: "LT"),
    CountryInfo(name: "Люксембург", flag: "🇱🇺", capital: "Люксембург", code: "LU"),
    CountryInfo(name: "Мальта", flag: "🇲🇹", capital: "Валлетта", code: "MT"),
    CountryInfo(name: "Молдова", flag: "🇲🇩", capital: "Кишинёв", code: "MD"),
    CountryInfo(name: "Монако", flag: "🇲🇨", capital: "Монако", code: "MC"),
    CountryInfo(name: "Нидерланды", flag: "🇳🇱", capital: "Амстердам", code: "NL"),
    CountryInfo(name: "Норвегия", flag: "🇳🇴", capital: "Осло", code: "NO"),
    CountryInfo(name: "Польша", flag: "🇵🇱", capital: "Варшава", code: "PL"),
    CountryInfo(name: "Португалия", flag: "🇵🇹", capital: "Лиссабон", code: "PT"),
    CountryInfo(name: "Россия", flag: "🇷🇺", capital: "Москва", code: "RU"),
    CountryInfo(name: "Румыния", flag: "🇷🇴", capital: "Бухарест", code: "RO"),
    CountryInfo(name: "Сан-Марино", flag: "🇸🇲", capital: "Сан-Марино", code: "SM"),
    CountryInfo(name: "Северная Македония", flag: "🇲🇰", capital: "Скопье", code: "MK"),
    CountryInfo(name: "Сербия", flag: "🇷🇸", capital: "Белград", code: "RS"),
    CountryInfo(name: "Словакия", flag: "🇸🇰", capital: "Братислава", code: "SK"),
    CountryInfo(name: "Словения", flag: "🇸🇮", capital: "Любляна", code: "SI"),
    CountryInfo(name: "Украина", flag: "🇺🇦", capital: "Киев", code: "UA"),
    CountryInfo(name: "Финляндия", flag: "🇫🇮", capital: "Хельсинки", code: "FI"),
    CountryInfo(name: "Франция", flag: "🇫🇷", capital: "Париж", code: "FR"),
    CountryInfo(name: "Хорватия", flag: "🇭🇷", capital: "Загреб", code: "HR"),
    CountryInfo(name: "Черногория", flag: "🇲🇪", capital: "Подгорица", code: "ME"),
    CountryInfo(name: "Чехия", flag: "🇨🇿", capital: "Прага", code: "CZ"),
    CountryInfo(name: "Швейцария", flag: "🇨🇭", capital: "Берн", code: "CH"),
    CountryInfo(name: "Швеция", flag: "🇸🇪", capital: "Стокгольм", code: "SE"),
    CountryInfo(name: "Эстония", flag: "🇪🇪", capital: "Таллин", code: "EE")
]

private let asiaCountries: [CountryInfo] = [
    CountryInfo(name: "Афганистан", flag: "🇦🇫", capital: "Кабул", code: "AF"),
    CountryInfo(name: "Бангладеш", flag: "🇧🇩", capital: "Дакка", code: "BD"),
    CountryInfo(name: "Бахрейн", flag: "🇧🇭", capital: "Манама", code: "BH"),
    CountryInfo(name: "Бруней", flag: "🇧🇳", capital: "Бандар-Сери-Бегаван", code: "BN"),
    CountryInfo(name: "Бутан", flag: "🇧🇹", capital: "Тхимпху", code: "BT"),
    CountryInfo(name: "Восточный Тимор", flag: "🇹🇱", capital: "Дили", code: "TL"),
    CountryInfo(name: "Вьетнам", flag: "🇻🇳", capital: "Ханой", code: "VN"),
    CountryInfo(name: "Грузия", flag: "🇬🇪", capital: "Тбилиси", code: "GE"),
    CountryInfo(name: "Израиль", flag: "🇮🇱", capital: "Иерусалим", code: "IL"),
    CountryInfo(name: "Индия", flag: "🇮🇳", capital: "Нью-Дели", code: "IN"),
    CountryInfo(name: "Индонезия", flag: "🇮🇩", capital: "Джакарта", code: "ID"),
    CountryInfo(name: "Иордания", flag: "🇯🇴", capital: "Амман", code: "JO"),
    CountryInfo(name: "Ирак", flag: "🇮🇶", capital: "Багдад", code: "IQ"),
    CountryInfo(name: "Иран", flag: "🇮🇷", capital: "Тегеран", code: "IR"),
    CountryInfo(name: "Йемен", flag: "🇾🇪", capital: "Сана", code: "YE"),
    CountryInfo(name: "Казахстан", flag: "🇰🇿", capital: "Астана", code: "KZ"),
    CountryInfo(name: "Камбоджа", flag: "🇰🇭", capital: "Пномпень", code: "KH"),
    CountryInfo(name: "Катар", flag: "🇶🇦", capital: "Доха", code: "QA"),
    CountryInfo(name: "Кипр", flag: "🇨🇾", capital: "Никосия", code: "CY"),
    CountryInfo(name: "Киргизия", flag: "🇰🇬", capital: "Бишкек", code: "KG"),
    CountryInfo(name: "Китай", flag: "🇨🇳", capital: "Пекин", code: "CN"),
    CountryInfo(name: "КНДР", flag: "🇰🇵", capital: "Пхеньян", code: "KP"),
    CountryInfo(name: "Кувейт", flag: "🇰🇼", capital: "Эль-Кувейт", code: "KW"),
    CountryInfo(name: "Лаос", flag: "🇱🇦", capital: "Вьентьян", code: "LA"),
    CountryInfo(name: "Ливан", flag: "🇱🇧", capital: "Бейрут", code: "LB"),
    CountryInfo(name: "Малайзия", flag: "🇲🇾", capital: "Куала-Лумпур", code: "MY"),
    CountryInfo(name: "Мальдивы", flag: "🇲🇻", capital: "Мале", code: "MV"),
    CountryInfo(name: "Монголия", flag: "🇲🇳", capital: "Улан-Батор", code: "MN"),
    CountryInfo(name: "Мьянма", flag: "🇲🇲", capital: "Нейпьидо", code: "MM"),
    CountryInfo(name: "Непал", flag: "🇳🇵", capital: "Катманду", code: "NP"),
    CountryInfo(name: "ОАЭ", flag: "🇦🇪", capital: "Абу-Даби", code: "AE"),
    CountryInfo(name: "Оман", flag: "🇴🇲", capital: "Маскат", code: "OM"),
    CountryInfo(name: "Пакистан", flag: "🇵🇰", capital: "Исламабад", code: "PK"),
    CountryInfo(name: "Палестина", flag: "🇵🇸", capital: "Рамалла", code: "PS"),
    CountryInfo(name: "Саудовская Аравия", flag: "🇸🇦", capital: "Эр-Рияд", code: "SA"),
    CountryInfo(name: "Сингапур", flag: "🇸🇬", capital: "Сингапур", code: "SG"),
    CountryInfo(name: "Сирия", flag: "🇸🇾", capital: "Дамаск", code: "SY"),
    CountryInfo(name: "Таджикистан", flag: "🇹🇯", capital: "Душанбе", code: "TJ"),
    CountryInfo(name: "Таиланд", flag: "🇹🇭", capital: "Бангкок", code: "TH"),
    CountryInfo(name: "Туркмения", flag: "🇹🇲", capital: "Ашхабад", code: "TM"),
    CountryInfo(name: "Турция", flag: "🇹🇷", capital: "Анкара", code: "TR"),
    CountryInfo(name: "Узбекистан", flag: "🇺🇿", capital: "Ташкент", code: "UZ"),
    CountryInfo(name: "Филиппины", flag: "🇵🇭", capital: "Манила", code: "PH"),
    CountryInfo(name: "Шри-Ланка", flag: "🇱🇰", capital: "Коломбо", code: "LK"),
    CountryInfo(name: "Южная Корея", flag: "🇰🇷", capital: "Сеул", code: "KR"),
    CountryInfo(name: "Япония", flag: "🇯🇵", capital: "Токио", code: "JP")
]

private let africaCountries: [CountryInfo] = [
    CountryInfo(name: "Алжир", flag: "🇩🇿", capital: "Алжир", code: "DZ"),
    CountryInfo(name: "Ангола", flag: "🇦🇴", capital: "Луанда", code: "AO"),
    CountryInfo(name: "Бенин", flag: "🇧🇯", capital: "Порто-Ново", code: "BJ"),
    CountryInfo(name: "Ботсвана", flag: "🇧🇼", capital: "Габороне", code: "BW"),
    CountryInfo(name: "Буркина-Фасо", flag: "🇧🇫", capital: "Уагадугу", code: "BF"),
    CountryInfo(name: "Бурунди", flag: "🇧🇮", capital: "Бужумбура", code: "BI"),
    CountryInfo(name: "Габон", flag: "🇬🇦", capital: "Либревиль", code: "GA"),
    CountryInfo(name: "Гамбия", flag: "🇬🇲", capital: "Банжул", code: "GM"),
    CountryInfo(name: "Гана", flag: "🇬🇭", capital: "Аккра", code: "GH"),
    CountryInfo(name: "Гвинея", flag: "🇬🇳", capital: "Конакри", code: "GN"),
    CountryInfo(name: "Гвинея-Бисау", flag: "🇬🇼", capital: "Бисау", code: "GW"),
    CountryInfo(name: "Джибути", flag: "🇩🇯", capital: "Джибути", code: "DJ"),
    CountryInfo(name: "Египет", flag: "🇪🇬", capital: "Каир", code: "EG"),
    CountryInfo(name: "Замбия", flag: "🇿🇲", capital: "Лусака", code: "ZM"),
    CountryInfo(name: "Зимбабве", flag: "🇿🇼", capital: "Хараре", code: "ZW"),
    CountryInfo(name: "Кабо-Верде", flag: "🇨🇻", capital: "Прая", code: "CV"),
    CountryInfo(name: "Камерун", flag: "🇨🇲", capital: "Яунде", code: "CM"),
    CountryInfo(name: "Кения", flag: "🇰🇪", capital: "Найроби", code: "KE"),
    CountryInfo(name: "Коморы", flag: "🇰🇲", capital: "Морони", code: "KM"),
    CountryInfo(name: "ДР Конго", flag: "🇨🇩", capital: "Киншаса", code: "CD"),
    CountryInfo(name: "Республика Конго", flag: "🇨🇬", capital: "Браззавиль", code: "CG"),
    CountryInfo(name: "Кот-д'Ивуар", flag: "🇨🇮", capital: "Ямусукро", code: "CI"),
    CountryInfo(name: "Лесото", flag: "🇱🇸", capital: "Масеру", code: "LS"),
    CountryInfo(name: "Либерия", flag: "🇱🇷", capital: "Монровия", code: "LR"),
    CountryInfo(name: "Ливия", flag: "🇱🇾", capital: "Триполи", code: "LY"),
    CountryInfo(name: "Маврикий", flag: "🇲🇺", capital: "Порт-Луи", code: "MU"),
    CountryInfo(name: "Мавритания", flag: "🇲🇷", capital: "Нуакшот", code: "MR"),
    CountryInfo(name: "Мадагаскар", flag: "🇲🇬", capital: "Антананариву", code: "MG"),
    CountryInfo(name: "Малави", flag: "🇲🇼", capital: "Лилонгве", code: "MW"),
    CountryInfo(name: "Мали", flag: "🇲🇱", capital: "Бамако", code: "ML"),
    CountryInfo(name: "Марокко", flag: "🇲🇦", capital: "Рабат", code: "MA"),
    CountryInfo(name: "Мозамбик", flag: "🇲🇿", capital: "Мапуту", code: "MZ"),
    CountryInfo(name: "Намибия", flag: "🇳🇦", capital: "Виндхук", code: "NA"),
    CountryInfo(name: "Нигер", flag: "🇳🇪", capital: "Ниамей", code: "NE"),
    CountryInfo(name: "Нигерия", flag: "🇳🇬", capital: "Абуджа", code: "NG"),
    CountryInfo(name: "Руанда", flag: "🇷🇼", capital: "Кигали", code: "RW"),
    CountryInfo(name: "Сан-Томе и Принсипи", flag: "🇸🇹", capital: "Сан-Томе", code: "ST"),
    CountryInfo(name: "Свазиленд", flag: "🇸🇿", capital: "Мбабане", code: "SZ"),
    CountryInfo(name: "Сейшелы", flag: "🇸🇨", capital: "Виктория", code: "SC"),
    CountryInfo(name: "Сенегал", flag: "🇸🇳", capital: "Дакар", code: "SN"),
    CountryInfo(name: "Сомали", flag: "🇸🇴", capital: "Могадишо", code: "SO"),
    CountryInfo(name: "Судан", flag: "🇸🇩", capital: "Хартум", code: "SD"),
    CountryInfo(name: "Сьерра-Леоне", flag: "🇸🇱", capital: "Фритаун", code: "SL"),
    CountryInfo(name: "Танзания", flag: "🇹🇿", capital: "Додома", code: "TZ"),
    CountryInfo(name: "Того", flag: "🇹🇬", capital: "Ломе", code: "TG"),
    CountryInfo(name: "Тунис", flag: "🇹🇳", capital: "Тунис", code: "TN"),
    CountryInfo(name: "Уганда", flag: "🇺🇬", capital: "Кампала", code: "UG"),
    CountryInfo(name: "ЦАР", flag: "🇨🇫", capital: "Банги", code: "CF"),
    CountryInfo(name: "Чад", flag: "🇹🇩", capital: "Нджамена", code: "TD"),
    CountryInfo(name: "Экваториальная Гвинея", flag: "🇬🇶", capital: "Малабо", code: "GQ"),
    CountryInfo(name: "Эритрея", flag: "🇪🇷", capital: "Асмэра", code: "ER"),
    CountryInfo(name: "Эфиопия", flag: "🇪🇹", capital: "Аддис-Абеба", code: "ET"),
    CountryInfo(name: "ЮАР", flag: "🇿🇦", capital: "Кейптаун", code: "ZA"),
    CountryInfo(name: "Южный Судан", flag: "🇸🇸", capital: "Джуба", code: "SS")
]

private let northAmericaCountries: [CountryInfo] = [
    CountryInfo(name: "Антигуа и Барбуда", flag: "🇦🇬", capital: "Сент-Джонс", code: "AG"),
    CountryInfo(name: "Багамы", flag: "🇧🇸", capital: "Нассау", code: "BS"),
    CountryInfo(name: "Барбадос", flag: "🇧🇧", capital: "Бриджтаун", code: "BB"),
    CountryInfo(name: "Белиз", flag: "🇧🇿", capital: "Бельмопан", code: "BZ"),
    CountryInfo(name: "Гаити", flag: "🇭🇹", capital: "Порт-о-Пренс", code: "HT"),
    CountryInfo(name: "Гватемала", flag: "🇬🇹", capital: "Гватемала", code: "GT"),
    CountryInfo(name: "Гондурас", flag: "🇭🇳", capital: "Тегусигальпа", code: "HN"),
    CountryInfo(name: "Гренада", flag: "🇬🇩", capital: "Сент-Джорджес", code: "GD"),
    CountryInfo(name: "Доминика", flag: "🇩🇲", capital: "Розо", code: "DM"),
    CountryInfo(name: "Доминиканская Республика", flag: "🇩🇴", capital: "Санто-Доминго", code: "DO"),
    CountryInfo(name: "Канада", flag: "🇨🇦", capital: "Оттава", code: "CA"),
    CountryInfo(name: "Коста-Рика", flag: "🇨🇷", capital: "Сан-Хосе", code: "CR"),
    CountryInfo(name: "Куба", flag: "🇨🇺", capital: "Гавана", code: "CU"),
    CountryInfo(name: "Мексика", flag: "🇲🇽", capital: "Мехико", code: "MX"),
    CountryInfo(name: "Никарагуа", flag: "🇳🇮", capital: "Манагуа", code: "NI"),
    CountryInfo(name: "Панама", flag: "🇵🇦", capital: "Панама", code: "PA"),
    CountryInfo(name: "Сальвадор", flag: "🇸🇻", capital: "Сан-Сальвадор", code: "SV"),
    CountryInfo(name: "Сент-Винсент и Гренадины", flag: "🇻🇨", capital: "Кингстаун", code: "VC"),
    CountryInfo(name: "Сент-Китс и Невис", flag: "🇰🇳", capital: "Бастер", code: "KN"),
    CountryInfo(name: "Сент-Люсия", flag: "🇱🇨", capital: "Кастри", code: "LC"),
    CountryInfo(name: "США", flag: "🇺🇸", capital: "Вашингтон", code: "US"),
    CountryInfo(name: "Тринидад и Тобаго", flag: "🇹🇹", capital: "Порт-оф-Спейн", code: "TT"),
    CountryInfo(name: "Ямайка", flag: "🇯🇲", capital: "Кингстон", code: "JM")
]

private let southAmericaCountries: [CountryInfo] = [
    CountryInfo(name: "Аргентина", flag: "🇦🇷", capital: "Буэнос-Айрес", code: "AR"),
    CountryInfo(name: "Боливия", flag: "🇧🇴", capital: "Сукре", code: "BO"),
    CountryInfo(name: "Бразилия", flag: "🇧🇷", capital: "Бразилиа", code: "BR"),
    CountryInfo(name: "Венесуэла", flag: "🇻🇪", capital: "Каракас", code: "VE"),
    CountryInfo(name: "Гайана", flag: "🇬🇾", capital: "Джорджтаун", code: "GY"),
    CountryInfo(name: "Колумбия", flag: "🇨🇴", capital: "Богота", code: "CO"),
    CountryInfo(name: "Парагвай", flag: "🇵🇾", capital: "Асунсьон", code: "PY"),
    CountryInfo(name: "Перу", flag: "🇵🇪", capital: "Лима", code: "PE"),
    CountryInfo(name: "Суринам", flag: "🇸🇷", capital: "Парамарибо", code: "SR"),
    CountryInfo(name: "Уругвай", flag: "🇺🇾", capital: "Монтевидео", code: "UY"),
    CountryInfo(name: "Чили", flag: "🇨🇱", capital: "Сантьяго", code: "CL"),
    CountryInfo(name: "Эквадор", flag: "🇪🇨", capital: "Кито", code: "EC")
]

private let oceaniaCountries: [CountryInfo] = [
    CountryInfo(name: "Австралия", flag: "🇦🇺", capital: "Канберра", code: "AU"),
    CountryInfo(name: "Вануату", flag: "🇻🇺", capital: "Порт-Вила", code: "VU"),
    CountryInfo(name: "Кирибати", flag: "🇰🇮", capital: "Тарава", code: "KI"),
    CountryInfo(name: "Маршалловы острова", flag: "🇲🇭", capital: "Маджуро", code: "MH"),
    CountryInfo(name: "Микронезия", flag: "🇫🇲", capital: "Паликир", code: "FM"),
    CountryInfo(name: "Науру", flag: "🇳🇷", capital: "Ярен", code: "NR"),
    CountryInfo(name: "Новая Зеландия", flag: "🇳🇿", capital: "Веллингтон", code: "NZ"),
    CountryInfo(name: "Палау", flag: "🇵🇼", capital: "Нгерулмуд", code: "PW"),
    CountryInfo(name: "Папуа — Новая Гвинея", flag: "🇵🇬", capital: "Порт-Морсби", code: "PG"),
    CountryInfo(name: "Самоа", flag: "🇼🇸", capital: "Апиа", code: "WS"),
    CountryInfo(name: "Соломоновы острова", flag: "🇸🇧", capital: "Хониара", code: "SB"),
    CountryInfo(name: "Тонга", flag: "🇹🇴", capital: "Нукуалофа", code: "TO"),
    CountryInfo(name: "Тувалу", flag: "🇹🇻", capital: "Фунафути", code: "TV"),
    CountryInfo(name: "Фиджи", flag: "🇫🇯", capital: "Сува", code: "FJ")
]

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
                        .frame(width: 24, height: 18)
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

// MARK: - Localization Functions
@MainActor
private func getLocalizedCountryName(_ countryCode: String, _ fallbackName: String) -> String {
    let localizationManager = LocalizationManager.shared
    let currentLanguage = localizationManager.currentLocale.languageCode ?? "ru"
    
    // Возвращаем локализованное название в зависимости от языка
    switch currentLanguage {
    case "en":
        return getEnglishCountryName(countryCode) ?? fallbackName
    case "es":
        return getSpanishCountryName(countryCode) ?? fallbackName
    case "uk":
        return getUkrainianCountryName(countryCode) ?? fallbackName
    case "ca":
        return getCatalanCountryName(countryCode) ?? fallbackName
    case "zh":
        return getChineseCountryName(countryCode) ?? fallbackName
    default: // "ru"
        return fallbackName
    }
}

@MainActor
private func getLocalizedCapitalName(_ countryCode: String, _ fallbackCapital: String) -> String {
    let localizationManager = LocalizationManager.shared
    let currentLanguage = localizationManager.currentLocale.languageCode ?? "ru"
    
    // Возвращаем локализованное название столицы в зависимости от языка
    switch currentLanguage {
    case "en":
        return getEnglishCapitalName(countryCode) ?? fallbackCapital
    case "es":
        return getSpanishCapitalName(countryCode) ?? fallbackCapital
    case "uk":
        return getUkrainianCapitalName(countryCode) ?? fallbackCapital
    case "ca":
        return getCatalanCapitalName(countryCode) ?? fallbackCapital
    case "zh":
        return getChineseCapitalName(countryCode) ?? fallbackCapital
    default: // "ru"
        return fallbackCapital
    }
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

private func getEnglishCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Vienna", "AL": "Tirana", "AD": "Andorra la Vella", "AM": "Yerevan", "AZ": "Baku",
        "BY": "Minsk", "BE": "Brussels", "BA": "Sarajevo", "BG": "Sofia", "HR": "Zagreb",
        "CY": "Nicosia", "CZ": "Prague", "DK": "Copenhagen", "EE": "Tallinn", "FI": "Helsinki",
        "FR": "Paris", "GE": "Tbilisi", "DE": "Berlin", "GR": "Athens", "HU": "Budapest",
        "IS": "Reykjavik", "IE": "Dublin", "IT": "Rome", "XK": "Pristina", "LV": "Riga",
        "LI": "Vaduz", "LT": "Vilnius", "LU": "Luxembourg", "MT": "Valletta", "MD": "Chisinau",
        "MC": "Monaco", "ME": "Podgorica", "NL": "Amsterdam", "MK": "Skopje", "NO": "Oslo",
        "PL": "Warsaw", "PT": "Lisbon", "RO": "Bucharest", "RU": "Moscow", "SM": "San Marino",
        "RS": "Belgrade", "SK": "Bratislava", "SI": "Ljubljana", "ES": "Madrid", "SE": "Stockholm",
        "CH": "Bern", "TR": "Ankara", "UA": "Kyiv", "GB": "London", "VA": "Vatican City"
    ]
    return capitals[code]
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

private func getSpanishCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Viena", "AL": "Tirana", "DE": "Berlín", "FR": "París", "ES": "Madrid",
        "IT": "Roma", "GB": "Londres", "RU": "Moscú", "UA": "Kiev"
    ]
    return capitals[code]
}

// MARK: - Ukrainian Names (примеры)
private func getUkrainianCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "Австрія", "AL": "Албанія", "DE": "Німеччина", "FR": "Франція", "ES": "Іспанія",
        "IT": "Італія", "GB": "Велика Британія", "RU": "Росія", "UA": "Україна"
    ]
    return names[code]
}

private func getUkrainianCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Відень", "AL": "Тирана", "DE": "Берлін", "FR": "Париж", "ES": "Мадрид",
        "IT": "Рим", "GB": "Лондон", "RU": "Москва", "UA": "Київ"
    ]
    return capitals[code]
}

// MARK: - Catalan Names (примеры)
private func getCatalanCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "Àustria", "AL": "Albània", "DE": "Alemanya", "FR": "França", "ES": "Espanya",
        "IT": "Itàlia", "GB": "Regne Unit", "RU": "Rússia", "UA": "Ucraïna"
    ]
    return names[code]
}

private func getCatalanCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "Viena", "AL": "Tirana", "DE": "Berlín", "FR": "París", "ES": "Madrid",
        "IT": "Roma", "GB": "Londres", "RU": "Moscou", "UA": "Kíiv"
    ]
    return capitals[code]
}

// MARK: - Chinese Names (примеры)
private func getChineseCountryName(_ code: String) -> String? {
    let names: [String: String] = [
        "AT": "奥地利", "AL": "阿尔巴尼亚", "DE": "德国", "FR": "法国", "ES": "西班牙",
        "IT": "意大利", "GB": "英国", "RU": "俄国", "UA": "乌克兰"
    ]
    return names[code]
}

private func getChineseCapitalName(_ code: String) -> String? {
    let capitals: [String: String] = [
        "AT": "维也纳", "AL": "地拉那", "DE": "柏林", "FR": "巴黎", "ES": "马德里",
        "IT": "罗马", "GB": "伦敦", "RU": "莫斯科", "UA": "基辅"
    ]
    return capitals[code]
}

// MARK: - Localized Alphabet Functions
@MainActor
private func getLocalizedAlphabet() -> [String] {
    let localizationManager = LocalizationManager.shared
    let currentLanguage = localizationManager.currentLocale.languageCode ?? "ru"
    
    switch currentLanguage {
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
}
