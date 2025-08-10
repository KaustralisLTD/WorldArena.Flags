import SwiftUI

struct FlagCardView: View {
    let country: Country
    @Binding var isShowingInfo: Bool
    var flagScale: CGFloat
    var flagRotation: Double
    @ObservedObject var gameState: GameState
    var onNextQuestion: () -> Void
    
    @State private var showTapHint = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var cardSize: CGSize {
        if horizontalSizeClass == .regular {
            // iPad - увеличиваем в 2 раза
            return CGSize(width: 600, height: 400)
        } else {
            // iPhone - оставляем как есть
            return CGSize(width: 300, height: 200)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Передняя сторона (флаг)
                CachedAsyncImage(url: country.flagURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(LocalizationManager.shared.localizedString("Loading flag..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                }
                .frame(width: cardSize.width, height: cardSize.height)
                .opacity(isShowingInfo ? 0 : 1)
                
                // Задняя сторона (информация)
                VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 12 : 3) {
                    // Название страны
                    Text(getLocalizedName())
                        .font(.system(size: horizontalSizeClass == .regular ? 34 : 20, weight: .bold, design: .default))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .padding(.bottom, horizontalSizeClass == .regular ? 4 : 1)
                    
                    // Остальная информация
                    Group {
                        // Столица
                        if let capitals = country.capital, !capitals.isEmpty {
                            let capitalText = getLocalizedText("Capital")
                            let localizedCapitals = capitals.map { getLocalizedCapital($0) }
                            Text("\(capitalText): \(localizedCapitals.joined(separator: ", "))")
                                .font(horizontalSizeClass == .regular ? .title2 : .callout)
                        }
                        
                        // Население
                        let populationText = getLocalizedText("Population")
                        Text("\(populationText): \(formatPopulation(country.population))")
                            .font(horizontalSizeClass == .regular ? .title2 : .callout)
                        
                        // Площадь
                        if let area = country.area {
                            let areaText = getLocalizedText("Area")
                            Text("\(areaText): \(formatArea(area))")
                                .font(horizontalSizeClass == .regular ? .title2 : .callout)
                        }
                        
                        // Регион
                        let regionText = getLocalizedText("Region")
                        Text("\(regionText): \(getLocalizedRegion())")
                            .font(horizontalSizeClass == .regular ? .title2 : .callout)
                        
                        // Субрегион (последний элемент)
                        if let subregion = country.subregion {
                            let subregionText = getLocalizedText("Subregion")
                            Text("\(subregionText): \(getLocalizedSubregion(subregion))")
                                .font(horizontalSizeClass == .regular ? .title2 : .callout)
                        }
                        
                        // Подсказка сразу после субрегиона
                        if isShowingInfo {
                            HStack {
                                Spacer()
                                Text(LocalizationManager.shared.localizedString("Tap to continue"))
                                    .font(horizontalSizeClass == .regular ? .title3 : .caption)
                                    .foregroundColor(.secondary)
                                    .opacity(showTapHint ? 0.8 : 0.4)
                                    .animation(.easeInOut(duration: 1).repeatForever(), value: showTapHint)
                            }
                            .padding(.top, horizontalSizeClass == .regular ? 8 : 2)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                .padding(.vertical, horizontalSizeClass == .regular ? 24 : 12)
                .frame(width: cardSize.width, height: cardSize.height)
                .background(.background)
                .opacity(isShowingInfo ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: cardSize.width, height: cardSize.height, alignment: .center)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .cornerRadius(10)
        .shadow(radius: 5)
        .scaleEffect(flagScale)
        .rotation3DEffect(
            .degrees(isShowingInfo ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isShowingInfo)
        .onAppear {
            if isShowingInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTapHint = true
                }
            }
        }
        .onDisappear {
            showTapHint = false
        }
    }
    
    private func getLocalizedName() -> String {
        return LocalizationManager.shared.localizedCountryName(country)
    }
    
    // Вспомогательная функция для адаптации русского перевода в украинский
    private func adaptRussianToUkrainian(_ text: String) -> String {
        var ukr = text
        // Базовые правила транслитерации с русского на украинский
        ukr = ukr.replacingOccurrences(of: "ы", with: "и")
        ukr = ukr.replacingOccurrences(of: "э", with: "е")
        ukr = ukr.replacingOccurrences(of: "ъ", with: "'")
        ukr = ukr.replacingOccurrences(of: "ё", with: "йо")
        // Добавьте другие правила по необходимости
        return ukr
    }
    
    private func getLocalizedText(_ key: String) -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        if currentLanguage == "system" {
            return LocalizationManager.shared.localizedString(key)
        }
        
        switch currentLanguage {
        case "ru":
            switch key {
            case "Capital": return "Столица"
            case "Population": return "Население"
            case "Area": return "Площадь"
            case "Region": return "Регион"
            case "Subregion": return "Субрегион"
            default: return key
            }
        case "uk":
            switch key {
            case "Capital": return "Столиця"
            case "Population": return "Населення"
            case "Area": return "Площа"
            case "Region": return "Регіон"
            case "Subregion": return "Субрегіон"
            default: return key
            }
        case "es":
            switch key {
            case "Capital": return "Capital"
            case "Population": return "Población"
            case "Area": return "Área"
            case "Region": return "Región"
            case "Subregion": return "Subregión"
            default: return key
            }
        case "ca":
            switch key {
            case "Capital": return "Capital"
            case "Population": return "Població"
            case "Area": return "Àrea"
            case "Region": return "Regió"
            case "Subregion": return "Subregió"
            default: return key
            }
        case "zh":
            switch key {
            case "Capital": return "首都"
            case "Population": return "人口"
            case "Area": return "面积"
            case "Region": return "地区"
            case "Subregion": return "子区域"
            default: return key
            }
        default:
            return LocalizationManager.shared.localizedString(key)
        }
    }
    
    private func getLocalizedRegion() -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        if currentLanguage == "system" {
            return LocalizationManager.shared.localizedString(country.region)
        }
        
        switch currentLanguage {
        case "ru":
            switch country.region {
            case "Europe": return "Европа"
            case "Asia": return "Азия"
            case "Africa": return "Африка"
            case "Americas": return "Америка"
            case "Oceania": return "Океания"
            default: return country.region
            }
        case "uk":
            switch country.region {
            case "Europe": return "Європа"
            case "Asia": return "Азія"
            case "Africa": return "Африка"
            case "Americas": return "Америка"
            case "Oceania": return "Океанія"
            default: return country.region
            }
        case "es":
            switch country.region {
            case "Europe": return "Europa"
            case "Asia": return "Asia"
            case "Africa": return "África"
            case "Americas": return "América"
            case "Oceania": return "Oceanía"
            default: return country.region
            }
        case "ca":
            switch country.region {
            case "Europe": return "Europa"
            case "Asia": return "Àsia"
            case "Africa": return "Àfrica"
            case "Americas": return "Amèrica"
            case "Oceania": return "Oceania"
            default: return country.region
            }
        case "zh":
            switch country.region {
            case "Europe": return "欧洲"
            case "Asia": return "亚洲"
            case "Africa": return "非洲"
            case "Americas": return "美洲"
            case "Oceania": return "大洋洲"
            default: return country.region
            }
        default:
            return country.region
        }
    }
    
    private func getLocalizedCapital(_ capital: String) -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        if currentLanguage == "system" { return capital }
        
        switch currentLanguage {
        case "ru":
            switch capital {
            // Европа
            case "Tirana": return "Тирана"
            case "Andorra la Vella": return "Андорра-ла-Велья"
            case "Vienna": return "Вена"
            case "Minsk": return "Минск"
            case "Brussels": return "Брюссель"
            case "Sarajevo": return "Сараево"
            case "Sofia": return "София"
            case "Zagreb": return "Загреб"
            case "Prague": return "Прага"
            case "Copenhagen": return "Копенгаген"
            case "Tallinn": return "Таллин"
            case "Helsinki": return "Хельсинки"
            case "Paris": return "Париж"
            case "Berlin": return "Берлин"
            case "Athens": return "Афины"
            case "Budapest": return "Будапешт"
            case "Reykjavik": return "Рейкьявик"
            case "Dublin": return "Дублин"
            case "Rome": return "Рим"
            case "Riga": return "Рига"
            case "Vaduz": return "Вадуц"
            case "Vilnius": return "Вильнюс"
            case "Luxembourg": return "Люксембург"
            case "Valletta": return "Валлетта"
            case "Chisinau": return "Кишинёв"
            case "Monaco": return "Монако"
            case "Podgorica": return "Подгорица"
            case "Amsterdam": return "Амстердам"
            case "Skopje": return "Скопье"
            case "Oslo": return "Осло"
            case "Warsaw": return "Варшава"
            case "Lisbon": return "Лиссабон"
            case "Bucharest": return "Бухарест"
            case "Moscow": return "Москва"
            case "San Marino": return "Сан-Марино"
            case "Belgrade": return "Белград"
            case "Bratislava": return "Братислава"
            case "Ljubljana": return "Любляна"
            case "Madrid": return "Мадрид"
            case "Stockholm": return "Стокгольм"
            case "Bern": return "Берн"
            case "Kyiv": return "Киев"
            case "London": return "Лондон"
            case "Vatican City": return "Ватикан"

            // Азия
            case "Abu Dhabi": return "Абу-Даби"
            case "Amman": return "Амман"
            case "Ankara": return "Анкара"
            case "Ashgabat": return "Ашгабат"
            case "Baghdad": return "Багдад"
            case "Baku": return "Баку"
            case "Bangkok": return "Бангкок"
            case "Beijing": return "Пекин"
            case "Beirut": return "Бейрут"
            case "Bishkek": return "Бишкек"
            case "Bandar Seri Begawan": return "Бандар-Сери-Бегаван"
            case "Damascus": return "Дамаск"
            case "Dhaka": return "Дакка"
            case "Dili": return "Дили"
            case "Doha": return "Доха"
            case "Dushanbe": return "Душанбе"
            case "Hanoi": return "Ханой"
            case "Islamabad": return "Исламабад"
            case "Jakarta": return "Джакарта"
            case "Jerusalem": return "Иерусалим"
            case "Kabul": return "Кабул"
            case "Kathmandu": return "Катманду"
            case "Kuala Lumpur": return "Куала-Лумпур"
            case "Kuwait City": return "Эль-Кувейт"
            case "Manila": return "Манила"
            case "Male": return "Мале"
            case "Manama": return "Манама"
            case "Muscat": return "Маскат"
            case "Naypyidaw": return "Найп'їдо"
            case "New Delhi": return "Нью-Дели"
            case "Nicosia": return "Нікосія"
            case "Nur-Sultan": return "Нур-Султан"
            case "Phnom Penh": return "Пномпень"
            case "Pyongyang": return "Пхеньян"
            case "Riyadh": return "Эр-Рияд"
            case "Sana'a": return "Сана"
            case "Seoul": return "Сеул"
            case "Singapore": return "Сингапур"
            case "Sri Jayawardenepura Kotte": return "Шрі-Джаяварденепура-Котте"
            case "Taipei": return "Тайбей"
            case "Tashkent": return "Ташкент"
            case "Tbilisi": return "Тбилиси"
            case "Tehran": return "Тегеран"
            case "Thimphu": return "Тхімпху"
            case "Tokyo": return "Токіо"
            case "Ulaanbaatar": return "Улан-Батор"
            case "Vientiane": return "В'єнтьян"
            case "Yangon": return "Янгон"
            case "Yerevan": return "Ереван"

            // Африка
            case "Algiers": return "Алжир"
            case "Luanda": return "Луанда"
            case "Porto-Novo": return "Порто-Ново"
            case "Gaborone": return "Габороне"
            case "Ouagadougou": return "Уагадугу"
            case "Gitega": return "Гитега"
            case "Yaoundé": return "Яунде"
            case "Praia": return "Прая"
            case "Bangui": return "Банги"
            case "N'Djamena": return "Нджамена"
            case "Moroni": return "Морони"
            case "Brazzaville": return "Браззавиль"
            case "Kinshasa": return "Киншаса"
            case "Djibouti": return "Джибути"
            case "Cairo": return "Каир"
            case "Malabo": return "Малабо"
            case "Asmara": return "Асмэра"
            case "Mbabane": return "Мбабане"
            case "Addis Ababa": return "Аддис-Абеба"
            case "Libreville": return "Либревиль"
            case "Banjul": return "Банжул"
            case "Accra": return "Аккра"
            case "Conakry": return "Конакри"
            case "Bissau": return "Бисау"
            case "Yamoussoukro": return "Ямусукро"
            case "Nairobi": return "Найроби"
            case "Maseru": return "Масеру"
            case "Monrovia": return "Монровия"
            case "Tripoli": return "Триполи"
            case "Antananarivo": return "Антананариву"
            case "Lilongwe": return "Лилонгве"
            case "Bamako": return "Бамако"
            case "Nouakchott": return "Нуакшот"
            case "Port Louis": return "Порт-Луи"
            case "Rabat": return "Рабат"
            case "Maputo": return "Мапуту"
            case "Windhoek": return "Виндхук"
            case "Niamey": return "Ниамей"
            case "Abuja": return "Абуджа"
            case "Kigali": return "Кигали"
            case "São Tomé": return "Сан-Томе"
            case "Dakar": return "Дакар"
            case "Victoria": return "Виктория"
            case "Freetown": return "Фритаун"
            case "Mogadishu": return "Могадишо"
            case "Pretoria": return "Претория"
            case "Juba": return "Джуба"
            case "Khartoum": return "Хартум"
            case "Dodoma": return "Додома"
            case "Lomé": return "Ломе"
            case "Tunis": return "Тунис"
            case "Kampala": return "Кампала"
            case "Lusaka": return "Лусака"
            case "Harare": return "Хараре"

            // Америка
            case "Saint John's": return "Сент-Джонс"
            case "Buenos Aires": return "Буенос-Айрес"
            case "Nassau": return "Нассау"
            case "Bridgetown": return "Бриджтаун"
            case "Belmopan": return "Бельмопан"
            case "Sucre": return "Сукре"
            case "Brasília": return "Бразиліа"
            case "Ottawa": return "Оттава"
            case "Santiago": return "Сантьяго"
            case "Bogotá": return "Богота"
            case "San José": return "Сан-Хосе"
            case "Havana": return "Гавана"
            case "Roseau": return "Розо"
            case "Santo Domingo": return "Санто-Домінго"
            case "Quito": return "Кіто"
            case "San Salvador": return "Сан-Сальвадор"
            case "Saint George's": return "Сент-Джорджес"
            case "Guatemala City": return "Гватемала"
            case "Georgetown": return "Джорджтаун"
            case "Port-au-Prince": return "Порт-о-Пренс"
            case "Tegucigalpa": return "Тегусігальпа"
            case "Kingston": return "Кінгстон"
            case "Mexico City": return "Мехіко"
            case "Managua": return "Манагуа"
            case "Panama City": return "Панама"
            case "Asunción": return "Асунсьйон"
            case "Lima": return "Ліма"
            case "Basseterre": return "Бастер"
            case "Castries": return "Кастрі"
            case "Kingstown": return "Кінгстаун"
            case "Paramaribo": return "Парамарибо"
            case "Port of Spain": return "Порт-оф-Спейн"
            case "Washington, D.C.": return "Вашингтон"
            case "Montevideo": return "Монтевідео"
            case "Caracas": return "Каракас"
            case "Philipsburg": return "Филипсбург"
            case "Marigot": return "Мариго"
            case "Fort-de-France": return "Фор-де-Франс"
            case "Cockburn Town": return "Кокберн-Таун"
            case "Oranjestad": return "Ораньестад"
            case "Plymouth": return "Плимут"
            case "Charlotte Amalie": return "Шарлотта-Амалия"
            case "St. George's": return "Сент-Джорджес"
            case "San Juan": return "Сан-Хуан"
            case "Basse-Terre": return "Бас-Тер"
            case "The Valley": return "Валли"
            case "Road Town": return "Род-Таун"
            case "Gustavia": return "Густавия"
            case "Kralendijk": return "Кралендейк"
            case "George Town": return "Джорджтаун"
            case "Willemstad": return "Виллемстад"

            // Океания
            case "Canberra": return "Канберра"
            case "Suva": return "Сува"
            case "South Tarawa": return "Южная Тарава"
            case "Majuro": return "Маджуро"
            case "Palikir": return "Паликир"
            case "Yaren": return "Ярен"
            case "Wellington": return "Веллингтон"
            case "Ngerulmud": return "Нгерулмуд"
            case "Port Moresby": return "Порт-Морсби"
            case "Apia": return "Апиа"
            case "Honiara": return "Хониара"
            case "Nuku'alofa": return "Нукуалофа"
            case "Funafuti": return "Фунафути"
            case "Port Vila": return "Порт-Вила"

            // Для русского
            case "Avarua": return "Аваруа"

            default:
                return capital
            }
        case "uk":
            switch capital {
            // Європа
            case "Tirana": return "Тирана"
            case "Andorra la Vella": return "Андорра-ла-Велья"
            case "Vienna": return "Вена"
            case "Minsk": return "Мінськ"
            case "Brussels": return "Брюссель"
            case "Sarajevo": return "Сараево"
            case "Sofia": return "Софія"
            case "Zagreb": return "Загреб"
            case "Prague": return "Прага"
            case "Copenhagen": return "Копенгаген"
            case "Tallinn": return "Таллінн"
            case "Helsinki": return "Гельсінкі"
            case "Paris": return "Париж"
            case "Berlin": return "Берлін"
            case "Athens": return "Афіни"
            case "Budapest": return "Будапешт"
            case "Reykjavik": return "Рейк'явік"
            case "Dublin": return "Дублін"
            case "Rome": return "Рим"
            case "Riga": return "Рига"
            case "Vaduz": return "Вадуц"
            case "Vilnius": return "Вільнюс"
            case "Luxembourg": return "Люксембург"
            case "Valletta": return "Валлетта"
            case "Chisinau": return "Кишинів"
            case "Monaco": return "Монако"
            case "Podgorica": return "Подгорица"
            case "Amsterdam": return "Амстердам"
            case "Skopje": return "Скоп'є"
            case "Oslo": return "Осло"
            case "Warsaw": return "Варшава"
            case "Lisbon": return "Лісабон"
            case "Bucharest": return "Бухарест"
            case "Moscow": return "Москва"
            case "San Marino": return "Сан-Марино"
            case "Belgrade": return "Белград"
            case "Bratislava": return "Братислава"
            case "Ljubljana": return "Любляна"
            case "Madrid": return "Мадрид"
            case "Stockholm": return "Стокгольм"
            case "Bern": return "Берн"
            case "Kyiv": return "Київ"
            case "London": return "Лондон"
            case "Vatican City": return "Ватикан"

            // Азия (полный список)
            case "Abu Dhabi": return "Абу-Дабі"
            case "Amman": return "Амман"
            case "Ankara": return "Анкара"
            case "Ashgabat": return "Ашгабат"
            case "Baghdad": return "Багдад"
            case "Baku": return "Баку"
            case "Bangkok": return "Бангкок"
            case "Beijing": return "Пекін"
            case "Beirut": return "Бейрут"
            case "Bishkek": return "Бішкек"
            case "Bandar Seri Begawan": return "Бандар-Сері-Бегаван"
            case "Damascus": return "Дамаск"
            case "Dhaka": return "Дакка"
            case "Dili": return "Ділі"
            case "Doha": return "Доха"
            case "Dushanbe": return "Душанбе"
            case "Hanoi": return "Ханой"
            case "Islamabad": return "Ісламабад"
            case "Jakarta": return "Джакарта"
            case "Jerusalem": return "Єрусалим"
            case "Kabul": return "Кабул"
            case "Kathmandu": return "Катманду"
            case "Kuala Lumpur": return "Куала-Лумпур"
            case "Kuwait City": return "Ель-Кувейт"
            case "Manila": return "Маніла"
            case "Male": return "Мале"
            case "Manama": return "Манама"
            case "Muscat": return "Маскат"
            case "Naypyidaw": return "Найп'їдо"
            case "New Delhi": return "Нью-Делі"
            case "Nicosia": return "Нікосія"
            case "Nur-Sultan": return "Нур-Султан"
            case "Phnom Penh": return "Пномпень"
            case "Pyongyang": return "Пхеньян"
            case "Riyadh": return "Ер-Ріяд"
            case "Sana'a": return "Сана"
            case "Seoul": return "Сеул"
            case "Singapore": return "Сінгапур"
            case "Sri Jayawardenepura Kotte": return "Шрі-Джаяварденепура-Котте"
            case "Taipei": return "Тайбей"
            case "Tashkent": return "Ташкент"
            case "Tbilisi": return "Тбілісі"
            case "Tehran": return "Тегеран"
            case "Thimphu": return "Тхімпху"
            case "Tokyo": return "Токіо"
            case "Ulaanbaatar": return "Улан-Батор"
            case "Vientiane": return "В'єнтьян"
            case "Yangon": return "Янгон"
            case "Yerevan": return "Єреван"

            // Африка
            case "Algiers": return "Алжир"
            case "Luanda": return "Луанда"
            case "Porto-Novo": return "Порто-Ново"
            case "Gaborone": return "Габороне"
            case "Ouagadougou": return "Уагадугу"
            case "Gitega": return "Гітега"
            case "Yaoundé": return "Яунде"
            case "Praia": return "Прая"
            case "Bangui": return "Бангі"
            case "N'Djamena": return "Нджамена"
            case "Moroni": return "Мороні"
            case "Brazzaville": return "Браззавіль"
            case "Kinshasa": return "Кіншаса"
            case "Djibouti": return "Джибуті"
            case "Cairo": return "Каїр"
            case "Malabo": return "Малабо"
            case "Asmara": return "Асмера"
            case "Mbabane": return "Мбабане"
            case "Addis Ababa": return "Аддис-Абеба"
            case "Libreville": return "Лібревіль"
            case "Banjul": return "Банжул"
            case "Accra": return "Аккра"
            case "Conakry": return "Конакрі"
            case "Bissau": return "Бісау"
            case "Yamoussoukro": return "Ямусукро"
            case "Nairobi": return "Найробі"
            case "Maseru": return "Масеру"
            case "Monrovia": return "Монровія"
            case "Tripoli": return "Тріполі"
            case "Antananarivo": return "Антананаріву"
            case "Lilongwe": return "Лілонгве"
            case "Bamako": return "Бамако"
            case "Nouakchott": return "Нуакшот"
            case "Port Louis": return "Порт-Луї"
            case "Rabat": return "Рабат"
            case "Maputo": return "Мапуту"
            case "Windhoek": return "Віндгук"
            case "Niamey": return "Ніамей"
            case "Abuja": return "Абуджа"
            case "Kigali": return "Кігалі"
            case "São Tomé": return "Сан-Томе"
            case "Dakar": return "Дакар"
            case "Victoria": return "Вікторія"
            case "Freetown": return "Фрітаун"
            case "Mogadishu": return "Могадішо"
            case "Pretoria": return "Преторія"
            case "Juba": return "Джуба"
            case "Khartoum": return "Хартум"
            case "Dodoma": return "Додома"
            case "Lomé": return "Ломе"
            case "Tunis": return "Туніс"
            case "Kampala": return "Кампала"
            case "Lusaka": return "Лусака"
            case "Harare": return "Хараре"

            // Америка
            case "Saint John's": return "Сент-Джонс"
            case "Buenos Aires": return "Буенос-Айрес"
            case "Nassau": return "Нассау"
            case "Bridgetown": return "Бриджтаун"
            case "Belmopan": return "Бельмопан"
            case "Sucre": return "Сукре"
            case "Brasília": return "Бразиліа"
            case "Ottawa": return "Оттава"
            case "Santiago": return "Сантьяго"
            case "Bogotá": return "Богота"
            case "San José": return "Сан-Хосе"
            case "Havana": return "Гавана"
            case "Roseau": return "Розо"
            case "Santo Domingo": return "Санто-Домінго"
            case "Quito": return "Кіто"
            case "San Salvador": return "Сан-Сальвадор"
            case "Saint George's": return "Сент-Джорджес"
            case "Guatemala City": return "Гватемала"
            case "Georgetown": return "Джорджтаун"
            case "Port-au-Prince": return "Порт-о-Пренс"
            case "Tegucigalpa": return "Тегусігальпа"
            case "Kingston": return "Кінгстон"
            case "Mexico City": return "Мехіко"
            case "Managua": return "Манагуа"
            case "Panama City": return "Панама"
            case "Asunción": return "Асунсьйон"
            case "Lima": return "Ліма"
            case "Basseterre": return "Бастер"
            case "Castries": return "Кастрі"
            case "Kingstown": return "Кінгстаун"
            case "Paramaribo": return "Парамарибо"
            case "Port of Spain": return "Порт-оф-Спейн"
            case "Washington, D.C.": return "Вашингтон"
            case "Montevideo": return "Монтевідео"
            case "Caracas": return "Каракас"
            case "Philipsburg": return "Філіпсбург"
            case "Marigot": return "Маріго"
            case "Fort-de-France": return "Фор-де-Франс"
            case "Cockburn Town": return "Кокберн-Таун"
            case "Oranjestad": return "Ораньєстад"
            case "Plymouth": return "Плімут"
            case "Charlotte Amalie": return "Шарлотта-Амалія"
            case "St. George's": return "Сент-Джорджес"
            case "San Juan": return "Сан-Хуан"
            case "Basse-Terre": return "Бас-Тер"
            case "The Valley": return "Валлі"
            case "Road Town": return "Род-Таун"
            case "Gustavia": return "Густавія"
            case "Kralendijk": return "Кралендейк"
            case "George Town": return "Джорджтаун"
            case "Willemstad": return "Віллемстад"

            // Океания
            case "Canberra": return "Канберра"
            case "Suva": return "Сува"
            case "South Tarawa": return "Південна Тарава"
            case "Majuro": return "Маджуро"
            case "Palikir": return "Палікір"
            case "Yaren": return "Ярен"
            case "Wellington": return "Веллінгтон"
            case "Ngerulmud": return "Нгерулмуд"
            case "Port Moresby": return "Порт-Морсбі"
            case "Apia": return "Апіа"
            case "Honiara": return "Хоніара"
            case "Nuku'alofa": return "Нукуалофа"
            case "Funafuti": return "Фунафуті"
            case "Port Vila": return "Порт-Віла"

            // Для русского
            case "Avarua": return "Аваруа"

            default:
                return capital
            }
        case "es":
            switch capital {
            // Europa
            case "Tirana": return "Tirana"
            case "Andorra la Vella": return "Andorra la Vella"
            case "Vienna": return "Viena"
            case "Minsk": return "Minsk"
            case "Brussels": return "Bruselas"
            case "Sarajevo": return "Sarajevo"
            case "Sofia": return "Sofía"
            case "Zagreb": return "Zagreb"
            case "Prague": return "Praga"
            case "Copenhagen": return "Copenhague"
            case "Tallinn": return "Tallinn"
            case "Helsinki": return "Helsinki"
            case "Paris": return "París"
            case "Berlin": return "Berlín"
            case "Athens": return "Atenas"
            case "Budapest": return "Budapest"
            case "Reykjavik": return "Reykjavík"
            case "Dublin": return "Dublín"
            case "Rome": return "Roma"
            case "Riga": return "Riga"
            case "Vaduz": return "Vaduz"
            case "Vilnius": return "Vilna"
            case "Luxembourg": return "Luxemburgo"
            case "Valletta": return "La Valletta"
            case "Chisinau": return "Chisináu"
            case "Monaco": return "Mónaco"
            case "Podgorica": return "Podgorica"
            case "Amsterdam": return "Amsterdam"
            case "Skopje": return "Skopje"
            case "Oslo": return "Oslo"
            case "Warsaw": return "Varsòvia"
            case "Lisbon": return "Lisboa"
            case "Bucharest": return "Bucarest"
            case "Moscow": return "Moscou"
            case "San Marino": return "San Marino"
            case "Belgrade": return "Belgrad"
            case "Bratislava": return "Bratislava"
            case "Ljubljana": return "Liubliana"
            case "Madrid": return "Madrid"
            case "Stockholm": return "Estocolm"
            case "Bern": return "Berna"
            case "Kyiv": return "Kíiv"
            case "London": return "Londres"
            case "Vatican City": return "Ciutat del Vaticà"

            // Asia
            case "Abu Dhabi": return "Abu Dabi"
            case "Amman": return "Amán"
            case "Ankara": return "Ankara"
            case "Ashgabat": return "Asjabad"
            case "Baghdad": return "Bagdad"
            case "Baku": return "Bakú"
            case "Bangkok": return "Bangkok"
            case "Beijing": return "Pequín"
            case "Beirut": return "Beirut"
            case "Bishkek": return "Biskek"
            case "Bandar Seri Begawan": return "Bandar Seri Begawan"
            case "Damascus": return "Damasco"
            case "Dhaka": return "Daca"
            case "Dili": return "Dili"
            case "Doha": return "Doha"
            case "Dushanbe": return "Dusambé"
            case "Hanoi": return "Hanói"
            case "Jerusalem": return "Jerusalén"
            case "Manila": return "Manila"
            case "New Delhi": return "Nueva Delhi"
            case "Seoul": return "Seúl"
            case "Tokyo": return "Tokio"

            // Africa
            case "Algiers": return "Argel"
            case "Luanda": return "Luanda"
            case "Porto-Novo": return "Porto-Novo"
            case "Gaborone": return "Gaborone"
            case "Ouagadougou": return "Uagadugú"
            case "Gitega": return "Guitega"
            case "Yaoundé": return "Yaundé"
            case "Praia": return "Praia"
            case "Bangui": return "Bangui"
            case "N'Djamena": return "Yamena"
            case "Moroni": return "Moroni"
            case "Brazzaville": return "Brazzaville"
            case "Kinshasa": return "Kinshasa"
            case "Djibouti": return "Yibuti"
            case "Cairo": return "El Cairo"
            case "Malabo": return "Malabo"
            case "Asmara": return "Asmara"
            case "Mbabane": return "Mbabane"
            case "Addis Ababa": return "Adís Abeba"
            case "Libreville": return "Libreville"
            case "Banjul": return "Banjul"
            case "Accra": return "Acra"
            case "Conakry": return "Conakri"
            case "Bissau": return "Bisáu"
            case "Yamoussoukro": return "Yamusukro"
            case "Nairobi": return "Nairobi"
            case "Maseru": return "Maseru"
            case "Monrovia": return "Monrovia"
            case "Tripoli": return "Trípoli"
            case "Antananarivo": return "Antananarivo"
            case "Lilongwe": return "Lilongüe"
            case "Bamako": return "Bamako"
            case "Nouakchott": return "Nuakchot"
            case "Port Louis": return "Port Louis"
            case "Rabat": return "Rabat"
            case "Maputo": return "Maputo"
            case "Windhoek": return "Windhoek"
            case "Niamey": return "Niamey"
            case "Abuja": return "Abuya"
            case "Kigali": return "Kigali"
            case "São Tomé": return "Santo Tomé"
            case "Dakar": return "Dakar"
            case "Victoria": return "Victoria"
            case "Freetown": return "Freetown"
            case "Mogadishu": return "Mogadiscio"
            case "Pretoria": return "Pretoria"
            case "Juba": return "Yuba"
            case "Khartoum": return "Jartum"
            case "Dodoma": return "Dodoma"
            case "Lomé": return "Lomé"
            case "Tunis": return "Túnez"
            case "Kampala": return "Kampala"
            case "Lusaka": return "Lusaka"
            case "Harare": return "Harare"

            // America
            case "Brasília": return "Brasilia"
            case "Buenos Aires": return "Buenos Aires"
            case "Havana": return "La Habana"
            case "Lima": return "Lima"
            case "Mexico City": return "Ciudad de México"
            case "Ottawa": return "Ottawa"
            case "Washington, D.C.": return "Washington D.C."

            // Oceania
            case "Canberra": return "Canberra"
            case "Wellington": return "Wellington"
            case "Suva": return "Suva"

            // Продолжаем Asia
            case "Islamabad": return "Islamabad"
            case "Jakarta": return "Yakarta"
            case "Kabul": return "Kabul"
            case "Kathmandu": return "Katmandú"
            case "Kuwait City": return "Kuwait"
            case "Male": return "Malé"
            case "Manama": return "Manama"
            case "Muscat": return "Mascate"
            case "Naypyidaw": return "Naipyidó"
            case "Nicosia": return "Nicosia"
            case "Nur-Sultan": return "Nursultán"
            case "Phnom Penh": return "Nom Pen"
            case "Pyongyang": return "Pionyang"
            case "Riyadh": return "Riad"
            case "Sana'a": return "Saná"
            case "Singapore": return "Singapur"
            case "Sri Jayawardenepura Kotte": return "Sri Jayawardenepura Kotte"
            case "Taipei": return "Taipéi"
            case "Tashkent": return "Taskent"
            case "Tbilisi": return "Tiflis"
            case "Tehran": return "Teherán"
            case "Thimphu": return "Timbu"
            case "Ulaanbaatar": return "Ulán Bator"
            case "Vientiane": return "Vientián"
            case "Yangon": return "Rangún"
            case "Yerevan": return "Ereván"

            // América
            case "Saint John's": return "Saint John's"
            case "Nassau": return "Nassau"
            case "Bridgetown": return "Bridgetown"
            case "Belmopan": return "Belmopán"
            case "Sucre": return "Sucre"
            case "Santiago": return "Santiago"
            case "Bogotá": return "Bogotá"
            case "San José": return "San José"
            case "Roseau": return "Roseau"
            case "Santo Domingo": return "Santo Domingo"
            case "Quito": return "Quito"
            case "San Salvador": return "San Salvador"
            case "Saint George's": return "Saint George's"
            case "Guatemala City": return "Ciudad de Guatemala"
            case "Georgetown": return "Georgetown"
            case "Port-au-Prince": return "Puerto Príncipe"
            case "Tegucigalpa": return "Tegucigalpa"
            case "Kingston": return "Kingston"
            case "Managua": return "Managua"
            case "Panama City": return "Ciudad de Panamá"
            case "Asunción": return "Asunción"
            case "Basseterre": return "Basseterre"
            case "Castries": return "Castries"
            case "Kingstown": return "Kingstown"
            case "Paramaribo": return "Paramaribo"
            case "Port of Spain": return "Puerto España"
            case "Montevideo": return "Montevideo"
            case "Caracas": return "Caracas"
            case "Philipsburg": return "Philipsburg"
            case "Marigot": return "Marigot"
            case "Fort-de-France": return "Fort-de-France"
            case "Cockburn Town": return "Cockburn Town"
            case "Oranjestad": return "Oranjestad"
            case "Plymouth": return "Plymouth"
            case "Charlotte Amalie": return "Charlotte Amalie"
            case "St. George's": return "Saint George"
            case "San Juan": return "San Juan"
            case "Basse-Terre": return "Basse-Terre"
            case "The Valley": return "El Valle"
            case "Road Town": return "Road Town"
            case "Gustavia": return "Gustavia"
            case "Kralendijk": return "Kralendijk"
            case "George Town": return "George Town"
            case "Willemstad": return "Willemstad"

            // Oceanía
            case "South Tarawa": return "Tarawa del Sur"
            case "Majuro": return "Majuro"
            case "Palikir": return "Palikir"
            case "Yaren": return "Yaren"
            case "Ngerulmud": return "Ngerulmud"
            case "Port Moresby": return "Puerto Moresby"
            case "Apia": return "Apia"
            case "Honiara": return "Honiara"
            case "Nuku'alofa": return "Nukualofa"
            case "Funafuti": return "Funafuti"
            case "Port Vila": return "Port Vila"

            // Для русского
            case "Avarua": return "Аваруа"

            default:
                return capital
            }
        case "ca":
            switch capital {
            // Àsia
            case "Abu Dhabi": return "Abu Dhabi"
            case "Amman": return "Amman"
            case "Ankara": return "Ankara"
            case "Ashgabat": return "Aixkhabad"
            case "Baghdad": return "Bagdad"
            case "Baku": return "Bakú"
            case "Bangkok": return "Bangkok"
            case "Beijing": return "Pequín"
            case "Beirut": return "Beirut"
            case "Bishkek": return "Bixkek"
            case "Bandar Seri Begawan": return "Bandar Seri Begawan"
            case "Damascus": return "Damasc"
            case "Dhaka": return "Dacca"
            case "Dili": return "Dili"
            case "Doha": return "Doha"
            case "Dushanbe": return "Duixanbe"
            case "Hanoi": return "Hanoi"
            case "Islamabad": return "Islamabad"
            case "Jakarta": return "Jakarta"
            case "Jerusalem": return "Jerusalem"
            case "Kabul": return "Kabul"
            case "Kathmandu": return "Katmandú"
            case "Kuwait City": return "Kuwait"
            case "Male": return "Malé"
            case "Manama": return "Al-Manama"
            case "Manila": return "Manila"
            case "Muscat": return "Masqat"
            case "Naypyidaw": return "Naypyidaw"
            case "New Delhi": return "Nova Delhi"
            case "Nicosia": return "Nicòsia"
            case "Nur-Sultan": return "Nursultan"
            case "Phnom Penh": return "Phnom Penh"
            case "Pyongyang": return "Pyongyang"
            case "Riyadh": return "Al-Riyad"
            case "Sana'a": return "Sanà"
            case "Seoul": return "Seül"
            case "Singapore": return "Singapur"
            case "Sri Jayawardenepura Kotte": return "Sri Jayawardenepura Kotte"
            case "Taipei": return "Taipei"
            case "Tashkent": return "Taixkent"
            case "Tbilisi": return "Tbilissi"
            case "Tehran": return "Teheran"
            case "Thimphu": return "Thimphu"
            case "Tokyo": return "Tòquio"
            case "Ulaanbaatar": return "Ulan Bator"
            case "Vientiane": return "Vientiane"
            case "Yangon": return "Yangon"
            case "Yerevan": return "Erevan"

            // Àfrica
            case "Algiers": return "Alger"
            case "Luanda": return "Luanda"
            case "Porto-Novo": return "Porto-Novo"
            case "Gaborone": return "Gaborone"
            case "Ouagadougou": return "Ouagadougou"
            case "Gitega": return "Gitega"
            case "Yaoundé": return "Yaoundé"
            case "Praia": return "Praia"
            case "Bangui": return "Bangui"
            case "N'Djamena": return "N'Djamena"
            case "Moroni": return "Moroni"
            case "Brazzaville": return "Brazzaville"
            case "Kinshasa": return "Kinshasa"
            case "Djibouti": return "Djibouti"
            case "Cairo": return "El Caire"
            case "Malabo": return "Malabo"
            case "Asmara": return "Asmara"
            case "Mbabane": return "Mbabane"
            case "Addis Ababa": return "Addis Abeba"
            case "Libreville": return "Libreville"
            case "Banjul": return "Banjul"
            case "Accra": return "Accra"
            case "Conakry": return "Conakry"
            case "Bissau": return "Bissau"
            case "Yamoussoukro": return "Yamoussoukro"
            case "Nairobi": return "Nairobi"
            case "Maseru": return "Maseru"
            case "Monrovia": return "Monròvia"
            case "Tripoli": return "Trípoli"
            case "Antananarivo": return "Antananarivo"
            case "Lilongwe": return "Lilongwe"
            case "Bamako": return "Bamako"
            case "Nouakchott": return "Nouakchott"
            case "Port Louis": return "Port Louis"
            case "Rabat": return "Rabat"
            case "Maputo": return "Maputo"
            case "Windhoek": return "Windhoek"
            case "Niamey": return "Niamey"
            case "Abuja": return "Abuja"
            case "Kigali": return "Kigali"
            case "São Tomé": return "São Tomé"
            case "Dakar": return "Dakar"
            case "Victoria": return "Victòria"
            case "Freetown": return "Freetown"
            case "Mogadishu": return "Mogadiscio"
            case "Pretoria": return "Pretòria"
            case "Juba": return "Juba"
            case "Khartoum": return "Khartum"
            case "Dodoma": return "Dodoma"
            case "Lomé": return "Lomé"
            case "Tunis": return "Tunis"
            case "Kampala": return "Kampala"
            case "Lusaka": return "Lusaka"
            case "Harare": return "Harare"

            // Amèrica
            case "Saint John's": return "Saint John's"
            case "Nassau": return "Nassau"
            case "Bridgetown": return "Bridgetown"
            case "Belmopan": return "Belmopan"
            case "Sucre": return "Sucre"
            case "Brasília": return "Brasília"
            case "Ottawa": return "Ottawa"
            case "Santiago": return "Santiago"
            case "Bogotá": return "Bogotà"
            case "San José": return "San José"
            case "Havana": return "L'Havana"
            case "Roseau": return "Roseau"
            case "Santo Domingo": return "Santo Domingo"
            case "Quito": return "Quito"
            case "San Salvador": return "San Salvador"
            case "Saint George's": return "Saint George's"
            case "Guatemala City": return "Ciutat de Guatemala"
            case "Georgetown": return "Georgetown"
            case "Port-au-Prince": return "Port-au-Prince"
            case "Tegucigalpa": return "Tegucigalpa"
            case "Kingston": return "Kingston"
            case "Mexico City": return "Ciutat de Mèxic"
            case "Managua": return "Managua"
            case "Panama City": return "Ciutat de Panamà"
            case "Asunción": return "Asunción"
            case "Lima": return "Lima"
            case "Basseterre": return "Basseterre"
            case "Castries": return "Castries"
            case "Kingstown": return "Kingstown"
            case "Paramaribo": return "Paramaribo"
            case "Port of Spain": return "Port-of-Spain"
            case "Washington, D.C.": return "Washington DC"
            case "Montevideo": return "Montevideo"
            case "Caracas": return "Caracas"
            case "Philipsburg": return "Philipsburg"
            case "Marigot": return "Marigot"
            case "Fort-de-France": return "Fort-de-France"
            case "Cockburn Town": return "Cockburn Town"
            case "Oranjestad": return "Oranjestad"
            case "Plymouth": return "Plymouth"
            case "Charlotte Amalie": return "Charlotte Amalie"
            case "St. George's": return "Saint George"
            case "San Juan": return "San Juan"
            case "Basse-Terre": return "Basse-Terre"
            case "The Valley": return "La Vall"
            case "Road Town": return "Road Town"
            case "Gustavia": return "Gustavia"
            case "Kralendijk": return "Kralendijk"
            case "George Town": return "George Town"
            case "Willemstad": return "Willemstad"

            // Oceania
            case "Canberra": return "Canberra"
            case "Suva": return "Suva"
            case "South Tarawa": return "Tarawa Sud"
            case "Majuro": return "Majuro"
            case "Palikir": return "Palikir"
            case "Yaren": return "Yaren"
            case "Wellington": return "Wellington"
            case "Ngerulmud": return "Ngerulmud"
            case "Port Moresby": return "Port Moresby"
            case "Apia": return "Apia"
            case "Honiara": return "Honiara"
            case "Nuku'alofa": return "Nukualofa"
            case "Funafuti": return "Funafuti"
            case "Port Vila": return "Port Vila"
            case "Avarua": return "Avarua"

            default:
                return capital
            }
        case "zh":
            switch capital {
            // Europa
            case "Tirana": return "地拉那"
            case "Andorra la Vella": return "安德拉-拉-维莱亚"
            case "Vienna": return "维也纳"
            case "Minsk": return "明斯克"
            case "Brussels": return "布鲁塞尔"
            case "Sarajevo": return "萨拉热窝"
            case "Sofia": return "索非亚"
            case "Zagreb": return "萨格勒布"
            case "Prague": return "布拉格"
            case "Copenhagen": return "哥本哈根"
            case "Tallinn": return "塔林"
            case "Helsinki": return "赫尔辛基"
            case "Paris": return "巴黎"
            case "Berlin": return "柏林"
            case "Athens": return "雅典"
            case "Budapest": return "布达佩斯"
            case "Reykjavik": return "雷克雅未克"
            case "Dublin": return "都柏林"
            case "Rome": return "罗马"
            case "Riga": return "里加"
            case "Vaduz": return "瓦杜兹"
            case "Vilnius": return "维尔纽斯"
            case "Luxembourg": return "卢森堡"
            case "Valletta": return "瓦莱塔"
            case "Chisinau": return "基希讷乌"
            case "Monaco": return "摩纳哥"
            case "Podgorica": return "波德戈里察"
            case "Amsterdam": return "阿姆斯特丹"
            case "Skopje": return "斯科普里"
            case "Oslo": return "奥斯陆"
            case "Warsaw": return "华沙"
            case "Lisbon": return "里斯本"
            case "Bucharest": return "布加勒斯特"
            case "Moscow": return "莫斯科"
            case "San Marino": return "圣马力诺"
            case "Belgrade": return "贝尔格莱德"
            case "Bratislava": return "布拉迪斯拉发"
            case "Ljubljana": return "卢布尔雅那"
            case "Madrid": return "马德里"
            case "Stockholm": return "斯德哥尔摩"
            case "Bern": return "伯尔尼"
            case "Kyiv": return "基辅"
            case "London": return "伦敦"
            case "Vatican City": return "梵蒂冈城"

            // Азия
            case "Ankara": return "安卡拉"
            case "Baghdad": return "巴格达"
            case "Bangkok": return "曼谷"
            case "Beijing": return "北京"
            case "Hanoi": return "河内"
            case "Jerusalem": return "耶路撒冷"
            case "Manila": return "马尼拉"
            case "New Delhi": return "新德里"
            case "Seoul": return "首尔"
            case "Tokyo": return "东京"

            // Africa
            case "Algiers": return "阿尔及尔"
            case "Cairo": return "开罗"
            case "Cape Town": return "开普敦"
            case "Dakar": return "达喀尔"
            case "Nairobi": return "内罗毕"
            case "Pretoria": return "比勒陀利亚"
            case "Tunis": return "突尼斯"

            // America
            case "Brasília": return "巴西利亚"
            case "Buenos Aires": return "布宜诺斯艾利斯"
            case "Havana": return "哈瓦那"
            case "Lima": return "利马"
            case "Mexico City": return "墨西哥城"
            case "Ottawa": return "渥太华"
            case "Washington, D.C.": return "华盛顿特区"

            // Oceania
            case "Canberra": return "堪培拉"
            case "Wellington": return "惠灵顿"
            case "Suva": return "苏瓦"

            // Продолжаем Asia
            case "Abu Dhabi": return "阿布扎比"
            case "Amman": return "安曼"
            case "Ashgabat": return "阿什哈巴德"
            case "Baku": return "巴库"
            case "Bandar Seri Begawan": return "斯里巴加湾市"
            case "Beirut": return "贝鲁特"
            case "Bishkek": return "比什凯克"
            case "Damascus": return "大马士革"
            case "Dhaka": return "达卡"
            case "Dili": return "帝力"
            case "Doha": return "多哈"
            case "Dushanbe": return "杜尚别"
            case "Islamabad": return "伊斯兰堡"
            case "Jakarta": return "雅加达"
            case "Kabul": return "喀布尔"
            case "Kathmandu": return "加德满都"
            case "Kuwait City": return "科威特城"
            case "Male": return "马累"
            case "Manama": return "麦纳麦"
            case "Muscat": return "马斯喀特"
            case "Naypyidaw": return "内比都"
            case "Nicosia": return "尼科西亚"
            case "Nur-Sultan": return "努尔苏丹"
            case "Phnom Penh": return "金边"
            case "Pyongyang": return "平壤"
            case "Riyadh": return "利雅得"
            case "Sana'a": return "萨那"
            case "Singapore": return "新加坡"
            case "Sri Jayawardenepura Kotte": return "斯里贾亚瓦德纳普拉科特"
            case "Taipei": return "台北"
            case "Tashkent": return "塔什干"
            case "Tbilisi": return "第比利斯"
            case "Tehran": return "德黑兰"
            case "Thimphu": return "廷布"
            case "Ulaanbaatar": return "乌兰巴托"
            case "Vientiane": return "万象"
            case "Yangon": return "仰光"
            case "Yerevan": return "埃里温"

            // Африка
            case "Luanda": return "罗安达"
            case "Porto-Novo": return "波多诺伏"
            case "Gaborone": return "哈博罗内"
            case "Ouagadougou": return "瓦加杜古"
            case "Gitega": return "基特加"
            case "Yaoundé": return "雅温得"
            case "Praia": return "普拉亚"
            case "Bangui": return "班吉"
            case "N'Djamena": return "恩贾梅纳"
            case "Moroni": return "莫罗尼"
            case "Brazzaville": return "布拉柴维尔"
            case "Kinshasa": return "金沙萨"
            case "Djibouti": return "吉布提"
            case "Malabo": return "马拉博"
            case "Asmara": return "阿斯马拉"
            case "Mbabane": return "姆巴巴纳"
            case "Addis Ababa": return "亚的斯亚贝巴"
            case "Libreville": return "利伯维尔"
            case "Banjul": return "班珠尔"
            case "Accra": return "阿克拉"
            case "Conakry": return "科纳克里"
            case "Bissau": return "比绍"
            case "Yamoussoukro": return "亚穆苏克罗"
            case "Maseru": return "马塞卢"
            case "Monrovia": return "蒙罗维亚"
            case "Tripoli": return "的黎波里"
            case "Antananarivo": return "塔那那利佛"
            case "Lilongwe": return "利隆圭"
            case "Bamako": return "巴马科"
            case "Nouakchott": return "努瓦克肖特"
            case "Port Louis": return "路易港"
            case "Rabat": return "拉巴特"
            case "Maputo": return "马普托"
            case "Windhoek": return "温得和克"
            case "Niamey": return "尼亚美"
            case "Abuja": return "阿布贾"
            case "Kigali": return "基加利"
            case "São Tomé": return "圣多美"
            case "Victoria": return "维多利亚"
            case "Freetown": return "弗里敦"
            case "Mogadishu": return "摩加迪沙"
            case "Juba": return "朱巴"
            case "Khartoum": return "喀土穆"
            case "Dodoma": return "多多马"
            case "Lomé": return "洛美"
            case "Kampala": return "坎帕拉"
            case "Lusaka": return "卢萨卡"
            case "Harare": return "哈拉雷"

            // Америка
            case "Saint John's": return "圣约翰"
            case "Nassau": return "拿骚"
            case "Bridgetown": return "布里奇顿"
            case "Belmopan": return "贝尔莫潘"
            case "Sucre": return "苏克雷"
            case "Santiago": return "圣地亚哥"
            case "Bogotá": return "波哥大"
            case "San José": return "圣何塞"
            case "Roseau": return "罗索"
            case "Santo Domingo": return "圣多明各"
            case "Quito": return "基多"
            case "San Salvador": return "圣萨尔瓦多"
            case "Saint George's": return "圣乔治"
            case "Guatemala City": return "危地马拉城"
            case "Georgetown": return "乔治敦"
            case "Port-au-Prince": return "太子港"
            case "Tegucigalpa": return "特古西加尔巴"
            case "Kingston": return "金斯敦"
            case "Managua": return "马那瓜"
            case "Panama City": return "巴拿马城"
            case "Asunción": return "亚松森"
            case "Basseterre": return "巴斯特尔"
            case "Castries": return "卡斯特里"
            case "Kingstown": return "金斯敦"
            case "Paramaribo": return "帕拉马里博"
            case "Port of Spain": return "西班牙港"
            case "Montevideo": return "蒙得维的亚"
            case "Caracas": return "加拉加斯"
            case "Philipsburg": return "菲利普斯堡"
            case "Marigot": return "马里戈"
            case "Fort-de-France": return "法兰西堡"
            case "Cockburn Town": return "科克伯恩城"
            case "Oranjestad": return "奥兰耶斯塔德"
            case "Plymouth": return "普利茅斯"
            case "Charlotte Amalie": return "夏洛特阿马利亚"
            case "St. George's": return "圣乔治"
            case "San Juan": return "圣胡安"
            case "Basse-Terre": return "巴斯特尔"
            case "The Valley": return "山谷城"
            case "Road Town": return "罗德城"
            case "Gustavia": return "古斯塔维亚"
            case "Kralendijk": return "克拉伦代克"
            case "George Town": return "乔治城"
            case "Willemstad": return "威廉斯塔德"


            // Океания
            case "South Tarawa": return "南塔拉瓦"
            case "Majuro": return "马朱罗"
            case "Palikir": return "帕利基尔"
            case "Yaren": return "亚伦"
            case "Ngerulmud": return "恩吉鲁穆德"
            case "Port Moresby": return "莫尔兹比港"
            case "Apia": return "阿皮亚"
            case "Honiara": return "霍尼亚拉"
            case "Nuku'alofa": return "努库阿洛法"
            case "Funafuti": return "富纳富提"
            case "Port Vila": return "维拉港"
            case "Avarua": return "阿瓦鲁阿"

            default:
                return capital
            }
        default:
            return capital
        }
    }
    
    private func getLocalizedSubregion(_ subregion: String) -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        if currentLanguage == "system" { return subregion }
        
        switch currentLanguage {
        case "ru":
            switch subregion {
            case "Northern Europe": return "Северная Европа"
            case "Southern Europe": return "Южная Европа"
            case "Western Europe": return "Западная Европа"
            case "Eastern Europe": return "Восточная Европа"
            case "Southeast Europe": return "Юго-Восточная Европа"
            case "Central Europe": return "Центральная Европа"
            case "Northern Africa": return "Северная Африка"
            case "Southern Africa": return "Южная Африка"
            case "Eastern Africa": return "Восточная Африка"
            case "Western Africa": return "Западная Африка"
            case "Middle Africa": return "Центральная Африка"
            case "Eastern Asia": return "Восточная Азия"
            case "Southern Asia": return "Южная Азия"
            case "Southeast Asia": return "Юго-Восточная Азия"
            case "Western Asia": return "Западная Азия"
            case "Central Asia": return "Центральная Азия"
            case "Northern America": return "Северная Америка"
            case "South America": return "Южная Америка"
            case "Central America": return "Центральная Америка"
            case "Caribbean": return "Карибский бассейн"
            case "Melanesia": return "Меланезия"
            case "Micronesia": return "Микронезия"
            case "Polynesia": return "Полинезия"
            default: return subregion
            }
        case "uk":
            switch subregion {
            case "Northern Europe": return "Північна Європа"
            case "Southern Europe": return "Південна Європа"
            case "Western Europe": return "Західна Європа"
            case "Eastern Europe": return "Східна Європа"
            case "Southeast Europe": return "Південно-Східна Європа"
            case "Central Europe": return "Центральна Європа"
            case "Northern Africa": return "Північна Африка"
            case "Southern Africa": return "Південна Африка"
            case "Eastern Africa": return "Східна Африка"
            case "Western Africa": return "Західна Африка"
            case "Middle Africa": return "Центральна Африка"
            case "Eastern Asia": return "Східна Азія"
            case "Southern Asia": return "Південна Азія"
            case "Southeast Asia": return "Південно-Східна Азія"
            case "Western Asia": return "Західна Азія"
            case "Central Asia": return "Центральна Азія"
            case "Northern America": return "Північна Америка"
            case "South America": return "Південна Америка"
            case "Central America": return "Центральна Америка"
            case "Caribbean": return "Карибський басейн"
            case "Melanesia": return "Меланезія"
            case "Micronesia": return "Мікронезія"
            case "Polynesia": return "Полінезія"
            default: return subregion
            }
        case "es":
            switch subregion {
            case "Northern Europe": return "Europa del Norte"
            case "Southern Europe": return "Europa del Sur"
            case "Western Europe": return "Europa Occidental"
            case "Eastern Europe": return "Europa Oriental"
            case "Southeast Europe": return "Europa Suroriental"
            case "Central Europe": return "Europa Central"
            case "Northern Africa": return "África del Norte"
            case "Southern Africa": return "África del Sur"
            case "Eastern Africa": return "África Oriental"
            case "Western Africa": return "África Occidental"
            case "Middle Africa": return "África Central"
            case "Eastern Asia": return "Asia Oriental"
            case "Southern Asia": return "Asia del Sur"
            case "Southeast Asia": return "Sudeste Asiático"
            case "Western Asia": return "Asia Occidental"
            case "Central Asia": return "Asia Central"
            case "Northern America": return "América del Norte"
            case "South America": return "América del Sur"
            case "Central America": return "América Central"
            case "Caribbean": return "Caribe"
            case "Melanesia": return "Melanèsia"
            case "Micronesia": return "Micronèsia"
            case "Polynesia": return "Polinèsia"
            default: return subregion
            }
        case "ca":
            switch subregion {
            case "Northern Europe": return "Europa del Nord"
            case "Southern Europe": return "Europa del Sud"
            case "Western Europe": return "Europa Occidental"
            case "Eastern Europe": return "Europa Oriental"
            case "Southeast Europe": return "Europa Sud-oriental"
            case "Central Europe": return "Europa Central"
            case "Northern Africa": return "Àfrica del Nord"
            case "Southern Africa": return "Àfrica del Sud"
            case "Eastern Africa": return "Àfrica Oriental"
            case "Western Africa": return "Àfrica Occidental"
            case "Middle Africa": return "Àfrica Central"
            case "Eastern Asia": return "Àsia Oriental"
            case "Southern Asia": return "Àsia del Sud"
            case "Southeast Asia": return "Sud-est Asiàtic"
            case "Western Asia": return "Àsia Occidental"
            case "Central Asia": return "Àsia Central"
            case "Northern America": return "Amèrica del Nord"
            case "South America": return "Amèrica del Sud"
            case "Central America": return "Amèrica Central"
            case "Caribbean": return "Carib"
            case "Melanesia": return "Melanèsia"
            case "Micronesia": return "Micronèsia"
            case "Polynesia": return "Polinèsia"
            default: return subregion
            }
        case "zh":
            switch subregion {
            case "Northern Europe": return "北欧"
            case "Southern Europe": return "南欧"
            case "Western Europe": return "西欧"
            case "Eastern Europe": return "东欧"
            case "Southeast Europe": return "东南欧"
            case "Central Europe": return "中欧"
            case "Northern Africa": return "北非"
            case "Southern Africa": return "南非"
            case "Eastern Africa": return "东非"
            case "Western Africa": return "西非"
            case "Middle Africa": return "中非"
            case "Eastern Asia": return "东亚"
            case "Southern Asia": return "南亚"
            case "Southeast Asia": return "东南亚"
            case "Western Asia": return "西亚"
            case "Central Asia": return "中亚"
            case "Northern America": return "北美洲"
            case "South America": return "南美洲"
            case "Central America": return "中美洲"
            case "Caribbean": return "加勒比地区"
            case "Melanesia": return "美拉尼西亚"
            case "Micronesia": return "密克罗尼西亚"
            case "Polynesia": return "波利尼西亚"
            default: return subregion
            }
        default:
            return subregion
        }
    }
    
    private func formatPopulation(_ population: Int) -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        
        let millions = Double(population) / 1_000_000.0
        let thousands = Double(population) / 1_000.0
        
        switch currentLanguage {
        case "ru":
            if population >= 1_000_000 {
                return String(format: "%.1f млн", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f тыс", thousands)
            }
        case "uk":
            if population >= 1_000_000 {
                return String(format: "%.1f млн", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f тис", thousands)
            }
        case "es":
            if population >= 1_000_000 {
                return String(format: "%.1f millones", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f mil", thousands)
            }
        case "ca":
            if population >= 1_000_000 {
                return String(format: "%.1f milions", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f mil", thousands)
            }
        case "zh":
            if population >= 1_000_000 {
                return String(format: "%.1f 百万", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f 千", thousands)
            }
        default:
            if population >= 1_000_000 {
                return String(format: "%.1f million", millions)
            } else if population >= 1_000 {
                return String(format: "%.1f thousand", thousands)
            }
        }
        return "\(population)"
    }
    
    private func formatArea(_ area: Double) -> String {
        let currentLanguage = gameState.selectedLanguage.rawValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        
        let millions = area / 1_000_000.0
        
        switch currentLanguage {
        case "ru":
            if area >= 1_000_000 {
                return String(format: "%.2f млн км²", millions)
            }
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) км²"
        case "uk":
            if area >= 1_000_000 {
                return String(format: "%.2f млн км²", millions)
            }
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) км²"
        case "es", "ca":
            if area >= 1_000_000 {
                return String(format: "%.2f millones km²", millions)
            }
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) km²"
        case "zh":
            if area >= 1_000_000 {
                return String(format: "%.2f 百万平方公里", millions)
            }
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) 平方公里"
        default:
            if area >= 1_000_000 {
                return String(format: "%.2f million km²", millions)
            }
            return "\(formatter.string(from: NSNumber(value: area)) ?? String(format: "%.0f", area)) км²"
        }
    }
} 
