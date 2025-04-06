import SwiftUI

@MainActor
struct StartScreen: View {
    @EnvironmentObject var gameState: GameState
    @Binding var showingGame: Bool
    @State private var showingStatistics = false
    @State private var isStartingGame = false
    @State private var gameInitialized = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationManager.shared.localizedString("World Flags"))
                .font(.largeTitle)
                .bold()
            
            // Language Selector
            VStack(alignment: .leading) {
                Text(LocalizationManager.shared.localizedString("Select Language"))
                    .font(.headline)
                
                Picker(LocalizationManager.shared.localizedString("Select Language"), selection: Binding(
                    get: { gameState.selectedLanguage },
                    set: { language in
                        Task {
                            await gameState.setLanguage(language)
                        }
                    }
                )) {
                    ForEach(GameState.Language.allCases, id: \.self) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Region Selector
            RegionSelectionView(gameState: gameState)
            
            // Обновим секцию выбора режима игры
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localizedString("Select Game Mode"))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(gameState.availableGameModes, id: \.self) { mode in
                        Button(action: {
                            gameState.selectedGameMode = mode
                        }) {
                            Text(mode.displayName)
                                .font(.system(size: 18, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    gameState.selectedGameMode == mode
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.15)
                                )
                                .foregroundColor(
                                    gameState.selectedGameMode == mode
                                    ? .white
                                    : .primary
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                // Принудительно обновляем View при смене языка
                gameState.objectWillChange.send()
            }
            
            Button {
                startGame()
            } label: {
                Text(LocalizationManager.shared.localizedString("START GAME"))
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isStartingGame ? Color.gray : Color.green)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(gameState.isLoading || gameState.countries.isEmpty || isStartingGame)
            
            Button(action: {
                showingStatistics = true
            }) {
                Label(LocalizationManager.shared.localizedString("Statistics"), systemImage: "chart.bar.fill")
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView()
            }
        }
        .padding()
        .onChange(of: gameState.selectedLanguage) { _ in
            gameState.objectWillChange.send()
        }
        .onChange(of: gameInitialized) { initialized in
            if initialized {
                withAnimation {
                    showingGame = true
                }
                gameInitialized = false
            }
        }
    }
    
    private func startGame() {
        guard !isStartingGame else { return }
        
        Task { @MainActor in
            isStartingGame = true
            
            do {
                // Инициализируем игру
                await gameState.startNewGameWithCurrentRegions()
                
                // Отмечаем, что игра инициализирована
                gameInitialized = true
            } catch {
                print("Error starting game: \(error)")
            }
            
            isStartingGame = false
        }
    }
} 