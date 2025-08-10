import NetInfo from '@react-native-community/netinfo';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '../config/api';

export interface NetworkState {
  isConnected: boolean;
  isInternetReachable: boolean | null;
  type: string;
}

class NetworkService {
  private listeners: Array<(state: NetworkState) => void> = [];
  private currentState: NetworkState = {
    isConnected: false,
    isInternetReachable: null,
    type: 'unknown',
  };

  constructor() {
    this.initialize();
  }

  private async initialize() {
    // Get initial network state
    const state = await NetInfo.fetch();
    this.updateState(state);

    // Subscribe to network state changes
    NetInfo.addEventListener(this.handleNetworkChange);
  }

  private handleNetworkChange = (state: any) => {
    this.updateState(state);
  };

  private updateState(netInfoState: any) {
    const newState: NetworkState = {
      isConnected: netInfoState.isConnected ?? false,
      isInternetReachable: netInfoState.isInternetReachable,
      type: netInfoState.type || 'unknown',
    };

    this.currentState = newState;
    this.notifyListeners(newState);
  }

  private notifyListeners(state: NetworkState) {
    this.listeners.forEach(listener => {
      try {
        listener(state);
      } catch (error) {
        console.error('Error in network listener:', error);
      }
    });
  }

  // Public methods
  getState(): NetworkState {
    return this.currentState;
  }

  isOnline(): boolean {
    return this.currentState.isConnected && this.currentState.isInternetReachable !== false;
  }

  isOffline(): boolean {
    return !this.isOnline();
  }

  subscribe(listener: (state: NetworkState) => void): () => void {
    this.listeners.push(listener);
    
    // Return unsubscribe function
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  // Offline data management
  async saveOfflineData(key: string, data: any): Promise<void> {
    try {
      const offlineData = await this.getOfflineData();
      offlineData[key] = {
        data,
        timestamp: Date.now(),
      };
      
      await AsyncStorage.setItem(
        STORAGE_KEYS.OFFLINE_GAMES,
        JSON.stringify(offlineData)
      );
    } catch (error) {
      console.error('Error saving offline data:', error);
    }
  }

  async getOfflineData(): Promise<Record<string, any>> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.OFFLINE_GAMES);
      return data ? JSON.parse(data) : {};
    } catch (error) {
      console.error('Error getting offline data:', error);
      return {};
    }
  }

  async clearOfflineData(): Promise<void> {
    try {
      await AsyncStorage.removeItem(STORAGE_KEYS.OFFLINE_GAMES);
    } catch (error) {
      console.error('Error clearing offline data:', error);
    }
  }

  async syncOfflineData(): Promise<void> {
    if (this.isOffline()) {
      console.log('Cannot sync offline data: no internet connection');
      return;
    }

    try {
      const offlineData = await this.getOfflineData();
      const keys = Object.keys(offlineData);

      if (keys.length === 0) {
        return;
      }

      console.log(`Syncing ${keys.length} offline items...`);

      // TODO: Implement actual sync logic with backend
      // For now, just clear the offline data after "sync"
      await this.clearOfflineData();
      
      console.log('Offline data synced successfully');
    } catch (error) {
      console.error('Error syncing offline data:', error);
    }
  }

  // Network retry utility
  async retryWithBackoff<T>(
    operation: () => Promise<T>,
    maxRetries: number = 3,
    baseDelay: number = 1000
  ): Promise<T> {
    let lastError: Error;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error as Error;
        
        if (attempt === maxRetries) {
          break;
        }

        // Check if we should retry (network errors)
        if (this.isOffline()) {
          throw new Error('No internet connection');
        }

        // Exponential backoff
        const delay = baseDelay * Math.pow(2, attempt);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    throw lastError!;
  }

  // Check if a request should be cached
  shouldCache(url: string): boolean {
    // Cache country data and flags
    return url.includes('restcountries.com') || 
           url.includes('/countries') ||
           url.includes('flags');
  }

  // Get cache key for a request
  getCacheKey(url: string, params?: any): string {
    const paramString = params ? JSON.stringify(params) : '';
    return `cache_${url}_${paramString}`;
  }
}

export const networkService = new NetworkService(); 