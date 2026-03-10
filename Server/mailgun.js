/**
 * Отправка писем через Mailgun API (сброс пароля, приветствие, уведомления).
 * Если MAILGUN_API_KEY не задан — отправка не выполняется.
 */
const https = require('https');
const FormData = require('form-data');

const apiKey = process.env.MAILGUN_API_KEY;
const domain = (process.env.MAILGUN_DOMAIN || '').trim();
const eu = process.env.MAILGUN_EU === 'true' || process.env.MAILGUN_EU === '1';
const host = eu ? 'api.eu.mailgun.net' : 'api.mailgun.net';

if (!apiKey || !domain) {
  console.log('[mailgun] Disabled: set MAILGUN_API_KEY and MAILGUN_DOMAIN in .env to enable');
}

const baseStyles = `
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  line-height: 1.5;
  color: #333;
  max-width: 520px;
  margin: 0 auto;
`;
const cardStyle = `
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
  padding: 28px 32px;
  margin: 24px 0;
`;
const codeStyle = `
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 6px;
  background: linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%);
  color: #fff;
  padding: 14px 24px;
  border-radius: 8px;
  text-align: center;
  margin: 20px 0;
`;
const footerStyle = `
  font-size: 12px;
  color: #888;
  margin-top: 28px;
  padding-top: 16px;
  border-top: 1px solid #eee;
`;

const emailLocale = {
  en: {
    footer: 'This email was sent by World Arena Flags. If you did not expect it, please ignore.',
    reset: {
      subject: 'Password reset — World Arena Flags',
      greeting: 'Hello',
      greetingName: (n) => `Hello, ${n}!`,
      codeLabel: 'Password reset code:',
      codeValid: 'Code is valid for 30 minutes. If you did not request a reset, ignore this email.',
    },
    welcome: {
      subject: 'Welcome to World Arena Flags!',
      greetingName: (n) => `Hello, ${n}!`,
      thanks: 'Thank you for registering with World Arena Flags. You received bonus F-Bucks for signing up.',
      bye: 'Good luck in duels and new records!',
    },
    passwordChanged: {
      subject: 'Password changed — World Arena Flags',
      greetingName: (n) => `Hello, ${n}!`,
      body: 'Your World Arena Flags account password was successfully changed.',
      ifNotYou: 'If this was not you — restore access via "Forgot password" in the app.',
    },
    dailyReminder: {
      subject: 'Got 5 minutes? Time for a tiny Flags practice!',
      greetingName: (n) => `Hi ${n}!`,
      gotTime: 'Got 5 minutes? Time for a tiny Flags practice.',
      startGame: 'START GAME',
      practiceMakes: 'Practice makes progress',
      takeFive: 'Take 5 minutes to learn something new today!',
      currentStreakLabel: 'Current streak:',
      daysInRow: (n) => `${n} days in a row`,
      totalLabel: 'Total',
      currentWeekLabel: 'Current week',
      streakExtended: 'Streak extended',
      futureDay: 'Future day',
      weekDays: ['We', 'Th', 'Fr', 'Sa', 'Su', 'Mo', 'Tu'],
    },
    streakAtRisk: {
      subject: 'Don\'t lose your streak! You haven\'t played today',
      greetingName: (n) => `Hi ${n}!`,
      body: 'You haven\'t played World Arena Flags today. Play now to keep your streak going!',
      cta: 'PLAY NOW',
    },
    weeklySummary: {
      subject: 'Your week in World Arena Flags',
      greetingName: (n) => `Hi ${n}!`,
      intro: 'Here\'s your weekly summary.',
      daysPlayed: 'Days played',
      streak: 'Current streak',
      weakCountries: 'Weak countries to review',
      progress: 'Progress by continent',
      cta: 'OPEN APP',
    },
    duelChallenge: {
      subject: 'You\'ve been challenged to a duel!',
      body: (name) => `${name} challenged you to a Flags duel. Accept and show who knows more!`,
      cta: 'ACCEPT CHALLENGE',
    },
    achievement: {
      subject: 'Achievement unlocked!',
      greetingName: (n) => `Hi ${n}!`,
      body: 'You\'ve unlocked a new achievement in World Arena Flags.',
      achievementTitle: 'Achievement',
      cta: 'VIEW IN APP',
    },
    streakRecovery: {
      subject: 'Start a new streak today!',
      greetingName: (n) => `Hi ${n}!`,
      body: 'You missed yesterday. No problem — start a new streak today and get back on track!',
      cta: 'PLAY NOW',
    },
    subscriptionReminder: {
      subject: 'Your Premium subscription ends soon',
      greetingName: (n) => `Hi ${n}!`,
      body: (days) => `Your World Arena Flags Premium subscription will expire in ${days} day(s). Renew to keep your benefits!`,
      cta: 'RENEW',
    },
  },
  ru: {
    footer: 'Это письмо отправлено сервисом World Arena Flags. Если вы не ожидали его — проигнорируйте.',
    reset: {
      subject: 'Сброс пароля — World Arena Flags',
      greeting: 'Привет',
      greetingName: (n) => `Привет, ${n}!`,
      codeLabel: 'Код для сброса пароля:',
      codeValid: 'Код действителен 30 минут. Если вы не запрашивали сброс — проигнорируйте это письмо.',
    },
    welcome: {
      subject: 'Добро пожаловать в World Arena Flags!',
      greetingName: (n) => `Привет, ${n}!`,
      thanks: 'Спасибо за регистрацию в World Arena Flags. Вы получили бонусные F-Bucks за регистрацию.',
      bye: 'Удачных дуэлей и новых рекордов!',
    },
    passwordChanged: {
      subject: 'Пароль изменён — World Arena Flags',
      greetingName: (n) => `Привет, ${n}!`,
      body: 'Пароль вашего аккаунта World Arena Flags был успешно изменён.',
      ifNotYou: 'Если это были не вы — срочно восстановите доступ через «Забыли пароль» в приложении.',
    },
    dailyReminder: {
      subject: 'Есть 5 минут? Пора потренировать флаги!',
      greetingName: (n) => `Привет, ${n}!`,
      gotTime: 'Есть 5 минут? Пора короткой тренировки по флагам.',
      startGame: 'НАЧАТЬ ИГРУ',
      practiceMakes: 'Практика ведёт к прогрессу',
      takeFive: 'Выдели 5 минут и узнай что-то новое сегодня!',
      currentStreakLabel: 'Текущая серия:',
      daysInRow: (n) => `${n} дн. подряд`,
      totalLabel: 'Всего',
      currentWeekLabel: 'Текущая неделя',
      streakExtended: 'Серия продолжена',
      futureDay: 'Будущий день',
      weekDays: ['Ср', 'Чт', 'Пт', 'Сб', 'Вс', 'Пн', 'Вт'],
    },
    streakAtRisk: {
      subject: 'Не потеряй серию! Ты ещё не играл сегодня',
      greetingName: (n) => `Привет, ${n}!`,
      body: 'Ты ещё не играл в World Arena Flags сегодня. Зайди и продолжи серию!',
      cta: 'ИГРАТЬ',
    },
    weeklySummary: {
      subject: 'Твоя неделя в World Arena Flags',
      greetingName: (n) => `Привет, ${n}!`,
      intro: 'Вот твоя недельная сводка.',
      daysPlayed: 'Дней сыграно',
      streak: 'Текущая серия',
      weakCountries: 'Слабые страны для повторения',
      progress: 'Прогресс по континентам',
      cta: 'ОТКРЫТЬ',
    },
    duelChallenge: {
      subject: 'Тебя вызвали на дуэль!',
      body: (name) => `${name} вызвал тебя на дуэль по флагам. Прими вызов и покажи, кто знает больше!`,
      cta: 'ПРИНЯТЬ ВЫЗОВ',
    },
    achievement: {
      subject: 'Достижение разблокировано!',
      greetingName: (n) => `Привет, ${n}!`,
      body: 'Ты разблокировал новое достижение в World Arena Flags.',
      achievementTitle: 'Достижение',
      cta: 'СМОТРЕТЬ В ПРИЛОЖЕНИИ',
    },
    streakRecovery: {
      subject: 'Начни новую серию сегодня!',
      greetingName: (n) => `Привет, ${n}!`,
      body: 'Ты пропустил вчера. Ничего страшного — начни новую серию сегодня!',
      cta: 'ИГРАТЬ',
    },
    subscriptionReminder: {
      subject: 'Подписка Premium скоро закончится',
      greetingName: (n) => `Привет, ${n}!`,
      body: (days) => `Подписка World Arena Flags Premium истечёт через ${days} дн. Продли, чтобы сохранить преимущества!`,
      cta: 'ПРОДЛИТЬ',
    },
  },
  de: {
    footer: 'Diese E-Mail wurde von World Arena Flags gesendet. Wenn Sie sie nicht erwartet haben, ignorieren Sie sie bitte.',
    reset: {
      subject: 'Passwort zurücksetzen — World Arena Flags',
      greeting: 'Hallo',
      greetingName: (n) => `Hallo, ${n}!`,
      codeLabel: 'Code zum Zurücksetzen des Passworts:',
      codeValid: 'Der Code ist 30 Minuten gültig. Wenn Sie keine Zurücksetzung angefordert haben, ignorieren Sie diese E-Mail.',
    },
    welcome: {
      subject: 'Willkommen bei World Arena Flags!',
      greetingName: (n) => `Hallo, ${n}!`,
      thanks: 'Danke für Ihre Registrierung bei World Arena Flags. Sie haben Bonus-F-Bucks für die Anmeldung erhalten.',
      bye: 'Viel Erfolg bei den Duellen und neuen Rekorden!',
    },
    passwordChanged: {
      subject: 'Passwort geändert — World Arena Flags',
      greetingName: (n) => `Hallo, ${n}!`,
      body: 'Das Passwort Ihres World Arena Flags-Kontos wurde erfolgreich geändert.',
      ifNotYou: 'Wenn Sie das nicht waren — stellen Sie den Zugang über „Passwort vergessen“ in der App wieder her.',
    },
    dailyReminder: {
      subject: '5 Minuten Zeit? Zeit für eine kleine Flaggen-Übung!',
      greetingName: (n) => `Hallo ${n}!`,
      gotTime: '5 Minuten Zeit? Zeit für eine kleine Flaggen-Übung.',
      startGame: 'SPIEL STARTEN',
      practiceMakes: 'Übung macht den Meister',
      takeFive: 'Nimm dir 5 Minuten und lern heute etwas Neues!',
      currentStreakLabel: 'Aktuelle Serie:',
      daysInRow: (n) => `${n} Tage in Folge`,
      totalLabel: 'Gesamt',
      currentWeekLabel: 'Aktuelle Woche',
      streakExtended: 'Serie fortgesetzt',
      futureDay: 'Zukünftiger Tag',
      weekDays: ['Mi', 'Do', 'Fr', 'Sa', 'So', 'Mo', 'Di'],
    },
    streakAtRisk: {
      subject: 'Verliere deine Serie nicht! Du hast heute noch nicht gespielt',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Du hast heute noch nicht World Arena Flags gespielt. Spiele jetzt und halte deine Serie!',
      cta: 'JETZT SPIELEN',
    },
    weeklySummary: {
      subject: 'Deine Woche in World Arena Flags',
      greetingName: (n) => `Hallo ${n}!`,
      intro: 'Hier ist deine wöchentliche Zusammenfassung.',
      daysPlayed: 'Gespielte Tage',
      streak: 'Aktuelle Serie',
      weakCountries: 'Schwache Länder zum Wiederholen',
      progress: 'Fortschritt nach Kontinent',
      cta: 'APP ÖFFNEN',
    },
    duelChallenge: {
      subject: 'Du wurdest zu einem Duell herausgefordert!',
      body: (name) => `${name} hat dich zu einem Flaggen-Duell herausgefordert. Nimm an und zeig, wer mehr weiß!`,
      cta: 'HERAUSFORDERUNG ANNEHMEN',
    },
    achievement: {
      subject: 'Erfolg freigeschaltet!',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Du hast einen neuen Erfolg in World Arena Flags freigeschaltet.',
      achievementTitle: 'Erfolg',
      cta: 'IN APP ANZEIGEN',
    },
    streakRecovery: {
      subject: 'Starte heute eine neue Serie!',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Du hast gestern verpasst. Kein Problem — starte heute eine neue Serie!',
      cta: 'JETZT SPIELEN',
    },
    subscriptionReminder: {
      subject: 'Dein Premium-Abo endet bald',
      greetingName: (n) => `Hallo ${n}!`,
      body: (days) => `Dein World Arena Flags Premium-Abo läuft in ${days} Tag(en) ab. Verlängere, um deine Vorteile zu behalten!`,
      cta: 'VERLÄNGERN',
    },
  },
  es: {
    footer: 'Este correo fue enviado por World Arena Flags. Si no lo esperaba, ignórelo.',
    reset: {
      subject: 'Restablecer contraseña — World Arena Flags',
      greeting: 'Hola',
      greetingName: (n) => `¡Hola, ${n}!`,
      codeLabel: 'Código para restablecer la contraseña:',
      codeValid: 'El código es válido 30 minutos. Si no solicitó el restablecimiento, ignore este correo.',
    },
    welcome: {
      subject: '¡Bienvenido a World Arena Flags!',
      greetingName: (n) => `¡Hola, ${n}!`,
      thanks: 'Gracias por registrarte en World Arena Flags. Has recibido F-Bucks de bonificación por registrarte.',
      bye: '¡Buena suerte en los duelos y nuevos récords!',
    },
    passwordChanged: {
      subject: 'Contraseña cambiada — World Arena Flags',
      greetingName: (n) => `¡Hola, ${n}!`,
      body: 'La contraseña de tu cuenta World Arena Flags se ha cambiado correctamente.',
      ifNotYou: 'Si no fuiste tú — restaura el acceso mediante «Olvidé la contraseña» en la app.',
    },
    dailyReminder: {
      subject: '¿Tienes 5 minutos? ¡Hora de practicar banderas!',
      greetingName: (n) => `¡Hola ${n}!`,
      gotTime: '¿Tienes 5 minutos? Hora de una práctica rápida de banderas.',
      startGame: 'JUGAR',
      practiceMakes: 'La práctica hace al maestro',
      takeFive: '¡Dedica 5 minutos a aprender algo nuevo hoy!',
      currentStreakLabel: 'Racha actual:',
      daysInRow: (n) => `${n} días seguidos`,
      totalLabel: 'Total',
      currentWeekLabel: 'Semana actual',
      streakExtended: 'Racha extendida',
      futureDay: 'Día futuro',
      weekDays: ['Mi', 'Ju', 'Vi', 'Sá', 'Do', 'Lu', 'Ma'],
    },
    streakAtRisk: {
      subject: '¡No pierdas tu racha! Aún no has jugado hoy',
      greetingName: (n) => `¡Hola ${n}!`,
      body: 'Aún no has jugado a World Arena Flags hoy. ¡Juega ahora para mantener tu racha!',
      cta: 'JUGAR AHORA',
    },
    weeklySummary: {
      subject: 'Tu semana en World Arena Flags',
      greetingName: (n) => `¡Hola ${n}!`,
      intro: 'Aquí tienes tu resumen semanal.',
      daysPlayed: 'Días jugados',
      streak: 'Racha actual',
      weakCountries: 'Países débiles para repasar',
      progress: 'Progreso por continente',
      cta: 'ABRIR APP',
    },
    duelChallenge: {
      subject: '¡Te han desafiado a un duelo!',
      body: (name) => `${name} te ha desafiado a un duelo de banderas. ¡Acepta y muestra quién sabe más!`,
      cta: 'ACEPTAR DESAFÍO',
    },
    achievement: {
      subject: '¡Logro desbloqueado!',
      greetingName: (n) => `¡Hola ${n}!`,
      body: 'Has desbloqueado un nuevo logro en World Arena Flags.',
      achievementTitle: 'Logro',
      cta: 'VER EN APP',
    },
    streakRecovery: {
      subject: '¡Empieza una nueva racha hoy!',
      greetingName: (n) => `¡Hola ${n}!`,
      body: 'Ayer no jugaste. No pasa nada — ¡empieza una nueva racha hoy!',
      cta: 'JUGAR AHORA',
    },
    subscriptionReminder: {
      subject: 'Tu suscripción Premium termina pronto',
      greetingName: (n) => `¡Hola ${n}!`,
      body: (days) => `Tu suscripción Premium de World Arena Flags expira en ${days} día(s). ¡Renueva para mantener tus beneficios!`,
      cta: 'RENOVAR',
    },
  },
  fr: {
    footer: 'Cet e-mail a été envoyé par World Arena Flags. Si vous ne l\'attendiez pas, ignorez-le.',
    reset: {
      subject: 'Réinitialisation du mot de passe — World Arena Flags',
      greeting: 'Bonjour',
      greetingName: (n) => `Bonjour, ${n} !`,
      codeLabel: 'Code de réinitialisation du mot de passe :',
      codeValid: 'Le code est valable 30 minutes. Si vous n\'avez pas demandé de réinitialisation, ignorez cet e-mail.',
    },
    welcome: {
      subject: 'Bienvenue sur World Arena Flags !',
      greetingName: (n) => `Bonjour, ${n} !`,
      thanks: 'Merci de vous être inscrit sur World Arena Flags. Vous avez reçu des F-Bucks bonus pour votre inscription.',
      bye: 'Bonne chance dans les duels et pour les nouveaux records !',
    },
    passwordChanged: {
      subject: 'Mot de passe modifié — World Arena Flags',
      greetingName: (n) => `Bonjour, ${n} !`,
      body: 'Le mot de passe de votre compte World Arena Flags a été modifié avec succès.',
      ifNotYou: 'Si ce n\'était pas vous — rétablissez l\'accès via « Mot de passe oublié » dans l\'app.',
    },
    dailyReminder: {
      subject: '5 minutes devant vous ? C\'est l\'heure des drapeaux !',
      greetingName: (n) => `Salut ${n} !`,
      gotTime: '5 minutes devant vous ? C\'est l\'heure d\'une petite pratique des drapeaux.',
      startGame: 'JOUER',
      practiceMakes: 'C\'est en forgeant qu\'on devient forgeron',
      takeFive: 'Prenez 5 minutes pour apprendre quelque chose de nouveau aujourd\'hui !',
      currentStreakLabel: 'Série actuelle :',
      daysInRow: (n) => `${n} jours d\'affilée`,
      totalLabel: 'Total',
      currentWeekLabel: 'Semaine en cours',
      streakExtended: 'Série prolongée',
      futureDay: 'Jour à venir',
      weekDays: ['Me', 'Je', 'Ve', 'Sa', 'Di', 'Lu', 'Ma'],
    },
    streakAtRisk: {
      subject: 'Ne perdez pas votre série ! Vous n\'avez pas joué aujourd\'hui',
      greetingName: (n) => `Salut ${n} !`,
      body: 'Vous n\'avez pas joué à World Arena Flags aujourd\'hui. Jouez pour maintenir votre série !',
      cta: 'JOUER',
    },
    weeklySummary: {
      subject: 'Votre semaine dans World Arena Flags',
      greetingName: (n) => `Salut ${n} !`,
      intro: 'Voici votre résumé hebdomadaire.',
      daysPlayed: 'Jours joués',
      streak: 'Série actuelle',
      weakCountries: 'Pays faibles à réviser',
      progress: 'Progrès par continent',
      cta: 'OUVRIR L\'APP',
    },
    duelChallenge: {
      subject: 'Vous avez été défié en duel !',
      body: (name) => `${name} vous a défié à un duel de drapeaux. Acceptez et montrez qui en sait plus !`,
      cta: 'ACCEPTER LE DÉFI',
    },
    achievement: {
      subject: 'Succès débloqué !',
      greetingName: (n) => `Salut ${n} !`,
      body: 'Vous avez débloqué un nouveau succès dans World Arena Flags.',
      achievementTitle: 'Succès',
      cta: 'VOIR DANS L\'APP',
    },
    streakRecovery: {
      subject: 'Commencez une nouvelle série aujourd\'hui !',
      greetingName: (n) => `Salut ${n} !`,
      body: 'Vous avez manqué hier. Pas de souci — recommencez une nouvelle série aujourd\'hui !',
      cta: 'JOUER',
    },
    subscriptionReminder: {
      subject: 'Votre abonnement Premium se termine bientôt',
      greetingName: (n) => `Salut ${n} !`,
      body: (days) => `Votre abonnement World Arena Flags Premium expire dans ${days} jour(s). Renouvelez pour garder vos avantages !`,
      cta: 'RENOUVELER',
    },
  },
  it: {
    footer: 'Questa email è stata inviata da World Arena Flags. Se non te l\'aspettavi, ignorala.',
    reset: {
      subject: 'Reimpostazione password — World Arena Flags',
      greeting: 'Ciao',
      greetingName: (n) => `Ciao, ${n}!`,
      codeLabel: 'Codice per reimpostare la password:',
      codeValid: 'Il codice è valido 30 minuti. Se non hai richiesto la reimpostazione, ignora questa email.',
    },
    welcome: {
      subject: 'Benvenuto in World Arena Flags!',
      greetingName: (n) => `Ciao, ${n}!`,
      thanks: 'Grazie per esserti registrato a World Arena Flags. Hai ricevuto F-Bucks bonus per la registrazione.',
      bye: 'Buona fortuna nei duelli e nei nuovi record!',
    },
    passwordChanged: {
      subject: 'Password modificata — World Arena Flags',
      greetingName: (n) => `Ciao, ${n}!`,
      body: 'La password del tuo account World Arena Flags è stata modificata con successo.',
      ifNotYou: 'Se non sei stato tu — ripristina l\'accesso tramite «Password dimenticata» nell\'app.',
    },
    dailyReminder: {
      subject: 'Hai 5 minuti? È l\'ora di praticare le bandiere!',
      greetingName: (n) => `Ciao ${n}!`,
      gotTime: 'Hai 5 minuti? È l\'ora di un po\' di pratica con le bandiere.',
      startGame: 'GIOCA',
      practiceMakes: 'La pratica rende perfetti',
      takeFive: 'Dedica 5 minuti per imparare qualcosa di nuovo oggi!',
      currentStreakLabel: 'Serie attuale:',
      daysInRow: (n) => `${n} giorni di seguito`,
      totalLabel: 'Totale',
      currentWeekLabel: 'Settimana corrente',
      streakExtended: 'Serie estesa',
      futureDay: 'Giorno futuro',
      weekDays: ['Me', 'Gi', 'Ve', 'Sa', 'Do', 'Lu', 'Ma'],
    },
    streakAtRisk: {
      subject: 'Non perdere la tua serie! Non hai ancora giocato oggi',
      greetingName: (n) => `Ciao ${n}!`,
      body: 'Non hai ancora giocato a World Arena Flags oggi. Gioca per mantenere la serie!',
      cta: 'GIOCA ORA',
    },
    weeklySummary: {
      subject: 'La tua settimana in World Arena Flags',
      greetingName: (n) => `Ciao ${n}!`,
      intro: 'Ecco il tuo riepilogo settimanale.',
      daysPlayed: 'Giorni giocati',
      streak: 'Serie attuale',
      weakCountries: 'Paesi deboli da rivedere',
      progress: 'Progressi per continente',
      cta: 'APRI APP',
    },
    duelChallenge: {
      subject: 'Sei stato sfidato a un duello!',
      body: (name) => `${name} ti ha sfidato a un duello di bandiere. Accetta e mostra chi ne sa di più!`,
      cta: 'ACCETTA SFIDA',
    },
    achievement: {
      subject: 'Achievement sbloccato!',
      greetingName: (n) => `Ciao ${n}!`,
      body: 'Hai sbloccato un nuovo achievement in World Arena Flags.',
      achievementTitle: 'Achievement',
      cta: 'VEDI IN APP',
    },
    streakRecovery: {
      subject: 'Inizia una nuova serie oggi!',
      greetingName: (n) => `Ciao ${n}!`,
      body: 'Ieri non hai giocato. Nessun problema — inizia una nuova serie oggi!',
      cta: 'GIOCA ORA',
    },
    subscriptionReminder: {
      subject: 'Il tuo abbonamento Premium sta per scadere',
      greetingName: (n) => `Ciao ${n}!`,
      body: (days) => `Il tuo abbonamento World Arena Flags Premium scade tra ${days} giorno/i. Rinnova per mantenere i vantaggi!`,
      cta: 'RINNOVA',
    },
  },
  nl: {
    footer: 'Deze e-mail is verzonden door World Arena Flags. Als u deze niet verwachtte, negeer hem dan.',
    reset: {
      subject: 'Wachtwoord resetten — World Arena Flags',
      greeting: 'Hallo',
      greetingName: (n) => `Hallo, ${n}!`,
      codeLabel: 'Code om wachtwoord te resetten:',
      codeValid: 'De code is 30 minuten geldig. Als u geen reset heeft aangevraagd, negeer deze e-mail.',
    },
    welcome: {
      subject: 'Welkom bij World Arena Flags!',
      greetingName: (n) => `Hallo, ${n}!`,
      thanks: 'Bedankt voor je registratie bij World Arena Flags. Je hebt bonus F-Bucks ontvangen voor je aanmelding.',
      bye: 'Succes in de duels en nieuwe records!',
    },
    passwordChanged: {
      subject: 'Wachtwoord gewijzigd — World Arena Flags',
      greetingName: (n) => `Hallo, ${n}!`,
      body: 'Het wachtwoord van je World Arena Flags-account is succesvol gewijzigd.',
      ifNotYou: 'Als jij dat niet was — herstel de toegang via «Wachtwoord vergeten» in de app.',
    },
    dailyReminder: {
      subject: '5 minuten tijd? Tijd voor een korte vlaggenoefening!',
      greetingName: (n) => `Hallo ${n}!`,
      gotTime: '5 minuten tijd? Tijd voor een korte vlaggenoefening.',
      startGame: 'START SPEL',
      practiceMakes: 'Oefening baart kunst',
      takeFive: 'Neem 5 minuten om vandaag iets nieuws te leren!',
      currentStreakLabel: 'Huidige reeks:',
      daysInRow: (n) => `${n} dagen op rij`,
      totalLabel: 'Totaal',
      currentWeekLabel: 'Huidige week',
      streakExtended: 'Reeks verlengd',
      futureDay: 'Toekomstige dag',
      weekDays: ['Wo', 'Do', 'Vr', 'Za', 'Zo', 'Ma', 'Di'],
    },
    streakAtRisk: {
      subject: 'Verlies je reeks niet! Je hebt vandaag nog niet gespeeld',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Je hebt vandaag nog niet World Arena Flags gespeeld. Speel nu om je reeks te behouden!',
      cta: 'NU SPELEN',
    },
    weeklySummary: {
      subject: 'Je week in World Arena Flags',
      greetingName: (n) => `Hallo ${n}!`,
      intro: 'Hier is je wekelijkse samenvatting.',
      daysPlayed: 'Dagen gespeeld',
      streak: 'Huidige reeks',
      weakCountries: 'Zwakke landen om te herhalen',
      progress: 'Voortgang per continent',
      cta: 'APP OPENEN',
    },
    duelChallenge: {
      subject: 'Je bent uitgedaagd voor een duel!',
      body: (name) => `${name} heeft je uitgedaagd voor een vlaggenduel. Accepteer en laat zien wie meer weet!`,
      cta: 'UITDAGING ANNEMEN',
    },
    achievement: {
      subject: 'Prestatie ontgrendeld!',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Je hebt een nieuwe prestatie ontgrendeld in World Arena Flags.',
      achievementTitle: 'Prestatie',
      cta: 'BEKIJK IN APP',
    },
    streakRecovery: {
      subject: 'Begin vandaag een nieuwe reeks!',
      greetingName: (n) => `Hallo ${n}!`,
      body: 'Je hebt gisteren gemist. Geen probleem — begin vandaag een nieuwe reeks!',
      cta: 'NU SPELEN',
    },
    subscriptionReminder: {
      subject: 'Je Premium-abonnement verloopt binnenkort',
      greetingName: (n) => `Hallo ${n}!`,
      body: (days) => `Je World Arena Flags Premium-abonnement verloopt over ${days} dag(en). Verleng om je voordelen te behouden!`,
      cta: 'VERLENGEN',
    },
  },
  pl: {
    footer: 'Ten e-mail został wysłany przez World Arena Flags. Jeśli go nie oczekiwałeś, zignoruj go.',
    reset: {
      subject: 'Reset hasła — World Arena Flags',
      greeting: 'Cześć',
      greetingName: (n) => `Cześć, ${n}!`,
      codeLabel: 'Kod do zresetowania hasła:',
      codeValid: 'Kod jest ważny 30 minut. Jeśli nie prosiłeś o reset, zignoruj ten e-mail.',
    },
    welcome: {
      subject: 'Witaj w World Arena Flags!',
      greetingName: (n) => `Cześć, ${n}!`,
      thanks: 'Dziękujemy za rejestrację w World Arena Flags. Otrzymałeś bonusowe F-Bucks za rejestrację.',
      bye: 'Powodzenia w pojedynkach i nowych rekordach!',
    },
    passwordChanged: {
      subject: 'Hasło zmienione — World Arena Flags',
      greetingName: (n) => `Cześć, ${n}!`,
      body: 'Hasło do Twojego konta World Arena Flags zostało pomyślnie zmienione.',
      ifNotYou: 'Jeśli to nie Ty — przywróć dostęp przez „Zapomniałem hasła” w aplikacji.',
    },
    dailyReminder: {
      subject: 'Masz 5 minut? Czas na szybką praktykę flag!',
      greetingName: (n) => `Cześć ${n}!`,
      gotTime: 'Masz 5 minut? Czas na krótką praktykę flag.',
      startGame: 'ROZPOCZNIJ GRĘ',
      practiceMakes: 'Ćwiczenie czyni mistrza',
      takeFive: 'Poświęć 5 minut, żeby nauczyć się czegoś nowego dziś!',
      currentStreakLabel: 'Aktualna seria:',
      daysInRow: (n) => `${n} dni z rzędu`,
      totalLabel: 'Razem',
      currentWeekLabel: 'Bieżący tydzień',
      streakExtended: 'Seria przedłużona',
      futureDay: 'Przyszły dzień',
      weekDays: ['Śr', 'Cz', 'Pt', 'So', 'Nd', 'Pn', 'Wt'],
    },
    streakAtRisk: {
      subject: 'Nie trać serii! Nie grałeś dziś',
      greetingName: (n) => `Cześć ${n}!`,
      body: 'Nie grałeś dziś w World Arena Flags. Zagraj, żeby utrzymać serię!',
      cta: 'GRAJ TERAZ',
    },
    weeklySummary: {
      subject: 'Twój tydzień w World Arena Flags',
      greetingName: (n) => `Cześć ${n}!`,
      intro: 'Oto twoje podsumowanie tygodnia.',
      daysPlayed: 'Dni grania',
      streak: 'Aktualna seria',
      weakCountries: 'Słabe kraje do powtórki',
      progress: 'Postęp według kontynentów',
      cta: 'OTWÓRZ APP',
    },
    duelChallenge: {
      subject: 'Zostałeś wyzwany na pojedynek!',
      body: (name) => `${name} wyzwał cię na pojedynek flag. Przyjmij wyzwanie i pokaż, kto wie więcej!`,
      cta: 'PRZYJMIJ WYZWANIE',
    },
    achievement: {
      subject: 'Osiągnięcie odblokowane!',
      greetingName: (n) => `Cześć ${n}!`,
      body: 'Odblokowałeś nowe osiągnięcie w World Arena Flags.',
      achievementTitle: 'Osiągnięcie',
      cta: 'ZOBACZ W APP',
    },
    streakRecovery: {
      subject: 'Zacznij nową serię dziś!',
      greetingName: (n) => `Cześć ${n}!`,
      body: 'Opuściłeś wczoraj. Nic nie szkodzi — zacznij nową serię dziś!',
      cta: 'GRAJ TERAZ',
    },
    subscriptionReminder: {
      subject: 'Twój abonament Premium wkrótce się kończy',
      greetingName: (n) => `Cześć ${n}!`,
      body: (days) => `Twój abonament World Arena Flags Premium wygaśnie za ${days} dni. Odnów, żeby zachować korzyści!`,
      cta: 'ODNOW',
    },
  },
  pt: {
    footer: 'Este e-mail foi enviado por World Arena Flags. Se você não o esperava, ignore-o.',
    reset: {
      subject: 'Redefinir senha — World Arena Flags',
      greeting: 'Olá',
      greetingName: (n) => `Olá, ${n}!`,
      codeLabel: 'Código para redefinir a senha:',
      codeValid: 'O código é válido por 30 minutos. Se você não solicitou a redefinição, ignore este e-mail.',
    },
    welcome: {
      subject: 'Bem-vindo ao World Arena Flags!',
      greetingName: (n) => `Olá, ${n}!`,
      thanks: 'Obrigado por se registrar no World Arena Flags. Você recebeu F-Bucks de bônus pela inscrição.',
      bye: 'Boa sorte nos duelos e novos recordes!',
    },
    passwordChanged: {
      subject: 'Senha alterada — World Arena Flags',
      greetingName: (n) => `Olá, ${n}!`,
      body: 'A senha da sua conta World Arena Flags foi alterada com sucesso.',
      ifNotYou: 'Se não foi você — restaure o acesso por «Esqueci a senha» no app.',
    },
    dailyReminder: {
      subject: 'Tem 5 minutos? Hora de praticar bandeiras!',
      greetingName: (n) => `Oi ${n}!`,
      gotTime: 'Tem 5 minutos? Hora de uma prática rápida de bandeiras.',
      startGame: 'JOGAR',
      practiceMakes: 'A prática leva à perfeição',
      takeFive: 'Reserve 5 minutos para aprender algo novo hoje!',
      currentStreakLabel: 'Sequência atual:',
      daysInRow: (n) => `${n} dias seguidos`,
      totalLabel: 'Total',
      currentWeekLabel: 'Semana atual',
      streakExtended: 'Sequência estendida',
      futureDay: 'Dia futuro',
      weekDays: ['Qua', 'Qui', 'Sex', 'Sáb', 'Dom', 'Seg', 'Ter'],
    },
    streakAtRisk: {
      subject: 'Não perca sua sequência! Você ainda não jogou hoje',
      greetingName: (n) => `Oi ${n}!`,
      body: 'Você ainda não jogou World Arena Flags hoje. Jogue agora para manter sua sequência!',
      cta: 'JOGAR AGORA',
    },
    weeklySummary: {
      subject: 'Sua semana no World Arena Flags',
      greetingName: (n) => `Oi ${n}!`,
      intro: 'Aqui está seu resumo semanal.',
      daysPlayed: 'Dias jogados',
      streak: 'Sequência atual',
      weakCountries: 'Países fracos para revisar',
      progress: 'Progresso por continente',
      cta: 'ABRIR APP',
    },
    duelChallenge: {
      subject: 'Você foi desafiado a um duelo!',
      body: (name) => `${name} desafiou você para um duelo de bandeiras. Aceite e mostre quem sabe mais!`,
      cta: 'ACEITAR DESAFIO',
    },
    achievement: {
      subject: 'Conquista desbloqueada!',
      greetingName: (n) => `Oi ${n}!`,
      body: 'Você desbloqueou uma nova conquista no World Arena Flags.',
      achievementTitle: 'Conquista',
      cta: 'VER NO APP',
    },
    streakRecovery: {
      subject: 'Comece uma nova sequência hoje!',
      greetingName: (n) => `Oi ${n}!`,
      body: 'Você perdeu ontem. Sem problemas — comece uma nova sequência hoje!',
      cta: 'JOGAR AGORA',
    },
    subscriptionReminder: {
      subject: 'Sua assinatura Premium termina em breve',
      greetingName: (n) => `Oi ${n}!`,
      body: (days) => `Sua assinatura World Arena Flags Premium expira em ${days} dia(s). Renove para manter seus benefícios!`,
      cta: 'RENOVAR',
    },
  },
  zh: {
    footer: '此邮件由 World Arena Flags 发送。如非您本人操作，请忽略。',
    reset: {
      subject: '重置密码 — World Arena Flags',
      greeting: '你好',
      greetingName: (n) => `你好，${n}！`,
      codeLabel: '密码重置码：',
      codeValid: '验证码有效期为30分钟。如非您本人请求重置，请忽略此邮件。',
    },
    welcome: {
      subject: '欢迎使用 World Arena Flags！',
      greetingName: (n) => `你好，${n}！`,
      thanks: '感谢您注册 World Arena Flags。您已获得注册奖励 F-Bucks。',
      bye: '祝您对决顺利，再创佳绩！',
    },
    passwordChanged: {
      subject: '密码已修改 — World Arena Flags',
      greetingName: (n) => `你好，${n}！`,
      body: '您的 World Arena Flags 账户密码已成功修改。',
      ifNotYou: '如非您本人操作，请通过应用内「忘记密码」恢复访问。',
    },
    dailyReminder: {
      subject: '有5分钟吗？来练练国旗吧！',
      greetingName: (n) => `你好${n}！`,
      gotTime: '有5分钟吗？来做一次简短的国旗练习吧。',
      startGame: '开始游戏',
      practiceMakes: '熟能生巧',
      takeFive: '花5分钟，今天学点新知识！',
      currentStreakLabel: '当前连续：',
      daysInRow: (n) => `连续${n}天`,
      totalLabel: '总计',
      currentWeekLabel: '本周',
      streakExtended: '连续已延续',
      futureDay: '未来日期',
      weekDays: ['周三', '周四', '周五', '周六', '周日', '周一', '周二'],
    },
    streakAtRisk: {
      subject: '别断连！您今天还没玩',
      greetingName: (n) => `你好${n}！`,
      body: '您今天还没玩 World Arena Flags。快来玩，保持您的连续记录！',
      cta: '立即玩',
    },
    weeklySummary: {
      subject: '您的 World Arena Flags 本周总结',
      greetingName: (n) => `你好${n}！`,
      intro: '这是您的本周总结。',
      daysPlayed: '游玩天数',
      streak: '当前连续',
      weakCountries: '待复习薄弱国家',
      progress: '按大洲进度',
      cta: '打开应用',
    },
    duelChallenge: {
      subject: '有人向您发起对决！',
      body: (name) => `${name} 向您发起了国旗对决。接受挑战，看看谁懂得更多！`,
      cta: '接受挑战',
    },
    achievement: {
      subject: '成就已解锁！',
      greetingName: (n) => `你好${n}！`,
      body: '您在 World Arena Flags 中解锁了新成就。',
      achievementTitle: '成就',
      cta: '在应用中查看',
    },
    streakRecovery: {
      subject: '今天开始新的连续记录！',
      greetingName: (n) => `你好${n}！`,
      body: '您昨天没玩。没关系 — 今天开始新的连续记录吧！',
      cta: '立即玩',
    },
    subscriptionReminder: {
      subject: '您的 Premium 订阅即将到期',
      greetingName: (n) => `你好${n}！`,
      body: (days) => `您的 World Arena Flags Premium 订阅将在 ${days} 天后到期。续订以保留权益！`,
      cta: '续订',
    },
  },
  ca: {
    footer: 'Aquest correu l\'ha enviat World Arena Flags. Si no l\'esperaves, ignora\'l.',
    reset: {
      subject: 'Restablir contrasenya — World Arena Flags',
      greeting: 'Hola',
      greetingName: (n) => `Hola, ${n}!`,
      codeLabel: 'Codi per restablir la contrasenya:',
      codeValid: 'El codi és vàlid 30 minuts. Si no has sol·licitat el restabliment, ignora aquest correu.',
    },
    welcome: {
      subject: 'Benvingut a World Arena Flags!',
      greetingName: (n) => `Hola, ${n}!`,
      thanks: 'Gràcies per registrar-te a World Arena Flags. Has rebut F-Bucks de bonificació per la inscripció.',
      bye: 'Bona sort en els duelos i nous rècords!',
    },
    passwordChanged: {
      subject: 'Contrasenya canviada — World Arena Flags',
      greetingName: (n) => `Hola, ${n}!`,
      body: 'La contrasenya del teu compte World Arena Flags s\'ha canviat correctament.',
      ifNotYou: 'Si no has estat tu — restaura l\'accés mitjançant «He oblidat la contrasenya» a l\'app.',
    },
    dailyReminder: {
      subject: 'Tens 5 minuts? Hora de practicar banderes!',
      greetingName: (n) => `Hola ${n}!`,
      gotTime: 'Tens 5 minuts? Hora d\'una pràctica ràpida de banderes.',
      startGame: 'JUGAR',
      practiceMakes: 'La pràctica fa el mestre',
      takeFive: 'Dedica 5 minuts a aprendre alguna cosa nova avui!',
      currentStreakLabel: 'Ratxa actual:',
      daysInRow: (n) => `${n} dies seguits`,
      totalLabel: 'Total',
      currentWeekLabel: 'Setmana actual',
      streakExtended: 'Ratxa allargada',
      futureDay: 'Dia futur',
      weekDays: ['Dc', 'Dj', 'Dv', 'Ds', 'Dg', 'Dl', 'Dt'],
    },
    streakAtRisk: {
      subject: 'No perdis la ratxa! Encara no has jugat avui',
      greetingName: (n) => `Hola ${n}!`,
      body: 'Encara no has jugat a World Arena Flags avui. Juga ara per mantenir la ratxa!',
      cta: 'JUGAR ARA',
    },
    weeklySummary: {
      subject: 'La teva setmana a World Arena Flags',
      greetingName: (n) => `Hola ${n}!`,
      intro: 'Aquí tens el teu resum setmanal.',
      daysPlayed: 'Dies jugats',
      streak: 'Ratxa actual',
      weakCountries: 'Països febles per repassar',
      progress: 'Progrés per continent',
      cta: 'OBRIR APP',
    },
    duelChallenge: {
      subject: 'T\'han desafiat a un duel!',
      body: (name) => `${name} t\'ha desafiat a un duel de banderes. Accepta i mostra qui en sap més!`,
      cta: 'ACCEPTAR DESAFIAMENT',
    },
    achievement: {
      subject: 'Assoliment desbloquejat!',
      greetingName: (n) => `Hola ${n}!`,
      body: 'Has desbloquejat un nou assoliment a World Arena Flags.',
      achievementTitle: 'Assoliment',
      cta: 'VEURE A L\'APP',
    },
    streakRecovery: {
      subject: 'Comença una nova ratxa avui!',
      greetingName: (n) => `Hola ${n}!`,
      body: 'Ahir no vas jugar. Cap problema — comença una nova ratxa avui!',
      cta: 'JUGAR ARA',
    },
    subscriptionReminder: {
      subject: 'La teva subscripció Premium acaba aviat',
      greetingName: (n) => `Hola ${n}!`,
      body: (days) => `La teva subscripció World Arena Flags Premium caduca en ${days} dia(s). Renova per mantenir els beneficis!`,
      cta: 'RENOVAR',
    },
  },
  uk: {
    footer: 'Цей лист надіслано сервісом World Arena Flags. Якщо ви його не очікували — проігноруйте.',
    reset: {
      subject: 'Скидання пароля — World Arena Flags',
      greeting: 'Привіт',
      greetingName: (n) => `Привіт, ${n}!`,
      codeLabel: 'Код для скидання пароля:',
      codeValid: 'Код дійсний 30 хвилин. Якщо ви не запитували скидання — проігноруйте цей лист.',
    },
    welcome: {
      subject: 'Ласкаво просимо до World Arena Flags!',
      greetingName: (n) => `Привіт, ${n}!`,
      thanks: 'Дякуємо за реєстрацію в World Arena Flags. Ви отримали бонусні F-Bucks за реєстрацію.',
      bye: 'Успіхів у дуелях та нових рекордів!',
    },
    passwordChanged: {
      subject: 'Пароль змінено — World Arena Flags',
      greetingName: (n) => `Привіт, ${n}!`,
      body: 'Пароль вашого облікового запису World Arena Flags успішно змінено.',
      ifNotYou: 'Якщо це були не ви — терміново відновіть доступ через «Забули пароль» у додатку.',
    },
    dailyReminder: {
      subject: 'Є 5 хвилин? Час тренувати прапори!',
      greetingName: (n) => `Привіт, ${n}!`,
      gotTime: 'Є 5 хвилин? Час невеличкої практики з прапорів.',
      startGame: 'ПОЧАТИ ГРУ',
      practiceMakes: 'Практика веде до прогресу',
      takeFive: 'Знайди 5 хвилин і дізнайся щось нове сьогодні!',
      currentStreakLabel: 'Поточна серія:',
      daysInRow: (n) => `${n} дн. поспіль`,
      totalLabel: 'Всього',
      currentWeekLabel: 'Поточний тиждень',
      streakExtended: 'Серію продовжено',
      futureDay: 'Майбутній день',
      weekDays: ['Ср', 'Чт', 'Пт', 'Сб', 'Нд', 'Пн', 'Вт'],
    },
    streakAtRisk: {
      subject: 'Не втрать серію! Ти ще не грав сьогодні',
      greetingName: (n) => `Привіт, ${n}!`,
      body: 'Ти ще не грав сьогодні в World Arena Flags. Зайди та продовж серію!',
      cta: 'ГРАТИ',
    },
    weeklySummary: {
      subject: 'Тиждень у World Arena Flags',
      greetingName: (n) => `Привіт, ${n}!`,
      intro: 'Ось твоя тижнева зведенка.',
      daysPlayed: 'Днів зіграно',
      streak: 'Поточна серія',
      weakCountries: 'Слабкі країни для повторення',
      progress: 'Прогрес по континентах',
      cta: 'ВІДКРИТИ',
    },
    duelChallenge: {
      subject: 'Тебе викликали на дуель!',
      body: (name) => `${name} викликав тебе на дуель з прапорів. Прийми виклик і покажи, хто знає більше!`,
      cta: 'ПРИЙНЯТИ ВИКЛИК',
    },
    achievement: {
      subject: 'Досягнення розблоковано!',
      greetingName: (n) => `Привіт, ${n}!`,
      body: 'Ти розблокував нове досягнення в World Arena Flags.',
      achievementTitle: 'Досягнення',
      cta: 'ДИВИТИСЬ В ДОДАТКУ',
    },
    streakRecovery: {
      subject: 'Почни нову серію сьогодні!',
      greetingName: (n) => `Привіт, ${n}!`,
      body: 'Ти пропустив вчора. Нічого — почни нову серію сьогодні!',
      cta: 'ГРАТИ',
    },
    subscriptionReminder: {
      subject: 'Підписка Premium скоро закінчиться',
      greetingName: (n) => `Привіт, ${n}!`,
      body: (days) => `Підписка World Arena Flags Premium закінчиться через ${days} дн. Продовж, щоб зберегти переваги!`,
      cta: 'ПРОДОВЖИТИ',
    },
  },
};

function localeFromAcceptLanguage(header) {
  if (!header) return 'en';
  const raw = header.split(',')[0].trim().toLowerCase();
  const first = raw.substring(0, 2);
  if (first === 'pt' && (raw.startsWith('pt-br') || raw.startsWith('pt_br'))) return 'pt';
  return emailLocale[first] ? first : 'en';
}

function wrapHtml(title, bodyHtml, locale = 'en') {
  const L = emailLocale[locale] || emailLocale.en;
  const footer = L.footer || emailLocale.en.footer;
  return `<!DOCTYPE html>
<html lang="${locale}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
</head>
<body style="margin:0; padding:20px; background:#f4f4f5; ${baseStyles}">
  <div style="${cardStyle}">
    <div style="text-align:center; margin-bottom:20px;">
      <span style="font-size:18px; font-weight:600; color:#1a5fb4;">World Arena Flags</span>
    </div>
    ${bodyHtml}
    <div style="${footerStyle}">
      ${escapeHtml(footer)}
    </div>
  </div>
</body>
</html>`;
}

function escapeHtml(s) {
  if (!s) return '';
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function sendMail(toEmail, subject, text, html) {
  if (!apiKey || !domain) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const from = process.env.MAILGUN_FROM || `World Arena <noreply@${domain}>`;
    const form = new FormData();
    form.append('from', from);
    form.append('to', toEmail);
    form.append('subject', subject);
    form.append('text', text);
    if (html) form.append('html', Buffer.from(html, 'utf8'), { contentType: 'text/html; charset=utf-8' });

    const opts = {
      host,
      path: '/v3/' + encodeURIComponent(domain) + '/messages',
      method: 'POST',
      headers: {
        ...form.getHeaders(),
        'Authorization': 'Basic ' + Buffer.from('api:' + apiKey).toString('base64')
      }
    };

    const req = https.request(opts, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const body = Buffer.concat(chunks).toString();
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log('[mailgun] Sent to=%s subject=%s', toEmail, subject);
          resolve();
        } else {
          console.error('[mailgun] Failed to=%s subject=%s status=%s body=%s', toEmail, subject, res.statusCode, body);
          reject(new Error('Mailgun ' + res.statusCode + ': ' + body));
        }
      });
    });
    req.on('error', (err) => {
      console.error('[mailgun] Request error to=%s subject=%s err=%s', toEmail, subject, err.message);
      reject(err);
    });
    form.pipe(req);
  });
}

function sendResetEmail(toEmail, code, username, locale = 'en') {
  const L = (emailLocale[locale] || emailLocale.en).reset;
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.greeting + '!';
  const subject = L.subject;
  const text = [greeting, '', L.codeLabel + ' ' + code, '', L.codeValid, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 8px;">${escapeHtml(L.codeLabel)}</p>
    <div style="${codeStyle}">${escapeHtml(code)}</div>
    <p style="margin:0; font-size:14px; color:#666;">${escapeHtml(L.codeValid)}</p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendWelcomeEmail(toEmail, username, locale = 'en') {
  const L = (emailLocale[locale] || emailLocale.en).welcome;
  const name = username ? escapeHtml(username) : (locale === 'ru' ? 'игрок' : 'player');
  const greeting = L.greetingName(name);
  const subject = L.subject;
  const text = [greeting, '', L.thanks, '', L.bye, '', '— World Arena Flags'].join('\n');
  const thanksHtml = escapeHtml(L.thanks).replace(/World Arena Flags/g, '<strong>World Arena Flags</strong>');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 16px;">${thanksHtml}</p>
    <p style="margin:0;">${escapeHtml(L.bye)}</p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendPasswordChangedEmail(toEmail, username, locale = 'en') {
  const L = (emailLocale[locale] || emailLocale.en).passwordChanged;
  const name = username ? escapeHtml(username) : (locale === 'ru' ? 'пользователь' : 'user');
  const greeting = L.greetingName(name);
  const subject = L.subject;
  const text = [greeting, '', L.body, L.ifNotYou, '', '— World Arena Flags'].join('\n');
  const bodyHtml = escapeHtml(L.body).replace(/World Arena Flags/g, '<strong>World Arena Flags</strong>');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 16px;">${bodyHtml}</p>
    <p style="margin:0; font-size:14px; color:#666;">${escapeHtml(L.ifNotYou)}</p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

/**
 * Ежедневное напоминание поиграть.
 * @param {string} toEmail
 * @param {string} username
 * @param {number} currentStreak - дней подряд в игре
 * @param {string[]} weekStatuses - 7 элементов: 'extended' | 'future' | 'missed'
 * @param {number} [totalDays] - всего дней в игре (опционально)
 * @param {string} [locale]
 * @param {string} [startGameUrl] - ссылка на приложение (deep link или App Store)
 */
function sendDailyReminderEmail(toEmail, username, currentStreak, weekStatuses, totalDays, locale = 'en', startGameUrl) {
  const L = (emailLocale[locale] || emailLocale.en).dailyReminder;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.gotTime;
  const subject = L.subject;
  const gameUrl = startGameUrl || 'https://apps.apple.com/app/world-arena-flags/id6479476272';
  const weekRows = (L.weekDays || ['We', 'Th', 'Fr', 'Sa', 'Su', 'Mo', 'Tu']).map((day, i) => {
    const status = weekStatuses && weekStatuses[i];
    const label = status === 'extended' ? L.streakExtended : (status === 'future' ? L.futureDay : L.streakExtended);
    return `<td style="padding:8px; text-align:center; font-size:12px; color:#666;">${escapeHtml(day)}<br><span style="font-size:10px;">${escapeHtml(label)}</span></td>`;
  }).join('');
  const streakText = typeof L.daysInRow === 'function' ? L.daysInRow(currentStreak) : `${currentStreak}`;
  const totalLine = totalDays != null ? `<br><span style="font-size:14px; color:#666;">${escapeHtml(L.totalLabel)}: ${totalDays}</span>` : '';
  const text = [greeting, '', L.gotTime, '', L.practiceMakes, L.takeFive, '', L.currentStreakLabel + ' ' + streakText, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 8px; font-size:18px;">${greeting}</p>
    <p style="margin:0 0 20px; font-size:16px; color:#555;">${escapeHtml(L.gotTime)}</p>
    <div style="text-align:center; margin:24px 0;">
      <span style="font-size:20px; font-weight:600; color:#1a5fb4;">World Arena Flags</span>
    </div>
    <p style="text-align:center; margin:0 0 24px;">
      <a href="${escapeHtml(gameUrl)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.startGame)}</a>
    </p>
    <p style="margin:0 0 8px; font-size:14px; color:#666;">${escapeHtml(L.practiceMakes)}</p>
    <p style="margin:0 0 24px; font-size:14px;">${escapeHtml(L.takeFive)}</p>
    <p style="margin:0 0 8px;"><strong>${escapeHtml(L.currentStreakLabel)}</strong> ${escapeHtml(streakText)}</p>
    <p style="margin:0 0 16px; font-size:14px; color:#666;">${escapeHtml(L.currentWeekLabel)}${totalLine}</p>
    <table style="width:100%; border-collapse:collapse; margin:16px 0;">
      <tr>${weekRows}</tr>
    </table>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

const defaultAppUrl = 'https://apps.apple.com/app/world-arena-flags/id6479476272';

function sendStreakAtRiskEmail(toEmail, username, locale = 'en', appUrl) {
  const L = (emailLocale[locale] || emailLocale.en).streakAtRisk;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.body;
  const subject = L.subject;
  const url = appUrl || defaultAppUrl;
  const text = [greeting, '', L.body, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 24px;">${escapeHtml(L.body)}</p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendWeeklySummaryEmail(toEmail, username, locale = 'en', appUrl) {
  const L = (emailLocale[locale] || emailLocale.en).weeklySummary;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.intro;
  const subject = L.subject;
  const url = appUrl || defaultAppUrl;
  const text = [greeting, '', L.intro, '', L.daysPlayed, L.streak, L.weakCountries, L.progress, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 16px;">${escapeHtml(L.intro)}</p>
    <p style="margin:0 0 8px;"><strong>${escapeHtml(L.daysPlayed)}</strong></p>
    <p style="margin:0 0 8px;"><strong>${escapeHtml(L.streak)}</strong></p>
    <p style="margin:0 0 8px;"><strong>${escapeHtml(L.weakCountries)}</strong></p>
    <p style="margin:0 0 24px;"><strong>${escapeHtml(L.progress)}</strong></p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendDuelChallengeEmail(toEmail, challengerName, locale = 'en', duelDeepLink) {
  const L = (emailLocale[locale] || emailLocale.en).duelChallenge;
  if (!L) return Promise.resolve();
  const body = typeof L.body === 'function' ? L.body(escapeHtml(challengerName)) : L.body;
  const subject = L.subject;
  const url = duelDeepLink || defaultAppUrl;
  const text = [body, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 24px;">${body}</p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendAchievementEmail(toEmail, username, achievementTitle, locale = 'en', appUrl) {
  const L = (emailLocale[locale] || emailLocale.en).achievement;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.body;
  const subject = L.subject;
  const url = appUrl || defaultAppUrl;
  const title = achievementTitle ? escapeHtml(achievementTitle) : escapeHtml(L.achievementTitle);
  const text = [greeting, '', L.body, '', (achievementTitle || L.achievementTitle || ''), '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 8px;">${escapeHtml(L.body)}</p>
    <p style="margin:0 0 24px;"><strong>${title}</strong></p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendStreakRecoveryEmail(toEmail, username, locale = 'en', appUrl) {
  const L = (emailLocale[locale] || emailLocale.en).streakRecovery;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : L.body;
  const subject = L.subject;
  const url = appUrl || defaultAppUrl;
  const text = [greeting, '', L.body, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 24px;">${escapeHtml(L.body)}</p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

function sendSubscriptionReminderEmail(toEmail, username, daysLeft, locale = 'en', renewUrl) {
  const L = (emailLocale[locale] || emailLocale.en).subscriptionReminder;
  if (!L) return Promise.resolve();
  const greeting = username ? L.greetingName(escapeHtml(username)) : (typeof L.body === 'function' ? L.body(daysLeft) : L.body);
  const subject = L.subject;
  const bodyText = typeof L.body === 'function' ? L.body(daysLeft) : L.body;
  const url = renewUrl || defaultAppUrl;
  const text = [greeting, '', bodyText, '', '— World Arena Flags'].join('\n');
  const html = wrapHtml(L.subject, `
    <p style="margin:0 0 16px;">${greeting}</p>
    <p style="margin:0 0 24px;">${escapeHtml(bodyText)}</p>
    <p style="text-align:center;"><a href="${escapeHtml(url)}" style="display:inline-block; background:linear-gradient(135deg, #1a5fb4 0%, #3584e4 100%); color:#fff; padding:14px 28px; border-radius:8px; text-decoration:none; font-weight:600;">${escapeHtml(L.cta)}</a></p>
  `, locale);
  return sendMail(toEmail, subject, text, html);
}

module.exports = {
  sendResetEmail,
  sendWelcomeEmail,
  sendPasswordChangedEmail,
  sendDailyReminderEmail,
  sendStreakAtRiskEmail,
  sendWeeklySummaryEmail,
  sendDuelChallengeEmail,
  sendAchievementEmail,
  sendStreakRecoveryEmail,
  sendSubscriptionReminderEmail,
  localeFromAcceptLanguage
};
