import SwiftUI

struct RegionSelectorView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizationManager.shared.localizedString("Select Regions"))
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(GameState.Region.allCases, id: \.self) { region in
                        RegionToggle(gameState: gameState, region: region)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
} 