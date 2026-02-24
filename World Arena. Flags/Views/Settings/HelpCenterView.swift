import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct HelpCenterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                    
                    // Popular topics
                    if searchText.isEmpty {
                        popularTopicsSection
                        
                        // Categories
                        categoriesSection
                        
                        // Contact support
                        contactSupportSection
                    } else {
                        searchResultsSection
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Центр помощи"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Закрыть")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(LocalizationManager.shared.localizedString("Закрыть")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
        }
        .sheet(item: $selectedCategory) { category in
            HelpCategoryDetailView(category: category)
        }
    }
    
    private var popularTopicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("Популярные темы"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 12) {
                ForEach(HelpTopic.popularTopics, id: \.id) { topic in
                    HelpTopicRow(topic: topic)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("Категории"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(HelpCategory.allCategories, id: \.id) { category in
                    HelpCategoryCard(category: category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var contactSupportSection: some View {
        VStack(spacing: 16) {
            Text(LocalizationManager.shared.localizedString("Нужна дополнительная помощь?"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Button(action: {
                contactSupport()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                    
                    Text(LocalizationManager.shared.localizedString("Связаться с поддержкой"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("Результаты поиска"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            let filteredTopics = HelpTopic.allTopics.filter { topic in
                topic.title.localizedCaseInsensitiveContains(searchText) ||
                topic.content.localizedCaseInsensitiveContains(searchText)
            }
            
            if filteredTopics.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(LocalizationManager.shared.localizedString("Ничего не найдено"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localizedString("Попробуйте другие ключевые слова"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTopics, id: \.id) { topic in
                        HelpTopicRow(topic: topic)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func contactSupport() {
        let subjectRaw = LocalizationManager.shared.localizedString("Поддержка World Arena Flags")
        let subject = subjectRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subjectRaw
        if let url = URL(string: "mailto:support@worldarena.games?subject=\(subject)") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizationManager.shared.localizedString("Поиск в справке..."), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

struct HelpTopicRow: View {
    let topic: HelpTopic
    @State private var isExpanded = false
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString(topic.title))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if !isExpanded && !topic.subtitle.isEmpty {
                            Text(LocalizationManager.shared.localizedString(topic.subtitle))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    Text(LocalizationManager.shared.localizedString(topic.content))
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

struct HelpCategoryCard: View {
    let category: HelpCategory
    let action: () -> Void
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
            Text(LocalizationManager.shared.localizedString(category.name))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(String(format: LocalizationManager.shared.localizedString("%d тем"), category.topicsCount))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(secondarySystemGroupedBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HelpCategoryDetailView: View {
    let category: HelpCategory
    @Environment(\.presentationMode) var presentationMode
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(category.topics, id: \.id) { topic in
                        HelpTopicRow(topic: topic)
                    }
                }
                .padding(20)
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString(category.name))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
        }
    }
}

// MARK: - Data Models

struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let content: String
    let category: String
    
    static let popularTopics: [HelpTopic] = [
        HelpTopic(
            title: "Как играть в World Arena Flags?",
            subtitle: "Основы игры и правила",
            content: """
            World Arena Flags - это увлекательная игра для изучения флагов стран мира!
            
            Правила игры:
            1. Вам показывается флаг страны
            2. Выберите правильное название из предложенных вариантов
            3. Зарабатывайте очки опыта за правильные ответы
            4. Поддерживайте серию правильных ответов
            5. Повышайте свой уровень и лигу
            
            Чем больше вы играете, тем больше флагов изучите!
            """,
            category: "Игра"
        ),
        HelpTopic(
            title: "Что такое серия дней?",
            subtitle: "Как работает система серий",
            content: """
            Серия дней показывает, сколько дней подряд вы играли в World Arena Flags.
            
            Как поддерживать серию:
            • Играйте хотя бы в одну игру каждый день
            • Серия сбрасывается, если вы пропустите день
            • Чем длиннее серия, тем больше бонусных очков вы получаете
            
            Серия помогает формировать привычку регулярного обучения!
            """,
            category: "Прогресс"
        ),
        HelpTopic(
            title: "Как работают лиги?",
            subtitle: "Система рейтингов и соревнований",
            content: """
            Лиги - это система соревнований с другими игроками.
            
            Виды лиг (от низшей к высшей):
            • Бронзовая лига
            • Серебряная лига  
            • Золотая лига
            • Платиновая лига
            • Алмазная лига
            • Лига Мастеров
            
            Каждую неделю лиги обновляются:
            • Топ-3 игрока получают награды
            • Игроки на местах 16-20 могут быть понижены
            • Остальные остаются в той же лиге
            """,
            category: "Лиги"
        )
    ]
    
    static let allTopics: [HelpTopic] = popularTopics + [
        HelpTopic(
            title: "Как изменить аватар?",
            subtitle: "Персонализация профиля",
            content: """
            Чтобы изменить аватар:
            1. Перейдите в раздел "Профиль"
            2. Нажмите на шестеренку (настройки)
            3. Выберите "Профиль пользователя"
            4. Выберите новый аватар из доступных вариантов
            5. Нажмите "Сохранить"
            """,
            category: "Профиль"
        ),
        HelpTopic(
            title: "Как добавить друзей?",
            subtitle: "Социальные функции",
            content: """
            Добавление друзей:
            1. Перейдите в раздел "Профиль"
            2. Нажмите "Добавить друзей"
            3. Поделитесь своим кодом друга или введите код другого игрока
            4. Отправьте заявку в друзья
            
            С друзьями вы можете:
            • Сравнивать статистику
            • Видеть их прогресс
            • Соревноваться в лигах
            """,
            category: "Социальные функции"
        )
    ]
}

struct HelpCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let topics: [HelpTopic]
    
    var topicsCount: Int { topics.count }
    
    static let allCategories: [HelpCategory] = [
        HelpCategory(
            name: "Игра",
            icon: "gamecontroller",
            topics: HelpTopic.allTopics.filter { $0.category == "Игра" }
        ),
        HelpCategory(
            name: "Прогресс",
            icon: "chart.line.uptrend.xyaxis",
            topics: HelpTopic.allTopics.filter { $0.category == "Прогресс" }
        ),
        HelpCategory(
            name: "Лиги",
            icon: "trophy",
            topics: HelpTopic.allTopics.filter { $0.category == "Лиги" }
        ),
        HelpCategory(
            name: "Профиль",
            icon: "person.circle",
            topics: HelpTopic.allTopics.filter { $0.category == "Профиль" }
        ),
        HelpCategory(
            name: "Социальные функции",
            icon: "person.2",
            topics: HelpTopic.allTopics.filter { $0.category == "Социальные функции" }
        ),
        HelpCategory(
            name: "Технические вопросы",
            icon: "gear",
            topics: [
                HelpTopic(
                    title: "Проблемы с загрузкой флагов",
                    subtitle: "Что делать если флаги не загружаются",
                    content: """
                    Если флаги не загружаются:
                    1. Проверьте подключение к интернету
                    2. Перезапустите приложение
                    3. Очистите кеш в настройках
                    4. Обратитесь в поддержку, если проблема не решилась
                    """,
                    category: "Технические вопросы"
                ),
                HelpTopic(
                    title: "Синхронизация данных",
                    subtitle: "Как сохранить прогресс",
                    content: """
                    Ваш прогресс автоматически сохраняется на устройстве.
                    
                    Для резервного копирования:
                    • Используйте iCloud для автоматического резервного копирования
                    • Экспортируйте данные через настройки приватности
                    • Регулярно делайте резервные копии устройства
                    """,
                    category: "Технические вопросы"
                )
            ]
        )
    ]
}

#Preview {
    HelpCenterView()
}
