import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var themeManager = AppThemeManager.shared
    
    var body: some View {
        NavigationView {
            StartView(gameState: gameState)
        }
        .environmentObject(themeManager)
    }
} 