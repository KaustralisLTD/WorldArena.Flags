import SwiftUI

struct RegionSelectionView: View {
    @ObservedObject var gameState: GameState
    @State private var availableRegions: [GameState.Region] = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Количество колонок (2 по умолчанию, 3 для iPad горизонтально)
    var columnCount: Int = 2
    /// Компактный вид кнопок (меньше отступы), например для iPad landscape
    var compact: Bool = false
    /// Крупный шрифт названий регионов (для iPad landscape)
    var largeFontForLandscape: Bool = false
    
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: compact ? 6 : 8), count: columnCount), spacing: compact ? 6 : 8) {
            ForEach(availableRegions, id: \.self) { region in
                RegionToggle(gameState: gameState, region: region, compact: compact, largeFontForLandscape: largeFontForLandscape)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .onAppear {
            updateAvailableRegions()
        }
        .onChange(of: gameState.mistakeCountries) { _ in
            updateAvailableRegions()
        }
    }
} 