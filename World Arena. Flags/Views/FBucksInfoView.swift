import SwiftUI

struct FBucksInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок с F-bucks chip
                VStack(spacing: 16) {
                    FBucksChipView(count: userProfile.fBucks, size: .regular)
                    Text(localizationManager.localizedString("F-Bucks"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(localizationManager.localizedString("Flags Bucks"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Табы
                Picker("", selection: $selectedTab) {
                    Text(localizationManager.localizedString("О F-Bucks")).tag(0)
                    Text(localizationManager.localizedString("Как заработать")).tag(1)
                    Text(localizationManager.localizedString("История")).tag(2)
                    Text(localizationManager.localizedString("Магазин")).tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Контент табов
                TabView(selection: $selectedTab) {
                    aboutTab.tag(0)
                    howToEarnTab.tag(1)
                    historyTab.tag(2)
                    shopTab.tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString("Закрыть")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - About Tab
    private var aboutTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localizedString("Что такое F-Bucks?"))
                    .font(.system(size: 24, weight: .bold))
                
                Text(localizationManager.localizedString("F-Bucks (Flags Bucks) — это внутриигровая валюта, которую можно заработать, играя в World Arena Flags. Используйте F-Bucks для покупки уникальных элементов аватара, скинов и других эксклюзивных предметов."))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localizedString("Особенности:"))
                        .font(.system(size: 20, weight: .semibold))
                    
                    FeatureRow(icon: "🎯", text: localizationManager.localizedString("Зарабатывайте за идеальные результаты в играх"))
                    FeatureRow(icon: "🔥", text: localizationManager.localizedString("Получайте бонусы за длинные серии дней"))
                    FeatureRow(icon: "💎", text: localizationManager.localizedString("Покупайте эксклюзивные элементы для аватара"))
                    FeatureRow(icon: "🎨", text: localizationManager.localizedString("Создавайте уникальный стиль"))
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - How to Earn Tab
    private var howToEarnTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localizedString("Как заработать F-Bucks"))
                    .font(.system(size: 24, weight: .bold))
                
                VStack(spacing: 16) {
                    EarningMethodCard(
                        icon: "🎯",
                        title: localizationManager.localizedString("Идеальный результат"),
                        description: localizationManager.localizedString("Получите идеальный результат в игре (10/10 или 15/15)"),
                        reward: "+1 F-Bucks"
                    )
                    
                    EarningMethodCard(
                        icon: "🔥",
                        title: localizationManager.localizedString("Серия 10 дней"),
                        description: localizationManager.localizedString("Играйте 10 дней подряд"),
                        reward: "+1 F-Bucks"
                    )
                    
                    EarningMethodCard(
                        icon: "🔥",
                        title: localizationManager.localizedString("Серия 20 дней"),
                        description: localizationManager.localizedString("Играйте 20 дней подряд"),
                        reward: "+2 F-Bucks"
                    )
                    
                    EarningMethodCard(
                        icon: "🔥",
                        title: localizationManager.localizedString("Серия 50 дней"),
                        description: localizationManager.localizedString("Играйте 50 дней подряд"),
                        reward: "+5 F-Bucks"
                    )
                    
                    EarningMethodCard(
                        icon: "🔥",
                        title: localizationManager.localizedString("Серия 100 дней"),
                        description: localizationManager.localizedString("Играйте 100 дней подряд"),
                        reward: "+10 F-Bucks"
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - History Tab
    private var historyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString("История начислений"))
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if userProfile.fBucksHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(localizationManager.localizedString("История пуста"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(localizationManager.localizedString("Начните играть и зарабатывать F-Bucks!"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(userProfile.fBucksHistory.sorted(by: { $0.date > $1.date })) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Shop Tab
    private var shopTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localizedString("Магазин F-Bucks"))
                    .font(.system(size: 24, weight: .bold))
                
                Text(localizationManager.localizedString("Потратьте F-Bucks на эксклюзивные элементы для вашего аватара"))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                // Категории товаров
                VStack(spacing: 16) {
                    ShopCategoryCard(
                        icon: "👕",
                        title: localizationManager.localizedString("Одежда"),
                        description: localizationManager.localizedString("Уникальные наряды и аксессуары"),
                        items: shopClothingItems
                    )
                    
                    ShopCategoryCard(
                        icon: "🎨",
                        title: localizationManager.localizedString("Скины"),
                        description: localizationManager.localizedString("Особые визуальные эффекты"),
                        items: shopSkinItems
                    )
                    
                    ShopCategoryCard(
                        icon: "✨",
                        title: localizationManager.localizedString("Эффекты"),
                        description: localizationManager.localizedString("Анимации и спецэффекты"),
                        items: shopEffectItems
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Shop Items (заглушки, позже из API/бэкенда)
    private var shopClothingItems: [ShopItem] {
        [
            ShopItem(id: "shirt_1", name: localizationManager.localizedString("Футболка чемпиона"), price: 5, icon: "👕"),
            ShopItem(id: "hat_1", name: localizationManager.localizedString("Кепка путешественника"), price: 3, icon: "🧢"),
            ShopItem(id: "jacket_1", name: localizationManager.localizedString("Куртка исследователя"), price: 10, icon: "🧥")
        ]
    }
    
    private var shopSkinItems: [ShopItem] {
        [
            ShopItem(id: "skin_gold", name: localizationManager.localizedString("Золотой скин"), price: 20, icon: "✨"),
            ShopItem(id: "skin_rainbow", name: localizationManager.localizedString("Радужный скин"), price: 15, icon: "🌈"),
            ShopItem(id: "skin_neon", name: localizationManager.localizedString("Неоновый скин"), price: 25, icon: "💫")
        ]
    }
    
    private var shopEffectItems: [ShopItem] {
        [
            ShopItem(id: "effect_sparkles", name: localizationManager.localizedString("Эффект блёсток"), price: 8, icon: "✨"),
            ShopItem(id: "effect_fire", name: localizationManager.localizedString("Огненный эффект"), price: 12, icon: "🔥"),
            ShopItem(id: "effect_stars", name: localizationManager.localizedString("Звёздный эффект"), price: 10, icon: "⭐")
        ]
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
            Text(text)
                .font(.system(size: 16))
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct EarningMethodCard: View {
    let icon: String
    let title: String
    let description: String
    let reward: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(reward)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let transaction: FBucksTransaction
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.reason.localizedDescription)
                    .font(.system(size: 16, weight: .medium))
                Text(formatDate(transaction.date))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.amount > 0 ? "+\(transaction.amount)" : "\(transaction.amount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(transaction.amount > 0 ? .green : .red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ShopCategoryCard: View {
    let icon: String
    let title: String
    let description: String
    let items: [ShopItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(icon)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            ForEach(items) { item in
                ShopItemRow(item: item)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let price: Int
    let icon: String
}

struct ShopItemRow: View {
    let item: ShopItem
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack {
            Text(item.icon)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                Text("\(item.price) F-Bucks")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                purchaseItem(item)
            }) {
                Text(localizationManager.localizedString("Купить"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(userProfile.fBucks >= item.price ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(userProfile.fBucks < item.price)
        }
        .padding(.vertical, 8)
    }
    
    private func purchaseItem(_ item: ShopItem) {
        guard userProfile.fBucks >= item.price else { return }
        // TODO: Реализовать покупку и применение предмета к аватару
        userProfile.addFBucks(-item.price, reason: .purchase)
    }
}

#Preview {
    FBucksInfoView()
}
