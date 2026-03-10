import SwiftUI
#if os(iOS)
import UIKit
#endif

struct GameModeSelectionView: View {
    @ObservedObject var gameState: GameState
    /// Крупный шрифт для iPad landscape
    var largeFontForLandscape: Bool = false
    /// Компактный вид при увеличенном тексте (accessibility): только заголовок + (?) с описанием по тапу
    var compactForAccessibility: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var descriptionAlertMode: GameState.PlayMode? = nil

    #if os(iOS)
    private static var isLargeAccessibilityText: Bool {
        UIFont.preferredFont(forTextStyle: .body).pointSize > 20
    }
    #else
    private static var isLargeAccessibilityText: Bool { false }
    #endif

    private var compactModeEnabled: Bool {
        compactForAccessibility
            || sizeCategory.isAccessibilityCategory
            || sizeCategory >= .extraExtraLarge
            || Self.isLargeAccessibilityText
    }

    var body: some View {
        gameModeSelectionView
            .padding(.horizontal, 20)
            .alert(descriptionAlertMode?.displayName ?? LocalizationManager.shared.localizedString("Game Mode"), isPresented: Binding(
                get: { descriptionAlertMode != nil },
                set: { if !$0 { descriptionAlertMode = nil } }
            )) {
                Button(LocalizationManager.shared.localizedString("Close"), role: .cancel) {
                    descriptionAlertMode = nil
                }
            } message: {
                if let mode = descriptionAlertMode {
                    Text(mode.description)
                }
            }
    }
    
    private var difficultySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localizedString("Difficulty"))
                .font(titleFont)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
            
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(gameState.availableDifficulties, id: \.self) { difficulty in
                    difficultyButton(for: difficulty)
                }
            }
        }
    }
    
    private var gameModeSelectionView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(gameState.availablePlayModes, id: \.self) { playMode in
                gameModeButton(for: playMode)
            }
        }
    }
    
    private var titleFont: Font {
        horizontalSizeClass == .regular ? .title2 : .headline
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    private func difficultyButton(for difficulty: GameState.Difficulty) -> some View {
        Button(action: {
            gameState.selectedDifficulty = difficulty
        }) {
            difficultyButtonContent(for: difficulty)
        }
    }
    
    private func difficultyButtonContent(for difficulty: GameState.Difficulty) -> some View {
        let isSelected = gameState.selectedDifficulty == difficulty
        let textColor = isSelected ? Color.white : Color.primary
        let secondaryColor = isSelected ? Color.white.opacity(0.8) : Color.secondary
        let backgroundColor = isSelected ? Color.accentColor : Color.secondary.opacity(0.15)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(difficulty.displayName)
                .font(.system(size: horizontalSizeClass == .regular ? 18 : 16, weight: .medium))
                .foregroundColor(textColor)
            
            Text(difficulty.description)
                .font(.system(size: horizontalSizeClass == .regular ? 14 : 12))
                .foregroundColor(secondaryColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private func gameModeButton(for playMode: GameState.PlayMode) -> some View {
        Button(action: {
            gameState.selectedPlayMode = playMode
        }) {
            gameModeButtonContent(for: playMode)
        }
    }
    
    private func gameModeButtonContent(for playMode: GameState.PlayMode) -> some View {
        let isSelected = gameState.selectedPlayMode == playMode
        let textColor = isSelected ? Color.white : Color.primary
        let secondaryColor = isSelected ? Color.white.opacity(0.8) : Color.secondary
        let backgroundColor = isSelected ? Color.accentColor : Color.secondary.opacity(0.15)
        
        let titleSize: CGFloat = largeFontForLandscape ? 22 : (horizontalSizeClass == .regular ? 18 : 16)
        let descSize: CGFloat = largeFontForLandscape ? 17 : (horizontalSizeClass == .regular ? 14 : 12)
        let iconSize: CGFloat = largeFontForLandscape ? 22 : 20
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Group {
                    if let sys = playMode.systemImage {
                        Image(systemName: sys)
                            .font(.system(size: iconSize))
                    } else {
                        Text(playMode.icon)
                            .font(.system(size: iconSize))
                    }
                }
                .foregroundColor(textColor)
                Text(playMode.displayName)
                    .font(.system(size: titleSize, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if compactModeEnabled {
                    Button {
                        descriptionAlertMode = playMode
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: iconSize))
                            .foregroundColor(secondaryColor)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            
            if !compactModeEnabled {
                Text(playMode.description)
                    .font(.system(size: descSize))
                    .foregroundColor(secondaryColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

struct GameModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GameModeSelectionView(gameState: GameState())
    }
} 