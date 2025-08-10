import { useGameStore } from '../src/lib/gameStore';
import { useTranslation } from '../src/lib/translations';
import Layout from '../src/components/Layout';
import { useEffect, useState } from 'react';

export default function Statistics() {
  const { statistics, language } = useGameStore();
  const { t } = useTranslation(language);
  const [isClient, setIsClient] = useState(false);

  // Отладочная информация
  useEffect(() => {
    setIsClient(true);
    console.log('Statistics page loaded');
    console.log('Current statistics:', statistics);
    if (typeof window !== 'undefined') {
      console.log('localStorage content:', localStorage.getItem('flags-world-game-store'));
    }
  }, [statistics]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    const secsStr = secs < 10 ? '0' + secs : secs.toString();
    return `${mins}:${secsStr}`;
  };

  const formatPercentage = (value: number) => {
    return `${Math.round(value)}%`;
  };

  const handleNavigation = (path: string) => {
    if (typeof window !== 'undefined') {
      window.location.href = window.location.origin + path;
    }
  };

  // Don't render statistics until client-side hydration is complete
  if (!isClient) {
    return (
      <Layout title={t.statistics} showBackButton>
        <div className="container mx-auto px-4 py-8">
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📊</div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Загрузка статистики...
            </h2>
          </div>
        </div>
      </Layout>
    );
  }

  // Check if there are any statistics to show
  const hasStatistics = statistics.totalGames > 0;

  return (
    <Layout title={t.statistics} showBackButton>
      <div className="container mx-auto px-4 py-8">
        {!hasStatistics ? (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📊</div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Пока нет статистики
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Сыграйте несколько игр, чтобы увидеть свою статистику
            </p>
            <button
              onClick={() => handleNavigation('/game/')}
              className="bg-primary-500 hover:bg-primary-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
            >
              Начать игру
            </button>
          </div>
        ) : (
          <>
            {/* Overall Statistics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-primary-600 dark:text-primary-400">
                  {statistics.totalGames}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.totalGames}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                  {statistics.totalQuestions}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.totalQuestions}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {statistics.correctAnswers}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.correctAnswers}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                  {formatPercentage(statistics.totalQuestions > 0 ? (statistics.correctAnswers / statistics.totalQuestions) * 100 : 0)}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.accuracy}</div>
              </div>
            </div>

            {/* Score Statistics */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-orange-600 dark:text-orange-400">
                  {Math.round(statistics.averageScore)}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.averageScore}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-yellow-600 dark:text-yellow-400">
                  {statistics.bestScore}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.bestScore}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-red-600 dark:text-red-400">
                  {formatTime(Math.round(statistics.averageTime))}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.averageTime}</div>
              </div>
            </div>

            {/* Streak Statistics */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-indigo-600 dark:text-indigo-400">
                  {statistics.streakCurrent}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.currentStreak}</div>
              </div>
              
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <div className="text-2xl font-bold text-pink-600 dark:text-pink-400">
                  {statistics.streakBest}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">{t.bestStreak}</div>
              </div>
            </div>

            {/* Region Statistics */}
            {Object.keys(statistics.regionStats).length > 0 && (
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm mb-8">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
                  {t.regionStats}
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {Object.keys(statistics.regionStats).map((region) => {
                    const stats = statistics.regionStats[region];
                    return (
                      <div key={region} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                        <div className="font-semibold text-gray-900 dark:text-white capitalize mb-2">
                          {region}
                        </div>
                        <div className="space-y-1 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.games}:</span>
                            <span className="font-medium">{stats.games}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.accuracy}:</span>
                            <span className="font-medium">{formatPercentage(stats.accuracy)}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.correct}:</span>
                            <span className="font-medium">{stats.correct}/{stats.total}</span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Difficulty Statistics */}
            {Object.keys(statistics.difficultyStats).length > 0 && (
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
                  {t.difficultyStats}
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {Object.keys(statistics.difficultyStats).map((difficulty) => {
                    const stats = statistics.difficultyStats[difficulty];
                    return (
                      <div key={difficulty} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                        <div className="font-semibold text-gray-900 dark:text-white capitalize mb-2">
                          {difficulty === 'easy' ? t.easy : difficulty === 'medium' ? t.medium : t.hard}
                        </div>
                        <div className="space-y-1 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.games}:</span>
                            <span className="font-medium">{stats.games}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.accuracy}:</span>
                            <span className="font-medium">{formatPercentage(stats.accuracy)}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600 dark:text-gray-400">{t.correct}:</span>
                            <span className="font-medium">{stats.correct}/{stats.total}</span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </Layout>
  );
} 