import SwiftUI

struct GameOverView: View {
    let score: Int
    let timeElapsed: String
    let dismiss: DismissAction
    @EnvironmentObject var gameState: GameState
    
    @State private var scoreScale = 0.5
    @State private var buttonsOpacity = 0.0
    @State private var isSharePresented = false
    
    private func getResultMessage(score: Int, total: Int) -> String {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return LocalizationManager.shared.localizedString("Excellent game!")
        } else if percentage >= 0.7 {
            return LocalizationManager.shared.localizedString("Great result!")
        } else if percentage >= 0.5 {
            return LocalizationManager.shared.localizedString("Good game!")
        } else {
            return LocalizationManager.shared.localizedString("Keep practicing!")
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text(getResultMessage(score: score, total: gameState.questionsPerGame))
                .font(.largeTitle)
                .bold()
                .transition(.move(edge: .top))
            
            VStack(spacing: 10) {
                Text("\(score)")
                    .font(.system(size: 60))
                    .bold()
                    .scaleEffect(scoreScale)
                Text(LocalizationManager.shared.localizedString("points"))
                    .font(.title2)
                    .opacity(buttonsOpacity)
            }
            .foregroundColor(.green)
            
            VStack(spacing: 15) {
                Button(action: {
                    Task {
                        await gameState.startNewGameWithCurrentRegions()
                        isSharePresented = false
                    }
                }, label: {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                })
                
                Button(LocalizationManager.shared.localizedString("Share Result")) {
                    isSharePresented = true
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button(action: {
                    dismiss()
                }) {
                    Text(LocalizationManager.shared.localizedString("Home"))
                }
                .buttonStyle(.bordered)
            }
            .opacity(buttonsOpacity)
            .padding(.top)
            
            Text("\(LocalizationManager.shared.localizedString("Time")): \(timeElapsed)")
                .font(.title2)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scoreScale = 1.0
            }
            withAnimation(.easeIn.delay(0.3)) {
                buttonsOpacity = 1.0
            }
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(activityItems: [
                ShareService.shared.createShareMessage(score: score)
            ])
        }
    }
}

// Вспомогательное представление для шаринга
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 