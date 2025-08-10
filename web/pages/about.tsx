import { motion } from 'framer-motion';
import { useGameStore } from '../src/lib/gameStore';
import { useTranslation } from '../src/lib/translations';
import Layout from '../src/components/Layout';

export default function AboutPage() {
  const { language } = useGameStore();
  const { t } = useTranslation(language);

  // Helper function for translations with fallbacks for all languages
  const getTranslation = (key: string, fallback: string) => {
    const translations: Record<string, Record<string, string>> = {
      en: {
        'ourMission': 'Our Mission',
        'appFeatures': 'App Features', 
        'projectFuture': 'Project Future',
        'multilingual': 'Multilingual',
        'multilingualDesc': 'Support for 6 languages for global learning',
        'differentLevels': 'Different Levels',
        'differentLevelsDesc': 'From easy to hard for all ages',
        'modernUI': 'Modern UI',
        'modernUIDesc': 'Beautiful and intuitive interface'
      },
      es: {
        'ourMission': 'Nuestra Misión',
        'appFeatures': 'Características de la App', 
        'projectFuture': 'Futuro del Proyecto',
        'multilingual': 'Multilingüe',
        'multilingualDesc': 'Soporte para 6 idiomas para aprendizaje global',
        'differentLevels': 'Diferentes Niveles',
        'differentLevelsDesc': 'De fácil a difícil para todas las edades',
        'modernUI': 'UI Moderno',
        'modernUIDesc': 'Interfaz hermosa e intuitiva'
      },
      uk: {
        'ourMission': 'Наша Місія',
        'appFeatures': 'Особливості Програми', 
        'projectFuture': 'Майбутнє Проекту',
        'multilingual': 'Багатомовність',
        'multilingualDesc': 'Підтримка 6 мов для глобального навчання',
        'differentLevels': 'Різні Рівні',
        'differentLevelsDesc': 'Від легкого до складного для всіх віків',
        'modernUI': 'Сучасний UI',
        'modernUIDesc': 'Красивий та інтуїтивний інтерфейс'
      },
      ca: {
        'ourMission': 'La Nostra Missió',
        'appFeatures': 'Característiques de l\'App', 
        'projectFuture': 'Futur del Projecte',
        'multilingual': 'Multilingüe',
        'multilingualDesc': 'Suport per a 6 idiomes per a l\'aprenentatge global',
        'differentLevels': 'Diferents Nivells',
        'differentLevelsDesc': 'De fàcil a difícil per a totes les edats',
        'modernUI': 'UI Modern',
        'modernUIDesc': 'Interfície bonica i intuïtiva'
      },
      ru: {
        'ourMission': 'Наша Миссия',
        'appFeatures': 'Особенности Приложения', 
        'projectFuture': 'Будущее Проекта',
        'multilingual': 'Многоязычность',
        'multilingualDesc': 'Поддержка 6 языков для глобального обучения',
        'differentLevels': 'Разные Уровни',
        'differentLevelsDesc': 'От легкого до сложного для всех возрастов',
        'modernUI': 'Современный UI',
        'modernUIDesc': 'Красивый и интуитивный интерфейс'
      },
      zh: {
        'ourMission': '我们的使命',
        'appFeatures': '应用特色', 
        'projectFuture': '项目未来',
        'multilingual': '多语言',
        'multilingualDesc': '支持6种语言进行全球学习',
        'differentLevels': '不同难度',
        'differentLevelsDesc': '从简单到困难适合所有年龄',
        'modernUI': '现代界面',
        'modernUIDesc': '美观直观的界面'
      }
    };
    
    return translations[language]?.[key] || fallback;
  };

  return (
    <Layout title={t.aboutTitle} showBackButton>
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-100 dark:from-gray-900 dark:via-purple-900/20 dark:to-indigo-900/20">
        <div className="container mx-auto px-4 py-12">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-16"
          >
            <h1 className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-4">
              {t.aboutTitle}
            </h1>
            <div className="w-24 h-1 bg-gradient-to-r from-blue-500 to-purple-600 mx-auto rounded-full"></div>
          </motion.div>

          {/* Main Content */}
          <div className="max-w-6xl mx-auto">
            {/* Hero Section with Photo */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2 }}
              className="bg-white dark:bg-gray-800 rounded-3xl shadow-2xl overflow-hidden mb-12"
            >
              <div className="grid md:grid-cols-2 gap-8 p-8 md:p-12">
                {/* Photo Section */}
                <div className="flex flex-col items-center justify-center">
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.4, type: "spring" }}
                    className="relative"
                  >
                    <div className="w-80 h-[29rem] rounded-3xl overflow-hidden shadow-2xl border-4 border-white/20">
                      <img 
                        src="/sergii-and-mark.jpg" 
                        alt="Sergii and Mark"
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent flex items-end justify-center pb-6">
                        <div className="text-center text-white">
                          <p className="text-xl font-semibold">
                            {t.developer} & {t.inspiration}
                          </p>
                          <p className="text-lg opacity-90 mt-1">
                            Sergii & Mark
                          </p>
                        </div>
                      </div>
                    </div>
                    {/* Decorative elements */}
                    <div className="absolute -top-4 -right-4 w-8 h-8 bg-yellow-400 rounded-full animate-bounce"></div>
                    <div className="absolute -bottom-4 -left-4 w-6 h-6 bg-green-400 rounded-full animate-pulse"></div>
                  </motion.div>
                </div>

                {/* Text Section */}
                <div className="flex flex-col justify-center">
                  <motion.div
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.6 }}
                  >
                    <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-6">
                      {t.aboutTitle}
                    </h2>
                    <p className="text-lg text-gray-600 dark:text-gray-300 leading-relaxed mb-6">
                      {t.aboutDescription}
                    </p>
                    <div className="flex items-center space-x-4">
                      <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                        <span className="text-white text-xl">💡</span>
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900 dark:text-white">
                          {t.inspiration || 'Вдохновение'}
                        </h3>
                        <p className="text-gray-600 dark:text-gray-400">
                          Mark - {t.inspiration}
                        </p>
                      </div>
                    </div>
                  </motion.div>
                </div>
              </div>
            </motion.div>

            {/* Mission Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8 }}
              className="grid md:grid-cols-2 gap-8 mb-12"
            >
              <div className="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-xl">
                <div className="flex items-center mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-teal-600 rounded-full flex items-center justify-center mr-4">
                    <span className="text-white text-xl">🎯</span>
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
                    {getTranslation('ourMission', 'Наша Миссия')}
                  </h3>
                </div>
                <p className="text-gray-600 dark:text-gray-300 leading-relaxed">
                  {t.aboutMission}
                </p>
              </div>

              <div className="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-xl">
                <div className="flex items-center mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-600 rounded-full flex items-center justify-center mr-4">
                    <span className="text-white text-xl">✨</span>
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
                    {t.inspiration}
                  </h3>
                </div>
                <p className="text-gray-600 dark:text-gray-300 leading-relaxed">
                  {t.aboutInspiration}
                </p>
              </div>
            </motion.div>

            {/* Features Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1.0 }}
              className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-3xl p-8 md:p-12 text-white mb-12"
            >
              <div className="text-center mb-8">
                <h3 className="text-3xl font-bold mb-4">{getTranslation('appFeatures', 'Особенности Приложения')}</h3>
                <p className="text-xl opacity-90">
                  {t.aboutFeatures}
                </p>
              </div>
              
              <div className="grid md:grid-cols-3 gap-6">
                <div className="text-center">
                  <div className="text-4xl mb-4">🌍</div>
                  <h4 className="text-xl font-semibold mb-2">{getTranslation('multilingual', 'Многоязычность')}</h4>
                  <p className="opacity-90">{getTranslation('multilingualDesc', 'Поддержка 6 языков для глобального обучения')}</p>
                </div>
                <div className="text-center">
                  <div className="text-4xl mb-4">🎮</div>
                  <h4 className="text-xl font-semibold mb-2">{getTranslation('differentLevels', 'Разные Уровни')}</h4>
                  <p className="opacity-90">{getTranslation('differentLevelsDesc', 'От легкого до сложного для всех возрастов')}</p>
                </div>
                <div className="text-center">
                  <div className="text-4xl mb-4">📱</div>
                  <h4 className="text-xl font-semibold mb-2">{getTranslation('modernUI', 'Современный UI')}</h4>
                  <p className="opacity-90">{getTranslation('modernUIDesc', 'Красивый и интуитивный интерфейс')}</p>
                </div>
              </div>
            </motion.div>

            {/* Future Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1.2 }}
              className="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-xl text-center"
            >
              <div className="text-4xl mb-6">🚀</div>
              <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                {getTranslation('projectFuture', 'Будущее Проекта')}
              </h3>
              <p className="text-gray-600 dark:text-gray-300 leading-relaxed max-w-3xl mx-auto">
                {t.aboutFuture}
              </p>
            </motion.div>
          </div>
        </div>
      </div>
    </Layout>
  );
} 