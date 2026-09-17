import SwiftUI

/// Сборка аватара из PNG-слоёв (см. `AvatarLayerAssetNames` + `Docs/Avatar_Layers_Assets.md`).
/// Если слоя нет в бандле — используется прежняя векторная отрисовка для этой части.
struct AvatarLayeredComposerView: View {
    let configuration: AvatarConfiguration

    private var silhouetteStyle: AvatarBodyStyle {
        switch configuration.bodyStyle {
        case .slim: return .slim
        case .regular: return .regular
        case .wide: return .wide
        case .hoodie, .tshirt, .sweater: return .regular
        }
    }

    private var torsoGarment: AvatarClothingStyle {
        switch configuration.bodyStyle {
        case .hoodie: return .hoodie
        case .tshirt: return .tshirt
        case .sweater: return .sweater
        case .slim, .regular, .wide: return configuration.clothingStyle
        }
    }

    var body: some View {
        Group {
            if usesDuolingoCanvas {
                AvatarDuolingoCanvasComposer(configuration: configuration)
            } else {
                legacyLayeredStack
            }
        }
    }

    /// Цельные `avatar_body_*` — общий холст 501×684 как в `temporary_examples` (Duolingo).
    private var usesDuolingoCanvas: Bool {
        guard let bodyAsset = resolvedBodyAsset(for: configuration.bodyStyle) else { return false }
        return bodyAsset.hasPrefix("avatar_body_")
    }

    private var legacyLayeredStack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let tight = min(w, h)
            /// Высокая «карточка» (превью на полэкрана): иначе min(w,h) даёт узкую базу и фигура мелкая.
            let isTallCard = h > w * 1.08
            let layoutBase = tight * 0.98
            let base = layoutBase * 0.90
            let sil = silhouetteStyle
            let (headScale, bodyScale): (CGFloat, CGFloat) = {
                switch sil {
                case .slim: return (0.93, 0.84)
                case .regular: return (1, 1)
                case .wide: return (1.09, 1.16)
                case .hoodie, .tshirt, .sweater: return (1, 1)
                }
            }()
            let bodyW = base * bodyScale * 0.92
            let bodyH = base * bodyScale * 0.55
            let cloth = configuration.clothingColor.color

            let bustSilhouetteMul: CGFloat = {
                switch sil {
                case .slim: return 0.90
                case .regular, .wide: return 1
                case .hoodie, .tshirt, .sweater: return 1
                }
            }()
            let bustW = layoutBase * 0.92 * bustSilhouetteMul

            let bodyAsset = resolvedBodyAsset(for: configuration.bodyStyle)
            let hasHeadBase = AvatarBundleImage.exists(AvatarLayerAssetNames.headBase)
            let compositeBodyShowsOutfit = bodyAsset?.hasPrefix("avatar_body_") == true
            /// Выше кадр для цельного тела до пояса (`avatar_body_*`); legacy — компактнее.
            let bustH = layoutBase * (compositeBodyShowsOutfit ? 1.48 : 1.30)
            let mouthResolvedName = resolvedMouthImageName(for: configuration.expression)
            let expressionIsCompositePNG = mouthResolvedName?.hasPrefix("avatar_expression_") == true

            /// Цельное тело: опускаем торс, лицо чуть выше — видна шея между головой и плечами.
            let compositeTorsoDrop = compositeBodyShowsOutfit ? layoutBase * 0.048 : 0
            let bodyLayerYOffset = layoutBase * 0.03 + compositeTorsoDrop
            let compositeExprYBustMul: CGFloat = compositeBodyShowsOutfit ? 0.032 : 0.048

            /// Для цельного тела: только зона лица на макете (не половина bust), иначе слой выражения шире торса и «наезжает» на тело
            let (headW, headH): (CGFloat, CGFloat) = compositeBodyShowsOutfit
                ? (bustW * 0.40, bustH * 0.34)
                : (base * headScale * 0.52, base * headScale * 0.60)

            let contentRoughHeight = bustH + headH * 0.42
            let tallFitScale: CGFloat = isTallCard
                ? min(1.72, (h * 0.92) / max(contentRoughHeight, 1))
                : 1.0

            ZStack(alignment: .top) {
                // 1) Тело / силуэт
                if let bodyAsset {
                    tintedLayerImage(name: bodyAsset, bustW: bustW, bustH: bustH, bodyLayerYOffset: bodyLayerYOffset)
                } else {
                    legacyCompositeBody(sil: sil, bustW: bustW, bustH: bustH, layoutBase: layoutBase)
                }

                // 2) Голова-база (отдельный слой; если есть — кожа только на нём, иначе встроено в body_*)
                if hasHeadBase {
                    Image(AvatarLayerAssetNames.headBase)
                        .resizable()
                        .scaledToFit()
                        .frame(width: bustW * 0.88, height: bustH * 0.72)
                        .colorMultiply(configuration.skinTone.color)
                        .brightness(skinBrightnessAdjust(configuration.skinTone))
                        .offset(y: layoutBase * 0.06)
                        .accessibilityHidden(true)
                }

                // 3) Одежда — только если тело не из цельного PNG конструктора (в нём уже футболка/худи)
                if !compositeBodyShowsOutfit {
                    torsoLayer(bodyW: bodyW, bodyH: bodyH, color: cloth)
                        .offset(y: headH * 0.95)

                    if torsoGarment == .hoodie {
                        Ellipse()
                            .fill(cloth.opacity(0.92))
                            .frame(width: bodyW * 0.58, height: bodyH * 0.52)
                            .offset(y: headH * 0.52)
                    }
                }

                // 4) Глаза (не рисуем поверх цельного PNG выражения — там уже лицо целиком)
                if !expressionIsCompositePNG {
                    let eyeName = AvatarLayerAssetNames.eyes(configuration.eyeColor)
                    if AvatarBundleImage.exists(eyeName) {
                        ZStack {
                            Image(eyeName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: headW * 1.05, height: headH * 0.38)
                        }
                        .offset(y: headH * 0.18)
                    } else {
                        vectorEyes(headW: headW, headH: headH)
                    }
                }

                // 5) Рот / выражение (цельный `avatar_expression_*` — в блоке 7b после волос: лысое лицо поверх причёски)
                if let mouthName = mouthResolvedName {
                    let isFullExpression = mouthName.hasPrefix("avatar_expression_")
                    let deferCompositeExpression = compositeBodyShowsOutfit && isFullExpression
                    if !deferCompositeExpression {
                        Image(mouthName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: isFullExpression ? headW * 1.05 : headW * 0.55,
                                height: isFullExpression ? headH * 0.5 : headH * 0.22
                            )
                            .offset(y: isFullExpression ? headH * 0.48 : headH * 0.57)
                    }
                } else {
                    vectorMouthOnly(headW: headW, headH: headH)
                }

                // 6) Борода: цельнохолстовые `avatar_facial_hair_*` — только в legacy без composite (ниже для composite — после выражения)
                if !compositeBodyShowsOutfit {
                    if let beard = AvatarLayerAssetNames.beard(configuration.facialHairStyle),
                       AvatarBundleImage.exists(beard) {
                        if beard.hasPrefix("avatar_facial_hair_") {
                            Image(beard)
                                .resizable()
                                .scaledToFit()
                                .frame(width: bustW, height: bustH)
                                .offset(y: layoutBase * 0.03)
                                .accessibilityHidden(true)
                        } else {
                            Image(beard)
                                .resizable()
                                .scaledToFit()
                                .frame(width: headW * 1.1, height: headH * 0.55)
                                .colorMultiply((configuration.facialHairColor ?? configuration.hairColor).color)
                                .offset(y: headH * 0.52)
                        }
                    } else if configuration.facialHairStyle != .none {
                        facialHairShape(headW: headW)
                            .fill((configuration.facialHairColor ?? configuration.hairColor).color)
                            .frame(width: headW * 1.15, height: headH * 0.55)
                            .offset(y: headH * 0.60)
                    }
                }

                // 7) Волосы — под лицом: только волосы + прозрачность на лице (`avatar_hair_*` = холст как тело)
                if let hairName = AvatarLayerAssetNames.hair(configuration.hairstyle),
                   AvatarBundleImage.exists(hairName) {
                    hairLayerImage(
                        name: hairName,
                        headW: headW,
                        headH: headH,
                        bustW: bustW,
                        bustH: bustH,
                        compositeBodyYOffset: bodyLayerYOffset,
                        matchCompositeBodyCanvas: compositeBodyShowsOutfit && hairName.hasPrefix("avatar_hair_"),
                        hairColor: configuration.hairColor.color
                    )
                    .offset(y: (compositeBodyShowsOutfit && hairName.hasPrefix("avatar_hair_")) ? 0 : -headH * 0.12)
                } else if configuration.hairstyle != .bald {
                    hairShape(headW: headW, headH: headH)
                        .fill(configuration.hairColor.color)
                        .frame(width: headW * 1.35, height: headH * 0.9)
                        .offset(y: -headH * 0.20)
                }

                // 7b) Лысое выражение поверх волос и тела — глаза/рот «пробивают» причёску (альфа вне лица)
                if let mouthName = mouthResolvedName,
                   compositeBodyShowsOutfit,
                   mouthName.hasPrefix("avatar_expression_") {
                    /// Удерживаем exprW < bustW, чтобы лицо не перекрывало шею/плечи (как в референсе)
                    let expressionScale: CGFloat = 1.12
                    let exprW = headW * 1.06 * expressionScale
                    let exprH = headH * 1.04 * expressionScale
                    let exprY = bodyLayerYOffset + bustH * compositeExprYBustMul
                    Image(mouthName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: exprW, height: exprH)
                        .offset(y: exprY)
                }

                // 7c) Усы/борода на цельном теле — тот же кадр, что `avatar_body_*`, поверх лица
                if compositeBodyShowsOutfit,
                   let beardName = AvatarLayerAssetNames.beard(configuration.facialHairStyle),
                   AvatarBundleImage.exists(beardName),
                   beardName.hasPrefix("avatar_facial_hair_") {
                    Image(beardName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: bustW, height: bustH)
                        .offset(y: bodyLayerYOffset)
                        .accessibilityHidden(true)
                }

                // 8) Очки
                if let g = AvatarLayerAssetNames.glasses(configuration.glassesStyle),
                   AvatarBundleImage.exists(g) {
                    Image(g)
                        .resizable()
                        .scaledToFit()
                        .frame(width: headW * 1.15, height: headH * 0.32)
                        .colorMultiply((configuration.glassesColor ?? .blue).color)
                        .offset(y: headH * 0.22)
                } else if configuration.glassesStyle != .none {
                    glassesShape(headW: headW)
                        .stroke((configuration.glassesColor ?? .blue).color, lineWidth: 2.4)
                        .frame(width: headW * 1.2, height: headH * 0.36)
                        .offset(y: headH * 0.25)
                }

                // 9) Головной убор
                if let h = AvatarLayerAssetNames.hat(configuration.headwearStyle),
                   AvatarBundleImage.exists(h) {
                    if h.hasPrefix("avatar_hat_") {
                        Image(h)
                            .resizable()
                            .scaledToFit()
                            .frame(width: bustW, height: bustH)
                            .offset(y: compositeBodyShowsOutfit ? bodyLayerYOffset : layoutBase * 0.03)
                            .accessibilityHidden(true)
                    } else {
                        Image(h)
                            .resizable()
                            .scaledToFit()
                            .frame(width: headW * 1.2, height: headH * 0.55)
                            .colorMultiply((configuration.headwearColor ?? .purple).color)
                            .offset(y: -headH * 0.28)
                    }
                } else if configuration.headwearStyle != .none {
                    headwearShape(headW: headW)
                        .fill((configuration.headwearColor ?? .purple).color)
                        .frame(width: headW * 1.25, height: headH * 0.62)
                        .offset(y: -headH * 0.33)
                }
            }
            .scaleEffect(tallFitScale, anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Разрешение имён + legacy

    private func resolvedBodyAsset(for style: AvatarBodyStyle) -> String? {
        let preferred = AvatarLayerAssetNames.body(for: style)
        if AvatarBundleImage.exists(preferred) { return preferred }
        let sil = silhouetteFromBody(style)
        let legacy = legacyBodyAssetName(for: sil)
        return AvatarBundleImage.exists(legacy) ? legacy : nil
    }

    private func silhouetteFromBody(_ style: AvatarBodyStyle) -> AvatarBodyStyle {
        switch style {
        case .slim: return .slim
        case .regular: return .regular
        case .wide: return .wide
        case .hoodie, .tshirt, .sweater: return .regular
        }
    }

    private func resolvedMouthImageName(for expression: AvatarExpression) -> String? {
        let primary = AvatarLayerAssetNames.mouthPrimary(expression)
        if AvatarBundleImage.exists(primary) { return primary }
        let fb = AvatarLayerAssetNames.mouthFallback(expression)
        return AvatarBundleImage.exists(fb) ? fb : nil
    }

    private func legacyBodyAssetName(for silhouette: AvatarBodyStyle) -> String {
        switch silhouette {
        case .slim: return "AvatarEditorBodySlim"
        case .wide: return "AvatarEditorBodyWide"
        case .regular, .hoodie, .tshirt, .sweater: return "AvatarEditorBodyRegular"
        }
    }

    @ViewBuilder
    private func tintedLayerImage(name: String, bustW: CGFloat, bustH: CGFloat, bodyLayerYOffset: CGFloat) -> some View {
        let tintSkin = !name.hasPrefix("avatar_body_")
        if tintSkin {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: bustW, height: bustH)
                .colorMultiply(configuration.skinTone.color)
                .brightness(skinBrightnessAdjust(configuration.skinTone))
                .offset(y: bodyLayerYOffset)
                .accessibilityHidden(true)
        } else {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: bustW, height: bustH)
                .offset(y: bodyLayerYOffset)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func hairLayerImage(
        name: String,
        headW: CGFloat,
        headH: CGFloat,
        bustW: CGFloat,
        bustH: CGFloat,
        compositeBodyYOffset: CGFloat,
        matchCompositeBodyCanvas: Bool,
        hairColor: Color
    ) -> some View {
        let tint = !name.hasPrefix("avatar_hair_")
        if matchCompositeBodyCanvas {
            if tint {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: bustW, height: bustH)
                    .offset(y: compositeBodyYOffset)
                    .colorMultiply(hairColor)
            } else {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: bustW, height: bustH)
                    .offset(y: compositeBodyYOffset)
            }
        } else if tint {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: headW * 1.25, height: headH * 0.75)
                .colorMultiply(hairColor)
        } else {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: headW * 1.25, height: headH * 0.75)
        }
    }

    @ViewBuilder
    private func legacyCompositeBody(sil: AvatarBodyStyle, bustW: CGFloat, bustH: CGFloat, layoutBase: CGFloat) -> some View {
        let legacy = legacyBodyAssetName(for: sil)
        tintedLayerImage(name: legacy, bustW: bustW, bustH: bustH, bodyLayerYOffset: layoutBase * 0.03)
    }

    private func skinBrightnessAdjust(_ token: AvatarColorToken) -> Double {
        switch token {
        case .black: return -0.24
        case .darkBrown: return -0.14
        case .brown: return -0.06
        case .lightBrown, .beige: return 0.04
        default: return 0
        }
    }

    // MARK: - Векторные запасные варианты (как раньше)

    @ViewBuilder
    private func vectorEyes(headW: CGFloat, headH: CGFloat) -> some View {
        let eyeColor = configuration.eyeColor.color
        let eyeY = headH * 0.22
        ZStack {
            HStack(spacing: headW * 0.25) {
                eyeBall(eyeColor: eyeColor, focused: false)
                eyeBall(eyeColor: eyeColor, focused: false)
            }
            .offset(y: eyeY)
        }
    }

    @ViewBuilder
    private func vectorMouthOnly(headW: CGFloat, headH: CGFloat) -> some View {
        let mouthSize = mouthFrameSize(headW: headW)
        expressionShape()
            .fill(mouthFillColor)
            .frame(width: mouthSize.width, height: mouthSize.height)
            .offset(y: headH * 0.57)
    }

    private func mouthFrameSize(headW: CGFloat) -> CGSize {
        CGSize(width: headW * 0.36, height: 14)
    }

    private var mouthFillColor: Color {
        Color(red: 0.35, green: 0.32, blue: 0.34)
    }

    private func eyeBall(eyeColor: Color, focused: Bool) -> some View {
        let w: CGFloat = focused ? 17 : 20
        let h: CGFloat = focused ? 14 : 16
        let pupil: CGFloat = focused ? 6 : 8
        return Circle().fill(.white).frame(width: w, height: h)
            .overlay(Circle().fill(eyeColor).frame(width: pupil, height: pupil))
    }

    @ViewBuilder
    private func torsoLayer(bodyW: CGFloat, bodyH: CGFloat, color: Color) -> some View {
        switch torsoGarment {
        case .tshirt:
            RoundedRectangle(cornerRadius: 26)
                .fill(color)
                .frame(width: bodyW, height: bodyH)
        case .sweater:
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(color)
                    .frame(width: bodyW, height: bodyH)
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.88))
                    .frame(width: bodyW * 0.44, height: bodyH * 0.26)
                    .offset(y: -bodyH * 0.36)
            }
        case .hoodie:
            RoundedRectangle(cornerRadius: 26)
                .fill(color)
                .frame(width: bodyW, height: bodyH)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.12), lineWidth: 2)
                        .frame(width: bodyW * 0.32, height: bodyH * 0.2)
                        .offset(y: -bodyH * 0.38)
                )
        case .jacket:
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .frame(width: bodyW, height: bodyH)
                JacketLapelsPath()
                    .stroke(Color.black.opacity(0.38), lineWidth: 3)
                    .frame(width: bodyW, height: bodyH)
                    .offset(y: -bodyH * 0.02)
            }
        }
    }

    private func hairShape(headW: CGFloat, headH: CGFloat) -> some Shape {
        switch configuration.hairstyle {
        case .bald: return AnyShape(Rectangle())
        case .sidePart, .slick: return AnyShape(RoundedRectangle(cornerRadius: 20))
        case .shortFlat: return AnyShape(Capsule())
        case .curl, .waves: return AnyShape(Ellipse())
        case .modernTop, .pompadour: return AnyShape(RoundedRectangle(cornerRadius: 22))
        case .buzz, .spiky: return AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func expressionShape() -> some Shape {
        AnyShape(Capsule())
    }

    private func facialHairShape(headW: CGFloat) -> some Shape {
        switch configuration.facialHairStyle {
        case .none: return AnyShape(Rectangle())
        case .moustache: return AnyShape(Capsule())
        case .trimmed: return AnyShape(RoundedRectangle(cornerRadius: 10))
        case .goatee: return AnyShape(Capsule())
        case .beardFull: return AnyShape(RoundedRectangle(cornerRadius: 12))
        case .beardLight: return AnyShape(RoundedRectangle(cornerRadius: 11))
        case .beardBushy: return AnyShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func glassesShape(headW: CGFloat) -> some Shape {
        switch configuration.glassesStyle {
        case .none: return AnyShape(Rectangle())
        case .round: return AnyShape(Ellipse())
        case .square: return AnyShape(RoundedRectangle(cornerRadius: 4))
        case .sunglasses: return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .slim: return AnyShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private func headwearShape(headW: CGFloat) -> some Shape {
        switch configuration.headwearStyle {
        case .none: return AnyShape(Rectangle())
        case .cap: return AnyShape(Capsule())
        case .beanie: return AnyShape(RoundedRectangle(cornerRadius: 10))
        case .bandana: return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .sportCap: return AnyShape(Capsule())
        case .SilverLeague, .tenDayStreak, .beginner, .Premium: return AnyShape(Capsule())
        }
    }
}

// MARK: - Совместимость со старым именем

struct AvatarRendererView: View {
    let configuration: AvatarConfiguration
    var body: some View { AvatarLayeredComposerView(configuration: configuration) }
}

// MARK: - Фигуры торса / запасные контуры

private struct JacketLapelsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let yTop = h * 0.1
        p.move(to: CGPoint(x: w * 0.1, y: yTop))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.4))
        p.addLine(to: CGPoint(x: w * 0.9, y: yTop))
        return p
    }
}

struct AngryBrowsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.02, y: h * 0.62))
        p.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.22), control: CGPoint(x: w * 0.18, y: h * 0.12))
        p.move(to: CGPoint(x: w * 0.98, y: h * 0.62))
        p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.22), control: CGPoint(x: w * 0.82, y: h * 0.12))
        return p
    }
}

struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ wrapped: S) {
        _path = { rect in wrapped.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path { _path(rect) }
}
