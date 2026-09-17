import SwiftUI

/// Режим «как у Duolingo»: один логический холст **501×684**, все `avatar_body_*` / `avatar_hair_*` / `avatar_expression_*`
/// в **одинаковом** кадре и масштабе (см. `temporary_examples`).
struct AvatarDuolingoCanvasComposer: View {
    private static let canvasW: CGFloat = 501
    private static let canvasH: CGFloat = 684

    let configuration: AvatarConfiguration

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let baseScale = min(w / Self.canvasW, h / Self.canvasH)
            let fw = Self.canvasW * baseScale
            let fh = Self.canvasH * baseScale
            let isTallCard = h > w * 1.08
            let tallFitScale: CGFloat = isTallCard
                ? min(1.72, (h * 0.92) / max(fh, 1))
                : 1.0

            /// Зона лица — доли холста (для очков / шапки / векторных запасных слоёв).
            let headW = fw * 0.40
            let headH = fh * 0.34

            let bodyName = resolvedBodyAsset(for: configuration.bodyStyle)!
            let mouthResolved = resolvedMouthImageName(for: configuration.expression)
            let expressionIsCompositePNG = mouthResolved?.hasPrefix("avatar_expression_") == true

            /// Торс ниже, «голова» выше — шея читается; холст 501×684 без обрезки снизу.
            let torsoDrop = fh * 0.028
            let headClusterLift = -fh * 0.016

            ZStack(alignment: .top) {
                ZStack {
                    Image(bodyName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: fw, height: fh)
                        .offset(y: torsoDrop)
                        .accessibilityHidden(true)

                    Group {
                        duolingoHairLayer(fw: fw, fh: fh, headW: headW, headH: headH)

                        if expressionIsCompositePNG, let mouthName = mouthResolved {
                            Image(mouthName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: fw, height: fh)
                                .accessibilityHidden(true)
                        } else {
                            duolingoEyes(headW: headW, headH: headH)
                            if let mouthName = mouthResolved {
                                Image(mouthName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: headW * 0.55, height: headH * 0.22)
                                    .offset(y: headH * 0.57)
                                    .accessibilityHidden(true)
                            } else {
                                duolingoVectorMouth(headW: headW, headH: headH)
                            }
                        }

                        duolingoFacialHairLayer(fw: fw, fh: fh, headW: headW, headH: headH)

                        duolingoGlasses(headW: headW, headH: headH)
                        duolingoHeadwear(headW: headW, headH: headH, fw: fw, fh: fh)
                    }
                    .offset(y: headClusterLift)
                }
                .frame(width: fw, height: fh)
            }
            .scaleEffect(tallFitScale, anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Подслои

    @ViewBuilder
    private func duolingoHairLayer(fw: CGFloat, fh: CGFloat, headW: CGFloat, headH: CGFloat) -> some View {
        if let hairName = AvatarLayerAssetNames.hair(configuration.hairstyle),
           AvatarBundleImage.exists(hairName) {
            if hairName.hasPrefix("avatar_hair_") {
                Image(hairName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fw, height: fh)
                    .accessibilityHidden(true)
            } else {
                Image(hairName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: headW * 1.25, height: headH * 0.75)
                    .colorMultiply(configuration.hairColor.color)
                    .offset(y: -headH * 0.12)
                    .accessibilityHidden(true)
            }
        } else if configuration.hairstyle != .bald {
            duolingoHairShape()
                .fill(configuration.hairColor.color)
                .frame(width: headW * 1.35, height: headH * 0.9)
                .offset(y: -headH * 0.20)
        }
    }

    @ViewBuilder
    private func duolingoFacialHairLayer(fw: CGFloat, fh: CGFloat, headW: CGFloat, headH: CGFloat) -> some View {
        if let beard = AvatarLayerAssetNames.beard(configuration.facialHairStyle),
           AvatarBundleImage.exists(beard) {
            if beard.hasPrefix("avatar_facial_hair_") {
                Image(beard)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fw, height: fh)
                    .accessibilityHidden(true)
            } else {
                Image(beard)
                    .resizable()
                    .scaledToFit()
                    .frame(width: headW * 1.1, height: headH * 0.55)
                    .colorMultiply((configuration.facialHairColor ?? configuration.hairColor).color)
                    .offset(y: headH * 0.52)
                    .accessibilityHidden(true)
            }
        } else if configuration.facialHairStyle != .none {
            duolingoFacialHairShape()
                .fill((configuration.facialHairColor ?? configuration.hairColor).color)
                .frame(width: headW * 1.15, height: headH * 0.55)
                .offset(y: headH * 0.60)
        }
    }

    private func duolingoFacialHairShape() -> some Shape {
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

    @ViewBuilder
    private func duolingoGlasses(headW: CGFloat, headH: CGFloat) -> some View {
        if let g = AvatarLayerAssetNames.glasses(configuration.glassesStyle),
           AvatarBundleImage.exists(g) {
            Image(g)
                .resizable()
                .scaledToFit()
                .frame(width: headW * 1.15, height: headH * 0.32)
                .colorMultiply((configuration.glassesColor ?? .blue).color)
                .offset(y: headH * 0.22)
                .accessibilityHidden(true)
        } else if configuration.glassesStyle != .none {
            duolingoGlassesShape()
                .stroke((configuration.glassesColor ?? .blue).color, lineWidth: 2.4)
                .frame(width: headW * 1.2, height: headH * 0.36)
                .offset(y: headH * 0.25)
        }
    }

    @ViewBuilder
    private func duolingoHeadwear(headW: CGFloat, headH: CGFloat, fw: CGFloat, fh: CGFloat) -> some View {
        if let hatName = AvatarLayerAssetNames.hat(configuration.headwearStyle),
           AvatarBundleImage.exists(hatName) {
            if hatName.hasPrefix("avatar_hat_") {
                Image(hatName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fw, height: fh)
                    .accessibilityHidden(true)
            } else {
                Image(hatName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: headW * 1.2, height: headH * 0.55)
                    .colorMultiply((configuration.headwearColor ?? .purple).color)
                    .offset(y: -headH * 0.28)
                    .accessibilityHidden(true)
            }
        } else if configuration.headwearStyle != .none {
            duolingoHeadwearShape()
                .fill((configuration.headwearColor ?? .purple).color)
                .frame(width: headW * 1.25, height: headH * 0.62)
                .offset(y: -headH * 0.33)
        }
    }

    @ViewBuilder
    private func duolingoEyes(headW: CGFloat, headH: CGFloat) -> some View {
        let eyeColor = configuration.eyeColor.color
        let eyeName = AvatarLayerAssetNames.eyes(configuration.eyeColor)
        if AvatarBundleImage.exists(eyeName) {
            Image(eyeName)
                .resizable()
                .scaledToFit()
                .frame(width: headW * 1.05, height: headH * 0.38)
                .offset(y: headH * 0.18)
                .accessibilityHidden(true)
        } else {
            let eyeY = headH * 0.22
            HStack(spacing: headW * 0.25) {
                duolingoEyeBall(eyeColor: eyeColor, focused: false)
                duolingoEyeBall(eyeColor: eyeColor, focused: false)
            }
            .offset(y: eyeY)
        }
    }

    private func duolingoEyeBall(eyeColor: Color, focused: Bool) -> some View {
        let w: CGFloat = focused ? 17 : 20
        let h: CGFloat = focused ? 14 : 16
        let pupil: CGFloat = focused ? 6 : 8
        return Circle().fill(.white).frame(width: w, height: h)
            .overlay(Circle().fill(eyeColor).frame(width: pupil, height: pupil))
    }

    @ViewBuilder
    private func duolingoVectorMouth(headW: CGFloat, headH: CGFloat) -> some View {
        let mouthSize = duolingoMouthFrameSize(headW: headW)
        duolingoExpressionShape()
            .fill(duolingoMouthFillColor)
            .frame(width: mouthSize.width, height: mouthSize.height)
            .offset(y: headH * 0.57)
    }

    private func duolingoMouthFrameSize(headW: CGFloat) -> CGSize {
        CGSize(width: headW * 0.36, height: 14)
    }

    private var duolingoMouthFillColor: Color {
        Color(red: 0.35, green: 0.32, blue: 0.34)
    }

    private func duolingoHairShape() -> some Shape {
        switch configuration.hairstyle {
        case .bald: AnyShape(Rectangle())
        case .sidePart, .slick: AnyShape(RoundedRectangle(cornerRadius: 20))
        case .shortFlat: AnyShape(Capsule())
        case .curl, .waves: AnyShape(Ellipse())
        case .modernTop, .pompadour: AnyShape(RoundedRectangle(cornerRadius: 22))
        case .buzz, .spiky: AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func duolingoExpressionShape() -> some Shape {
        AnyShape(Capsule())
    }

    private func duolingoGlassesShape() -> some Shape {
        switch configuration.glassesStyle {
        case .none: AnyShape(Rectangle())
        case .round: AnyShape(Ellipse())
        case .square: AnyShape(RoundedRectangle(cornerRadius: 4))
        case .sunglasses: AnyShape(RoundedRectangle(cornerRadius: 6))
        case .slim: AnyShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private func duolingoHeadwearShape() -> some Shape {
        switch configuration.headwearStyle {
        case .none: AnyShape(Rectangle())
        case .cap: AnyShape(Capsule())
        case .beanie: AnyShape(RoundedRectangle(cornerRadius: 10))
        case .bandana: AnyShape(RoundedRectangle(cornerRadius: 6))
        case .sportCap: AnyShape(Capsule())
        case .SilverLeague, .tenDayStreak, .beginner, .Premium: AnyShape(Capsule())
        }
    }

    // MARK: - Разрешение ассетов (как в `AvatarLayeredComposerView`)

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

    private func legacyBodyAssetName(for silhouette: AvatarBodyStyle) -> String {
        switch silhouette {
        case .slim: return "AvatarEditorBodySlim"
        case .wide: return "AvatarEditorBodyWide"
        case .regular, .hoodie, .tshirt, .sweater: return "AvatarEditorBodyRegular"
        }
    }

    private func resolvedMouthImageName(for expression: AvatarExpression) -> String? {
        let primary = AvatarLayerAssetNames.mouthPrimary(expression)
        if AvatarBundleImage.exists(primary) { return primary }
        let fb = AvatarLayerAssetNames.mouthFallback(expression)
        return AvatarBundleImage.exists(fb) ? fb : nil
    }
}
