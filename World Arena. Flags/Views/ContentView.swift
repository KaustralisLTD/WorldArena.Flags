import SwiftUI

struct ContentView: View {
    @ObservedObject var gameState: GameState
    @State private var showingStatistics = false
    @State private var isLoading = false
    @ObservedObject private var themeManager = AppThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            ScrollView {
            VStack(spacing: 20) {
                // Language Selector
                HStack {
                    Text(LocalizationManager.shared.localizedString("Select Language"))
                        .font(horizontalSizeClass == .regular ? .title2 : .headline)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(GameState.Language.allCases, id: \.self) { language in
                            Button(action: {
                                Task {
                                    await gameState.setLanguage(language)
                                }
                            }) {
                                HStack {
                                    Text(language.displayName)
                                    if gameState.selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Text(gameState.selectedLanguage.displayName)
                                    .font(horizontalSizeClass == .regular ? .title3 : .body)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, horizontalSizeClass == .regular ? 12 : 8)
                            .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appBackgroundSecondary)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                // Region Selection
                RegionSelectionView(gameState: gameState)
                
                // Game Mode Selection
                GameModeSelectionView(gameState: gameState)
                
                // Start Game Button
                Button(action: {
                    if !isLoading {
                        Task {
                            isLoading = true
                            await gameState.startNewGameWithCurrentRegions()
                            isLoading = false
                        }
                    }
                }) {
                    Text(LocalizationManager.shared.localizedString("START GAME"))
                        .font(.system(size: horizontalSizeClass == .regular ? 28 : 22, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: horizontalSizeClass == .regular ? 60 : 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(gameState.selectedRegions.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Statistics Button
                Button(action: {
                    showingStatistics = true
                }) {
                    Text(LocalizationManager.shared.localizedString("Statistics"))
                        .font(horizontalSizeClass == .regular ? .title2 : .headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: horizontalSizeClass == .regular ? 50 : 40)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, horizontalSizeClass == .regular ? 40 : 20)
            }
            NavigationLink(
                destination: GameView()
                    .environmentObject(gameState),
                isActive: $gameState.isNavigatingToGame
            ) {
                EmptyView()
            }
            .hidden()
        }
        .background(Color.appBackgroundPrimary)
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
                .environmentObject(gameState)
        }
                .onAppear {
            gameState.updateOptionsCount(isIPad: horizontalSizeClass == .regular)
        }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}