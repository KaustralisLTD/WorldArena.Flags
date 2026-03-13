import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ThemeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: AppThemeManager
    
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
                        Image(systemName: "paintbrush")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(LocalizationManager.shared.localizedString("Тема"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizationManager.shared.localizedString("Выберите тему оформления приложения"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    
                    // Themes list
                    VStack(spacing: 1) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeRow(
                                theme: theme,
                                isSelected: themeManager.selectedTheme == theme
                            ) {
                                selectTheme(theme)
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
            .navigationTitle(LocalizationManager.shared.localizedString("Тема"))
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
    
    private func selectTheme(_ theme: AppTheme) {
        themeManager.setTheme(theme)
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
}

struct ThemeRow: View {
    let theme: AppTheme
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
                // Theme icon
                Text(themeIcon)
                    .font(.system(size: 24))
                    .frame(width: 40)
                
                // Theme name
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationManager.shared.localizedString(theme.localizationKey))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(themeDescriptionKey)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
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
    
    private var themeIcon: String {
        switch theme {
        case .system: return "⚙️"
        case .light: return "☀️"
        case .dark: return "🌙"
        }
    }
    
    private var themeDescriptionKey: String {
        switch theme {
        case .system:
            return LocalizationManager.shared.localizedString("Следует системным настройкам")
        case .light:
            return LocalizationManager.shared.localizedString("Светлое оформление")
        case .dark:
            return LocalizationManager.shared.localizedString("Темное оформление")
        }
    }
}

#Preview {
    ThemeSelectionView()
        .environmentObject(AppThemeManager.shared)
}
