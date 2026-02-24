import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct InterestingFactsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var safeTopInset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: Color.appGradientColors(for: themeManager.colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Закреплённая шапка
                headerBackground
                
                // Основной контент
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(interestingFacts.enumerated()), id: \.offset) { index, fact in
                            FactDetailCard(fact: fact, number: index + 1)
                        }
                    }
                    .padding(.horizontal, 20)
                                            .padding(.top, 20) // Убрали лишние отступы, оставили минимальный
                    .padding(.bottom, 100)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.background)
                        .ignoresSafeArea(.container, edges: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .background(GeometryReader { geometry in
            Color.clear
                .preference(key: SafeTopInsetKey.self, value: geometry.safeAreaInsets.top)
        })
        .onPreferenceChange(SafeTopInsetKey.self) { value in
            safeTopInset = value
        }
    }
    
    // MARK: - Header
    private var headerBackground: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: headerHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .ignoresSafeArea(.container, edges: .top)
            
            // Заголовок
            VStack(spacing: 8) {
                Spacer()
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(localizationManager.localizedString("Интересные факты"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Text("🌟")
                    .font(.system(size: 40))
                
                Text("\(interestingFacts.count) \(localizationManager.localizedString("фактов о флагах и странах"))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .frame(height: headerHeight)
        }
    }
    
    private var headerHeight: CGFloat { 240 + safeTopInset } // Увеличили высоту для полного перекрытия текста
    
    private var contentTopInset: CGFloat {
        max(0, headerHeight - 40)
    }
}

// MARK: - FactDetailCard
struct FactDetailCard: View {
    let fact: InterestingFact
    let number: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                Spacer()
                
                Text(fact.emoji)
                    .font(.system(size: 30))
            }
            
            Text(localizationManager.localizedString(fact.title))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(localizationManager.localizedString(fact.description))
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - InterestingFact Model
struct InterestingFact {
    let title: String
    let description: String
    let emoji: String
}

// MARK: - Facts Data
private let interestingFacts: [InterestingFact] = [
    InterestingFact(
        title: "Самый старый флаг",
        description: "Флаг Дании (Данеброг) считается самым старым государственным флагом в мире, который используется непрерывно с 1219 года.",
        emoji: "🇩🇰"
    ),
    InterestingFact(
        title: "Единственный квадратный флаг",
        description: "Швейцария имеет единственный квадратный национальный флаг в мире. Ватикан также имеет квадратный флаг, но это город-государство.",
        emoji: "🇨🇭"
    ),
    InterestingFact(
        title: "Самый сложный флаг",
        description: "Флаг Бутана изображает дракона Друк, держащего драгоценности в лапах, что символизирует богатство и безопасность страны.",
        emoji: "🇧🇹"
    ),
    InterestingFact(
        title: "Флаг без красного, белого или синего",
        description: "Ямайка - единственная страна в мире, чей флаг не содержит красного, белого или синего цвета. Он состоит из зеленого, желтого и черного.",
        emoji: "🇯🇲"
    ),
    InterestingFact(
        title: "Флаг, который меняется",
        description: "У Саудовской Аравии флаг никогда не приспускается до половины мачты, так как на нем написано священное исламское изречение.",
        emoji: "🇸🇦"
    ),
    InterestingFact(
        title: "Самый молодой флаг",
        description: "Флаг Южного Судана был принят в 2011 году, когда страна обрела независимость, что делает его самым молодым национальным флагом.",
        emoji: "🇸🇸"
    ),
    InterestingFact(
        title: "Флаг с AK-47",
        description: "Мозамбик - единственная страна в мире, на флаге которой изображено современное оружие - автомат Калашникова.",
        emoji: "🇲🇿"
    ),
    InterestingFact(
        title: "Одинаковые флаги",
        description: "Румыния и Чад имеют практически идентичные флаги. Различие только в оттенке синего цвета, который у Чада немного темнее.",
        emoji: "🇷🇴"
    ),
    InterestingFact(
        title: "Флаг-палиндром",
        description: "Флаг Украины читается одинаково сверху и снизу - это синяя полоса над желтой, символизирующая небо над пшеничным полем.",
        emoji: "🇺🇦"
    ),
    InterestingFact(
        title: "Самый простой флаг",
        description: "Флаг Ливии с 1977 по 2011 год состоял только из зеленого цвета без каких-либо символов или узоров.",
        emoji: "🏳️"
    ),
    InterestingFact(
        title: "Флаг с картой",
        description: "Кипр - одна из двух стран (вместе с Косово), на флаге которой изображена карта самой страны.",
        emoji: "🇨🇾"
    ),
    InterestingFact(
        title: "Флаг с Библией",
        description: "На флаге Доминиканской Республики изображена открытая Библия, что делает его единственным национальным флагом с религиозной книгой.",
        emoji: "🇩🇴"
    ),
    InterestingFact(
        title: "Самый популярный цвет",
        description: "Красный цвет присутствует на 75% всех национальных флагов мира, что делает его самым популярным цветом флагов.",
        emoji: "🔴"
    ),
    InterestingFact(
        title: "Флаг с надписью",
        description: "Саудовская Аравия - одна из немногих стран, на флаге которой есть текст. Надпись сделана на арабском языке.",
        emoji: "🇸🇦"
    ),
    InterestingFact(
        title: "Флаг, который нельзя носить",
        description: "В Таиланде незаконно носить одежду с изображением национального флага, так как это считается неуважением к королевской семье.",
        emoji: "🇹🇭"
    ),
    InterestingFact(
        title: "Флаг с разными сторонами",
        description: "Парагвай имеет единственный в мире национальный флаг с разными изображениями на лицевой и обратной сторонах.",
        emoji: "🇵🇾"
    ),
    InterestingFact(
        title: "Самый большой флаг",
        description: "Самый большой флаг в мире находится в Иордании. Его размеры составляют 60 на 30 метров, а вес - около 3 тонн.",
        emoji: "🇯🇴"
    ),
    InterestingFact(
        title: "Флаг с изменяющимся дизайном",
        description: "Флаг Непала - единственный в мире национальный флаг, который не является прямоугольным. Он состоит из двух треугольников.",
        emoji: "🇳🇵"
    ),
    InterestingFact(
        title: "Флаг Олимпиады",
        description: "Пять олимпийских колец на флаге Олимпийских игр представляют пять континентов, а их цвета присутствуют на всех флагах мира.",
        emoji: "🏅"
    ),
    InterestingFact(
        title: "Флаг с самым сложным гербом",
        description: "На флаге Мексики изображен орел, сидящий на кактусе и держащий в клюве змею - один из самых детализированных гербов на флагах.",
        emoji: "🇲🇽"
    ),
    InterestingFact(
        title: "Флаг-копия",
        description: "Флаг Монако и Индонезии почти идентичны - красная полоса сверху, белая снизу. Различие только в пропорциях.",
        emoji: "🇲🇨"
    ),
    InterestingFact(
        title: "Флаг с 50 звездами",
        description: "На флаге США 50 звезд, по одной на каждый штат. Дизайн флага менялся 27 раз с момента принятия в 1777 году.",
        emoji: "🇺🇸"
    ),
    InterestingFact(
        title: "Самый северный флаг",
        description: "Флаг Гренландии развевается в самой северной точке земли среди всех национальных и региональных флагов.",
        emoji: "🇬🇱"
    ),
    InterestingFact(
        title: "Флаг с крестом",
        description: "29 стран мира имеют крест на своем флаге, что делает его одним из самых популярных символов на национальных флагах.",
        emoji: "✝️"
    ),
    InterestingFact(
        title: "Флаг без изображений",
        description: "Нидерланды имеют один из самых простых флагов - три горизонтальные полосы: красная, белая и синяя, без каких-либо символов.",
        emoji: "🇳🇱"
    ),
    InterestingFact(
        title: "Флаг с полумесяцем",
        description: "Полумесяц присутствует на флагах 12 стран, в основном мусульманских, символизируя исламскую веру.",
        emoji: "☪️"
    ),
    InterestingFact(
        title: "Самый яркий флаг",
        description: "Флаг Бангладеш считается одним из самых ярких в мире - красный круг на зеленом фоне символизирует восходящее солнце.",
        emoji: "🇧🇩"
    ),
    InterestingFact(
        title: "Флаг с деревом",
        description: "Ливан - единственная страна, на флаге которой изображено дерево (ливанский кедр), символизирующее вечность и мир.",
        emoji: "🇱🇧"
    ),
    InterestingFact(
        title: "Флаг с солнцем",
        description: "На флагах 23 стран мира изображено солнце в различных формах - от простых кругов до сложных лучистых символов.",
        emoji: "☀️"
    ),
    InterestingFact(
        title: "Самый узкий флаг",
        description: "Флаг Катара имеет самое необычное соотношение сторон среди всех национальных флагов - 11:28.",
        emoji: "🇶🇦"
    ),
    InterestingFact(
        title: "Флаг с щитом",
        description: "Эквадор имеет один из самых детализированных гербов на флаге, включающий кондора, щит и множество других символов.",
        emoji: "🇪🇨"
    ),
    InterestingFact(
        title: "Флаг-радуга",
        description: "Боливия имеет два официальных флага - традиционный трехцветный и радужный флаг коренных народов Випала.",
        emoji: "🇧🇴"
    ),
    InterestingFact(
        title: "Флаг с королевским символом",
        description: "На флаге Камбоджи изображен храм Ангкор-Ват, что делает его единственным национальным флагом со зданием.",
        emoji: "🇰🇭"
    ),
    InterestingFact(
        title: "Самый спорный флаг",
        description: "Флаг Македонии был изменен в 1995 году из-за протестов Греции, которая считала первоначальный дизайн своим историческим символом.",
        emoji: "🇲🇰"
    ),
    InterestingFact(
        title: "Флаг с мечом",
        description: "На флаге Шри-Ланки изображен лев, держащий меч, что символизирует храбрость сингальского народа.",
        emoji: "🇱🇰"
    ),
    InterestingFact(
        title: "Флаг без синего",
        description: "Только 4 страны в мире не используют синий цвет на своих флагах: Ямайка, Мавритания, Шри-Ланка и Ватикан.",
        emoji: "🌈"
    ),
    InterestingFact(
        title: "Флаг с птицей",
        description: "На флагах 25 стран мира изображены птицы - от простых силуэтов до детализированных изображений орлов и других птиц.",
        emoji: "🦅"
    ),
    InterestingFact(
        title: "Самый мирный флаг",
        description: "Флаг Антарктиды неофициально представляет континент мира и науки - белый континент на синем фоне.",
        emoji: "🇦🇶"
    ),
    InterestingFact(
        title: "Флаг с звездой",
        description: "196 стран и территорий имеют звезды на своих флагах, что делает звезду самым популярным символом после креста.",
        emoji: "⭐"
    ),
    InterestingFact(
        title: "Флаг-близнец",
        description: "Сингапур и Польша имеют флаги с одинаковыми цветами (красный и белый), но расположенными в обратном порядке.",
        emoji: "🇸🇬"
    ),
    InterestingFact(
        title: "Самый молодой континентальный флаг",
        description: "Флаг Африканского союза был принят в 2010 году и включает карту Африки на зеленом фоне с золотыми звездами.",
        emoji: "🌍"
    ),
    InterestingFact(
        title: "Флаг с алмазом",
        description: "На флаге Ботсваны изображена черная полоса, символизирующая единство народов, окруженная белыми полосами мира.",
        emoji: "🇧🇼"
    ),
    InterestingFact(
        title: "Флаг морского дна",
        description: "Науру - самая маленькая островная нация в мире, и ее флаг символизирует остров (желтая полоса) в океане (синий фон).",
        emoji: "🇳🇷"
    ),
    InterestingFact(
        title: "Флаг с самой длинной историей изменений",
        description: "Флаг США изменялся 27 раз с 1777 года, каждый раз при присоединении нового штата добавлялась новая звезда.",
        emoji: "🇺🇸"
    ),
    InterestingFact(
        title: "Флаг пустыни",
        description: "Флаг Нигера символизирует пустыню Сахара (оранжевая полоса сверху) и реку Нигер (синяя полоса снизу).",
        emoji: "🇳🇪"
    ),
    InterestingFact(
        title: "Самый космический флаг",
        description: "Флаг Малайзии имеет 14 полос и полумесяц со звездой, символизирующие единство 13 штатов и федерального правительства.",
        emoji: "🇲🇾"
    ),
    InterestingFact(
        title: "Флаг вулкана",
        description: "На флаге Никарагуа изображены два океана и вулканы, что отражает географическое положение страны между Тихим и Атлантическим океанами.",
        emoji: "🇳🇮"
    ),
    InterestingFact(
        title: "Флаг-загадка",
        description: "Флаг Бутана можно интерпретировать по-разному в зависимости от того, как его повесить - дракон может смотреть в разные стороны.",
        emoji: "🇧🇹"
    )
]

// MARK: - SafeTopInsetKey
private struct SafeTopInsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    InterestingFactsView()
}
