import SwiftUI

struct RegionToggle: View {
    @ObservedObject var gameState: GameState
    let region: GameState.Region
    var compact: Bool = false
    var largeFontForLandscape: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var titleFontSize: CGFloat {
        if compact { return largeFontForLandscape ? 24 : 18 }
        return horizontalSizeClass == .regular ? 27 : 18
    }
    private var countFontSize: CGFloat {
        if compact { return largeFontForLandscape ? 18 : 14 }
        return horizontalSizeClass == .regular ? 24 : 16
    }
    private var crownFontSize: CGFloat {
        if compact { return largeFontForLandscape ? 14 : 10 }
        return horizontalSizeClass == .regular ? 16 : 12
    }
    private var hPadding: CGFloat { compact ? 8 : (horizontalSizeClass == .regular ? 15 : 10) }
    private var vPadding: CGFloat { compact ? 5 : (horizontalSizeClass == .regular ? 12 : 8) }
    
    var body: some View {
        Button(action: {
            // Проверка Premium для раздела "Мои ошибки"
            if region == .myMistakes && !gameState.isPremium {
                // Показываем алерт Premium
                gameState.showMistakesPremiumAlert = true
                return
            }
            gameState.toggleRegion(region)
        }) {
            HStack(spacing: 4) {
                Text(LocalizationManager.shared.localizedString(region.rawValue))
                    .font(.system(size: titleFontSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if region == .myMistakes {
                    Text("(\(gameState.mistakeCountries.count))")
                        .font(.system(size: countFontSize))
                        .foregroundColor(.secondary)
                    
                    // Показываем значок Premium если пользователь не Premium
                    if !gameState.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: crownFontSize))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .frame(maxWidth: .infinity)
            .background(
                gameState.selectedRegions.contains(region)
                ? Color.accentColor
                : Color.secondary.opacity(0.15)
            )
            .foregroundColor(
                gameState.selectedRegions.contains(region)
                ? .white
                : .primary
            )
            .cornerRadius(8)
            .overlay(
                region == .myMistakes ?
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                : nil
            )
        }
    }
} 