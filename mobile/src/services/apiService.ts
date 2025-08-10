import axios, { AxiosInstance, AxiosResponse } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_CONFIG, STORAGE_KEYS } from '../config/api';

// Types
export interface Country {
  id: string;
  code: string;
  name: string;
  region: string;
  subregion?: string;
  flag_url: string;
  capital?: string;
  population?: number;
  area?: number;
}

export interface User {
  id: string;
  email: string;
  username: string;
  preferredLanguage: string;
  createdAt: string;
  lastActive?: string;
}

export interface GameSession {
  id: string;
  totalQuestions: number;
  regions: string[];
  gameMode: string;
  difficulty: string;
  startedAt: string;
}

export interface GameResult {
  score: number;
  totalQuestions: number;
  correctAnswers: number;
  accuracy: number;
  durationSeconds: number;
}

export interface Statistics {
  totalGames: number;
  bestScore: number;
  totalCorrectAnswers: number;
  totalQuestions: number;
  accuracy: number;
  totalMistakes?: number;
}

// REST Countries API response interface
interface RestCountryResponse {
  name: {
    common: string;
    official: string;
    nativeName?: Record<string, { official: string; common: string }>;
  };
  cca2: string;
  cca3: string;
  region: string;
  subregion?: string;
  capital?: string[];
  population: number;
  area: number;
  flags: {
    png: string;
    svg: string;
    alt?: string;
  };
  translations?: Record<string, { official: string; common: string }>;
}

class ApiService {
  private axiosInstance: AxiosInstance;
  private restCountriesApi: AxiosInstance;
  private countriesCache: Country[] | null = null;
  private cacheTimestamp: number = 0;
  private readonly CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

  constructor() {
    // Main API instance for backend
    this.axiosInstance = axios.create({
      baseURL: API_CONFIG.BASE_URL,
      timeout: API_CONFIG.TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // REST Countries API instance
    this.restCountriesApi = axios.create({
      baseURL: 'https://restcountries.com/v3.1',
      timeout: 15000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor for main API
    this.axiosInstance.interceptors.request.use(
      async (config) => {
        try {
          const token = await AsyncStorage.getItem(STORAGE_KEYS.AUTH_TOKEN);
          if (token) {
            config.headers.Authorization = `Bearer ${token}`;
          } else {
            // Add session ID for anonymous users
            const sessionId = await this.getOrCreateSessionId();
            config.headers['X-Session-ID'] = sessionId;
          }
        } catch (error) {
          console.error('Error setting auth headers:', error);
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.axiosInstance.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Token expired, clear auth data
          await AsyncStorage.multiRemove([
            STORAGE_KEYS.AUTH_TOKEN,
            STORAGE_KEYS.USER_PREFERENCES,
          ]);
        }
        return Promise.reject(error);
      }
    );

    // REST Countries API interceptor for retry logic
    this.restCountriesApi.interceptors.response.use(
      (response) => response,
      async (error) => {
        const config = error.config;
        if (!config._retry && error.response?.status >= 500) {
          config._retry = true;
          await new Promise(resolve => setTimeout(resolve, 1000));
          return this.restCountriesApi.request(config);
        }
        return Promise.reject(error);
      }
    );
  }

  private async getOrCreateSessionId(): Promise<string> {
    try {
      let sessionId = await AsyncStorage.getItem(STORAGE_KEYS.SESSION_ID);
      if (!sessionId) {
        sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        await AsyncStorage.setItem(STORAGE_KEYS.SESSION_ID, sessionId);
      }
      return sessionId;
    } catch (error) {
      console.error('Error managing session ID:', error);
      return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
  }

  private transformRestCountryToCountry(restCountry: RestCountryResponse, language: string = 'en'): Country {
    // Get translated name if available
    let name = restCountry.name.common;
    if (language !== 'en' && restCountry.translations?.[language]) {
      name = restCountry.translations[language].common;
    }

    return {
      id: restCountry.cca3,
      code: restCountry.cca2,
      name,
      region: restCountry.region,
      subregion: restCountry.subregion,
      flag_url: restCountry.flags.svg || restCountry.flags.png,
      capital: restCountry.capital?.[0],
      population: restCountry.population,
      area: restCountry.area,
    };
  }

  private async loadCountriesFromRestAPI(language: string = 'en'): Promise<Country[]> {
    try {
      const response: AxiosResponse<RestCountryResponse[]> = await this.restCountriesApi.get(
        '/all?fields=name,cca2,cca3,region,subregion,capital,population,area,flags,translations'
      );

      const countries = response.data
        .filter(country => country.flags?.svg || country.flags?.png) // Only countries with flags
        .map(country => this.transformRestCountryToCountry(country, language))
        .sort((a, b) => a.name.localeCompare(b.name));

      // Cache countries data
      this.countriesCache = countries;
      this.cacheTimestamp = Date.now();
      
      // Store in AsyncStorage for offline access
      await AsyncStorage.setItem(
        `${STORAGE_KEYS.COUNTRIES_CACHE}_${language}`,
        JSON.stringify({ countries, timestamp: this.cacheTimestamp })
      );

      return countries;
    } catch (error) {
      console.error('Error loading countries from REST API:', error);
      
      // Try to load from cache
      try {
        const cachedData = await AsyncStorage.getItem(`${STORAGE_KEYS.COUNTRIES_CACHE}_${language}`);
        if (cachedData) {
          const { countries } = JSON.parse(cachedData);
          return countries;
        }
      } catch (cacheError) {
        console.error('Error loading from cache:', cacheError);
      }
      
      throw new Error('Failed to load countries data');
    }
  }

  private async getCachedCountries(language: string = 'en'): Promise<Country[] | null> {
    // Check memory cache first
    if (this.countriesCache && (Date.now() - this.cacheTimestamp) < this.CACHE_DURATION) {
      return this.countriesCache;
    }

    // Check AsyncStorage cache
    try {
      const cachedData = await AsyncStorage.getItem(`${STORAGE_KEYS.COUNTRIES_CACHE}_${language}`);
      if (cachedData) {
        const { countries, timestamp } = JSON.parse(cachedData);
        if ((Date.now() - timestamp) < this.CACHE_DURATION) {
          this.countriesCache = countries;
          this.cacheTimestamp = timestamp;
          return countries;
        }
      }
    } catch (error) {
      console.error('Error reading cache:', error);
    }

    return null;
  }

  // Auth methods
  async register(userData: {
    email: string;
    username: string;
    password: string;
    preferredLanguage?: string;
  }) {
    try {
      const response = await this.axiosInstance.post('/api/auth/register', userData);
      
      if (response.data.token) {
        await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, response.data.token);
      }
      
      return response.data;
    } catch (error) {
      console.error('Registration error:', error);
      throw error;
    }
  }

  async login(credentials: { email: string; password: string }) {
    try {
      const response = await this.axiosInstance.post('/api/auth/login', credentials);
      
      if (response.data.token) {
        await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, response.data.token);
      }
      
      return response.data;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }

  async getProfile() {
    try {
      const response = await this.axiosInstance.get('/api/auth/profile');
      return response.data;
    } catch (error) {
      console.error('Get profile error:', error);
      throw error;
    }
  }

  async updateProfile(updates: { username?: string; preferredLanguage?: string }) {
    try {
      const response = await this.axiosInstance.put('/api/auth/profile', updates);
      return response.data;
    } catch (error) {
      console.error('Update profile error:', error);
      throw error;
    }
  }

  // Countries methods
  async getCountries(params: {
    regions?: string[];
    language?: string;
    limit?: number;
  } = {}): Promise<{ countries: Country[]; total: number }> {
    try {
      const { language = 'en', regions, limit } = params;
      
      // Try to get from cache first
      let countries = await this.getCachedCountries(language);
      
      // If not in cache, load from API
      if (!countries) {
        countries = await this.loadCountriesFromRestAPI(language);
      }

      // Filter by regions if specified
      if (regions && regions.length > 0 && !regions.includes('all')) {
        countries = countries.filter(country => 
          regions.some(region => 
            region.toLowerCase() === country.region.toLowerCase()
          )
        );
      }

      // Apply limit if specified
      if (limit && limit > 0) {
        countries = countries.slice(0, limit);
      }

      return {
        countries,
        total: countries.length,
      };
    } catch (error) {
      console.error('Error getting countries:', error);
      throw error;
    }
  }

  async getCountriesForGame(params: {
    regions?: string[];
    language?: string;
    count?: number;
    difficulty?: string;
  } = {}): Promise<{ countries: Country[]; total: number; type: string }> {
    try {
      const { regions, language = 'en', count = 20, difficulty = 'medium' } = params;

      // Handle mistakes region
      if (regions?.includes('mistakes')) {
        const { mistakes } = await this.getMistakes({ language });
        return {
          countries: mistakes.slice(0, count),
          total: mistakes.length,
          type: 'mistakes',
        };
      }

      // Get countries based on regions
      const { countries: allCountries } = await this.getCountries({ regions, language });

      // Filter by difficulty
      let filteredCountries = allCountries;
      if (difficulty === 'easy') {
        // Large countries (population > 10M)
        filteredCountries = allCountries.filter(c => (c.population || 0) > 10000000);
      } else if (difficulty === 'hard') {
        // Small countries (population < 5M)
        filteredCountries = allCountries.filter(c => (c.population || 0) < 5000000);
      }

      // Shuffle and select required count
      const shuffled = filteredCountries.sort(() => Math.random() - 0.5);
      const selectedCountries = shuffled.slice(0, count);

      return {
        countries: selectedCountries,
        total: selectedCountries.length,
        type: 'game',
      };
    } catch (error) {
      console.error('Error getting countries for game:', error);
      throw error;
    }
  }

  async getCountryDetails(id: string, language?: string): Promise<{ country: Country }> {
    try {
      const { countries } = await this.getCountries({ language });
      const country = countries.find(c => c.id === id || c.code === id);
      
      if (!country) {
        throw new Error('Country not found');
      }

      return { country };
    } catch (error) {
      console.error('Error getting country details:', error);
      throw error;
    }
  }

  async searchCountries(query: string, params?: {
    language?: string;
    limit?: number;
  }): Promise<{ countries: Country[]; total: number }> {
    try {
      const { language = 'en', limit = 50 } = params || {};
      const { countries } = await this.getCountries({ language });

      const searchResults = countries.filter(country =>
        country.name.toLowerCase().includes(query.toLowerCase()) ||
        country.capital?.toLowerCase().includes(query.toLowerCase()) ||
        country.region.toLowerCase().includes(query.toLowerCase())
      ).slice(0, limit);

      return {
        countries: searchResults,
        total: searchResults.length,
      };
    } catch (error) {
      console.error('Error searching countries:', error);
      throw error;
    }
  }

  // Game methods
  async startGame(gameConfig: {
    regions: string[];
    gameMode?: string;
    difficulty?: string;
  }): Promise<{ game: GameSession }> {
    try {
      const response = await this.axiosInstance.post('/api/games/start', gameConfig);
      return response.data;
    } catch (error) {
      console.error('Error starting game:', error);
      
      // Fallback: create local game session
      const game: GameSession = {
        id: `local_${Date.now()}`,
        totalQuestions: parseInt(gameConfig.gameMode || '20'),
        regions: gameConfig.regions,
        gameMode: gameConfig.gameMode || '20',
        difficulty: gameConfig.difficulty || 'medium',
        startedAt: new Date().toISOString(),
      };
      
      return { game };
    }
  }

  async finishGame(gameData: {
    gameId: string;
    score: number;
    totalQuestions: number;
    correctAnswers: number;
    durationSeconds: number;
    answers: Array<{
      countryId: string;
      selectedCountryId: string;
      isCorrect: boolean;
      answerTimeMs: number;
      questionNumber: number;
    }>;
  }): Promise<{ gameResults: GameResult; userStatistics: Statistics }> {
    try {
      const response = await this.axiosInstance.post('/api/games/finish', gameData);
      return response.data;
    } catch (error) {
      console.error('Error finishing game:', error);
      
      // Fallback: create local results
      const gameResults: GameResult = {
        score: gameData.score,
        totalQuestions: gameData.totalQuestions,
        correctAnswers: gameData.correctAnswers,
        accuracy: (gameData.correctAnswers / gameData.totalQuestions) * 100,
        durationSeconds: gameData.durationSeconds,
      };

      const userStatistics: Statistics = {
        totalGames: 1,
        bestScore: gameData.score,
        totalCorrectAnswers: gameData.correctAnswers,
        totalQuestions: gameData.totalQuestions,
        accuracy: gameResults.accuracy,
      };

      return { gameResults, userStatistics };
    }
  }

  async getGameHistory(params?: {
    limit?: number;
    offset?: number;
  }) {
    try {
      const response = await this.axiosInstance.get('/api/games/history', { params });
      return response.data;
    } catch (error) {
      console.error('Error getting game history:', error);
      return { games: [], pagination: {} };
    }
  }

  async getGameDetails(gameId: string) {
    try {
      const response = await this.axiosInstance.get(`/api/games/${gameId}`);
      return response.data;
    } catch (error) {
      console.error('Error getting game details:', error);
      throw error;
    }
  }

  // Statistics methods
  async getStatistics(): Promise<{ statistics: Statistics }> {
    try {
      const response = await this.axiosInstance.get('/api/statistics');
      return response.data;
    } catch (error) {
      console.error('Error getting statistics:', error);
      
      // Fallback: return default statistics
      const statistics: Statistics = {
        totalGames: 0,
        bestScore: 0,
        totalCorrectAnswers: 0,
        totalQuestions: 0,
        accuracy: 0,
      };
      
      return { statistics };
    }
  }

  async getMistakes(params?: {
    language?: string;
    limit?: number;
  }): Promise<{ mistakes: Country[]; total: number }> {
    try {
      const response = await this.axiosInstance.get('/api/statistics/mistakes', { params });
      return response.data;
    } catch (error) {
      console.error('Error getting mistakes:', error);
      return { mistakes: [], total: 0 };
    }
  }

  async deleteMistake(countryId: string) {
    try {
      const response = await this.axiosInstance.delete(`/api/statistics/mistakes/${countryId}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting mistake:', error);
      throw error;
    }
  }

  async getRegionStatistics() {
    try {
      const response = await this.axiosInstance.get('/api/statistics/regions');
      return response.data;
    } catch (error) {
      console.error('Error getting region statistics:', error);
      return { regionStatistics: [] };
    }
  }

  async getPerformanceData(limit?: number) {
    try {
      const response = await this.axiosInstance.get('/api/statistics/performance', {
        params: { limit },
      });
      return response.data;
    } catch (error) {
      console.error('Error getting performance data:', error);
      return { recentGames: [], trends: {} };
    }
  }

  async getLeaderboard(params?: {
    limit?: number;
    type?: 'best_score' | 'accuracy' | 'total_games';
  }) {
    try {
      const response = await this.axiosInstance.get('/api/statistics/leaderboard', { params });
      return response.data;
    } catch (error) {
      console.error('Error getting leaderboard:', error);
      return { leaderboard: [] };
    }
  }
}

export const apiService = new ApiService(); 