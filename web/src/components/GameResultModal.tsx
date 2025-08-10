import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useTranslation } from '../lib/translations';

interface GameResultModalProps {
  isOpen: boolean;
  onClose: () => void;
  score: number;
  totalQuestions: number;
  correctAnswers: number;
  totalTime: number;
  accuracy: number;
  language: string;
  difficulty: string;
  region: string;
}

export default function GameResultModal({
  isOpen,
  onClose,
  score,
  totalQuestions,
  correctAnswers,
  totalTime,
  accuracy,
  language,
  difficulty,
  region
}: GameResultModalProps) {
  const { t } = useTranslation(language);

  const formatTime = (ms: number) => {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const getPerformanceMessage = (accuracy: number) => {
    if (accuracy >= 90) return { message: `🏆 ${t.resultExcellent}`, color: 'text-yellow-500', bg: 'bg-yellow-50' };
    if (accuracy >= 80) return { message: `🎉 ${t.resultGreat}`, color: 'text-green-500', bg: 'bg-green-50' };
    if (accuracy >= 70) return { message: `👍 ${t.resultGood}`, color: 'text-blue-500', bg: 'bg-blue-50' };
    if (accuracy >= 60) return { message: `👌 ${t.resultNotBad}`, color: 'text-purple-500', bg: 'bg-purple-50' };
    return { message: `💪 ${t.resultKeepPracticing}`, color: 'text-orange-500', bg: 'bg-orange-50' };
  };

  const performance = getPerformanceMessage(accuracy);
  const averageTimePerQuestion = totalTime / totalQuestions / 1000;

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50"
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.8, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.8, opacity: 0, y: 20 }}
            transition={{ type: "spring", duration: 0.5 }}
            className="bg-white dark:bg-gray-800 rounded-3xl shadow-2xl max-w-md w-full mx-4 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header with celebration */}
            <div className={`${performance.bg} dark:bg-gray-700 px-8 py-6 text-center relative overflow-hidden`}>
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: "spring" }}
                className="relative z-10"
              >
                <h2 className={`text-3xl font-bold ${performance.color} dark:text-white mb-2`}>
                  {performance.message}
                </h2>
                <p className="text-gray-600 dark:text-gray-300 text-lg">
                  {t.resultGameCompleted}
                </p>
              </motion.div>
              
              {/* Animated background elements */}
              <div className="absolute inset-0 overflow-hidden">
                {[...Array(6)].map((_, i) => (
                  <motion.div
                    key={i}
                    initial={{ scale: 0, rotate: 0 }}
                    animate={{ scale: 1, rotate: 360 }}
                    transition={{ delay: 0.3 + i * 0.1, duration: 1 }}
                    className={`absolute w-4 h-4 ${performance.color.replace('text-', 'bg-')} rounded-full opacity-20`}
                    style={{
                      left: `${20 + i * 15}%`,
                      top: `${20 + (i % 2) * 40}%`,
                    }}
                  />
                ))}
              </div>
            </div>

            {/* Main Results */}
            <div className="px-8 py-6">
              {/* Score Circle */}
              <div className="flex justify-center mb-6">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.4, type: "spring" }}
                  className="relative"
                >
                  <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 120 120">
                    <circle
                      cx="60"
                      cy="60"
                      r="50"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="8"
                      className="text-gray-200 dark:text-gray-600"
                    />
                    <motion.circle
                      cx="60"
                      cy="60"
                      r="50"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="8"
                      strokeLinecap="round"
                      className={performance.color}
                      initial={{ pathLength: 0 }}
                      animate={{ pathLength: accuracy / 100 }}
                      transition={{ delay: 0.5, duration: 1.5, ease: "easeOut" }}
                      style={{
                        strokeDasharray: "314.16",
                        strokeDashoffset: "314.16",
                      }}
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="text-center">
                      <motion.div
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        transition={{ delay: 0.6 }}
                        className="text-3xl font-bold text-gray-900 dark:text-white"
                      >
                        {Math.round(accuracy)}%
                      </motion.div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        {correctAnswers}/{totalQuestions}
                      </div>
                    </div>
                  </div>
                </motion.div>
              </div>

              {/* Detailed Stats */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 }}
                className="space-y-4"
              >
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-gray-50 dark:bg-gray-700 rounded-xl p-4 text-center">
                    <div className="text-2xl font-bold text-gray-900 dark:text-white">
                      {score}
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {t.resultPoints}
                    </div>
                  </div>
                  <div className="bg-gray-50 dark:bg-gray-700 rounded-xl p-4 text-center">
                    <div className="text-2xl font-bold text-gray-900 dark:text-white">
                      {formatTime(totalTime)}
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {t.resultTime}
                    </div>
                  </div>
                </div>

                <div className="bg-gray-50 dark:bg-gray-700 rounded-xl p-4">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-gray-600 dark:text-gray-400">{t.resultDifficulty}:</span>
                    <span className="font-semibold text-gray-900 dark:text-white capitalize">
                      {difficulty}
                    </span>
                  </div>
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-gray-600 dark:text-gray-400">{t.resultRegion}:</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {region === 'all' ? t.resultAllWorld : region}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">{t.resultAverageTime}:</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {averageTimePerQuestion.toFixed(1)}с
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* Action Buttons */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.8 }}
                className="flex gap-3 mt-6"
              >
                <button
                  onClick={onClose}
                  className="flex-1 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold py-3 px-6 rounded-xl hover:from-blue-600 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:scale-105"
                >
                  🏠 {t.resultToHome}
                </button>
                <button
                  onClick={() => window.location.reload()}
                  className="flex-1 bg-gradient-to-r from-green-500 to-teal-600 text-white font-semibold py-3 px-6 rounded-xl hover:from-green-600 hover:to-teal-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:scale-105"
                >
                  🔄 {t.resultPlayAgain}
                </button>
              </motion.div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
} 