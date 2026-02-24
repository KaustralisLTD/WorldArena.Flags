import SwiftUI

struct GameModeSelectionView: View {
    @ObservedObject var gameState: GameState
    /// Крупный шрифт для iPad landscape
    var largeFontForLandscape: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        gameModeSelectionView
            .padding(.horizontal, 20)
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
            }
            
            Text(playMode.description)
                .font(.system(size: descSize))
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
}

struct GameModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GameModeSelectionView(gameState: GameState())
    }
} 