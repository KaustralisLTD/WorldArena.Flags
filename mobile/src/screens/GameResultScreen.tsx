import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Share,
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp } from '@react-navigation/native';
import { RootStackParamList } from '../../App';

type GameResultScreenNavigationProp = StackNavigationProp<RootStackParamList, 'GameResult'>;
type GameResultScreenRouteProp = RouteProp<RootStackParamList, 'GameResult'>;

interface Props {
  navigation: GameResultScreenNavigationProp;
  route: GameResultScreenRouteProp;
}

const GameResultScreen: React.FC<Props> = ({ navigation, route }) => {
  const { score, totalQuestions, correctAnswers, accuracy, duration } = route.params;

  const formatTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const getPerformanceEmoji = (): string => {
    if (accuracy >= 90) return '🏆';
    if (accuracy >= 80) return '🥇';
    if (accuracy >= 70) return '🥈';
    if (accuracy >= 60) return '🥉';
    return '📚';
  };

  const getPerformanceText = (): string => {
    if (accuracy >= 90) return 'Превосходно!';
    if (accuracy >= 80) return 'Отлично!';
    if (accuracy >= 70) return 'Хорошо!';
    if (accuracy >= 60) return 'Неплохо!';
    return 'Есть к чему стремиться!';
  };

  const shareResults = async () => {
    try {
      const message = `🌎 Флаги Мира - Мой результат:\n` +
                     `${getPerformanceEmoji()} ${correctAnswers}/${totalQuestions} правильных ответов\n` +
                     `📊 Точность: ${accuracy}%\n` +
                     `⏱️ Время: ${formatTime(duration)}\n` +
                     `🎯 Очки: ${score}\n\n` +
                     `Попробуй и ты! #FlagsWorld`;

      await Share.share({
        message,
        title: 'Мой результат в игре Флаги Мира',
      });
    } catch (error) {
      console.error('Error sharing:', error);
    }
  };

  const playAgain = () => {
    navigation.navigate('Home');
  };

  const viewStatistics = () => {
    navigation.navigate('Statistics');
  };

  const goHome = () => {
    navigation.navigate('Home');
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.emoji}>{getPerformanceEmoji()}</Text>
        <Text style={styles.performanceText}>{getPerformanceText()}</Text>
        <Text style={styles.subtitle}>Игра завершена!</Text>
      </View>

      {/* Main Results */}
      <View style={styles.resultsCard}>
        <View style={styles.mainScore}>
          <Text style={styles.scoreValue}>{score}</Text>
          <Text style={styles.scoreLabel}>очков</Text>
        </View>

        <View style={styles.resultStats}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{correctAnswers}</Text>
            <Text style={styles.statLabel}>из {totalQuestions}</Text>
            <Text style={styles.statDescription}>правильно</Text>
          </View>

          <View style={styles.statDivider} />

          <View style={styles.statItem}>
            <Text style={styles.statValue}>{accuracy}%</Text>
            <Text style={styles.statLabel}>точность</Text>
          </View>

          <View style={styles.statDivider} />

          <View style={styles.statItem}>
            <Text style={styles.statValue}>{formatTime(duration)}</Text>
            <Text style={styles.statLabel}>время</Text>
          </View>
        </View>
      </View>

      {/* Detailed Results */}
      <View style={styles.detailsCard}>
        <Text style={styles.detailsTitle}>Подробности</Text>

        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Правильные ответы:</Text>
          <Text style={[styles.detailValue, styles.correctText]}>
            ✅ {correctAnswers}
          </Text>
        </View>

        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Неправильные ответы:</Text>
          <Text style={[styles.detailValue, styles.wrongText]}>
            ❌ {totalQuestions - correctAnswers}
          </Text>
        </View>

        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Среднее время на вопрос:</Text>
          <Text style={styles.detailValue}>
            ⏱️ {Math.round(duration / totalQuestions)}с
          </Text>
        </View>

        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Очки за правильный ответ:</Text>
          <Text style={styles.detailValue}>
            🎯 {correctAnswers > 0 ? Math.round(score / correctAnswers) : 0}
          </Text>
        </View>
      </View>

      {/* Achievement Hints */}
      {accuracy < 100 && (
        <View style={styles.hintsCard}>
          <Text style={styles.hintsTitle}>💡 Совет</Text>
          {accuracy < 60 && (
            <Text style={styles.hintText}>
              Попробуйте изучить флаги отдельных регионов для лучшего результата
            </Text>
          )}
          {accuracy >= 60 && accuracy < 80 && (
            <Text style={styles.hintText}>
              Вы на правильном пути! Практикуйтесь чаще для улучшения результата
            </Text>
          )}
          {accuracy >= 80 && accuracy < 100 && (
            <Text style={styles.hintText}>
              Отличный результат! Попробуйте режим "Сложный" для новых вызовов
            </Text>
          )}
        </View>
      )}

      {/* Action Buttons */}
      <View style={styles.actions}>
        <TouchableOpacity style={styles.primaryButton} onPress={playAgain}>
          <Text style={styles.primaryButtonText}>🎮 Играть снова</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.secondaryButton} onPress={shareResults}>
          <Text style={styles.secondaryButtonText}>📤 Поделиться</Text>
        </TouchableOpacity>

        <View style={styles.bottomActions}>
          <TouchableOpacity 
            style={styles.bottomButton} 
            onPress={viewStatistics}
          >
            <Text style={styles.bottomButtonText}>📊 Статистика</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.bottomButton} 
            onPress={goHome}
          >
            <Text style={styles.bottomButtonText}>🏠 На главную</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Продолжайте изучать флаги мира!
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
    paddingVertical: 40,
    paddingHorizontal: 20,
  },
  emoji: {
    fontSize: 64,
    marginBottom: 16,
  },
  performanceText: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2C3E50',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#7F8C8D',
  },
  resultsCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 16,
    paddingVertical: 30,
    paddingHorizontal: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 6,
  },
  mainScore: {
    alignItems: 'center',
    marginBottom: 30,
  },
  scoreValue: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#4A90E2',
  },
  scoreLabel: {
    fontSize: 16,
    color: '#7F8C8D',
    marginTop: 4,
  },
  resultStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2C3E50',
  },
  statLabel: {
    fontSize: 14,
    color: '#7F8C8D',
    marginTop: 4,
  },
  statDescription: {
    fontSize: 12,
    color: '#7F8C8D',
  },
  statDivider: {
    width: 1,
    height: 40,
    backgroundColor: '#E5E5E5',
  },
  detailsCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    paddingVertical: 20,
    paddingHorizontal: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  detailsTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#2C3E50',
    marginBottom: 16,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  detailLabel: {
    fontSize: 14,
    color: '#7F8C8D',
    flex: 1,
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#2C3E50',
  },
  correctText: {
    color: '#28A745',
  },
  wrongText: {
    color: '#DC3545',
  },
  hintsCard: {
    backgroundColor: '#FFF3CD',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderWidth: 1,
    borderColor: '#FFEAA7',
  },
  hintsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#856404',
    marginBottom: 8,
  },
  hintText: {
    fontSize: 14,
    color: '#856404',
    lineHeight: 20,
  },
  actions: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  primaryButton: {
    backgroundColor: '#4A90E2',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#4A90E2',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  secondaryButton: {
    backgroundColor: '#fff',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 16,
    borderWidth: 2,
    borderColor: '#4A90E2',
  },
  secondaryButtonText: {
    color: '#4A90E2',
    fontSize: 16,
    fontWeight: '600',
  },
  bottomActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  bottomButton: {
    flex: 1,
    backgroundColor: '#fff',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 4,
    borderWidth: 1,
    borderColor: '#E5E5E5',
  },
  bottomButtonText: {
    color: '#7F8C8D',
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

export default GameResultScreen; 