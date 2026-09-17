import SwiftUI
#if os(iOS)
import UIKit
#endif

final class AvatarEditorViewModel: ObservableObject {
    @Published var draft: AvatarConfiguration
    let original: AvatarConfiguration
    @Published var selectedCategory: AvatarEditorCategory = .body

    init(configuration: AvatarConfiguration) {
        var cfg = configuration
        AvatarEditorViewModel.sanitizeDraftForEditor(&cfg)
        self.draft = cfg
        self.original = cfg
        if !AvatarEditorViewModel.visibleEditorCategories.contains(self.selectedCategory) {
            self.selectedCategory = .body
        }
    }

    var hasChanges: Bool { draft != original }

    /// Видимые вкладки (без очков и одежды — временно).
    static var visibleEditorCategories: [AvatarEditorCategory] {
        AvatarEditorCategory.allCases.filter { $0 != .glasses && $0 != .clothing }
    }

    /// Убранные из редактора эмоции / шапки не оставляем в черновике (иначе превью без выбора в сетке).
    static func sanitizeDraftForEditor(_ cfg: inout AvatarConfiguration) {
        if AvatarEditorView.hiddenExpressionRawValues.contains(cfg.expression.rawValue) {
            cfg.expression = .e1
        }
        if cfg.headwearStyle == .beanie || cfg.headwearStyle == .bandana {
            cfg.headwearStyle = .none
            cfg.headwearColor = nil
        }
    }
}

struct AvatarEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var viewModel: AvatarEditorViewModel
    @State private var showDiscardAlert = false
    @State private var showHeadwearLockAlert = false
    @State private var headwearLockAlertMessage = ""

    /// Эмоции, скрытые в сетке редактора (номера 1…23 на ассетах).
    static let hiddenExpressionRawValues: Set<Int> = [2, 4, 5, 6, 9, 10]
    /// iPad / широкий контейнер: превью слева, опции справа, табы снизу (паттерн Duolingo).
    private var useWideAvatarLayout: Bool { horizontalSizeClass == .regular }
    private let wideLayoutTabBarHeight: CGFloat = 58

    init() {
        let config = AvatarStorage.shared.load() ?? AvatarConfiguration.default
        _viewModel = StateObject(wrappedValue: AvatarEditorViewModel(configuration: config))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                if useWideAvatarLayout {
                    wideAvatarEditorBody
                } else {
                    compactAvatarEditorBody
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemGray6))
        .alert(t("discard_title"), isPresented: $showDiscardAlert) {
            Button(t("discard_action"), role: .destructive) { dismiss() }
            Button(t("continue_editing"), role: .cancel) { }
        } message: {
            Text(t("discard_message"))
        }
        .alert(t("lock_item_title"), isPresented: $showHeadwearLockAlert) {
            Button(t("lock_item_ok"), role: .cancel) { }
        } message: {
            Text(headwearLockAlertMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 6) {
            Button {
                if viewModel.hasChanges { showDiscardAlert = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            Text(t("edit_avatar"))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Button {
                saveAvatar()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.blue)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("done"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white)
    }

    /// Кадр «по пояс»: ~половина высоты экрана, ширина на весь блок — композитор сам подгоняет масштаб.
    private var avatarPreviewCanvasHeight: CGFloat {
        #if os(iOS)
        min(max(UIScreen.main.bounds.height * 0.46, 300), 520)
        #else
        320
            #endif
    }

    private var compactAvatarEditorBody: some View {
        VStack(spacing: 0) {
            avatarPreviewBlock(canvasHeight: avatarPreviewCanvasHeight)
            categoryTabs
            editorPanel
        }
    }

    private var wideAvatarEditorBody: some View {
        GeometryReader { geo in
            let mainH = max(220, geo.size.height - wideLayoutTabBarHeight)
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    avatarPreviewBlock(canvasHeight: mainH)
                        .frame(width: min(420, max(280, geo.size.width * 0.38)))
                    Divider()
                    ScrollView {
                        editorScrollSections
                            .padding(14)
                            .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: mainH)
                }
                .frame(height: mainH)
                categoryTabs
            }
        }
    }

    private func avatarPreviewBlock(canvasHeight: CGFloat) -> some View {
        ZStack {
            viewModel.draft.backgroundColor.color
            AvatarRendererView(configuration: viewModel.draft)
                .id("\(viewModel.draft.skinTone.rawValue)-\(viewModel.draft.bodyStyle.rawValue)-\(viewModel.draft.clothingStyle.rawValue)-\(viewModel.draft.expression.rawValue)-\(viewModel.draft.hairstyle.rawValue)-\(viewModel.draft.hairColor.rawValue)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .frame(height: canvasHeight)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(AvatarEditorViewModel.visibleEditorCategories) { category in
                    Button {
                        viewModel.selectedCategory = category
        } label: {
                        VStack(spacing: 7) {
                            Image(categoryTabAssetName(for: category))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 54, height: 54)
                                .opacity(viewModel.selectedCategory == category ? 1 : 0.55)
                            Rectangle()
                                .fill(viewModel.selectedCategory == category ? Color.blue : .clear)
                                .frame(height: 2.5)
                        }
                        .frame(width: 66)
        }
        .buttonStyle(.plain)
    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.white)
    }

    @ViewBuilder
    private var editorScrollSections: some View {
        VStack(alignment: .leading, spacing: 22) {
            switch viewModel.selectedCategory {
            case .body: bodySection
            case .face: faceSection
            case .hair: hairSection
            case .glasses: glassesSection
            case .facialHair: facialHairSection
            case .headwear: headwearSection
            case .clothing: clothingSection
            case .background: backgroundSection
            }
        }
    }

    private var editorPanel: some View {
        ScrollView {
            editorScrollSections
                .padding(14)
                .padding(.bottom, 30)
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("skin_tone"))
            Text(t("editor_section_coming_soon"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            sectionTitle(t("body"))
            AvatarStyleGrid(items: AvatarBodyStyle.allCases, selected: viewModel.draft.bodyStyle, title: bodyTitle, preview: { item in
                AnyView(bodyShapePreview(for: item))
            }) { item in
                viewModel.draft.bodyStyle = item
                switch item {
                case .hoodie: viewModel.draft.clothingStyle = .hoodie
                case .tshirt: viewModel.draft.clothingStyle = .tshirt
                case .sweater: viewModel.draft.clothingStyle = .sweater
                case .slim, .regular, .wide: break
                }
            }
        }
    }

    private var faceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("eye_color"))
            Text(t("editor_section_coming_soon"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            sectionTitle(t("expression"))
            AvatarStyleGrid(
                items: expressionEditorItems,
                selected: viewModel.draft.expression,
                showLabels: false,
                title: { _ in "" },
                accessibilityLabel: { item in
                    if let idx = expressionEditorItems.firstIndex(of: item) {
                        return "\(t("expression")) \(idx + 1)"
                    }
                    return t("expression")
                },
                preview: { item in
                    AnyView(expressionPreview(for: item))
                }
            ) {
                viewModel.draft.expression = $0
            }
        }
    }

    private var expressionEditorItems: [AvatarExpression] {
        AvatarExpression.allCases.filter { !Self.hiddenExpressionRawValues.contains($0.rawValue) }
    }

    private var headwearEditorItems: [AvatarHeadwearStyle] {
        AvatarHeadwearStyle.allCases.filter { $0 != .beanie && $0 != .bandana }
    }

    private func presentHeadwearLockExplanation(for style: AvatarHeadwearStyle) {
        switch style.availability {
        case .premiumSubscription:
            headwearLockAlertMessage = t("lock_headwear_premium_body")
        case .shopLocked:
            headwearLockAlertMessage = t("lock_headwear_shop_body")
        case .always:
            headwearLockAlertMessage = t("lock_headwear_generic_body")
        }
        showHeadwearLockAlert = true
    }

    private var hairSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("main_hair_color"))
            Text(t("editor_section_coming_soon"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            sectionTitle(t("hairstyle"))
            AvatarStyleGrid(items: AvatarHairStyle.allCases, selected: viewModel.draft.hairstyle, title: hairTitle, preview: { item in
                AnyView(hairStylePreview(for: item))
            }) {
                viewModel.draft.hairstyle = $0
            }
        }
    }

    private var glassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("glasses"))
            AvatarStyleGrid(items: AvatarGlassesStyle.allCases, selected: viewModel.draft.glassesStyle, title: glassesTitle, preview: { item in
                AnyView(glassesIconPreview(for: item))
            }) {
                viewModel.draft.glassesStyle = $0
                if $0 == .none { viewModel.draft.glassesColor = nil }
            }
            if viewModel.draft.glassesStyle != .none {
                sectionTitle(t("glasses_color"))
                AvatarColorGrid(
                    colors: [.black, .blue, .green, .orange, .redSoft, .purple],
                    selected: viewModel.draft.glassesColor ?? .blue
                ) { viewModel.draft.glassesColor = $0 }
            }
        }
    }

    private var facialHairSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("facial_hair"))
            AvatarStyleGrid(items: AvatarFacialHairStyle.allCases, selected: viewModel.draft.facialHairStyle, title: facialHairTitle, preview: { item in
                AnyView(stylePreview { $0.facialHairStyle = item })
            }) {
                viewModel.draft.facialHairStyle = $0
                if $0 == .none { viewModel.draft.facialHairColor = nil }
            }
            if viewModel.draft.facialHairStyle != .none, !facialHairUsesPreColoredPNG {
                sectionTitle(t("facial_hair_color"))
                AvatarColorGrid(
                    colors: [.black, .darkBrown, .brown, .auburn, .gray, .white],
                    selected: viewModel.draft.facialHairColor ?? .brown
                ) { viewModel.draft.facialHairColor = $0 }
            }
        }
    }

    private var headwearSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("headwear"))
            AvatarHeadwearStyleGrid(
                items: headwearEditorItems,
                selected: viewModel.draft.headwearStyle,
                isPremiumActive: gameState.isPremium,
                title: headwearTitle,
                preview: { item in AnyView(stylePreview { $0.headwearStyle = item }) },
                onSelect: { style in
                    viewModel.draft.headwearStyle = style
                    if style == .none { viewModel.draft.headwearColor = nil }
                },
                onLockedTap: { presentHeadwearLockExplanation(for: $0) }
            )
            if viewModel.draft.headwearStyle != .none, !headwearUsesPreColoredHatPNG {
                sectionTitle(t("headwear_color"))
                AvatarColorGrid(
                    colors: [.purple, .blue, .green, .yellow, .orange, .redSoft],
                    selected: viewModel.draft.headwearColor ?? .purple
                ) { viewModel.draft.headwearColor = $0 }
            }
        }
    }

    private var headwearUsesPreColoredHatPNG: Bool {
        guard viewModel.draft.headwearStyle != .none,
              let name = AvatarLayerAssetNames.hat(viewModel.draft.headwearStyle),
              AvatarBundleImage.exists(name) else { return false }
        return name.hasPrefix("avatar_hat_")
    }

    private var clothingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("clothing_color"))
            AvatarColorGrid(
                colors: [.purple, .skyBlue, .green, .yellow, .orange, .redSoft, .pink, .lightGray, .darkGray],
                selected: viewModel.draft.clothingColor
            ) { viewModel.draft.clothingColor = $0 }
            sectionTitle(t("clothing_style"))
            AvatarStyleGrid(items: AvatarClothingStyle.allCases, selected: viewModel.draft.clothingStyle, title: clothingTitle, preview: { item in
                AnyView(stylePreview { $0.clothingStyle = item })
            }) { item in
                viewModel.draft.clothingStyle = item
                switch item {
                case .hoodie, .tshirt, .sweater:
                    if [.hoodie, .tshirt, .sweater].contains(viewModel.draft.bodyStyle) {
                        switch item {
                        case .hoodie: viewModel.draft.bodyStyle = .hoodie
                        case .tshirt: viewModel.draft.bodyStyle = .tshirt
                        case .sweater: viewModel.draft.bodyStyle = .sweater
                        default: break
                        }
                    }
                case .jacket:
                    if [.hoodie, .tshirt, .sweater].contains(viewModel.draft.bodyStyle) {
                        viewModel.draft.bodyStyle = .regular
                    }
                }
            }
        }
    }

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(t("background_color"))
            AvatarColorGrid(
                colors: [.lightGray, .gray, .darkGray, .beige, .purple, .skyBlue, .blue, .mint, .green, .lime, .yellow, .orange, .peach, .pink, .redSoft],
                selected: viewModel.draft.backgroundColor
            ) { viewModel.draft.backgroundColor = $0 }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .minimumScaleFactor(0.7)
            .lineLimit(1)
    }

    private func stylePreview(apply: (inout AvatarConfiguration) -> Void) -> some View {
        var cfg = viewModel.draft
        apply(&cfg)
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(cfg.backgroundColor.color.opacity(0.9))
            AvatarRendererView(configuration: cfg)
                .padding(6)
        }
    }

    private func categoryTabAssetName(for category: AvatarEditorCategory) -> String {
        switch category {
        /// Иконки 1-го и 2-го таба переставлены; разделы `.body` / `.face` и `editorScrollSections` без изменений.
        case .body: return "AvatarEditorTabFace"
        case .face: return "AvatarEditorTabBody"
        case .hair: return "AvatarEditorTabHair"
        case .glasses: return "AvatarEditorTabGlasses"
        case .facialHair: return "AvatarEditorTabFacialHair"
        case .headwear: return "AvatarEditorTabHeadwear"
        case .clothing: return "AvatarEditorTabClothing"
        case .background: return "AvatarEditorTabBackground"
        }
    }

    @ViewBuilder
    private func bodyShapePreview(for item: AvatarBodyStyle) -> some View {
        let layer = AvatarLayerAssetNames.body(for: item)
        if AvatarBundleImage.exists(layer) {
            tabIconCard {
                Image(layer)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            }
        } else {
            switch item {
            case .slim:
                tabIconCard { Image("AvatarEditorBodySlim").resizable().scaledToFit().padding(4) }
            case .regular:
                tabIconCard { Image("AvatarEditorBodyRegular").resizable().scaledToFit().padding(4) }
            case .wide:
                tabIconCard { Image("AvatarEditorBodyWide").resizable().scaledToFit().padding(4) }
            case .hoodie, .tshirt, .sweater:
                stylePreview { $0.bodyStyle = item }
            }
        }
    }

    private func tabIconCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.14))
            content()
        }
    }

    @ViewBuilder
    private func glassesIconPreview(for style: AvatarGlassesStyle) -> some View {
        let name: String = {
            if let layer = AvatarLayerAssetNames.glasses(style), AvatarBundleImage.exists(layer) { return layer }
            switch style {
            case .none: return "AvatarPickerGlassesNone"
            case .round: return "AvatarPickerGlassesRound"
            case .square: return "AvatarPickerGlassesSquare"
            case .sunglasses: return "AvatarPickerGlassesSunglasses"
            case .slim: return "AvatarPickerGlassesSlim"
            }
        }()
        tabIconCard {
            Image(name)
                .resizable()
                .scaledToFit()
                .padding(6)
        }
    }

    @ViewBuilder
    private func expressionPreview(for item: AvatarExpression) -> some View {
        let primary = AvatarLayerAssetNames.mouthPrimary(item)
        tabIconCard {
            Image(primary)
                .resizable()
                .scaledToFit()
                .padding(4)
        }
    }

    @ViewBuilder
    private func hairStylePreview(for item: AvatarHairStyle) -> some View {
        switch item {
        case .bald:
            tabIconCard {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        default:
            if let layer = AvatarLayerAssetNames.hair(item), AvatarBundleImage.exists(layer) {
                tabIconCard { hairPNGSwatch(layerName: layer) }
            } else {
                hairLegacyIconPreview(for: item)
            }
        }
    }

    /// Только верх ассета (причёска), без полного тела — не дублируем «вторую голову» как `stylePreview`.
    @ViewBuilder
    private func hairPNGSwatch(layerName: String) -> some View {
        let tinted = !layerName.hasPrefix("avatar_hair_")
        Group {
            if tinted {
                Image(layerName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .padding(4)
                    .colorMultiply(viewModel.draft.hairColor.color)
            } else {
                Image(layerName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .padding(4)
            }
        }
    }

    @ViewBuilder
    private func hairLegacyIconPreview(for item: AvatarHairStyle) -> some View {
        switch item {
        case .shortFlat, .buzz:
            tabIconCard { Image("AvatarPickerHairShort").resizable().scaledToFit().padding(4) }
        case .curl, .waves:
            tabIconCard { Image("AvatarPickerHairCurl").resizable().scaledToFit().padding(4) }
        case .sidePart, .modernTop, .slick, .pompadour:
            tabIconCard { Image("AvatarPickerHairBold").resizable().scaledToFit().padding(4) }
        case .spiky:
            tabIconCard { Image("AvatarPickerHairShort").resizable().scaledToFit().padding(4) }
        case .bald:
            tabIconCard {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveAvatar() {
        AvatarStorage.shared.save(viewModel.draft)
        #if os(iOS)
        if let data = snapshotAvatarJPEG(configuration: viewModel.draft) {
            userProfile.customAvatarImageData = data
            userProfile.avatar = "custom_photo"
        }
        #endif

        userProfile.saveToStorage()
        let username = userProfile.username
        Task {
            try? await DuelAPIService.shared.updateMyAvatarConfig(
                userId: username,
                config: viewModel.draft,
                avatar: userProfile.avatar,
                customAvatarImageData: userProfile.customAvatarImageData
            )
        }
        dismiss()
    }

    #if os(iOS)
    /// Экспорт в JPEG для профиля: **квадрат** под рамку в шапке профиля (без полей `scaledToFit`).
    private func snapshotAvatarJPEG(configuration: AvatarConfiguration) -> Data? {
        let exportS: CGFloat = 360
        let size = CGSize(width: exportS, height: exportS)
        let root = avatarExportRoot(configuration: configuration, exportSize: exportS)

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: root)
            renderer.scale = UIScreen.main.scale
            renderer.proposedSize = ProposedViewSize(width: exportS, height: exportS)
            if let ui = renderer.uiImage {
                return ui.jpegData(compressionQuality: 0.92)
            }
        }
        return snapshotAvatarJPEGLegacy(root: root, size: size, backgroundUIColor: UIColor(configuration.backgroundColor.color))
    }

    /// Квадратный кадр: фон на весь размер + портретный холст конструктора заполняет квадрат (обрезка как в профиле `scaledToFill`).
    private func avatarExportRoot(configuration: AvatarConfiguration, exportSize: CGFloat) -> some View {
        let canvasAspectWidthOverHeight: CGFloat = 501 / 684
        return ZStack {
            Rectangle()
                .fill(configuration.backgroundColor.color)
                .frame(width: exportSize, height: exportSize)
            AvatarRendererView(configuration: configuration)
                .aspectRatio(canvasAspectWidthOverHeight, contentMode: .fill)
                .frame(width: exportSize, height: exportSize)
                .clipped()
        }
        .frame(width: exportSize, height: exportSize)
        .clipped()
    }

    private func snapshotAvatarJPEGLegacy<V: View>(root: V, size: CGSize, backgroundUIColor: UIColor) -> Data? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return nil
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: -20_000, y: -20_000, width: size.width, height: size.height)
        window.windowLevel = .normal
        window.backgroundColor = backgroundUIColor
        let hosting = UIHostingController(rootView: root)
        hosting.view.bounds = CGRect(origin: .zero, size: size)
        hosting.view.backgroundColor = backgroundUIColor
        window.rootViewController = hosting
        window.isHidden = false
        window.makeKeyAndVisible()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        CATransaction.flush()
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        let imgRenderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = imgRenderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        return image.jpegData(compressionQuality: 0.92)
    }
    #endif

    private func bodyTitle(_ item: AvatarBodyStyle) -> String {
        switch item {
        case .slim: return t("opt_slim")
        case .regular: return t("opt_regular")
        case .hoodie: return t("opt_hoodie")
        case .tshirt: return t("opt_tshirt")
        case .sweater: return t("opt_sweater")
        case .wide: return t("opt_wide")
        }
    }

    private func hairTitle(_ item: AvatarHairStyle) -> String {
        switch item {
        case .bald: return t("opt_bald")
        case .sidePart: return t("opt_side_part")
        case .shortFlat: return t("opt_short")
        case .curl: return t("opt_curl")
        case .modernTop: return t("opt_modern")
        case .buzz: return t("opt_buzz")
        case .waves: return t("opt_hair_waves")
        case .spiky: return t("opt_hair_spiky")
        case .slick: return t("opt_hair_slick")
        case .pompadour: return t("opt_hair_pompadour")
        }
    }

    private func glassesTitle(_ item: AvatarGlassesStyle) -> String {
        switch item {
        case .none: return t("none")
        case .round: return t("round")
        case .square: return t("square")
        case .sunglasses: return t("sunglasses")
        case .slim: return t("slim")
        }
    }

    private var facialHairUsesPreColoredPNG: Bool {
        guard viewModel.draft.facialHairStyle != .none,
              let name = AvatarLayerAssetNames.beard(viewModel.draft.facialHairStyle),
              AvatarBundleImage.exists(name) else { return false }
        return name.hasPrefix("avatar_facial_hair_")
    }

    private func facialHairTitle(_ item: AvatarFacialHairStyle) -> String {
        switch item {
        case .none: return t("none")
        case .moustache: return t("opt_moustache")
        case .trimmed: return t("opt_trimmed")
        case .goatee: return t("opt_goatee")
        case .beardFull: return t("opt_beard_full")
        case .beardLight: return t("opt_beard_light")
        case .beardBushy: return t("opt_beard_bushy")
        }
    }

    private func headwearTitle(_ item: AvatarHeadwearStyle) -> String {
        switch item {
        case .none: return t("none")
        case .cap: return t("cap")
        case .beanie: return t("beanie")
        case .bandana: return t("bandana")
        case .sportCap: return t("sport_cap")
        case .SilverLeague: return t("hat_SilverLeague")
        case .tenDayStreak: return t("hat_10-day-streak")
        case .beginner: return t("hat_beginner")
        case .Premium: return t("hat_Premium")
        }
    }

    private func clothingTitle(_ item: AvatarClothingStyle) -> String {
        switch item {
        case .tshirt: return t("opt_tshirt")
        case .sweater: return t("opt_sweater")
        case .hoodie: return t("opt_hoodie")
        case .jacket: return t("opt_jacket")
        }
    }
}

private extension AvatarEditorView {
    /// Строки в `Localizable.strings`: ключ `avatar_editor_<internal>`, дефисы в internal заменяются на `_`.
    func t(_ key: String) -> String {
        let _ = localizationManager.currentLocale
        let bundleKey = "avatar_editor_" + key.replacingOccurrences(of: "-", with: "_")
        return LocalizationManager.shared.localizedString(bundleKey)
    }
}

struct AvatarSkinToneGrid: View {
    let selected: AvatarColorToken
    let onSelect: (AvatarColorToken) -> Void

    private let rows: [(AvatarColorToken, String)] = [
        (.peach, "AvatarEditorSkinPeach"),
        (.beige, "AvatarEditorSkinBeige"),
        (.lightBrown, "AvatarEditorSkinLightBrown"),
        (.brown, "AvatarEditorSkinBrown"),
        (.darkBrown, "AvatarEditorSkinDarkBrown"),
        (.black, "AvatarEditorSkinBlack")
    ]

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(rows, id: \.0) { row in
                Button {
                    onSelect(row.0)
                } label: {
                    ZStack {
                        Image(row.1)
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                        if row.0 == .black {
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.black.opacity(0.45))
                        }
                    }
                    .frame(height: 76)
                    .background(RoundedRectangle(cornerRadius: 13).fill(Color.gray.opacity(0.14)))
                                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(selected == row.0 ? Color.blue : Color.black.opacity(0.08), lineWidth: selected == row.0 ? 3 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Иконки оттенка глаз: имена слоёв `eyes_*` из `AvatarLayerAssetNames`, иначе старые превью.
struct AvatarEyeIconGrid: View {
    let selected: AvatarColorToken
    let onSelect: (AvatarColorToken) -> Void

    private let tokens: [AvatarColorToken] = [.black, .brown, .auburn, .green, .blue, .cyan]

    private func thumbAsset(for token: AvatarColorToken) -> String {
        let layer = AvatarLayerAssetNames.eyes(token)
        if AvatarBundleImage.exists(layer) { return layer }
        switch token {
        case .black: return "AvatarPickerEyeBlack"
        case .brown: return "AvatarPickerEyeBrown2"
        case .auburn: return "AvatarPickerEyeBrown3"
        case .green: return "AvatarPickerEyeGreen"
        case .blue: return "AvatarPickerEyeBlue"
        case .cyan: return "AvatarPickerEyeBrown4"
        default: return "AvatarPickerEyeBrown2"
        }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(tokens, id: \.self) { token in
                Button {
                    onSelect(token)
                } label: {
                    Image(thumbAsset(for: token))
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .frame(height: 72)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Color.gray.opacity(0.14)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(selected == token ? Color.blue : Color.black.opacity(0.08), lineWidth: selected == token ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AvatarColorGrid: View {
    let colors: [AvatarColorToken]
    let selected: AvatarColorToken
    let onSelect: (AvatarColorToken) -> Void

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(colors, id: \.self) { token in
                Button {
                    onSelect(token)
                } label: {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(token.color)
                        .frame(height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(selected == token ? Color.blue : Color.black.opacity(0.08), lineWidth: selected == token ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Сетка головных уборов: замок и недоступный тап для `availability` ≠ always (Premium / магазин).
private struct AvatarHeadwearStyleGrid: View {
    let items: [AvatarHeadwearStyle]
    let selected: AvatarHeadwearStyle
    let isPremiumActive: Bool
    let title: (AvatarHeadwearStyle) -> String
    let preview: (AvatarHeadwearStyle) -> AnyView
    let onSelect: (AvatarHeadwearStyle) -> Void
    let onLockedTap: (AvatarHeadwearStyle) -> Void

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                let unlocked = item.isUnlockedForEditor(isPremiumActive: isPremiumActive)
                Button {
                    if unlocked {
                        onSelect(item)
                    } else {
                        onLockedTap(item)
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 8) {
                            preview(item)
                                .frame(height: 74)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .opacity(unlocked ? 1 : 0.5)
                            Text(title(item))
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .multilineTextAlignment(.center)
                                .foregroundColor(unlocked ? .primary : .secondary)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(selected == item ? Color.blue.opacity(0.12) : .white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected == item ? Color.blue : Color.black.opacity(0.1), lineWidth: selected == item ? 2 : 1)
                        )
                        .cornerRadius(14)
                        if !unlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(5)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(6)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(item))
            }
        }
    }
}

struct AvatarStyleGrid<Item: CaseIterable & Hashable>: View {
    let items: [Item]
    let selected: Item
    /// Только иконки, без подписи под ячейкой (например эмоции).
    var showLabels: Bool = true
    let title: (Item) -> String
    /// Подпись для VoiceOver, если `showLabels == false` или нужно отличить от `title`.
    var accessibilityLabel: ((Item) -> String)? = nil
    let preview: (Item) -> AnyView
    let onSelect: (Item) -> Void

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    onSelect(item)
                } label: {
                    VStack(spacing: showLabels ? 8 : 0) {
                        preview(item)
                            .frame(height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        if showLabels {
                            Text(title(item))
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(8)
                    .background(selected == item ? Color.blue.opacity(0.12) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected == item ? Color.blue : Color.black.opacity(0.1), lineWidth: selected == item ? 2 : 1)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel?(item) ?? title(item))
            }
        }
    }
}

#Preview {
    AvatarEditorView()
        .environmentObject(UserProfile.shared)
        .environmentObject(GameState())
}

