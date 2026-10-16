import SwiftUI

struct AvatarShopView: View {
    @ObservedObject private var profile = UserProfile.shared
    @ObservedObject private var language = LocalizationManager.shared
    @State private var configuration = AvatarStorage.shared.load() ?? .default
    @State private var selected: AvatarShopProduct?
    @State private var wardrobe = false

    private func t(_ key: String) -> String { language.localizedString(key) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(t("fbucks.shop.title")).font(.title2.bold())
                    Spacer()
                    Text("\(profile.fBucks) F-Bucks").font(.headline).foregroundColor(.blue)
                }
                HStack {
                    AvatarRendererView(configuration: configuration)
                        .frame(width: 100, height: 120).clipShape(RoundedRectangle(cornerRadius: 22))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("shop.avatar")).font(.headline)
                        Text(t("shop.preview_hint")).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Picker("", selection: $wardrobe) {
                    Text(t("fbucks.tab.shop")).tag(false)
                    Text(t("shop.wardrobe")).tag(true)
                }.pickerStyle(.segmented)
                if wardrobe && profile.ownedAvatarItems.isEmpty {
                    Text(t("shop.empty")).foregroundColor(.secondary).padding(.vertical, 24)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                    ForEach(AvatarShopProduct.catalog.filter { !wardrobe || profile.ownedAvatarItems.contains($0.id) }) { item in
                        Button { selected = item } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                AvatarRendererView(configuration: item.applying(to: configuration))
                                    .frame(height: 170).clipped().clipShape(RoundedRectangle(cornerRadius: 18))
                                Text(t(item.nameKey)).font(.headline).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
                                Text(item.isEquipped(in: configuration) ? t("shop.equipped") : profile.ownedAvatarItems.contains(item.id) ? t("shop.owned") : "\(item.price) F-Bucks")
                                    .font(.subheadline.weight(.semibold)).foregroundColor(.blue)
                            }.padding(12).background(Color.primary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 22))
                        }.buttonStyle(.plain).accessibilityIdentifier("shop.item.\(item.id)")
                    }
                }
            }.frame(maxWidth: 900).padding(20).frame(maxWidth: .infinity)
        }
        .sheet(item: $selected, onDismiss: { configuration = AvatarStorage.shared.load() ?? .default }) { item in
            AvatarShopFittingView(item: item)
        }
    }
}

private struct AvatarShopFittingView: View {
    let item: AvatarShopProduct
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profile = UserProfile.shared
    @ObservedObject private var language = LocalizationManager.shared
    @State private var configuration = AvatarStorage.shared.load() ?? .default
    @State private var failed = false
    @State private var saving = false
    private var owned: Bool { profile.ownedAvatarItems.contains(item.id) }
    private var equipped: Bool { item.isEquipped(in: configuration) }
    private func t(_ key: String) -> String { language.localizedString(key) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AvatarRendererView(configuration: item.applying(to: configuration))
                        .frame(width: 240, height: 300).clipped().clipShape(RoundedRectangle(cornerRadius: 28))
                    Text(t(item.nameKey)).font(.title2.bold()).multilineTextAlignment(.center)
                    Text(t("shop.preview_hint")).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Text("\(profile.fBucks) F-Bucks").font(.headline)
                    Button(action: apply) {
                        Text(failed ? t("shop.equip") : owned ? t(equipped ? "shop.remove" : "shop.equip") : String(format: t("fbucks.buy_for"), item.price))
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                            .foregroundColor(.white).background(Color.indigo).clipShape(RoundedRectangle(cornerRadius: 16))
                    }.disabled(saving || (!owned && profile.fBucks < item.price))
                        .opacity(!owned && profile.fBucks < item.price ? 0.45 : 1)
                        .accessibilityIdentifier("shop.apply")
                    if !owned && profile.fBucks < item.price { Text(t("fbucks.earn_more")).foregroundColor(.secondary) }
                    if failed {
                        Text(t("shop.save_error")).foregroundColor(.red)
                    }
                }.padding(24).frame(maxWidth: 550).frame(maxWidth: .infinity)
            }.navigationTitle(t("shop.avatar")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(t("fbucks.close")) { dismiss() }.disabled(saving) } }
        }.navigationViewStyle(.stack).interactiveDismissDisabled(saving)
    }

    private func apply() {
        guard !saving else { return }
        let next = failed ? configuration : item.applying(to: configuration, remove: owned && equipped)
        #if os(iOS)
        guard let photo = AvatarPortraitExporter.jpeg(configuration: next) else { failed = true; return }
        guard owned || profile.purchaseAvatarItem(item.id) else { return }
        AvatarStorage.shared.save(next)
        profile.customAvatarImageData = photo
        profile.avatar = "custom_photo"
        profile.saveToStorage()
        configuration = next
        saving = true
        failed = false
        Task { @MainActor in
            do {
                try await DuelAPIService.shared.updateMyAvatarConfig(userId: profile.username, config: next, avatar: profile.avatar, customAvatarImageData: photo)
                saving = false
                dismiss()
            } catch {
                // Local purchase remains owned. A subsequent equip retries the portrait upload.
                saving = false
                failed = true
            }
        }
        #endif
    }
}
