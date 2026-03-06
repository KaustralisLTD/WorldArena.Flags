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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Animation states
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0.0
    @State private var buttonScale: CGFloat = 0.9
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // ТЕСТОВЫЙ ЯРКИЙ ФОН ДЛЯ ПРОВЕРКИ
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.3),
                        Color.orange.opacity(0.3),
                        Color.yellow.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        languageSelector
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: showContent)
                        
                        titleView
                        
                        RegionSelectionView(gameState: gameState)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: showContent)
                        
                        difficultySelection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
                        
                        gameModeSelection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: showContent)
                        
                        startGameButton
                            .scaleEffect(buttonScale)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showContent)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        if let error = error {
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        themeSelector
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: showContent)
                        
                        statisticsButton
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: showContent)
                    }
                    .padding()
                }
            }
            
            NavigationLink(
                destination: GameView()
                    .environmentObject(gameState)
                    #if os(iOS)
                    .navigationBarBackButtonHidden(true)
                    #endif
                ,
                isActive: $gameState.isNavigatingToGame
            ) {
                EmptyView()
            }
            #if os(iOS)
            .isDetailLink(false)
            #endif
        }
        .preferredColorScheme(themeManager.colorScheme)
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Принудительно обновляем view при смене языка
            gameState.objectWillChange.send()
        }
        .onAppear {
            // Обновляем количество вариантов ответов для iPhone (6 вариантов)
            gameState.updateOptionsCount(isIPad: false)
            
            // Запускаем начальные анимации
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
    
    // MARK: - View Components
    
    private var languageSelector: some View {
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
    }
    
    private var titleView: some View {
        VStack(spacing: 8) {
            Text("🌍")
                .font(.system(size: 50))
                .scaleEffect(titleScale)
                .opacity(titleOpacity)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: titleScale)
                .animation(.easeIn(duration: 0.8).delay(0.2), value: titleOpacity)
            
            Text("🔥 НОВЫЙ ДИЗАЙН! 🔥")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.red)
                .background(Color.yellow)
                .padding()
                .scaleEffect(titleScale)
                .opacity(titleOpacity)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: titleScale)
                .animation(.easeIn(duration: 1.0).delay(0.3), value: titleOpacity)
        }
        .onAppear {
            withAnimation {
                titleScale = 1.0
                titleOpacity = 1.0
            }
        }
        .padding(.bottom, 8)
    }
    
    private var difficultySelection: some View {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("Difficulty"))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(gameState.availableDifficulties, id: \.self) { difficulty in
                            Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                gameState.selectedDifficulty = difficulty
                        }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(difficulty.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(
                                            gameState.selectedDifficulty == difficulty ? .white : .primary
                                        )
                                    
                                    Text(difficulty.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            gameState.selectedDifficulty == difficulty ? .white.opacity(0.8) : .secondary
                                        )
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    gameState.selectedDifficulty == difficulty
                                    ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.secondary.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: gameState.selectedDifficulty == difficulty ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(gameState.selectedDifficulty == difficulty ? 1.02 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameState.selectedDifficulty)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
        }
                }
                
    private var gameModeSelection: some View {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("Game Mode"))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(gameState.availableGameModes, id: \.self) { mode in
                            Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                gameState.selectedGameMode = mode
                        }
                            }) {
                                HStack(spacing: 12) {
                            Text("🎯")
                                        .font(.system(size: 24))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(
                                                gameState.selectedGameMode == mode ? .white : .primary
                                            )
                                        
                                Text(LocalizationManager.shared.localizedString("Standard multiple choice game"))
                                            .font(.system(size: 12))
                                            .foregroundColor(
                                                gameState.selectedGameMode == mode ? .white.opacity(0.8) : .secondary
                                            )
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    gameState.selectedGameMode == mode
                                    ? LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.secondary.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: gameState.selectedGameMode == mode ? .green.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(gameState.selectedGameMode == mode ? 1.02 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameState.selectedGameMode)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
        }
    }
    
    private var startGameButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Strong haptic feedback for main action
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                
                // Button press animation
                withAnimation(.easeInOut(duration: 0.1)) {
                    buttonScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale = 1.0
                    }
                }
                
                    Task {
                        isLoading = true
                        error = nil
                        await gameState.startNewGameWithCurrentRegions()
                        isLoading = false
                    }
                }) {
                HStack(spacing: 12) {
                    if isLoading && !gameState.isPreloadingFlags {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    }
                    
                    Text(LocalizationManager.shared.localizedString("START GAME"))
                        .font(.system(size: horizontalSizeClass == .regular ? 32 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !isLoading {
                        Image(systemName: "play.fill")
                            .font(.system(size: horizontalSizeClass == .regular ? 28 : 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                        .frame(maxWidth: .infinity)
                .frame(height: horizontalSizeClass == .regular ? 80 : 60)
                        .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            gameState.selectedRegions.isEmpty 
                            ? LinearGradient(colors: [Color.gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(
                                colors: [.orange, .red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: gameState.selectedRegions.isEmpty ? .clear : .red.opacity(0.4),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        )
                }
                .disabled(gameState.selectedRegions.isEmpty || isLoading)
            .scaleEffect(gameState.selectedRegions.isEmpty ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gameState.selectedRegions.isEmpty)
                
            // Современный индикатор загрузки флагов
            if gameState.isPreloadingFlags {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                    ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                        
                        Text(LocalizationManager.shared.localizedString("Loading flags..."))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    // Современный прогресс-бар с градиентом
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, UIScreen.main.bounds.width * 0.7 * gameState.flagPreloadProgress), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: gameState.flagPreloadProgress)
                    }
                    
                    Text("\(Int(gameState.flagPreloadProgress * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var themeSelector: some View {
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
                }
                
    private var statisticsButton: some View {
                Button(action: {
            // Light haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
                    showingStatistics = true
                }) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(LocalizationManager.shared.localizedString("Statistics"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingStatistics)
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
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
                switch mode {
                case .all:
                    localizedName = LocalizationManager.shared.localizedString("All Flags")
                case .twenty:
                    localizedName = LocalizationManager.shared.localizedString("20 Flags")
                case .fifty:
                    localizedName = LocalizationManager.shared.localizedString("50 Flags")
                case .hundred:
                    localizedName = LocalizationManager.shared.localizedString("100 Flags")
                }
            }
            .task {
                switch mode {
                case .all:
                    localizedName = LocalizationManager.shared.localizedString("All Flags")
                case .twenty:
                    localizedName = LocalizationManager.shared.localizedString("20 Flags")
                case .fifty:
                    localizedName = LocalizationManager.shared.localizedString("50 Flags")
                case .hundred:
                    localizedName = LocalizationManager.shared.localizedString("100 Flags")
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Button(action: {
            // Haptic feedback for theme selection
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            themeManager.setTheme(theme)
            action()
        }) {
            Text(localizedName)
                .font(.system(size: horizontalSizeClass == .regular ? 24 : 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                .padding(.vertical, horizontalSizeClass == .regular ? 12 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected 
                            ? LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.appBackgroundSecondary], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
        .task {
            localizedName = theme.getLocalizedName()
        }
        .onChange(of: gameState.selectedLanguage) { _ in
            localizedName = theme.getLocalizedName()
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

// Кастомный стиль кнопки с эффектом нажатия
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Стиль кнопки с пульсацией
struct PulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 
