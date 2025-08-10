// API Configuration
export const API_CONFIG = {
  BASE_URL: 'http://localhost:3000', // В production будет https://api.flagsworld.com
  TIMEOUT: 30000,
  RETRY_ATTEMPTS: 3,
};

// Storage Keys
export const STORAGE_KEYS = {
  AUTH_TOKEN: 'auth_token',
  SESSION_ID: 'session_id',
  USER_PREFERENCES: 'user_preferences',
  GAME_STATISTICS: 'game_statistics',
  OFFLINE_GAMES: 'offline_games',
  LANGUAGE: 'selected_language',
  THEME: 'selected_theme',
  COUNTRIES_CACHE: 'countries_cache',
};

// API Endpoints
export const API_ENDPOINTS = {
  // Auth
  REGISTER: '/api/auth/register',
  LOGIN: '/api/auth/login',
  PROFILE: '/api/auth/profile',
  
  // Countries
  COUNTRIES: '/api/countries',
  COUNTRIES_FOR_GAME: '/api/countries/for-game',
  COUNTRY_DETAILS: (id: string) => `/api/countries/${id}`,
  SEARCH_COUNTRIES: (query: string) => `/api/countries/search/${query}`,
  
  // Games
  START_GAME: '/api/games/start',
  FINISH_GAME: '/api/games/finish',
  GAME_HISTORY: '/api/games/history',
  GAME_DETAILS: (id: string) => `/api/games/${id}`,
  
  // Statistics
  STATISTICS: '/api/statistics',
  MISTAKES: '/api/statistics/mistakes',
  REGION_STATS: '/api/statistics/regions',
  PERFORMANCE: '/api/statistics/performance',
  LEADERBOARD: '/api/statistics/leaderboard',
  DELETE_MISTAKE: (countryId: string) => `/api/statistics/mistakes/${countryId}`,
};

// Game Configuration
export const GAME_CONFIG = {
  MODES: {
    TWENTY: '20',
    FIFTY: '50',
    HUNDRED: '100',
    ALL: 'all',
  },
  DIFFICULTIES: {
    EASY: 'easy',
    MEDIUM: 'medium',
    HARD: 'hard',
  },
  REGIONS: {
    ALL: 'all',
    EUROPE: 'Europe',
    ASIA: 'Asia',
    AFRICA: 'Africa',
    AMERICAS: 'Americas',
    OCEANIA: 'Oceania',
    MISTAKES: 'mistakes',
  },
  DEFAULT_ANSWER_TIME: 15, // seconds
  POINTS_PER_CORRECT: 10,
  TIME_BONUS_MULTIPLIER: 1.5,
};

// Language Configuration
export const LANGUAGE_CONFIG = {
  SUPPORTED_LANGUAGES: ['en', 'ru', 'es', 'uk', 'ca', 'zh'],
  DEFAULT_LANGUAGE: 'en',
  FALLBACK_LANGUAGE: 'en',
};

// Theme Configuration
export const THEME_CONFIG = {
  THEMES: {
    LIGHT: 'light',
    DARK: 'dark',
    SYSTEM: 'system',
  },
  DEFAULT_THEME: 'system',
};

// Mock storage functions for now
export const getAuthToken = async (): Promise<string | null> => {
  // TODO: Implement with AsyncStorage
  return null;
};

export const getSessionId = async (): Promise<string> => {
  // TODO: Implement with AsyncStorage  
  return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

export const clearAuthData = async (): Promise<void> => {
  // TODO: Implement with AsyncStorage
  console.log('Clear auth data called');
}; 