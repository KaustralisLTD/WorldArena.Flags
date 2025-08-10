import SwiftUI

struct RegionToggle: View {
    @ObservedObject var gameState: GameState
    let region: GameState.Region
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Button(action: {
            gameState.toggleRegion(region)
        }) {
            HStack(spacing: 4) {
                Text(LocalizationManager.shared.localizedString(region.rawValue))
                    .font(.system(size: horizontalSizeClass == .regular ? 27 : 18, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if region == .myMistakes {
                    Text("(\(gameState.mistakeCountries.count))")
                        .font(.system(size: horizontalSizeClass == .regular ? 24 : 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 15 : 10)
            .padding(.vertical, horizontalSizeClass == .regular ? 12 : 8)
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