import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Dimensions,
  ActivityIndicator,
  Image,
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp } from '@react-navigation/native';
import { RootStackParamList } from '../../App';
import { useGameStore } from '../stores/gameStore';
import { Country } from '../services/apiService';

type GameScreenNavigationProp = StackNavigationProp<RootStackParamList, 'Game'>;
type GameScreenRouteProp = RouteProp<RootStackParamList, 'Game'>;

interface Props {
  navigation: GameScreenNavigationProp;
  route: GameScreenRouteProp;
}

const { width } = Dimensions.get('window');

const GameScreen: React.FC<Props> = ({ navigation }) => {
  const gameStore = useGameStore();
  const [gameState, setGameState] = useState(gameStore.getState());
  const [selectedAnswer, setSelectedAnswer] = useState<string | null>(null);
  const [showResult, setShowResult] = useState(false);
  const [timeLeft, setTimeLeft] = useState(15);

  useEffect(() => {
    // Subscribe to game store changes
    const unsubscribe = gameStore.subscribe(() => {
      setGameState(gameStore.getState());
    });

    // Start the game when component mounts
    startGame();

    return unsubscribe;
  }, []);

  useEffect(() => {
    // Timer logic
    if (gameState.isGameActive && timeLeft > 0 && !showResult) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && !showResult) {
      // Time's up - automatically select wrong answer
      handleTimeUp();
    }
  }, [timeLeft, gameState.isGameActive, showResult]);

  const startGame = async () => {
    try {
      await gameStore.startNewGame();
    } catch (error) {
      Alert.alert('Ошибка', 'Не удалось загрузить игру');
      navigation.goBack();
    }
  };

  const handleAnswerSelect = (country: Country) => {
    if (selectedAnswer || !gameState.isGameActive) return;

    setSelectedAnswer(country.id);
    setShowResult(true);

    // Process the answer
    gameStore.selectAnswer(country);

    // Show result for 2 seconds then continue
    setTimeout(() => {
      if (gameState.currentQuestion + 1 >= (gameState.currentGame?.totalQuestions || 20)) {
        // Game finished
        finishGame();
      } else {
        setSelectedAnswer(null);
        setShowResult(false);
        setTimeLeft(15);
      }
    }, 2000);
  };

  const handleTimeUp = () => {
    if (!gameState.currentCountry) return;

    // Select a random wrong answer when time is up
    const wrongAnswers = gameState.answerOptions.filter(
      option => option.id !== gameState.currentCountry?.id
    );
    if (wrongAnswers.length > 0) {
      handleAnswerSelect(wrongAnswers[0]);
    }
  };

  const finishGame = async () => {
    try {
      const results = await gameStore.finishGame();
      navigation.navigate('GameResult', {
        score: gameState.score,
        totalQuestions: gameState.currentGame?.totalQuestions || 20,
        correctAnswers: gameState.gameAnswers.filter(a => a.isCorrect).length,
        accuracy: Math.round((gameState.gameAnswers.filter(a => a.isCorrect).length / (gameState.currentGame?.totalQuestions || 20)) * 100),
        duration: Math.floor((Date.now() - (gameState.startTime || Date.now())) / 1000),
      });
    } catch (error) {
      Alert.alert('Ошибка', 'Не удалось завершить игру');
    }
  };

  const exitGame = () => {
    Alert.alert(
      'Выйти из игры?',
      'Весь прогресс будет потерян',
      [
        { text: 'Отмена', style: 'cancel' },
        {
          text: 'Выйти',
          style: 'destructive',
          onPress: () => {
            gameStore.resetGame();
            navigation.goBack();
          },
        },
      ]
    );
  };

  const getAnswerButtonStyle = (country: Country) => {
    if (!showResult) {
      return selectedAnswer === country.id ? styles.selectedAnswer : styles.answerButton;
    }

    if (country.id === gameState.currentCountry?.id) {
      return styles.correctAnswer;
    } else if (selectedAnswer === country.id) {
      return styles.wrongAnswer;
    }
    return styles.answerButton;
  };

  const getAnswerTextStyle = (country: Country) => {
    if (!showResult) {
      return selectedAnswer === country.id ? styles.selectedAnswerText : styles.answerText;
    }

    if (country.id === gameState.currentCountry?.id) {
      return styles.correctAnswerText;
    } else if (selectedAnswer === country.id) {
      return styles.wrongAnswerText;
    }
    return styles.answerText;
  };

  if (gameState.isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4A90E2" />
        <Text style={styles.loadingText}>Загрузка игры...</Text>
      </View>
    );
  }

  if (!gameState.currentCountry || !gameState.isGameActive) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Подготовка вопроса...</Text>
      </View>
    );
  }

  const progress = ((gameState.currentQuestion + 1) / (gameState.currentGame?.totalQuestions || 20)) * 100;

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.exitButton} onPress={exitGame}>
          <Text style={styles.exitButtonText}>✕</Text>
        </TouchableOpacity>

        <View style={styles.gameInfo}>
          <Text style={styles.questionCounter}>
            {gameState.currentQuestion + 1} / {gameState.currentGame?.totalQuestions}
          </Text>
          <Text style={styles.score}>Очки: {gameState.score}</Text>
        </View>

        <View style={styles.timer}>
          <Text style={[styles.timerText, timeLeft <= 5 && styles.timerWarning]}>
            {timeLeft}s
          </Text>
        </View>
      </View>

      {/* Progress Bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${progress}%` }]} />
        </View>
      </View>

      {/* Flag Display */}
      <View style={styles.flagContainer}>
        <View style={styles.flagCard}>
          {gameState.currentCountry?.flag_url ? (
            <Image
              source={{ uri: gameState.currentCountry.flag_url }}
              style={styles.flagImage}
              onError={() => console.log('Flag load error')}
            />
          ) : (
            <>
              <Text style={styles.flagEmoji}>🏴</Text>
              <Text style={styles.flagText}>Флаг загружается...</Text>
            </>
          )}
        </View>
        
        <Text style={styles.question}>
          Какая это страна?
        </Text>
      </View>

      {/* Answer Options */}
      <View style={styles.answersContainer}>
        {gameState.answerOptions.map((country, index) => (
          <TouchableOpacity
            key={country.id}
            style={getAnswerButtonStyle(country)}
            onPress={() => handleAnswerSelect(country)}
            disabled={showResult}
          >
            <Text style={getAnswerTextStyle(country)}>
              {country.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Result Display */}
      {showResult && (
        <View style={styles.resultContainer}>
          <Text style={[
            styles.resultText,
            selectedAnswer === gameState.currentCountry?.id ? styles.correctResult : styles.wrongResult
          ]}>
            {selectedAnswer === gameState.currentCountry?.id ? '✅ Правильно!' : '❌ Неправильно!'}
          </Text>
          {selectedAnswer !== gameState.currentCountry?.id && (
            <Text style={styles.correctAnswerResult}>
              Правильный ответ: {gameState.currentCountry?.name}
            </Text>
          )}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8F9FA',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#7F8C8D',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5E5',
  },
  exitButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#E74C3C',
    justifyContent: 'center',
    alignItems: 'center',
  },
  exitButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  gameInfo: {
    alignItems: 'center',
  },
  questionCounter: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
  },
  score: {
    fontSize: 14,
    color: '#7F8C8D',
  },
  timer: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#4A90E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  timerText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  timerWarning: {
    color: '#E74C3C',
  },
  progressContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  progressBar: {
    height: 6,
    backgroundColor: '#E5E5E5',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4A90E2',
    borderRadius: 3,
  },
  flagContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  flagCard: {
    width: width * 0.7,
    height: width * 0.5,
    backgroundColor: '#fff',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 6,
    marginBottom: 24,
  },
  flagEmoji: {
    fontSize: 80,
    marginBottom: 12,
  },
  flagText: {
    fontSize: 16,
    color: '#7F8C8D',
  },
  flagImage: {
    width: '100%',
    height: '100%',
    borderRadius: 16,
  },
  question: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2C3E50',
    textAlign: 'center',
  },
  answersContainer: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  answerButton: {
    backgroundColor: '#fff',
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 2,
    borderColor: '#E5E5E5',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  selectedAnswer: {
    backgroundColor: '#E8F4FD',
    borderColor: '#4A90E2',
  },
  correctAnswer: {
    backgroundColor: '#D5EDDA',
    borderColor: '#28A745',
  },
  wrongAnswer: {
    backgroundColor: '#F8D7DA',
    borderColor: '#DC3545',
  },
  answerText: {
    fontSize: 16,
    color: '#2C3E50',
    textAlign: 'center',
    fontWeight: '500',
  },
  selectedAnswerText: {
    color: '#4A90E2',
    fontWeight: '600',
  },
  correctAnswerText: {
    color: '#28A745',
    fontWeight: '600',
  },
  wrongAnswerText: {
    color: '#DC3545',
    fontWeight: '600',
  },
  resultContainer: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 8,
  },
  resultText: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  correctResult: {
    color: '#28A745',
  },
  wrongResult: {
    color: '#DC3545',
  },
  correctAnswerResult: {
    fontSize: 14,
    color: '#7F8C8D',
    textAlign: 'center',
  },
});

export default GameScreen; 