import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';
import { useGameStore } from '../stores/gameStore';
import { Country, Statistics } from '../services/apiService';

type StatisticsScreenNavigationProp = StackNavigationProp<RootStackParamList, 'Statistics'>;

interface Props {
  navigation: StatisticsScreenNavigationProp;
}

const StatisticsScreen: React.FC<Props> = ({ navigation }) => {
  const gameStore = useGameStore();
  const [gameState, setGameState] = useState(gameStore.getState());
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedTab, setSelectedTab] = useState<'overview' | 'mistakes'>('overview');

  useEffect(() => {
    const unsubscribe = gameStore.subscribe(() => {
      setGameState(gameStore.getState());
    });

    loadData();
    return unsubscribe;
  }, []);

  const loadData = async () => {
    try {
      await Promise.all([
        gameStore.loadStatistics(),
        gameStore.loadMistakes(),
      ]);
    } catch (error) {
      console.error('Error loading statistics:', error);
    }
  };

  const onRefresh = async () => {
    setIsRefreshing(true);
    await loadData();
    setIsRefreshing(false);
  };

  const handleDeleteMistake = async (country: Country) => {
    Alert.alert(
      'Удалить ошибку?',
      `Убрать "${country.name}" из списка ошибок?`,
      [
        { text: 'Отмена', style: 'cancel' },
        {
          text: 'Удалить',
          style: 'destructive',
          onPress: async () => {
            try {
              // await apiService.deleteMistake(country.id);
              await gameStore.loadMistakes();
            } catch (error) {
              Alert.alert('Ошибка', 'Не удалось удалить ошибку');
            }
          },
        },
      ]
    );
  };

  const playMistakesGame = () => {
    if (gameState.mistakes.length === 0) {
      Alert.alert('Нет ошибок', 'У вас пока нет ошибок для изучения!');
      return;
    }

    gameStore.setGameConfig({
      regions: ['mistakes'],
      gameMode: '20',
      difficulty: 'medium',
    });

    navigation.navigate('Game');
  };

  const renderOverviewTab = () => {
    const stats = gameState.userStatistics;

    if (!stats) {
      return (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateText}>📊</Text>
          <Text style={styles.emptyStateTitle}>Нет данных</Text>
          <Text style={styles.emptyStateDescription}>
            Сыграйте первую игру, чтобы увидеть статистику
          </Text>
        </View>
      );
    }

    return (
      <ScrollView>
        {/* Overall Stats */}
        <View style={styles.statsCard}>
          <Text style={styles.cardTitle}>Общая статистика</Text>
          
          <View style={styles.statRow}>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>{stats.totalGames}</Text>
              <Text style={styles.statLabel}>игр сыграно</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>{stats.bestScore}</Text>
              <Text style={styles.statLabel}>лучший результат</Text>
            </View>
          </View>

          <View style={styles.statRow}>
            <View style={styles.statItem}>
              <Text style={[styles.statValue, styles.accuracyValue]}>
                {Math.round(stats.accuracy)}%
              </Text>
              <Text style={styles.statLabel}>точность</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>{stats.totalCorrectAnswers}</Text>
              <Text style={styles.statLabel}>правильных ответов</Text>
            </View>
          </View>
        </View>

        {/* Progress Card */}
        <View style={styles.progressCard}>
          <Text style={styles.cardTitle}>Ваш прогресс</Text>
          
          <View style={styles.progressItem}>
            <Text style={styles.progressLabel}>Точность ответов</Text>
            <View style={styles.progressBar}>
              <View 
                style={[
                  styles.progressFill, 
                  { width: `${Math.min(stats.accuracy, 100)}%` }
                ]} 
              />
            </View>
            <Text style={styles.progressValue}>{Math.round(stats.accuracy)}%</Text>
          </View>

          <View style={styles.progressItem}>
            <Text style={styles.progressLabel}>Изучено стран</Text>
            <View style={styles.progressBar}>
              <View 
                style={[
                  styles.progressFill, 
                  { width: `${Math.min((stats.totalCorrectAnswers / 195) * 100, 100)}%` }
                ]} 
              />
            </View>
            <Text style={styles.progressValue}>
              {Math.round((stats.totalCorrectAnswers / 195) * 100)}%
            </Text>
          </View>
        </View>

        {/* Achievements */}
        <View style={styles.achievementsCard}>
          <Text style={styles.cardTitle}>Достижения</Text>
          
          <View style={styles.achievementsList}>
            <View style={[
              styles.achievement,
              stats.totalGames >= 1 && styles.achievementUnlocked
            ]}>
              <Text style={styles.achievementIcon}>🎯</Text>
              <View style={styles.achievementContent}>
                <Text style={styles.achievementTitle}>Первые шаги</Text>
                <Text style={styles.achievementDescription}>Сыграть первую игру</Text>
              </View>
              <Text style={styles.achievementStatus}>
                {stats.totalGames >= 1 ? '✅' : '🔒'}
              </Text>
            </View>

            <View style={[
              styles.achievement,
              stats.accuracy >= 80 && styles.achievementUnlocked
            ]}>
              <Text style={styles.achievementIcon}>🎖️</Text>
              <View style={styles.achievementContent}>
                <Text style={styles.achievementTitle}>Знаток флагов</Text>
                <Text style={styles.achievementDescription}>Достичь 80% точности</Text>
              </View>
              <Text style={styles.achievementStatus}>
                {stats.accuracy >= 80 ? '✅' : '🔒'}
              </Text>
            </View>

            <View style={[
              styles.achievement,
              stats.totalGames >= 10 && styles.achievementUnlocked
            ]}>
              <Text style={styles.achievementIcon}>🏆</Text>
              <View style={styles.achievementContent}>
                <Text style={styles.achievementTitle}>Опытный игрок</Text>
                <Text style={styles.achievementDescription}>Сыграть 10 игр</Text>
              </View>
              <Text style={styles.achievementStatus}>
                {stats.totalGames >= 10 ? '✅' : '🔒'}
              </Text>
            </View>
          </View>
        </View>
      </ScrollView>
    );
  };

  const renderMistakesTab = () => {
    if (gameState.mistakes.length === 0) {
      return (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateText}>✅</Text>
          <Text style={styles.emptyStateTitle}>Нет ошибок!</Text>
          <Text style={styles.emptyStateDescription}>
            У вас пока нет неправильных ответов. Продолжайте в том же духе!
          </Text>
        </View>
      );
    }

    return (
      <ScrollView>
        <View style={styles.mistakesHeader}>
          <Text style={styles.mistakesTitle}>
            Ваши ошибки ({gameState.mistakes.length})
          </Text>
          <Text style={styles.mistakesDescription}>
            Изучите флаги, с которыми у вас возникли сложности
          </Text>
          
          <TouchableOpacity style={styles.playMistakesButton} onPress={playMistakesGame}>
            <Text style={styles.playMistakesButtonText}>
              🎮 Играть с ошибками
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.mistakesList}>
          {gameState.mistakes.map((country) => (
            <TouchableOpacity 
              key={country.id}
              style={styles.mistakeItem}
              onPress={() => handleDeleteMistake(country)}
            >
              <View style={styles.countryFlag}>
                <Text style={styles.flagEmoji}>🏴</Text>
              </View>
              
              <View style={styles.countryInfo}>
                <Text style={styles.countryName}>{country.name}</Text>
                <Text style={styles.countryRegion}>{country.region}</Text>
              </View>

              <TouchableOpacity 
                style={styles.deleteButton}
                onPress={() => handleDeleteMistake(country)}
              >
                <Text style={styles.deleteButtonText}>✕</Text>
              </TouchableOpacity>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
    );
  };

  return (
    <View style={styles.container}>
      {/* Tab Navigation */}
      <View style={styles.tabBar}>
        <TouchableOpacity
          style={[styles.tab, selectedTab === 'overview' && styles.activeTab]}
          onPress={() => setSelectedTab('overview')}
        >
          <Text style={[
            styles.tabText,
            selectedTab === 'overview' && styles.activeTabText
          ]}>
            📊 Обзор
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tab, selectedTab === 'mistakes' && styles.activeTab]}
          onPress={() => setSelectedTab('mistakes')}
        >
          <Text style={[
            styles.tabText,
            selectedTab === 'mistakes' && styles.activeTabText
          ]}>
            ❌ Ошибки ({gameState.mistakes.length})
          </Text>
        </TouchableOpacity>
      </View>

      {/* Tab Content */}
      <View style={styles.tabContent}>
        <ScrollView
          style={styles.scrollView}
          refreshControl={
            <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
          }
        >
          {selectedTab === 'overview' ? renderOverviewTab() : renderMistakesTab()}
        </ScrollView>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5E5',
  },
  tab: {
    flex: 1,
    paddingVertical: 16,
    alignItems: 'center',
  },
  activeTab: {
    borderBottomWidth: 2,
    borderBottomColor: '#4A90E2',
  },
  tabText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#7F8C8D',
  },
  activeTabText: {
    color: '#4A90E2',
  },
  tabContent: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 60,
    paddingHorizontal: 40,
  },
  emptyStateText: {
    fontSize: 64,
    marginBottom: 20,
  },
  emptyStateTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#2C3E50',
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontSize: 16,
    color: '#7F8C8D',
    textAlign: 'center',
    lineHeight: 22,
  },
  statsCard: {
    backgroundColor: '#fff',
    margin: 20,
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 6,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2C3E50',
    marginBottom: 20,
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 20,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#4A90E2',
  },
  accuracyValue: {
    color: '#28A745',
  },
  statLabel: {
    fontSize: 14,
    color: '#7F8C8D',
    marginTop: 4,
  },
  progressCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  progressItem: {
    marginBottom: 20,
  },
  progressLabel: {
    fontSize: 14,
    color: '#7F8C8D',
    marginBottom: 8,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#E5E5E5',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 4,
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4A90E2',
    borderRadius: 4,
  },
  progressValue: {
    fontSize: 12,
    color: '#4A90E2',
    fontWeight: '600',
    textAlign: 'right',
  },
  achievementsCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  achievementsList: {
    marginTop: 8,
  },
  achievement: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
    opacity: 0.5,
  },
  achievementUnlocked: {
    opacity: 1,
  },
  achievementIcon: {
    fontSize: 24,
    marginRight: 16,
  },
  achievementContent: {
    flex: 1,
  },
  achievementTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
  },
  achievementDescription: {
    fontSize: 14,
    color: '#7F8C8D',
    marginTop: 2,
  },
  achievementStatus: {
    fontSize: 16,
  },
  mistakesHeader: {
    padding: 20,
  },
  mistakesTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#2C3E50',
    marginBottom: 8,
  },
  mistakesDescription: {
    fontSize: 14,
    color: '#7F8C8D',
    marginBottom: 16,
    lineHeight: 20,
  },
  playMistakesButton: {
    backgroundColor: '#4A90E2',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    alignItems: 'center',
  },
  playMistakesButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  mistakesList: {
    paddingHorizontal: 20,
  },
  mistakeItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  countryFlag: {
    width: 50,
    height: 36,
    backgroundColor: '#F0F0F0',
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  flagEmoji: {
    fontSize: 24,
  },
  countryInfo: {
    flex: 1,
  },
  countryName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
  },
  countryRegion: {
    fontSize: 14,
    color: '#7F8C8D',
    marginTop: 2,
  },
  deleteButton: {
    width: 32,
    height: 32,
    backgroundColor: '#E74C3C',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deleteButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});

export default StatisticsScreen; 