import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  ActivityIndicator,
  Dimensions,
} from 'react-native';

interface Props {
  flagUrl: string;
  countryName: string;
  width?: number;
  height?: number;
  style?: any;
}

const { width: screenWidth } = Dimensions.get('window');

const FlagImage: React.FC<Props> = ({
  flagUrl,
  countryName,
  width = screenWidth * 0.7,
  height = (screenWidth * 0.7) * 0.6, // 3:2 aspect ratio
  style,
}) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const handleLoadStart = () => {
    setLoading(true);
    setError(false);
  };

  const handleLoadEnd = () => {
    setLoading(false);
  };

  const handleError = () => {
    setLoading(false);
    setError(true);
  };

  if (error || !flagUrl) {
    return (
      <View style={[styles.container, { width, height }, style]}>
        <View style={styles.fallback}>
          <Text style={styles.fallbackEmoji}>🏴</Text>
          <Text style={styles.fallbackText}>{countryName}</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.container, { width, height }, style]}>
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4A90E2" />
          <Text style={styles.loadingText}>Загрузка флага...</Text>
        </View>
      )}
      
      <Image
        source={{ uri: flagUrl }}
        style={[styles.flag, { width, height }]}
        onLoadStart={handleLoadStart}
        onLoadEnd={handleLoadEnd}
        onError={handleError}
        resizeMode="cover"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#fff',
    borderRadius: 12,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
  flag: {
    borderRadius: 12,
  },
  loadingContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8F9FA',
    zIndex: 1,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: '#7F8C8D',
  },
  fallback: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F0F0F0',
    width: '100%',
    height: '100%',
  },
  fallbackEmoji: {
    fontSize: 48,
    marginBottom: 8,
  },
  fallbackText: {
    fontSize: 14,
    color: '#7F8C8D',
    textAlign: 'center',
    paddingHorizontal: 16,
  },
});

export default FlagImage; 