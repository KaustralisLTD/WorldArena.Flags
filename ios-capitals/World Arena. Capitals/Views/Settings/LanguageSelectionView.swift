import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct LanguageSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
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
                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(LocalizationManager.shared.localizedString("Выберите язык игры"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizationManager.shared.localizedString("Язык интерфейса игры и заданий"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    
                    // Languages list
                    VStack(spacing: 1) {
                        ForEach(GameState.Language.allCases, id: \.self) { language in
                            LanguageRow(
                                language: language,
                                isSelected: gameState.selectedLanguage == language
                            ) {
                                selectLanguage(language)
                            }
                        }
                    }
                    .background(secondarySystemGroupedBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100)
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Язык игры"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(LocalizationManager.shared.localizedString("Готово")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
                #endif
            }
        }
    }
    
    private func selectLanguage(_ language: GameState.Language) {
        Task {
            await gameState.setLanguage(language)
        }
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
}

struct LanguageRow: View {
    let language: GameState.Language
    let isSelected: Bool
    let action: () -> Void
    
    private static let flagSize = CGSize(width: 40, height: 28)
    
    private func flagURL() -> URL? {
        // Качественные PNG-флаги (единый формат) — вместо emoji.
        // Берём небольшие, но чёткие (w80) и подгоняем в 40×28.
        let code: String?
        switch language {
        case .system:
            code = nil
        case .english:
            code = "us"
        case .russian:
            code = "ru"
        case .spanish:
            code = "es"
        case .ukrainian:
            code = "ua"
        case .catalan:
            code = nil // кастомная senyera ниже
        case .chinese:
            code = "cn"
        case .german:
            code = "de"
        case .french:
            code = "fr"
        case .italian:
            code = "it"
        case .portugueseBrazil:
            code = "br"
        case .polish:
            code = "pl"
        case .dutch:
            code = "nl"
        case .hindi:
            code = "in"
        case .czech:
            code = "cz"
        case .swedish:
            code = "se"
        case .japanese:
            code = "jp"
        case .arabic:
            code = "sa"
        case .bengali:
            code = "bd"
        case .hungarian:
            code = "hu"
        case .vietnamese:
            code = "vn"
        case .greek:
            code = "gr"
        case .indonesian:
            code = "id"
        case .korean:
            code = "kr"
        case .romanian:
            code = "ro"
        case .thai:
            code = "th"
        case .tamil, .telugu:
            code = "in"
        case .chineseTraditional:
            code = "tw"
        case .turkish:
            code = "tr"
        case .filipino:
            code = "ph"
        }
        guard let code else { return nil }
        return URL(string: "https://flagcdn.com/w80/\(code).png")
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Language flag/icon (Catalan: custom senyera, others: emoji)
                ZStack {
                    if language == .system {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.gray.opacity(0.14))
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    } else if language == .catalan {
                        CatalanFlagView()
                    } else if let url = flagURL() {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.gray.opacity(0.12))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.gray.opacity(0.12))
                    }
                }
                .frame(width: Self.flagSize.width, height: Self.flagSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                
                // Language name
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if language != .system {
                        Text(nativeName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(secondarySystemGroupedBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var languageFlag: String {
        switch language {
        case .system: return "⚙️"
        case .english: return "🇺🇸"
        case .russian: return "🇷🇺"
        case .spanish: return "🇪🇸"
        case .ukrainian: return "🇺🇦"
        case .catalan: return "🏴󠁥󠁳󠁣󠁴󠁿"
        case .chinese: return "🇨🇳"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        case .portugueseBrazil: return "🇧🇷"
        case .polish: return "🇵🇱"
        case .dutch: return "🇳🇱"
        case .hindi: return "🇮🇳"
        case .czech: return "🇨🇿"
        case .swedish: return "🇸🇪"
        case .japanese: return "🇯🇵"
        case .arabic: return "🇸🇦"
        case .bengali: return "🇧🇩"
        case .hungarian: return "🇭🇺"
        case .vietnamese: return "🇻🇳"
        case .greek: return "🇬🇷"
        case .indonesian: return "🇮🇩"
        case .korean: return "🇰🇷"
        case .romanian: return "🇷🇴"
        case .thai: return "🇹🇭"
        case .tamil: return "🇮🇳"
        case .telugu: return "🇮🇳"
        case .chineseTraditional: return "🇹🇼"
        case .turkish: return "🇹🇷"
        case .filipino: return "🇵🇭"
        }
    }
    
    private var nativeName: String {
        switch language {
        case .system: return ""
        case .english: return "English"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .ukrainian: return "Українська"
        case .catalan: return "Català"
        case .chinese: return "中文"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .portugueseBrazil: return "Português (Brasil)"
        case .polish: return "Polski"
        case .dutch: return "Nederlands"
        case .hindi: return "हिन्दी"
        case .czech: return "Čeština"
        case .swedish: return "Svenska"
        case .japanese: return "日本語"
        case .arabic: return "العربية"
        case .bengali: return "বাংলা"
        case .hungarian: return "Magyar"
        case .vietnamese: return "Tiếng Việt"
        case .greek: return "Ελληνικά"
        case .indonesian: return "Bahasa Indonesia"
        case .korean: return "한국어"
        case .romanian: return "Română"
        case .thai: return "ไทย"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .chineseTraditional: return "繁體中文"
        case .turkish: return "Türkçe"
        case .filipino: return "Filipino"
        }
    }
}

/// Флаг Каталонии (сенера): 9 горизонтальных полос — 4 красные, 5 жёлтых.
private struct CatalanFlagView: View {
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let stripeHeight = h / 9
            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { i in
                    (i % 2 == 1 ? Color.red : Color.yellow)
                        .frame(height: stripeHeight)
                }
            }
        }
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject(GameState())
}
