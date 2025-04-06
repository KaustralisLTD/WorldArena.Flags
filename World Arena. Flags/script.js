// Конфигурация
const CONFIG = {
    questionsPerGame: 20,
    difficulties: {
        easy: { timer: 20, regions: ['Europe', 'Asia'] },
        medium: { timer: 15, regions: ['Europe', 'Asia', 'Americas'] },
        hard: { timer: 10, regions: 'all' }
    }
};

// Состояние приложения
const state = {
    flags: [],
    usedFlags: [],
    score: 0,
    currentFlag: null,
    currentQuestion: 0,
    timer: null,
    statistics: {
        totalGames: 0,
        bestScore: 0,
        correctAnswers: 0,
        totalAnswers: 0
    },
    selectedRegions: ['all']
};

// Добавить в начало файла после CONFIG
let currentLang = localStorage.getItem('preferred-language') || 'ru';

// Функция перевода интерфейса
function translateUI() {
    document.querySelectorAll('[data-i18n]').forEach(element => {
        const key = element.getAttribute('data-i18n');
        element.textContent = TRANSLATIONS[currentLang][key];
        
        // Обновляем заголовок страницы без эмодзи
        if (element.tagName === 'TITLE') {
            element.textContent = TRANSLATIONS[currentLang][key].replace('🌎 ', '');
        }
    });
}

// Загрузка статистики из localStorage
function loadStatistics() {
    const saved = localStorage.getItem('flagQuizStats');
    if (saved) {
        state.statistics = JSON.parse(saved);
        updateStatisticsDisplay();
    }
}

// Обновление отображения статистики
function updateStatisticsDisplay() {
    document.getElementById('total-games').textContent = state.statistics.totalGames;
    document.getElementById('best-score').textContent = state.statistics.bestScore;
    document.getElementById('correct-answers').textContent = 
        `${state.statistics.correctAnswers} (${Math.round(state.statistics.correctAnswers / state.statistics.totalAnswers * 100) || 0}%)`;
}

// Сохранение статистики
function saveStatistics() {
    localStorage.setItem('flagQuizStats', JSON.stringify(state.statistics));
    updateStatisticsDisplay();
}

// Обновление прогресс-бара
function updateProgress() {
    const progress = (state.currentQuestion / CONFIG.questionsPerGame) * 100;
    document.querySelector('.progress-fill').style.width = `${progress}%`;
}

// Вибрация при ответе
function vibrate(isCorrect) {
    if ('vibrate' in navigator) {
        if (isCorrect) {
            navigator.vibrate(100);
        } else {
            navigator.vibrate([100, 50, 100]);
        }
    }
}

// Поделиться результатом
async function shareResult() {
    try {
        const shareText = TRANSLATIONS[currentLang].shareMessage.replace('{score}', state.score);
        await navigator.share({
            title: document.title,
            text: shareText,
            url: window.location.href
        });
    } catch (err) {
        console.error('Ошибка при попытке поделиться:', err);
    }
}

// Добавим украинские названия стран (полный список)
const ukrainianCountryNames = {
    // Существующие переводы для Европы и Азии
    'Switzerland': 'Швейцарія',
    'Hungary': 'Угорщина',
    'Taiwan': 'Тайвань',
    'Italy': 'Італія',
    'Indonesia': 'Індонезія',
    'Laos': 'Лаос',
    'Andorra': 'Андорра',
    'France': 'Франція',
    'North Macedonia': 'Північна Македонія',
    'China': 'Китай',
    'Yemen': 'Ємен',
    'Guernsey': 'Гернсі',
    'Svalbard and Jan Mayen': 'Шпіцберген та Ян-Маєн',
    'Faroe Islands': 'Фарерські острови',
    'Uzbekistan': 'Узбекистан',
    'Sri Lanka': 'Шрі-Ланка',
    'Palestine': 'Палестина',
    'Bangladesh': 'Бангладеш',
    'Singapore': 'Сінгапур',
    'Turkey': 'Туреччина',
    'Afghanistan': 'Афганістан',
    'United Kingdom': 'Велика Британія',
    'Finland': 'Фінляндія',
    'Azerbaijan': 'Азербайджан',
    'North Korea': 'Північна Корея',
    'Greece': 'Греція',
    'Croatia': 'Хорватія',
    'Netherlands': 'Нідерланди',
    'Liechtenstein': 'Ліхтенштейн',
    'Nepal': 'Непал',
    'Georgia': 'Грузія',
    'Pakistan': 'Пакистан',
    'Monaco': 'Монако',
    'Lebanon': 'Ліван',
    'Qatar': 'Катар',
    'India': 'Індія',
    'Syria': 'Сирія',
    'Montenegro': 'Чорногорія',
    'Ukraine': 'Україна',
    'Isle of Man': 'Острів Мен',
    'United Arab Emirates': 'Об\'єднані Арабські Емірати',
    'Bulgaria': 'Болгарія',
    'Germany': 'Німеччина',
    'Cambodia': 'Камбоджа',
    'Iraq': 'Ірак',
    'Sweden': 'Швеція',
    'Kyrgyzstan': 'Киргизстан',
    'Russia': 'Росія',
    'Malaysia': 'Малайзія',
    'Cyprus': 'Кіпр',
    'Saudi Arabia': 'Саудівська Аравія',
    'Bosnia and Herzegovina': 'Боснія і Герцеговина',
    'Spain': 'Іспанія',
    'Slovenia': 'Словенія',
    'Oman': 'Оман',
    'Macau': 'Макао',
    'San Marino': 'Сан-Марино',
    'Iceland': 'Ісландія',
    'Luxembourg': 'Люксембург',
    'Thailand': 'Таїланд',
    'Belarus': 'Білорусь',
    'Latvia': 'Латвія',
    'Philippines': 'Філіппіни',
    'Gibraltar': 'Гібралтар',
    'Denmark': 'Данія',
    'Bahrain': 'Бахрейн',
    'Czechia': 'Чехія',
    'Estonia': 'Естонія',
    'Romania': 'Румунія',
    'Timor-Leste': 'Східний Тимор',
    'Vietnam': 'В\'єтнам',
    'Vatican City': 'Ватикан',
    'Hong Kong': 'Гонконг',
    'Austria': 'Австрія',
    'Turkmenistan': 'Туркменістан',
    'Ireland': 'Ірландія',
    'Norway': 'Норвегія',
    'Åland Islands': 'Аландські острови',
    'South Korea': 'Південна Корея',
    'Jordan': 'Йорданія',
    'Lithuania': 'Литва',
    'Slovakia': 'Словаччина',
    'Kazakhstan': 'Казахстан',
    'Moldova': 'Молдова',
    'Armenia': 'Вірменія',
    'Jersey': 'Джерсі',
    'Japan': 'Японія',
    'Tajikistan': 'Таджикистан',
    'Malta': 'Мальта',
    'Kosovo': 'Косово',
    'Kuwait': 'Кувейт',
    'Maldives': 'Мальдіви',
    'Iran': 'Іран',
    'Albania': 'Албанія',
    'Serbia': 'Сербія',
    'Myanmar': 'М\'янма',
    'Bhutan': 'Бутан',
    'Poland': 'Польща',
    'Brunei': 'Бруней',
    'Mongolia': 'Монголія',
    'Portugal': 'Португалія',
    'Belgium': 'Бельгія',
    'Israel': 'Ізраїль',

    // Америки
    'United States': 'Сполучені Штати Америки',
    'Canada': 'Канада',
    'Mexico': 'Мексика',
    'Brazil': 'Бразилія',
    'Argentina': 'Аргентина',
    'Chile': 'Чилі',
    'Colombia': 'Колумбія',
    'Peru': 'Перу',
    'Venezuela': 'Венесуела',
    'Ecuador': 'Еквадор',
    'Bolivia': 'Болівія',
    'Paraguay': 'Парагвай',
    'Uruguay': 'Уругвай',
    'Guyana': 'Гаяна',
    'Suriname': 'Суринам',
    'French Guiana': 'Французька Гвіана',
    'Panama': 'Панама',
    'Costa Rica': 'Коста-Рика',
    'Nicaragua': 'Нікарагуа',
    'Honduras': 'Гондурас',
    'El Salvador': 'Сальвадор',
    'Guatemala': 'Гватемала',
    'Belize': 'Беліз',
    'Cuba': 'Куба',
    'Haiti': 'Гаїті',
    'Dominican Republic': 'Домініканська Республіка',
    'Jamaica': 'Ямайка',
    'Trinidad and Tobago': 'Тринідад і Тобаго',
    'Bahamas': 'Багамські Острови',
    'Barbados': 'Барбадос',

    // Африка
    'Egypt': 'Єгипет',
    'South Africa': 'Південно-Африканська Республіка',
    'Nigeria': 'Нігерія',
    'Kenya': 'Кенія',
    'Ethiopia': 'Ефіопія',
    'Ghana': 'Гана',
    'Morocco': 'Марокко',
    'Algeria': 'Алжир',
    'Tunisia': 'Туніс',
    'Libya': 'Лівія',
    'Sudan': 'Судан',
    'South Sudan': 'Південний Судан',
    'Uganda': 'Уганда',
    'Tanzania': 'Танзанія',
    'Rwanda': 'Руанда',
    'Burundi': 'Бурунді',
    'Congo': 'Конго',
    'Democratic Republic of the Congo': 'Демократична Республіка Конго',
    'Angola': 'Ангола',
    'Zambia': 'Замбія',
    'Zimbabwe': 'Зімбабве',
    'Mozambique': 'Мозамбік',
    'Madagascar': 'Мадагаскар',
    'Cameroon': 'Камерун',
    'Ivory Coast': 'Кот-д\'Івуар',
    'Senegal': 'Сенегал',
    'Mali': 'Малі',
    'Burkina Faso': 'Буркіна-Фасо',
    'Niger': 'Нігер',
    'Chad': 'Чад',
    'Somalia': 'Сомалі',
    'Eritrea': 'Еритрея',
    'Mauritania': 'Мавританія',
    'Namibia': 'Намібія',
    'Botswana': 'Ботсвана',
    'Lesotho': 'Лесото',
    'Eswatini': 'Есватіні',
    'Malawi': 'Малаві',
    'Gambia': 'Гамбія',
    'Guinea': 'Гвінея',
    'Sierra Leone': 'Сьєрра-Леоне',
    'Liberia': 'Ліберія',
    'Togo': 'Того',
    'Benin': 'Бенін',
    'Central African Republic': 'Центральноафриканська Республіка',
    'Gabon': 'Габон',
    'Equatorial Guinea': 'Екваторіальна Гвінея',
    'Djibouti': 'Джибуті',

    // Океания
    'Australia': 'Австралія',
    'New Zealand': 'Нова Зеландія',
    'Papua New Guinea': 'Папуа-Нова Гвінея',
    'Fiji': 'Фіджі',
    'Solomon Islands': 'Соломонові Острови',
    'Vanuatu': 'Вануату',
    'New Caledonia': 'Нова Каледонія',
    'French Polynesia': 'Французька Полінезія',
    'Samoa': 'Самоа',
    'Tonga': 'Тонга',

    // Карибский бассейн
    'Puerto Rico': 'Пуерто-Рико',
    'Martinique': 'Мартиніка',
    'Guadeloupe': 'Гваделупа',
    'Saint Lucia': 'Сент-Люсія',
    'Grenada': 'Гренада',
    'Saint Vincent and the Grenadines': 'Сент-Вінсент і Гренадини',
    'Antigua and Barbuda': 'Антигуа і Барбуда',
    'Dominica': 'Домініка',
    'Saint Kitts and Nevis': 'Сент-Кітс і Невіс',

    // Другие территории и зависимые территории
    'Greenland': 'Гренландія',
    'Falkland Islands': 'Фолклендські острови',
    'Bermuda': 'Бермудські острови',
    'Cayman Islands': 'Кайманові острови',
    'Virgin Islands': 'Віргінські острови',
    'Reunion': 'Реюньйон',
    'Mayotte': 'Майотта',
    'Seychelles': 'Сейшельські острови',
    'Mauritius': 'Маврикій',
    'Comoros': 'Коморські острови',
    'Cape Verde': 'Кабо-Верде',
    'Sao Tome and Principe': 'Сан-Томе і Принсіпі'
};

// Добавим каталанские названия стран
const catalanCountryNames = {
    // Европа и Азия
    'Switzerland': 'Suïssa',
    'Hungary': 'Hongria',
    'Taiwan': 'Taiwan',
    'Italy': 'Itàlia',
    'Indonesia': 'Indonèsia',
    'Laos': 'Laos',
    'Andorra': 'Andorra',
    'France': 'França',
    'North Macedonia': 'Macedònia del Nord',
    'China': 'Xina',
    'Yemen': 'Iemen',
    'Guernsey': 'Guernsey',
    'Svalbard and Jan Mayen': 'Svalbard i Jan Mayen',
    'Faroe Islands': 'Illes Fèroe',
    'Uzbekistan': 'Uzbekistan',
    'Sri Lanka': 'Sri Lanka',
    'Palestine': 'Palestina',
    'Bangladesh': 'Bangladesh',
    'Singapore': 'Singapur',
    'Turkey': 'Turquia',
    'Afghanistan': 'Afganistan',
    'United Kingdom': 'Regne Unit',
    'Finland': 'Finlàndia',
    'Azerbaijan': 'Azerbaidjan',
    'North Korea': 'Corea del Nord',
    'Greece': 'Grècia',
    'Croatia': 'Croàcia',
    'Netherlands': 'Països Baixos',
    'Liechtenstein': 'Liechtenstein',
    'Nepal': 'Nepal',
    'Georgia': 'Geòrgia',
    'Pakistan': 'Pakistan',
    'Monaco': 'Mònaco',
    'Lebanon': 'Líban',
    'Qatar': 'Qatar',
    'India': 'Índia',
    'Syria': 'Síria',
    'Montenegro': 'Montenegro',
    'Ukraine': 'Ucraïna',
    'Isle of Man': 'Illa de Man',
    'United Arab Emirates': 'Emirats Àrabs Units',
    'Bulgaria': 'Bulgària',
    'Germany': 'Alemanya',
    'Cambodia': 'Cambodja',
    'Iraq': 'Iraq',
    'Sweden': 'Suècia',
    'Kyrgyzstan': 'Kirguizistan',
    'Russia': 'Rússia',
    'Malaysia': 'Malàisia',
    'Cyprus': 'Xipre',
    'Saudi Arabia': 'Aràbia Saudita',
    'Bosnia and Herzegovina': 'Bòsnia i Hercegovina',
    'Spain': 'Espanya',
    'Slovenia': 'Eslovènia',
    'Oman': 'Oman',
    'Macau': 'Macau',
    'San Marino': 'San Marino',
    'Iceland': 'Islàndia',
    'Luxembourg': 'Luxemburg',
    'Thailand': 'Tailàndia',
    'Belarus': 'Bielorússia',
    'Latvia': 'Letònia',
    'Philippines': 'Filipines',
    'Gibraltar': 'Gibraltar',
    'Denmark': 'Dinamarca',
    'Bahrain': 'Bahrain',
    'Czechia': 'República Txeca',
    'Estonia': 'Estònia',
    'Romania': 'Romania',
    'Timor-Leste': 'Timor Oriental',
    'Vietnam': 'Vietnam',
    'Vatican City': 'Ciutat del Vaticà',
    'Hong Kong': 'Hong Kong',
    'Austria': 'Àustria',
    'Turkmenistan': 'Turkmenistan',
    'Ireland': 'Irlanda',
    'Norway': 'Noruega',
    'Åland Islands': 'Illes Åland',
    'South Korea': 'Corea del Sud',
    'Jordan': 'Jordània',
    'Lithuania': 'Lituània',
    'Slovakia': 'Eslovàquia',
    'Kazakhstan': 'Kazakhstan',
    'Moldova': 'Moldàvia',
    'Armenia': 'Armènia',
    'Jersey': 'Jersey',
    'Japan': 'Japó',
    'Tajikistan': 'Tadjikistan',
    'Malta': 'Malta',
    'Kosovo': 'Kosovo',
    'Kuwait': 'Kuwait',
    'Maldives': 'Maldives',
    'Iran': 'Iran',
    'Albania': 'Albània',
    'Serbia': 'Sèrbia',
    'Myanmar': 'Myanmar',
    'Bhutan': 'Bhutan',
    'Poland': 'Polònia',
    'Brunei': 'Brunei',
    'Mongolia': 'Mongòlia',
    'Portugal': 'Portugal',
    'Belgium': 'Bèlgica',
    'Israel': 'Israel',

    // Америки
    'United States': 'Estats Units',
    'Canada': 'Canadà',
    'Mexico': 'Mèxic',
    'Brazil': 'Brasil',
    'Argentina': 'Argentina',
    'Chile': 'Xile',
    'Colombia': 'Colòmbia',
    'Peru': 'Perú',
    'Venezuela': 'Veneçuela',
    'Ecuador': 'Equador',
    'Bolivia': 'Bolívia',
    'Paraguay': 'Paraguai',
    'Uruguay': 'Uruguai',
    'Guyana': 'Guyana',
    'Suriname': 'Surinam',
    'French Guiana': 'Guaiana Francesa',
    'Panama': 'Panamà',
    'Costa Rica': 'Costa Rica',
    'Nicaragua': 'Nicaragua',
    'Honduras': 'Hondures',
    'El Salvador': 'El Salvador',
    'Guatemala': 'Guatemala',
    'Belize': 'Belize',
    'Cuba': 'Cuba',
    'Haiti': 'Haití',
    'Dominican Republic': 'República Dominicana',
    'Jamaica': 'Jamaica',
    'Trinidad and Tobago': 'Trinitat i Tobago',
    'Bahamas': 'Bahames',
    'Barbados': 'Barbados',

    // Африка
    'Egypt': 'Egipte',
    'South Africa': 'Sud-àfrica',
    'Nigeria': 'Nigèria',
    'Kenya': 'Kenya',
    'Ethiopia': 'Etiòpia',
    'Ghana': 'Ghana',
    'Morocco': 'Marroc',
    'Algeria': 'Algèria',
    'Tunisia': 'Tunísia',
    'Libya': 'Líbia',
    'Sudan': 'Sudan',
    'South Sudan': 'Sudan del Sud',
    'Uganda': 'Uganda',
    'Tanzania': 'Tanzània',
    'Rwanda': 'Rwanda',
    'Burundi': 'Burundi',
    'Congo': 'Congo',
    'Democratic Republic of the Congo': 'República Democràtica del Congo',
    'Angola': 'Angola',
    'Zambia': 'Zàmbia',
    'Zimbabwe': 'Zimbabwe',
    'Mozambique': 'Moçambic',
    'Madagascar': 'Madagascar',
    'Cameroon': 'Camerun',
    'Ivory Coast': 'Costa d\'Ivori',
    'Senegal': 'Senegal',
    'Mali': 'Mali',
    'Burkina Faso': 'Burkina Faso',
    'Niger': 'Níger',
    'Chad': 'Txad',
    'Somalia': 'Somàlia',
    'Eritrea': 'Eritrea',
    'Mauritania': 'Mauritània',
    'Namibia': 'Namíbia',
    'Botswana': 'Botswana',
    'Lesotho': 'Lesotho',
    'Eswatini': 'Eswatini',
    'Malawi': 'Malawi',
    'Gambia': 'Gàmbia',
    'Guinea': 'Guinea',
    'Sierra Leone': 'Sierra Leone',
    'Liberia': 'Libèria',
    'Togo': 'Togo',
    'Benin': 'Benín',
    'Central African Republic': 'República Centreafricana',
    'Gabon': 'Gabon',
    'Equatorial Guinea': 'Guinea Equatorial',
    'Djibouti': 'Djibouti',

    // Океания
    'Australia': 'Austràlia',
    'New Zealand': 'Nova Zelanda',
    'Papua New Guinea': 'Papua Nova Guinea',
    'Fiji': 'Fiji',
    'Solomon Islands': 'Illes Salomó',
    'Vanuatu': 'Vanuatu',
    'New Caledonia': 'Nova Caledònia',
    'French Polynesia': 'Polinèsia Francesa',
    'Samoa': 'Samoa',
    'Tonga': 'Tonga',

    // Карибский бассейн
    'Puerto Rico': 'Puerto Rico',
    'Martinique': 'Martinica',
    'Guadeloupe': 'Guadalupe',
    'Saint Lucia': 'Santa Llúcia',
    'Grenada': 'Granada',
    'Saint Vincent and the Grenadines': 'Sant Vicent i les Grenadines',
    'Antigua and Barbuda': 'Antigua i Barbuda',
    'Dominica': 'Dominica',
    'Saint Kitts and Nevis': 'Saint Kitts i Nevis',

    // Другие территории
    'Greenland': 'Grenlàndia',
    'Falkland Islands': 'Illes Malvines',
    'Bermuda': 'Bermudes',
    'Cayman Islands': 'Illes Caiman',
    'Virgin Islands': 'Illes Verges',
    'Reunion': 'Reunió',
    'Mayotte': 'Mayotte',
    'Seychelles': 'Seychelles',
    'Mauritius': 'Maurici',
    'Comoros': 'Comores',
    'Cape Verde': 'Cap Verd',
    'Sao Tome and Principe': 'São Tomé i Príncipe'
};

// Обновляем функцию loadCountries
async function loadCountries() {
    try {
        const loadingScreen = document.querySelector('.loading-screen');
        loadingScreen.style.display = 'flex';
        
        const response = await fetch('https://restcountries.com/v3.1/all');
        const countries = await response.json();
        
        // Фильтрация стран по выбранным регионам
        let filteredCountries = countries;
        if (!state.selectedRegions.includes('all')) {
            filteredCountries = countries.filter(country => 
                state.selectedRegions.includes(country.region)
            );
        }

        // Исправляем сопоставление языковых кодов с API
        const langKey = {
            'ru': 'rus',
            'en': 'eng',
            'es': 'spa',
            'uk': 'ukr',
            'ca': 'cat',
            'zh': 'zho'
        }[currentLang];

        // Добавим отладочный вывод
        console.log('Current language:', currentLang);
        console.log('API language key:', langKey);
        console.log('Sample country translations:', countries[0].translations);
        console.log('Sample native names:', countries[0].name.nativeName);
        
        state.flags = filteredCountries
            .map(country => {
                let countryName;

                if (currentLang === 'uk') {
                    // Для украинского языка используем украинский словарь
                    countryName = ukrainianCountryNames[country.name.common] || country.name.common;
                } else if (currentLang === 'ca') {
                    // Для каталанского языка используем каталанский словарь
                    countryName = catalanCountryNames[country.name.common] || country.name.common;
                } else if (country.translations[langKey]?.common) {
                    // Для других языков используем API
                    countryName = country.translations[langKey].common;
                } else {
                    countryName = country.name.common;
                    console.log(`No translation for ${country.name.common} in ${currentLang} (${langKey})`);
                }

                return {
                    country: countryName,
                image: country.flags.png,
                    capital: country.capital?.[0] || TRANSLATIONS[currentLang].noData
                };
            })
            .filter(country => country.country && country.image);

        if (state.flags.length < 4) {
            throw new Error(TRANSLATIONS[currentLang].notEnoughCountries);
        }

        loadingScreen.style.display = 'none';
        loadNewQuestion();
    } catch (error) {
        console.error('Ошибка при загрузке стран:', error);
        alert(TRANSLATIONS[currentLang].error);
        loadingScreen.style.display = 'none';
    }
}

// Получение случайных вариантов ответов
function getRandomOptions(correctAnswer) {
    const options = [correctAnswer];
    const usedCountries = new Set([correctAnswer]);
    
    while (options.length < 4) {
        const randomCountry = state.flags[Math.floor(Math.random() * state.flags.length)].country;
        if (!usedCountries.has(randomCountry)) {
            options.push(randomCountry);
            usedCountries.add(randomCountry);
        }
    }
    
    // Перемешиваем варианты ответов
    return options.sort(() => Math.random() - 0.5);
}

// Проверка ответа
function checkAnswer(selectedAnswer) {
    clearInterval(state.timer);
    
    const isCorrect = selectedAnswer === state.currentFlag.country;
    
    if (isCorrect) {
        // Увеличиваем счет и количество правильных ответов
        state.score++;
        state.statistics.correctAnswers++;
        // Обновляем отображение счета
        document.getElementById('score').textContent = state.score;
        vibrate(true);
    } else {
        vibrate(false);
    }
    
    const optionButtons = document.querySelectorAll('.option');
    optionButtons.forEach(button => {
        button.disabled = true;
        if (button.textContent === state.currentFlag.country) {
            button.classList.add('correct');
        } else if (button.textContent === selectedAnswer) {
            button.classList.add('incorrect');
        }
    });
    
    state.statistics.totalAnswers++;
    state.currentQuestion++;
    
    if (state.currentQuestion >= CONFIG.questionsPerGame) {
        setTimeout(endGame, 1000);
    } else {
        setTimeout(loadNewQuestion, 1000);
    }
    
    updateProgress();
    saveStatistics();
}

// Окончание игры
function endGame() {
    state.statistics.totalGames++;
    if (state.score > state.statistics.bestScore) {
        state.statistics.bestScore = state.score;
    }
    saveStatistics();
    
    // Обновляем финальный экран
    document.getElementById('final-score').textContent = state.score;
    document.getElementById('final-correct-answers').textContent = 
        `${state.statistics.correctAnswers}/${CONFIG.questionsPerGame}`;
    document.getElementById('final-best-score').textContent = state.statistics.bestScore;

    // Показываем модальное окно
    const modal = document.getElementById('game-over-modal');
    modal.style.display = 'block';

    // Обработчики кнопок
    document.getElementById('share-result-btn').onclick = shareResult;
    
    document.getElementById('play-again-btn').onclick = () => {
        modal.style.display = 'none';
    resetGame();
    };
    
    document.getElementById('go-home-btn').onclick = () => {
        modal.style.display = 'none';
        // Показываем стартовый экран и полностью сбрасываем состояние
        document.getElementById('game-container').style.display = 'none';
        document.getElementById('start-screen').style.display = 'flex';
        // Полный сброс состояния
        state.score = 0;
        state.currentQuestion = 0;
        state.statistics.correctAnswers = 0;
        state.statistics.totalAnswers = 0;
        state.usedFlags = [];
        document.getElementById('score').textContent = '0';
        updateProgress();
        clearInterval(state.timer);
    };
}

// Сброс игры
function resetGame() {
    state.score = 0;
    state.currentQuestion = 0;
    state.statistics.correctAnswers = 0;
    state.statistics.totalAnswers = 0;
    state.usedFlags = [];
    document.getElementById('score').textContent = '0';
    updateProgress();
    
    // Очищаем текущий таймер
    clearInterval(state.timer);
    
    loadNewQuestion();
}

// Загрузка нового вопроса
function loadNewQuestion() {
    if (state.flags.length === 0) return;
    
    // Очищаем предыдущий таймер
    clearInterval(state.timer);
    
    // Получаем неиспользованные флаги
    const availableFlags = state.flags.filter(flag => 
        !state.usedFlags.some(used => used.country === flag.country)
    );
    
    // Если все флаги использованы, очищаем массив использованных
    if (availableFlags.length === 0) {
        state.usedFlags = [];
        state.currentFlag = state.flags[Math.floor(Math.random() * state.flags.length)];
    } else {
        // Выбираем случайный флаг из неиспользованных
        state.currentFlag = availableFlags[Math.floor(Math.random() * availableFlags.length)];
    }
    
    // Добавляем флаг в использованные
    state.usedFlags.push(state.currentFlag);
    
    const flagImage = document.getElementById('flag-image');
    
    // Предзагрузка изображения
    const img = new Image();
    img.onload = function() {
        flagImage.src = state.currentFlag.image;
    };
    img.src = state.currentFlag.image;
    
    const options = getRandomOptions(state.currentFlag.country);
    const optionButtons = document.querySelectorAll('.option');
    
    // Сначала удаляем все обработчики событий
    optionButtons.forEach(button => {
        button.replaceWith(button.cloneNode(true));
    });
    
    // Заново получаем кнопки после замены
    const newOptionButtons = document.querySelectorAll('.option');
    
    // Добавляем новые обработчики
    newOptionButtons.forEach((button, index) => {
        button.textContent = options[index];
        button.onclick = () => checkAnswer(options[index]);
        button.disabled = false;
        button.classList.remove('correct', 'incorrect');
    });

    // Добавляем таймер
    const difficulty = document.getElementById('difficulty').value;
    const timeLimit = CONFIG.difficulties[difficulty].timer;
    let timeLeft = timeLimit;
    
    document.getElementById('timer').textContent = timeLeft;
    
    state.timer = setInterval(() => {
        timeLeft--;
        const timerElement = document.getElementById('timer');
        timerElement.textContent = timeLeft;
        
        // Добавляем визуальное предупреждение
        const timerContainer = timerElement.parentElement;
        if (timeLeft <= 5) {
            timerContainer.classList.add('warning');
        } else {
            timerContainer.classList.remove('warning');
        }
        
        if (timeLeft <= 0) {
            clearInterval(state.timer);
            checkAnswer('');  // Время истекло, засчитываем неправильный ответ
        }
    }, 1000);
}

// Обработчики событий
document.getElementById('share-btn').onclick = shareResult;
document.getElementById('stats-btn').onclick = () => {
    document.getElementById('stats-modal').style.display = 'block';
};
document.querySelector('.close-modal').onclick = () => {
    document.getElementById('stats-modal').style.display = 'none';
};
document.getElementById('difficulty').onchange = loadCountries;

// Инициализация стартового экрана
function initStartScreen() {
    const startLanguage = document.getElementById('start-language');
    const startButton = document.getElementById('start-game');
    const startScreen = document.getElementById('start-screen');
    const gameContainer = document.getElementById('game-container');

    // Устанавливаем сохранённый язык
    startLanguage.value = currentLang;

    // Функция для обновления текста на стартовом экране
    function updateStartScreenText(lang) {
        startButton.textContent = TRANSLATIONS[lang].startGame;
        document.querySelector('.start-content h1').textContent = TRANSLATIONS[lang].title;
        document.title = TRANSLATIONS[lang].title.replace('🌎 ', '');
        
        // Обновляем текст для регионов
        document.querySelector('[data-i18n="selectRegions"]').textContent = TRANSLATIONS[lang].selectRegions;
        document.querySelector('[data-i18n="allRegions"]').textContent = TRANSLATIONS[lang].allRegions;
        document.querySelector('[data-i18n="europe"]').textContent = TRANSLATIONS[lang].europe;
        document.querySelector('[data-i18n="asia"]').textContent = TRANSLATIONS[lang].asia;
        document.querySelector('[data-i18n="americas"]').textContent = TRANSLATIONS[lang].americas;
        document.querySelector('[data-i18n="africa"]').textContent = TRANSLATIONS[lang].africa;
        document.querySelector('[data-i18n="oceania"]').textContent = TRANSLATIONS[lang].oceania;
    }

    // Обработчик кнопки старта
    startButton.onclick = async () => {
        currentLang = startLanguage.value;
        localStorage.setItem('preferred-language', currentLang);
        
        // Скрываем стартовый экран и показываем игру
        startScreen.style.display = 'none';
        gameContainer.style.display = 'flex';
        
        // Полный сброс состояния перед началом новой игры
        state.score = 0;
        state.currentQuestion = 0;
        state.statistics.correctAnswers = 0;
        state.statistics.totalAnswers = 0;
        state.usedFlags = [];
        document.getElementById('score').textContent = '0';
        updateProgress();
        clearInterval(state.timer);
        
        // Инициализируем игру
        translateUI();
        await loadCountries();
    };

    // Обновляем текст при выборе языка
    startLanguage.onchange = async (e) => {
        const newLang = e.target.value;
        currentLang = newLang;
        localStorage.setItem('preferred-language', currentLang);
        
        // Обновляем все тексты на стартовом экране
        updateStartScreenText(newLang);
        
        // Если игра уже запущена, обновляем названия стран
        if (gameContainer.style.display === 'flex') {
            translateUI();
            await loadCountries();
            loadNewQuestion();
        }
    };

    // Устанавливаем начальный текст
    updateStartScreenText(currentLang);
}

// Добавим функцию создания фоновых флагов
function createBackgroundFlags() {
    const backgroundFlags = document.querySelector('.background-flags');
    
    // Создаем несколько полос с флагами
    for (let i = 0; i < 5; i++) {
        const stripe = document.createElement('div');
        stripe.className = 'flag-stripe';
        stripe.style.top = `${i * 25}%`; // Распределяем полосы по высоте
        
        // URL некоторых популярных флагов
        const flagUrls = [
            'https://flagcdn.com/w160/us.png',
            'https://flagcdn.com/w160/gb.png',
            'https://flagcdn.com/w160/fr.png',
            'https://flagcdn.com/w160/de.png',
            'https://flagcdn.com/w160/it.png',
            'https://flagcdn.com/w160/es.png',
            'https://flagcdn.com/w160/pt.png',
            'https://flagcdn.com/w160/ru.png',
            'https://flagcdn.com/w160/jp.png',
            'https://flagcdn.com/w160/kr.png',
            'https://flagcdn.com/w160/cn.png',
            'https://flagcdn.com/w160/in.png'
        ];
        
        // Добавляем флаги в полосу
        for (let j = 0; j < 10; j++) {
            flagUrls.forEach(url => {
                const flag = document.createElement('img');
                flag.className = 'background-flag';
                flag.src = url;
                flag.alt = '';
                stripe.appendChild(flag);
            });
        }
        
        backgroundFlags.appendChild(stripe);
    }
}

// Добавим обработку выбора регионов
function initRegionSelector() {
    const regionCheckboxes = document.querySelectorAll('.region-option input[type="checkbox"]');
    const allRegionsCheckbox = document.querySelector('.region-option input[value="all"]');

    function updateRegionSelection() {
        const selectedCheckboxes = Array.from(regionCheckboxes)
            .filter(checkbox => checkbox.checked && checkbox.value !== 'all');

        if (selectedCheckboxes.length === 0) {
            allRegionsCheckbox.checked = true;
            state.selectedRegions = ['all'];
        } else {
            allRegionsCheckbox.checked = false;
            state.selectedRegions = selectedCheckboxes.map(checkbox => checkbox.value);
        }
    }

    regionCheckboxes.forEach(checkbox => {
        checkbox.addEventListener('change', (e) => {
            if (e.target.value === 'all' && e.target.checked) {
                // Если выбран "Все регионы", снимаем остальные галочки
                regionCheckboxes.forEach(cb => {
                    if (cb.value !== 'all') cb.checked = false;
                });
                state.selectedRegions = ['all'];
            } else {
                updateRegionSelection();
            }
        });
    });
}

// Обновляем window.onload
window.onload = () => {
    loadStatistics();
    initStartScreen();
    initRegionSelector();
    createBackgroundFlags();
};