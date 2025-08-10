-- Создание расширений
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Таблица пользователей
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    preferred_language VARCHAR(5) DEFAULT 'ru',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Таблица стран/флагов 
CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(3) UNIQUE NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_ru VARCHAR(255),
    name_es VARCHAR(255),
    name_uk VARCHAR(255),
    name_ca VARCHAR(255),
    name_zh VARCHAR(255),
    region VARCHAR(50) NOT NULL,
    subregion VARCHAR(100),
    flag_url VARCHAR(500) NOT NULL,
    capital VARCHAR(255),
    population BIGINT,
    area DECIMAL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица игр
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100), -- для анонимных пользователей
    score INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL DEFAULT 0,
    duration_seconds INTEGER,
    regions TEXT[], -- массив выбранных регионов
    game_mode VARCHAR(20) DEFAULT 'standard',
    difficulty VARCHAR(20) DEFAULT 'medium',
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица ответов в играх
CREATE TABLE game_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    country_id UUID REFERENCES countries(id),
    selected_country_id UUID REFERENCES countries(id),
    is_correct BOOLEAN NOT NULL,
    answer_time_ms INTEGER,
    question_number INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица ошибок пользователей
CREATE TABLE user_mistakes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100), -- для анонимных пользователей
    country_id UUID REFERENCES countries(id) ON DELETE CASCADE,
    mistake_count INTEGER DEFAULT 1,
    last_mistake_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, country_id),
    UNIQUE(session_id, country_id)
);

-- Таблица статистики пользователей
CREATE TABLE user_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100), -- для анонимных пользователей
    total_games INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    total_correct_answers INTEGER DEFAULT 0,
    best_score INTEGER DEFAULT 0,
    best_time_seconds INTEGER,
    average_score DECIMAL(5,2),
    favorite_region VARCHAR(50),
    last_played_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id),
    UNIQUE(session_id)
);

-- Индексы для оптимизации
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_countries_region ON countries(region);
CREATE INDEX idx_countries_code ON countries(code);
CREATE INDEX idx_games_user_id ON games(user_id);
CREATE INDEX idx_games_session_id ON games(session_id);
CREATE INDEX idx_games_completed_at ON games(completed_at);
CREATE INDEX idx_game_answers_game_id ON game_answers(game_id);
CREATE INDEX idx_user_mistakes_user_id ON user_mistakes(user_id);
CREATE INDEX idx_user_mistakes_session_id ON user_mistakes(session_id);
CREATE INDEX idx_user_statistics_user_id ON user_statistics(user_id);
CREATE INDEX idx_user_statistics_session_id ON user_statistics(session_id); 