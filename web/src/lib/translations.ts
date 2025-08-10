export interface Translations {
  // App
  appTitle: string;
  appDescription: string;
  
  // Navigation
  home: string;
  statistics: string;
  leaderboard: string;
  settings: string;
  back: string;
  
  // Game
  startGame: string;
  loading: string;
  gameNotFound: string;
  returnHome: string;
  question: string;
  of: string;
  score: string;
  time: string;
  correct: string;
  incorrect: string;
  gameCompleted: string;
  yourResult: string;
  
  // Game setup
  selectRegion: string;
  allRegions: string;
  europe: string;
  asia: string;
  africa: string;
  americas: string;
  oceania: string;
  
  selectDifficulty: string;
  easy: string;
  medium: string;
  hard: string;
  expert: string;
  erudite: string;
  easyDesc: string;
  mediumDesc: string;
  hardDesc: string;
  expertDesc: string;
  eruditeDesc: string;
  
  selectGameMode: string;
  classic: string;
  timeAttack: string;
  survival: string;
  mistakes: string;
  classicDesc: string;
  timeAttackDesc: string;
  survivalDesc: string;
  mistakesDesc: string;
  
  // Questions
  whichCountryFlag: string;
  selectCountryFlag: string;
  
  // Statistics
  totalGames: string;
  totalQuestions: string;
  correctAnswers: string;
  averageScore: string;
  bestScore: string;
  currentStreak: string;
  bestStreak: string;
  averageTime: string;
  regionStats: string;
  difficultyStats: string;
  accuracy: string;
  games: string;
  
  // Leaderboard
  rank: string;
  player: string;
  points: string;
  
  // Settings
  language: string;
  theme: string;
  light: string;
  dark: string;
  system: string;
  clearData: string;
  clearDataConfirm: string;
  dataManagement: string;
  clearAllStats: string;
  clear: string;
  aboutApp: string;
  version: string;
  platform: string;
  lastUpdate: string;
  confirmAction: string;
  cancel: string;
  
  // Leaderboard page
  region: string;
  difficulty: string;
  mode: string;
  date: string;
  gameTime: string;
  
  // Errors
  failedToLoadCountries: string;
  failedToStartGame: string;
  noMistakesToReview: string;
  
  // PWA
  installApp: string;
  
  // About section
  about: string;
  aboutTitle: string;
  aboutDescription: string;
  aboutMission: string;
  aboutInspiration: string;
  aboutFeatures: string;
  aboutFuture: string;
  developer: string;
  inspiration: string;
  
  // About page specific
  ourMission: string;
  appFeatures: string;
  projectFuture: string;
  multilingual: string;
  multilingualDesc: string;
  differentLevels: string;
  differentLevelsDesc: string;
  modernUI: string;
  modernUIDesc: string;
  
  // Game result modal
  resultExcellent: string;
  resultGreat: string;
  resultGood: string;
  resultNotBad: string;
  resultKeepPracticing: string;
  resultGameCompleted: string;
  resultPoints: string;
  resultTime: string;
  resultDifficulty: string;
  resultRegion: string;
  resultAverageTime: string;
  resultAllWorld: string;
  resultToHome: string;
  resultPlayAgain: string;
}

export const translations: Record<string, Translations> = {
  en: {
    // App
    appTitle: 'FLAGS',
    appDescription: 'A fun and educational game to test your knowledge of country flags',
    
    // Navigation
    home: 'Home',
    statistics: 'Statistics',
    leaderboard: 'Leaderboard',
    settings: 'Settings',
    back: 'Back',
    
    // Game
    startGame: 'Start Game',
    loading: 'Loading...',
    gameNotFound: 'Game not found',
    returnHome: 'Return Home',
    question: 'Question',
    of: 'of',
    score: 'Score',
    time: 'Time',
    correct: 'Correct!',
    incorrect: 'Incorrect!',
    gameCompleted: 'Game completed! Your result:',
    yourResult: 'Your result',
    
    // Game setup
    selectRegion: 'Select Region',
    allRegions: 'All Regions',
    europe: 'Europe',
    asia: 'Asia',
    africa: 'Africa',
    americas: 'Americas',
    oceania: 'Oceania',
    
    selectDifficulty: 'Select Difficulty',
    easy: 'Easy',
    medium: 'Medium',
    hard: 'Hard',
    expert: 'Expert',
    erudite: 'Erudite',
    easyDesc: '10 questions, 45 sec per answer',
    mediumDesc: '15 questions, 30 sec per answer',
    hardDesc: '20 questions, 15 sec per answer',
    expertDesc: '50% of countries from selected region, 10 sec per answer',
    eruditeDesc: '100% of countries from selected region, 5 sec per answer',
    
    selectGameMode: 'Select Game Mode',
    classic: 'Classic',
    timeAttack: 'Time Attack',
    survival: 'Survival',
    mistakes: 'Mistakes Review',
    classicDesc: 'Standard multiple choice game',
    timeAttackDesc: 'Answer quickly, time is limited',
    survivalDesc: 'Game until first mistake',
    mistakesDesc: 'Review countries you got wrong',
    
    // Questions
    whichCountryFlag: 'Which country does this flag belong to?',
    selectCountryFlag: 'Select the flag of the country:',
    
    // Statistics
    totalGames: 'Total Games',
    totalQuestions: 'Total Questions',
    correctAnswers: 'Correct Answers',
    averageScore: 'Average Score',
    bestScore: 'Best Score',
    currentStreak: 'Current Streak',
    bestStreak: 'Best Streak',
    averageTime: 'Average Time',
    regionStats: 'Region Statistics',
    difficultyStats: 'Difficulty Statistics',
    accuracy: 'Accuracy',
    games: 'Games',
    
    // Leaderboard
    rank: 'Rank',
    player: 'Player',
    points: 'Points',
    
    // Settings
    language: 'Language',
    theme: 'Theme',
    light: 'Light',
    dark: 'Dark',
    system: 'System',
    clearData: 'Clear Data',
    clearDataConfirm: 'Are you sure you want to clear all data?',
    dataManagement: 'Data Management',
    clearAllStats: 'Clear all statistics and game history',
    clear: 'Clear',
    aboutApp: 'About App',
    version: 'Version',
    platform: 'Platform',
    lastUpdate: 'Last Update',
    confirmAction: 'Confirm Action',
    cancel: 'Cancel',
    
    // Leaderboard page
    region: 'Region',
    difficulty: 'Difficulty',
    mode: 'Mode',
    date: 'Date',
    gameTime: 'Time',
    
    // Errors
    failedToLoadCountries: 'Failed to load countries data',
    failedToStartGame: 'Failed to start game',
    noMistakesToReview: 'You have no mistakes to review yet',
    
    // PWA
    installApp: 'Install App',
    
    // About section
    about: 'About Us',
    aboutTitle: 'About Our Project',
    aboutDescription: 'This educational application was born from a father\'s love and a son\'s curiosity. When my son Mark showed interest in world geography and flags, I realized how important it is for children and adults from all corners of our planet to have access to quality educational tools. Our mission is to break down language barriers and make learning geography an exciting adventure that connects people across cultures and continents.',
    aboutMission: 'Our mission is to make learning about world geography accessible, engaging, and fun for international residents of our planet. We believe that knowledge of countries, their flags, and cultures helps build bridges between people and promotes global understanding.',
    aboutInspiration: 'Mark, my son, was the main inspiration for creating this application. His questions about different countries and their flags made me think about how we can help all children and adults learn and develop, regardless of their native language or location.',
    aboutFeatures: 'The application supports multiple languages and offers various difficulty levels, making it suitable for users of all ages and knowledge levels. We strive to create an inclusive educational environment where everyone can learn and grow.',
    aboutFuture: 'We continue to develop and improve the application, adding new features and expanding language support. Our goal is to make geography learning an exciting journey for everyone.',
    developer: 'Developer',
    inspiration: 'Inspiration',
    
    // About page specific
    ourMission: 'Our Mission',
    appFeatures: 'App Features',
    projectFuture: 'Project Future',
    multilingual: 'Multilingual',
    multilingualDesc: 'Support for 6 languages for global learning',
    differentLevels: 'Different Levels',
    differentLevelsDesc: 'From easy to hard for all ages',
    modernUI: 'Modern UI',
    modernUIDesc: 'Beautiful and intuitive interface',
    
    // Game result modal
    resultExcellent: 'Excellent!',
    resultGreat: 'Great!',
    resultGood: 'Good!',
    resultNotBad: 'Not Bad!',
    resultKeepPracticing: 'Keep Practicing!',
    resultGameCompleted: 'Game Completed!',
    resultPoints: 'Points',
    resultTime: 'Time',
    resultDifficulty: 'Difficulty',
    resultRegion: 'Region',
    resultAverageTime: 'Average Time',
    resultAllWorld: 'All World',
    resultToHome: 'To Home',
    resultPlayAgain: 'Play Again',
  },
  
  es: {
    // App
    appTitle: 'FLAGS',
    appDescription: 'Un juego divertido y educativo para probar tu conocimiento de las banderas de los países',
    
    // Navigation
    home: 'Inicio',
    statistics: 'Estadísticas',
    leaderboard: 'Clasificación',
    settings: 'Configuración',
    back: 'Atrás',
    
    // Game
    startGame: 'Comenzar Juego',
    loading: 'Cargando...',
    gameNotFound: 'Juego no encontrado',
    returnHome: 'Volver al Inicio',
    question: 'Pregunta',
    of: 'de',
    score: 'Puntuación',
    time: 'Tiempo',
    correct: '¡Correcto!',
    incorrect: '¡Incorrecto!',
    gameCompleted: '¡Juego completado! Tu resultado:',
    yourResult: 'Tu resultado',
    
    // Game setup
    selectRegion: 'Seleccionar Región',
    allRegions: 'Todas las Regiones',
    europe: 'Europa',
    asia: 'Asia',
    africa: 'África',
    americas: 'Américas',
    oceania: 'Oceanía',
    
    selectDifficulty: 'Seleccionar Dificultad',
    easy: 'Fácil',
    medium: 'Medio',
    hard: 'Difícil',
    expert: 'Experto',
    erudite: 'Erudito',
    easyDesc: '10 preguntas, 45 seg por respuesta',
    mediumDesc: '15 preguntas, 30 seg por respuesta',
    hardDesc: '20 preguntas, 15 seg por respuesta',
    expertDesc: '50% de países de la región seleccionada, 10 seg por respuesta',
    eruditeDesc: '100% de países de la región seleccionada, 5 seg por respuesta',
    
    selectGameMode: 'Seleccionar Modo de Juego',
    classic: 'Clásico',
    timeAttack: 'Ataque de Tiempo',
    survival: 'Supervivencia',
    mistakes: 'Revisión de Errores',
    classicDesc: 'Juego estándar de opción múltiple',
    timeAttackDesc: 'Responde rápido, el tiempo es limitado',
    survivalDesc: 'Juego hasta el primer error',
    mistakesDesc: 'Revisa los países que fallaste',
    
    // Questions
    whichCountryFlag: '¿A qué país pertenece esta bandera?',
    selectCountryFlag: 'Selecciona la bandera del país:',
    
    // Statistics
    totalGames: 'Juegos Totales',
    totalQuestions: 'Preguntas Totales',
    correctAnswers: 'Respuestas Correctas',
    averageScore: 'Puntuación Promedio',
    bestScore: 'Mejor Puntuación',
    currentStreak: 'Racha Actual',
    bestStreak: 'Mejor Racha',
    averageTime: 'Tiempo Promedio',
    regionStats: 'Estadísticas por Región',
    difficultyStats: 'Estadísticas por Dificultad',
    accuracy: 'Precisión',
    games: 'Juegos',
    
    // Leaderboard
    rank: 'Rango',
    player: 'Jugador',
    points: 'Puntos',
    
    // Settings
    language: 'Idioma',
    theme: 'Tema',
    light: 'Claro',
    dark: 'Oscuro',
    system: 'Sistema',
    clearData: 'Limpiar Datos',
    clearDataConfirm: '¿Estás seguro de que quieres limpiar todos los datos?',
    dataManagement: 'Gestión de Datos',
    clearAllStats: 'Limpiar todas las estadísticas e historial de juegos',
    clear: 'Limpiar',
    aboutApp: 'Acerca de la App',
    version: 'Versión',
    platform: 'Plataforma',
    lastUpdate: 'Última Actualización',
    confirmAction: 'Confirmar Acción',
    cancel: 'Cancelar',
    
    // Leaderboard page
    region: 'Región',
    difficulty: 'Dificultad',
    mode: 'Modo',
    date: 'Fecha',
    gameTime: 'Hora',
    
    // Errors
    failedToLoadCountries: 'Error al cargar datos de países',
    failedToStartGame: 'Error al iniciar el juego',
    noMistakesToReview: 'No tienes errores para revisar aún',
    
    // PWA
    installApp: 'Instalar App',
    
    // About section
    about: 'Sobre Nosotros',
    aboutTitle: 'Sobre Nuestro Proyecto',
    aboutDescription: 'Esta aplicación educativa nació del amor de un padre y la curiosidad de un hijo. Cuando mi hijo Mark mostró interés en la geografía mundial y las banderas, me di cuenta de lo importante que es para niños y adultos de todos los rincones de nuestro planeta tener acceso a herramientas educativas de calidad. Nuestra misión es derribar las barreras del idioma y hacer que aprender geografía sea una aventura emocionante que conecte a las personas a través de culturas y continentes.',
    aboutMission: 'Nuestra misión es hacer que el aprendizaje sobre la geografía del mundo sea accesible, entretenido y divertido para residentes internacionales de nuestro planeta. Creemos que el conocimiento de los países, sus banderas y sus culturas ayuda a construir puentes entre las personas y promueve la comprensión global.',
    aboutInspiration: 'Mark, mi hijo, fue la principal inspiración para crear esta aplicación. Sus preguntas sobre diferentes países y sus banderas me hicieron pensar en cómo podemos ayudar a que todos los niños y adultos aprendan y desarrollen, independientemente de su idioma nativo o ubicación.',
    aboutFeatures: 'La aplicación soporta múltiples idiomas y ofrece varios niveles de dificultad, lo que la hace adecuada para usuarios de todas las edades y niveles de conocimiento. Nos esforzamos por crear un entorno educativo inclusivo donde todos puedan aprender y crecer.',
    aboutFuture: 'Seguimos desarrollando y mejorando la aplicación, agregando nuevas funciones y ampliando el soporte de idiomas. Nuestro objetivo es hacer que el aprendizaje geográfico sea una aventura emocionante para todos.',
    developer: 'Desarrollador',
    inspiration: 'Inspiración',
    
    // About page specific
    ourMission: 'Nuestra Misión',
    appFeatures: 'Características de la App',
    projectFuture: 'Futuro del Proyecto',
    multilingual: 'Multilingüe',
    multilingualDesc: 'Soporte para 6 idiomas para aprendizaje global',
    differentLevels: 'Diferentes Niveles',
    differentLevelsDesc: 'De fácil a difícil para todas las edades',
    modernUI: 'UI Moderno',
    modernUIDesc: 'Interfaz hermosa e intuitiva',
    
    // Game result modal
    resultExcellent: 'Excelente!',
    resultGreat: '¡Genial!',
    resultGood: '¡Bueno!',
    resultNotBad: '¡No Malo!',
    resultKeepPracticing: '¡Sigue Practicando!',
    resultGameCompleted: '¡Juego Completado!',
    resultPoints: 'Puntos',
    resultTime: 'Tiempo',
    resultDifficulty: 'Dificultad',
    resultRegion: 'Región',
    resultAverageTime: 'Tiempo Promedio',
    resultAllWorld: 'Todo el Mundo',
    resultToHome: 'A Inicio',
    resultPlayAgain: 'Jugar de Nuevo',
  },
  
  uk: {
    // App
    appTitle: 'FLAGS',
    appDescription: 'Весела та освітня гра для перевірки ваших знань про прапори країн',
    
    // Navigation
    home: 'Головна',
    statistics: 'Статистика',
    leaderboard: 'Рейтинг',
    settings: 'Налаштування',
    back: 'Назад',
    
    // Game
    startGame: 'Почати гру',
    loading: 'Завантаження...',
    gameNotFound: 'Гру не знайдено',
    returnHome: 'Повернутися на головну',
    question: 'Питання',
    of: 'з',
    score: 'Рахунок',
    time: 'Час',
    correct: 'Правильно!',
    incorrect: 'Неправильно!',
    gameCompleted: 'Гру завершено! Ваш результат:',
    yourResult: 'Ваш результат',
    
    // Game setup
    selectRegion: 'Оберіть регіон',
    allRegions: 'Всі регіони',
    europe: 'Європа',
    asia: 'Азія',
    africa: 'Африка',
    americas: 'Америка',
    oceania: 'Океанія',
    
    selectDifficulty: 'Оберіть складність',
    easy: 'Легкий',
    medium: 'Середній',
    hard: 'Складний',
    expert: 'Експерт',
    erudite: 'Ерудит',
    easyDesc: '10 питань, 45 сек на відповідь',
    mediumDesc: '15 питань, 30 сек на відповідь',
    hardDesc: '20 питань, 15 сек на відповідь',
    expertDesc: '50% країн з вибраного регіону, 10 сек на відповідь',
    eruditeDesc: '100% країн з вибраного регіону, 5 сек на відповідь',
    
    selectGameMode: 'Оберіть режим гри',
    classic: 'Класичний',
    timeAttack: 'На час',
    survival: 'Виживання',
    mistakes: 'Робота над помилками',
    classicDesc: 'Стандартна гра з вибором відповідей',
    timeAttackDesc: 'Відповідайте швидко, час обмежений',
    survivalDesc: 'Гра до першої помилки',
    mistakesDesc: 'Повторіть країни, в яких помилялися',
    
    // Questions
    whichCountryFlag: 'Якій країні належить цей прапор?',
    selectCountryFlag: 'Оберіть прапор країни:',
    
    // Statistics
    totalGames: 'Всього ігор',
    totalQuestions: 'Всього питань',
    correctAnswers: 'Правильних відповідей',
    averageScore: 'Середній рахунок',
    bestScore: 'Найкращий рахунок',
    currentStreak: 'Поточна серія',
    bestStreak: 'Найкраща серія',
    averageTime: 'Середній час',
    regionStats: 'Статистика по регіонах',
    difficultyStats: 'Статистика по складності',
    accuracy: 'Точність',
    games: 'Ігри',
    
    // Leaderboard
    rank: 'Ранг',
    player: 'Гравець',
    points: 'Очки',
    
    // Settings
    language: 'Мова',
    theme: 'Тема',
    light: 'Світла',
    dark: 'Темна',
    system: 'Системна',
    clearData: 'Очистити дані',
    clearDataConfirm: 'Ви впевнені, що хочете очистити всі дані?',
    dataManagement: 'Управління даними',
    clearAllStats: 'Видалити всю статистику та історію ігор',
    clear: 'Очистити',
    aboutApp: 'Про додаток',
    version: 'Версія',
    platform: 'Платформа',
    lastUpdate: 'Останнє оновлення',
    confirmAction: 'Підтвердіть дію',
    cancel: 'Скасувати',
    
    // Leaderboard page
    region: 'Регіон',
    difficulty: 'Складність',
    mode: 'Режим',
    date: 'Дата',
    gameTime: 'Час',
    
    // Errors
    failedToLoadCountries: 'Не вдалося завантажити дані країн',
    failedToStartGame: 'Не вдалося почати гру',
    noMistakesToReview: 'У вас поки немає помилок для повторення',
    
    // PWA
    installApp: 'Встановити додаток',
    
    // About section
    about: 'Про Нас',
    aboutTitle: 'Про Наш Проект',
    aboutDescription: 'Ця освітня програма народилася з батьківської любові та дитячої цікавості. Коли мій син Марк проявив інтерес до світової географії та прапорів, я зрозумів, наскільки важливо для дітей та дорослих з усіх куточків нашої планети мати доступ до якісних освітніх інструментів. Наша місія - зруйнувати мовні бар\'єри та зробити вивчення географії захоплюючою пригодою, яка з\'єднує людей через культури та континенти.',
    aboutMission: 'Наша місія полягає в тому, щоб зробити географію світу доступною, захоплюючою та веселою для міжнародних жителів планети. Ми віримо, що знання про країни, їх прапори та культури допомагають будувати мости між людьми та просувати глобальне розуміння.',
    aboutInspiration: 'Марк, мій син, був головною інспірацією для створення цієї програми. Його питання про різні країни та їх прапори змусили мене подумати, як ми можемо допомогти всім дітям та дорослим навчатися та розвиватися, незалежно від їхньої рідної мови чи місцезнаходження.',
    aboutFeatures: 'Програма підтримує кілька мов та пропонує різні рівні складності, що робить її придатною для користувачів усіх віків та рівнів знань. Ми прагнемо створити інклюзивне освітнє середовище, де кожен може навчатися та розвиватися.',
    aboutFuture: 'Ми продовжуємо розвивати та вдосконалювати програму, додаючи нові функції та розширюючи підтримку мов. Наша мета - зробити вивчення географії захоплюючою подорожжю для кожного.',
    developer: 'Розробник',
    inspiration: 'Натхнення',
    
    // About page specific
    ourMission: 'Наша Місія',
    appFeatures: 'Особливості Програми',
    projectFuture: 'Майбутнє Проекту',
    multilingual: 'Багатомовність',
    multilingualDesc: 'Підтримка 6 мов для глобального навчання',
    differentLevels: 'Різні Рівні',
    differentLevelsDesc: 'Від легкого до складного для всіх віків',
    modernUI: 'Сучасний UI',
    modernUIDesc: 'Красивий та інтуїтивний інтерфейс',
    
    // Game result modal
    resultExcellent: 'Відмінно!',
    resultGreat: 'Чудово!',
    resultGood: 'Добре!',
    resultNotBad: 'Непогано!',
    resultKeepPracticing: 'Тренуйтесь далі!',
    resultGameCompleted: 'Гру завершено!',
    resultPoints: 'Очки',
    resultTime: 'Час',
    resultDifficulty: 'Складність',
    resultRegion: 'Регіон',
    resultAverageTime: 'Середній час',
    resultAllWorld: 'Весь світ',
    resultToHome: 'На головну',
    resultPlayAgain: 'Ще раз',
  },
  
  ca: {
    // App
    appTitle: 'FLAGS',
    appDescription: 'Un joc divertit i educatiu per provar el teu coneixement de les banderes dels països',
    
    // Navigation
    home: 'Inici',
    statistics: 'Estadístiques',
    leaderboard: 'Classificació',
    settings: 'Configuració',
    back: 'Enrere',
    
    // Game
    startGame: 'Començar Joc',
    loading: 'Carregant...',
    gameNotFound: 'Joc no trobat',
    returnHome: 'Tornar a l\'Inici',
    question: 'Pregunta',
    of: 'de',
    score: 'Puntuació',
    time: 'Temps',
    correct: 'Correcte!',
    incorrect: 'Incorrecte!',
    gameCompleted: 'Joc completat! El teu resultat:',
    yourResult: 'El teu resultat',
    
    // Game setup
    selectRegion: 'Seleccionar Regió',
    allRegions: 'Totes les Regions',
    europe: 'Europa',
    asia: 'Àsia',
    africa: 'Àfrica',
    americas: 'Amèriques',
    oceania: 'Oceania',
    
    selectDifficulty: 'Seleccionar Dificultat',
    easy: 'Fàcil',
    medium: 'Mitjà',
    hard: 'Difícil',
    expert: 'Expert',
    erudite: 'Erudit',
    easyDesc: '10 preguntes, 45 seg per resposta',
    mediumDesc: '15 preguntes, 30 seg per resposta',
    hardDesc: '20 preguntes, 15 seg per resposta',
    expertDesc: '50% de països de la regió seleccionada, 10 seg per resposta',
    eruditeDesc: '100% de països de la regió seleccionada, 5 seg per resposta',
    
    selectGameMode: 'Seleccionar Mode de Joc',
    classic: 'Clàssic',
    timeAttack: 'Atac de Temps',
    survival: 'Supervivència',
    mistakes: 'Revisió d\'Errors',
    classicDesc: 'Joc estàndard d\'opció múltiple',
    timeAttackDesc: 'Respon ràpid, el temps és limitat',
    survivalDesc: 'Joc fins al primer error',
    mistakesDesc: 'Revisa els països que vas fallar',
    
    // Questions
    whichCountryFlag: 'A quin país pertany aquesta bandera?',
    selectCountryFlag: 'Selecciona la bandera del país:',
    
    // Statistics
    totalGames: 'Jocs Totals',
    totalQuestions: 'Preguntes Totals',
    correctAnswers: 'Respostes Correctes',
    averageScore: 'Puntuació Mitjana',
    bestScore: 'Millor Puntuació',
    currentStreak: 'Ratxa Actual',
    bestStreak: 'Millor Ratxa',
    averageTime: 'Temps Mitjà',
    regionStats: 'Estadístiques per Regió',
    difficultyStats: 'Estadístiques per Dificultat',
    accuracy: 'Precisió',
    games: 'Jocs',
    
    // Leaderboard
    rank: 'Rang',
    player: 'Jugador',
    points: 'Punts',
    
    // Settings
    language: 'Idioma',
    theme: 'Tema',
    light: 'Clar',
    dark: 'Fosc',
    system: 'Sistema',
    clearData: 'Netejar Dades',
    clearDataConfirm: 'Estàs segur que vols netejar totes les dades?',
    dataManagement: 'Gestió de Dades',
    clearAllStats: 'Netejar totes les estadístiques i historial de jocs',
    clear: 'Netejar',
    aboutApp: 'Sobre l\'App',
    version: 'Versió',
    platform: 'Plataforma',
    lastUpdate: 'Última Actualització',
    confirmAction: 'Confirmar Acció',
    cancel: 'Cancel·lar',
    
    // Leaderboard page
    region: 'Regió',
    difficulty: 'Dificultat',
    mode: 'Mode',
    date: 'Data',
    gameTime: 'Hora',
    
    // Errors
    failedToLoadCountries: 'Error al carregar dades de països',
    failedToStartGame: 'Error a l\'iniciar el joc',
    noMistakesToReview: 'No tens errors per revisar encara',
    
    // PWA
    installApp: 'Instal·lar App',
    
    // About section
    about: 'Sobre Nosaltres',
    aboutTitle: 'Sobre El Nostre Projecte',
    aboutDescription: 'Aquesta aplicació educativa va néixer de l\'amor d\'un pare i la curiositat d\'un fill. Quan el meu fill Mark va mostrar interès per la geografia mundial i les banderes, em vaig adonar de la importància que tenen els nens i adults de tots els racons del nostre planeta d\'accedir a eines educatives de qualitat. La nostra missió és trencar les barreres lingüístiques i fer que aprendre geografia sigui una aventura emocionant que connecti les persones a través de cultures i continents.',
    aboutMission: 'La nostra missió és fer que l\'aprenentatge sobre la geografia del món sigui accessible, entretingut i divertit per als residents internacionals del planeta. Creiem que el coneixement dels països, les seves banderes i les seves cultures ajuda a construir ponts entre les persones i a promoure la comprensió global.',
    aboutInspiration: 'Mark, el meu fill, va ser la principal inspiració per crear aquesta aplicació. Les seves preguntes sobre diferents països i les seves banderes em van fer pensar en com podem ajudar a que tots els nens i adults aprenguin i es desenvolupin, independentment del seu idioma natiu o ubicació.',
    aboutFeatures: 'L\'aplicació suporta múltiples idiomes i ofereix diversos nivells de dificultat, fent que sigui adequada per a usuaris de totes les edats i nivells de coneixement. Ens esforcem per crear un entorn educatiu inclusiu on tothom pot aprendre i créixer.',
    aboutFuture: 'Seguim desenvolupant i millorant l\'aplicació, afegint noves funcions i ampliant el suport lingüístic. El nostre objectiu és fer que l\'aprenentatge geogràfic sigui una aventura emocionant per a tothom.',
    developer: 'Desenvolupador',
    inspiration: 'Inspiració',
    
    // About page specific
    ourMission: 'La Nostra Missió',
    appFeatures: 'Característiques de l\'App',
    projectFuture: 'Futur del Projecte',
    multilingual: 'Multilingüe',
    multilingualDesc: 'Suport per a 6 idiomes per a l\'aprenentatge global',
    differentLevels: 'Diferents Nivells',
    differentLevelsDesc: 'De fàcil a difícil per a totes les edats',
    modernUI: 'UI Modern',
    modernUIDesc: 'Interfície bonica i intuïtiva',
    
    // Game result modal
    resultExcellent: 'Excel·lent!',
    resultGreat: '¡Genial!',
    resultGood: '¡Bé!',
    resultNotBad: '¡No Mal!',
    resultKeepPracticing: '¡Segueix Practicant!',
    resultGameCompleted: '¡Joc Completat!',
    resultPoints: 'Punts',
    resultTime: 'Temps',
    resultDifficulty: 'Dificultat',
    resultRegion: 'Regió',
    resultAverageTime: 'Temps Mitjà',
    resultAllWorld: 'Tot el Món',
    resultToHome: 'A Inici',
    resultPlayAgain: 'Jugar de Nou',
  },
  
  ru: {
    // App
    appTitle: 'FLAGS',
    appDescription: 'Веселая и образовательная игра для проверки ваших знаний о флагах стран',
    
    // Navigation
    home: 'Главная',
    statistics: 'Статистика',
    leaderboard: 'Рейтинг',
    settings: 'Настройки',
    back: 'Назад',
    
    // Game
    startGame: 'Начать игру',
    loading: 'Загрузка...',
    gameNotFound: 'Игра не найдена',
    returnHome: 'Вернуться на главную',
    question: 'Вопрос',
    of: 'из',
    score: 'Счет',
    time: 'Время',
    correct: 'Правильно!',
    incorrect: 'Неправильно!',
    gameCompleted: 'Игра завершена! Ваш результат:',
    yourResult: 'Ваш результат',
    
    // Game setup
    selectRegion: 'Выберите регион',
    allRegions: 'Все регионы',
    europe: 'Европа',
    asia: 'Азия',
    africa: 'Африка',
    americas: 'Америка',
    oceania: 'Океания',
    
    selectDifficulty: 'Выберите сложность',
    easy: 'Легкий',
    medium: 'Средний',
    hard: 'Сложный',
    expert: 'Эксперт',
    erudite: 'Эрудит',
    easyDesc: '10 вопросов, 45 сек на ответ',
    mediumDesc: '15 вопросов, 30 сек на ответ',
    hardDesc: '20 вопросов, 15 сек на ответ',
    expertDesc: '50% стран из выбранного региона, 10 сек на ответ',
    eruditeDesc: '100% стран из выбранного региона, 5 сек на ответ',
    
    selectGameMode: 'Выберите режим игры',
    classic: 'Классический',
    timeAttack: 'На время',
    survival: 'Выживание',
    mistakes: 'Работа над ошибками',
    classicDesc: 'Стандартная игра с выбором ответов',
    timeAttackDesc: 'Отвечайте быстро, время ограничено',
    survivalDesc: 'Игра до первой ошибки',
    mistakesDesc: 'Повторите страны, в которых ошибались',
    
    // Questions
    whichCountryFlag: 'Какой стране принадлежит этот флаг?',
    selectCountryFlag: 'Выберите флаг страны:',
    
    // Statistics
    totalGames: 'Всего игр',
    totalQuestions: 'Всего вопросов',
    correctAnswers: 'Правильных ответов',
    averageScore: 'Средний счет',
    bestScore: 'Лучший счет',
    currentStreak: 'Текущая серия',
    bestStreak: 'Лучшая серия',
    averageTime: 'Среднее время',
    regionStats: 'Статистика по регионам',
    difficultyStats: 'Статистика по сложности',
    accuracy: 'Точность',
    games: 'Игры',
    
    // Leaderboard
    rank: 'Ранг',
    player: 'Игрок',
    points: 'Очки',
    
    // Settings
    language: 'Язык',
    theme: 'Тема',
    light: 'Светлая',
    dark: 'Темная',
    system: 'Системная',
    clearData: 'Очистить данные',
    clearDataConfirm: 'Вы уверены, что хотите очистить все данные?',
    dataManagement: 'Управление данными',
    clearAllStats: 'Удалить всю статистику и историю игр',
    clear: 'Очистить',
    aboutApp: 'О приложении',
    version: 'Версия',
    platform: 'Платформа',
    lastUpdate: 'Последнее обновление',
    confirmAction: 'Подтвердите действие',
    cancel: 'Отмена',
    
    // Leaderboard page
    region: 'Регион',
    difficulty: 'Сложность',
    mode: 'Режим',
    date: 'Дата',
    gameTime: 'Время',
    
    // Errors
    failedToLoadCountries: 'Не удалось загрузить данные стран',
    failedToStartGame: 'Не удалось начать игру',
    noMistakesToReview: 'У вас пока нет ошибок для повторения',
    
    // PWA
    installApp: 'Установить приложение',
    
    // About section
    about: 'О Нас',
    aboutTitle: 'О Нашем Проекте',
    aboutDescription: 'Это образовательное приложение родилось из отцовской любви и детского любопытства. Когда мой сын Марк проявил интерес к мировой географии и флагам, я понял, насколько важно для детей и взрослых со всех уголков нашей планеты иметь доступ к качественным образовательным инструментам. Наша миссия - разрушить языковые барьеры и сделать изучение географии увлекательным приключением, которое соединяет людей через культуры и континенты.',
    aboutMission: 'Наша миссия состоит в том, чтобы сделать обучение географии доступным, увлекательным и веселым для международных жителей планеты. Мы верим, что знание о странах, их флагах и культурах помогает строить мосты между людьми и продвигать глобальное понимание.',
    aboutInspiration: 'Марк, мой сын, был основной вдохновляющей силой для создания этого приложения. Его вопросы о разных странах и их флагах заставили меня задуматься о том, как мы можем помочь всем детям и взрослым учиться и развиваться, независимо от их родного языка или места жительства.',
    aboutFeatures: 'Приложение поддерживает несколько языков и предлагает различные уровни сложности, делая его подходящим для пользователей всех возрастов и уровней знаний. Мы стремимся создать всеобъемлющее образовательное окружение, где каждый может учиться и развиваться.',
    aboutFuture: 'Мы продолжаем развивать и совершенствовать приложение, добавляя новые функции и расширяя поддержку языков. Наша цель - сделать обучение географии увлекательным путешествием для всех.',
    developer: 'Разработчик',
    inspiration: 'Вдохновение',
    
    // About page specific
    ourMission: 'Наша Миссия',
    appFeatures: 'Особенности Приложения',
    projectFuture: 'Будущее Проекта',
    multilingual: 'Многоязычность',
    multilingualDesc: 'Поддержка 6 языков для глобального обучения',
    differentLevels: 'Разные Уровни',
    differentLevelsDesc: 'От легкого до сложного для всех возрастов',
    modernUI: 'Современный UI',
    modernUIDesc: 'Красивый и интуитивный интерфейс',
    
    // Game result modal
    resultExcellent: 'Отлично!',
    resultGreat: 'Отлично!',
    resultGood: 'Отлично!',
    resultNotBad: 'Неплохо!',
    resultKeepPracticing: 'Продолжайте практиковаться!',
    resultGameCompleted: 'Игра завершена!',
    resultPoints: 'Очки',
    resultTime: 'Время',
    resultDifficulty: 'Сложность',
    resultRegion: 'Регион',
    resultAverageTime: 'Среднее время',
    resultAllWorld: 'Весь мир',
    resultToHome: 'На главную',
    resultPlayAgain: 'Еще раз',
  },
  
  zh: {
    // App
    appTitle: 'FLAGS',
    appDescription: '一个有趣的教育游戏，测试你对国家国旗的知识',
    
    // Navigation
    home: '首页',
    statistics: '统计',
    leaderboard: '排行榜',
    settings: '设置',
    back: '返回',
    
    // Game
    startGame: '开始游戏',
    loading: '加载中...',
    gameNotFound: '未找到游戏',
    returnHome: '返回首页',
    question: '问题',
    of: '/',
    score: '得分',
    time: '时间',
    correct: '正确！',
    incorrect: '错误！',
    gameCompleted: '游戏完成！您的结果：',
    yourResult: '您的结果',
    
    // Game setup
    selectRegion: '选择地区',
    allRegions: '所有地区',
    europe: '欧洲',
    asia: '亚洲',
    africa: '非洲',
    americas: '美洲',
    oceania: '大洋洲',
    
    selectDifficulty: '选择难度',
    easy: '简单',
    medium: '中等',
    hard: '困难',
    expert: '专家',
    erudite: '博学',
    easyDesc: '10个问题，每题45秒',
    mediumDesc: '15个问题，每题30秒',
    hardDesc: '20个问题，每题15秒',
    expertDesc: '50%的国家来自选定地区，每题10秒',
    eruditeDesc: '100%的国家来自选定地区，每题5秒',
    
    selectGameMode: '选择游戏模式',
    classic: '经典',
    timeAttack: '限时挑战',
    survival: '生存',
    mistakes: '错题复习',
    classicDesc: '标准多选题游戏',
    timeAttackDesc: '快速回答，时间有限',
    survivalDesc: '游戏直到第一个错误',
    mistakesDesc: '复习答错的国家',
    
    // Questions
    whichCountryFlag: '这面旗帜属于哪个国家？',
    selectCountryFlag: '选择国家的旗帜：',
    
    // Statistics
    totalGames: '总游戏数',
    totalQuestions: '总问题数',
    correctAnswers: '正确答案',
    averageScore: '平均得分',
    bestScore: '最佳得分',
    currentStreak: '当前连胜',
    bestStreak: '最佳连胜',
    averageTime: '平均时间',
    regionStats: '地区统计',
    difficultyStats: '难度统计',
    accuracy: '准确率',
    games: '游戏',
    
    // Leaderboard
    rank: '排名',
    player: '玩家',
    points: '积分',
    
    // Settings
    language: '语言',
    theme: '主题',
    light: '浅色',
    dark: '深色',
    system: '系统',
    clearData: '清除数据',
    clearDataConfirm: '您确定要清除所有数据吗？',
    dataManagement: '数据管理',
    clearAllStats: '清除所有统计和游戏历史',
    clear: '清除',
    aboutApp: '关于应用',
    version: '版本',
    platform: '平台',
    lastUpdate: '最后更新',
    confirmAction: '确认操作',
    cancel: '取消',
    
    // Leaderboard page
    region: '地区',
    difficulty: '难度',
    mode: '模式',
    date: '日期',
    gameTime: '时间',
    
    // Errors
    failedToLoadCountries: '加载国家数据失败',
    failedToStartGame: '开始游戏失败',
    noMistakesToReview: '您还没有需要复习的错误',
    
    // PWA
    installApp: '安装应用',
    
    // About section
    about: '关于我们',
    aboutTitle: '关于我们的项目',
    aboutDescription: '这个教育应用程序诞生于父亲的爱和儿子的好奇心。当我的儿子马克对世界地理和国旗表现出兴趣时，我意识到让来自地球各个角落的儿童和成人都能获得优质教育工具是多么重要。我们的使命是打破语言障碍，让学习地理成为一次激动人心的冒险，连接不同文化和大陆的人们。',
    aboutMission: '我们的使命是让世界地理学习变得可访问、吸引人和有趣，以造福我们星球上的国际居民。我们相信，了解国家、他们的旗帜和文化有助于建立人与人之间的桥梁，并促进全球理解。',
    aboutInspiration: '马克，我的儿子，是创建这个应用程序的主要灵感来源。他对不同国家和他们的旗帜的问题让我思考如何帮助所有孩子和成人学习和发展，无论他们的母语或位置如何。',
    aboutFeatures: '该应用程序支持多种语言，并提供各种难度级别，使其适合所有年龄和知识水平的用户。我们努力创造一个包容性的教育环境，让每个人都能学习和成长。',
    aboutFuture: '我们继续开发和改进应用程序，添加新功能并扩展语言支持。我们的目标是让地理学习成为每个人的激动人心的旅程。',
    developer: '开发者',
    inspiration: '灵感',
    
    // About page specific
    ourMission: '我们的使命',
    appFeatures: '应用特色',
    projectFuture: '项目未来',
    multilingual: '多语言',
    multilingualDesc: '支持6种语言进行全球学习',
    differentLevels: '不同难度',
    differentLevelsDesc: '从简单到困难适合所有年龄',
    modernUI: '现代界面',
    modernUIDesc: '美观直观的界面',
    
    // Game result modal
    resultExcellent: '优秀！',
    resultGreat: '优秀！',
    resultGood: '优秀！',
    resultNotBad: '不错！',
    resultKeepPracticing: '继续练习！',
    resultGameCompleted: '游戏完成！',
    resultPoints: '积分',
    resultTime: '时间',
    resultDifficulty: '难度',
    resultRegion: '地区',
    resultAverageTime: '平均时间',
    resultAllWorld: '全世界',
    resultToHome: '返回首页',
    resultPlayAgain: '再玩一次',
  },
};

export function useTranslation(language: string = 'ru') {
  const t = translations[language] || translations.ru;
  return { t };
} 