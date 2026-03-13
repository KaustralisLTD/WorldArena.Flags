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
            content: "HELP_GAME_RULES",
            category: "Игра"
        ),
        HelpTopic(
            title: "Что такое серия дней?",
            subtitle: "Как работает система серий",
            content: "HELP_STREAK_TEXT",
            category: "Прогресс"
        ),
        HelpTopic(
            title: "Как работают лиги?",
            subtitle: "Система рейтингов и соревнований",
            content: "HELP_LEAGUES_TEXT",
            category: "Лиги"
        )
    ]
    
    static let allTopics: [HelpTopic] = popularTopics + [
        HelpTopic(
            title: "Как изменить аватар?",
            subtitle: "Персонализация профиля",
            content: "HELP_PROFILE_AVATAR",
            category: "Профиль"
        ),
        HelpTopic(
            title: "Как работает создание скина?",
            subtitle: "Редактор аватара и элементы",
            content: "HELP_PROFILE_SKIN_EDITOR",
            category: "Профиль"
        ),
        HelpTopic(
            title: "Как добавить друзей?",
            subtitle: "Социальные функции",
            content: "HELP_SOCIAL_ADD_FRIENDS",
            category: "Социальные функции"
        ),
        HelpTopic(
            title: "Как работают напоминания друзьям?",
            subtitle: "Пуш-уведомления о ежедневном уроке",
            content: "HELP_SOCIAL_REMINDERS",
            category: "Социальные функции"
        ),
        HelpTopic(
            title: "Что такое дуэль и как её начать?",
            subtitle: "Режим соревнований 1 на 1",
            content: "HELP_GAME_DUEL",
            category: "Игра"
        ),
        HelpTopic(
            title: "Как зарабатывать и тратить F-bucks?",
            subtitle: "Внутриигровая валюта",
            content: "HELP_PROGRESS_FBUCKS",
            category: "Прогресс"
        ),
        HelpTopic(
            title: "Как работают квесты и достижения?",
            subtitle: "Месячные задания и артефакты",
            content: "HELP_PROGRESS_QUESTS",
            category: "Прогресс"
        ),
        HelpTopic(
            title: "Уведомления: какие бывают и как их настроить?",
            subtitle: "Ежедневный урок, дуэли и напоминания",
            content: "HELP_NOTIFICATIONS_TYPES",
            category: "Технические вопросы"
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
                    content: "HELP_TECH_FLAGS_NOT_LOADING",
                    category: "Технические вопросы"
                ),
                HelpTopic(
                    title: "Синхронизация данных",
                    subtitle: "Как сохранить прогресс",
                    content: "HELP_TECH_DATA_SYNC",
                    category: "Технические вопросы"
                )
            ]
        )
    ]
}

#Preview {
    HelpCenterView()
}
