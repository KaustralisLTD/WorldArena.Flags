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
                // Language flag/icon
                Text(languageFlag)
                    .font(.system(size: 24))
                    .frame(width: 40)
                
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
        }
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject(GameState())
}
