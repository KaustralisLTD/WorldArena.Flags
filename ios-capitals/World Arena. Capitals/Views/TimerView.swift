import SwiftUI

struct TimerView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack {
            Text(gameState.formattedTime())
                .font(.title2)
                .monospacedDigit()
                .foregroundColor(timeColor)
            
            ProgressView(value: gameState.timeProgress)
                .tint(timeColor)
                .padding(.horizontal)
        }
    }
    
    private var timeColor: Color {
        if gameState.timeProgress < 0.5 {
            return .green
        } else if gameState.timeProgress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
} 