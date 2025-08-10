import { useGameStore } from '../src/lib/gameStore';
import { useTranslation } from '../src/lib/translations';
import Layout from '../src/components/Layout';
import { GameSession } from '../src/lib/gameStore';
import { useEffect, useState } from 'react';

export default function Leaderboard() {
  const { gameHistory, language } = useGameStore();
  const { t } = useTranslation(language);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  // Don't render until client-side hydration is complete
  if (!isClient) {
    return (
      <Layout title={t.leaderboard} showBackButton>
        <div className="container mx-auto px-4 py-8">
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🏆</div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Загрузка рейтинга...
            </h2>
          </div>
        </div>
      </Layout>
    );
  }

  // Create leaderboard from game history
  const leaderboardData = gameHistory
    .filter((game: GameSession) => game.isCompleted)
    .sort((a: GameSession, b: GameSession) => b.score - a.score)
    .slice(0, 50) // Top 50 scores
    .map((game: GameSession, index: number) => ({
      rank: index + 1,
      score: game.score,
      date: new Date(game.startTime).toLocaleDateString(),
      time: new Date(game.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      region: game.settings.region,
      difficulty: game.settings.difficulty,
      gameMode: game.settings.gameMode,
      accuracy: game.answers.length > 0 ? 
        Math.round((game.answers.filter((a: any) => a.isCorrect).length / game.answers.length) * 100) : 0,
    }));

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'easy': return 'text-green-600 dark:text-green-400';
      case 'medium': return 'text-yellow-600 dark:text-yellow-400';
      case 'hard': return 'text-red-600 dark:text-red-400';
      case 'expert': return 'text-purple-600 dark:text-purple-400';
      case 'erudite': return 'text-pink-600 dark:text-pink-400';
      default: return 'text-gray-600 dark:text-gray-400';
    }
  };

  const getGameModeIcon = (mode: string) => {
    switch (mode) {
      case 'classic': return '🎯';
      case 'time-attack': return '⚡';
      case 'survival': return '💪';
      case 'mistakes': return '🔄';
      default: return '🎮';
    }
  };

  return (
    <Layout title={t.leaderboard} showBackButton>
      <div className="container mx-auto px-4 py-8">
        {leaderboardData.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🏆</div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Пока нет результатов
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Сыграйте несколько игр, чтобы увидеть свои лучшие результаты
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {/* Header */}
            <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm">
              <div className="grid grid-cols-12 gap-4 text-sm font-semibold text-gray-600 dark:text-gray-400">
                <div className="col-span-1">{t.rank}</div>
                <div className="col-span-1">{t.score}</div>
                <div className="col-span-1">{t.accuracy}</div>
                <div className="col-span-2">{t.region}</div>
                <div className="col-span-2">{t.difficulty}</div>
                <div className="col-span-2">{t.mode}</div>
                <div className="col-span-2">{t.date}</div>
                <div className="col-span-1">{t.gameTime}</div>
              </div>
            </div>

            {/* Leaderboard entries */}
            {leaderboardData.map((entry: any) => (
              <div 
                key={`${entry.rank}-${entry.date}-${entry.time}`}
                className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow"
              >
                <div className="grid grid-cols-12 gap-4 items-center">
                  {/* Rank */}
                  <div className="col-span-1">
                    <div className={`text-lg font-bold ${
                      entry.rank === 1 ? 'text-yellow-500' :
                      entry.rank === 2 ? 'text-gray-400' :
                      entry.rank === 3 ? 'text-orange-600' :
                      'text-gray-600 dark:text-gray-400'
                    }`}>
                      {entry.rank === 1 ? '🥇' :
                       entry.rank === 2 ? '🥈' :
                       entry.rank === 3 ? '🥉' :
                       `#${entry.rank}`}
                    </div>
                  </div>

                  {/* Score */}
                  <div className="col-span-1">
                    <div className="text-xl font-bold text-primary-600 dark:text-primary-400">
                      {entry.score}
                    </div>
                  </div>

                  {/* Accuracy */}
                  <div className="col-span-1">
                    <div className="text-lg font-semibold text-green-600 dark:text-green-400">
                      {entry.accuracy}%
                    </div>
                  </div>

                  {/* Region */}
                  <div className="col-span-2">
                    <div className="text-sm font-medium text-gray-700 dark:text-gray-300 capitalize">
                      {entry.region === 'all' ? t.allRegions : entry.region}
                    </div>
                  </div>

                  {/* Difficulty */}
                  <div className="col-span-2">
                    <div className={`text-sm font-medium capitalize ${getDifficultyColor(entry.difficulty)}`}>
                      {entry.difficulty === 'easy' ? t.easy :
                       entry.difficulty === 'medium' ? t.medium : 
                       entry.difficulty === 'hard' ? t.hard :
                       entry.difficulty === 'expert' ? t.expert :
                       entry.difficulty === 'erudite' ? t.erudite : entry.difficulty}
                    </div>
                  </div>

                  {/* Game Mode */}
                  <div className="col-span-2">
                    <div className="flex items-center space-x-2">
                      <span>{getGameModeIcon(entry.gameMode)}</span>
                      <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                        {entry.gameMode === 'classic' ? t.classic :
                         entry.gameMode === 'time-attack' ? t.timeAttack :
                         entry.gameMode === 'survival' ? t.survival : t.mistakes}
                      </span>
                    </div>
                  </div>

                  {/* Date */}
                  <div className="col-span-2">
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      {entry.date}
                    </div>
                  </div>

                  {/* Time */}
                  <div className="col-span-1">
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      {entry.time}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
} 