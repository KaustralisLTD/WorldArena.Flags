import Foundation

/// Имена imageset в Asset Catalog. Выражения: `avatar_expression_1…23`.
enum AvatarLayerAssetNames {

    static let headBase = "head_base"

    /// Полный кадр тела/торса под вариант «Тело» в редакторе (уже с цветом одежды в макете — без tint).
    static func body(for style: AvatarBodyStyle) -> String {
        switch style {
        case .slim: return "avatar_body_1"
        case .regular: return "avatar_body_2"
        case .wide: return "avatar_body_3"
        case .hoodie: return "avatar_body_4"
        case .tshirt: return "avatar_body_5"
        case .sweater: return "avatar_body_6"
        }
    }

    /// Только волосы (PNG с альфой). `bald` — без слоя.
    static func hair(_ style: AvatarHairStyle) -> String? {
        switch style {
        case .bald: return nil
        case .sidePart: return "avatar_hair_1"
        case .shortFlat: return "avatar_hair_2"
        case .curl: return "avatar_hair_3"
        case .modernTop: return "avatar_hair_4"
        case .buzz: return "avatar_hair_5"
        case .waves: return "avatar_hair_6"
        case .spiky: return "avatar_hair_7"
        case .slick: return "avatar_hair_8"
        case .pompadour: return "avatar_hair_9"
        }
    }

    static func eyes(_ token: AvatarColorToken) -> String {
        switch token {
        case .black: return "eyes_black"
        case .brown: return "eyes_brown"
        case .auburn: return "eyes_hazel"
        case .green: return "eyes_green"
        case .blue: return "eyes_blue"
        case .cyan: return "eyes_cyan"
        default: return "eyes_brown"
        }
    }

    /// Слой лица (`avatar_expression_<n>`).
    static func mouthPrimary(_ expression: AvatarExpression) -> String {
        "avatar_expression_\(expression.rawValue)"
    }

    static func mouthFallback(_ expression: AvatarExpression) -> String {
        "mouth_\(expression.rawValue)"
    }

    static func glasses(_ style: AvatarGlassesStyle) -> String? {
        switch style {
        case .none: return nil
        case .round: return "glasses_round"
        case .square: return "glasses_square"
        case .sunglasses: return "glasses_sunglasses"
        case .slim: return "glasses_slim"
        }
    }

    /// PNG на том же холсте, что `avatar_body_*` (`avatar_facial_hair_2…7`).
    static func beard(_ style: AvatarFacialHairStyle) -> String? {
        switch style {
        case .none: return nil
        case .moustache: return "avatar_facial_hair_2"
        case .trimmed: return "avatar_facial_hair_3"
        case .goatee: return "avatar_facial_hair_4"
        case .beardFull: return "avatar_facial_hair_5"
        case .beardLight: return "avatar_facial_hair_6"
        case .beardBushy: return "avatar_facial_hair_7"
        }
    }

    static func hat(_ style: AvatarHeadwearStyle) -> String? {
        switch style {
        case .none: return nil
        /// Тестовые кепки на холсте конструктора (`avatar_hat_1`, `avatar_hat_2`).
        case .cap: return "avatar_hat_1"
        case .beanie: return "hat_beanie"
        case .bandana: return "hat_bandana"
        case .sportCap: return "avatar_hat_2"
        case .SilverLeague: return "avatar_hat_SilverLeague"
        case .tenDayStreak: return "avatar_hat_10_day_streak"
        case .beginner: return "avatar_hat_beginner"
        case .Premium: return "avatar_hat_Premium"
        }
    }
}
