import { apiService, Country, GameSession, Statistics } from '../services/apiService';
import { GAME_CONFIG } from '../config/api';

interface GameAnswer {
  countryId: string;
  selectedCountryId: string;
  isCorrect: boolean;
  answerTimeMs: number;
  questionNumber: number;
}

interface GameState {
  // Game configuration
  selectedRegions: string[];
  gameMode: string;
  difficulty: string;
  language: string;

  // Current game state
  currentGame: GameSession | null;
  countries: Country[];
  currentCountry: Country | null;
  answerOptions: Country[];
  currentQuestion: number;
  score: number;
  gameAnswers: GameAnswer[];
  startTime: number | null;
  isGameActive: boolean;
  isLoading: boolean;

  // Statistics
  userStatistics: Statistics | null;
  mistakes: Country[];
}

// Simplified store implementation without Zustand for now
class GameStore {
  private state: GameState = {
    selectedRegions: [GAME_CONFIG.REGIONS.ALL],
    gameMode: GAME_CONFIG.MODES.TWENTY,
    difficulty: GAME_CONFIG.DIFFICULTIES.MEDIUM,
    language: 'en',

    currentGame: null,
    countries: [],
    currentCountry: null,
    answerOptions: [],
    currentQuestion: 0,
    score: 0,
    gameAnswers: [],
    startTime: null,
    isGameActive: false,
    isLoading: false,

    userStatistics: null,
    mistakes: [],
  };

  private listeners: Array<() => void> = [];

  // State management
  getState(): GameState {
    return this.state;
  }

  setState(updates: Partial<GameState>): void {
    this.state = { ...this.state, ...updates };
    this.listeners.forEach(listener => listener());
  }

  subscribe(listener: () => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  // Actions
  setGameConfig(config: {
    regions?: string[];
    gameMode?: string;
    difficulty?: string;
    language?: string;
  }): void {
    this.setState({
      selectedRegions: config.regions || this.state.selectedRegions,
      gameMode: config.gameMode || this.state.gameMode,
      difficulty: config.difficulty || this.state.difficulty,
      language: config.language || this.state.language,
    });
  }

  async startNewGame(): Promise<void> {
    this.setState({ isLoading: true });

    try {
      // Start game session
      const { game } = await apiService.startGame({
        regions: this.state.selectedRegions,
        gameMode: this.state.gameMode,
        difficulty: this.state.difficulty,
      });

      // Load countries for the game
      const { countries } = await apiService.getCountriesForGame({
        regions: this.state.selectedRegions,
        language: this.state.language,
        count: game.totalQuestions,
        difficulty: this.state.difficulty,
      });

      if (countries.length === 0) {
        throw new Error('No countries loaded for the selected configuration');
      }

      // Shuffle countries and prepare first question
      const shuffledCountries = [...countries].sort(() => Math.random() - 0.5);
      const firstCountry = shuffledCountries[0];
      const answerOptions = this.generateAnswerOptions(firstCountry, countries);

      this.setState({
        currentGame: game,
        countries: shuffledCountries,
        currentCountry: firstCountry,
        answerOptions,
        currentQuestion: 0,
        score: 0,
        gameAnswers: [],
        startTime: Date.now(),
        isGameActive: true,
        isLoading: false,
      });
    } catch (error) {
      console.error('Error starting game:', error);
      this.setState({ isLoading: false });
      throw error;
    }
  }

  selectAnswer(selectedCountry: Country): void {
    if (!this.state.currentCountry || !this.state.isGameActive) return;

    const isCorrect = selectedCountry.id === this.state.currentCountry.id;
    const answerTime = Date.now() - (this.state.startTime || Date.now());

    const answer: GameAnswer = {
      countryId: this.state.currentCountry.id,
      selectedCountryId: selectedCountry.id,
      isCorrect,
      answerTimeMs: answerTime,
      questionNumber: this.state.currentQuestion + 1,
    };

    this.setState({
      score: this.state.score + (isCorrect ? GAME_CONFIG.POINTS_PER_CORRECT : 0),
      gameAnswers: [...this.state.gameAnswers, answer],
    });

    // Move to next question after a short delay
    setTimeout(() => {
      this.nextQuestion();
    }, 1500);
  }

  nextQuestion(): void {
    const nextQuestionIndex = this.state.currentQuestion + 1;
    const totalQuestions = this.state.currentGame?.totalQuestions || 20;

    if (nextQuestionIndex >= totalQuestions || nextQuestionIndex >= this.state.countries.length) {
      // Game finished
      this.finishGame();
      return;
    }

    const nextCountry = this.state.countries[nextQuestionIndex];
    const answerOptions = this.generateAnswerOptions(nextCountry, this.state.countries);

    this.setState({
      currentCountry: nextCountry,
      answerOptions,
      currentQuestion: nextQuestionIndex,
      startTime: Date.now(),
    });
  }

  async finishGame(): Promise<any> {
    if (!this.state.currentGame) return;

    this.setState({ isLoading: true });

    try {
      const durationSeconds = Math.floor((Date.now() - (this.state.startTime || Date.now())) / 1000);

      const { gameResults, userStatistics } = await apiService.finishGame({
        gameId: this.state.currentGame.id,
        score: this.state.score,
        totalQuestions: this.state.currentGame.totalQuestions,
        correctAnswers: this.state.gameAnswers.filter(a => a.isCorrect).length,
        durationSeconds,
        answers: this.state.gameAnswers,
      });

      this.setState({
        isGameActive: false,
        userStatistics,
        isLoading: false,
      });

      // Reload mistakes if game included mistake regions
      if (this.state.selectedRegions.includes(GAME_CONFIG.REGIONS.MISTAKES)) {
        await this.loadMistakes();
      }

      return gameResults;
    } catch (error) {
      console.error('Error finishing game:', error);
      this.setState({ isLoading: false });
      throw error;
    }
  }

  resetGame(): void {
    this.setState({
      currentGame: null,
      countries: [],
      currentCountry: null,
      answerOptions: [],
      currentQuestion: 0,
      score: 0,
      gameAnswers: [],
      startTime: null,
      isGameActive: false,
    });
  }

  async loadStatistics(): Promise<void> {
    try {
      const { statistics } = await apiService.getStatistics();
      this.setState({ userStatistics: statistics });
    } catch (error) {
      console.error('Error loading statistics:', error);
    }
  }

  async loadMistakes(): Promise<void> {
    try {
      const { mistakes } = await apiService.getMistakes({
        language: this.state.language,
      });
      this.setState({ mistakes });
    } catch (error) {
      console.error('Error loading mistakes:', error);
    }
  }

  // Helper function to generate answer options
  private generateAnswerOptions(correctCountry: Country, allCountries: Country[]): Country[] {
    const optionsCount = 6;
    const options = [correctCountry];

    // Filter out the correct country and get wrong options
    const wrongCountries = allCountries.filter(country => country.id !== correctCountry.id);

    // Try to get wrong options from the same region first
    const sameRegionCountries = wrongCountries.filter(country => 
      country.region === correctCountry.region
    );

    // Add same region countries first
    while (options.length < optionsCount && sameRegionCountries.length > 0) {
      const randomIndex = Math.floor(Math.random() * sameRegionCountries.length);
      const selectedCountry = sameRegionCountries.splice(randomIndex, 1)[0];
      options.push(selectedCountry);
    }

    // Fill remaining slots with random countries
    while (options.length < optionsCount && wrongCountries.length > 0) {
      const randomIndex = Math.floor(Math.random() * wrongCountries.length);
      const selectedCountry = wrongCountries.splice(randomIndex, 1)[0];
      if (!options.find(c => c.id === selectedCountry.id)) {
        options.push(selectedCountry);
      }
    }

    // Shuffle the options
    return options.sort(() => Math.random() - 0.5);
  }
}

// Create and export singleton instance
export const gameStore = new GameStore();

// Hook for React components
export const useGameStore = () => gameStore; 