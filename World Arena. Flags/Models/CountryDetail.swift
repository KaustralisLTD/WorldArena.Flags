import Foundation

// MARK: - Country Detail Model
struct CountryDetail {
    let code: String
    let name: String
    let flag: String
    let capital: String
    let officialLanguage: String
    let government: String
    let leader: String
    let dialingCode: String
    let population: String
    let currency: String
    let independence: String
    let area: String
    let description: String
    let flagDescription: String
    let anthemDescription: String
    let anthemMeaning: String
    let anthemText: String // Реальный текст гимна страны
    let photos: [String] // URLs или имена файлов фотографий
    let anthemAudio: String // URL или имя файла аудио
    let interestingFacts: [String] // Три интересных факта о стране
}

// MARK: - Country Details Data
class CountryDetailsService {
    static let shared = CountryDetailsService()
    
    private init() {}
    
    @MainActor
    func getCountryDetail(for code: String) -> CountryDetail? {
        let language = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        switch code {
        case "AT":
            return getAustriaDetail(language: language)
        case "DE", "FR", "IT", "ES", "GB", "RU", "US", "CN", "JP":
            return getDefaultCountryDetail(code: code, language: language)
        default:
            return getDefaultCountryDetail(code: code, language: language)
        }
    }
    
    /// Загружает данные страны из RestCountries и собирает CountryDetail (информация, фото из CountryPhotosService, локализованные факты).
    /// Также пытается загрузить локализованный контент (описания флагов, гимнов, факты) из API/бэкенда через CountryLocalizationService.
    @MainActor
    func getCountryDetailAsync(for code: String) async -> CountryDetail? {
        let language = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        
        // Пытаемся загрузить локализованный контент из API/бэкенда
        var localizedContent: CountryLocalizationService.LocalizedCountryContent? = nil
        do {
            localizedContent = try await CountryLocalizationService.shared.fetchLocalizedContent(for: code, language: language)
        } catch {
            print("⚠️ Failed to load localized content from API, using fallback")
        }
        let name = getLocalizedCountryName(for: code)
        let flagEmoji = getFlagEmoji(for: code)
        let photoURLs = CountryPhotosService.shared.getPhotos(for: code).map(\.imageURL)
        
        if let api = try? await CountryService.shared.fetchCountryDetailByCode(code) {
            let capital = api.capitalFirst ?? getCapitalName(for: code, language: language)
            let population: String = {
                guard let p = api.population else { return getPopulation(for: code) }
                if p >= 1_000_000_000 { return String(format: "%.2fB", Double(p) / 1_000_000_000) }
                if p >= 1_000_000 { return String(format: "%.2fM", Double(p) / 1_000_000) }
                if p >= 1_000 { return String(format: "%.1fK", Double(p) / 1_000) }
                return "\(p)"
            }()
            let area: String = {
                guard let a = api.area else { return getArea(for: code) }
                if a >= 1_000_000 { return String(format: "%.0f млн км²", a / 1_000_000) }
                return String(format: "%.0f км²", a)
            }()
            return CountryDetail(
                code: code,
                name: name,
                flag: flagEmoji,
                capital: capital,
                officialLanguage: api.languageString ?? getOfficialLanguage(for: code, language: language),
                government: getGovernmentType(for: code, language: language),
                leader: getLeaderName(for: code, language: language),
                dialingCode: api.dialingCode ?? getDialingCode(for: code),
                population: population,
                currency: api.currencyString ?? getCurrency(for: code, language: language),
                independence: getIndependenceYear(for: code),
                area: area,
                description: getCountryDescription(for: code, language: language),
                flagDescription: localizedContent?.flagDescription ?? getFlagDescription(for: code, language: language),
                anthemDescription: localizedContent?.anthemDescription ?? getAnthemDescription(for: code, language: language),
                anthemMeaning: localizedContent?.anthemMeaning ?? getAnthemMeaning(for: code, language: language),
                anthemText: localizedContent?.anthemText ?? getAnthemText(for: code, language: language),
                photos: photoURLs,
                anthemAudio: localizedContent?.anthemAudioURL ?? "anthem_\(code.lowercased())",
                interestingFacts: localizedContent?.interestingFacts ?? getInterestingFacts(for: code, language: language)
            )
        }
        return getDefaultCountryDetail(code: code, language: language, photoURLs: photoURLs)
    }
    
    // Получить локализованное название страны (сначала системная локализация по коду, иначе словари)
    @MainActor
    func getLocalizedCountryName(for code: String) -> String {
        let language = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        let locale = Locale(identifier: language)
        if let name = locale.localizedString(forRegionCode: code), !name.isEmpty, name != code {
            return name
        }
        switch language {
        case "en":
            return getEnglishName(for: code)
        case "es":
            return getSpanishName(for: code)
        case "uk":
            return getUkrainianName(for: code)
        case "ca":
            return getCatalanName(for: code)
        case "zh":
            return getChineseName(for: code)
        default:
            return getRussianName(for: code)
        }
    }
    
    // Английские названия
    private func getEnglishName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "Austria", "DE": "Germany", "FR": "France", "IT": "Italy", "ES": "Spain",
            "GB": "United Kingdom", "RU": "Russia", "US": "United States", "CN": "China", "JP": "Japan"
        ]
        return names[code] ?? "Country"
    }
    
    // Испанские названия
    private func getSpanishName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "Austria", "DE": "Alemania", "FR": "Francia", "IT": "Italia", "ES": "España",
            "GB": "Reino Unido", "RU": "Rusia", "US": "Estados Unidos", "CN": "China", "JP": "Japón"
        ]
        return names[code] ?? "País"
    }
    
    // Украинские названия
    private func getUkrainianName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "Австрія", "DE": "Німеччина", "FR": "Франція", "IT": "Італія", "ES": "Іспанія",
            "GB": "Велика Британія", "RU": "Росія", "US": "США", "CN": "Китай", "JP": "Японія"
        ]
        return names[code] ?? "Країна"
    }
    
    // Каталанские названия
    private func getCatalanName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "Àustria", "DE": "Alemanya", "FR": "França", "IT": "Itàlia", "ES": "Espanya",
            "GB": "Regne Unit", "RU": "Rússia", "US": "Estats Units", "CN": "Xina", "JP": "Japó"
        ]
        return names[code] ?? "País"
    }
    
    // Китайские названия
    private func getChineseName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "奥地利", "DE": "德国", "FR": "法国", "IT": "意大利", "ES": "西班牙",
            "GB": "英国", "RU": "俄罗斯", "US": "美国", "CN": "中国", "JP": "日本"
        ]
        return names[code] ?? "国家"
    }
    
    // Русские названия
    private func getRussianName(for code: String) -> String {
        let names: [String: String] = [
            "AT": "Австрия", "DE": "Германия", "FR": "Франция", "IT": "Италия", "ES": "Испания",
            "GB": "Великобритания", "RU": "Россия", "US": "США", "CN": "Китай", "JP": "Япония"
        ]
        return names[code] ?? "Страна"
    }
    
    private func getAustriaDetail(language: String) -> CountryDetail {
        switch language {
        case "ru":
            return CountryDetail(
                code: "AT",
                name: "Австрия",
                flag: "🇦🇹",
                capital: "Вена",
                officialLanguage: "Немецкий",
                government: "Федеративная республика",
                leader: "Александр Ван дер Беллен",
                dialingCode: "+43",
                population: "9.178 млн (2024)",
                currency: "Евро (€)",
                independence: "1955",
                area: "83,871 км²",
                description: "Австрия, официально Австрийская Республика, — государство в Центральной Европе, расположенное в Восточных Альпах. Это федерация из девяти земель, столицей которой является Вена — самый густонаселенный город и земля.",
                flagDescription: "Флаг Австрии состоит из трех равновеликих горизонтальных полос: красной, белой и красной. Флаг имеет прямоугольную форму с соотношением сторон 2:3. Красный цвет символизирует кровь, пролитую в борьбе за независимость, а белый - свободу и реку Дунай.",
                anthemDescription: "Гимн Австрии 'Land der Berge, Land am Strome' (Земля гор, земля у реки) был принят в 1947 году.",
                anthemMeaning: "Гимн прославляет красоту австрийской природы, горы и реки, а также единство народа и любовь к родине.",
                anthemText: getAnthemText(for: "AT", language: "ru"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: [
                    "Австрия известна как родина классической музыки - здесь родились Моцарт, Бетховен, Шуберт и Штраус.",
                    "Вена была признана самым пригодным для жизни городом в мире несколько лет подряд.",
                    "В Австрии находится самый старый зоопарк в мире - Шёнбруннский зоопарк, основанный в 1752 году."
                ]
            )
        case "en":
            return CountryDetail(
                code: "AT",
                name: "Austria",
                flag: "🇦🇹",
                capital: "Vienna",
                officialLanguage: "German",
                government: "Federal Republic",
                leader: "Alexander Van der Bellen",
                dialingCode: "+43",
                population: "9.178 million (2024)",
                currency: "Euro (€)",
                independence: "1955",
                area: "83,871 km²",
                description: "Austria, formally the Republic of Austria, is a landlocked country in Central Europe, lying in the Eastern Alps. It is a federation of nine states, of which the capital Vienna is the most populous city and state.",
                flagDescription: "The flag of Austria consists of three equal horizontal bands: red, white, and red. The flag has a rectangular shape with a 2:3 aspect ratio. Red symbolizes the blood shed in the struggle for independence, while white represents freedom and the Danube River.",
                anthemDescription: "The Austrian anthem 'Land der Berge, Land am Strome' (Land of Mountains, Land by the River) was adopted in 1947.",
                anthemMeaning: "The anthem celebrates the beauty of Austrian nature, mountains and rivers, as well as the unity of the people and love for the homeland.",
                anthemText: getAnthemText(for: "AT", language: "en"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: [
                    "Austria is known as the birthplace of classical music - Mozart, Beethoven, Schubert and Strauss were born here.",
                    "Vienna has been ranked as the world's most livable city for several years in a row.",
                    "Austria is home to the world's oldest zoo - Schönbrunn Zoo, founded in 1752."
                ]
            )
        case "es":
            return CountryDetail(
                code: "AT",
                name: "Austria",
                flag: "🇦🇹",
                capital: "Viena",
                officialLanguage: "Alemán",
                government: "República Federal",
                leader: "Alexander Van der Bellen",
                dialingCode: "+43",
                population: "9.178 millones (2024)",
                currency: "Euro (€)",
                independence: "1955",
                area: "83,871 km²",
                description: "Austria, formalmente la República de Austria, es un país sin litoral en Europa Central, ubicado en los Alpes Orientales. Es una federación de nueve estados, de los cuales la capital Viena es la ciudad y estado más poblado.",
                flagDescription: "La bandera de Austria consta de tres bandas horizontales iguales: roja, blanca y roja. La bandera tiene forma rectangular con una relación de aspecto 2:3. El rojo simboliza la sangre derramada en la lucha por la independencia, mientras que el blanco representa la libertad y el río Danubio.",
                anthemDescription: "El himno austriaco 'Land der Berge, Land am Strome' (Tierra de Montañas, Tierra junto al Río) fue adoptado en 1947.",
                anthemMeaning: "El himno celebra la belleza de la naturaleza austriaca, montañas y ríos, así como la unidad del pueblo y el amor por la patria.",
                anthemText: getAnthemText(for: "AT", language: "es"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: getInterestingFacts(for: "AT", language: language)
            )
        case "uk":
            return CountryDetail(
                code: "AT",
                name: "Австрія",
                flag: "🇦🇹",
                capital: "Відень",
                officialLanguage: "Німецька",
                government: "Федеративна республіка",
                leader: "Александр Ван дер Беллен",
                dialingCode: "+43",
                population: "9.178 млн (2024)",
                currency: "Євро (€)",
                independence: "1955",
                area: "83,871 км²",
                description: "Австрія, офіційно Австрійська Республіка, — держава в Центральній Європі, розташована в Східних Альпах. Це федерація з дев'яти земель, столицею якої є Відень — найбільш густонаселений місто і земля.",
                flagDescription: "Прапор Австрії складається з трьох рівновеликих горизонтальних смуг: червоної, білої та червоної. Прапор має прямокутну форму зі співвідношенням сторін 2:3. Червоний колір символізує кров, пролиту в боротьбі за незалежність, а білий - свободу та річку Дунай.",
                anthemDescription: "Гімн Австрії 'Land der Berge, Land am Strome' (Земля гір, земля біля річки) був прийнятий у 1947 році.",
                anthemMeaning: "Гімн прославляє красу австрійської природи, гори та річки, а також єдність народу та любов до батьківщини.",
                anthemText: getAnthemText(for: "AT", language: "uk"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: getInterestingFacts(for: "AT", language: language)
            )
        case "ca":
            return CountryDetail(
                code: "AT",
                name: "Àustria",
                flag: "🇦🇹",
                capital: "Viena",
                officialLanguage: "Alemany",
                government: "República Federal",
                leader: "Alexander Van der Bellen",
                dialingCode: "+43",
                population: "9.178 milions (2024)",
                currency: "Euro (€)",
                independence: "1955",
                area: "83,871 km²",
                description: "Àustria, formalment la República d'Àustria, és un país sense litoral a Europa Central, situat als Alps Orientals. És una federació de nou estats, dels quals la capital Viena és la ciutat i estat més poblat.",
                flagDescription: "La bandera d'Àustria consta de tres bandes horitzontals iguals: vermella, blanca i vermella. La bandera té forma rectangular amb una relació d'aspecte 2:3. El vermell simbolitza la sang vessada en la lluita per la independència, mentre que el blanc representa la llibertat i el riu Danubi.",
                anthemDescription: "L'himne austríac 'Land der Berge, Land am Strome' (Terra de Muntanyes, Terra al costat del Riu) va ser adoptat el 1947.",
                anthemMeaning: "L'himne celebra la bellesa de la natura austríaca, muntanyes i rius, així com la unitat del poble i l'amor per la pàtria.",
                anthemText: getAnthemText(for: "AT", language: "ca"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: getInterestingFacts(for: "AT", language: language)
            )
        case "zh":
            return CountryDetail(
                code: "AT",
                name: "奥地利",
                flag: "🇦🇹",
                capital: "维也纳",
                officialLanguage: "德语",
                government: "联邦共和国",
                leader: "亚历山大·范德贝伦",
                dialingCode: "+43",
                population: "917.8万 (2024)",
                currency: "欧元 (€)",
                independence: "1955",
                area: "83,871平方公里",
                description: "奥地利，正式名称为奥地利共和国，是一个位于中欧的内陆国家，位于东阿尔卑斯山。它是一个由九个州组成的联邦，首都维也纳是人口最多的城市和州。",
                flagDescription: "奥地利国旗由三个相等的水平条纹组成：红色、白色和红色。国旗呈矩形，长宽比为2:3。红色象征着为独立而斗争时流下的鲜血，而白色代表自由和多瑙河。",
                anthemDescription: "奥地利国歌《Land der Berge, Land am Strome》（山之国，河之邦）于1947年采用。",
                anthemMeaning: "国歌歌颂奥地利自然之美、山川河流，以及人民的团结和对祖国的热爱。",
                anthemText: getAnthemText(for: "AT", language: "zh"),
                photos: ["austria_flag", "austria_coat_of_arms", "vienna_palace", "salzburg_castle", "hallstatt_lake"],
                anthemAudio: "austria_anthem",
                interestingFacts: getInterestingFacts(for: "AT", language: language)
            )
        default:
            return getAustriaDetail(language: "en")
        }
    }
    
    @MainActor
    private func getGermanyDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Германии
        return getDefaultCountryDetail(code: "DE", language: language)
    }
    
    @MainActor
    private func getFranceDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Франции
        return getDefaultCountryDetail(code: "FR", language: language)
    }
    
    @MainActor
    private func getItalyDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Италии
        return getDefaultCountryDetail(code: "IT", language: language)
    }
    
    @MainActor
    private func getSpainDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Испании
        return getDefaultCountryDetail(code: "ES", language: language)
    }
    
    @MainActor
    private func getUKDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Великобритании
        return getDefaultCountryDetail(code: "GB", language: language)
    }
    
    @MainActor
    private func getRussiaDetail(language: String) -> CountryDetail {
        // Аналогичная структура для России
        return getDefaultCountryDetail(code: "RU", language: language)
    }
    
    @MainActor
    private func getUSDetail(language: String) -> CountryDetail {
        // Аналогичная структура для США
        return getDefaultCountryDetail(code: "US", language: language)
    }
    
    @MainActor
    private func getChinaDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Китая
        return getDefaultCountryDetail(code: "CN", language: language)
    }
    
    @MainActor
    private func getJapanDetail(language: String) -> CountryDetail {
        // Аналогичная структура для Японии
        return getDefaultCountryDetail(code: "JP", language: language)
    }
    
    @MainActor
    private func getDefaultCountryDetail(code: String, language: String, photoURLs: [String]? = nil) -> CountryDetail {
        let countryName = getLocalizedCountryName(for: code)
        let photos = photoURLs ?? getDefaultPhotos(for: code)
        return CountryDetail(
            code: code,
            name: countryName,
            flag: getFlagEmoji(for: code),
            capital: getCapitalName(for: code, language: language),
            officialLanguage: getOfficialLanguage(for: code, language: language),
            government: getGovernmentType(for: code, language: language),
            leader: getLeaderName(for: code, language: language),
            dialingCode: getDialingCode(for: code),
            population: getPopulation(for: code),
            currency: getCurrency(for: code, language: language),
            independence: getIndependenceYear(for: code),
            area: getArea(for: code),
            description: getCountryDescription(for: code, language: language),
            flagDescription: getFlagDescription(for: code, language: language),
            anthemDescription: getAnthemDescription(for: code, language: language),
            anthemMeaning: getAnthemMeaning(for: code, language: language),
            anthemText: getAnthemText(for: code, language: language),
            photos: photos,
            anthemAudio: "anthem_\(code.lowercased())",
            interestingFacts: getInterestingFacts(for: code, language: language)
        )
    }
    
    // Вспомогательные функции для создания универсального шаблона
    private func getFlagEmoji(for code: String) -> String {
        let two = code.uppercased().prefix(2)
        guard two.count == 2,
              two.unicodeScalars.allSatisfy({ $0.value >= 0x41 && $0.value <= 0x5A }) else { return "🏳️" }
        let base: UInt32 = 127397
        var s = ""
        for v in two.unicodeScalars { s.unicodeScalars.append(UnicodeScalar(base + v.value)!) }
        return String(s)
    }
    
    private func getCapitalName(for code: String, language: String) -> String {
        // Базовые столицы для основных стран
        let capitals: [String: String] = [
            "AT": "Vienna", "DE": "Berlin", "FR": "Paris", "IT": "Rome", "ES": "Madrid",
            "GB": "London", "RU": "Moscow", "US": "Washington", "CN": "Beijing", "JP": "Tokyo"
        ]
        return capitals[code] ?? "Capital"
    }
    
    private func getOfficialLanguage(for code: String, language: String) -> String {
        // Базовые официальные языки
        let languages: [String: String] = [
            "AT": "German", "DE": "German", "FR": "French", "IT": "Italian", "ES": "Spanish",
            "GB": "English", "RU": "Russian", "US": "English", "CN": "Chinese", "JP": "Japanese"
        ]
        return languages[code] ?? "Language"
    }
    
    private func getGovernmentType(for code: String, language: String) -> String {
        // Базовые типы правительств
        let governments: [String: String] = [
            "AT": "Federal Republic", "DE": "Federal Republic", "FR": "Republic", "IT": "Republic", "ES": "Constitutional Monarchy",
            "GB": "Constitutional Monarchy", "RU": "Federal Republic", "US": "Federal Republic", "CN": "People's Republic", "JP": "Constitutional Monarchy"
        ]
        return governments[code] ?? "Government"
    }
    
    private func getLeaderName(for code: String, language: String) -> String {
        // Базовые лидеры (обновляются периодически)
        let leaders: [String: String] = [
            "AT": "Alexander Van der Bellen", "DE": "Frank-Walter Steinmeier", "FR": "Emmanuel Macron", "IT": "Sergio Mattarella", "ES": "Felipe VI",
            "GB": "Charles III", "RU": "Vladimir Putin", "US": "Joe Biden", "CN": "Xi Jinping", "JP": "Naruhito"
        ]
        return leaders[code] ?? "Leader"
    }
    
    private func getDialingCode(for code: String) -> String {
        // Телефонные коды стран
        let dialingCodes: [String: String] = [
            "AT": "+43", "DE": "+49", "FR": "+33", "IT": "+39", "ES": "+34",
            "GB": "+44", "RU": "+7", "US": "+1", "CN": "+86", "JP": "+81"
        ]
        return dialingCodes[code] ?? "+00"
    }
    
    private func getPopulation(for code: String) -> String {
        // Примерная численность населения
        let populations: [String: String] = [
            "AT": "9.1M", "DE": "83.2M", "FR": "67.4M", "IT": "60.4M", "ES": "47.4M",
            "GB": "67.2M", "RU": "146.7M", "US": "331.9M", "CN": "1.4B", "JP": "125.7M"
        ]
        return populations[code] ?? "Population"
    }
    
    private func getCurrency(for code: String, language: String) -> String {
        // Валюты стран
        let currencies: [String: String] = [
            "AT": "Euro (€)", "DE": "Euro (€)", "FR": "Euro (€)", "IT": "Euro (€)", "ES": "Euro (€)",
            "GB": "Pound Sterling (£)", "RU": "Russian Ruble (₽)", "US": "US Dollar ($)", "CN": "Chinese Yuan (¥)", "JP": "Japanese Yen (¥)"
        ]
        return currencies[code] ?? "Currency"
    }
    
    private func getIndependenceYear(for code: String) -> String {
        // Годы независимости
        let independence: [String: String] = [
            "AT": "1955", "DE": "1990", "FR": "1789", "IT": "1861", "ES": "1492",
            "GB": "1707", "RU": "1991", "US": "1776", "CN": "1949", "JP": "660 BC"
        ]
        return independence[code] ?? "Year"
    }
    
    private func getArea(for code: String) -> String {
        // Площади стран
        let areas: [String: String] = [
            "AT": "83,871 km²", "DE": "357,022 km²", "FR": "551,695 km²", "IT": "301,340 km²", "ES": "505,990 km²",
            "GB": "242,495 km²", "RU": "17,098,246 km²", "US": "9,833,517 km²", "CN": "9,596,961 km²", "JP": "377,975 km²"
        ]
        return areas[code] ?? "Area"
    }
    
    private func getCountryDescription(for code: String, language: String) -> String {
        // Базовые описания стран
        let descriptions: [String: String] = [
            "AT": "A beautiful country in Central Europe known for its mountains, music, and culture.",
            "DE": "A powerful European nation with rich history and strong economy.",
            "FR": "A country of art, culture, and revolution, famous for its cuisine and fashion.",
            "IT": "A Mediterranean country with ancient history and delicious cuisine.",
            "ES": "A vibrant country with diverse culture, beautiful beaches, and rich history."
        ]
        return descriptions[code] ?? "A fascinating country with unique culture and history."
    }
    
    private func getFlagDescription(for code: String, language: String) -> String {
        switch language {
        case "ru":
            return getRussianFlagDescription(for: code)
        case "es":
            return getSpanishFlagDescription(for: code)
        case "uk":
            return getUkrainianFlagDescription(for: code)
        case "ca":
            return getCatalanFlagDescription(for: code)
        case "zh":
            return getChineseFlagDescription(for: code)
        default:
            return getEnglishFlagDescription(for: code)
        }
    }
    
    private func getEnglishFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "The flag of Austria consists of three equal horizontal stripes: red-white-red. According to legend, the colors come from Duke Leopold V's white tunic soaked with blood from battle, with only a white stripe remaining where his belt was worn.",
            "US": "The American flag features 13 horizontal stripes (7 red, 6 white) representing the original colonies, and 50 white stars on a blue canton representing the current states. The red symbolizes valor, white represents purity, and blue stands for justice.",
            "GB": "The Union Jack combines the crosses of St. George (England), St. Andrew (Scotland), and St. Patrick (Ireland). The red cross on white represents England, the white diagonal cross on blue represents Scotland, and the red diagonal cross represents Ireland.",
            "FR": "The French tricolor has three vertical stripes: blue, white, and red. Blue and red are the traditional colors of Paris, while white represents the monarchy. Together they symbolize liberty, equality, and fraternity.",
            "DE": "The German flag consists of three horizontal stripes: black, red, and gold. These colors have represented German unity and freedom since the 19th century, particularly during the 1848 revolution.",
            "IT": "The Italian flag has three vertical stripes: green, white, and red. Green represents the country's plains and hills, white symbolizes the snow-capped Alps, and red represents the blood spilled for independence.",
            "ES": "The Spanish flag features two red horizontal stripes with a yellow stripe twice as wide between them. The coat of arms in the center includes symbols representing Spain's historical kingdoms and territories.",
            "RU": "The Russian flag has three horizontal stripes: white, blue, and red. White represents nobility and frankness, blue symbolizes faithfulness and honesty, and red stands for courage and generosity.",
            "CN": "The Chinese flag is red with five yellow stars. The large star represents the Communist Party, while the four smaller stars represent the unity of the Chinese people under the party's leadership.",
            "JP": "The Japanese flag, called Hinomaru, features a red circle (representing the sun) on a white background. The design symbolizes Japan as the 'Land of the Rising Sun' and represents brightness, sincerity, and warmth.",
            "PL": "The Polish flag consists of two equal horizontal stripes: white on top and red below. White represents peace and purity, while red symbolizes courage and the blood shed for independence.",
            "NL": "The Dutch flag has three horizontal stripes: red, white, and blue. These colors date back to the 16th century and represent the struggle for independence from Spanish rule.",
            "BE": "The Belgian flag has three vertical stripes: black, yellow, and red. These colors were adopted during the Belgian Revolution of 1830 and represent the historical provinces.",
            "CH": "The Swiss flag is a red square with a white cross in the center. The cross represents Christianity and Swiss unity, while red symbolizes the blood of martyrs.",
            "SE": "The Swedish flag features a blue field with a yellow Scandinavian cross extending to the edges. The cross represents Christianity, blue symbolizes the sky and lakes, yellow represents the sun.",
            "NO": "The Norwegian flag has a red field with a blue-bordered white Scandinavian cross. The cross represents Christianity, and the colors reflect Norway's historical ties to Denmark.",
            "DK": "The Danish flag, called Dannebrog, is red with a white Scandinavian cross. Legend says it fell from the sky during a battle in 1219, making it one of the oldest flags still in use.",
            "FI": "The Finnish flag features a blue cross on a white background. Blue represents the thousands of lakes and the sky, white symbolizes the snow that covers the country in winter.",
            "PT": "The Portuguese flag has green and red vertical stripes with the national coat of arms. Green represents hope, red symbolizes the blood of those who fought for the nation.",
            "IE": "The Irish flag has three vertical stripes: green, white, and orange. Green represents Catholics, orange represents Protestants, and white symbolizes peace between them.",
            "CZ": "The Czech flag consists of two horizontal stripes (white and red) with a blue triangle extending from the hoist. The colors represent the historical regions of Bohemia, Moravia, and Slovakia.",
            "HU": "The Hungarian flag has three horizontal stripes: red, white, and green. Red represents strength, white symbolizes faithfulness, and green stands for hope.",
            "RO": "The Romanian flag has three vertical stripes: blue, yellow, and red. Blue represents the sky, yellow symbolizes the fields, and red stands for the blood of heroes.",
            "BG": "The Bulgarian flag has three horizontal stripes: white, green, and red. White represents peace, green symbolizes the forests and agriculture, red stands for the blood of freedom fighters.",
            "HR": "The Croatian flag features red, white, and blue horizontal stripes with the national coat of arms in the center, displaying the historic Croatian checkerboard pattern.",
            "RS": "The Serbian flag has three horizontal stripes: red, blue, and white, with the national coat of arms slightly offset to the hoist. The colors represent Pan-Slavic unity.",
            "IL": "The Israeli flag features a blue Star of David between two horizontal blue stripes on a white background. The design represents the Jewish prayer shawl and the connection to the land.",
            "SA": "The Saudi Arabian flag is green with white Arabic script and a sword. The script is the Shahada (Islamic declaration of faith), and green is the traditional color of Islam.",
            "AE": "The UAE flag has four colors: red, green, white, and black. These Pan-Arab colors represent unity among Arab nations, with each emirate contributing to the federation.",
            "IR": "The Iranian flag has three horizontal stripes: green, white, and red. Green represents Islam, white symbolizes peace, and red stands for courage. The center features the national emblem.",
            "PK": "The Pakistani flag has a green field with a white crescent and star. Green represents Islam and the Muslim majority, white symbolizes religious minorities, and the crescent and star are Islamic symbols.",
            "BD": "The Bangladeshi flag features a red circle on a green field. The red circle represents the sun rising over Bengal and the blood of martyrs, green symbolizes the lush landscape.",
            "VN": "The Vietnamese flag has a red field with a yellow five-pointed star in the center. Red represents revolution and blood, yellow symbolizes the Vietnamese people, and the star represents unity.",
            "ID": "The Indonesian flag has two equal horizontal stripes: red on top and white below. Red represents courage and independence, white symbolizes purity and peace.",
            "PH": "The Philippine flag has a blue stripe on top and red below, with a white triangle on the hoist containing a sun and three stars. Blue represents peace, red symbolizes courage.",
            "MY": "The Malaysian flag features 14 alternating red and white stripes with a blue canton containing a crescent and 14-pointed star. The stripes represent the 13 states and federal territories.",
            "SG": "The Singapore flag has two equal horizontal stripes: red on top and white below, with a white crescent and five stars in the upper hoist. Red represents universal brotherhood, white symbolizes purity.",
            "KR": "The South Korean flag, called Taegukgi, features a white field with a red and blue yin-yang symbol in the center, surrounded by four black trigrams representing the elements.",
            "NZ": "The New Zealand flag is blue with the Union Jack in the canton and four red stars with white borders representing the Southern Cross constellation.",
            "CL": "The Chilean flag has two horizontal stripes: white on top and red below, with a blue square in the upper hoist containing a white five-pointed star. The star represents progress and honor."
        ]
        return descriptions[code] ?? "The national flag represents the country's identity, history, and values. Each color and symbol has special meaning for the nation."
    }
    
    private func getAnthemDescription(for code: String, language: String) -> String {
        switch language {
        case "ru":
            return getRussianAnthemDescription(for: code)
        case "es":
            return getSpanishAnthemDescription(for: code)
        case "uk":
            return getUkrainianAnthemDescription(for: code)
        case "ca":
            return getCatalanAnthemDescription(for: code)
        case "zh":
            return getChineseAnthemDescription(for: code)
        default:
            return getEnglishAnthemDescription(for: code)
        }
    }
    
    private func getAnthemMeaning(for code: String, language: String) -> String {
        switch language {
        case "ru":
            return getRussianAnthemMeaning(for: code)
        case "es":
            return getSpanishAnthemMeaning(for: code)
        case "uk":
            return getUkrainianAnthemMeaning(for: code)
        case "ca":
            return getCatalanAnthemMeaning(for: code)
        case "zh":
            return getChineseAnthemMeaning(for: code)
        default:
            return getEnglishAnthemMeaning(for: code)
        }
    }
    
    private func getAnthemText(for code: String, language: String) -> String {
        switch language {
        case "ru":
            return getRussianAnthemText(for: code)
        case "es":
            return getSpanishAnthemText(for: code)
        case "uk":
            return getUkrainianAnthemText(for: code)
        case "ca":
            return getCatalanAnthemText(for: code)
        case "zh":
            return getChineseAnthemText(for: code)
        default:
            return getEnglishAnthemText(for: code)
        }
    }
    
    // MARK: - Anthem Descriptions (English)
    private func getEnglishAnthemDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "PL": "The Polish national anthem 'Mazurek Dąbrowskiego' (Poland Is Not Yet Lost) was written in 1797 and became the official anthem in 1926. It expresses hope for Poland's independence.",
            "NL": "The Dutch national anthem 'Wilhelmus' is one of the oldest anthems in the world, dating back to the 16th century. It tells the story of William of Orange.",
            "BE": "The Belgian national anthem 'La Brabançonne' was written during the Belgian Revolution of 1830. It celebrates the country's independence and unity.",
            "CH": "The Swiss national anthem 'Swiss Psalm' was adopted in 1981. It praises Switzerland's natural beauty and the unity of its diverse regions.",
            "SE": "The Swedish national anthem 'Du gamla, Du fria' (Thou ancient, Thou free) was written in 1844. It celebrates Sweden's natural beauty and freedom.",
            "NO": "The Norwegian national anthem 'Ja, vi elsker dette landet' (Yes, we love this country) was written in 1859. It expresses deep love for Norway's landscapes and people.",
            "DK": "The Danish national anthem 'Der er et yndigt land' (There is a lovely land) was written in 1819. It celebrates Denmark's natural beauty and peaceful character.",
            "FI": "The Finnish national anthem 'Maamme' (Our Land) was written in 1848. It expresses love for Finland's nature and the Finnish people.",
            "PT": "The Portuguese national anthem 'A Portuguesa' was written in 1890. It celebrates Portugal's maritime history and national pride.",
            "IE": "The Irish national anthem 'Amhrán na bhFiann' (The Soldier's Song) was written in 1907. It became the official anthem in 1926, celebrating Irish independence.",
            "CZ": "The Czech national anthem consists of two parts: 'Kde domov můj' (Where is my home) and 'Nad Tatrou sa blýska' (Lightning over the Tatras). Both celebrate the Czech homeland.",
            "HU": "The Hungarian national anthem 'Himnusz' was written in 1823. It is a prayer for God's blessing on Hungary and its people.",
            "RO": "The Romanian national anthem 'Deșteaptă-te, române!' (Awaken thee, Romanian!) was written in 1848. It calls for unity and freedom.",
            "BG": "The Bulgarian national anthem 'Mila Rodino' (Dear Motherland) was written in 1885. It expresses love for Bulgaria's mountains and valleys.",
            "HR": "The Croatian national anthem 'Lijepa naša domovino' (Our Beautiful Homeland) was written in 1835. It celebrates Croatia's natural beauty.",
            "RS": "The Serbian national anthem 'Bože pravde' (God of Justice) was written in 1872. It is a prayer for Serbia's prosperity and unity.",
            "IL": "The Israeli national anthem 'Hatikvah' (The Hope) was written in 1878. It expresses the Jewish people's hope for a homeland in Israel.",
            "SA": "The Saudi Arabian national anthem 'Aash Al Maleek' (Long Live the King) was adopted in 1950. It praises the king and the country.",
            "AE": "The UAE national anthem 'Ishy Bilady' (Long Live My Country) was adopted in 1971. It celebrates the unity of the seven emirates.",
            "IR": "The Iranian national anthem 'Soroud-e Melli-e Jomhouri-e Eslami' was adopted in 1990. It celebrates the Islamic Revolution and Iran's independence.",
            "PK": "The Pakistani national anthem 'Qaumi Taranah' was written in 1954. It praises Pakistan's natural beauty and Islamic values.",
            "BD": "The Bangladeshi national anthem 'Amar Sonar Bangla' (My Golden Bengal) was written by Rabindranath Tagore in 1905. It celebrates Bengal's natural beauty.",
            "VN": "The Vietnamese national anthem 'Tiến Quân Ca' (Marching Song) was written in 1944. It became the official anthem in 1976, celebrating Vietnam's independence.",
            "ID": "The Indonesian national anthem 'Indonesia Raya' (Great Indonesia) was written in 1928. It became the official anthem in 1945, celebrating Indonesia's unity.",
            "PH": "The Philippine national anthem 'Lupang Hinirang' (Chosen Land) was written in 1898. It celebrates the Philippines' natural beauty and independence.",
            "MY": "The Malaysian national anthem 'Negaraku' (My Country) was adopted in 1957. It celebrates Malaysia's unity and diversity.",
            "SG": "The Singaporean national anthem 'Majulah Singapura' (Onward Singapore) was written in 1958. It became the official anthem in 1965, encouraging progress.",
            "KR": "The South Korean national anthem 'Aegukga' (Patriotic Song) was written in the late 19th century. It celebrates Korea's history and natural beauty.",
            "NZ": "The New Zealand national anthem 'God Defend New Zealand' was written in 1876. It became one of two official anthems in 1977, praising New Zealand's natural beauty.",
            "CL": "The Chilean national anthem 'Himno Nacional de Chile' was written in 1819. It celebrates Chile's independence and natural beauty."
        ]
        return descriptions[code] ?? "The national anthem is a symbol of national pride and unity, representing the country's history and aspirations."
    }
    
    // MARK: - Anthem Meanings (English)
    private func getEnglishAnthemMeaning(for code: String) -> String {
        let meanings: [String: String] = [
            "PL": "The anthem expresses the Polish people's determination to maintain their national identity and hope for independence, even during times of foreign occupation.",
            "NL": "The anthem tells the story of William of Orange, who led the Dutch struggle for independence from Spain, symbolizing Dutch resilience and freedom.",
            "BE": "The anthem celebrates Belgium's independence from the Netherlands and the unity of its French, Dutch, and German-speaking communities.",
            "CH": "The anthem emphasizes Switzerland's natural beauty, from mountains to lakes, and the unity of its diverse linguistic and cultural regions.",
            "SE": "The anthem celebrates Sweden's natural landscapes, from northern mountains to southern plains, and the Swedish people's love for freedom.",
            "NO": "The anthem expresses deep love for Norway's fjords, mountains, and people, celebrating the country's independence and natural beauty.",
            "DK": "The anthem celebrates Denmark's peaceful character, beautiful landscapes, and the Danish people's connection to their homeland.",
            "FI": "The anthem expresses love for Finland's lakes, forests, and northern lights, celebrating the Finnish people's resilience and independence.",
            "PT": "The anthem celebrates Portugal's maritime history, its explorers, and the Portuguese people's courage and national pride.",
            "IE": "The anthem celebrates Ireland's struggle for independence and the Irish people's determination to be free, expressing hope for a united Ireland.",
            "CZ": "The anthem celebrates the Czech homeland's beauty, from Bohemian forests to Moravian fields, expressing love for the Czech people and their traditions.",
            "HU": "The anthem is a prayer asking God to bless Hungary, protect its people, and grant prosperity to the nation.",
            "RO": "The anthem calls for Romanians to awaken and unite, celebrating the country's independence and the Romanian people's courage.",
            "BG": "The anthem expresses deep love for Bulgaria's mountains, valleys, and the Bulgarian people, celebrating the country's natural beauty.",
            "HR": "The anthem celebrates Croatia's Adriatic coast, mountains, and the Croatian people's love for their beautiful homeland.",
            "RS": "The anthem is a prayer for Serbia's prosperity, unity, and God's protection, celebrating the Serbian people's resilience.",
            "IL": "The anthem expresses the Jewish people's 2000-year hope to return to their ancestral homeland in Israel, celebrating Jewish identity and freedom.",
            "SA": "The anthem praises the Saudi king and celebrates the country's Islamic values, unity, and prosperity.",
            "AE": "The anthem celebrates the unity of the seven emirates, their progress, and the UAE's role as a modern Arab nation.",
            "IR": "The anthem celebrates the Islamic Revolution, Iran's independence, and the Iranian people's commitment to Islamic values.",
            "PK": "The anthem celebrates Pakistan's natural beauty, from mountains to plains, and the country's Islamic identity and values.",
            "BD": "The anthem expresses love for Bengal's rivers, fields, and people, celebrating the region's natural beauty and cultural heritage.",
            "VN": "The anthem celebrates Vietnam's struggle for independence, the Vietnamese people's determination, and the country's unity.",
            "ID": "The anthem celebrates Indonesia's unity across its thousands of islands, expressing hope for a great and united Indonesia.",
            "PH": "The anthem celebrates the Philippines' natural beauty, from mountains to seas, and the Filipino people's love for their chosen land.",
            "MY": "The anthem celebrates Malaysia's unity despite its diversity, expressing hope for the country's prosperity and progress.",
            "SG": "The anthem encourages Singaporeans to progress forward together, celebrating the nation's unity, diversity, and determination to succeed.",
            "KR": "The anthem celebrates Korea's 5000-year history, its natural beauty, and the Korean people's love for their homeland.",
            "NZ": "The anthem celebrates New Zealand's natural beauty, from mountains to seas, and asks God to protect and defend the nation.",
            "CL": "The anthem celebrates Chile's independence, its natural beauty from the Atacama Desert to Patagonia, and the Chilean people's courage."
        ]
        return meanings[code] ?? "The anthem celebrates the country's natural beauty, cultural heritage, and the unity of its people."
    }
    
    private func getDefaultPhotos(for code: String) -> [String] {
        // Базовые фотографии для всех стран
        return ["flag", "landmark1", "landmark2", "landmark3", "landmark4"]
    }
    
    private func getInterestingFacts(for code: String, language: String) -> [String] {
        // Реальные интересные факты для каждой страны
        switch language {
        case "ru":
            return getRussianFacts(for: code)
        case "es":
            return getSpanishFacts(for: code)
        case "uk":
            return getUkrainianFacts(for: code)
        case "ca":
            return getCatalanFacts(for: code)
        case "zh":
            return getChineseFacts(for: code)
        default:
            return getEnglishFacts(for: code)
        }
    }
    
    private func getEnglishFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": [
                "Austria is known as the birthplace of classical music - Mozart, Beethoven, Schubert and Strauss were born here.",
                "Vienna has been ranked as the world's most livable city for several years in a row.",
                "Austria is home to the world's oldest zoo - Schönbrunn Zoo, founded in 1752."
            ],
            "US": [
                "The United States has no official language at the federal level, though English is the most commonly spoken.",
                "Alaska was purchased from Russia in 1867 for $7.2 million, which equals about 2 cents per acre.",
                "The US has the world's largest economy and is home to more than 400 national parks."
            ],
            "GB": [
                "The UK is made up of four countries: England, Scotland, Wales, and Northern Ireland.",
                "London's Big Ben is not actually the name of the clock tower - it's the name of the largest bell inside.",
                "The UK has more than 1,500 castles, many of which are still inhabited today."
            ],
            "FR": [
                "France is the most visited country in the world, with over 89 million tourists annually.",
                "The Eiffel Tower was originally intended to be temporary and was almost demolished in 1909.",
                "France has won the most Nobel Prizes for Literature of any country - 16 awards."
            ],
            "DE": [
                "Germany has over 1,500 breweries and is famous for its beer purity law from 1516.",
                "The fall of the Berlin Wall in 1989 marked the beginning of German reunification.",
                "Germany is Europe's economic powerhouse and the world's fourth-largest economy."
            ],
            "IT": [
                "Italy has more UNESCO World Heritage Sites than any other country - 58 sites.",
                "The Roman Colosseum could hold up to 80,000 spectators and had a sophisticated drainage system.",
                "Italy is home to three active volcanoes: Vesuvius, Etna, and Stromboli."
            ],
            "ES": [
                "Spain has the second-highest number of UNESCO World Heritage Sites after Italy.",
                "The Spanish language is spoken by over 500 million people worldwide.",
                "Spain produces about 45% of the world's olive oil, mostly from Andalusia."
            ],
            "JP": [
                "Japan consists of 6,852 islands, though only about 430 are inhabited.",
                "The Japanese writing system uses three different scripts: Hiragana, Katakana, and Kanji.",
                "Japan has one of the world's longest life expectancies and lowest crime rates."
            ],
            "CN": [
                "The Great Wall of China is not visible from space with the naked eye, contrary to popular belief.",
                "China has 56 recognized ethnic groups, with Han Chinese making up about 92% of the population.",
                "China is the world's largest producer of rice, wheat, and many other agricultural products."
            ],
            "RU": [
                "Russia spans 11 time zones, more than any other country in the world.",
                "The Trans-Siberian Railway is the longest railway line in the world at 9,289 kilometers.",
                "Russia has the world's largest forest reserves and contains about 25% of the world's fresh water."
            ],
            "BR": [
                "The Amazon rainforest in Brazil produces about 20% of the world's oxygen.",
                "Brazil is the largest country in South America, covering almost half the continent.",
                "Brazilian Carnival in Rio de Janeiro is one of the world's largest festivals."
            ],
            "CA": [
                "Canada has two official languages: English and French.",
                "Canada has the longest coastline of any country in the world - 243,042 kilometers.",
                "The name 'Canada' comes from the Huron-Iroquois word 'kanata' meaning village."
            ],
            "AU": [
                "Australia is the only country that is also a continent.",
                "About 80% of Australia's animals are found nowhere else in the world.",
                "The Great Barrier Reef is the world's largest living structure, visible from space."
            ],
            "IN": [
                "India has 22 official languages and over 1,600 spoken languages.",
                "The Indian film industry produces more movies than Hollywood.",
                "India is the birthplace of four major world religions: Hinduism, Buddhism, Jainism, and Sikhism."
            ],
            "MX": [
                "Mexico gave the world chocolate, vanilla, and chili peppers.",
                "The ancient Mayan and Aztec civilizations built impressive pyramids that still stand today.",
                "Mexico City is built on a lake and is slowly sinking at a rate of 6-8 inches per year."
            ],
            "EG": [
                "The Great Pyramid of Giza was the tallest man-made structure for over 3,800 years.",
                "Ancient Egyptians invented paper, ink, and the 365-day calendar.",
                "The Nile River is the longest river in the world at 6,650 kilometers."
            ],
            "GR": [
                "Greece is considered the birthplace of democracy, philosophy, and the Olympic Games.",
                "Greece has over 6,000 islands, but only about 200 are inhabited.",
                "The Greek alphabet has been used for over 2,700 years and influenced many other writing systems."
            ],
            "TR": [
                "Turkey is located on two continents: Europe and Asia, separated by the Bosphorus strait.",
                "The ancient city of Troy, famous from Homer's Iliad, is located in modern-day Turkey.",
                "Turkey is the world's largest producer of hazelnuts, providing about 70% of global supply."
            ],
            "TH": [
                "Thailand is the only Southeast Asian country never to have been colonized by Europeans.",
                "Thai cuisine is known worldwide for its balance of sweet, sour, salty, and spicy flavors.",
                "Thailand is home to the world's smallest mammal, the bumblebee bat, and the largest fish, the whale shark."
            ],
            "AR": [
                "Argentina is famous for tango dance, which originated in Buenos Aires in the late 19th century.",
                "Argentina is the world's second-largest country in South America and eighth-largest in the world.",
                "The country is renowned for its beef production and wine, especially Malbec."
            ],
            "ZA": [
                "South Africa has 11 official languages, more than any other country.",
                "It's the only country to voluntarily dismantle its nuclear weapons program.",
                "South Africa is home to the world's largest diamond mine and produces about 15% of the world's gold."
            ],
            "PL": [
                "Poland is home to the world's largest castle by land area - Malbork Castle, built by the Teutonic Knights.",
                "Poland has produced more Nobel Prize winners per capita than any other country in Central and Eastern Europe.",
                "The Polish language has the second-largest number of speakers among Slavic languages, after Russian."
            ],
            "NL": [
                "The Netherlands has more museums per square kilometer than any other country in the world.",
                "About 26% of the Netherlands is below sea level, protected by an elaborate system of dikes and pumps.",
                "The Netherlands is the world's second-largest exporter of agricultural products, despite its small size."
            ],
            "BE": [
                "Belgium produces over 220,000 tons of chocolate per year, making it one of the world's largest chocolate producers.",
                "Belgium has the highest number of castles per square kilometer in the world.",
                "The Belgian city of Antwerp is the world's diamond capital, handling 84% of the world's rough diamonds."
            ],
            "CH": [
                "Switzerland has four official languages: German, French, Italian, and Romansh.",
                "Switzerland has one of the highest gun ownership rates in the world, yet one of the lowest crime rates.",
                "The Swiss consume more chocolate per capita than any other nation - about 19 pounds per person per year."
            ],
            "SE": [
                "Sweden has the highest number of patents per capita in Europe and is home to companies like IKEA, Volvo, and Spotify.",
                "Sweden was the first country in the world to ban corporal punishment of children in 1979.",
                "Sweden has over 95,000 lakes and is covered by about 69% forest."
            ],
            "NO": [
                "Norway has the longest road tunnel in the world - the Lærdal Tunnel, stretching 24.5 kilometers.",
                "Norway has one of the highest standards of living in the world and ranks consistently high in happiness indexes.",
                "The Norwegian fjords are among the deepest in the world, with Sognefjord reaching depths of over 1,300 meters."
            ],
            "DK": [
                "Denmark consistently ranks as one of the happiest countries in the world according to the World Happiness Report.",
                "Denmark has over 7,000 kilometers of coastline despite being a relatively small country.",
                "The Danish concept of 'hygge' (coziness and contentment) has become internationally recognized as a lifestyle philosophy."
            ],
            "FI": [
                "Finland has more saunas than cars - there are over 3 million saunas for a population of 5.5 million.",
                "Finland has been ranked as the world's happiest country multiple times by the World Happiness Report.",
                "Finland is home to Santa Claus Village in Rovaniemi, located in Lapland, the official home of Santa Claus."
            ],
            "PT": [
                "Portugal is the oldest nation-state in Europe, with its borders remaining unchanged since 1249.",
                "Portugal is the world's largest cork producer, producing about 50% of the world's cork supply.",
                "The Portuguese language is spoken by over 260 million people worldwide, making it the 6th most spoken language."
            ],
            "IE": [
                "Ireland has the highest number of red-haired people per capita in the world - about 10% of the population.",
                "Ireland is the only country in the world with a musical instrument (the harp) as its national symbol.",
                "Ireland has more Nobel Prize winners per capita in literature than any other country."
            ],
            "CZ": [
                "The Czech Republic consumes more beer per capita than any other country in the world - about 143 liters per person annually.",
                "Prague Castle is the largest ancient castle in the world, covering an area of almost 70,000 square meters.",
                "The Czech Republic has one of the densest railway networks in the world."
            ],
            "HU": [
                "Hungary has the highest number of thermal springs in Europe, with over 1,000 natural thermal springs.",
                "Hungary invented many things including the ballpoint pen, the Rubik's Cube, and vitamin C.",
                "Hungary has 13 Nobel Prize winners, more than China, India, or Australia."
            ],
            "RO": [
                "Romania is home to the largest population of brown bears in Europe outside of Russia.",
                "Romania has the fastest internet speeds in Europe and one of the fastest in the world.",
                "The Romanian language is the only Romance language in Eastern Europe."
            ],
            "BG": [
                "Bulgaria is one of the oldest countries in Europe, founded in 681 AD.",
                "Bulgaria is the world's second-largest producer of rose oil, used in perfumes worldwide.",
                "The Cyrillic alphabet, used by many Slavic languages, was invented in Bulgaria."
            ],
            "HR": [
                "Croatia has over 1,000 islands along its Adriatic coast, though only about 50 are inhabited.",
                "Croatia is home to the world's smallest town - Hum, with a population of about 20 people.",
                "The necktie (cravat) originated in Croatia and was named after the Croatian word 'Hrvat'."
            ],
            "RS": [
                "Serbia is one of the largest producers of raspberries in the world, producing about 30% of global supply.",
                "Serbia has five national parks covering about 5% of the country's territory.",
                "The Serbian language uses both Cyrillic and Latin alphabets officially."
            ],
            "IL": [
                "Israel has the highest number of museums per capita in the world.",
                "Israel is the only country in the world that has more trees today than it had 100 years ago.",
                "Israel has the highest number of startups per capita in the world and is known as the 'Startup Nation'."
            ],
            "SA": [
                "Saudi Arabia has no rivers, but it has the world's largest continuous sand desert - the Rub' al Khali.",
                "Saudi Arabia is the world's largest oil producer and exporter.",
                "Mecca, located in Saudi Arabia, is the holiest city in Islam and receives millions of pilgrims annually."
            ],
            "AE": [
                "The UAE has the world's tallest building - the Burj Khalifa in Dubai, standing at 828 meters.",
                "The UAE is building a city on Mars by 2117 as part of its Mars 2117 project.",
                "Dubai has the world's largest shopping mall - the Dubai Mall, covering over 1.1 million square meters."
            ],
            "IR": [
                "Iran has one of the oldest continuous civilizations in the world, dating back over 5,000 years.",
                "Iran is home to one of the world's oldest continuously inhabited cities - Susa, dating back to 4200 BC.",
                "Persian (Farsi) is spoken by over 110 million people worldwide and has influenced many languages including English."
            ],
            "PK": [
                "Pakistan is home to the world's second-highest mountain - K2, standing at 8,611 meters.",
                "Pakistan has the world's largest irrigation system, with over 60,000 kilometers of canals.",
                "Pakistan is one of only seven countries in the world with nuclear weapons."
            ],
            "BD": [
                "Bangladesh has the world's largest river delta - the Ganges-Brahmaputra Delta.",
                "Bangladesh is the world's second-largest producer of jute and garments.",
                "Despite being one of the most densely populated countries, Bangladesh has made remarkable progress in reducing poverty."
            ],
            "VN": [
                "Vietnam has the world's largest cave - Son Doong Cave, large enough to fit a 40-story building inside.",
                "Vietnam is the world's second-largest coffee producer after Brazil.",
                "Vietnam has over 3,000 kilometers of coastline and thousands of islands."
            ],
            "ID": [
                "Indonesia is the world's largest archipelago, consisting of over 17,000 islands.",
                "Indonesia is home to the world's largest Muslim population, with over 230 million Muslims.",
                "Indonesia has the world's highest number of active volcanoes - about 127."
            ],
            "PH": [
                "The Philippines consists of over 7,600 islands, making it one of the world's largest archipelagos.",
                "The Philippines is the world's largest producer of coconuts.",
                "Filipino (Tagalog) is one of the most widely spoken languages in the world, with over 100 million speakers."
            ],
            "MY": [
                "Malaysia is one of the world's most biodiverse countries, home to about 20% of the world's animal species.",
                "Malaysia has the world's largest flower - the Rafflesia, which can grow up to 1 meter in diameter.",
                "Malaysia is one of the world's leading producers of palm oil, rubber, and tin."
            ],
            "SG": [
                "Singapore is one of only three surviving city-states in the world, along with Monaco and Vatican City.",
                "Singapore has one of the world's busiest ports and is a major global financial center.",
                "Singapore has four official languages: English, Malay, Mandarin, and Tamil."
            ],
            "KR": [
                "South Korea has the world's fastest average internet speeds and highest smartphone penetration rate.",
                "South Korea is home to companies like Samsung, Hyundai, and LG, which are global leaders in technology.",
                "South Korea has one of the world's most advanced education systems and highest literacy rates."
            ],
            "NZ": [
                "New Zealand has more sheep than people - about 6 sheep per person.",
                "New Zealand was the first country to give women the right to vote in 1893.",
                "New Zealand has no native land mammals except for bats, making it a unique ecosystem."
            ],
            "CL": [
                "Chile is the world's longest country from north to south, stretching over 4,300 kilometers.",
                "Chile is the world's largest producer of copper, accounting for about one-third of global production.",
                "Chile's Atacama Desert is the driest place on Earth, with some areas receiving no rainfall for decades."
            ]
        ]
        
        return facts[code] ?? [
            "This country has a rich and fascinating history.",
            "The local culture and traditions are unique and diverse.",
            "This nation has made significant contributions to world civilization."
        ]
    }
    
    private func getRussianFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": ["Австрия известна как родина классической музыки — здесь родились Моцарт, Бетховен, Шуберт и Штраус.", "Вена несколько лет подряд признавалась самым пригодным для жизни городом в мире.", "В Австрии находится старейший зоопарк мира — Шёнбруннский зоопарк (1752)."],
            "US": ["В США нет официального языка на федеральном уровне, хотя английский наиболее распространён.", "Аляска была куплена у России в 1867 году за 7,2 млн долларов.", "В США более 400 национальных парков и крупнейшая экономика мира."],
            "GB": ["Великобритания состоит из четырёх стран: Англия, Шотландия, Уэльс и Северная Ирландия.", "Биг-Бен — это название колокола, а не башни с часами.", "В Великобритании более 1500 замков, многие до сих пор обитаемы."],
            "FR": ["Франция — самая посещаемая страна мира (свыше 89 млн туристов в год).", "Эйфелеву башню планировали как временную и чуть не снесли в 1909 году.", "Франция получила больше всего Нобелевских премий по литературе — 16."],
            "DE": ["В Германии более 1500 пивоварен и знаменитый закон о чистоте пива 1516 года.", "Падение Берлинской стены в 1989 году положило начало объединению Германии.", "Германия — локомотив экономики Европы и четвёртая экономика мира."],
            "IT": ["В Италии больше объектов Всемирного наследия ЮНЕСКО, чем в любой другой стране — 58.", "Колизей вмещал до 80 000 зрителей и имел продуманную дренажную систему.", "В Италии три действующих вулкана: Везувий, Этна и Стромболи."],
            "ES": ["Испания на втором месте по числу объектов ЮНЕСКО после Италии.", "На испанском говорят более 500 млн человек в мире.", "Испания производит около 45% мирового оливкового масла, в основном в Андалусии."],
            "JP": ["Япония состоит из 6852 островов, из них обитаемы около 430.", "В японской письменности используются три системы: хирагана, катакана и кандзи.", "В Японии одна из самых высоких в мире продолжительность жизни и низкая преступность."],
            "CN": ["Великую Китайскую стену не видно из космоса невооружённым глазом.", "В Китае 56 признанных народов; ханьцы составляют около 92% населения.", "Китай — крупнейший в мире производитель риса, пшеницы и многих других сельхозкультур."],
            "RU": ["Россия занимает 11 часовых поясов — больше, чем любая другая страна.", "Транссибирская магистраль — самая длинная железная дорога в мире (9289 км).", "В России крупнейшие в мире лесные запасы и около 25% мировых запасов пресной воды."],
            "BR": ["Амазонские леса в Бразилии производят около 20% мирового кислорода.", "Бразилия — крупнейшая страна Южной Америки, занимает почти половину континента.", "Карнавал в Рио-де-Жанейро — один из крупнейших фестивалей мира."],
            "CA": ["В Канаде два государственных языка: английский и французский.", "У Канады самая длинная береговая линия в мире — 243 042 км.", "Название «Канада» происходит от слова «каната» на языке гуронов — «деревня»."],
            "AU": ["Австралия — единственная страна, являющаяся и континентом.", "Около 80% австралийских животных не встречаются больше нигде в мире.", "Большой Барьерный риф — крупнейшая живая структура на Земле, видна из космоса."],
            "IN": ["В Индии 22 официальных языка и более 1600 разговорных.", "Индийский кинематограф производит больше фильмов, чем Голливуд.", "Индия — родина четырёх крупных мировых религий: индуизма, буддизма, джайнизма и сикхизма."],
            "MX": ["Мексика подарила миру шоколад, ваниль и перец чили.", "Древние майя и ацтеки строили впечатляющие пирамиды, многие стоят до сих пор.", "Мехико построен на озере и постепенно проседает на 15–20 см в год."],
            "EG": ["Пирамида Хеопса была высочайшим рукотворным сооружением более 3800 лет.", "Древние египтяне изобрели бумагу, чернила и 365-дневный календарь.", "Нил — самая длинная река в мире (6650 км)."],
            "GR": ["Греция считается родиной демократии, философии и Олимпийских игр.", "В Греции более 6000 островов, обитаемы около 200.", "Греческий алфавит используется более 2700 лет и повлиял на многие письменности."],
            "TR": ["Турция расположена на двух континентах: Европа и Азия (разделены Босфором).", "Древняя Троя из «Илиады» Гомера находилась на территории современной Турции.", "Турция — крупнейший в мире производитель фундука (около 70% мирового урожая)."],
            "TH": ["Таиланд — единственная страна Юго-Восточной Азии, не бывшая колонией европейцев.", "Тайская кухня известна балансом сладкого, кислого, солёного и острого.", "В Таиланде обитают самая маленькая летучая мышь (свиноносая) и крупнейшая рыба (китовая акула)."],
            "AR": ["Аргентина славится танго, зародившимся в Буэнос-Айресе в конце XIX века.", "Аргентина — вторая по площади страна Южной Америки и восьмая в мире.", "Страна известна производством говядины и вина, особенно мальбека."],
            "ZA": ["В ЮАР 11 государственных языков — больше, чем в любой другой стране.", "ЮАР — единственная страна, добровольно отказавшаяся от ядерного оружия.", "В ЮАР находится крупнейший в мире алмазный рудник; страна даёт около 15% мировой добычи золота."],
            "PL": ["В Польше находится крупнейший по площади замок в мире — Мальборкский замок, построенный тевтонскими рыцарями.", "Польша произвела больше лауреатов Нобелевской премии на душу населения, чем любая другая страна Центральной и Восточной Европы.", "Польский язык занимает второе место по числу носителей среди славянских языков после русского."],
            "NL": ["В Нидерландах больше музеев на квадратный километр, чем в любой другой стране мира.", "Около 26% территории Нидерландов находится ниже уровня моря, защищено сложной системой дамб и насосов.", "Нидерланды — второй по величине экспортёр сельскохозяйственной продукции в мире, несмотря на малый размер."],
            "BE": ["Бельгия производит более 220 000 тонн шоколада в год, что делает её одним из крупнейших производителей шоколада в мире.", "В Бельгии самое большое количество замков на квадратный километр в мире.", "Бельгийский город Антверпен — мировая столица алмазов, обрабатывающая 84% мировых необработанных алмазов."],
            "CH": ["В Швейцарии четыре официальных языка: немецкий, французский, итальянский и ретороманский.", "В Швейцарии один из самых высоких показателей владения оружием в мире, но один из самых низких уровней преступности.", "Швейцарцы потребляют больше шоколада на душу населения, чем любая другая нация — около 8,6 кг на человека в год."],
            "SE": ["В Швеции самое большое количество патентов на душу населения в Европе; здесь базируются компании IKEA, Volvo и Spotify.", "Швеция стала первой страной в мире, запретившей телесные наказания детей в 1979 году.", "В Швеции более 95 000 озёр, и около 69% территории покрыто лесами."],
            "NO": ["В Норвегии самый длинный автомобильный туннель в мире — туннель Лердал, протяжённостью 24,5 километра.", "В Норвегии один из самых высоких уровней жизни в мире, страна стабильно занимает высокие места в рейтингах счастья.", "Норвежские фьорды — одни из самых глубоких в мире; Согне-фьорд достигает глубины более 1300 метров."],
            "DK": ["Дания стабильно входит в число самых счастливых стран мира согласно Всемирному докладу о счастье.", "У Дании более 7000 километров береговой линии, несмотря на относительно небольшой размер страны.", "Датская концепция 'хюгге' (уют и удовлетворённость) получила международное признание как философия образа жизни."],
            "FI": ["В Финляндии больше саун, чем автомобилей — более 3 миллионов саун на население 5,5 миллионов человек.", "Финляндия неоднократно признавалась самой счастливой страной мира по Всемирному докладу о счастье.", "В Финляндии находится Деревня Санта-Клауса в Рованиеми, расположенная в Лапландии — официальном доме Санта-Клауса."],
            "PT": ["Португалия — старейшее национальное государство в Европе, её границы остаются неизменными с 1249 года.", "Португалия — крупнейший производитель пробки в мире, производящий около 50% мировых поставок пробки.", "На португальском языке говорят более 260 миллионов человек по всему миру, что делает его 6-м по распространённости языком."],
            "IE": ["В Ирландии самое большое количество рыжеволосых людей на душу населения в мире — около 10% населения.", "Ирландия — единственная страна в мире, у которой музыкальный инструмент (арфа) является национальным символом.", "В Ирландии больше лауреатов Нобелевской премии по литературе на душу населения, чем в любой другой стране."],
            "CZ": ["Чехия потребляет больше пива на душу населения, чем любая другая страна в мире — около 143 литров на человека в год.", "Пражский Град — крупнейший древний замок в мире, занимающий площадь почти 70 000 квадратных метров.", "В Чехии одна из самых плотных железнодорожных сетей в мире."],
            "HU": ["В Венгрии самое большое количество термальных источников в Европе — более 1000 природных термальных источников.", "Венгрия изобрела многие вещи, включая шариковую ручку, кубик Рубика и витамин C.", "В Венгрии 13 лауреатов Нобелевской премии — больше, чем в Китае, Индии или Австралии."],
            "RO": ["В Румынии самая большая популяция бурых медведей в Европе за пределами России.", "В Румынии самые быстрые скорости интернета в Европе и одни из самых быстрых в мире.", "Румынский язык — единственный романский язык в Восточной Европе."],
            "BG": ["Болгария — одна из старейших стран Европы, основанная в 681 году нашей эры.", "Болгария — второй по величине производитель розового масла в мире, используемого в парфюмерии по всему миру.", "Кириллица, используемая многими славянскими языками, была изобретена в Болгарии."],
            "HR": ["В Хорватии более 1000 островов вдоль её адриатического побережья, хотя обитаемы только около 50.", "В Хорватии находится самый маленький город в мире — Хум, с населением около 20 человек.", "Галстук (крават) возник в Хорватии и был назван в честь хорватского слова 'Хрват'."],
            "RS": ["Сербия — один из крупнейших производителей малины в мире, производящий около 30% мировых поставок.", "В Сербии пять национальных парков, покрывающих около 5% территории страны.", "Сербский язык официально использует как кириллицу, так и латиницу."],
            "IL": ["В Израиле самое большое количество музеев на душу населения в мире.", "Израиль — единственная страна в мире, где сегодня больше деревьев, чем было 100 лет назад.", "В Израиле самое большое количество стартапов на душу населения в мире, страна известна как 'Стартап-нация'."],
            "SA": ["В Саудовской Аравии нет рек, но здесь находится крупнейшая в мире непрерывная песчаная пустыня — Руб-эль-Хали.", "Саудовская Аравия — крупнейший производитель и экспортёр нефти в мире.", "Мекка, расположенная в Саудовской Аравии, — святейший город в исламе, ежегодно принимающий миллионы паломников."],
            "AE": ["В ОАЭ находится самое высокое здание в мире — Бурдж-Халифа в Дубае, высотой 828 метров.", "ОАЭ строят город на Марсе к 2117 году в рамках проекта Mars 2117.", "В Дубае находится крупнейший торговый центр в мире — Dubai Mall, площадью более 1,1 миллиона квадратных метров."],
            "IR": ["В Иране одна из старейших непрерывных цивилизаций в мире, насчитывающая более 5000 лет.", "В Иране находится один из старейших непрерывно населённых городов мира — Сузы, датируемый 4200 годом до нашей эры.", "На персидском (фарси) говорят более 110 миллионов человек по всему миру, он повлиял на многие языки, включая английский."],
            "PK": ["В Пакистане находится вторая по высоте гора в мире — К2, высотой 8611 метров.", "В Пакистане самая большая ирригационная система в мире, с более чем 60 000 километрами каналов.", "Пакистан — одна из семи стран в мире, обладающих ядерным оружием."],
            "BD": ["В Бангладеш самая большая речная дельта в мире — дельта Ганга-Брахмапутры.", "Бангладеш — второй по величине производитель джута и одежды в мире.", "Несмотря на то, что это одна из самых густонаселённых стран, Бангладеш добился значительного прогресса в сокращении бедности."],
            "VN": ["Во Вьетнаме находится самая большая пещера в мире — пещера Сон Донг, достаточно большая, чтобы внутри поместилось 40-этажное здание.", "Вьетнам — второй по величине производитель кофе в мире после Бразилии.", "Во Вьетнаме более 3000 километров береговой линии и тысячи островов."],
            "ID": ["Индонезия — крупнейший архипелаг в мире, состоящий из более чем 17 000 островов.", "В Индонезии самое большое мусульманское население в мире — более 230 миллионов мусульман.", "В Индонезии самое большое количество действующих вулканов в мире — около 127."],
            "PH": ["Филиппины состоят из более чем 7600 островов, что делает их одним из крупнейших архипелагов в мире.", "Филиппины — крупнейший производитель кокосов в мире.", "Филиппинский (тагальский) — один из самых распространённых языков в мире, на нём говорят более 100 миллионов человек."],
            "MY": ["Малайзия — одна из самых биоразнообразных стран мира, здесь обитает около 20% видов животных мира.", "В Малайзии растёт самый большой цветок в мире — раффлезия, который может достигать 1 метра в диаметре.", "Малайзия — один из ведущих производителей пальмового масла, каучука и олова в мире."],
            "SG": ["Сингапур — одно из трёх сохранившихся городов-государств в мире, наряду с Монако и Ватиканом.", "В Сингапуре один из самых загруженных портов в мире, и это крупный глобальный финансовый центр.", "В Сингапуре четыре официальных языка: английский, малайский, мандарин и тамильский."],
            "KR": ["В Южной Корее самые быстрые средние скорости интернета в мире и самый высокий уровень проникновения смартфонов.", "В Южной Корее базируются компании Samsung, Hyundai и LG, которые являются мировыми лидерами в области технологий.", "В Южной Корее одна из самых передовых систем образования в мире и самые высокие показатели грамотности."],
            "NZ": ["В Новой Зеландии больше овец, чем людей — около 6 овец на человека.", "Новая Зеландия стала первой страной, предоставившей женщинам право голоса в 1893 году.", "В Новой Зеландии нет местных наземных млекопитающих, кроме летучих мышей, что делает её уникальной экосистемой."],
            "CL": ["Чили — самая длинная страна в мире с севера на юг, протяжённостью более 4300 километров.", "Чили — крупнейший производитель меди в мире, на долю которого приходится около одной трети мирового производства.", "Пустыня Атакама в Чили — самое сухое место на Земле, некоторые районы не получают осадков десятилетиями."]
        ]
        return facts[code] ?? getEnglishFacts(for: code)
    }
    
    private func getSpanishFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": ["Austria es conocida como la cuna de la música clásica; Mozart, Beethoven, Schubert y Strauss nacieron aquí.", "Viena ha sido clasificada como la ciudad más habitable del mundo durante varios años consecutivos.", "Austria alberga el zoológico más antiguo del mundo, el Zoo de Schönbrunn, fundado en 1752."],
            "US": ["Estados Unidos no tiene idioma oficial a nivel federal, aunque el inglés es el más hablado.", "Alaska fue comprada a Rusia en 1867 por 7,2 millones de dólares.", "Estados Unidos tiene más de 400 parques nacionales y la economía más grande del mundo."],
            "GB": ["El Reino Unido está formado por cuatro países: Inglaterra, Escocia, Gales e Irlanda del Norte.", "Big Ben es el nombre de la campana, no de la torre del reloj.", "El Reino Unido tiene más de 1500 castillos, muchos aún habitados."],
            "FR": ["Francia es el país más visitado del mundo, con más de 89 millones de turistas al año.", "La Torre Eiffel fue concebida como temporal y casi fue demolida en 1909.", "Francia ha ganado más premios Nobel de Literatura que ningún otro país: 16."],
            "DE": ["Alemania tiene más de 1500 cervecerías y la famosa ley de pureza de la cerveza de 1516.", "La caída del Muro de Berlín en 1989 marcó el inicio de la reunificación alemana.", "Alemania es la locomotora económica de Europa y la cuarta economía mundial."],
            "IT": ["Italia tiene más sitios Patrimonio de la Humanidad de la UNESCO que ningún otro país: 58.", "El Coliseo podía albergar hasta 80 000 espectadores y tenía un sistema de drenaje sofisticado.", "Italia alberga tres volcanes activos: Vesubio, Etna y Stromboli."],
            "ES": ["España tiene el segundo mayor número de sitios UNESCO después de Italia.", "El español lo hablan más de 500 millones de personas en el mundo.", "España produce alrededor del 45% del aceite de oliva mundial, sobre todo en Andalucía."],
            "JP": ["Japón consta de 6852 islas, de las cuales unas 430 están habitadas.", "El sistema de escritura japonés usa tres scripts: hiragana, katakana y kanji.", "Japón tiene una de las esperanzas de vida más altas del mundo y una de las tasas de delincuencia más bajas."],
            "CN": ["La Gran Muralla China no es visible desde el espacio a simple vista, pese al mito.", "China tiene 56 grupos étnicos reconocidos; los han representan alrededor del 92% de la población.", "China es el mayor productor mundial de arroz, trigo y muchos otros productos agrícolas."],
            "RU": ["Rusia abarca 11 zonas horarias, más que ningún otro país.", "El Transiberiano es la línea ferroviaria más larga del mundo: 9289 km.", "Rusia tiene las mayores reservas forestales del mundo y alrededor del 25% del agua dulce mundial."],
            "BR": ["La selva amazónica en Brasil produce alrededor del 20% del oxígeno mundial.", "Brasil es el país más grande de Sudamérica y ocupa casi la mitad del continente.", "El Carnaval de Río de Janeiro es una de las mayores fiestas del mundo."],
            "CA": ["Canadá tiene dos idiomas oficiales: inglés y francés.", "Canadá tiene la costa más larga del mundo: 243 042 km.", "El nombre «Canadá» procede de la palabra hurón-iroquesa «kanata», que significa aldea."],
            "AU": ["Australia es el único país que es también un continente.", "Un 80% de los animales de Australia no se encuentran en ningún otro lugar del mundo.", "La Gran Barrera de Coral es la estructura viva más grande del mundo y es visible desde el espacio."],
            "IN": ["India tiene 22 idiomas oficiales y más de 1600 lenguas habladas.", "La industria cinematográfica india produce más películas que Hollywood.", "India es la cuna de cuatro grandes religiones: hinduismo, budismo, jainismo y sijismo."],
            "MX": ["México dio al mundo el chocolate, la vainilla y el chile.", "Las civilizaciones maya y azteca construyeron impresionantes pirámides que aún se mantienen.", "Ciudad de México está construida sobre un lago y se hunde unos 15–20 cm al año."],
            "EG": ["La Gran Pirámide de Giza fue la estructura artificial más alta durante más de 3800 años.", "Los antiguos egipcios inventaron el papel, la tinta y el calendario de 365 días.", "El Nilo es el río más largo del mundo, con 6650 km."],
            "GR": ["Grecia es considerada la cuna de la democracia, la filosofía y los Juegos Olímpicos.", "Grecia tiene más de 6000 islas, pero solo unas 200 están habitadas.", "El alfabeto griego se ha usado más de 2700 años e influyó en muchos sistemas de escritura."],
            "TR": ["Turquía está en dos continentes: Europa y Asia, separados por el Bósforo.", "La antigua Troya de la Ilíada de Homero está en la actual Turquía.", "Turquía es el mayor productor mundial de avellanas, con alrededor del 70% de la producción global."],
            "TH": ["Tailandia es el único país del Sudeste Asiático que nunca fue colonizado por europeos.", "La cocina tailandesa es conocida por el equilibrio entre dulce, ácido, salado y picante.", "Tailandia alberga el mamífero más pequeño (murciélago abejorro) y el pez más grande (tiburón ballena)."],
            "AR": ["Argentina es famosa por el tango, que nació en Buenos Aires a finales del siglo XIX.", "Argentina es el segundo país más grande de Sudamérica y el octavo del mundo.", "El país es conocido por su producción de carne y vino, especialmente malbec."],
            "ZA": ["Sudáfrica tiene 11 idiomas oficiales, más que ningún otro país.", "Es el único país que desmanteló voluntariamente su programa de armas nucleares.", "Sudáfrica alberga la mina de diamantes más grande del mundo y produce alrededor del 15% del oro mundial."]
        ]
        return facts[code] ?? getEnglishFacts(for: code)
    }
    
    private func getUkrainianFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": ["Австрія відома як батьківщина класичної музики — тут народились Моцарт, Бетховен, Шуберт та Штраус.", "Відень кілька років поспіль визнавали найзручнішим для життя містом світу.", "В Австрії знаходиться найстаріший зоопарк світу — Шенбруннський зоопарк (1752)."],
            "US": ["У США немає офіційної мови на федеральному рівні, хоча англійська найпоширеніша.", "Аляску купили у Росії в 1867 році за 7,2 млн доларів.", "У США понад 400 національних парків і найбільша економіка світу."],
            "GB": ["Велика Британія складається з чотирьох країн: Англія, Шотландія, Уельс і Північна Ірландія.", "Біг-Бен — це назва дзвону, а не годинникової вежі.", "У Великій Британії понад 1500 замків, багато досі обжитих."],
            "FR": ["Франція — найвідвідуваніша країна світу (понад 89 млн туристів на рік).", "Ейфелеву вежу планували як тимчасову і ледь не знесли в 1909 році.", "Франція отримала найбільше Нобелівських премій з літератури — 16."],
            "DE": ["У Німеччині понад 1500 пивоварень і знаменитий закон про чистоту пива 1516 року.", "Падіння Берлінської стіни в 1989 році поклало початок об'єднанню Німеччини.", "Німеччина — локомотив економіки Європи і четверта економіка світу."],
            "IT": ["В Італії більше об'єктів Всесвітньої спадщини ЮНЕСКО, ніж у будь-якій іншій країні — 58.", "Колізей вміщував до 80 000 глядачів і мав продуману дренажну систему.", "В Італії три діючих вулкани: Везувій, Етна і Стромболі."],
            "ES": ["Іспанія на другому місці за числом об'єктів ЮНЕСКО після Італії.", "Іспанською говорять понад 500 млн осіб у світі.", "Іспанія виробляє близько 45% світової оливкової олії, переважно в Андалусії."],
            "JP": ["Японія складається з 6852 островів, з них населені близько 430.", "У японській писемності використовуються три системи: хірагана, катакана і кандзі.", "У Японії одна з найвищих у світі тривалість життя і низька злочинність."],
            "CN": ["Великий Китайський мур не видно з космосу неозброєним оком.", "У Китаї 56 визнаних народів; ханьці становлять близько 92% населення.", "Китай — найбільший у світі виробник рису, пшениці та багатьох інших сільгоспкультур."],
            "RU": ["Росія займає 11 часових поясів — більше, ніж будь-яка інша країна.", "Транссибірська магістраль — найдовша залізниця світу (9289 км).", "У Росії найбільші у світі лісові запаси і близько 25% світових запасів прісної води."],
            "BR": ["Амазонські ліси в Бразилії виробляють близько 20% світового кисню.", "Бразилія — найбільша країна Південної Америки, займає майже половину континенту.", "Карнавал у Ріо-де-Жанейро — один із найбільших фестивалів світу."],
            "CA": ["У Канаді дві державні мови: англійська та французька.", "У Канади найдовша берегова лінія у світі — 243 042 км.", "Назва «Канада» походить від слова «каната» мовою гуронів — «село»."],
            "AU": ["Австралія — єдина країна, що є й континентом.", "Близько 80% австралійських тварин не зустрічаються більше ніде в світі.", "Великий Бар'єрний риф — найбільша жива структура на Землі, видна з космосу."],
            "IN": ["В Індії 22 офіційні мови і понад 1600 розмовних.", "Індійський кінематограф виробляє більше фільмів, ніж Голлівуд.", "Індія — батьківщина чотирьох великих світових релігій: індуїзму, буддизму, джайнізму та сикхізму."],
            "MX": ["Мексика подарувала світу шоколад, ваніль і перець чилі.", "Стародавні майя та ацтеки будували вражаючі піраміди, багато стоять і сьогодні.", "Мехіко зведений на озері і поступово просідає на 15–20 см на рік."],
            "EG": ["Піраміда Хеопса була найвищою рукотворною спорудою понад 3800 років.", "Стародавні єгиптяни винайшли папір, чорнило і 365-денний календар.", "Ніл — найдовша ріка світу (6650 км)."],
            "GR": ["Грецію вважають батьківщиною демократії, філософії та Олімпійських ігор.", "В Греції понад 6000 островів, населені близько 200.", "Грецька абетка використовується понад 2700 років і вплинула на багато писемностей."],
            "TR": ["Туреччина розташована на двох континентах: Європа та Азія (розділені Босфором).", "Стародавня Троя з «Іліади» Гомера знаходилась на території сучасної Туреччини.", "Туреччина — найбільший у світі виробник фундуку (близько 70% світового урожаю)."],
            "TH": ["Таїланд — єдина країна Південно-Східної Азії, що не була колонією європейців.", "Тайська кухня відома балансом солодкого, кислого, солоного та гострого.", "В Таїланді мешкають найменша кажановидна миша і найбільша риба — китова акула."],
            "AR": ["Аргентина славиться танго, що зародилось у Буенос-Айресі наприкінці XIX століття.", "Аргентина — друга за площею країна Південної Америки і восьма в світі.", "Країна відома виробництвом яловичини та вина, особливо мальбека."],
            "ZA": ["У ПАР 11 державних мов — більше, ніж у будь-якій іншій країні.", "ПАР — єдина країна, що добровільно відмовилась від ядерної зброї.", "У ПАР знаходиться найбільший у світі алмазний рудник; країна дає близько 15% світової видобутку золота."]
        ]
        return facts[code] ?? getEnglishFacts(for: code)
    }
    
    private func getCatalanFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": ["Àustria és coneguda com la bressol de la música clàssica; Mozart, Beethoven, Schubert i Strauss van néixer aquí.", "Viena ha estat classificada com la ciutat més habitable del món durant diversos anys consecutius.", "Àustria alberga el zoològic més antic del món, el Zoo de Schönbrunn, fundat el 1752."],
            "US": ["Estats Units no té idioma oficial a nivell federal, tot i que l'anglès és el més parlat.", "Alaska es va comprar a Rússia el 1867 per 7,2 milions de dòlars.", "Estats Units té més de 400 parcs nacionals i l'economia més gran del món."],
            "GB": ["El Regne Unit es compon de quatre països: Anglaterra, Escòcia, Gal·les i Irlanda del Nord.", "Big Ben és el nom de la campana, no de la torre del rellotge.", "El Regne Unit té més de 1500 castells, molts encara habitats."],
            "FR": ["França és el país més visitat del món, amb més de 89 milions de turistes l'any.", "La Torre Eiffel es va concebre com a temporal i gairebé es va enderrocar el 1909.", "França ha guanyat més premis Nobel de Literatura que cap altre país: 16."],
            "DE": ["Alemanya té més de 1500 cerveseries i la famosa llei de puresa de la cervesa del 1516.", "La caiguda del Mur de Berlín el 1989 va marcar l'inici de la reunificació alemanya.", "Alemanya és la locomotora econòmica d'Europa i la quarta economia mundial."],
            "IT": ["Itàlia té més llocs Patrimoni de la Humanitat de la UNESCO que cap altre país: 58.", "El Colosseu podia acollir fins a 80 000 espectadors i tenia un sistema de drenatge sofisticat.", "Itàlia alberga tres volcans actius: Vesuvi, Etna i Stromboli."],
            "ES": ["Espanya té el segon major nombre de llocs UNESCO després d'Itàlia.", "L'espanyol el parlen més de 500 milions de persones al món.", "Espanya produeix al voltant del 45% de l'oli d'oliva mundial, sobretot a Andalusia."],
            "JP": ["Japó consta de 6852 illes, de les quals unes 430 estan habitades.", "L'escriptura japonesa usa tres scripts: hiragana, katakana i kanji.", "Japó té una de les esperances de vida més altes del món i una de les taxes de criminalitat més baixes."],
            "CN": ["La Gran Muralla Xinesa no es veu des de l'espai a ull nu.", "La Xina té 56 grups ètnics reconeguts; els han representen al voltant del 92% de la població.", "La Xina és el major productor mundial d'arròs, blat i molts altres productes agrícoles."],
            "RU": ["Rússia abasta 11 zones horàries, més que cap altre país.", "El Transsiberià és la línia ferroviària més llarga del món: 9289 km.", "Rússia té les majors reserves forestals del món i al voltant del 25% de l'aigua dolça mundial."],
            "BR": ["La selva amazònica al Brasil produeix al voltant del 20% de l'oxigen mundial.", "El Brasil és el país més gran de Sud-amèrica i ocupa gairebé la meitat del continent.", "El Carnaval de Rio de Janeiro és una de les majors festes del món."],
            "CA": ["Canadà té dues llengües oficials: anglès i francès.", "Canadà té la costa més llarga del món: 243 042 km.", "El nom «Canadà» prové de la paraula huron-iroquesa «kanata», que vol dir poble."],
            "AU": ["Austràlia és l'únic país que és també un continent.", "Un 80% dels animals d'Austràlia no es troben en cap altre lloc del món.", "La Gran Barrera de Corall és l'estructura viva més gran del món i és visible des de l'espai."],
            "IN": ["L'Índia té 22 idiomes oficials i més de 1600 llengües parlades.", "La indústria cinematogràfica índia produeix més pel·lícules que Hollywood.", "L'Índia és la bressol de quatre grans religions: hinduisme, budisme, jainisme i sikhisme."],
            "MX": ["Mèxic va donar al món la xocolata, la vainilla i el pebrot.", "Les civilitzacions maia i asteca van construir piràmides impressionants que encara es mantenen.", "Ciudad de México està construïda sobre un llac i s'enfonsa uns 15–20 cm l'any."],
            "EG": ["La Gran Piràmide de Giza va ser l'estructura artificial més alta durant més de 3800 anys.", "Els antics egipcis van inventar el paper, la tinta i el calendari de 365 dies.", "El Nil és el riu més llarg del món, amb 6650 km."],
            "GR": ["Grècia és considerada la bressol de la democràcia, la filosofia i els Jocs Olímpics.", "Grècia té més de 6000 illes, però només unes 200 estan habitades.", "L'alfabet grec s'ha fet servir més de 2700 anys i va influir en molts sistemes d'escriptura."],
            "TR": ["Turquia està en dos continents: Europa i Àsia, separats pel Bòsfor.", "L'antiga Troia de la Ilíada d'Homer és a l'actual Turquia.", "Turquia és el major productor mundial d'avellanes, amb al voltant del 70% de la producció global."],
            "TH": ["Tailàndia és l'únic país del Sud-est Asiàtic que mai va ser colonitzat pels europeus.", "La cuina tailandesa és coneguda per l'equilibri entre dolç, àcid, salat i picant.", "Tailàndia alberga el mamífer més petit (ratpenat abella) i el peix més gran (tauró balena)."],
            "AR": ["Argentina és famosa pel tango, que va néixer a Buenos Aires a finals del segle XIX.", "Argentina és el segon país més gran de Sud-amèrica i el vuitè del món.", "El país és conegut per la producció de carn i vi, especialment malbec."],
            "ZA": ["Sud-àfrica té 11 idiomes oficials, més que cap altre país.", "És l'únic país que va desmantellar voluntàriament el seu programa d'armes nuclears.", "Sud-àfrica alberga la mina de diamants més gran del món i produeix al voltant del 15% de l'or mundial."]
        ]
        return facts[code] ?? getEnglishFacts(for: code)
    }
    
    private func getChineseFacts(for code: String) -> [String] {
        let facts: [String: [String]] = [
            "AT": ["奥地利被誉为古典音乐的故乡，莫扎特、贝多芬、舒伯特和施特劳斯都出生在这里。", "维也纳连续多年被评为世界上最适宜居住的城市。", "奥地利拥有世界上最古老的动物园——美泉宫动物园，建于1752年。"],
            "US": ["美国联邦层面没有规定官方语言，但英语是最常用的语言。", "阿拉斯加于1867年以720万美元从俄罗斯购得。", "美国拥有400多个国家公园，是世界第一大经济体。"],
            "GB": ["英国由四个国家组成：英格兰、苏格兰、威尔士和北爱尔兰。", "大本钟是钟的名字，不是钟楼的名字。", "英国有1500多座城堡，许多至今仍有人居住。"],
            "FR": ["法国是世界上接待游客最多的国家，年接待量超过8900万人次。", "埃菲尔铁塔最初是临时建筑，1909年险些被拆除。", "法国获得的诺贝尔文学奖数量世界第一，共16次。"],
            "DE": ["德国有1500多家啤酒厂，以1516年啤酒纯净法闻名。", "1989年柏林墙的倒塌标志着德国统一的开始。", "德国是欧洲经济引擎，世界第四大经济体。"],
            "IT": ["意大利的联合国教科文组织世界遗产数量世界第一，共58处。", "罗马斗兽场可容纳约8万名观众，并拥有先进的排水系统。", "意大利有三座活火山：维苏威、埃特纳和斯特龙博利。"],
            "ES": ["西班牙的联合国教科文组织遗产数量仅次于意大利。", "全球有超过5亿人使用西班牙语。", "西班牙生产全球约45%的橄榄油，主要来自安达卢西亚。"],
            "JP": ["日本由6852个岛屿组成，其中约430个有人居住。", "日文书写使用三种文字：平假名、片假名和汉字。", "日本是世界上预期寿命最长、犯罪率最低的国家之一。"],
            "CN": ["长城无法从太空用肉眼看到，这是常见误解。", "中国有56个民族，汉族约占人口的92%。", "中国是世界上水稻、小麦及多种农产品的最大生产国。"],
            "RU": ["俄罗斯横跨11个时区，为全球之最。", "西伯利亚铁路是世界上最长的铁路，全长9289公里。", "俄罗斯拥有世界上最大的森林储备和约25%的淡水储量。"],
            "BR": ["巴西亚马逊雨林产生全球约20%的氧气。", "巴西是南美洲面积最大的国家，几乎占半个大陆。", "里约热内卢狂欢节是世界上最大的节庆之一。"],
            "CA": ["加拿大有两种官方语言：英语和法语。", "加拿大拥有世界上最长的海岸线，达243042公里。", "「加拿大」一名来自休伦-易洛魁语「kanata」，意为村庄。"],
            "AU": ["澳大利亚是唯一同时作为国家与大陆的陆地。", "澳大利亚约80%的动物为当地特有。", "大堡礁是世界上最大的活体结构，可从太空看到。"],
            "IN": ["印度有22种官方语言和1600多种口语。", "印度电影产量超过好莱坞。", "印度是印度教、佛教、耆那教和锡克教四大宗教的发源地。"],
            "MX": ["墨西哥为世界带来了巧克力、香草和辣椒。", "古代玛雅和阿兹特克文明建造的金字塔至今仍存。", "墨西哥城建在湖上，每年下沉约15–20厘米。"],
            "EG": ["吉萨大金字塔在3800多年间都是世界上最高的人造建筑。", "古埃及人发明了纸、墨水和365天历法。", "尼罗河是世界上最长的河流，长6650公里。"],
            "GR": ["希腊被视为民主、哲学和奥运会的发源地。", "希腊有6000多座岛屿，其中约200座有人居住。", "希腊字母已使用2700多年，影响了许多书写系统。"],
            "TR": ["土耳其横跨欧亚两洲，以博斯普鲁斯海峡为界。", "荷马《伊利亚特》中的古城特洛伊位于今土耳其。", "土耳其是全球最大的榛子生产国，约占全球产量的70%。"],
            "TH": ["泰国是东南亚唯一未被欧洲殖民的国家。", "泰国菜以甜、酸、咸、辣的平衡闻名。", "泰国既有世界上最小的哺乳动物（大黄蜂蝙蝠），也有最大的鱼（鲸鲨）。"],
            "AR": ["阿根廷以探戈闻名，探戈于19世纪末诞生于布宜诺斯艾利斯。", "阿根廷是南美洲第二、世界第八大国家。", "该国以牛肉和葡萄酒（尤其是马尔贝克）闻名。"],
            "ZA": ["南非有11种官方语言，为全球之最。", "南非是唯一自愿放弃核武计划的国家。", "南非拥有世界上最大的钻石矿，黄金产量约占全球15%。"]
        ]
        return facts[code] ?? getEnglishFacts(for: code)
    }
    
    private func getRussianFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "Флаг Австрии состоит из трех равных горизонтальных полос: красно-бело-красной. По легенде, цвета происходят от белой туники герцога Леопольда V, пропитанной кровью в битве, с белой полосой там, где был пояс.",
            "US": "Американский флаг имеет 13 горизонтальных полос (7 красных, 6 белых), представляющих первоначальные колонии, и 50 белых звезд на синем кантоне, представляющих нынешние штаты.",
            "GB": "Юнион Джек объединяет кресты святого Георгия (Англия), святого Андрея (Шотландия) и святого Патрика (Ирландия). Красный крест на белом представляет Англию, белый диагональный крест на синем - Шотландию.",
            "FR": "Французский триколор имеет три вертикальные полосы: синюю, белую и красную. Синий и красный - традиционные цвета Парижа, белый представляет монархию.",
            "DE": "Немецкий флаг состоит из трех горизонтальных полос: черной, красной и золотой. Эти цвета представляют немецкое единство и свободу с XIX века.",
            "IT": "Итальянский флаг имеет три вертикальные полосы: зеленую, белую и красную. Зеленый представляет равнины и холмы, белый - заснеженные Альпы, красный - кровь за независимость.",
            "ES": "Испанский флаг имеет две красные горизонтальные полосы с желтой полосой в два раза шире между ними. Герб в центре включает символы исторических королевств Испании.",
            "RU": "Российский флаг имеет три горизонтальные полосы: белую, синюю и красную. Белый представляет благородство, синий - верность, красный - мужество и великодушие.",
            "CN": "Китайский флаг красный с пятью желтыми звездами. Большая звезда представляет Коммунистическую партию, четыре меньшие - единство китайского народа.",
            "JP": "Японский флаг называется Хиномару и представляет красный круг (солнце) на белом фоне. Дизайн символизирует Японию как 'Страну восходящего солнца'.",
            "PL": "Польский флаг состоит из двух равных горизонтальных полос: белой сверху и красной снизу. Белый символизирует мир и чистоту, красный - мужество и кровь, пролитую за независимость.",
            "NL": "Голландский флаг имеет три горизонтальные полосы: красную, белую и синюю. Эти цвета восходят к XVI веку и символизируют борьбу за независимость от испанского владычества.",
            "BE": "Бельгийский флаг имеет три вертикальные полосы: черную, желтую и красную. Эти цвета были приняты во время Бельгийской революции 1830 года и представляют исторические провинции.",
            "CH": "Швейцарский флаг представляет собой красный квадрат с белым крестом в центре. Крест символизирует христианство и единство Швейцарии, красный - кровь мучеников.",
            "SE": "Шведский флаг имеет синее поле с желтым скандинавским крестом, доходящим до краев. Крест символизирует христианство, синий - небо и озера, желтый - солнце.",
            "NO": "Норвежский флаг имеет красное поле с белым скандинавским крестом с синей каймой. Крест символизирует христианство, цвета отражают исторические связи с Данией.",
            "DK": "Датский флаг, называемый Даннеброг, красный с белым скандинавским крестом. Легенда гласит, что он упал с неба во время битвы в 1219 году, что делает его одним из старейших флагов.",
            "FI": "Финский флаг имеет синий крест на белом фоне. Синий символизирует тысячи озер и небо, белый - снег, покрывающий страну зимой.",
            "PT": "Португальский флаг имеет зеленую и красную вертикальные полосы с национальным гербом. Зеленый символизирует надежду, красный - кровь тех, кто сражался за нацию.",
            "IE": "Ирландский флаг имеет три вертикальные полосы: зеленую, белую и оранжевую. Зеленый символизирует католиков, оранжевый - протестантов, белый - мир между ними.",
            "CZ": "Чешский флаг состоит из двух горизонтальных полос (белой и красной) с синим треугольником у древка. Цвета представляют исторические регионы: Богемию, Моравию и Словакию.",
            "HU": "Венгерский флаг имеет три горизонтальные полосы: красную, белую и зеленую. Красный символизирует силу, белый - верность, зеленый - надежду.",
            "RO": "Румынский флаг имеет три вертикальные полосы: синюю, желтую и красную. Синий символизирует небо, желтый - поля, красный - кровь героев.",
            "BG": "Болгарский флаг имеет три горизонтальные полосы: белую, зеленую и красную. Белый символизирует мир, зеленый - леса и сельское хозяйство, красный - кровь борцов за свободу.",
            "HR": "Хорватский флаг имеет красную, белую и синюю горизонтальные полосы с национальным гербом в центре, демонстрирующим исторический хорватский шахматный узор.",
            "RS": "Сербский флаг имеет три горизонтальные полосы: красную, синюю и белую, с национальным гербом, слегка смещенным к древку. Цвета символизируют панславянское единство.",
            "IL": "Израильский флаг имеет синюю звезду Давида между двумя горизонтальными синими полосами на белом фоне. Дизайн представляет еврейский молитвенный платок и связь с землей.",
            "SA": "Флаг Саудовской Аравии зеленый с белой арабской надписью и мечом. Надпись - это Шахада (исламское исповедание веры), зеленый - традиционный цвет ислама.",
            "AE": "Флаг ОАЭ имеет четыре цвета: красный, зеленый, белый и черный. Эти панарабские цвета символизируют единство арабских наций, каждый эмират вносит вклад в федерацию.",
            "IR": "Иранский флаг имеет три горизонтальные полосы: зеленую, белую и красную. Зеленый символизирует ислам, белый - мир, красный - мужество. В центре изображен национальный герб.",
            "PK": "Пакистанский флаг имеет зеленое поле с белым полумесяцем и звездой. Зеленый символизирует ислам и мусульманское большинство, белый - религиозные меньшинства.",
            "BD": "Бангладешский флаг имеет красный круг на зеленом поле. Красный круг символизирует восходящее над Бенгалией солнце и кровь мучеников, зеленый - пышный ландшафт.",
            "VN": "Вьетнамский флаг имеет красное поле с желтой пятиконечной звездой в центре. Красный символизирует революцию и кровь, желтый - вьетнамский народ, звезда - единство.",
            "ID": "Индонезийский флаг имеет две равные горизонтальные полосы: красную сверху и белую снизу. Красный символизирует мужество и независимость, белый - чистоту и мир.",
            "PH": "Филиппинский флаг имеет синюю полосу сверху и красную снизу, с белым треугольником у древка, содержащим солнце и три звезды. Синий символизирует мир, красный - мужество.",
            "MY": "Малайзийский флаг имеет 14 чередующихся красных и белых полос с синим кантоном, содержащим полумесяц и 14-конечную звезду. Полосы представляют 13 штатов и федеральные территории.",
            "SG": "Сингапурский флаг имеет две равные горизонтальные полосы: красную сверху и белую снизу, с белым полумесяцем и пятью звездами в верхней части у древка. Красный символизирует братство, белый - чистоту.",
            "KR": "Южнокорейский флаг, называемый Тхэгыкки, имеет белое поле с красно-синим символом инь-ян в центре, окруженным четырьмя черными триграммами, представляющими элементы.",
            "NZ": "Флаг Новой Зеландии синий с Юнион Джеком в кантоне и четырьмя красными звездами с белыми краями, представляющими созвездие Южного Креста.",
            "CL": "Чилийский флаг имеет две горизонтальные полосы: белую сверху и красную снизу, с синим квадратом в верхней части у древка, содержащим белую пятиконечную звезду. Звезда символизирует прогресс и честь."
        ]
        return descriptions[code] ?? "Национальный флаг представляет идентичность, историю и ценности страны. Каждый цвет и символ имеет особое значение для нации."
    }
    
    private func getSpanishFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "La bandera de Austria consta de tres franjas horizontales iguales: rojo-blanco-rojo. Según la leyenda, los colores provienen de la túnica blanca del duque Leopoldo V empapada de sangre en batalla.",
            "US": "La bandera americana tiene 13 franjas horizontales (7 rojas, 6 blancas) que representan las colonias originales, y 50 estrellas blancas en un cantón azul que representan los estados actuales.",
            "GB": "La Union Jack combina las cruces de San Jorge (Inglaterra), San Andrés (Escocia) y San Patricio (Irlanda). La cruz roja sobre blanco representa Inglaterra.",
            "FR": "La tricolor francesa tiene tres franjas verticales: azul, blanca y roja. Azul y rojo son los colores tradicionales de París, mientras que el blanco representa la monarquía.",
            "DE": "La bandera alemana consiste en tres franjas horizontales: negra, roja y dorada. Estos colores han representado la unidad y libertad alemana desde el siglo XIX.",
            "IT": "La bandera italiana tiene tres franjas verticales: verde, blanca y roja. El verde representa las llanuras y colinas, el blanco los Alpes nevados, el rojo la sangre por la independencia.",
            "ES": "La bandera española presenta dos franjas rojas horizontales con una franja amarilla del doble de ancho entre ellas. El escudo de armas en el centro incluye símbolos de los reinos históricos.",
            "RU": "La bandera rusa tiene tres franjas horizontales: blanca, azul y roja. El blanco representa la nobleza, el azul la fidelidad, el rojo el coraje y la generosidad.",
            "CN": "La bandera china es roja con cinco estrellas amarillas. La estrella grande representa el Partido Comunista, las cuatro pequeñas representan la unidad del pueblo chino.",
            "JP": "La bandera japonesa se llama Hinomaru y presenta un círculo rojo (el sol) sobre fondo blanco. El diseño simboliza Japón como la 'Tierra del Sol Naciente'.",
            "PL": "La bandera polaca consta de dos franjas horizontales iguales: blanca arriba y roja abajo. El blanco representa la paz y la pureza, el rojo simboliza el coraje y la sangre derramada por la independencia.",
            "NL": "La bandera holandesa tiene tres franjas horizontales: roja, blanca y azul. Estos colores se remontan al siglo XVI y representan la lucha por la independencia del dominio español.",
            "BE": "La bandera belga tiene tres franjas verticales: negra, amarilla y roja. Estos colores fueron adoptados durante la Revolución Belga de 1830 y representan las provincias históricas.",
            "CH": "La bandera suiza es un cuadrado rojo con una cruz blanca en el centro. La cruz representa el cristianismo y la unidad suiza, mientras que el rojo simboliza la sangre de los mártires.",
            "SE": "La bandera sueca presenta un campo azul con una cruz escandinava amarilla que se extiende hasta los bordes. La cruz representa el cristianismo, el azul simboliza el cielo y los lagos, el amarillo representa el sol.",
            "NO": "La bandera noruega tiene un campo rojo con una cruz escandinava blanca con borde azul. La cruz representa el cristianismo, y los colores reflejan los vínculos históricos con Dinamarca.",
            "DK": "La bandera danesa, llamada Dannebrog, es roja con una cruz escandinava blanca. La leyenda dice que cayó del cielo durante una batalla en 1219, lo que la convierte en una de las banderas más antiguas aún en uso.",
            "FI": "La bandera finlandesa presenta una cruz azul sobre fondo blanco. El azul representa los miles de lagos y el cielo, el blanco simboliza la nieve que cubre el país en invierno.",
            "PT": "La bandera portuguesa tiene franjas verticales verdes y rojas con el escudo de armas nacional. El verde representa la esperanza, el rojo simboliza la sangre de quienes lucharon por la nación.",
            "IE": "La bandera irlandesa tiene tres franjas verticales: verde, blanca y naranja. El verde representa a los católicos, el naranja a los protestantes, y el blanco simboliza la paz entre ellos.",
            "CZ": "La bandera checa consta de dos franjas horizontales (blanca y roja) con un triángulo azul que se extiende desde el asta. Los colores representan las regiones históricas de Bohemia, Moravia y Eslovaquia.",
            "HU": "La bandera húngara tiene tres franjas horizontales: roja, blanca y verde. El rojo representa la fuerza, el blanco simboliza la fidelidad, y el verde representa la esperanza.",
            "RO": "La bandera rumana tiene tres franjas verticales: azul, amarilla y roja. El azul representa el cielo, el amarillo simboliza los campos, y el rojo representa la sangre de los héroes.",
            "BG": "La bandera búlgara tiene tres franjas horizontales: blanca, verde y roja. El blanco representa la paz, el verde simboliza los bosques y la agricultura, el rojo representa la sangre de los luchadores por la libertad.",
            "HR": "La bandera croata presenta franjas horizontales rojas, blancas y azules con el escudo de armas nacional en el centro, mostrando el patrón de tablero de ajedrez histórico croata.",
            "RS": "La bandera serbia tiene tres franjas horizontales: roja, azul y blanca, con el escudo de armas nacional ligeramente desplazado hacia el asta. Los colores representan la unidad paneslava.",
            "IL": "La bandera israelí presenta una estrella de David azul entre dos franjas azules horizontales sobre fondo blanco. El diseño representa el manto de oración judío y la conexión con la tierra.",
            "SA": "La bandera de Arabia Saudí es verde con escritura árabe blanca y una espada. La escritura es la Shahada (declaración de fe islámica), y el verde es el color tradicional del islam.",
            "AE": "La bandera de los EAU tiene cuatro colores: rojo, verde, blanco y negro. Estos colores panárabes representan la unidad entre las naciones árabes, con cada emirato contribuyendo a la federación.",
            "IR": "La bandera iraní tiene tres franjas horizontales: verde, blanca y roja. El verde representa el islam, el blanco simboliza la paz, y el rojo representa el coraje. El centro presenta el emblema nacional.",
            "PK": "La bandera pakistaní tiene un campo verde con una media luna y una estrella blancas. El verde representa el islam y la mayoría musulmana, el blanco simboliza las minorías religiosas.",
            "BD": "La bandera de Bangladesh presenta un círculo rojo sobre un campo verde. El círculo rojo representa el sol naciente sobre Bengala y la sangre de los mártires, el verde simboliza el paisaje exuberante.",
            "VN": "La bandera vietnamita tiene un campo rojo con una estrella amarilla de cinco puntas en el centro. El rojo representa la revolución y la sangre, el amarillo simboliza al pueblo vietnamita, y la estrella representa la unidad.",
            "ID": "La bandera indonesia tiene dos franjas horizontales iguales: roja arriba y blanca abajo. El rojo representa el coraje y la independencia, el blanco simboliza la pureza y la paz.",
            "PH": "La bandera filipina tiene una franja azul arriba y roja abajo, con un triángulo blanco en el asta que contiene un sol y tres estrellas. El azul representa la paz, el rojo simboliza el coraje.",
            "MY": "La bandera malasia presenta 14 franjas alternas rojas y blancas con un cantón azul que contiene una media luna y una estrella de 14 puntas. Las franjas representan los 13 estados y territorios federales.",
            "SG": "La bandera de Singapur tiene dos franjas horizontales iguales: roja arriba y blanca abajo, con una media luna blanca y cinco estrellas en la parte superior del asta. El rojo representa la hermandad universal, el blanco simboliza la pureza.",
            "KR": "La bandera de Corea del Sur, llamada Taegukgi, presenta un campo blanco con un símbolo yin-yang rojo y azul en el centro, rodeado de cuatro trigramas negros que representan los elementos.",
            "NZ": "La bandera de Nueva Zelanda es azul con la Union Jack en el cantón y cuatro estrellas rojas con bordes blancos que representan la constelación de la Cruz del Sur.",
            "CL": "La bandera chilena tiene dos franjas horizontales: blanca arriba y roja abajo, con un cuadrado azul en la parte superior del asta que contiene una estrella blanca de cinco puntas. La estrella representa el progreso y el honor."
        ]
        return descriptions[code] ?? "La bandera nacional representa la identidad, historia y valores del país. Cada color y símbolo tiene un significado especial para la nación."
    }
    
    private func getUkrainianFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "Прапор Австрії складається з трьох рівних горизонтальних смуг: червоно-біло-червоної. За легендою, кольори походять від білої туніки герцога Леопольда V, просоченої кров'ю в битві.",
            "US": "Американський прапор має 13 горизонтальних смуг (7 червоних, 6 білих), що представляють первинні колонії, та 50 білих зірок на синьому кантоні, що представляють нинішні штати.",
            "GB": "Юніон Джек поєднує хрести святого Георгія (Англія), святого Андрія (Шотландія) та святого Патрика (Ірландія).",
            "FR": "Французький триколор має три вертикальні смуги: синю, білу та червону. Синій і червоний - традиційні кольори Парижа, білий представляє монархію.",
            "DE": "Німецький прапор складається з трьох горизонтальних смуг: чорної, червоної та золотої. Ці кольори представляють німецьку єдність і свободу з XIX століття.",
            "IT": "Італійський прапор має три вертикальні смуги: зелену, білу та червону. Зелений представляє рівнини та пагорби, білий - засніжені Альпи.",
            "ES": "Іспанський прапор має дві червоні горизонтальні смуги з жовтою смугою вдвічі ширшою між ними.",
            "RU": "Російський прапор має три горизонтальні смуги: білу, синю та червону. Білий представляє благородство, синій - вірність, червоний - мужність.",
            "CN": "Китайський прапор червоний з п'ятьма жовтими зірками. Велика зірка представляє Комуністичну партію.",
            "JP": "Японський прапор називається Хіномару і представляє червоне коло (сонце) на білому тлі.",
            "PL": "Польський прапор складається з двох рівних горизонтальних смуг: білої зверху та червоної знизу. Білий символізує мир і чистоту, червоний - мужність і кров, пролиту за незалежність.",
            "NL": "Голландський прапор має три горизонтальні смуги: червону, білу та синю. Ці кольори сягають XVI століття і символізують боротьбу за незалежність від іспанського панування.",
            "BE": "Бельгійський прапор має три вертикальні смуги: чорну, жовту та червону. Ці кольори були прийняті під час Бельгійської революції 1830 року і представляють історичні провінції.",
            "CH": "Швейцарський прапор являє собою червоний квадрат з білим хрестом у центрі. Хрест символізує християнство та єдність Швейцарії, червоний - кров мучеників.",
            "SE": "Шведський прапор має синє поле з жовтим скандинавським хрестом, що доходить до країв. Хрест символізує християнство, синій - небо та озера, жовтий - сонце.",
            "NO": "Норвезький прапор має червоне поле з білим скандинавським хрестом з синьою облямівкою. Хрест символізує християнство, кольори відображають історичні зв'язки з Данією.",
            "DK": "Данський прапор, званий Даннеброг, червоний з білим скандинавським хрестом. Легенда каже, що він впав з неба під час битви в 1219 році, що робить його одним з найстаріших прапорів.",
            "FI": "Фінський прапор має синій хрест на білому тлі. Синій символізує тисячі озер та небо, білий - сніг, що покриває країну взимку.",
            "PT": "Португальський прапор має зелену та червону вертикальні смуги з національним гербом. Зелений символізує надію, червоний - кров тих, хто боровся за націю.",
            "IE": "Ірландський прапор має три вертикальні смуги: зелену, білу та помаранчеву. Зелений символізує католиків, помаранчевий - протестантів, білий - мир між ними.",
            "CZ": "Чеський прапор складається з двох горизонтальних смуг (білої та червоної) з синім трикутником біля древка. Кольори представляють історичні регіони: Богемію, Моравію та Словаччину.",
            "HU": "Угорський прапор має три горизонтальні смуги: червону, білу та зелену. Червоний символізує силу, білий - вірність, зелений - надію.",
            "RO": "Румунський прапор має три вертикальні смуги: синю, жовту та червону. Синій символізує небо, жовтий - поля, червоний - кров героїв.",
            "BG": "Болгарський прапор має три горизонтальні смуги: білу, зелену та червону. Білий символізує мир, зелений - ліси та сільське господарство, червоний - кров борців за свободу.",
            "HR": "Хорватський прапор має червону, білу та синю горизонтальні смуги з національним гербом у центрі, що демонструє історичний хорватський шаховий візерунок.",
            "RS": "Сербський прапор має три горизонтальні смуги: червону, синю та білу, з національним гербом, трохи зміщеним до древка. Кольори символізують панслов'янську єдність.",
            "IL": "Ізраїльський прапор має синю зірку Давида між двома горизонтальними синіми смугами на білому тлі. Дизайн представляє єврейський молитовний платок та зв'язок із землею.",
            "SA": "Прапор Саудівської Аравії зелений з білим арабським написом та мечем. Напис - це Шахада (ісламське сповідання віри), зелений - традиційний колір ісламу.",
            "AE": "Прапор ОАЕ має чотири кольори: червоний, зелений, білий та чорний. Ці панарабські кольори символізують єдність арабських націй, кожен емірат вносить внесок у федерацію.",
            "IR": "Іранський прапор має три горизонтальні смуги: зелену, білу та червону. Зелений символізує іслам, білий - мир, червоний - мужність. У центрі зображено національний герб.",
            "PK": "Пакистанський прапор має зелене поле з білим півмісяцем та зіркою. Зелений символізує іслам та мусульманську більшість, білий - релігійні меншини.",
            "BD": "Бангладешський прапор має червоний круг на зеленому полі. Червоний круг символізує сонце, що сходить над Бенгалією, та кров мучеників, зелений - пишний ландшафт.",
            "VN": "В'єтнамський прапор має червоне поле з жовтою п'ятикутною зіркою в центрі. Червоний символізує революцію та кров, жовтий - в'єтнамський народ, зірка - єдність.",
            "ID": "Індонезійський прапор має дві рівні горизонтальні смуги: червону зверху та білу знизу. Червоний символізує мужність та незалежність, білий - чистоту та мир.",
            "PH": "Філіппінський прапор має синю смугу зверху та червону знизу, з білим трикутником біля древка, що містить сонце та три зірки. Синій символізує мир, червоний - мужність.",
            "MY": "Малайзійський прапор має 14 чергуючих червоних та білих смуг з синім кантоном, що містить півмісяць та 14-кутну зірку. Смуги представляють 13 штатів та федеральні території.",
            "SG": "Сингапурський прапор має дві рівні горизонтальні смуги: червону зверху та білу знизу, з білим півмісяцем та п'ятьма зірками у верхній частині біля древка. Червоний символізує братерство, білий - чистоту.",
            "KR": "Південнокорейський прапор, званий Тегиккі, має біле поле з красно-синім символом ін-ян у центрі, оточеним чотирма чорними триграмами, що представляють елементи.",
            "NZ": "Прапор Нової Зеландії синій з Юніон Джеком у кантоні та чотирма червоними зірками з білими краями, що представляють сузір'я Південного Хреста.",
            "CL": "Чилійський прапор має дві горизонтальні смуги: білу зверху та червону знизу, з синім квадратом у верхній частині біля древка, що містить білу п'ятикутну зірку. Зірка символізує прогрес та честь."
        ]
        return descriptions[code] ?? "Національний прапор представляє ідентичність, історію та цінності країни."
    }
    
    private func getCatalanFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "La bandera d'Àustria consisteix en tres franges horitzontals iguals: vermell-blanc-vermell. Segons la llegenda, els colors provenen de la túnica blanca del duc Leopold V empapada de sang en batalla.",
            "US": "La bandera americana té 13 franges horitzontals (7 vermelles, 6 blanques) que representen les colònies originals, i 50 estrelles blanques en un cantó blau.",
            "GB": "La Union Jack combina les creus de Sant Jordi (Anglaterra), Sant Andreu (Escòcia) i Sant Patrici (Irlanda).",
            "FR": "La tricolor francesa té tres franges verticals: blava, blanca i vermella. Blau i vermell són els colors tradicionals de París.",
            "DE": "La bandera alemanya consisteix en tres franges horitzontals: negra, vermella i daurada. Aquests colors han representat la unitat alemanya des del segle XIX.",
            "IT": "La bandera italiana té tres franges verticals: verda, blanca i vermella. El verd representa les planes i turons.",
            "ES": "La bandera espanyola presenta dues franges vermelles horitzontals amb una franja groga del doble d'ample entre elles.",
            "RU": "La bandera russa té tres franges horitzontals: blanca, blava i vermella. El blanc representa la noblesa.",
            "CN": "La bandera xinesa és vermella amb cinc estrelles grogues. L'estrella gran representa el Partit Comunista.",
            "JP": "La bandera japonesa s'anomena Hinomaru i presenta un cercle vermell (el sol) sobre fons blanc.",
            "PL": "La bandera polonesa consta de dues franges horitzontals iguals: blanca a dalt i vermella a baix. El blanc representa la pau i la puresa, el vermell simbolitza el coratge i la sang vessada per la independència.",
            "NL": "La bandera holandesa té tres franges horitzontals: vermella, blanca i blava. Aquests colors es remunten al segle XVI i representen la lluita per la independència del domini espanyol.",
            "BE": "La bandera belga té tres franges verticals: negra, groga i vermella. Aquests colors van ser adoptats durant la Revolució Belga de 1830 i representen les províncies històriques.",
            "CH": "La bandera suïssa és un quadrat vermell amb una creu blanca al centre. La creu representa el cristianisme i la unitat suïssa, mentre que el vermell simbolitza la sang dels màrtirs.",
            "SE": "La bandera sueca presenta un camp blau amb una creu escandinava groga que s'estén fins als vores. La creu representa el cristianisme, el blau simbolitza el cel i els llacs, el groc representa el sol.",
            "NO": "La bandera noruega té un camp vermell amb una creu escandinava blanca amb vora blava. La creu representa el cristianisme, i els colors reflecteixen els llaços històrics amb Dinamarca.",
            "DK": "La bandera danesa, anomenada Dannebrog, és vermella amb una creu escandinava blanca. La llegenda diu que va caure del cel durant una batalla el 1219, cosa que la converteix en una de les banderes més antigues encara en ús.",
            "FI": "La bandera finlandesa presenta una creu blava sobre fons blanc. El blau representa els milers de llacs i el cel, el blanc simbolitza la neu que cobreix el país a l'hivern.",
            "PT": "La bandera portuguesa té franges verticals verdes i vermelles amb l'escut d'armes nacional. El verd representa l'esperança, el vermell simbolitza la sang dels que van lluitar per la nació.",
            "IE": "La bandera irlandesa té tres franges verticals: verda, blanca i taronja. El verd representa als catòlics, el taronja als protestants, i el blanc simbolitza la pau entre ells.",
            "CZ": "La bandera txeca consta de dues franges horitzontals (blanca i vermella) amb un triangle blau que s'estén des de l'asta. Els colors representen les regions històriques de Bohèmia, Moràvia i Eslovàquia.",
            "HU": "La bandera hongaresa té tres franges horitzontals: vermella, blanca i verda. El vermell representa la força, el blanc simbolitza la fidelitat, i el verd representa l'esperança.",
            "RO": "La bandera romanesa té tres franges verticals: blava, groga i vermella. El blau representa el cel, el groc simbolitza els camps, i el vermell representa la sang dels herois.",
            "BG": "La bandera búlgara té tres franges horitzontals: blanca, verda i vermella. El blanc representa la pau, el verd simbolitza els boscos i l'agricultura, el vermell representa la sang dels lluitadors per la llibertat.",
            "HR": "La bandera croata presenta franges horitzontals vermelles, blanques i blaves amb l'escut d'armes nacional al centre, mostrant el patró d'escacs històric croat.",
            "RS": "La bandera sèrbia té tres franges horitzontals: vermella, blava i blanca, amb l'escut d'armes nacional lleugerament desplaçat cap a l'asta. Els colors representen la unitat paneslava.",
            "IL": "La bandera israeliana presenta una estrella de David blava entre dues franges blaves horitzontals sobre fons blanc. El disseny representa el mantell d'oració jueu i la connexió amb la terra.",
            "SA": "La bandera d'Aràbia Saudí és verda amb escriptura àrab blanca i una espasa. L'escriptura és la Shahada (declaració de fe islàmica), i el verd és el color tradicional de l'islam.",
            "AE": "La bandera dels EAU té quatre colors: vermell, verd, blanc i negre. Aquests colors panàrabs representen la unitat entre les nacions àrabs, amb cada emirat contribuint a la federació.",
            "IR": "La bandera iraniana té tres franges horitzontals: verda, blanca i vermella. El verd representa l'islam, el blanc simbolitza la pau, i el vermell representa el coratge. El centre presenta l'emblema nacional.",
            "PK": "La bandera pakistanesa té un camp verd amb una mitja lluna i una estrella blanques. El verd representa l'islam i la majoria musulmana, el blanc simbolitza les minories religioses.",
            "BD": "La bandera de Bangladesh presenta un cercle vermell sobre un camp verd. El cercle vermell representa el sol naixent sobre Bengala i la sang dels màrtirs, el verd simbolitza el paisatge exuberant.",
            "VN": "La bandera vietnamita té un camp vermell amb una estrella groga de cinc puntes al centre. El vermell representa la revolució i la sang, el groc simbolitza al poble vietnamita, i l'estrella representa la unitat.",
            "ID": "La bandera indonèsia té dues franges horitzontals iguals: vermella a dalt i blanca a baix. El vermell representa el coratge i la independència, el blanc simbolitza la puresa i la pau.",
            "PH": "La bandera filipina té una franja blava a dalt i vermella a baix, amb un triangle blanc a l'asta que conté un sol i tres estrelles. El blau representa la pau, el vermell simbolitza el coratge.",
            "MY": "La bandera malàisia presenta 14 franges alternatives vermelles i blanques amb un cantó blau que conté una mitja lluna i una estrella de 14 puntes. Les franges representen els 13 estats i territoris federals.",
            "SG": "La bandera de Singapur té dues franges horitzontals iguals: vermella a dalt i blanca a baix, amb una mitja lluna blanca i cinc estrelles a la part superior de l'asta. El vermell representa la germanor universal, el blanc simbolitza la puresa.",
            "KR": "La bandera de Corea del Sud, anomenada Taegukgi, presenta un camp blanc amb un símbol yin-yang vermell i blau al centre, envoltat de quatre trigrames negres que representen els elements.",
            "NZ": "La bandera de Nova Zelanda és blava amb la Union Jack al cantó i quatre estrelles vermelles amb vores blanques que representen la constel·lació de la Creu del Sud.",
            "CL": "La bandera xilena té dues franges horitzontals: blanca a dalt i vermella a baix, amb un quadrat blau a la part superior de l'asta que conté una estrella blanca de cinc puntes. L'estrella representa el progrés i l'honor."
        ]
        return descriptions[code] ?? "La bandera nacional representa la identitat, història i valors del país."
    }
    
    private func getChineseFlagDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "AT": "奥地利国旗由三条相等的水平条纹组成：红-白-红。据传说，颜色来自利奥波德五世公爵在战斗中被血浸透的白色外衣。",
            "US": "美国国旗有13条水平条纹（7条红色，6条白色）代表最初的殖民地，蓝色区域上的50颗白星代表现在的州。",
            "GB": "英国国旗结合了圣乔治十字（英格兰）、圣安德鲁十字（苏格兰）和圣帕特里克十字（爱尔兰）。",
            "FR": "法国三色旗有三条垂直条纹：蓝、白、红。蓝色和红色是巴黎的传统颜色，白色代表君主制。",
            "DE": "德国国旗由三条水平条纹组成：黑、红、金。这些颜色自19世纪以来代表德国的统一和自由。",
            "IT": "意大利国旗有三条垂直条纹：绿、白、红。绿色代表平原和丘陵，白色象征雪山阿尔卑斯山。",
            "ES": "西班牙国旗有两条红色水平条纹，中间是双倍宽度的黄色条纹。",
            "RU": "俄罗斯国旗有三条水平条纹：白、蓝、红。白色代表高贵，蓝色象征忠诚，红色代表勇气。",
            "CN": "中国国旗是红色底色配五颗黄星。大星代表中国共产党，四颗小星代表中国人民的团结。",
            "JP": "日本国旗被称为日之丸，在白色背景上有一个红圆圈（太阳）。设计象征日本为'日出之国'。",
            "PL": "波兰国旗由两条相等的水平条纹组成：上白下红。白色象征和平与纯洁，红色象征勇气和为独立而流的鲜血。",
            "NL": "荷兰国旗有三条水平条纹：红、白、蓝。这些颜色可追溯到16世纪，代表从西班牙统治下争取独立的斗争。",
            "BE": "比利时国旗有三条垂直条纹：黑、黄、红。这些颜色在1830年比利时革命期间被采用，代表历史省份。",
            "CH": "瑞士国旗是红色正方形，中央有白色十字。十字代表基督教和瑞士统一，红色象征烈士的鲜血。",
            "SE": "瑞典国旗为蓝色底色，上有黄色斯堪的纳维亚十字延伸至边缘。十字代表基督教，蓝色象征天空和湖泊，黄色代表太阳。",
            "NO": "挪威国旗为红色底色，上有带蓝色边框的白色斯堪的纳维亚十字。十字代表基督教，颜色反映挪威与丹麦的历史联系。",
            "DK": "丹麦国旗名为丹尼布洛格，红色底色配白色斯堪的纳维亚十字。传说它于1219年战斗时从天而降，是仍在使用的最古老旗帜之一。",
            "FI": "芬兰国旗为白色底色，上有蓝色十字。蓝色象征数千个湖泊和天空，白色象征冬季覆盖全国的雪。",
            "PT": "葡萄牙国旗有绿色和红色垂直条纹，配以国徽。绿色象征希望，红色象征为国家而战者的鲜血。",
            "IE": "爱尔兰国旗有三条垂直条纹：绿、白、橙。绿色代表天主教徒，橙色代表新教徒，白色象征两者之间的和平。",
            "CZ": "捷克国旗由两条水平条纹（白、红）组成，旗杆侧有蓝色三角形。颜色代表历史地区：波希米亚、摩拉维亚和斯洛伐克。",
            "HU": "匈牙利国旗有三条水平条纹：红、白、绿。红色象征力量，白色象征忠诚，绿色代表希望。",
            "RO": "罗马尼亚国旗有三条垂直条纹：蓝、黄、红。蓝色象征天空，黄色象征田野，红色代表英雄的鲜血。",
            "BG": "保加利亚国旗有三条水平条纹：白、绿、红。白色象征和平，绿色象征森林和农业，红色代表自由战士的鲜血。",
            "HR": "克罗地亚国旗有红、白、蓝三条水平条纹，中央有国徽，展示历史悠久的克罗地亚棋盘图案。",
            "RS": "塞尔维亚国旗有三条水平条纹：红、蓝、白，国徽略偏旗杆侧。颜色象征泛斯拉夫统一。",
            "IL": "以色列国旗为白色底色，上有蓝色大卫之星，位于两条蓝色水平条纹之间。设计代表犹太祈祷披巾与土地的联系。",
            "SA": "沙特阿拉伯国旗为绿色，上有白色阿拉伯文字和剑。文字是沙哈达（伊斯兰信仰宣言），绿色是伊斯兰的传统颜色。",
            "AE": "阿联酋国旗有四种颜色：红、绿、白、黑。这些泛阿拉伯颜色象征阿拉伯国家间的统一，每个酋长国都为联邦做出贡献。",
            "IR": "伊朗国旗有三条水平条纹：绿、白、红。绿色代表伊斯兰，白色象征和平，红色代表勇气。中央有国徽。",
            "PK": "巴基斯坦国旗为绿色底色，上有白色新月和星星。绿色代表伊斯兰和穆斯林多数，白色象征宗教少数群体。",
            "BD": "孟加拉国旗为绿色底色，上有红色圆圈。红色圆圈象征升起的太阳和烈士的鲜血，绿色象征郁郁葱葱的景观。",
            "VN": "越南国旗为红色底色，中央有黄色五角星。红色象征革命和鲜血，黄色象征越南人民，星星代表团结。",
            "ID": "印度尼西亚国旗有两条相等的水平条纹：上红下白。红色象征勇气和独立，白色象征纯洁与和平。",
            "PH": "菲律宾国旗上蓝下红，旗杆侧有白色三角形，内含太阳和三颗星。蓝色象征和平，红色象征勇气。",
            "MY": "马来西亚国旗有14条红白相间的条纹，左上角蓝色区域有新月和14角星。条纹代表13个州和联邦直辖区。",
            "SG": "新加坡国旗有两条相等的水平条纹：上红下白，左上角有白色新月和五颗星。红色象征普遍兄弟情谊，白色象征纯洁。",
            "KR": "韩国国旗名为太极旗，白色底色，中央有红蓝阴阳符号，周围有四个黑色三卦，代表元素。",
            "NZ": "新西兰国旗为蓝色，左上角有英国国旗，四颗带白边的红星代表南十字星座。",
            "CL": "智利国旗有两条水平条纹：上白下红，左上角有蓝色正方形，内含白色五角星。星星象征进步和荣誉。"
        ]
        return descriptions[code] ?? "国旗代表国家的身份、历史和价值观。每种颜色和符号对国家都有特殊意义。"
    }
    
    // MARK: - Anthem Descriptions (Russian)
    private func getRussianAnthemDescription(for code: String) -> String {
        let descriptions: [String: String] = [
            "PL": "Польский гимн 'Мазурка Домбровского' (Польша ещё не погибла) был написан в 1797 году и стал официальным гимном в 1926 году. Он выражает надежду на независимость Польши.",
            "NL": "Голландский гимн 'Вильгельмус' — один из старейших гимнов в мире, восходящий к XVI веку. Он рассказывает историю Вильгельма Оранского.",
            "BE": "Бельгийский гимн 'Брабансонна' был написан во время Бельгийской революции 1830 года. Он прославляет независимость и единство страны.",
            "CH": "Швейцарский гимн 'Швейцарский псалом' был принят в 1981 году. Он восхваляет природную красоту Швейцарии и единство её разнообразных регионов.",
            "SE": "Шведский гимн 'Ты древняя, ты свободная' был написан в 1844 году. Он прославляет природную красоту и свободу Швеции.",
            "NO": "Норвежский гимн 'Да, мы любим эту страну' был написан в 1859 году. Он выражает глубокую любовь к норвежским пейзажам и народу.",
            "DK": "Датский гимн 'Есть прекрасная страна' был написан в 1819 году. Он прославляет природную красоту и мирный характер Дании.",
            "FI": "Финский гимн 'Наша земля' был написан в 1848 году. Он выражает любовь к природе Финляндии и финскому народу.",
            "PT": "Португальский гимн 'Португальская' был написан в 1890 году. Он прославляет морскую историю Португалии и национальную гордость.",
            "IE": "Ирландский гимн 'Песня солдата' был написан в 1907 году. Он стал официальным гимном в 1926 году, прославляя независимость Ирландии.",
            "CZ": "Чешский гимн состоит из двух частей: 'Где мой дом' и 'Молния над Татрами'. Обе части прославляют чешскую родину.",
            "HU": "Венгерский гимн 'Гимн' был написан в 1823 году. Это молитва о Божьем благословении Венгрии и её народа.",
            "RO": "Румынский гимн 'Пробудись, румын!' был написан в 1848 году. Он призывает к единству и свободе.",
            "BG": "Болгарский гимн 'Милая Родина' был написан в 1885 году. Он выражает любовь к горам и долинам Болгарии.",
            "HR": "Хорватский гимн 'Наша прекрасная родина' был написан в 1835 году. Он прославляет природную красоту Хорватии.",
            "RS": "Сербский гимн 'Боже правды' был написан в 1872 году. Это молитва о процветании и единстве Сербии.",
            "IL": "Израильский гимн 'Ха-Тиква' (Надежда) был написан в 1878 году. Он выражает надежду еврейского народа на родину в Израиле.",
            "SA": "Гимн Саудовской Аравии 'Да здравствует король' был принят в 1950 году. Он прославляет короля и страну.",
            "AE": "Гимн ОАЭ 'Да здравствует моя страна' был принят в 1971 году. Он прославляет единство семи эмиратов.",
            "IR": "Иранский гимн 'Национальный гимн Исламской Республики' был принят в 1990 году. Он прославляет Исламскую революцию и независимость Ирана.",
            "PK": "Пакистанский гимн 'Национальный гимн' был написан в 1954 году. Он восхваляет природную красоту и исламские ценности Пакистана.",
            "BD": "Бангладешский гимн 'Моя золотая Бенгалия' был написан Рабиндранатом Тагором в 1905 году. Он прославляет природную красоту Бенгалии.",
            "VN": "Вьетнамский гимн 'Марш на войну' был написан в 1944 году. Он стал официальным гимном в 1976 году, прославляя независимость Вьетнама.",
            "ID": "Индонезийский гимн 'Великая Индонезия' был написан в 1928 году. Он стал официальным гимном в 1945 году, прославляя единство Индонезии.",
            "PH": "Филиппинский гимн 'Избранная земля' был написан в 1898 году. Он прославляет природную красоту и независимость Филиппин.",
            "MY": "Малайзийский гимн 'Моя страна' был принят в 1957 году. Он прославляет единство и разнообразие Малайзии.",
            "SG": "Сингапурский гимн 'Вперёд, Сингапур' был написан в 1958 году. Он стал официальным гимном в 1965 году, призывая к прогрессу.",
            "KR": "Южнокорейский гимн 'Патриотическая песня' был написан в конце XIX века. Он прославляет историю и природную красоту Кореи.",
            "NZ": "Гимн Новой Зеландии 'Боже, защити Новую Зеландию' был написан в 1876 году. Он стал одним из двух официальных гимнов в 1977 году, восхваляя природную красоту Новой Зеландии.",
            "CL": "Чилийский гимн 'Национальный гимн Чили' был написан в 1819 году. Он прославляет независимость и природную красоту Чили."
        ]
        return descriptions[code] ?? "Национальный гимн — символ национальной гордости и единства, представляющий историю и устремления страны."
    }
    
    // MARK: - Anthem Meanings (Russian)
    private func getRussianAnthemMeaning(for code: String) -> String {
        let meanings: [String: String] = [
            "PL": "Гимн выражает решимость польского народа сохранить свою национальную идентичность и надежду на независимость, даже во времена иностранной оккупации.",
            "NL": "Гимн рассказывает историю Вильгельма Оранского, который возглавил голландскую борьбу за независимость от Испании, символизируя стойкость и свободу голландцев.",
            "BE": "Гимн прославляет независимость Бельгии от Нидерландов и единство её франкоязычных, нидерландоязычных и немецкоязычных сообществ.",
            "CH": "Гимн подчёркивает природную красоту Швейцарии, от гор до озёр, и единство её разнообразных языковых и культурных регионов.",
            "SE": "Гимн прославляет природные ландшафты Швеции, от северных гор до южных равнин, и любовь шведского народа к свободе.",
            "NO": "Гимн выражает глубокую любовь к норвежским фьордам, горам и народу, прославляя независимость и природную красоту Норвегии.",
            "DK": "Гимн прославляет мирный характер Дании, красивые пейзажи и связь датского народа со своей родиной.",
            "FI": "Гимн выражает любовь к финским озёрам, лесам и северному сиянию, прославляя стойкость и независимость финского народа.",
            "PT": "Гимн прославляет морскую историю Португалии, её исследователей и мужество и национальную гордость португальского народа.",
            "IE": "Гимн прославляет борьбу Ирландии за независимость и решимость ирландского народа быть свободными, выражая надежду на объединённую Ирландию.",
            "CZ": "Гимн прославляет красоту чешской родины, от богемских лесов до моравских полей, выражая любовь к чешскому народу и его традициям.",
            "HU": "Гимн — это молитва, просящая Бога благословить Венгрию, защитить её народ и даровать процветание нации.",
            "RO": "Гимн призывает румын пробудиться и объединиться, прославляя независимость страны и мужество румынского народа.",
            "BG": "Гимн выражает глубокую любовь к горам, долинам Болгарии и болгарскому народу, прославляя природную красоту страны.",
            "HR": "Гимн прославляет адриатическое побережье, горы Хорватии и любовь хорватского народа к своей прекрасной родине.",
            "RS": "Гимн — это молитва о процветании, единстве Сербии и Божьей защите, прославляющая стойкость сербского народа.",
            "IL": "Гимн выражает 2000-летнюю надежду еврейского народа вернуться на свою историческую родину в Израиле, прославляя еврейскую идентичность и свободу.",
            "SA": "Гимн восхваляет саудовского короля и прославляет исламские ценности, единство и процветание страны.",
            "AE": "Гимн прославляет единство семи эмиратов, их прогресс и роль ОАЭ как современной арабской нации.",
            "IR": "Гимн прославляет Исламскую революцию, независимость Ирана и приверженность иранского народа исламским ценностям.",
            "PK": "Гимн прославляет природную красоту Пакистана, от гор до равнин, и исламскую идентичность и ценности страны.",
            "BD": "Гимн выражает любовь к рекам, полям и народу Бенгалии, прославляя природную красоту и культурное наследие региона.",
            "VN": "Гимн прославляет борьбу Вьетнама за независимость, решимость вьетнамского народа и единство страны.",
            "ID": "Гимн прославляет единство Индонезии на её тысячах островов, выражая надежду на великую и объединённую Индонезию.",
            "PH": "Гимн прославляет природную красоту Филиппин, от гор до морей, и любовь филиппинского народа к своей избранной земле.",
            "MY": "Гимн прославляет единство Малайзии, несмотря на её разнообразие, выражая надежду на процветание и прогресс страны.",
            "SG": "Гимн призывает сингапурцев двигаться вперёд вместе, прославляя единство, разнообразие и решимость нации добиться успеха.",
            "KR": "Гимн прославляет 5000-летнюю историю Кореи, её природную красоту и любовь корейского народа к своей родине.",
            "NZ": "Гимн прославляет природную красоту Новой Зеландии, от гор до морей, и просит Бога защитить и оборонить нацию.",
            "CL": "Гимн прославляет независимость Чили, её природную красоту от пустыни Атакама до Патагонии и мужество чилийского народа."
        ]
        return meanings[code] ?? "Гимн прославляет природную красоту страны, её культурное наследие и единство народа."
    }
    
    // MARK: - Anthem Descriptions (Spanish, Ukrainian, Catalan, Chinese) - Simplified versions
    private func getSpanishAnthemDescription(for code: String) -> String {
        // Используем английские описания как основу, можно расширить позже
        return getEnglishAnthemDescription(for: code)
    }
    
    private func getUkrainianAnthemDescription(for code: String) -> String {
        return getEnglishAnthemDescription(for: code)
    }
    
    private func getCatalanAnthemDescription(for code: String) -> String {
        return getEnglishAnthemDescription(for: code)
    }
    
    private func getChineseAnthemDescription(for code: String) -> String {
        return getEnglishAnthemDescription(for: code)
    }
    
    private func getSpanishAnthemMeaning(for code: String) -> String {
        return getEnglishAnthemMeaning(for: code)
    }
    
    private func getUkrainianAnthemMeaning(for code: String) -> String {
        return getEnglishAnthemMeaning(for: code)
    }
    
    private func getCatalanAnthemMeaning(for code: String) -> String {
        return getEnglishAnthemMeaning(for: code)
    }
    
    private func getChineseAnthemMeaning(for code: String) -> String {
        return getEnglishAnthemMeaning(for: code)
    }
    
    // MARK: - Anthem Texts (English)
    private func getEnglishAnthemText(for code: String) -> String {
        let texts: [String: String] = [
            "AT": "Land der Berge, Land am Strome,\nLand der Äcker, Land der Dome,\nLand der Hämmer, zukunftsreich!\nHeimat großer Töchter und Söhne,\nVolk, begnadet für das Schöne,\nVielgerühmtes Österreich!\n\nHeiß umfehdet, wild umstritten,\nLiegst dem Erdteil du inmitten,\nEinem starken Herzen gleich.\nHast seit frühen Ahnentagen\nHoher Sendung Last getragen,\nVielgeprüftes Österreich!\n\nMutig in die neuen Zeiten,\nFrei und gläubig sieh uns schreiten,\nArbeitsfroh und hoffnungsreich.\nEinig laß in Brüderchören,\nVaterland, dir Treue schwören.\nVielgeliebtes Österreich!",
            "US": "O say can you see, by the dawn's early light,\nWhat so proudly we hailed at the twilight's last gleaming,\nWhose broad stripes and bright stars through the perilous fight,\nO'er the ramparts we watched, were so gallantly streaming?\nAnd the rockets' red glare, the bombs bursting in air,\nGave proof through the night that our flag was still there;\nO say does that star-spangled banner yet wave\nO'er the land of the free and the home of the brave?",
            "GB": "God save our gracious King!\nLong live our noble King!\nGod save the King!\nSend him victorious,\nHappy and glorious,\nLong to reign over us,\nGod save the King!\n\nThy choicest gifts in store\nOn him be pleased to pour,\nLong may he reign.\nMay he defend our laws,\nAnd ever give us cause,\nTo sing with heart and voice,\nGod save the King!",
            "FR": "Allons enfants de la Patrie,\nLe jour de gloire est arrivé!\nContre nous de la tyrannie,\nL'étendard sanglant est levé,\nL'étendard sanglant est levé,\nEntendez-vous dans les campagnes\nMugir ces féroces soldats?\nIls viennent jusque dans vos bras\nÉgorger vos fils, vos compagnes!\n\nAux armes, citoyens!\nFormez vos bataillons!\nMarchons, marchons!\nQu'un sang impur\nAbreuve nos sillons!",
            "DE": "Einigkeit und Recht und Freiheit\nFür das deutsche Vaterland!\nDanach lasst uns alle streben\nBrüderlich mit Herz und Hand!\nEinigkeit und Recht und Freiheit\nSind des Glückes Unterpfand;\nBlüh im Glanze dieses Glückes,\nBlühe, deutsches Vaterland!",
            "IT": "Fratelli d'Italia,\nL'Italia s'è desta,\nDell'elmo di Scipio\nS'è cinta la testa.\nDov'è la Vittoria?\nLe porga la chioma,\nChé schiava di Roma\nIddio la creò.\n\nStringiamci a coorte,\nSiam pronti alla morte.\nSiam pronti alla morte,\nL'Italia chiamò.\nStringiamci a coorte,\nSiam pronti alla morte.\nSiam pronti alla morte,\nL'Italia chiamò!",
            "ES": "Marcha Real\n(No official lyrics)",
            "RU": "Россия — священная наша держава,\nРоссия — любимая наша страна.\nМогучая воля, великая слава —\nТвоё достоянье на все времена!\n\nСлавься, Отечество наше свободное,\nБратских народов союз вековой,\nПредками данная мудрость народная!\nСлавься, страна! Мы гордимся тобой!",
            "CN": "起来！不愿做奴隶的人们！\n把我们的血肉，筑成我们新的长城！\n中华民族到了最危险的时候，\n每个人被迫着发出最后的吼声。\n起来！起来！起来！\n我们万众一心，\n冒着敌人的炮火，前进！\n冒着敌人的炮火，前进！\n前进！前进！进！",
            "JP": "君が代は\n千代に八千代に\nさざれ石の\nいわおとなりて\nこけのむすまで",
            "PL": "Jeszcze Polska nie zginęła,\nKiedy my żyjemy.\nCo nam obca przemoc wzięła,\nSzablą odbierzemy.\n\nMarsz, marsz, Dąbrowski,\nZ ziemi włoskiej do Polski.\nZa twoim przewodem\nZłączym się z narodem.",
            "NL": "Wilhelmus van Nassouwe\nBen ik, van Duitsen bloed,\nDen vaderland getrouwe\nBlijf ik tot in den dood.\nEen Prinse van Oranje\nBen ik, vrij, onverveerd,\nDen Koning van Hispanje\nHeb ik altijd geëerd.",
            "BE": "O dierbaar België,\nO heilig land der vaad'ren,\nOnze ziel en ons hart zijn u gewijd.\nAanvaard ons kracht en het bloed van onze ad'ren,\nWees ons doel in arbeid en in strijd.\nBloei, o land, in eendracht niet te breken,\nWees immer uzelf en ongeknecht,\nHet woord getrouw, dat ge onbevreesd moogt spreken,\nVoor Vorst, voor Vrijheid en voor Recht!",
            "CH": "Trittst im Morgenrot daher,\nSeh' ich dich im Strahlenmeer,\nDich, du Hocherhabener, Herrlicher!\nWenn der Alpenfirn sich rötet,\nBetet, freie Schweizer, betet!\nEure fromme Seele ahnt\nEure fromme Seele ahnt\nGott im hehren Vaterland,\nGott, den Herrn, im hehren Vaterland.",
            "SE": "Du gamla, Du fria, Du fjällhöga nord\nDu tysta, Du glädjerika sköna!\nJag hälsar Dig, vänaste land uppå jord,\nDin sol, Din himmel, Dina ängder gröna.\nDin sol, Din himmel, Dina ängder gröna.\n\nDu tronar på minnen från fornstora dar,\ndå ärat Ditt namn flög över jorden.\nJag vet att Du är och Du blir vad Du var.\nJa, jag vill leva, jag vill dö i Norden.",
            "NO": "Ja, vi elsker dette landet,\nsom det stiger frem,\nfuret, værbitt over vannet,\nmed de tusen hjem.\nElsker, elsker det og tenker\npå vår far og mor\nog den saganatt som senker\ndrømme på vår jord.",
            "DK": "Der er et yndigt land,\ndet står med brede bøge\nnær salten østerstrand.\nDet bugter sig i bakke, dal,\ndet hedder gamle Danmark\nog det er Frejas sal.",
            "FI": "Oi maamme, Suomi, synnyinmaa,\nsoi, sana kultainen!\nEi laaksoa, ei kukkulaa,\nei vettä, rantaa rakkaampaa\nkuin kotimaa tää pohjoinen,\nmaa kallis isien.",
            "PT": "Heróis do mar, nobre povo,\nNação valente, imortal,\nLevantai hoje de novo\nO esplendor de Portugal!\nEntre as brumas da memória,\nÓ Pátria, sente-se a voz\nDos teus egrégios avós,\nQue há-de guiar-te à vitória!",
            "IE": "Amhrán na bhFiann\n(We'll sing a song, a soldier's song,\nWith cheering rousing chorus,\nAs round our blazing fires we thong,\nThe starry heavens o'er us;\nImpatient for the coming fight,\nAnd as we wait the morning's light,\nHere in the silence of the night,\nWe'll chant a soldier's song.)",
            "CZ": "Kde domov můj, kde domov můj?\nVoda hučí po lučinách,\nbory šumí po skalinách,\nv sadě skví se jara květ,\nzemský ráj to na pohled!\nA to je ta krásná země,\nzemě česká, domov můj,\nzemě česká, domov můj!",
            "HU": "Isten, áldd meg a magyart\nJó kedvvel, bőséggel,\nNyújts feléje védő kart,\nHa küzd ellenséggel;\nBal sors akit régen tép,\nHozz rá víg esztendőt,\nMegbűnhődte már e nép\nA múltat s jövendőt!",
            "RO": "Deșteaptă-te, române, din somnul cel de moarte,\nÎn care te-adânciră barbarii de tirani!\nAcum ori niciodată croiește-ți altă soarte,\nLa care să se-nchine și cruzii tăi dușmani!\n\nAcum ori niciodată să dăm dovezi în lume\nCă-n aste mâni mai curge un sânge de roman,\nȘi că-n a noastre piepturi păstrăm cu fală-un nume\nTriumfător în lupte, un nume de Traian!",
            "BG": "Горда Стара планина,\nдо ней Дунава синей,\nслънце Тракия огрява,\nнад Пирина пламеней.\n\nПрипев:\nМила Родино,\nти си земен рай,\nтвоята хубост, твоята прелест,\nах, те нямат край.",
            "HR": "Lijepa naša domovino,\nOj junačka zemljo mila,\nStare slave djedovino,\nDa bi vazda sretna bila!\n\nMila, kano si nam slavna,\nMila si nam ti jedina.\nMila, kuda si nam ravna,\nMila, kuda si planina!",
            "RS": "Боже правде, ти што спасе\nод пропасти досад нас,\nчуј и од сад наше гласе\nи од сад нам буди спас.\n\nМоћном руком води, брани\nбудућности српске брод,\nБоже спаси, Боже храни,\nсрпске земље, српски род!",
            "IL": "כל עוד בלבב פנימה\nנפש יהודי הומיה,\nולפאתי מזרח קדימה\nעין לציון צופיה,\n\nעוד לא אבדה תקותנו,\nהתקוה בת שנות אלפים,\nלהיות עם חופשי בארצנו\nארץ ציון וירושלים.",
            "SA": "سارعي للمجد والعلياء\nمجدي لخالق السماء\nوارفعي الخفاق الأخضر\nيحمل النور المسطر\n\nرددي الله أكبر\nيا موطني\nموطني عشت فخر المسلمين\nعاش الملك للعلم والوطن",
            "AE": "عيشي بلادي عاش اتحاد إماراتنا\nعشت لشعب دينه الإسلام هديه القرآن\nحسبتك الله الوطن\n\nكلنا نفديك بالدماء نفديك\nنفديك بالأرواح يا وطن",
            "IR": "سر زد از افق مهر خاوران\nفروغ دیدهی حق باوران\nبهمن فر ایمان ماست\nپیامت ای امام، استقلال، آزادی نقش جان ماست\n\nشهیدان، پیچیده در گوش زمان فریادتان\nپاینده مانی و جاودان\nجمهوری اسلامی ایران",
            "PK": "قومی ترانہ\nپاک سرزمین شاد باد\nکشور حسین شاد باد\nتو نشان عزمِ عالی شان\nارض پاکستان\nمرکز یقین شاد باد",
            "BD": "আমার সোনার বাংলা\nআমি তোমায় ভালোবাসি\nচিরদিন তোমার আকাশ\nতোমার বাতাস\nআমার প্রাণে বাজায় বাঁশি",
            "VN": "Đoàn quân Việt Nam đi\nChung lòng cứu quốc\nBước chân dồn vang trên đường gập ghềnh xa\nCờ in máu chiến thắng mang hồn nước\nSúng ngoài xa chen khúc quân hành ca\nĐường vinh quang xây xác quân thù\nThắng gian lao cùng nhau lập chiến khu\nVì nhân dân chiến đấu không ngừng",
            "ID": "Indonesia Raya\nMerdeka, merdeka, Tanahku, negeriku yang kucinta!\nIndonesia Raya\nMerdeka, merdeka, Hiduplah Indonesia Raya!",
            "PH": "Lupang Hinirang\nBayang magiliw\nPerlas ng silanganan\nAlab ng puso\nSa dibdib mo'y buhay.\n\nLupang Hinirang,\nDuyan ka ng magiting,\nSa manlulupig\nDi ka pasisiil.",
            "MY": "Negaraku, tanah tumpahnya darahku,\nRakyat hidup bersatu dan maju,\nRahmat bahagia Tuhan kurniakan,\nRaja kita selamat bertakhta.\nRahmat bahagia Tuhan kurniakan,\nRaja kita selamat bertakhta.",
            "SG": "Majulah Singapura\nMari kita rakyat Singapura\nSama-sama menuju bahagia\nCita-cita kita yang mulia\nBerjaya Singapura",
            "KR": "동해 물과 백두산이 마르고 닳도록\n하느님이 보우하사 우리나라 만세.\n무궁화 삼천리 화려 강산\n대한 사람 대한으로 길이 보전하세.",
            "NZ": "God of Nations at Thy feet,\nIn the bonds of love we meet,\nHear our voices, we entreat,\nGod defend our free land.\nGuard Pacific's triple star\nFrom the shafts of strife and war,\nMake her praises heard afar,\nGod defend New Zealand.",
            "CL": "Puro, Chile, es tu cielo azulado,\npuras brisas te cruzan también,\ny tu campo de flores bordado\nes la copia feliz del Edén.\nMajestuosa es la blanca montaña\nque te dio por baluarte el Señor,\ny ese mar que tranquilo te baña\nte promete el futuro esplendor."
        ]
        return texts[code] ?? "National anthem text is a symbol of national pride and unity."
    }
    
    // MARK: - Anthem Texts (Russian)
    private func getRussianAnthemText(for code: String) -> String {
        let texts: [String: String] = [
            "AT": "Страна гор, страна у реки,\nСтрана полей, страна соборов,\nСтрана молотов, богатая будущим!\nРодина великих дочерей и сыновей,\nНарод, одарённый красотой,\nМногославная Австрия!",
            "US": "О, скажи, видишь ли ты в первых лучах зари,\nТо, чем мы так гордились в последнем отблеске заката?\nЧьи широкие полосы и яркие звёзды в опасной битве\nНад стенами, которые мы охраняли, так храбро реяли?\nИ красное сияние ракет, бомбы, взрывающиеся в воздухе,\nДоказали ночью, что наш флаг всё ещё там;\nО, скажи, развевается ли звёздно-полосатый флаг\nНад землёй свободных и домом храбрых?",
            "GB": "Боже, храни нашего милостивого Короля!\nДа здравствует наш благородный Король!\nБоже, храни Короля!\nПошли ему победу,\nСчастье и славу,\nДолго царствовать над нами,\nБоже, храни Короля!",
            "FR": "Вперёд, дети Отечества,\nДень славы настал!\nПротив нас тирания\nПодняла кровавое знамя,\nПодняла кровавое знамя.\nСлышите ли вы в полях\nРёв этих свирепых солдат?\nОни идут прямо в ваши объятия\nРезать ваших сыновей, ваших подруг!\n\nК оружию, граждане!\nФормируйте батальоны!\nМаршируем, маршируем!\nПусть нечистая кровь\nОросит наши борозды!",
            "DE": "Единство, право и свобода\nДля немецкого Отечества!\nК этому давайте все стремиться\nПо-братски сердцем и рукой!\nЕдинство, право и свобода\nЯвляются залогом счастья;\nЦвети в блеске этого счастья,\nЦвети, немецкое Отечество!",
            "IT": "Братья Италии,\nИталия пробудилась,\nШлемом Сципиона\nОкружена голова.\nГде Победа?\nПусть склонит она голову,\nИбо рабыня Рима\nБогом создана она.",
            "ES": "Королевский марш\n(Официальных слов нет)",
            "RU": "Россия — священная наша держава,\nРоссия — любимая наша страна.\nМогучая воля, великая слава —\nТвоё достоянье на все времена!\n\nСлавься, Отечество наше свободное,\nБратских народов союз вековой,\nПредками данная мудрость народная!\nСлавься, страна! Мы гордимся тобой!",
            "CN": "Вставайте! Те, кто не желает быть рабами!\nИз нашей плоти и крови построим новую Великую стену!\nКитайская нация в самой опасной ситуации,\nКаждый вынужден издавать последний крик.\nВставайте! Вставайте! Вставайте!\nМы миллионы как один,\nПод огнём врага, вперёд!\nПод огнём врага, вперёд!\nВперёд! Вперёд! Вперёд!",
            "JP": "Пусть правление императора\nПродлится тысячу, восемь тысяч поколений,\nПока камешек\nНе станет скалой,\nПокрытой мхом.",
            "PL": "Ещё Польша не погибла,\nПока мы живём.\nЧто у нас отняла чужая сила,\nСаблей отберём.\n\nМарш, марш, Домбровский,\nИз итальянской земли в Польшу.\nПод твоим предводительством\nОбъединимся с народом.",
            "NL": "Вильгельм Нассауский\nЯ, немецкой крови,\nОтечеству верный\nОстанусь до смерти.\nПринц Оранский\nЯ, свободный, бесстрашный,\nКороля Испании\nЯ всегда почитал.",
            "BE": "О дорогая Бельгия,\nО священная земля отцов,\nНаша душа и наше сердце посвящены тебе.\nПрими нашу силу и кровь наших вен,\nБудь нашей целью в труде и в борьбе.\nЦвети, о страна, в единстве нерушимом,\nБудь всегда сама собой и не порабощённой,\nСлову верна, которое ты можешь говорить бесстрашно,\nЗа Короля, за Свободу и за Право!",
            "CH": "В утренней заре появляешься,\nВижу тебя в море лучей,\nТебя, возвышенного, великолепного!\nКогда альпийский снег краснеет,\nМолись, свободные швейцарцы, молись!\nТвоя благочестивая душа предчувствует\nБога в возвышенном Отечестве,\nБога, Господа, в возвышенном Отечестве.",
            "SE": "Ты древняя, ты свободная, ты горная северная,\nТы тихая, ты радостная, прекрасная!\nПриветствую тебя, милейшая страна на земле,\nТвоё солнце, твоё небо, твои зелёные луга.",
            "NO": "Да, мы любим эту страну,\nКак она возвышается,\nИзрезанная, обветренная над водой,\nС тысячами домов.\nЛюбим, любим её и думаем\nО нашем отце и матери\nИ о саге ночи, которая погружает\nМечты на нашу землю.",
            "DK": "Есть прекрасная страна,\nОна стоит с широкими буками\nУ солёного восточного берега.\nОна извивается в холмах, долинах,\nОна называется старая Дания\nИ это зал Фрейи.",
            "FI": "О наша земля, Финляндия, родина,\nЗвучи, золотое слово!\nНет долины, нет холма,\nНет воды, берега дороже\nЧем эта северная родина,\nДорогая земля отцов.",
            "PT": "Герои моря, благородный народ,\nХрабрая нация, бессмертная,\nПоднимите сегодня снова\nВеликолепие Португалии!\nСреди туманов памяти,\nО Родина, чувствуется голос\nТвоих знаменитых предков,\nКоторый должен вести тебя к победе!",
            "IE": "Песня солдата\n(Мы споём песню, песню солдата,\nС бодрящим припевом,\nКак вокруг наших пылающих костров мы толпимся,\nЗвёздные небеса над нами;\nНетерпеливые к предстоящей битве,\nИ пока мы ждём утренний свет,\nЗдесь в тишине ночи,\nМы пропоём песню солдата.)",
            "CZ": "Где мой дом, где мой дом?\nВода шумит по лугам,\nБоры шумят по скалам,\nВ саду сверкает весенний цвет,\nЗемной рай на вид!\nИ это прекрасная страна,\nЧешская земля, мой дом,\nЧешская земля, мой дом!",
            "HU": "Боже, благослови венгра\nС хорошим настроением, изобилием,\nПротяни к нему защищающую руку,\nЕсли он борется с врагом;\nЗлая судьба, которая давно терзала его,\nПринеси ему радостный год,\nЭтот народ уже искупил\nПрошлое и будущее!",
            "RO": "Пробудись, румын, от смертного сна,\nВ который погрузили тебя варвары-тираны!\nТеперь или никогда создай себе другую судьбу,\nК которой склонятся и твои жестокие враги!",
            "BG": "Горда Стара планина,\nдо ней Дунава синей,\nслънце Тракия огрява,\nнад Пирина пламеней.\n\nПрипев:\nМила Родино,\nти си земен рай,\nтвоята хубост, твоята прелест,\nах, те нямат край.",
            "HR": "Наша прекрасная родина,\nО храбрая земля милая,\nРодина старой славы предков,\nДа будешь всегда счастливой!\n\nМилая, как ты нам славна,\nМилая ты нам единственная.\nМилая, где ты нам ровна,\nМилая, где ты гора!",
            "RS": "Боже правды, Ты, что спас\nОт пропасти до сих пор нас,\nУслышь и отныне наши голоса\nИ отныне будь нам спасением.\n\nМощной рукой веди, защищай\nБудущее сербского корабля,\nБоже спаси, Боже храни,\nСербские земли, сербский род!",
            "IL": "Пока в глубине сердца\nЕврейская душа тоскует,\nИ к востоку, вперёд\nГлаз смотрит на Сион,\n\nЕщё не потеряна наша надежда,\nНадежда двух тысяч лет,\nБыть свободным народом на нашей земле,\nЗемле Сиона и Иерусалима.",
            "SA": "Спеши к славе и величию,\nПрославляй Творца небес,\nИ подними зелёный флаг,\nНесущий записанный свет.\n\nПовторяй: Аллах велик,\nО моя родина,\nМоя родина, ты живёшь славой мусульман,\nДа живёт король за науку и родину",
            "AE": "Живи, моя страна, да живёт союз наших эмиратов,\nТы живёшь для народа, религия которого ислам, его руководство — Коран.\nДовольно тебе Бог — родина",
            "IR": "Восходит с горизонта солнце Востока,\nСвет очей верующих в истину.\nБахман — это вера наша,\nТвоё послание, о Имам, независимость, свобода — это суть нашей души",
            "PK": "Национальный гимн\nДа здравствует священная земля,\nДа здравствует прекрасная страна,\nТы символ высокой решимости\nЗемли Пакистана,\nЦентр уверенности, да здравствует",
            "BD": "Моя золотая Бенгалия,\nЯ люблю тебя.\nВечно твоё небо,\nТвой воздух\nИграет флейту в моей душе",
            "VN": "Вьетнамская армия идёт,\nЕдиным сердцем спасая страну,\nШаги гремят на далёкой неровной дороге,\nФлаг, окрашенный кровью победы, несёт душу нации",
            "ID": "Великая Индонезия\nСвободна, свободна, моя земля, моя страна, которую я люблю!\nВеликая Индонезия\nСвободна, свободна, да здравствует Великая Индонезия!",
            "PH": "Избранная земля\nЛюбимая страна,\nЖемчужина Востока,\nПламя сердца\nВ твоей груди живёт.",
            "MY": "Моя страна, земля, где пролита моя кровь,\nНарод живёт едино и прогрессирует,\nБлагословение счастья дарует Бог,\nНаш король благополучно правит.",
            "SG": "Вперёд, Сингапур\nДавайте мы, народ Сингапура,\nВместе идём к счастью\nНаша благородная цель\nДа преуспеет Сингапур",
            "KR": "Пока воды Восточного моря не высохнут и гора Пэкту не сотрётся,\nДа защитит Бог нашу страну навеки.\nРоза Шарона, три тысячи ли прекрасных рек и гор,\nКорейцы, да сохраним мы Корею вечно.",
            "NZ": "Бог наций у Твоих ног,\nВ узах любви мы встречаемся,\nУслышь наши голоса, мы умоляем,\nБоже, защити нашу свободную землю.",
            "CL": "Чист, Чили, твоё голубое небо,\nЧистые бризы пересекают тебя тоже,\nИ твоё поле, вышитое цветами,\nЭто счастливая копия Эдема."
        ]
        return texts[code] ?? getEnglishAnthemText(for: code)
    }
    
    // MARK: - Anthem Texts (Other languages - using English as base for now)
    private func getSpanishAnthemText(for code: String) -> String {
        return getEnglishAnthemText(for: code)
    }
    
    private func getUkrainianAnthemText(for code: String) -> String {
        return getEnglishAnthemText(for: code)
    }
    
    private func getCatalanAnthemText(for code: String) -> String {
        return getEnglishAnthemText(for: code)
    }
    
    private func getChineseAnthemText(for code: String) -> String {
        return getEnglishAnthemText(for: code)
    }
}
