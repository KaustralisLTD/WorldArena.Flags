import { useState, useEffect } from 'react';
import { networkService, NetworkState } from '../services/networkService';

export const useNetworkStatus = () => {
  const [networkState, setNetworkState] = useState<NetworkState>(
    networkService.getState()
  );

  useEffect(() => {
    const unsubscribe = networkService.subscribe(setNetworkState);
    return unsubscribe;
  }, []);

  return {
    isOnline: networkService.isOnline(),
    isOffline: networkService.isOffline(),
    networkState,
    retryWithBackoff: networkService.retryWithBackoff.bind(networkService),
  };
}; 