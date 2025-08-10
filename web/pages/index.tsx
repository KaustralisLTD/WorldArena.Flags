import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import Head from 'next/head';
import { useGameStore } from '../src/lib/gameStore';
import { apiService } from '../src/lib/apiService';
import { useTranslation } from '../src/lib/translations';
import Layout from '../src/components/Layout';
import toast from 'react-hot-toast';

export default function HomePage() {
  const { 
    settings, 
    updateSettings, 
    setCountries, 
    startGame, 
    isLoading, 
    setLoading,
    getMistakeCountries,
    language,
    countries
  } = useGameStore();
  const { t } = useTranslation(language);

  const [selectedRegion, setSelectedRegion] = useState(settings.region);
  const [selectedDifficulty, setSelectedDifficulty] = useState(settings.difficulty);
  const [selectedGameMode, setSelectedGameMode] = useState(settings.gameMode);

  const regions = [
    { id: 'all', name: t.allRegions, emoji: '🌍' },
    { id: 'Europe', name: t.europe, emoji: '🇪🇺' },
    { id: 'Asia', name: t.asia, emoji: '🌏' },
    { id: 'Africa', name: t.africa, emoji: '🌍' },
    { id: 'Americas', name: t.americas, emoji: '🌎' },
    { id: 'Oceania', name: t.oceania, emoji: '🌊' },
  ];

  const difficulties = [
    { id: 'easy', name: t.easy, description: t.easyDesc },
    { id: 'medium', name: t.medium, description: t.mediumDesc },
    { id: 'hard', name: t.hard, description: t.hardDesc },
    { id: 'expert', name: t.expert, description: t.expertDesc },
    { id: 'erudite', name: t.erudite, description: t.eruditeDesc },
  ];

  const gameModes = [
    { 
      id: 'classic', 
      name: t.classic, 
      description: t.classicDesc,
      icon: '🎯'
    },
    { 
      id: 'time-attack', 
      name: t.timeAttack, 
      description: t.timeAttackDesc,
      icon: '⚡'
    },
    { 
      id: 'survival', 
      name: t.survival, 
      description: t.survivalDesc,
      icon: '🔥'
    },
    { 
      id: 'mistakes', 
      name: t.mistakes, 
      description: t.mistakesDesc,
      icon: '📚'
    },
  ];

  useEffect(() => {
    loadCountries();
  }, [language]);

  const loadCountries = async () => {
    try {
      setLoading(true);
      // Принудительно обновляем данные для нового языка
      const countries = await apiService.forceRefreshCountries(language);
      setCountries(countries);
      console.log(`Loaded ${countries.length} countries for language: ${language}`);
    } catch (error) {
      console.error('Failed to load countries:', error);
      toast.error(t.failedToLoadCountries);
    } finally {
      setLoading(false);
    }
  };

  const handleStartGame = async () => {
    try {
      console.log('🎮 START GAME BUTTON CLICKED!');
      console.log('📊 Current countries in store before start:', countries.length);
      
      setLoading(true);

      // Ensure countries are loaded first
      if (countries.length === 0) {
        console.log('⏳ No countries loaded, loading first...');
        await loadCountries();
        
        // Get updated countries from store
        const { countries: updatedCountries } = useGameStore.getState();
        console.log('📊 Countries after loading:', updatedCountries.length);
        
        if (updatedCountries.length === 0) {
          console.log('❌ Failed to load countries');
          toast.error('Failed to load countries. Please try again.');
          return;
        }
      }

      // Update settings
      const gameSettings = {
        region: selectedRegion,
        difficulty: selectedDifficulty,
        gameMode: selectedGameMode,
        questionCount: selectedDifficulty === 'easy' ? 10 : 
                       selectedDifficulty === 'medium' ? 15 : 
                       selectedDifficulty === 'hard' ? 20 :
                       selectedDifficulty === 'expert' ? 25 :
                       selectedDifficulty === 'erudite' ? 30 : 20,
        timeLimit: selectedDifficulty === 'easy' ? 45 : 
                   selectedDifficulty === 'medium' ? 30 : 
                   selectedDifficulty === 'hard' ? 15 :
                   selectedDifficulty === 'expert' ? 10 :
                   selectedDifficulty === 'erudite' ? 5 : 30,
        questionTypes: ['flag-to-name', 'name-to-flag'] as const,
      };

      console.log('⚙️ Game settings prepared:', gameSettings);
      
      updateSettings(gameSettings);
      console.log('✅ Settings updated');

      // For mistakes mode, check if there are any mistakes
      if (selectedGameMode === 'mistakes') {
        const mistakeCountries = getMistakeCountries();
        if (mistakeCountries.length === 0) {
          console.log('❌ No mistakes to review');
          toast.error(t.noMistakesToReview);
          return;
        }
        console.log('📚 Found mistakes to review:', mistakeCountries.length);
      }

      // Start the game
      console.log('🚀 Calling startGame...');
      startGame(gameSettings);
      console.log('✅ startGame called');
      
      // Check if session was created
      const { currentSession: newSession } = useGameStore.getState();
      console.log('🔍 Checking if session was created:', !!newSession);
      if (newSession) {
        console.log('🎯 Session created successfully:', {
          id: newSession.id,
          questionsCount: newSession.questions.length
        });
        
        if (newSession.questions.length === 0) {
          console.log('❌ Session created but no questions generated!');
          toast.error('Failed to generate questions. Please try again.');
          return;
        }
      } else {
        console.log('❌ Session was NOT created!');
        toast.error('Failed to create game session. Please try again.');
        return;
      }
      
      // Navigate to game screen
      console.log('🧭 Navigating to game...');
      navigateToGame();
    } catch (error) {
      console.error('💥 Failed to start game:', error);
      toast.error(t.failedToStartGame);
    } finally {
      setLoading(false);
      console.log('🏁 handleStartGame finished');
    }
  };

  // Функция навигации
  const navigateToGame = () => {
    if (typeof window !== 'undefined') {
      window.location.href = window.location.origin + '/game/';
    }
  };

  // SEO мета-данные в зависимости от языка
  const getSEOData = () => {
    const baseKeywords = [
      'world arena',
      'world arena games', 
      'world arena flags',
      'world arena games flags',
      'flags game',
      'geography game',
      'country flags',
      'flag quiz',
      'geography quiz',
      'educational games',
      'world geography',
      'flags of the world',
      'country quiz',
      'learn flags',
      'geography learning'
    ];

    switch (language) {
      case 'ru':
        return {
          title: 'World Arena Games - Флаги Мира | Географическая Викторина',
          description: 'Изучайте флаги стран мира в увлекательной игре! World Arena Games предлагает викторину по флагам с разными уровнями сложности. Проверьте свои знания географии!',
          keywords: [
            ...baseKeywords,
            'флаги мира',
            'викторина флаги',
            'география игра',
            'флаги стран',
            'изучение флагов',
            'географическая викторина',
            'образовательные игры',
            'мировая арена',
            'игры флаги'
          ].join(', ')
        };
      case 'de':
        return {
          title: 'World Arena Games - Flaggen der Welt | Geografie-Quiz',
          description: 'Lernen Sie die Flaggen der Welt in einem spannenden Spiel! World Arena Games bietet ein Flaggen-Quiz mit verschiedenen Schwierigkeitsgraden.',
          keywords: [
            ...baseKeywords,
            'flaggen der welt',
            'flaggen quiz',
            'geografie spiel',
            'länderflaggen',
            'flaggen lernen',
            'geografie quiz',
            'lernspiele'
          ].join(', ')
        };
      case 'es':
        return {
          title: 'World Arena Games - Banderas del Mundo | Quiz de Geografía',
          description: '¡Aprende las banderas del mundo en un juego emocionante! World Arena Games ofrece un quiz de banderas con diferentes niveles de dificultad.',
          keywords: [
            ...baseKeywords,
            'banderas del mundo',
            'quiz banderas',
            'juego geografia',
            'banderas países',
            'aprender banderas',
            'quiz geografía',
            'juegos educativos'
          ].join(', ')
        };
      case 'fr':
        return {
          title: 'World Arena Games - Drapeaux du Monde | Quiz de Géographie',
          description: 'Apprenez les drapeaux du monde dans un jeu passionnant! World Arena Games propose un quiz sur les drapeaux avec différents niveaux de difficulté.',
          keywords: [
            ...baseKeywords,
            'drapeaux du monde',
            'quiz drapeaux',
            'jeu géographie',
            'drapeaux pays',
            'apprendre drapeaux',
            'quiz géographie',
            'jeux éducatifs'
          ].join(', ')
        };
      default:
        return {
          title: 'World Arena Games - Flags of the World | Geography Quiz Game',
          description: 'Learn flags of the world in an exciting game! World Arena Games offers a comprehensive flag quiz with multiple difficulty levels. Test your geography knowledge!',
          keywords: baseKeywords.join(', ')
        };
    }
  };

  const seoData = getSEOData();

  return (
    <Layout>
      <Head>
        <title>{seoData.title}</title>
        <meta name="description" content={seoData.description} />
        <meta name="keywords" content={seoData.keywords} />
        <meta name="author" content="World Arena Games" />
        <meta name="robots" content="index, follow" />
        
        {/* Open Graph */}
        <meta property="og:title" content={seoData.title} />
        <meta property="og:description" content={seoData.description} />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://flags.worldarena.games/" />
        <meta property="og:image" content="https://flags.worldarena.games/logo-worldarena-games.png" />
        <meta property="og:site_name" content="World Arena Games" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content={seoData.title} />
        <meta name="twitter:description" content={seoData.description} />
        <meta name="twitter:image" content="https://flags.worldarena.games/logo-worldarena-games.png" />
        
        {/* Canonical URL */}
        <link rel="canonical" href="https://flags.worldarena.games/" />
      </Head>
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-100 dark:from-gray-900 dark:via-purple-900/20 dark:to-indigo-900/20">
        <div className="container mx-auto px-4 py-8">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-12"
          >
            <div className="flex items-center justify-center mb-6">
              <motion.img 
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ type: "spring", duration: 0.8 }}
                src="/logo-worldarena-games.png" 
                alt="FLAGS Logo" 
                className="w-20 h-20 md:w-24 md:h-24 rounded-2xl mr-4 shadow-lg"
              />
              <motion.h1 
                initial={{ opacity: 0, x: -50 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
                className="text-5xl md:text-7xl font-black bg-gradient-to-r from-purple-600 via-blue-600 to-indigo-600 bg-clip-text text-transparent"
              >
                {t.appTitle}
              </motion.h1>
            </div>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto font-medium"
            >
              {t.appDescription}
            </motion.p>
          </motion.div>

          {/* Game Settings */}
          <div className="max-w-5xl mx-auto space-y-8">
            {/* Region Selection */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-3xl p-8 shadow-xl border border-white/20"
            >
              <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-6 text-center">
                🌍 {t.selectRegion}
              </h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {regions.map((region, index) => (
                  <motion.button
                    key={region.id}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.1 + index * 0.05 }}
                    whileHover={{ scale: 1.05, y: -5 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => setSelectedRegion(region.id)}
                    className={`p-6 rounded-2xl border-2 transition-all duration-300 transform ${
                      selectedRegion === region.id
                        ? 'border-purple-500 bg-gradient-to-br from-purple-50 to-indigo-50 dark:from-purple-900/30 dark:to-indigo-900/30 shadow-lg'
                        : 'border-gray-200 dark:border-gray-700 hover:border-purple-300 bg-white/50 dark:bg-gray-700/50'
                    }`}
                  >
                    <div className="text-4xl mb-3">{region.emoji}</div>
                    <div className="font-bold text-gray-900 dark:text-white text-lg">
                      {region.name}
                    </div>
                  </motion.button>
                ))}
              </div>
            </motion.div>

            {/* Difficulty Selection */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-3xl p-8 shadow-xl border border-white/20"
            >
              <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-6 text-center">
                ⚡ {t.selectDifficulty}
              </h2>
              
              {/* Первые три уровня */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                {difficulties.slice(0, 3).map((difficulty, index) => (
                  <motion.button
                    key={difficulty.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 + index * 0.1 }}
                    whileHover={{ scale: 1.03, y: -3 }}
                    whileTap={{ scale: 0.97 }}
                    onClick={() => setSelectedDifficulty(difficulty.id as any)}
                    className={`p-6 rounded-2xl border-2 transition-all duration-300 text-left transform ${
                      selectedDifficulty === difficulty.id
                        ? 'border-blue-500 bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-900/30 dark:to-cyan-900/30 shadow-lg'
                        : 'border-gray-200 dark:border-gray-700 hover:border-blue-300 bg-white/50 dark:bg-gray-700/50'
                    }`}
                  >
                    <div className="font-bold text-gray-900 dark:text-white mb-2 text-xl">
                      {difficulty.name}
                    </div>
                    <div className="text-gray-600 dark:text-gray-400 font-medium">
                      {difficulty.description}
                    </div>
                  </motion.button>
                ))}
              </div>
              
              {/* Продвинутые уровни */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {difficulties.slice(3).map((difficulty, index) => (
                  <motion.button
                    key={difficulty.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 + index * 0.1 }}
                    whileHover={{ scale: 1.03, y: -3 }}
                    whileTap={{ scale: 0.97 }}
                    onClick={() => setSelectedDifficulty(difficulty.id as any)}
                    className={`p-8 rounded-2xl border-2 transition-all duration-300 text-left transform ${
                      selectedDifficulty === difficulty.id
                        ? 'border-purple-500 bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-900/30 dark:to-pink-900/30 shadow-lg'
                        : 'border-gray-200 dark:border-gray-700 hover:border-purple-300 bg-white/50 dark:bg-gray-700/50'
                    }`}
                  >
                    <div className="flex items-center mb-3">
                      <div className="text-3xl mr-3">
                        {difficulty.id === 'expert' ? '🎯' : '🏆'}
                      </div>
                      <div className="font-bold text-gray-900 dark:text-white text-2xl">
                        {difficulty.name}
                      </div>
                    </div>
                    <div className="text-gray-600 dark:text-gray-400 font-medium text-lg">
                      {difficulty.description}
                    </div>
                  </motion.button>
                ))}
              </div>
            </motion.div>

            {/* Game Mode Selection */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-3xl p-8 shadow-xl border border-white/20"
            >
              <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-6 text-center">
                🎮 {t.selectGameMode}
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {gameModes.map((mode, index) => (
                  <motion.button
                    key={mode.id}
                    initial={{ opacity: 0, x: index % 2 === 0 ? -20 : 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + index * 0.1 }}
                    whileHover={{ scale: 1.03, y: -3 }}
                    whileTap={{ scale: 0.97 }}
                    onClick={() => setSelectedGameMode(mode.id as any)}
                    className={`p-6 rounded-2xl border-2 transition-all duration-300 text-left transform ${
                      selectedGameMode === mode.id
                        ? 'border-green-500 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/30 dark:to-emerald-900/30 shadow-lg'
                        : 'border-gray-200 dark:border-gray-700 hover:border-green-300 bg-white/50 dark:bg-gray-700/50'
                    }`}
                  >
                    <div className="flex items-center mb-3">
                      <span className="text-3xl mr-4">{mode.icon}</span>
                      <span className="font-bold text-gray-900 dark:text-white text-xl">
                        {mode.name}
                      </span>
                    </div>
                    <div className="text-gray-600 dark:text-gray-400 font-medium">
                      {mode.description}
                    </div>
                  </motion.button>
                ))}
              </div>
            </motion.div>

            {/* Start Game Button */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="text-center"
            >
              <motion.button
                whileHover={{ scale: 1.05, y: -5 }}
                whileTap={{ scale: 0.95 }}
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  console.log('🔥 BUTTON CLICKED - EVENT FIRED!');
                  handleStartGame();
                }}
                type="button"
                disabled={isLoading}
                className="bg-gradient-to-r from-purple-600 via-blue-600 to-indigo-600 hover:from-purple-700 hover:via-blue-700 hover:to-indigo-700 disabled:from-gray-400 disabled:to-gray-500 text-white font-black py-6 px-12 rounded-2xl text-2xl transition-all duration-300 transform shadow-2xl disabled:scale-100 disabled:shadow-lg"
              >
                {isLoading ? (
                  <div className="flex items-center">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white mr-3"></div>
                    {t.loading}
                  </div>
                ) : (
                  <div className="flex items-center">
                    <span className="mr-3">🚀</span>
                    {t.startGame}
                  </div>
                )}
              </motion.button>
            </motion.div>
          </div>
        </div>
      </div>
    </Layout>
  );
} 