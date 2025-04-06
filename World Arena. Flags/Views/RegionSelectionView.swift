import SwiftUI

struct RegionSelectionView: View {
    @ObservedObject var gameState: GameState
    @State private var availableRegions: [GameState.Region] = []
    
    private func updateAvailableRegions() {
        print("\n=== Updating Available Regions ===")
        var regions = GameState.Region.allCases.filter { $0 != .myMistakes && $0 != .all }
        regions.insert(.all, at: 0)
        
        if gameState.hasMistakes {
            print("Has mistakes, adding My Mistakes region")
            print("Mistakes count: \(gameState.mistakeCountries.count)")
            print("Mistakes: \(gameState.mistakeCountries.map { $0.name.common }.joined(separator: ", "))")
            regions.append(.myMistakes)
        } else {
            print("No mistakes found")
        }
        
        print("Final regions: \(regions.map { $0.rawValue })")
        availableRegions = regions
        print("=====================\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationManager.shared.localizedString("Select Regions"))
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(availableRegions, id: \.self) { region in
                    RegionToggle(gameState: gameState, region: region)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            updateAvailableRegions()
        }
        .onChange(of: gameState.mistakeCountries) { _ in
            updateAvailableRegions()
        }
    }
} 