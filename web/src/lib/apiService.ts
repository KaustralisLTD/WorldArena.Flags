import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { Country } from './gameStore';
import { getCountryTranslation } from './countryTranslations';

// API Configuration
const REST_COUNTRIES_BASE_URL = 'https://restcountries.com/v3.1';
const BACKEND_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api';

// Cache configuration
const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours
const CACHE_KEY_PREFIX = 'flags-world-cache';

interface CacheItem<T> {
  data: T;
  timestamp: number;
  language: string;
}

interface RestCountryData {
  cca2: string;
  name: {
    common: string;
    official: string;
    nativeName?: Record<string, { official: string; common: string }>;
  };
  flags: {
    png: string;
    svg: string;
    alt?: string;
  };
  region: string;
  subregion?: string;
  capital?: string[];
  population: number;
  area: number;
  languages?: Record<string, string>;
  currencies?: Record<string, { name: string; symbol?: string }>;
  translations?: Record<string, { official: string; common: string }>;
}

class ApiService {
  private restCountriesApi: AxiosInstance;
  private backendApi: AxiosInstance;
  private cache: Map<string, CacheItem<any>> = new Map();

  constructor() {
    // REST Countries API client
    this.restCountriesApi = axios.create({
      baseURL: REST_COUNTRIES_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Backend API client
    this.backendApi = axios.create({
      baseURL: BACKEND_BASE_URL,
      timeout: 15000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Setup interceptors
    this.setupInterceptors();
  }

  private setupInterceptors(): void {
    // Request interceptor for backend API
    this.backendApi.interceptors.request.use(
      (config) => {
        const token = this.getAuthToken();
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    const handleError = (error: any) => {
      if (error.response?.status === 401) {
        this.clearAuthToken();
        // Redirect to login if needed
      }
      
      if (error.code === 'NETWORK_ERROR' || !navigator.onLine) {
        console.warn('Network error, falling back to cache');
        throw new Error('NETWORK_ERROR');
      }
      
      return Promise.reject(error);
    };

    this.restCountriesApi.interceptors.response.use(
      (response) => response,
      handleError
    );

    this.backendApi.interceptors.response.use(
      (response) => response,
      handleError
    );
  }

  // Cache management
  private getCacheKey(key: string, language: string = 'en'): string {
    return `${CACHE_KEY_PREFIX}-${key}-${language}`;
  }

  private getFromCache<T>(key: string, language: string = 'en'): T | null {
    try {
      const cacheKey = this.getCacheKey(key, language);
      const cached = localStorage.getItem(cacheKey);
      
      if (!cached) return null;
      
      const item: CacheItem<T> = JSON.parse(cached);
      const now = Date.now();
      
      if (now - item.timestamp > CACHE_DURATION) {
        localStorage.removeItem(cacheKey);
        return null;
      }
      
      return item.data;
    } catch (error) {
      console.error('Cache read error:', error);
      return null;
    }
  }

  private setCache<T>(key: string, data: T, language: string = 'en'): void {
    try {
      const cacheKey = this.getCacheKey(key, language);
      const item: CacheItem<T> = {
        data,
        timestamp: Date.now(),
        language,
      };
      localStorage.setItem(cacheKey, JSON.stringify(item));
    } catch (error) {
      console.error('Cache write error:', error);
    }
  }

  // Auth token management
  private getAuthToken(): string | null {
    return localStorage.getItem('auth_token');
  }

  private setAuthToken(token: string): void {
    localStorage.setItem('auth_token', token);
  }

  private clearAuthToken(): void {
    localStorage.removeItem('auth_token');
  }

  // Transform REST Countries data to our format
  private transformCountryData(data: RestCountryData, language: string = 'ru'): Country {
    const getTranslatedName = (country: RestCountryData, lang: string): string => {
      // Отладочная информация для украинского языка
      if (lang === 'uk') {
        console.log(`\n=== Ukrainian Translation Debug ===`);
        console.log(`Country: ${country.name.common}`);
        console.log(`Language: ${lang}`);
      }
      
      // Сначала пробуем получить ручной перевод для украинского и каталанского
      const manualTranslation = getCountryTranslation(country.name.common, lang);
      if (manualTranslation) {
        console.log(`Using manual translation for ${country.name.common} (${lang}): ${manualTranslation}`);
        return manualTranslation;
      }
      
      if (lang === 'uk') {
        console.log(`No manual translation found for ${country.name.common}`);
      }
      
      // Правильный маппинг языковых кодов для REST Countries API v3.1
      const langMapping: Record<string, string> = {
        'en': 'eng',  // English
        'es': 'spa',  // Spanish
        'uk': 'ukr',  // Ukrainian
        'ca': 'cat',  // Catalan
        'ru': 'rus',  // Russian
        'zh': 'zho'   // Chinese
      };
      
      const apiLangCode = langMapping[lang] || 'eng';
      
      if (lang === 'uk') {
        console.log(`API language code: ${apiLangCode}`);
        console.log(`Available translations:`, Object.keys(country.translations || {}));
        console.log(`Ukrainian translation from API:`, country.translations?.[apiLangCode]?.common);
        console.log(`=================================\n`);
      }
      
      // Отладочная информация
      if (country.cca2 === 'EG') {
        console.log(`Egypt translation for ${lang} (${apiLangCode}):`, 
          country.translations?.[apiLangCode]?.common || 'not found');
      }
      
      // Пробуем получить перевод из REST Countries API
      if (country.translations && country.translations[apiLangCode]) {
        return country.translations[apiLangCode].common;
      }
      
      // Fallback на английское название
      if (country.translations && country.translations['eng']) {
        return country.translations['eng'].common;
      }
      
      // Последний fallback на оригинальное название
      return country.name.common;
    };

    return {
      code: data.cca2.toLowerCase(),
      name: getTranslatedName(data, language),
      flag: data.flags.svg || data.flags.png,
      region: data.region,
      subregion: data.subregion,
      capital: data.capital,
      population: data.population,
      area: data.area,
      languages: data.languages,
      currencies: data.currencies,
    };
  }

  // Public API methods
  async getAllCountries(language: string = 'ru'): Promise<Country[]> {
    const cacheKey = 'all-countries';
    
    // Try cache first
    const cached = this.getFromCache<Country[]>(cacheKey, language);
    if (cached) {
      console.log(`Using cached countries for language: ${language}`);
      return cached;
    }

    try {
      console.log(`Fetching countries from API for language: ${language}`);
      const response: AxiosResponse<RestCountryData[]> = await this.restCountriesApi.get(
        '/all?fields=name,cca2,flags,translations,region,subregion,capital,population,area'
      );

      const countries = response.data
        .map(country => {
          const transformed = this.transformCountryData(country, language);
          // Отладочная информация для первых 3 стран
          if (response.data.indexOf(country) < 3) {
            console.log(`Country ${country.cca2}: ${country.name.common} -> ${transformed.name} (lang: ${language})`);
          }
          return transformed;
        })
        .filter(country => country.flag && country.name)
        .sort((a, b) => a.name.localeCompare(b.name));

      // Cache the result
      this.setCache(cacheKey, countries, language);
      
      return countries;
    } catch (error) {
      console.error('Failed to fetch countries from API:', error);
      
      // Fallback to static data for testing
      const getFallbackName = (code: string, lang: string): string => {
        const names: Record<string, Record<string, string>> = {
          'ru': { 
            'ru': 'Россия', 'us': 'США', 'de': 'Германия', 'fr': 'Франция', 'gb': 'Великобритания',
            'it': 'Италия', 'es': 'Испания', 'jp': 'Япония', 'cn': 'Китай', 'in': 'Индия',
            'br': 'Бразилия', 'ca': 'Канада', 'au': 'Австралия', 'za': 'ЮАР', 'eg': 'Египет',
            'nz': 'Новая Зеландия', 'fj': 'Фиджи', 'pg': 'Папуа-Новая Гвинея', 'sb': 'Соломоновы Острова',
            'vu': 'Вануату', 'nc': 'Новая Каледония', 'pf': 'Французская Полинезия', 'ws': 'Самоа',
            'to': 'Тонга', 'ki': 'Кирибати', 'pw': 'Палау', 'mh': 'Маршалловы Острова'
          },
          'en': {
            'ru': 'Russia', 'us': 'United States', 'de': 'Germany', 'fr': 'France', 'gb': 'United Kingdom',
            'it': 'Italy', 'es': 'Spain', 'jp': 'Japan', 'cn': 'China', 'in': 'India',
            'br': 'Brazil', 'ca': 'Canada', 'au': 'Australia', 'za': 'South Africa', 'eg': 'Egypt',
            'nz': 'New Zealand', 'fj': 'Fiji', 'pg': 'Papua New Guinea', 'sb': 'Solomon Islands',
            'vu': 'Vanuatu', 'nc': 'New Caledonia', 'pf': 'French Polynesia', 'ws': 'Samoa',
            'to': 'Tonga', 'ki': 'Kiribati', 'pw': 'Palau', 'mh': 'Marshall Islands'
          },
          'es': {
            'ru': 'Rusia', 'us': 'Estados Unidos', 'de': 'Alemania', 'fr': 'Francia', 'gb': 'Reino Unido',
            'it': 'Italia', 'es': 'España', 'jp': 'Japón', 'cn': 'China', 'in': 'India',
            'br': 'Brasil', 'ca': 'Canadá', 'au': 'Australia', 'za': 'Sudáfrica', 'eg': 'Egipto',
            'nz': 'Nueva Zelanda', 'fj': 'Fiyi', 'pg': 'Papúa Nueva Guinea', 'sb': 'Islas Salomón',
            'vu': 'Vanuatu', 'nc': 'Nueva Caledonia', 'pf': 'Polinesia Francesa', 'ws': 'Samoa',
            'to': 'Tonga', 'ki': 'Kiribati', 'pw': 'Palau', 'mh': 'Islas Marshall'
          },
          'uk': {
            'ru': 'Росія', 'us': 'США', 'de': 'Німеччина', 'fr': 'Франція', 'gb': 'Велика Британія',
            'it': 'Італія', 'es': 'Іспанія', 'jp': 'Японія', 'cn': 'Китай', 'in': 'Індія',
            'br': 'Бразилія', 'ca': 'Канада', 'au': 'Австралія', 'za': 'ПАР', 'eg': 'Єгипет',
            'nz': 'Нова Зеландія', 'fj': 'Фіджі', 'pg': 'Папуа-Нова Гвінея', 'sb': 'Соломонові Острови',
            'vu': 'Вануату', 'nc': 'Нова Каледонія', 'pf': 'Французька Полінезія', 'ws': 'Самоа',
            'to': 'Тонга', 'ki': 'Кірібаті', 'pw': 'Палау', 'mh': 'Маршаллові Острови'
          },
          'ca': {
            'ru': 'Rússia', 'us': 'Estats Units', 'de': 'Alemanya', 'fr': 'França', 'gb': 'Regne Unit',
            'it': 'Itàlia', 'es': 'Espanya', 'jp': 'Japó', 'cn': 'Xina', 'in': 'Índia',
            'br': 'Brasil', 'ca': 'Canadà', 'au': 'Austràlia', 'za': 'Sud-àfrica', 'eg': 'Egipte',
            'nz': 'Nova Zelanda', 'fj': 'Fiji', 'pg': 'Papua Nova Guinea', 'sb': 'Illes Salomó',
            'vu': 'Vanuatu', 'nc': 'Nova Caledònia', 'pf': 'Polinèsia Francesa', 'ws': 'Samoa',
            'to': 'Tonga', 'ki': 'Kiribati', 'pw': 'Palau', 'mh': 'Illes Marshall'
          },
          'zh': {
            'ru': '俄罗斯', 'us': '美国', 'de': '德国', 'fr': '法国', 'gb': '英国',
            'it': '意大利', 'es': '西班牙', 'jp': '日本', 'cn': '中国', 'in': '印度',
            'br': '巴西', 'ca': '加拿大', 'au': '澳大利亚', 'za': '南非', 'eg': '埃及',
            'nz': '新西兰', 'fj': '斐济', 'pg': '巴布亚新几内亚', 'sb': '所罗门群岛',
            'vu': '瓦努阿图', 'nc': '新喀里多尼亚', 'pf': '法属波利尼西亚', 'ws': '萨摩亚',
            'to': '汤加', 'ki': '基里巴斯', 'pw': '帕劳', 'mh': '马绍尔群岛'
          }
        };

        return names[lang]?.[code] || names['en']?.[code] || code;
      };

      const fallbackCountries: Country[] = [
        {
          code: 'ru',
          name: getFallbackName('ru', language),
          flag: 'https://flagcdn.com/w320/ru.png',
          region: 'Europe',
          subregion: 'Eastern Europe',
          capital: ['Москва'],
          population: 146171015,
          area: 17098242
        },
        {
          code: 'us',
          name: getFallbackName('us', language),
          flag: 'https://flagcdn.com/w320/us.png',
          region: 'Americas',
          subregion: 'North America',
          capital: ['Вашингтон'],
          population: 329484123,
          area: 9833517
        },
        {
          code: 'de',
          name: getFallbackName('de', language),
          flag: 'https://flagcdn.com/w320/de.png',
          region: 'Europe',
          subregion: 'Western Europe',
          capital: ['Берлин'],
          population: 83240525,
          area: 357114
        },
        {
          code: 'fr',
          name: getFallbackName('fr', language),
          flag: 'https://flagcdn.com/w320/fr.png',
          region: 'Europe',
          subregion: 'Western Europe',
          capital: ['Париж'],
          population: 67391582,
          area: 643801
        },
        {
          code: 'gb',
          name: getFallbackName('gb', language),
          flag: 'https://flagcdn.com/w320/gb.png',
          region: 'Europe',
          subregion: 'Northern Europe',
          capital: ['Лондон'],
          population: 67886011,
          area: 242495
        },
        {
          code: 'it',
          name: getFallbackName('it', language),
          flag: 'https://flagcdn.com/w320/it.png',
          region: 'Europe',
          subregion: 'Southern Europe',
          capital: ['Рим'],
          population: 59554023,
          area: 301336
        },
        {
          code: 'es',
          name: getFallbackName('es', language),
          flag: 'https://flagcdn.com/w320/es.png',
          region: 'Europe',
          subregion: 'Southern Europe',
          capital: ['Мадрид'],
          population: 47351567,
          area: 505992
        },
        {
          code: 'jp',
          name: getFallbackName('jp', language),
          flag: 'https://flagcdn.com/w320/jp.png',
          region: 'Asia',
          subregion: 'Eastern Asia',
          capital: ['Токио'],
          population: 125836021,
          area: 377930
        },
        {
          code: 'cn',
          name: getFallbackName('cn', language),
          flag: 'https://flagcdn.com/w320/cn.png',
          region: 'Asia',
          subregion: 'Eastern Asia',
          capital: ['Пекин'],
          population: 1439323776,
          area: 9596961
        },
        {
          code: 'in',
          name: getFallbackName('in', language),
          flag: 'https://flagcdn.com/w320/in.png',
          region: 'Asia',
          subregion: 'Southern Asia',
          capital: ['Нью-Дели'],
          population: 1380004385,
          area: 3287263
        },
        {
          code: 'br',
          name: getFallbackName('br', language),
          flag: 'https://flagcdn.com/w320/br.png',
          region: 'Americas',
          subregion: 'South America',
          capital: ['Бразилиа'],
          population: 212559417,
          area: 8515767
        },
        {
          code: 'ca',
          name: getFallbackName('ca', language),
          flag: 'https://flagcdn.com/w320/ca.png',
          region: 'Americas',
          subregion: 'North America',
          capital: ['Оттава'],
          population: 38005238,
          area: 9984670
        },
        {
          code: 'au',
          name: getFallbackName('au', language),
          flag: 'https://flagcdn.com/w320/au.png',
          region: 'Oceania',
          subregion: 'Australia and New Zealand',
          capital: ['Канберра'],
          population: 25687041,
          area: 7692024
        },
        {
          code: 'nz',
          name: getFallbackName('nz', language),
          flag: 'https://flagcdn.com/w320/nz.png',
          region: 'Oceania',
          subregion: 'Australia and New Zealand',
          capital: ['Веллингтон'],
          population: 5084300,
          area: 268838
        },
        {
          code: 'fj',
          name: getFallbackName('fj', language),
          flag: 'https://flagcdn.com/w320/fj.png',
          region: 'Oceania',
          subregion: 'Melanesia',
          capital: ['Сува'],
          population: 896444,
          area: 18272
        },
        {
          code: 'pg',
          name: getFallbackName('pg', language),
          flag: 'https://flagcdn.com/w320/pg.png',
          region: 'Oceania',
          subregion: 'Melanesia',
          capital: ['Порт-Морсби'],
          population: 8947027,
          area: 462840
        },
        {
          code: 'sb',
          name: getFallbackName('sb', language),
          flag: 'https://flagcdn.com/w320/sb.png',
          region: 'Oceania',
          subregion: 'Melanesia',
          capital: ['Хониара'],
          population: 686878,
          area: 28896
        },
        {
          code: 'vu',
          name: getFallbackName('vu', language),
          flag: 'https://flagcdn.com/w320/vu.png',
          region: 'Oceania',
          subregion: 'Melanesia',
          capital: ['Порт-Вила'],
          population: 307150,
          area: 12189
        },
        {
          code: 'ws',
          name: getFallbackName('ws', language),
          flag: 'https://flagcdn.com/w320/ws.png',
          region: 'Oceania',
          subregion: 'Polynesia',
          capital: ['Апиа'],
          population: 198410,
          area: 2842
        },
        {
          code: 'to',
          name: getFallbackName('to', language),
          flag: 'https://flagcdn.com/w320/to.png',
          region: 'Oceania',
          subregion: 'Polynesia',
          capital: ['Нукуалофа'],
          population: 105697,
          area: 747
        },
        {
          code: 'ki',
          name: getFallbackName('ki', language),
          flag: 'https://flagcdn.com/w320/ki.png',
          region: 'Oceania',
          subregion: 'Micronesia',
          capital: ['Тарава'],
          population: 119446,
          area: 811
        },
        {
          code: 'pw',
          name: getFallbackName('pw', language),
          flag: 'https://flagcdn.com/w320/pw.png',
          region: 'Oceania',
          subregion: 'Micronesia',
          capital: ['Нгерулмуд'],
          population: 18092,
          area: 459
        },
        {
          code: 'mh',
          name: getFallbackName('mh', language),
          flag: 'https://flagcdn.com/w320/mh.png',
          region: 'Oceania',
          subregion: 'Micronesia',
          capital: ['Маджуро'],
          population: 59194,
          area: 181
        },
        {
          code: 'za',
          name: getFallbackName('za', language),
          flag: 'https://flagcdn.com/w320/za.png',
          region: 'Africa',
          subregion: 'Southern Africa',
          capital: ['Кейптаун', 'Претория', 'Блумфонтейн'],
          population: 59308690,
          area: 1221037
        },
        {
          code: 'eg',
          name: getFallbackName('eg', language),
          flag: 'https://flagcdn.com/w320/eg.png',
          region: 'Africa',
          subregion: 'Northern Africa',
          capital: ['Каир'],
          population: 102334404,
          area: 1002450
        }
      ];
      
      console.log('Using fallback countries data');
      this.setCache(cacheKey, fallbackCountries, language);
      return fallbackCountries;
    }
  }

  async getCountriesByRegion(region: string, language: string = 'ru'): Promise<Country[]> {
    const cacheKey = `region-${region}`;
    
    // Try cache first
    const cached = this.getFromCache<Country[]>(cacheKey, language);
    if (cached) {
      return cached;
    }

    try {
      const response: AxiosResponse<RestCountryData[]> = await this.restCountriesApi.get(
        `/region/${region}?fields=name,cca2,flags,translations,region,subregion,capital,population,area,languages,currencies`
      );

      const countries = response.data
        .map(country => this.transformCountryData(country, language))
        .filter(country => country.flag && country.name)
        .sort((a, b) => a.name.localeCompare(b.name));

      // Cache the result
      this.setCache(cacheKey, countries, language);
      
      return countries;
    } catch (error) {
      console.error(`Failed to fetch countries for region ${region}:`, error);
      
      // Fallback to all countries and filter
      const allCountries = await this.getAllCountries(language);
      return allCountries.filter(country => 
        country.region.toLowerCase() === region.toLowerCase()
      );
    }
  }

  async searchCountries(query: string, language: string = 'ru'): Promise<Country[]> {
    try {
      const response: AxiosResponse<RestCountryData[]> = await this.restCountriesApi.get(
        `/name/${encodeURIComponent(query)}?fields=name,cca2,flags,translations,region,subregion,capital,population,area,languages,currencies`
      );

      return response.data
        .map(country => this.transformCountryData(country, language))
        .filter(country => country.flag && country.name)
        .sort((a, b) => a.name.localeCompare(b.name));
    } catch (error) {
      console.error(`Failed to search countries for query ${query}:`, error);
      
      // Fallback to local search in cached data
      const allCountries = await this.getAllCountries(language);
      return allCountries.filter(country =>
        country.name.toLowerCase().includes(query.toLowerCase())
      );
    }
  }

  // Backend API methods (for user data, statistics, etc.)
  async login(email: string, password: string): Promise<{ token: string; user: any }> {
    try {
      const response = await this.backendApi.post('/auth/login', {
        email,
        password,
      });

      const { token, user } = response.data;
      this.setAuthToken(token);
      
      return { token, user };
    } catch (error) {
      console.error('Login failed:', error);
      throw new Error('Login failed');
    }
  }

  async register(email: string, password: string, name: string): Promise<{ token: string; user: any }> {
    try {
      const response = await this.backendApi.post('/auth/register', {
        email,
        password,
        name,
      });

      const { token, user } = response.data;
      this.setAuthToken(token);
      
      return { token, user };
    } catch (error) {
      console.error('Registration failed:', error);
      throw new Error('Registration failed');
    }
  }

  async logout(): Promise<void> {
    this.clearAuthToken();
  }

  async saveGameResult(gameData: any): Promise<void> {
    try {
      await this.backendApi.post('/games', gameData);
    } catch (error) {
      console.error('Failed to save game result:', error);
      // Store locally for later sync
      this.storeOfflineGameResult(gameData);
    }
  }

  async getUserStatistics(): Promise<any> {
    try {
      const response = await this.backendApi.get('/statistics');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch user statistics:', error);
      return null;
    }
  }

  async syncOfflineData(): Promise<void> {
    try {
      const offlineData = this.getOfflineGameResults();
      if (offlineData.length > 0) {
        await this.backendApi.post('/games/sync', { games: offlineData });
        this.clearOfflineGameResults();
      }
    } catch (error) {
      console.error('Failed to sync offline data:', error);
    }
  }

  // Offline data management
  private storeOfflineGameResult(gameData: any): void {
    try {
      const key = 'offline-game-results';
      const existing = JSON.parse(localStorage.getItem(key) || '[]');
      existing.push({ ...gameData, timestamp: Date.now() });
      localStorage.setItem(key, JSON.stringify(existing));
    } catch (error) {
      console.error('Failed to store offline game result:', error);
    }
  }

  private getOfflineGameResults(): any[] {
    try {
      const key = 'offline-game-results';
      return JSON.parse(localStorage.getItem(key) || '[]');
    } catch (error) {
      console.error('Failed to get offline game results:', error);
      return [];
    }
  }

  private clearOfflineGameResults(): void {
    try {
      localStorage.removeItem('offline-game-results');
    } catch (error) {
      console.error('Failed to clear offline game results:', error);
    }
  }

  // Network status
  isOnline(): boolean {
    return navigator.onLine;
  }

  // Clear all cache
  clearCache(): void {
    try {
      const keys = Object.keys(localStorage);
      keys.forEach(key => {
        if (key.startsWith(CACHE_KEY_PREFIX)) {
          localStorage.removeItem(key);
        }
      });
    } catch (error) {
      console.error('Failed to clear cache:', error);
    }
  }

  // Принудительное обновление стран для конкретного языка
  async forceRefreshCountries(language: string = 'ru'): Promise<Country[]> {
    const cacheKey = 'all-countries';
    
    // Удаляем из кэша данные для этого языка
    try {
      const specificCacheKey = this.getCacheKey(cacheKey, language);
      localStorage.removeItem(specificCacheKey);
      console.log(`Cleared cache for language: ${language}`);
    } catch (error) {
      console.error('Failed to clear specific cache:', error);
    }
    
    // Загружаем данные заново
    return this.getAllCountries(language);
  }
}

// Export singleton instance
export const apiService = new ApiService();
export default apiService; 