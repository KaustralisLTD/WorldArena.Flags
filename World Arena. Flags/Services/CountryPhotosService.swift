import Foundation

// MARK: - Country Photos Service
class CountryPhotosService {
    static let shared = CountryPhotosService()
    
    private init() {}
    
    // MARK: - Real Country Photos Database
    func getPhotos(for countryCode: String) -> [CountryPhoto] {
        switch countryCode.uppercased() {
        case "US": return usaPhotos
        case "GB": return ukPhotos
        case "FR": return francePhotos
        case "DE": return germanyPhotos
        case "IT": return italyPhotos
        case "ES": return spainPhotos
        case "JP": return japanPhotos
        case "CN": return chinaPhotos
        case "RU": return russiaPhotos
        case "BR": return brazilPhotos
        case "CA": return canadaPhotos
        case "AU": return australiaPhotos
        case "IN": return indiaPhotos
        case "MX": return mexicoPhotos
        case "EG": return egyptPhotos
        case "GR": return greecePhotos
        case "TR": return turkeyPhotos
        case "TH": return thailandPhotos
        case "AR": return argentinaPhotos
        case "ZA": return southAfricaPhotos
        default: return defaultPhotos(for: countryCode)
        }
    }
    
    // MARK: - USA Photos
    private var usaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "usa_flag",
                type: .flag,
                title: "Stars and Stripes",
                description: "50 stars representing states, 13 stripes for original colonies",
                imageURL: "https://flags.worldarena.games/photos/usa_flag.jpg",
                localImage: "🇺🇸"
            ),
            CountryPhoto(
                id: "usa_coat_of_arms",
                type: .coatOfArms,
                title: "Great Seal of the United States",
                description: "National coat of arms featuring bald eagle",
                imageURL: "https://flags.worldarena.games/photos/usa_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "usa_statue_liberty",
                type: .landmark,
                title: "Statue of Liberty", 
                description: "Gift from France, symbol of freedom and democracy",
                imageURL: "https://flags.worldarena.games/photos/usa_statue_liberty.jpg",
                localImage: "🗽"
            ),
            CountryPhoto(
                id: "usa_grand_canyon",
                type: .nature,
                title: "Grand Canyon",
                description: "Massive canyon carved by Colorado River in Arizona",
                imageURL: "https://flags.worldarena.games/photos/usa_grand_canyon.jpg",
                localImage: "🏜️"
            ),
            CountryPhoto(
                id: "usa_white_house",
                type: .government,
                title: "White House",
                description: "Official residence of the US President in Washington DC",
                imageURL: "https://flags.worldarena.games/photos/usa_white_house.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "usa_hollywood",
                type: .culture,
                title: "Hollywood Sign",
                description: "Iconic sign representing American entertainment industry",
                imageURL: "https://flags.worldarena.games/photos/usa_hollywood.jpg",
                localImage: "🎬"
            )
        ]
    }
    
    // MARK: - UK Photos
    private var ukPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "uk_flag",
                type: .flag,
                title: "Union Jack",
                description: "Flag combining England, Scotland, and Ireland",
                imageURL: "https://flags.worldarena.games/photos/uk_flag.jpg",
                localImage: "🇬🇧"
            ),
            CountryPhoto(
                id: "uk_coat_of_arms",
                type: .coatOfArms,
                title: "Royal Coat of Arms",
                description: "Royal heraldic symbol with lion and unicorn",
                imageURL: "https://flags.worldarena.games/photos/uk_coat_of_arms.jpg",
                localImage: "👑"
            ),
            CountryPhoto(
                id: "uk_big_ben",
                type: .landmark,
                title: "Big Ben",
                description: "Iconic clock tower in London",
                imageURL: "https://flags.worldarena.games/photos/uk_big_ben.jpg",
                localImage: "🕰️"
            ),
            CountryPhoto(
                id: "uk_stonehenge",
                type: .landmark,
                title: "Stonehenge",
                description: "Prehistoric monument in Wiltshire",
                imageURL: "https://flags.worldarena.games/photos/uk_stonehenge.jpg",
                localImage: "⭕"
            ),
            CountryPhoto(
                id: "uk_buckingham_palace",
                type: .government,
                title: "Buckingham Palace",
                description: "Official residence of British monarch",
                imageURL: "https://flags.worldarena.games/photos/uk_buckingham_palace.jpg",
                localImage: "🏰"
            ),
            CountryPhoto(
                id: "uk_scottish_highlands",
                type: .nature,
                title: "Scottish Highlands",
                description: "Mountainous region in northern Scotland",
                imageURL: "https://flags.worldarena.games/photos/uk_scottish_highlands.jpg",
                localImage: "🏔️"
            )
        ]
    }
    
    // MARK: - France Photos  
    private var francePhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "france_flag",
                type: .flag,
                title: "Tricolore",
                description: "Blue, white, and red tricolor representing liberty, equality, fraternity",
                imageURL: "https://flags.worldarena.games/photos/france_flag.jpg",
                localImage: "🇫🇷"
            ),
            CountryPhoto(
                id: "france_coat_of_arms",
                type: .coatOfArms,
                title: "National Emblem of France",
                description: "Fasces with oak and olive branches",
                imageURL: "https://flags.worldarena.games/photos/france_coat_of_arms.jpg",
                localImage: "⚜️"
            ),
            CountryPhoto(
                id: "france_eiffel_tower",
                type: .landmark,
                title: "Eiffel Tower",
                description: "Iron tower and symbol of Paris, built in 1889",
                imageURL: "https://flags.worldarena.games/photos/france_eiffel_tower.jpg",
                localImage: "🗼"
            ),
            CountryPhoto(
                id: "france_louvre",
                type: .culture,
                title: "Louvre Museum",
                description: "World's largest art museum in Paris",
                imageURL: "https://flags.worldarena.games/photos/france_louvre.jpg",
                localImage: "🎨"
            ),
            CountryPhoto(
                id: "france_versailles",
                type: .government,
                title: "Palace of Versailles",
                description: "Opulent royal residence near Paris",
                imageURL: "https://flags.worldarena.games/photos/france_versailles.jpg",
                localImage: "👑"
            ),
            CountryPhoto(
                id: "france_provence",
                type: .nature,
                title: "Provence Lavender Fields",
                description: "Purple lavender fields in southeastern France",
                imageURL: "https://flags.worldarena.games/photos/france_provence.jpg",
                localImage: "💜"
            )
        ]
    }
    
    // MARK: - Germany Photos
    private var germanyPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "germany_flag",
                type: .flag,
                title: "German Flag",
                description: "Black, red, and gold horizontal stripes",
                imageURL: "https://flags.worldarena.games/photos/germany_flag.jpg",
                localImage: "🇩🇪"
            ),
            CountryPhoto(
                id: "germany_coat_of_arms",
                type: .coatOfArms,
                title: "German Federal Eagle",
                description: "Black eagle on yellow background",
                imageURL: "https://flags.worldarena.games/photos/germany_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "germany_brandenburg_gate",
                type: .landmark,
                title: "Brandenburg Gate",
                description: "Neoclassical monument in Berlin",
                imageURL: "https://flags.worldarena.games/photos/germany_brandenburg_gate.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "germany_neuschwanstein",
                type: .landmark,
                title: "Neuschwanstein Castle",
                description: "Fairy-tale castle in Bavaria",
                imageURL: "https://flags.worldarena.games/photos/germany_neuschwanstein.jpg",
                localImage: "🏰"
            ),
            CountryPhoto(
                id: "germany_black_forest",
                type: .nature,
                title: "Black Forest",
                description: "Dense forested mountain range in Baden-Württemberg",
                imageURL: "https://flags.worldarena.games/photos/germany_black_forest.jpg",
                localImage: "🌲"
            ),
            CountryPhoto(
                id: "germany_oktoberfest",
                type: .culture,
                title: "Oktoberfest",
                description: "World's largest beer festival in Munich",
                imageURL: "https://flags.worldarena.games/photos/germany_oktoberfest.jpg",
                localImage: "🍺"
            )
        ]
    }
    
    // MARK: - Italy Photos
    private var italyPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "italy_flag",
                type: .flag,
                title: "Italian Tricolour",
                description: "Green, white, and red vertical stripes",
                imageURL: "https://flags.worldarena.games/photos/italy_flag.jpg",
                localImage: "🇮🇹"
            ),
            CountryPhoto(
                id: "italy_coat_of_arms",
                type: .coatOfArms,
                title: "Emblem of Italy",
                description: "Five-pointed star with cogwheel and olive branches",
                imageURL: "https://flags.worldarena.games/photos/italy_coat_of_arms.jpg",
                localImage: "⭐"
            ),
            CountryPhoto(
                id: "italy_colosseum",
                type: .landmark,
                title: "Colosseum",
                description: "Ancient Roman amphitheatre in Rome",
                imageURL: "https://flags.worldarena.games/photos/italy_colosseum.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "italy_leaning_tower",
                type: .landmark,
                title: "Leaning Tower of Pisa",
                description: "Famous tilted bell tower in Pisa",
                imageURL: "https://flags.worldarena.games/photos/italy_leaning_tower.jpg",
                localImage: "🗼"
            ),
            CountryPhoto(
                id: "italy_venice",
                type: .culture,
                title: "Venice Canals",
                description: "Historic city built on water with gondolas",
                imageURL: "https://flags.worldarena.games/photos/italy_venice.jpg",
                localImage: "🚣"
            ),
            CountryPhoto(
                id: "italy_tuscany",
                type: .nature,
                title: "Tuscany Hills",
                description: "Rolling hills with vineyards and cypress trees",
                imageURL: "https://flags.worldarena.games/photos/italy_tuscany.jpg",
                localImage: "🍇"
            )
        ]
    }
    
    // MARK: - Spain Photos
    private var spainPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "spain_flag",
                type: .flag,
                title: "Spanish Flag",
                description: "Red-yellow-red horizontal stripes with coat of arms",
                imageURL: "https://flags.worldarena.games/photos/spain_flag.jpg",
                localImage: "🇪🇸"
            ),
            CountryPhoto(
                id: "spain_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Spain",
                description: "Royal heraldic shield with crown",
                imageURL: "https://flags.worldarena.games/photos/spain_coat_of_arms.jpg",
                localImage: "👑"
            ),
            CountryPhoto(
                id: "spain_sagrada_familia",
                type: .landmark,
                title: "Sagrada Família",
                description: "Gaudí's unfinished basilica in Barcelona",
                imageURL: "https://flags.worldarena.games/photos/spain_sagrada_familia.jpg",
                localImage: "⛪"
            ),
            CountryPhoto(
                id: "spain_alhambra",
                type: .landmark,
                title: "Alhambra",
                description: "Moorish palace complex in Granada",
                imageURL: "https://flags.worldarena.games/photos/spain_alhambra.jpg",
                localImage: "🏰"
            ),
            CountryPhoto(
                id: "spain_flamenco",
                type: .culture,
                title: "Flamenco Dancing",
                description: "Traditional Spanish dance and music",
                imageURL: "https://flags.worldarena.games/photos/spain_flamenco.jpg",
                localImage: "💃"
            ),
            CountryPhoto(
                id: "spain_camino",
                type: .nature,
                title: "Camino de Santiago",
                description: "Historic pilgrimage route across northern Spain",
                imageURL: "https://flags.worldarena.games/photos/spain_camino.jpg",
                localImage: "🚶"
            )
        ]
    }
    
    // MARK: - Japan Photos
    private var japanPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "japan_flag",
                type: .flag,
                title: "Hinomaru",
                description: "Red circle representing the sun on white background",
                imageURL: "https://flags.worldarena.games/photos/japan_flag.jpg",
                localImage: "🇯🇵"
            ),
            CountryPhoto(
                id: "japan_coat_of_arms",
                type: .coatOfArms,
                title: "Imperial Seal of Japan",
                description: "Sixteen-petal chrysanthemum flower",
                imageURL: "https://flags.worldarena.games/photos/japan_coat_of_arms.jpg",
                localImage: "🌸"
            ),
            CountryPhoto(
                id: "japan_mount_fuji",
                type: .nature,
                title: "Mount Fuji",
                description: "Sacred mountain and highest peak in Japan",
                imageURL: "https://flags.worldarena.games/photos/japan_mount_fuji.jpg",
                localImage: "🗻"
            ),
            CountryPhoto(
                id: "japan_tokyo_tower",
                type: .landmark,
                title: "Tokyo Tower",
                description: "Communications tower inspired by Eiffel Tower",
                imageURL: "https://flags.worldarena.games/photos/japan_tokyo_tower.jpg",
                localImage: "🗼"
            ),
            CountryPhoto(
                id: "japan_cherry_blossoms",
                type: .culture,
                title: "Cherry Blossoms",
                description: "Sakura season celebrated throughout Japan",
                imageURL: "https://flags.worldarena.games/photos/japan_cherry_blossoms.jpg",
                localImage: "🌸"
            ),
            CountryPhoto(
                id: "japan_temple",
                type: .culture,
                title: "Traditional Temple",
                description: "Ancient Buddhist and Shinto temples",
                imageURL: "https://flags.worldarena.games/photos/japan_temple.jpg",
                localImage: "⛩️"
            )
        ]
    }
    
    // MARK: - China Photos
    private var chinaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "china_flag",
                type: .flag,
                title: "Five-starred Red Flag",
                description: "Red field with five yellow stars",
                imageURL: "https://flags.worldarena.games/photos/china_flag.jpg",
                localImage: "🇨🇳"
            ),
            CountryPhoto(
                id: "china_coat_of_arms",
                type: .coatOfArms,
                title: "National Emblem of China",
                description: "Tiananmen Gate with wheat and cogwheel",
                imageURL: "https://flags.worldarena.games/photos/china_coat_of_arms.jpg",
                localImage: "⭐"
            ),
            CountryPhoto(
                id: "china_great_wall",
                type: .landmark,
                title: "Great Wall of China",
                description: "Ancient fortification across northern China",
                imageURL: "https://flags.worldarena.games/photos/china_great_wall.jpg",
                localImage: "🏯"
            ),
            CountryPhoto(
                id: "china_forbidden_city",
                type: .government,
                title: "Forbidden City",
                description: "Imperial palace complex in Beijing",
                imageURL: "https://flags.worldarena.games/photos/china_forbidden_city.jpg",
                localImage: "🏰"
            ),
            CountryPhoto(
                id: "china_terracotta_army",
                type: .culture,
                title: "Terracotta Army",
                description: "Ancient army of clay soldiers in Xi'an",
                imageURL: "https://flags.worldarena.games/photos/china_terracotta_army.jpg",
                localImage: "🏺"
            ),
            CountryPhoto(
                id: "china_yangzte_river",
                type: .nature,
                title: "Yangtze River",
                description: "Longest river in Asia flowing through China",
                imageURL: "https://flags.worldarena.games/photos/china_yangzte_river.jpg",
                localImage: "🌊"
            )
        ]
    }
    
    // MARK: - Russia Photos
    private var russiaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "russia_flag",
                type: .flag,
                title: "Russian Tricolour",
                description: "White, blue, and red horizontal stripes",
                imageURL: "https://flags.worldarena.games/photos/russia_flag.jpg",
                localImage: "🇷🇺"
            ),
            CountryPhoto(
                id: "russia_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Russia",
                description: "Double-headed eagle with crown and scepter",
                imageURL: "https://flags.worldarena.games/photos/russia_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "russia_red_square",
                type: .landmark,
                title: "Red Square",
                description: "Historic square in Moscow with Kremlin",
                imageURL: "https://flags.worldarena.games/photos/russia_red_square.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "russia_st_basils",
                type: .landmark,
                title: "St. Basil's Cathedral",
                description: "Colorful onion-domed cathedral in Moscow",
                imageURL: "https://flags.worldarena.games/photos/russia_st_basils.jpg",
                localImage: "⛪"
            ),
            CountryPhoto(
                id: "russia_trans_siberian",
                type: .culture,
                title: "Trans-Siberian Railway",
                description: "World's longest railway line across Russia",
                imageURL: "https://flags.worldarena.games/photos/russia_trans_siberian.jpg",
                localImage: "🚂"
            ),
            CountryPhoto(
                id: "russia_siberian_taiga",
                type: .nature,
                title: "Siberian Taiga",
                description: "Vast boreal forest covering much of Russia",
                imageURL: "https://flags.worldarena.games/photos/russia_siberian_taiga.jpg",
                localImage: "🌲"
            )
        ]
    }
    
    // MARK: - Brazil Photos
    private var brazilPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "brazil_flag",
                type: .flag,
                title: "Auriverde",
                description: "Green field with yellow rhombus and blue celestial globe",
                imageURL: "https://flags.worldarena.games/photos/brazil_flag.jpg",
                localImage: "🇧🇷"
            ),
            CountryPhoto(
                id: "brazil_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Brazil",
                description: "Southern Cross with coffee and tobacco branches",
                imageURL: "https://flags.worldarena.games/photos/brazil_coat_of_arms.jpg",
                localImage: "⭐"
            ),
            CountryPhoto(
                id: "brazil_christ_redeemer",
                type: .landmark,
                title: "Christ the Redeemer",
                description: "Iconic statue overlooking Rio de Janeiro",
                imageURL: "https://flags.worldarena.games/photos/brazil_christ_redeemer.jpg",
                localImage: "✝️"
            ),
            CountryPhoto(
                id: "brazil_amazon",
                type: .nature,
                title: "Amazon Rainforest",
                description: "World's largest tropical rainforest",
                imageURL: "https://flags.worldarena.games/photos/brazil_amazon.jpg",
                localImage: "🌳"
            ),
            CountryPhoto(
                id: "brazil_carnival",
                type: .culture,
                title: "Carnival",
                description: "Famous festival with colorful parades and samba",
                imageURL: "https://flags.worldarena.games/photos/brazil_carnival.jpg",
                localImage: "🎭"
            ),
            CountryPhoto(
                id: "brazil_iguazu_falls",
                type: .nature,
                title: "Iguazu Falls",
                description: "Spectacular waterfalls on Argentina-Brazil border",
                imageURL: "https://flags.worldarena.games/photos/brazil_iguazu_falls.jpg",
                localImage: "💧"
            )
        ]
    }
    
    // MARK: - Canada Photos
    private var canadaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "canada_flag",
                type: .flag,
                title: "Maple Leaf Flag",
                description: "Red maple leaf on white square with red borders",
                imageURL: "https://flags.worldarena.games/photos/canada_flag.jpg",
                localImage: "🇨🇦"
            ),
            CountryPhoto(
                id: "canada_coat_of_arms",
                type: .coatOfArms,
                title: "Arms of Canada",
                description: "Shield with lion, fleur-de-lis, and maple leaves",
                imageURL: "https://flags.worldarena.games/photos/canada_coat_of_arms.jpg",
                localImage: "🍁"
            ),
            CountryPhoto(
                id: "canada_cn_tower",
                type: .landmark,
                title: "CN Tower",
                description: "Iconic communications tower in Toronto",
                imageURL: "https://flags.worldarena.games/photos/canada_cn_tower.jpg",
                localImage: "🗼"
            ),
            CountryPhoto(
                id: "canada_niagara_falls",
                type: .nature,
                title: "Niagara Falls",
                description: "Famous waterfalls on US-Canada border",
                imageURL: "https://flags.worldarena.games/photos/canada_niagara_falls.jpg",
                localImage: "💧"
            ),
            CountryPhoto(
                id: "canada_rocky_mountains",
                type: .nature,
                title: "Rocky Mountains",
                description: "Majestic mountain range in western Canada",
                imageURL: "https://flags.worldarena.games/photos/canada_rocky_mountains.jpg",
                localImage: "🏔️"
            ),
            CountryPhoto(
                id: "canada_parliament",
                type: .government,
                title: "Parliament Hill",
                description: "Gothic Revival buildings housing Canadian Parliament",
                imageURL: "https://flags.worldarena.games/photos/canada_parliament.jpg",
                localImage: "🏛️"
            )
        ]
    }
    
    // MARK: - Australia Photos
    private var australiaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "australia_flag",
                type: .flag,
                title: "Australian Flag",
                description: "Union Jack with Southern Cross and Commonwealth Star",
                imageURL: "https://flags.worldarena.games/photos/australia_flag.jpg",
                localImage: "🇦🇺"
            ),
            CountryPhoto(
                id: "australia_coat_of_arms",
                type: .coatOfArms,
                title: "Australian Coat of Arms",
                description: "Kangaroo and emu supporting a shield",
                imageURL: "https://flags.worldarena.games/photos/australia_coat_of_arms.jpg",
                localImage: "🦘"
            ),
            CountryPhoto(
                id: "australia_sydney_opera",
                type: .landmark,
                title: "Sydney Opera House",
                description: "Iconic performing arts venue with shell design",
                imageURL: "https://flags.worldarena.games/photos/australia_sydney_opera.jpg",
                localImage: "🎭"
            ),
            CountryPhoto(
                id: "australia_uluru",
                type: .nature,
                title: "Uluru",
                description: "Sacred monolith in the heart of Australia",
                imageURL: "https://flags.worldarena.games/photos/australia_uluru.jpg",
                localImage: "🪨"
            ),
            CountryPhoto(
                id: "australia_great_barrier_reef",
                type: .nature,
                title: "Great Barrier Reef",
                description: "World's largest coral reef system",
                imageURL: "https://flags.worldarena.games/photos/australia_great_barrier_reef.jpg",
                localImage: "🐠"
            ),
            CountryPhoto(
                id: "australia_outback",
                type: .nature,
                title: "Australian Outback",
                description: "Vast remote interior desert regions",
                imageURL: "https://flags.worldarena.games/photos/australia_outback.jpg",
                localImage: "🦘"
            )
        ]
    }
    
    // MARK: - India Photos
    private var indiaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "india_flag",
                type: .flag,
                title: "Tiranga",
                description: "Saffron, white, and green with blue wheel (Ashoka Chakra)",
                imageURL: "https://flags.worldarena.games/photos/india_flag.jpg",
                localImage: "🇮🇳"
            ),
            CountryPhoto(
                id: "india_coat_of_arms",
                type: .coatOfArms,
                title: "State Emblem of India",
                description: "Four lions standing back to back from Ashoka pillar",
                imageURL: "https://flags.worldarena.games/photos/india_coat_of_arms.jpg",
                localImage: "🦁"
            ),
            CountryPhoto(
                id: "india_taj_mahal",
                type: .landmark,
                title: "Taj Mahal",
                description: "Ivory-white marble mausoleum in Agra",
                imageURL: "https://flags.worldarena.games/photos/india_taj_mahal.jpg",
                localImage: "🕌"
            ),
            CountryPhoto(
                id: "india_ganges",
                type: .nature,
                title: "Ganges River",
                description: "Sacred river flowing through northern India",
                imageURL: "https://flags.worldarena.games/photos/india_ganges.jpg",
                localImage: "🌊"
            ),
            CountryPhoto(
                id: "india_holi",
                type: .culture,
                title: "Holi Festival",
                description: "Festival of colors celebrating spring",
                imageURL: "https://flags.worldarena.games/photos/india_holi.jpg",
                localImage: "🎨"
            ),
            CountryPhoto(
                id: "india_himalayas",
                type: .nature,
                title: "Himalayas",
                description: "World's highest mountain range including Everest",
                imageURL: "https://flags.worldarena.games/photos/india_himalayas.jpg",
                localImage: "🏔️"
            )
        ]
    }
    
    // MARK: - Mexico Photos
    private var mexicoPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "mexico_flag",
                type: .flag,
                title: "Mexican Flag",
                description: "Green, white, red with eagle devouring serpent",
                imageURL: "https://flags.worldarena.games/photos/mexico_flag.jpg",
                localImage: "🇲🇽"
            ),
            CountryPhoto(
                id: "mexico_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Mexico",
                description: "Golden eagle on prickly pear cactus",
                imageURL: "https://flags.worldarena.games/photos/mexico_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "mexico_chichen_itza",
                type: .landmark,
                title: "Chichen Itza",
                description: "Ancient Mayan pyramid in Yucatan",
                imageURL: "https://flags.worldarena.games/photos/mexico_chichen_itza.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "mexico_day_of_dead",
                type: .culture,
                title: "Day of the Dead",
                description: "Traditional celebration honoring deceased loved ones",
                imageURL: "https://flags.worldarena.games/photos/mexico_day_of_dead.jpg",
                localImage: "💀"
            ),
            CountryPhoto(
                id: "mexico_cenotes",
                type: .nature,
                title: "Cenotes",
                description: "Natural sinkholes filled with fresh water",
                imageURL: "https://flags.worldarena.games/photos/mexico_cenotes.jpg",
                localImage: "💧"
            ),
            CountryPhoto(
                id: "mexico_mariachi",
                type: .culture,
                title: "Mariachi Music",
                description: "Traditional Mexican folk music and dance",
                imageURL: "https://flags.worldarena.games/photos/mexico_mariachi.jpg",
                localImage: "🎺"
            )
        ]
    }
    
    // MARK: - Egypt Photos
    private var egyptPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "egypt_flag",
                type: .flag,
                title: "Egyptian Flag",
                description: "Red, white, black horizontal stripes with golden eagle",
                imageURL: "https://flags.worldarena.games/photos/egypt_flag.jpg",
                localImage: "🇪🇬"
            ),
            CountryPhoto(
                id: "egypt_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Egypt",
                description: "Eagle of Saladin with Egyptian flag shield",
                imageURL: "https://flags.worldarena.games/photos/egypt_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "egypt_pyramids",
                type: .landmark,
                title: "Pyramids of Giza",
                description: "Ancient pyramid complex including Great Pyramid",
                imageURL: "https://flags.worldarena.games/photos/egypt_pyramids.jpg",
                localImage: "🔺"
            ),
            CountryPhoto(
                id: "egypt_sphinx",
                type: .landmark,
                title: "Great Sphinx",
                description: "Limestone statue with human head and lion body",
                imageURL: "https://flags.worldarena.games/photos/egypt_sphinx.jpg",
                localImage: "🦁"
            ),
            CountryPhoto(
                id: "egypt_nile",
                type: .nature,
                title: "Nile River",
                description: "World's longest river flowing through Egypt",
                imageURL: "https://flags.worldarena.games/photos/egypt_nile.jpg",
                localImage: "🌊"
            ),
            CountryPhoto(
                id: "egypt_temple",
                type: .culture,
                title: "Temple of Karnak",
                description: "Ancient temple complex in Luxor",
                imageURL: "https://flags.worldarena.games/photos/egypt_temple.jpg",
                localImage: "🏛️"
            )
        ]
    }
    
    // MARK: - Greece Photos
    private var greecePhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "greece_flag",
                type: .flag,
                title: "Greek Flag",
                description: "Blue and white stripes with cross in canton",
                imageURL: "https://flags.worldarena.games/photos/greece_flag.jpg",
                localImage: "🇬🇷"
            ),
            CountryPhoto(
                id: "greece_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Greece",
                description: "Blue shield with white cross surrounded by laurel",
                imageURL: "https://flags.worldarena.games/photos/greece_coat_of_arms.jpg",
                localImage: "✝️"
            ),
            CountryPhoto(
                id: "greece_parthenon",
                type: .landmark,
                title: "Parthenon",
                description: "Ancient temple on Athenian Acropolis",
                imageURL: "https://flags.worldarena.games/photos/greece_parthenon.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "greece_santorini",
                type: .landmark,
                title: "Santorini",
                description: "Volcanic island with white-blue architecture",
                imageURL: "https://flags.worldarena.games/photos/greece_santorini.jpg",
                localImage: "🏝️"
            ),
            CountryPhoto(
                id: "greece_olympics",
                type: .culture,
                title: "Ancient Olympics",
                description: "Birthplace of Olympic Games in Olympia",
                imageURL: "https://flags.worldarena.games/photos/greece_olympics.jpg",
                localImage: "🏃"
            ),
            CountryPhoto(
                id: "greece_aegean_sea",
                type: .nature,
                title: "Aegean Sea",
                description: "Beautiful sea dotted with Greek islands",
                imageURL: "https://flags.worldarena.games/photos/greece_aegean_sea.jpg",
                localImage: "🌊"
            )
        ]
    }
    
    // MARK: - Turkey Photos
    private var turkeyPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "turkey_flag",
                type: .flag,
                title: "Turkish Flag",
                description: "Red field with white crescent moon and star",
                imageURL: "https://flags.worldarena.games/photos/turkey_flag.jpg",
                localImage: "🇹🇷"
            ),
            CountryPhoto(
                id: "turkey_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Turkey",
                description: "Red crescent and star on white background",
                imageURL: "https://flags.worldarena.games/photos/turkey_coat_of_arms.jpg",
                localImage: "☪️"
            ),
            CountryPhoto(
                id: "turkey_hagia_sophia",
                type: .landmark,
                title: "Hagia Sophia",
                description: "Historic mosque and former cathedral in Istanbul",
                imageURL: "https://flags.worldarena.games/photos/turkey_hagia_sophia.jpg",
                localImage: "🕌"
            ),
            CountryPhoto(
                id: "turkey_cappadocia",
                type: .nature,
                title: "Cappadocia",
                description: "Unique rock formations and hot air balloons",
                imageURL: "https://flags.worldarena.games/photos/turkey_cappadocia.jpg",
                localImage: "🎈"
            ),
            CountryPhoto(
                id: "turkey_grand_bazaar",
                type: .culture,
                title: "Grand Bazaar",
                description: "Historic covered market in Istanbul",
                imageURL: "https://flags.worldarena.games/photos/turkey_grand_bazaar.jpg",
                localImage: "🏪"
            ),
            CountryPhoto(
                id: "turkey_bosphorus",
                type: .nature,
                title: "Bosphorus Strait",
                description: "Waterway connecting Europe and Asia",
                imageURL: "https://flags.worldarena.games/photos/turkey_bosphorus.jpg",
                localImage: "🌊"
            )
        ]
    }
    
    // MARK: - Thailand Photos
    private var thailandPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "thailand_flag",
                type: .flag,
                title: "Thai Flag",
                description: "Red, white, blue, white, red horizontal stripes",
                imageURL: "https://flags.worldarena.games/photos/thailand_flag.jpg",
                localImage: "🇹🇭"
            ),
            CountryPhoto(
                id: "thailand_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Thailand",
                description: "Garuda (mythical bird) holding royal symbols",
                imageURL: "https://flags.worldarena.games/photos/thailand_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "thailand_grand_palace",
                type: .government,
                title: "Grand Palace",
                description: "Complex of royal buildings in Bangkok",
                imageURL: "https://flags.worldarena.games/photos/thailand_grand_palace.jpg",
                localImage: "🏰"
            ),
            CountryPhoto(
                id: "thailand_wat_pho",
                type: .culture,
                title: "Wat Pho Temple",
                description: "Temple complex with giant reclining Buddha",
                imageURL: "https://flags.worldarena.games/photos/thailand_wat_pho.jpg",
                localImage: "🛕"
            ),
            CountryPhoto(
                id: "thailand_phi_phi_islands",
                type: .nature,
                title: "Phi Phi Islands",
                description: "Tropical paradise in Andaman Sea",
                imageURL: "https://flags.worldarena.games/photos/thailand_phi_phi_islands.jpg",
                localImage: "🏝️"
            ),
            CountryPhoto(
                id: "thailand_floating_market",
                type: .culture,
                title: "Floating Markets",
                description: "Traditional markets on canals and rivers",
                imageURL: "https://flags.worldarena.games/photos/thailand_floating_market.jpg",
                localImage: "🚤"
            )
        ]
    }
    
    // MARK: - Argentina Photos
    private var argentinaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "argentina_flag",
                type: .flag,
                title: "Argentine Flag",
                description: "Light blue and white stripes with Sun of May",
                imageURL: "https://flags.worldarena.games/photos/argentina_flag.jpg",
                localImage: "🇦🇷"
            ),
            CountryPhoto(
                id: "argentina_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of Argentina",
                description: "Oval shield with handshake and Phrygian cap",
                imageURL: "https://flags.worldarena.games/photos/argentina_coat_of_arms.jpg",
                localImage: "☀️"
            ),
            CountryPhoto(
                id: "argentina_tango",
                type: .culture,
                title: "Tango Dancing",
                description: "Passionate dance originating in Buenos Aires",
                imageURL: "https://flags.worldarena.games/photos/argentina_tango.jpg",
                localImage: "💃"
            ),
            CountryPhoto(
                id: "argentina_patagonia",
                type: .nature,
                title: "Patagonia",
                description: "Vast region of glaciers, mountains, and steppes",
                imageURL: "https://flags.worldarena.games/photos/argentina_patagonia.jpg",
                localImage: "🏔️"
            ),
            CountryPhoto(
                id: "argentina_casa_rosada",
                type: .government,
                title: "Casa Rosada",
                description: "Pink presidential palace in Buenos Aires",
                imageURL: "https://flags.worldarena.games/photos/argentina_casa_rosada.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "argentina_gaucho",
                type: .culture,
                title: "Gaucho Culture",
                description: "Traditional horsemen of Argentine pampas",
                imageURL: "https://flags.worldarena.games/photos/argentina_gaucho.jpg",
                localImage: "🤠"
            )
        ]
    }
    
    // MARK: - South Africa Photos
    private var southAfricaPhotos: [CountryPhoto] {
        [
            CountryPhoto(
                id: "south_africa_flag",
                type: .flag,
                title: "South African Flag",
                description: "Colorful flag with Y-shaped design",
                imageURL: "https://flags.worldarena.games/photos/south_africa_flag.jpg",
                localImage: "🇿🇦"
            ),
            CountryPhoto(
                id: "south_africa_coat_of_arms",
                type: .coatOfArms,
                title: "Coat of Arms of South Africa",
                description: "Secretary bird with protea flowers and ears of wheat",
                imageURL: "https://flags.worldarena.games/photos/south_africa_coat_of_arms.jpg",
                localImage: "🦅"
            ),
            CountryPhoto(
                id: "south_africa_table_mountain",
                type: .nature,
                title: "Table Mountain",
                description: "Flat-topped mountain overlooking Cape Town",
                imageURL: "https://flags.worldarena.games/photos/south_africa_table_mountain.jpg",
                localImage: "⛰️"
            ),
            CountryPhoto(
                id: "south_africa_safari",
                type: .nature,
                title: "Safari Wildlife",
                description: "Big Five animals in Kruger National Park",
                imageURL: "https://flags.worldarena.games/photos/south_africa_safari.jpg",
                localImage: "🦁"
            ),
            CountryPhoto(
                id: "south_africa_robben_island",
                type: .culture,
                title: "Robben Island",
                description: "Historic prison island where Mandela was held",
                imageURL: "https://flags.worldarena.games/photos/south_africa_robben_island.jpg",
                localImage: "🏝️"
            ),
            CountryPhoto(
                id: "south_africa_union_buildings",
                type: .government,
                title: "Union Buildings",
                description: "Government buildings in Pretoria",
                imageURL: "https://flags.worldarena.games/photos/south_africa_union_buildings.jpg",
                localImage: "🏛️"
            )
        ]
    }
    
    // MARK: - Default Photos
    private func defaultPhotos(for countryCode: String) -> [CountryPhoto] {
        [
            CountryPhoto(
                id: "\(countryCode.lowercased())_flag",
                type: .flag,
                title: "National Flag",
                description: "Flag of the country",
                imageURL: "https://flags.worldarena.games/photos/\(countryCode.lowercased())_flag.jpg",
                localImage: getFlagEmoji(for: countryCode)
            ),
            CountryPhoto(
                id: "\(countryCode.lowercased())_landmark",
                type: .landmark,
                title: "Famous Landmark",
                description: "Iconic landmark of the country",
                imageURL: "https://flags.worldarena.games/photos/\(countryCode.lowercased())_landmark.jpg",
                localImage: "🏛️"
            ),
            CountryPhoto(
                id: "\(countryCode.lowercased())_nature",
                type: .nature,
                title: "Natural Beauty",
                description: "Beautiful natural scenery",
                imageURL: "https://flags.worldarena.games/photos/\(countryCode.lowercased())_nature.jpg",
                localImage: "🌄"
            )
        ]
    }
    
    private func getFlagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return String(s)
    }
}

// MARK: - Country Photo Model
struct CountryPhoto: Identifiable, Equatable {
    let id: String
    let type: PhotoType
    let title: String
    let description: String
    let imageURL: String
    let localImage: String
    
    static func == (lhs: CountryPhoto, rhs: CountryPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Photo Types
enum PhotoType: String, CaseIterable {
    case flag = "flag"
    case landmark = "landmark"
    case nature = "nature"
    case culture = "culture"
    case government = "government"
    case coatOfArms = "coat_of_arms"
    
    var displayName: String {
        switch self {
        case .flag: return "Flag"
        case .landmark: return "Landmarks"
        case .nature: return "Nature"
        case .culture: return "Culture"
        case .government: return "Government"
        case .coatOfArms: return "Coat of Arms"
        }
    }
    
    var icon: String {
        switch self {
        case .flag: return "flag.fill"
        case .landmark: return "building.columns.fill"
        case .nature: return "mountain.2.fill"
        case .culture: return "theatermasks.fill"
        case .government: return "building.fill"
        case .coatOfArms: return "shield.fill"
        }
    }
}