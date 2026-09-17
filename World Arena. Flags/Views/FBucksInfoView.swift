import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - F-Bucks экран: герой-блок, ежедневный бонус, «заработать сегодня», прогресс, магазин по уровням

private enum FBucksShopTier: Int, CaseIterable, Comparable, Hashable {
    case common = 0, rare = 1, legendary = 2
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

private struct ShopItem: Identifiable {
    let id: String
    let name: String
    let price: Int
    let tier: FBucksShopTier
    let isLimited: Bool
    let icon: String
    var systemImageName: String? = nil
}

struct FBucksInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var heroScale: CGFloat = 0.65
    @State private var heroGlow: Double = 0.25
    @State private var showDailyToast = false
    @State private var coinBounce = false

    private var secondaryBG: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private var groupedBG: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    private var allShopItems: [ShopItem] {
        [
            ShopItem(id: "cap_1", name: localizationManager.localizedString("fbucks.item.traveler_cap"), price: 3, tier: .common, isLimited: false, icon: "", systemImageName: "cap.fill"),
            ShopItem(id: "shirt_1", name: localizationManager.localizedString("fbucks.item.champion_shirt"), price: 5, tier: .common, isLimited: false, icon: "", systemImageName: "tshirt.fill"),
            ShopItem(id: "socks_1", name: localizationManager.localizedString("fbucks.item.socks"), price: 4, tier: .common, isLimited: false, icon: "", systemImageName: "shoeprints.fill"),
            ShopItem(id: "skin_rainbow", name: localizationManager.localizedString("fbucks.item.rainbow_skin"), price: 15, tier: .rare, isLimited: false, icon: "", systemImageName: "paintbrush.pointed.fill"),
            ShopItem(id: "skin_gold", name: localizationManager.localizedString("fbucks.item.gold_skin"), price: 20, tier: .rare, isLimited: false, icon: "", systemImageName: "sparkles"),
            ShopItem(id: "jacket_1", name: localizationManager.localizedString("fbucks.item.explorer_jacket"), price: 10, tier: .rare, isLimited: false, icon: "", systemImageName: "jacket.closed.fill"),
            ShopItem(id: "effect_fire", name: localizationManager.localizedString("fbucks.item.fire_effect"), price: 12, tier: .rare, isLimited: false, icon: "", systemImageName: "flame.fill"),
            ShopItem(id: "skin_neon", name: localizationManager.localizedString("fbucks.item.neon_skin"), price: 25, tier: .rare, isLimited: false, icon: "", systemImageName: "light.max"),
            ShopItem(id: "effect_stars", name: localizationManager.localizedString("fbucks.item.stars_effect"), price: 50, tier: .legendary, isLimited: false, icon: "", systemImageName: "star.fill"),
            ShopItem(id: "champion_jacket", name: localizationManager.localizedString("fbucks.item.champion_jacket"), price: 100, tier: .legendary, isLimited: true, icon: "", systemImageName: "crown.fill"),
        ]
    }

    private var minItemPrice: Int { allShopItems.map(\.price).min() ?? 3 }

    private var affordableItemsApprox: Int {
        max(0, userProfile.fBucks / max(1, minItemPrice))
    }

    private var nextTargetItem: ShopItem? {
        let sorted = allShopItems.sorted { $0.price < $1.price }
        return sorted.first { $0.price > userProfile.fBucks } ?? sorted.last
    }

    private var progressToNext: Double {
        guard let t = nextTargetItem else { return 1 }
        if userProfile.fBucks >= t.price { return 1 }
        return Double(userProfile.fBucks) / Double(max(1, t.price))
    }

    private var maxEarnToday: Int {
        var n = 1
        if userProfile.canClaimDailyFBucksBonus() { n += 1 }
        n += 3
        return min(5, n)
    }

    private var featuredDreamItem: ShopItem? {
        allShopItems.first { $0.id == "champion_jacket" }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                fbucksTabBar
                TabView(selection: $selectedTab) {
                    overviewTab.tag(0)
                    aboutTab.tag(1)
                    historyTab.tag(2)
                    shopTab.tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(groupedBG)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString("fbucks.close")) { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                heroScale = 1.0
                heroGlow = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.35)) { showDailyToast = userProfile.canClaimDailyFBucksBonus() }
            }
        }
    }

    // MARK: Tab bar (иконки + подсветка)
    private var fbucksTabBar: some View {
        HStack(spacing: 4) {
            fbucksTabButton(icon: "sparkles", titleKey: "fbucks.tab.today", tag: 0)
            fbucksTabButton(icon: "info.circle.fill", titleKey: "fbucks.tab.about", tag: 1)
            fbucksTabButton(icon: "clock.arrow.circlepath", titleKey: "fbucks.tab.history", tag: 2)
            fbucksTabButton(icon: "cart.fill", titleKey: "fbucks.tab.shop", tag: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(secondaryBG.opacity(0.95))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func fbucksTabButton(icon: String, titleKey: String, tag: Int) -> some View {
        let selected = selectedTab == tag
        return Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag } }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(localizationManager.localizedString(titleKey))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Capsule()
                    .fill(selected ? Color.orange : Color.clear)
                    .frame(height: 3)
                    .padding(.horizontal, 4)
            }
            .foregroundColor(selected ? .orange : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Overview
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 22) {
                heroBlock
                dailyBonusBlock
                if showDailyToast && userProfile.canClaimDailyFBucksBonus() {
                    Text(localizationManager.localizedString("fbucks.daily.hint"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                earnTodaySection
                progressSection
                if let dream = featuredDreamItem, userProfile.fBucks < dream.price {
                    wantItemBlock(dream)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
    }

    private var heroBlock: some View {
        ZStack {
            RadialGradient(
                colors: [Color.orange.opacity(0.45 * heroGlow), Color.yellow.opacity(0.12), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
            .frame(height: 260)
            .allowsHitTesting(false)

            VStack(spacing: 14) {
                FBucksChipView(count: userProfile.fBucks, size: .hero, showRoundedBackground: false)
                    .scaleEffect(heroScale)
                    .scaleEffect(coinBounce ? 1.06 : 1.0)
                    .shadow(color: Color.orange.opacity(0.55), radius: 28, x: 0, y: 12)
                    .rotationEffect(.degrees(coinBounce ? 2 : -2))
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: coinBounce)
                    .onAppear { coinBounce = true }

                Text(localizationManager.localizedString("fbucks.currency.name"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))

                Text(heroSubtitleText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroSubtitleText: String {
        if affordableItemsApprox >= 3 {
            return String(format: localizationManager.localizedString("fbucks.hero.subtitle.enough"), affordableItemsApprox)
        }
        if userProfile.fBucks >= 10 {
            return localizationManager.localizedString("fbucks.hero.subtitle.rare")
        }
        return localizationManager.localizedString("fbucks.hero.subtitle.save")
    }

    private var dailyBonusBlock: some View {
        HStack {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(localizationManager.localizedString("fbucks.daily.title"))
                    .font(.system(size: 16, weight: .bold))
                Text(localizationManager.localizedString("F-Bucks"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if userProfile.canClaimDailyFBucksBonus() {
                Button(action: {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    userProfile.claimDailyFBucksBonus()
                }) {
                    Text(localizationManager.localizedString("fbucks.daily.claim"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [Color.orange, Color.red.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text(localizationManager.localizedString("fbucks.daily.claimed"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(secondaryBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var earnTodaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localizationManager.localizedString("fbucks.earn.today.title"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(String(format: localizationManager.localizedString("fbucks.earn.today.subtitle"), maxEarnToday))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)

            FBucksEarnCard(
                icon: "target",
                iconColor: .green,
                title: localizationManager.localizedString("fbucks.earn.perfect.title"),
                subtitle: localizationManager.localizedString("fbucks.earn.perfect.sub"),
                reward: "+1",
                badgeText: localizationManager.localizedString("fbucks.perfect.badge"),
                showBadge: true,
                streakFire: false
            )
            FBucksEarnCard(
                icon: "flame.fill",
                iconColor: .orange,
                title: localizationManager.localizedString("fbucks.earn.streak"),
                subtitle: String(format: localizationManager.localizedString("fbucks.earn.streak.sub"), min(userProfile.streak, 10)),
                reward: userProfile.streak >= 10 ? "✓" : "+1",
                badgeText: "✓",
                showBadge: userProfile.streak >= 10,
                streakFire: true
            )
            FBucksEarnCard(
                icon: "trophy.fill",
                iconColor: .yellow,
                title: localizationManager.localizedString("fbucks.earn.league"),
                subtitle: localizationManager.localizedString("fbucks.earn.league.sub"),
                reward: "+3",
                badgeText: "★",
                showBadge: userProfile.leaguePosition > 0 && userProfile.leaguePosition <= 3,
                streakFire: false
            )
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("fbucks.progress.title"))
                .font(.system(size: 18, weight: .bold))
            if let t = nextTargetItem, userProfile.fBucks < t.price {
                Text(t.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2))
                        Capsule()
                            .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, g.size.width * progressToNext))
                    }
                }
                .frame(height: 12)
                Text(String(format: localizationManager.localizedString("fbucks.progress.percent"), Int(progressToNext * 100)))
                    .font(.caption.weight(.bold))
                    .foregroundColor(.orange)
            } else {
                Text(localizationManager.localizedString("fbucks.progress.full"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(secondaryBG))
    }

    private func wantItemBlock(_ item: ShopItem) -> some View {
        let need = max(0, item.price - userProfile.fBucks)
        return VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("fbucks.want.title"))
                .font(.headline)
            HStack {
                itemIconView(item: item, large: true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 17, weight: .bold))
                    Text(String(format: localizationManager.localizedString("fbucks.want.price"), item.price))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: localizationManager.localizedString("fbucks.want.you"), userProfile.fBucks))
                        .font(.caption)
                    Text(String(format: localizationManager.localizedString("fbucks.want.need"), need))
                        .font(.caption.weight(.bold))
                        .foregroundColor(.orange)
                }
                Spacer()
            }
            Button(action: { selectedTab = 3 }) {
                Text(localizationManager.localizedString("fbucks.earn_more"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [.purple.opacity(0.9), .blue], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(secondaryBG)
                .shadow(color: .purple.opacity(0.2), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: About
    private var aboutTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localizedString("Что такое F-Bucks?"))
                    .font(.system(size: 24, weight: .bold))
                Text(localizationManager.localizedString("F-Bucks (Flags Bucks) — это внутриигровая валюта, которую можно заработать, играя в World Arena Flags. Используйте F-Bucks для покупки уникальных элементов аватара, скинов и других эксклюзивных предметов."))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localizedString("Как заработать F-Bucks"))
                        .font(.system(size: 20, weight: .semibold))
                    EarningMethodCard(icon: "", systemImageName: "target", title: localizationManager.localizedString("Идеальный результат"), description: localizationManager.localizedString("Получите идеальный результат в игре (10/10 или 15/15)"), reward: "+1 F-Bucks")
                    EarningMethodCard(icon: "", systemImageName: "flame.fill", title: localizationManager.localizedString("Серия 10 дней"), description: localizationManager.localizedString("Играйте 10 дней подряд"), reward: "+1 F-Bucks")
                    EarningMethodCard(icon: "", systemImageName: "flame.fill", title: localizationManager.localizedString("Серия 20 дней"), description: localizationManager.localizedString("Играйте 20 дней подряд"), reward: "+2 F-Bucks")
                    EarningMethodCard(icon: "", systemImageName: "flame.fill", title: localizationManager.localizedString("Серия 50 дней"), description: localizationManager.localizedString("Играйте 50 дней подряд"), reward: "+5 F-Bucks")
                    EarningMethodCard(icon: "", systemImageName: "flame.fill", title: localizationManager.localizedString("Серия 100 дней"), description: localizationManager.localizedString("Играйте 100 дней подряд"), reward: "+10 F-Bucks")
                }
            }
            .padding(20)
        }
    }

    // MARK: History
    private var historyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString("История начислений"))
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 8)
                if userProfile.fBucksHistory.isEmpty {
                    emptyHistory
                } else {
                    ForEach(userProfile.fBucksHistory.sorted(by: { $0.date > $1.date })) { transaction in
                        FBucksTransactionRow(transaction: transaction)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(localizationManager.localizedString("История пуста"))
                .font(.headline)
                .foregroundColor(.secondary)
            Text(localizationManager.localizedString("Начните играть и зарабатывать F-Bucks!"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: Shop
    private var shopTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(localizationManager.localizedString("fbucks.shop.title"))
                    .font(.system(size: 24, weight: .bold))
                Text(localizationManager.localizedString("fbucks.shop.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(FBucksShopTier.allCases.sorted(), id: \.rawValue) { tier in
                    let items = allShopItems.filter { $0.tier == tier }
                    if !items.isEmpty {
                        shopTierSection(tier: tier, items: items)
                    }
                }
            }
            .padding(20)
        }
    }

    private func shopTierSection(tier: FBucksShopTier, items: [ShopItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tierColor(tier))
                    .frame(width: 10, height: 10)
                Text(tierTitle(tier))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            ForEach(items) { item in
                FBucksShopItemRow(item: item, tier: tier, onNeedEarn: { selectedTab = 0 })
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(secondaryBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tierColor(tier).opacity(tier == .legendary ? 0.55 : 0.2), lineWidth: tier == .legendary ? 2 : 1)
                )
        )
    }

    private func tierTitle(_ t: FBucksShopTier) -> String {
        switch t {
        case .common: return localizationManager.localizedString("fbucks.shop.tier.common")
        case .rare: return localizationManager.localizedString("fbucks.shop.tier.rare")
        case .legendary: return localizationManager.localizedString("fbucks.shop.tier.legendary")
        }
    }

    private func tierColor(_ t: FBucksShopTier) -> Color {
        switch t {
        case .common: return .green
        case .rare: return .blue
        case .legendary: return .purple
        }
    }

    private func itemIconView(item: ShopItem, large: Bool) -> some View {
        let c = accentColorForIcon(item.systemImageName)
        return Group {
            if let name = item.systemImageName {
                Image(systemName: name)
                    .font(.system(size: large ? 32 : 22, weight: .semibold))
            } else {
                Text(item.icon)
                    .font(.system(size: large ? 34 : 26))
            }
        }
        .foregroundStyle(c)
        .frame(width: large ? 64 : 48, height: large ? 64 : 48)
        .background(c.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Earn card (overview)
private struct FBucksEarnCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let reward: String
    let badgeText: String
    let showBadge: Bool
    let streakFire: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(iconColor)
                if streakFire {
                    Text("🔥")
                        .font(.caption)
                        .offset(x: 18, y: -18)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    if showBadge {
                        Text(badgeText)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                            .foregroundColor(.green)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(reward)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(iconColor)
        }
        .padding(14)
        #if os(iOS)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Shop row
private struct FBucksShopItemRow: View {
    let item: ShopItem
    let tier: FBucksShopTier
    let onNeedEarn: () -> Void
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var canBuy: Bool { userProfile.fBucks >= item.price }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if item.isLimited && tier == .legendary {
                Text(localizationManager.localizedString("fbucks.shop.limited"))
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple.opacity(0.25)))
                    .foregroundColor(.purple)
            }
            HStack(spacing: 12) {
                itemIconSmall
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text(String(format: localizationManager.localizedString("fbucks.want.price"), item.price))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if canBuy {
                    Button(action: { purchase() }) {
                        Text(String(format: localizationManager.localizedString("fbucks.buy_for"), item.price))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(colors: [Color.blue, Color.blue.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onNeedEarn) {
                        Text(localizationManager.localizedString("fbucks.earn_more"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var itemIconSmall: some View {
        let c = accentColorForIcon(item.systemImageName)
        Group {
            if let name = item.systemImageName {
                Image(systemName: name)
                    .font(.system(size: 22, weight: .semibold))
            } else {
                Text(item.icon).font(.system(size: 24))
            }
        }
        .foregroundStyle(c)
        .frame(width: 48, height: 48)
        .background(c.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func purchase() {
        guard userProfile.fBucks >= item.price else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        userProfile.addFBucks(-item.price, reason: .purchase)
    }
}

// MARK: - Transaction row (achievements style)
private struct FBucksTransactionRow: View {
    let transaction: FBucksTransaction
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rowIconBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: rowSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(rowIconColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(transaction.reason.localizedDescription)
                        .font(.system(size: 15, weight: .semibold))
                    if transaction.reason == .perfectGame && transaction.amount > 0 {
                        Text(localizationManager.localizedString("fbucks.perfect.badge"))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                            .foregroundColor(.green)
                    }
                    if isStreakReason(transaction.reason) && transaction.amount > 0 {
                        Text("🔥")
                            .font(.caption)
                    }
                }
                Text(formatDate(transaction.date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(transaction.amount > 0 ? "+\(transaction.amount)" : "\(transaction.amount)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(transaction.amount > 0 ? .green : .red)
        }
        .padding(12)
        #if os(iOS)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var rowSymbol: String {
        switch transaction.reason {
        case .perfectGame: return "checkmark.seal.fill"
        case .streak10, .streak20, .streak50, .streak100: return "flame.fill"
        case .purchase: return "cart.fill"
        case .dailyGift: return "gift.fill"
        case .leagueReward: return "flag.checkered"
        case .registrationBonus: return "person.badge.plus"
        case .birthday, .birthdayGiftFromFriend: return "birthday.cake.fill"
        case .dailyFBucksClaim: return "gift.circle.fill"
        case .streakRestore: return "arrow.uturn.backward.circle.fill"
        }
    }

    private var rowIconColor: Color {
        switch transaction.reason {
        case .perfectGame: return .green
        case .streak10, .streak20, .streak50, .streak100: return .orange
        case .purchase: return .red
        case .dailyFBucksClaim: return .orange
        default: return .blue
        }
    }

    private var rowIconBackground: Color { rowIconColor.opacity(0.15) }

    private func isStreakReason(_ r: FBucksTransaction.FBucksReason) -> Bool {
        switch r {
        case .streak10, .streak20, .streak50, .streak100: return true
        default: return false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private func accentColorForIcon(_ systemImageName: String?) -> Color {
    guard let name = systemImageName else { return .blue }
    switch name {
    case "target": return Color.blue
    case "flame.fill": return Color.orange
    case "diamond.fill": return Color(red: 0.4, green: 0.6, blue: 1.0)
    case "paintbrush.fill": return Color.pink
    case "tshirt.fill": return Color.green
    case "sparkles": return Color(red: 1.0, green: 0.75, blue: 0.2)
    case "light.max": return Color.cyan
    case "star.fill": return Color.yellow
    case "cap.fill", "jacket.closed.fill": return Color.mint
    case "paintbrush.pointed.fill": return Color.purple
    case "crown.fill": return Color.yellow
    case "shoeprints.fill": return Color.brown
    default: return Color.blue
    }
}

struct FeatureRow: View {
    let icon: String
    var systemImageName: String? = nil
    let text: String

    private var iconColor: Color { accentColorForIcon(systemImageName) }

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let name = systemImageName {
                    Image(systemName: name)
                        .font(.system(size: 22, weight: .semibold))
                } else {
                    Text(icon)
                        .font(.system(size: 22))
                }
            }
            .foregroundStyle(iconColor)
            .frame(width: 44, height: 44)
            .background(iconColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(text)
                .font(.system(size: 16, weight: .medium))
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

struct EarningMethodCard: View {
    let icon: String
    var systemImageName: String? = nil
    let title: String
    let description: String
    let reward: String

    private var iconColor: Color { accentColorForIcon(systemImageName) }

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let name = systemImageName {
                    Image(systemName: name)
                        .font(.system(size: 26, weight: .semibold))
                } else {
                    Text(icon)
                        .font(.system(size: 32))
                }
            }
            .foregroundStyle(iconColor)
            .frame(width: 56, height: 56)
            .background(
                LinearGradient(
                    colors: [iconColor.opacity(0.25), iconColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(iconColor.opacity(0.4), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(reward)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(iconColor)
        }
        .padding(16)
        #if os(iOS)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .cornerRadius(14)
    }
}

#Preview {
    FBucksInfoView()
}
