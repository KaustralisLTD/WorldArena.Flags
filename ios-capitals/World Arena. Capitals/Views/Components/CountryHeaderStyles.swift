import SwiftUI

// MARK: - Country Header Styles
struct CountryHeaderStyles {
    
    // MARK: - Header Style Generator
    static func getHeaderStyle(for countryCode: String) -> CountryHeaderStyle {
        switch countryCode.uppercased() {
        case "US": return usaHeaderStyle
        case "GB": return ukHeaderStyle  
        case "FR": return franceHeaderStyle
        case "DE": return germanyHeaderStyle
        case "IT": return italyHeaderStyle
        case "ES": return spainHeaderStyle
        case "RU": return russiaHeaderStyle
        case "CN": return chinaHeaderStyle
        case "JP": return japanHeaderStyle
        case "CA": return canadaHeaderStyle
        case "AU": return australiaHeaderStyle
        case "BR": return brazilHeaderStyle
        case "IN": return indiaHeaderStyle
        case "MX": return mexicoHeaderStyle
        case "AR": return argentinaHeaderStyle
        case "EG": return egyptHeaderStyle
        case "ZA": return southAfricaHeaderStyle
        case "NG": return nigeriaHeaderStyle
        case "KE": return kenyaHeaderStyle
        case "MA": return moroccoHeaderStyle
        default: return defaultHeaderStyle(for: countryCode)
        }
    }
    
    // MARK: - Specific Country Styles
    
    // США - звезды и полосы
    private static var usaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .blue,
            secondaryColor: .red,
            accentColor: .white,
            gradientColors: [
                Color.blue.opacity(0.8),
                Color.red.opacity(0.6),
                Color.blue.opacity(0.8)
            ],
            decorativeElements: [
                .stars(count: 13, color: .white, size: 8),
                .stripes(count: 7, horizontal: true)
            ],
            flagPosition: .topTrailing,
            textShadow: true
        )
    }
    
    // Великобритания - Union Jack стиль
    private static var ukHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.01, green: 0.18, blue: 0.65), // Синий
            secondaryColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            accentColor: .white,
            gradientColors: [
                Color(red: 0.01, green: 0.18, blue: 0.65).opacity(0.9),
                Color.white.opacity(0.3),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.7)
            ],
            decorativeElements: [
                .crosses(style: .diagonal),
                .crosses(style: .straight)
            ],
            flagPosition: .topLeading,
            textShadow: true
        )
    }
    
    // Франция - триколор
    private static var franceHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.27, blue: 0.68), // Синий
            secondaryColor: Color(red: 0.93, green: 0.11, blue: 0.14), // Красный
            accentColor: .white,
            gradientColors: [
                Color(red: 0.0, green: 0.27, blue: 0.68).opacity(0.8),
                Color.white.opacity(0.6),
                Color(red: 0.93, green: 0.11, blue: 0.14).opacity(0.8)
            ],
            decorativeElements: [
                .verticalStripes(count: 3),
                .elegantBorder
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Германия - черно-красно-золотой
    private static var germanyHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .black,
            secondaryColor: Color(red: 0.87, green: 0.0, blue: 0.0), // Красный
            accentColor: Color(red: 1.0, green: 0.81, blue: 0.0), // Золотой
            gradientColors: [
                Color.black.opacity(0.8),
                Color(red: 0.87, green: 0.0, blue: 0.0).opacity(0.7),
                Color(red: 1.0, green: 0.81, blue: 0.0).opacity(0.6)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .geometricPattern
            ],
            flagPosition: .topCenter,
            textShadow: true
        )
    }
    
    // Италия - зелено-бело-красный
    private static var italyHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.55, blue: 0.3), // Зеленый
            secondaryColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            accentColor: .white,
            gradientColors: [
                Color(red: 0.0, green: 0.55, blue: 0.3).opacity(0.8),
                Color.white.opacity(0.7),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.8)
            ],
            decorativeElements: [
                .verticalStripes(count: 3),
                .romanPattern
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Испания - красно-желто-красный
    private static var spainHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.76, green: 0.0, blue: 0.13), // Красный
            secondaryColor: Color(red: 1.0, green: 0.76, blue: 0.0), // Желтый
            accentColor: .white,
            gradientColors: [
                Color(red: 0.76, green: 0.0, blue: 0.13).opacity(0.8),
                Color(red: 1.0, green: 0.76, blue: 0.0).opacity(0.9),
                Color(red: 0.76, green: 0.0, blue: 0.13).opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .heraldic
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Россия - бело-сине-красный
    private static var russiaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .white,
            secondaryColor: Color(red: 0.0, green: 0.33, blue: 0.65), // Синий
            accentColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            gradientColors: [
                Color.white.opacity(0.9),
                Color(red: 0.0, green: 0.33, blue: 0.65).opacity(0.8),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .orthodoxCross
            ],
            flagPosition: .topCenter,
            textShadow: true
        )
    }
    
    // Китай - красный с звездами
    private static var chinaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.87, green: 0.0, blue: 0.0), // Красный
            secondaryColor: Color(red: 1.0, green: 0.84, blue: 0.0), // Золотой
            accentColor: .white,
            gradientColors: [
                Color(red: 0.87, green: 0.0, blue: 0.0).opacity(0.9),
                Color(red: 0.87, green: 0.0, blue: 0.0).opacity(0.7),
                Color.black.opacity(0.3)
            ],
            decorativeElements: [
                .stars(count: 5, color: Color(red: 1.0, green: 0.84, blue: 0.0), size: 12),
                .chinesePattern
            ],
            flagPosition: .topLeading,
            textShadow: true
        )
    }
    
    // Япония - красное солнце
    private static var japanHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .white,
            secondaryColor: Color(red: 0.74, green: 0.0, blue: 0.13), // Красный
            accentColor: Color(red: 0.9, green: 0.9, blue: 0.9),
            gradientColors: [
                Color.white.opacity(0.95),
                Color(red: 0.74, green: 0.0, blue: 0.13).opacity(0.3),
                Color.white.opacity(0.95)
            ],
            decorativeElements: [
                .risingSum,
                .sakura
            ],
            flagPosition: .center,
            textShadow: false
        )
    }
    
    // Канада - красно-белый с кленовым листом
    private static var canadaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.87, green: 0.0, blue: 0.0), // Красный
            secondaryColor: .white,
            accentColor: Color(red: 0.9, green: 0.9, blue: 0.9),
            gradientColors: [
                Color(red: 0.87, green: 0.0, blue: 0.0).opacity(0.8),
                Color.white.opacity(0.9),
                Color(red: 0.87, green: 0.0, blue: 0.0).opacity(0.8)
            ],
            decorativeElements: [
                .verticalStripes(count: 3),
                .mapleLeaf
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Австралия - синий с Union Jack
    private static var australiaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.15, blue: 0.49), // Синий
            secondaryColor: .white,
            accentColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            gradientColors: [
                Color(red: 0.0, green: 0.15, blue: 0.49).opacity(0.9),
                Color(red: 0.0, green: 0.15, blue: 0.49).opacity(0.6),
                Color.black.opacity(0.4)
            ],
            decorativeElements: [
                .stars(count: 6, color: .white, size: 10),
                .southernCross
            ],
            flagPosition: .topLeading,
            textShadow: true
        )
    }
    
    // Бразилия - зелено-желтый
    private static var brazilHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.64, blue: 0.22), // Зеленый
            secondaryColor: Color(red: 1.0, green: 0.82, blue: 0.0), // Желтый
            accentColor: Color(red: 0.0, green: 0.27, blue: 0.68), // Синий
            gradientColors: [
                Color(red: 0.0, green: 0.64, blue: 0.22).opacity(0.8),
                Color(red: 1.0, green: 0.82, blue: 0.0).opacity(0.7),
                Color(red: 0.0, green: 0.27, blue: 0.68).opacity(0.6)
            ],
            decorativeElements: [
                .diamond,
                .stars(count: 27, color: .white, size: 6)
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Индия - шафрановый, белый, зеленый
    private static var indiaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 1.0, green: 0.6, blue: 0.2), // Шафрановый
            secondaryColor: Color(red: 0.0, green: 0.53, blue: 0.22), // Зеленый
            accentColor: .white,
            gradientColors: [
                Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8),
                Color.white.opacity(0.9),
                Color(red: 0.0, green: 0.53, blue: 0.22).opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .chakra
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Мексика - зелено-бело-красный
    private static var mexicoHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.4, blue: 0.25), // Зеленый
            secondaryColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            accentColor: .white,
            gradientColors: [
                Color(red: 0.0, green: 0.4, blue: 0.25).opacity(0.8),
                Color.white.opacity(0.9),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.8)
            ],
            decorativeElements: [
                .verticalStripes(count: 3),
                .aztecPattern
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Аргентина - небесно-голубой и белый
    private static var argentinaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.46, green: 0.76, blue: 0.98), // Небесно-голубой
            secondaryColor: .white,
            accentColor: Color(red: 1.0, green: 0.84, blue: 0.0), // Золотой
            gradientColors: [
                Color(red: 0.46, green: 0.76, blue: 0.98).opacity(0.8),
                Color.white.opacity(0.9),
                Color(red: 0.46, green: 0.76, blue: 0.98).opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .sun
            ],
            flagPosition: .center,
            textShadow: false
        )
    }
    
    // Египет - красно-бело-черный
    private static var egyptHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            secondaryColor: .black,
            accentColor: .white,
            gradientColors: [
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.8),
                Color.white.opacity(0.9),
                Color.black.opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 3),
                .eagle
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // ЮАР - многоцветный
    private static var southAfricaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.27, blue: 0.68), // Синий
            secondaryColor: Color(red: 0.0, green: 0.64, blue: 0.22), // Зеленый
            accentColor: Color(red: 1.0, green: 0.82, blue: 0.0), // Желтый
            gradientColors: [
                Color(red: 0.0, green: 0.27, blue: 0.68).opacity(0.7),
                Color(red: 0.0, green: 0.64, blue: 0.22).opacity(0.8),
                Color(red: 1.0, green: 0.82, blue: 0.0).opacity(0.6),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.7)
            ],
            decorativeElements: [
                .rainbow,
                .protea
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Нигерия - зелено-белый
    private static var nigeriaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.0, green: 0.5, blue: 0.25), // Зеленый
            secondaryColor: .white,
            accentColor: Color(red: 0.9, green: 0.9, blue: 0.9),
            gradientColors: [
                Color(red: 0.0, green: 0.5, blue: 0.25).opacity(0.8),
                Color.white.opacity(0.9),
                Color(red: 0.0, green: 0.5, blue: 0.25).opacity(0.8)
            ],
            decorativeElements: [
                .verticalStripes(count: 3),
                .africanPattern
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Кения - черно-красно-зеленый
    private static var kenyaHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .black,
            secondaryColor: Color(red: 0.81, green: 0.12, blue: 0.23), // Красный
            accentColor: Color(red: 0.0, green: 0.5, blue: 0.25), // Зеленый
            gradientColors: [
                Color.black.opacity(0.8),
                Color(red: 0.81, green: 0.12, blue: 0.23).opacity(0.8),
                Color.white.opacity(0.3),
                Color(red: 0.0, green: 0.5, blue: 0.25).opacity(0.8)
            ],
            decorativeElements: [
                .horizontalStripes(count: 4),
                .masaiShield
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // Марокко - красный
    private static var moroccoHeaderStyle: CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: Color(red: 0.76, green: 0.0, blue: 0.13), // Красный
            secondaryColor: Color(red: 0.0, green: 0.5, blue: 0.25), // Зеленый
            accentColor: .white,
            gradientColors: [
                Color(red: 0.76, green: 0.0, blue: 0.13).opacity(0.9),
                Color(red: 0.76, green: 0.0, blue: 0.13).opacity(0.7),
                Color.black.opacity(0.3)
            ],
            decorativeElements: [
                .star(color: Color(red: 0.0, green: 0.5, blue: 0.25)),
                .islamicPattern
            ],
            flagPosition: .center,
            textShadow: true
        )
    }
    
    // MARK: - Default Style
    private static func defaultHeaderStyle(for countryCode: String) -> CountryHeaderStyle {
        CountryHeaderStyle(
            primaryColor: .blue,
            secondaryColor: .white,
            accentColor: .gray,
            gradientColors: [
                Color.blue.opacity(0.7),
                Color.white.opacity(0.8),
                Color.blue.opacity(0.7)
            ],
            decorativeElements: [.geometricPattern],
            flagPosition: .center,
            textShadow: true
        )
    }
}

// MARK: - Country Header Style Model
struct CountryHeaderStyle {
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let gradientColors: [Color]
    let decorativeElements: [DecorativeElement]
    let flagPosition: FlagPosition
    let textShadow: Bool
}

// MARK: - Decorative Elements
enum DecorativeElement {
    case stars(count: Int, color: Color, size: CGFloat)
    case stripes(count: Int, horizontal: Bool)
    case horizontalStripes(count: Int)
    case verticalStripes(count: Int)
    case crosses(style: CrossStyle)
    case elegantBorder
    case geometricPattern
    case romanPattern
    case heraldic
    case orthodoxCross
    case chinesePattern
    case risingSum
    case sakura
    case mapleLeaf
    case southernCross
    case diamond
    case chakra
    case aztecPattern
    case sun
    case eagle
    case rainbow
    case protea
    case africanPattern
    case masaiShield
    case star(color: Color)
    case islamicPattern
}

enum CrossStyle {
    case diagonal
    case straight
}

enum FlagPosition {
    case topLeading
    case topCenter
    case topTrailing
    case center
}

