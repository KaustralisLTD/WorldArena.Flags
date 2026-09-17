import SwiftUI

struct AvatarConfiguration: Codable, Equatable {
    var skinTone: AvatarColorToken
    var backgroundColor: AvatarColorToken
    var clothingColor: AvatarColorToken
    var hairColor: AvatarColorToken
    var eyeColor: AvatarColorToken
    var glassesColor: AvatarColorToken?
    var facialHairColor: AvatarColorToken?
    var headwearColor: AvatarColorToken?

    var bodyStyle: AvatarBodyStyle
    var expression: AvatarExpression
    var hairstyle: AvatarHairStyle
    var glassesStyle: AvatarGlassesStyle
    var facialHairStyle: AvatarFacialHairStyle
    var headwearStyle: AvatarHeadwearStyle
    var clothingStyle: AvatarClothingStyle

    static let `default` = AvatarConfiguration(
        skinTone: .peach,
        backgroundColor: .skyBlue,
        clothingColor: .yellow,
        hairColor: .brown,
        eyeColor: .black,
        glassesColor: .blue,
        facialHairColor: nil,
        headwearColor: .purple,
        bodyStyle: .wide,
        expression: .e1,
        hairstyle: .modernTop,
        glassesStyle: .none,
        facialHairStyle: .none,
        headwearStyle: .none,
        clothingStyle: .sweater
    )
}

enum AvatarColorToken: String, Codable, CaseIterable {
    case black, darkBrown, brown, auburn, lightBrown, blonde, red, gray, white
    case blue, skyBlue, cyan, green, lime, yellow, orange, pink, redSoft, purple, mint, beige, peach, lightGray, darkGray

    var color: Color {
        switch self {
        case .black: return .black
        case .darkBrown: return Color(red: 0.32, green: 0.22, blue: 0.18)
        case .brown: return Color(red: 0.45, green: 0.28, blue: 0.19)
        case .auburn: return Color(red: 0.55, green: 0.22, blue: 0.15)
        case .lightBrown: return Color(red: 0.65, green: 0.48, blue: 0.38)
        case .blonde: return Color(red: 0.93, green: 0.78, blue: 0.42)
        case .red: return .red
        case .gray: return .gray
        case .white: return .white
        case .blue: return .blue
        case .skyBlue: return Color(red: 0.49, green: 0.79, blue: 0.93)
        case .cyan: return .cyan
        case .green: return .green
        case .lime: return Color(red: 0.64, green: 0.84, blue: 0.36)
        case .yellow: return Color(red: 0.92, green: 0.78, blue: 0.24)
        case .orange: return .orange
        case .pink: return .pink
        case .redSoft: return Color(red: 0.88, green: 0.40, blue: 0.40)
        case .purple: return .purple
        case .mint: return .mint
        case .beige: return Color(red: 0.92, green: 0.86, blue: 0.67)
        case .peach: return Color(red: 0.88, green: 0.62, blue: 0.39)
        case .lightGray: return Color(red: 0.88, green: 0.89, blue: 0.90)
        case .darkGray: return Color(red: 0.28, green: 0.29, blue: 0.30)
        }
    }
}

enum AvatarBodyStyle: String, Codable, CaseIterable { case slim, regular, hoodie, tshirt, sweater, wide }
/// 23 лица на холсте (`avatar_expression_1…23`). В API/JSON — число 1…23; строки `calm`/`expressive`/`dreamy` мапятся в 1…3.
enum AvatarExpression: Int, Codable, CaseIterable, Identifiable {
    case e1 = 1, e2 = 2, e3 = 3, e4 = 4, e5 = 5, e6 = 6, e7 = 7, e8 = 8, e9 = 9, e10 = 10
    case e11 = 11, e12 = 12, e13 = 13, e14 = 14, e15 = 15, e16 = 16, e17 = 17, e18 = 18, e19 = 19
    case e20 = 20, e21 = 21, e22 = 22, e23 = 23

    var id: Int { rawValue }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Int.self), let e = Self(rawValue: v) {
            self = e
            return
        }
        let s = (try? c.decode(String.self)) ?? ""
        if let v = Int(s), let e = Self(rawValue: v) {
            self = e
            return
        }
        switch s {
        case "calm": self = .e1
        case "expressive": self = .e2
        case "dreamy": self = .e3
        default: self = .e1
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

enum AvatarHairStyle: String, Codable, CaseIterable {
    case bald, sidePart, shortFlat, curl, modernTop, buzz
    case waves, spiky, slick, pompadour
}
enum AvatarGlassesStyle: String, Codable, CaseIterable { case none, round, square, sunglasses, slim }
/// Шесть PNG на холсте (`avatar_facial_hair_2…7`) + `none`. Старые `beard` / `shortBeard` из JSON мапятся при декодировании.
enum AvatarFacialHairStyle: String, Codable, CaseIterable {
    case none
    case moustache
    case trimmed
    case goatee
    case beardFull
    case beardLight
    case beardBushy

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let s = try c.decode(String.self)
        switch s {
        case "none": self = .none
        case "moustache": self = .moustache
        case "goatee": self = .goatee
        case "trimmed", "shortBeard": self = .trimmed
        case "beardFull", "beard": self = .beardFull
        case "beardLight": self = .beardLight
        case "beardBushy": self = .beardBushy
        default:
            self = Self(rawValue: s) ?? .none
        }
    }
}
/// Сырые строки совпадают со slug в именах ассетов (`avatar-hat-SilverLeague-…` → `SilverLeague`) и пригодны для магазина.
enum AvatarHeadwearStyle: String, Codable, CaseIterable {
    case none, cap, beanie, bandana, sportCap
    case SilverLeague
    case tenDayStreak = "10-day-streak"
    case beginner
    case Premium
}

/// Правила доступности головного убора (магазин / подписка). Логику покупок добавим позже.
enum AvatarHeadwearAvailability: String, Codable, Equatable {
    /// Всегда можно выбрать в редакторе.
    case always
    /// Только при активном Premium (`GameState.isPremium`).
    case premiumSubscription
    /// Заготовка под магазин: сейчас заблокировано.
    case shopLocked
}

extension AvatarHeadwearStyle {
    var availability: AvatarHeadwearAvailability {
        switch self {
        case .none, .cap, .beanie, .bandana, .sportCap:
            return .always
        case .Premium:
            return .premiumSubscription
        case .SilverLeague, .tenDayStreak, .beginner:
            return .shopLocked
        }
    }

    /// Можно применить к черновику аватара (и показать на превью без замка при уже сохранённой конфигурации).
    func isUnlockedForEditor(isPremiumActive: Bool) -> Bool {
        switch availability {
        case .always: return true
        case .premiumSubscription: return isPremiumActive
        case .shopLocked: return false
        }
    }
}

enum AvatarClothingStyle: String, Codable, CaseIterable { case tshirt, sweater, hoodie, jacket }

enum AvatarEditorCategory: String, CaseIterable, Identifiable {
    /// Порядок табов: слева тело (тон кожи, фигура), затем лицо (глаза, выражение).
    case body, face, hair, glasses, facialHair, headwear, clothing, background
    var id: String { rawValue }
}

