import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';
import { useGameStore } from '../stores/gameStore';
import { GAME_CONFIG } from '../config/api';

type HomeScreenNavigationProp = StackNavigationProp<RootStackParamList, 'Home'>;

interface Props {
  navigation: HomeScreenNavigationProp;
}

const HomeScreen: React.FC<Props> = ({ navigation }) => {
  const gameStore = useGameStore();
  const gameState = gameStore.getState();
  
  const [selectedRegions, setSelectedRegions] = useState<string[]>(gameState.selectedRegions);
  const [selectedMode, setSelectedMode] = useState(gameState.gameMode);
  const [selectedDifficulty, setSelectedDifficulty] = useState(gameState.difficulty);

  const regionOptions = [
    { key: GAME_CONFIG.REGIONS.ALL, label: 'Все регионы', icon: '🌍' },
    { key: GAME_CONFIG.REGIONS.EUROPE, label: 'Европа', icon: '🇪🇺' },
    { key: GAME_CONFIG.REGIONS.ASIA, label: 'Азия', icon: '🇯🇵' },
    { key: GAME_CONFIG.REGIONS.AFRICA, label: 'Африка', icon: '🇿🇦' },
    { key: GAME_CONFIG.REGIONS.AMERICAS, label: 'Америка', icon: '🇺🇸' },
    { key: GAME_CONFIG.REGIONS.OCEANIA, label: 'Океания', icon: '🇦🇺' },
    { key: GAME_CONFIG.REGIONS.MISTAKES, label: 'Мои ошибки', icon: '❌' },
  ];

  const modeOptions = [
    { key: GAME_CONFIG.MODES.TWENTY, label: '20 флагов' },
    { key: GAME_CONFIG.MODES.FIFTY, label: '50 флагов' },
    { key: GAME_CONFIG.MODES.HUNDRED, label: '100 флагов' },
    { key: GAME_CONFIG.MODES.ALL, label: 'Все флаги' },
  ];

  const difficultyOptions = [
    { key: GAME_CONFIG.DIFFICULTIES.EASY, label: 'Легкий', description: 'Крупные страны' },
    { key: GAME_CONFIG.DIFFICULTIES.MEDIUM, label: 'Средний', description: 'Все страны' },
    { key: GAME_CONFIG.DIFFICULTIES.HARD, label: 'Сложный', description: 'Малые страны' },
  ];

  const toggleRegion = (regionKey: string) => {
    if (regionKey === GAME_CONFIG.REGIONS.ALL) {
      setSelectedRegions([GAME_CONFIG.REGIONS.ALL]);
    } else {
      let newRegions = selectedRegions.filter(r => r !== GAME_CONFIG.REGIONS.ALL);
      
      if (newRegions.includes(regionKey)) {
        newRegions = newRegions.filter(r => r !== regionKey);
      } else {
        newRegions.push(regionKey);
      }

      if (newRegions.length === 0) {
        newRegions = [GAME_CONFIG.REGIONS.ALL];
      }

      setSelectedRegions(newRegions);
    }
  };

  const startGame = async () => {
    try {
      // Update game configuration
      gameStore.setGameConfig({
        regions: selectedRegions,
        gameMode: selectedMode,
        difficulty: selectedDifficulty,
      });

      // Navigate to game screen
      navigation.navigate('Game');
    } catch (error) {
      Alert.alert('Ошибка', 'Не удалось начать игру. Попробуйте еще раз.');
    }
  };

  const navigateToStatistics = () => {
    navigation.navigate('Statistics');
  };

  const navigateToSettings = () => {
    navigation.navigate('Settings');
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>🌎 Флаги Мира</Text>
        <Text style={styles.subtitle}>Изучайте флаги стран мира!</Text>
      </View>

      {/* Region Selection */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Выберите регионы</Text>
        {regionOptions.map((region) => (
          <TouchableOpacity
            key={region.key}
            style={styles.option}
            onPress={() => toggleRegion(region.key)}
          >
            <View style={styles.optionLeft}>
              <Text style={styles.optionIcon}>{region.icon}</Text>
              <Text style={styles.optionText}>{region.label}</Text>
            </View>
            <Switch
              value={selectedRegions.includes(region.key)}
              onValueChange={() => toggleRegion(region.key)}
              trackColor={{ false: '#E5E5E5', true: '#4A90E2' }}
              thumbColor={selectedRegions.includes(region.key) ? '#fff' : '#f4f3f4'}
            />
          </TouchableOpacity>
        ))}
      </View>

      {/* Game Mode Selection */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Режим игры</Text>
        {modeOptions.map((mode) => (
          <TouchableOpacity
            key={mode.key}
            style={[
              styles.modeOption,
              selectedMode === mode.key && styles.selectedModeOption
            ]}
            onPress={() => setSelectedMode(mode.key)}
          >
            <Text style={[
              styles.modeText,
              selectedMode === mode.key && styles.selectedModeText
            ]}>
              {mode.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Difficulty Selection */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Сложность</Text>
        {difficultyOptions.map((difficulty) => (
          <TouchableOpacity
            key={difficulty.key}
            style={[
              styles.difficultyOption,
              selectedDifficulty === difficulty.key && styles.selectedDifficultyOption
            ]}
            onPress={() => setSelectedDifficulty(difficulty.key)}
          >
            <Text style={[
              styles.difficultyText,
              selectedDifficulty === difficulty.key && styles.selectedDifficultyText
            ]}>
              {difficulty.label}
            </Text>
            <Text style={styles.difficultyDescription}>
              {difficulty.description}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Action Buttons */}
      <View style={styles.actions}>
        <TouchableOpacity style={styles.startButton} onPress={startGame}>
          <Text style={styles.startButtonText}>🎮 Начать игру</Text>
        </TouchableOpacity>

        <View style={styles.secondaryActions}>
          <TouchableOpacity 
            style={styles.secondaryButton} 
            onPress={navigateToStatistics}
          >
            <Text style={styles.secondaryButtonText}>📊 Статистика</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.secondaryButton} 
            onPress={navigateToSettings}
          >
            <Text style={styles.secondaryButtonText}>⚙️ Настройки</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Учите флаги стран и проверяйте свои знания!
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    alignItems: 'center',
    paddingVertical: 30,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#2C3E50',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#7F8C8D',
    textAlign: 'center',
  },
  section: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    paddingVertical: 20,
    paddingHorizontal: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#2C3E50',
    marginBottom: 16,
  },
  option: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  optionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  optionIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  optionText: {
    fontSize: 16,
    color: '#2C3E50',
  },
  modeOption: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#E5E5E5',
    marginBottom: 8,
  },
  selectedModeOption: {
    borderColor: '#4A90E2',
    backgroundColor: '#E8F4FD',
  },
  modeText: {
    fontSize: 16,
    color: '#2C3E50',
    textAlign: 'center',
  },
  selectedModeText: {
    color: '#4A90E2',
    fontWeight: '600',
  },
  difficultyOption: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#E5E5E5',
    marginBottom: 8,
  },
  selectedDifficultyOption: {
    borderColor: '#4A90E2',
    backgroundColor: '#E8F4FD',
  },
  difficultyText: {
    fontSize: 16,
    color: '#2C3E50',
    fontWeight: '600',
    marginBottom: 4,
  },
  selectedDifficultyText: {
    color: '#4A90E2',
  },
  difficultyDescription: {
    fontSize: 14,
    color: '#7F8C8D',
  },
  actions: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  startButton: {
    backgroundColor: '#4A90E2',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 16,
    shadowColor: '#4A90E2',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },
  startButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  secondaryActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  secondaryButton: {
    flex: 1,
    backgroundColor: '#fff',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 4,
    borderWidth: 1,
    borderColor: '#E5E5E5',
  },
  secondaryButtonText: {
    color: '#4A90E2',
    fontSize: 14,
    fontWeight: '600',
  },
  footer: {
    alignItems: 'center',
    paddingVertical: 20,
    paddingHorizontal: 20,
  },
  footerText: {
    fontSize: 14,
    color: '#7F8C8D',
    textAlign: 'center',
  },
});

export default HomeScreen; 