import SwiftUI

struct RegionToggle: View {
    @ObservedObject var gameState: GameState
    let region: GameState.Region
    
    var body: some View {
        Button(action: {
            gameState.toggleRegion(region)
        }) {
            HStack(spacing: 4) {
                Text(LocalizationManager.shared.localizedString(region.rawValue))
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if region == .myMistakes {
                    Text("(\(gameState.mistakeCountries.count))")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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