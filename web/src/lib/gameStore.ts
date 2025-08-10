import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

export interface Country {
  code: string;
  name: string;
  flag: string;
  region: string;
  subregion?: string;
  capital?: string[];
  population?: number;
  area?: number;
  languages?: Record<string, string>;
  currencies?: Record<string, { name: string; symbol?: string }>;
}

export interface GameQuestion {
  id: string;
  country: Country;
  options: Country[];
  type: 'flag-to-name' | 'name-to-flag' | 'capital' | 'mixed';
}

export interface GameAnswer {
  questionId: string;
  selectedAnswer: string;
  correctAnswer: string;
  isCorrect: boolean;
  timeSpent: number;
  timestamp: number;
}

export interface GameSession {
  id: string;
  questions: GameQuestion[];
  answers: GameAnswer[];
  currentQuestionIndex: number;
  startTime: number;
  endTime?: number;
  settings: GameSettings;
  score: number;
  totalTime: number;
  isCompleted: boolean;
}

export interface GameSettings {
  region: string;
  difficulty: 'easy' | 'medium' | 'hard' | 'expert' | 'erudite';
  questionCount: number;
  timeLimit?: number;
  gameMode: 'classic' | 'time-attack' | 'survival' | 'mistakes';
  questionTypes: ('flag-to-name' | 'name-to-flag' | 'capital' | 'mixed')[];
}

export interface UserStatistics {
  totalGames: number;
  totalQuestions: number;
  correctAnswers: number;
  averageScore: number;
  bestScore: number;
  totalTime: number;
  averageTime: number;
  streakCurrent: number;
  streakBest: number;
  regionStats: Record<string, {
    games: number;
    correct: number;
    total: number;
    accuracy: number;
  }>;
  difficultyStats: Record<string, {
    games: number;
    correct: number;
    total: number;
    accuracy: number;
  }>;
  mistakeCountries: Record<string, {
    country: Country;
    mistakes: number;
    lastMistake: number;
  }>;
}

export interface GameState {
  // Game data
  countries: Country[];
  currentSession: GameSession | null;
  gameHistory: GameSession[];
  statistics: UserStatistics;
  
  // UI state
  isLoading: boolean;
  error: string | null;
  isOnline: boolean;
  
  // Settings
  settings: GameSettings;
  language: string;
  theme: 'light' | 'dark' | 'system';
  
  // Actions
  setCountries: (countries: Country[]) => void;
  startGame: (settings: GameSettings) => void;
  answerQuestion: (answer: GameAnswer) => void;
  nextQuestion: () => void;
  endGame: () => void;
  resetGame: () => void;
  
  // Statistics actions
  updateStatistics: (session: GameSession) => void;
  addMistake: (country: Country) => void;
  getMistakeCountries: () => Country[];
  
  // Settings actions
  updateSettings: (settings: Partial<GameSettings>) => void;
  setLanguage: (language: string) => void;
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  
  // Utility actions
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setOnlineStatus: (online: boolean) => void;
  clearData: () => void;
}

const defaultSettings: GameSettings = {
  region: 'all',
  difficulty: 'medium',
  questionCount: 10,
  timeLimit: 30,
  gameMode: 'classic',
  questionTypes: ['flag-to-name', 'name-to-flag'],
};

const defaultStatistics: UserStatistics = {
  totalGames: 0,
  totalQuestions: 0,
  correctAnswers: 0,
  averageScore: 0,
  bestScore: 0,
  totalTime: 0,
  averageTime: 0,
  streakCurrent: 0,
  streakBest: 0,
  regionStats: {},
  difficultyStats: {},
  mistakeCountries: {},
};

export const useGameStore = create<GameState>()(
  persist(
    immer((set, get) => ({
      // Initial state
      countries: [],
      currentSession: null,
      gameHistory: [],
      statistics: defaultStatistics,
      isLoading: false,
      error: null,
      isOnline: true,
      settings: defaultSettings,
      language: 'ru',
      theme: 'system',

      // Game actions
      setCountries: (countries) => set((state) => {
        state.countries = countries;
      }),

      startGame: (settings) => set((state) => {
        console.log('🎮 Starting game with settings:', settings);
        console.log('📊 Current countries in store:', state.countries.length);
        
        // Check if we have countries
        if (state.countries.length === 0) {
          console.error('❌ No countries loaded! Cannot start game.');
          state.error = 'No countries loaded';
          return;
        }
        
        // Filter countries by region
        let filteredCountries = state.countries;
        
        if (settings.region !== 'all') {
          const normalizeRegion = (region: string) => region.toLowerCase().trim();
          
          console.log('🔍 Filtering by region:', settings.region);
          console.log('📈 Available countries before filtering:', filteredCountries.length);
          
          filteredCountries = state.countries.filter(country => {
            const countryRegion = normalizeRegion(country.region);
            const targetRegion = normalizeRegion(settings.region);
            
            const matches = countryRegion === targetRegion || 
                           countryRegion.includes(targetRegion) ||
                           targetRegion.includes(countryRegion);
            
            if (matches) {
              console.log(`✓ ${country.name} (${country.region}) matches ${settings.region}`);
            }
            
            return matches;
          });
          
          console.log('📊 Countries after filtering:', filteredCountries.length);
          console.log('🏁 Filtered countries:', filteredCountries.map(c => `${c.name} (${c.region})`).join(', '));
        }

        // Check if we have enough countries
        if (filteredCountries.length < 4) {
          console.error('❌ Not enough countries for selected region! Need at least 4, found:', filteredCountries.length);
          state.error = `Not enough countries for ${settings.region}. Found: ${filteredCountries.length}`;
          return;
        }

        // Generate questions
        const questions = generateQuestions(filteredCountries, settings);
        
        console.log('❓ Generated questions:', questions.length);
        
        if (questions.length === 0) {
          console.error('❌ Failed to generate questions!');
          state.error = 'Failed to generate questions';
          return;
        }
        
        const session: GameSession = {
          id: Date.now().toString(),
          questions,
          answers: [],
          currentQuestionIndex: 0,
          startTime: Date.now(),
          settings,
          score: 0,
          totalTime: 0,
          isCompleted: false,
        };

        state.currentSession = session;
        state.error = null;
        
        console.log('✅ Game session created successfully!');
        console.log('🎯 Session ID:', session.id);
        console.log('❓ Total questions:', session.questions.length);
        console.log('===================');
      }),

      answerQuestion: (answer) => set((state) => {
        if (!state.currentSession) return;

        state.currentSession.answers.push(answer);
        
        if (answer.isCorrect) {
          state.currentSession.score += 1;
        } else {
          // Add to mistakes
          const question = state.currentSession.questions.find(q => q.id === answer.questionId);
          if (question) {
            const country = question.country;
            if (!state.statistics.mistakeCountries[country.code]) {
              state.statistics.mistakeCountries[country.code] = {
                country,
                mistakes: 0,
                lastMistake: 0,
              };
            }
            state.statistics.mistakeCountries[country.code].mistakes += 1;
            state.statistics.mistakeCountries[country.code].lastMistake = Date.now();
          }
        }
      }),

      nextQuestion: () => set((state) => {
        if (!state.currentSession) return;
        
        if (state.currentSession.currentQuestionIndex < state.currentSession.questions.length - 1) {
          state.currentSession.currentQuestionIndex += 1;
        } else {
          // Game completed - only mark as completed, don't update statistics here
          state.currentSession.isCompleted = true;
          state.currentSession.endTime = Date.now();
          state.currentSession.totalTime = state.currentSession.endTime - state.currentSession.startTime;
        }
      }),

      endGame: () => set((state) => {
        if (!state.currentSession) return;
        
        // Mark as completed if not already
        if (!state.currentSession.isCompleted) {
          state.currentSession.isCompleted = true;
          state.currentSession.endTime = Date.now();
          state.currentSession.totalTime = state.currentSession.endTime - state.currentSession.startTime;
        }
        
        // Check if this session is already in history to prevent duplicates
        const sessionExists = state.gameHistory.some(game => game.id === state.currentSession?.id);
        
        if (!sessionExists) {
          // Update statistics only if not already processed
          get().updateStatistics(state.currentSession);
          
          // Add to history
          state.gameHistory.unshift(state.currentSession);
          
          // Keep only last 50 games
          if (state.gameHistory.length > 50) {
            state.gameHistory = state.gameHistory.slice(0, 50);
          }
        }
      }),

      resetGame: () => set((state) => {
        state.currentSession = null;
        state.error = null;
      }),

      // Statistics actions
      updateStatistics: (session) => set((state) => {
        const stats = state.statistics;
        const correctCount = session.answers.filter(a => a.isCorrect).length;
        const totalCount = session.answers.length;
        const score = Math.round((correctCount / totalCount) * 100);

        stats.totalGames += 1;
        stats.totalQuestions += totalCount;
        stats.correctAnswers += correctCount;
        stats.totalTime += session.totalTime;
        
        stats.averageScore = Math.round(stats.correctAnswers / stats.totalQuestions * 100);
        stats.averageTime = Math.round(stats.totalTime / stats.totalQuestions);
        stats.bestScore = Math.max(stats.bestScore, score);

        // Update streak
        if (score >= 80) {
          stats.streakCurrent += 1;
          stats.streakBest = Math.max(stats.streakBest, stats.streakCurrent);
        } else {
          stats.streakCurrent = 0;
        }

        // Update region stats
        const region = session.settings.region;
        if (!stats.regionStats[region]) {
          stats.regionStats[region] = { games: 0, correct: 0, total: 0, accuracy: 0 };
        }
        stats.regionStats[region].games += 1;
        stats.regionStats[region].correct += correctCount;
        stats.regionStats[region].total += totalCount;
        stats.regionStats[region].accuracy = Math.round(
          stats.regionStats[region].correct / stats.regionStats[region].total * 100
        );

        // Update difficulty stats
        const difficulty = session.settings.difficulty;
        if (!stats.difficultyStats[difficulty]) {
          stats.difficultyStats[difficulty] = { games: 0, correct: 0, total: 0, accuracy: 0 };
        }
        stats.difficultyStats[difficulty].games += 1;
        stats.difficultyStats[difficulty].correct += correctCount;
        stats.difficultyStats[difficulty].total += totalCount;
        stats.difficultyStats[difficulty].accuracy = Math.round(
          stats.difficultyStats[difficulty].correct / stats.difficultyStats[difficulty].total * 100
        );
        
        console.log('Statistics updated:', {
          totalGames: stats.totalGames,
          totalQuestions: stats.totalQuestions,
          correctAnswers: stats.correctAnswers,
          averageScore: stats.averageScore,
          bestScore: stats.bestScore
        });

        // Принудительно сохраняем в localStorage после обновления статистики
        setTimeout(() => {
          try {
            const currentState = get();
            const stateToSave = {
              gameHistory: currentState.gameHistory,
              statistics: currentState.statistics,
              settings: currentState.settings,
              language: currentState.language,
              theme: currentState.theme,
            };
            localStorage.setItem('flags-world-game-store', JSON.stringify({ state: stateToSave, version: 0 }));
            console.log('✅ Statistics forcefully saved to localStorage');
          } catch (error) {
            console.error('❌ Failed to save statistics:', error);
          }
        }, 100);
      }),

      addMistake: (country) => set((state) => {
        if (!state.statistics.mistakeCountries[country.code]) {
          state.statistics.mistakeCountries[country.code] = {
            country,
            mistakes: 0,
            lastMistake: 0,
          };
        }
        state.statistics.mistakeCountries[country.code].mistakes += 1;
        state.statistics.mistakeCountries[country.code].lastMistake = Date.now();
      }),

      getMistakeCountries: () => {
        const mistakes = get().statistics.mistakeCountries;
        return Object.values(mistakes)
          .sort((a, b) => b.mistakes - a.mistakes)
          .map(m => m.country);
      },

      // Settings actions
      updateSettings: (newSettings) => set((state) => {
        state.settings = { ...state.settings, ...newSettings };
      }),

      setLanguage: (language) => set((state) => {
        state.language = language;
      }),

      setTheme: (theme) => set((state) => {
        state.theme = theme;
      }),

      // Utility actions
      setLoading: (loading) => set((state) => {
        state.isLoading = loading;
      }),

      setError: (error) => set((state) => {
        state.error = error;
      }),

      setOnlineStatus: (online) => set((state) => {
        state.isOnline = online;
      }),

      clearData: () => set((state) => {
        state.gameHistory = [];
        state.statistics = defaultStatistics;
        state.currentSession = null;
      }),
    })),
    {
      name: 'flags-world-game-store',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        gameHistory: state.gameHistory,
        statistics: state.statistics,
        settings: state.settings,
        language: state.language,
        theme: state.theme,
        currentSession: state.currentSession,
      }),
      version: 0,
      onRehydrateStorage: () => (state) => {
        console.log('🔄 Rehydrating store from localStorage');
        if (state) {
          console.log('✅ Store rehydrated with statistics:', {
            totalGames: state.statistics.totalGames,
            totalQuestions: state.statistics.totalQuestions,
            correctAnswers: state.statistics.correctAnswers
          });
        }
      },
    }
  )
);

// Helper function to generate questions
function generateQuestions(countries: Country[], settings: GameSettings): GameQuestion[] {
  const questions: GameQuestion[] = [];
  
  // Проверяем, что у нас есть минимум 4 страны для генерации вариантов ответов
  if (countries.length < 4) {
    console.warn('Not enough countries to generate questions. Need at least 4 countries.');
    return [];
  }
  
  // Создаем копию массива стран и перемешиваем
  const shuffledCountries = [...countries].sort(() => Math.random() - 0.5);
  
  // Создаем список стран для вопросов без дублей
  const questionsCountries: Country[] = [];
  
  // Если стран достаточно, берем уникальные страны
  if (shuffledCountries.length >= settings.questionCount) {
    questionsCountries.push(...shuffledCountries.slice(0, settings.questionCount));
  } else {
    // Если стран меньше чем вопросов, сначала добавляем все уникальные
    questionsCountries.push(...shuffledCountries);
    
    // Затем добавляем недостающие, избегая повторов подряд
    const remaining = settings.questionCount - shuffledCountries.length;
    for (let i = 0; i < remaining; i++) {
      // Берем страну, которая не была последней добавленной
      const availableCountries = shuffledCountries.filter(country => 
        questionsCountries[questionsCountries.length - 1]?.code !== country.code
      );
      const randomCountry = availableCountries[Math.floor(Math.random() * availableCountries.length)];
      questionsCountries.push(randomCountry);
    }
  }
  
  // Генерируем вопросы для каждой выбранной страны
  questionsCountries.forEach((country, i) => {
    const questionType = settings.questionTypes[Math.floor(Math.random() * settings.questionTypes.length)];
    
    // Generate wrong options (исключаем текущую страну)
    const availableWrongOptions = shuffledCountries.filter(c => c.code !== country.code);
    const wrongOptions = availableWrongOptions
      .sort(() => Math.random() - 0.5)
      .slice(0, Math.min(3, availableWrongOptions.length));
    
    // Если недостаточно неправильных вариантов, дополняем случайными
    while (wrongOptions.length < 3 && availableWrongOptions.length > 0) {
      const randomOption = availableWrongOptions[Math.floor(Math.random() * availableWrongOptions.length)];
      if (!wrongOptions.find(opt => opt.code === randomOption.code)) {
        wrongOptions.push(randomOption);
      }
    }
    
    const options = [country, ...wrongOptions].sort(() => Math.random() - 0.5);
    
    questions.push({
      id: `${i}-${country.code}-${questionType}-${Date.now()}-${Math.random()}`,
      country,
      options,
      type: questionType,
    });
  });
  
  console.log(`Generated ${questions.length} questions with countries:`, 
    questions.map(q => q.country.name).join(', '));
  
  return questions;
} 