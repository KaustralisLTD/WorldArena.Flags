import SwiftUI

struct StartView: View {
    @StateObject var gameState: GameState
    @State private var isNavigatingToGame = false
    @State private var showingStatistics = false
    @State private var isLoading = false
    @State private var error: Error?
    @ObservedObject private var themeManager = AppThemeManager.shared
    @State private var showLanguageMenu = false
    @State private var showStatistics = false
    @State private var showThemeMenu = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Language Selector
                HStack {
                    Text(LocalizationManager.shared.localizedString("Select Language"))
                        .font(.headline)
                    
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
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
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
                
                // Title
                Text(LocalizationManager.shared.localizedString("World Flags"))
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                // Region Selection
                RegionSelectionView(gameState: gameState)
                
                // Game Mode Selection
                HStack {
                    Text(LocalizationManager.shared.localizedString("Game Mode"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker(LocalizationManager.shared.localizedString("Game Mode"), selection: $gameState.selectedGameMode) {
                        ForEach(gameState.availableGameModes, id: \.self) { mode in
                            Text(LocalizationManager.shared.localizedString(mode.displayName))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                
                // Start Game Button
                Button(action: {
                    Task {
                        isLoading = true
                        error = nil
                        do {
                            await gameState.startNewGameWithCurrentRegions()
                            isLoading = false
                        } catch {
                            self.error = error
                            isLoading = false
                        }
                    }
                }) {
                    Text(LocalizationManager.shared.localizedString("START GAME"))
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(gameState.selectedRegions.isEmpty ? Color.gray : Color.blue)
                        )
                }
                .disabled(gameState.selectedRegions.isEmpty || isLoading)
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Theme Selector
                VStack(alignment: .leading) {
                    Text(LocalizationManager.shared.localizedString("App Theme"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                ThemeButton(
                                    theme: theme,
                                    isSelected: themeManager.selectedTheme == theme,
                                    action: { },
                                    gameState: gameState
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Statistics Button
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
                
                NavigationLink(
                    destination: GameView(gameState: gameState)
                        .navigationBarBackButtonHidden(true),
                    isActive: $gameState.isNavigatingToGame
                ) {
                    EmptyView()
                }
                .isDetailLink(false)
            }
            .padding()
            .preferredColorScheme(themeManager.colorScheme)
        }
        .navigationViewStyle(.stack)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            // Принудительно обновляем view при смене языка
            gameState.objectWillChange.send()
        }
    }
}

struct GameModeView: View {
    let mode: GameState.GameMode
    @State private var localizedName: String = ""
    @ObservedObject var gameState: GameState
    
    var body: some View {
        Text(localizedName)
            .onChange(of: gameState.selectedLanguage) { _ in
                Task {
                    switch mode {
                    case .all:
                        localizedName = await LocalizationManager.shared.localizedString("All Flags")
                    case .twenty:
                        localizedName = await LocalizationManager.shared.localizedString("20 Flags")
                    case .fifty:
                        localizedName = await LocalizationManager.shared.localizedString("50 Flags")
                    case .hundred:
                        localizedName = await LocalizationManager.shared.localizedString("100 Flags")
                    }
                }
            }
            .task {
                switch mode {
                case .all:
                    localizedName = await LocalizationManager.shared.localizedString("All Flags")
                case .twenty:
                    localizedName = await LocalizationManager.shared.localizedString("20 Flags")
                case .fifty:
                    localizedName = await LocalizationManager.shared.localizedString("50 Flags")
                case .hundred:
                    localizedName = await LocalizationManager.shared.localizedString("100 Flags")
                }
            }
    }
}

struct ThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    @State private var localizedName: String = ""
    @ObservedObject var gameState: GameState
    @ObservedObject private var themeManager = AppThemeManager.shared
    
    var body: some View {
        Button(action: {
            themeManager.setTheme(theme)
            action()
        }) {
            Text(localizedName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.appBackgroundSecondary)
                )
        }
        .task {
            localizedName = await theme.getLocalizedName()
        }
        .onChange(of: gameState.selectedLanguage) { _ in
            Task {
                localizedName = await theme.getLocalizedName()
            }
        }
    }
}

struct LanguageView: View {
    let language: GameState.Language
    
    var body: some View {
        HStack {
            Text(language.displayName)
                .frame(minWidth: 100, alignment: .leading)
                .contentShape(Rectangle())
        }
        .frame(height: 44)
    }
} 
