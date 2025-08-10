import express from 'express';
import Joi from 'joi';
import pool from '../config/database.js';

const router = express.Router();

// Схемы валидации
const startGameSchema = Joi.object({
  regions: Joi.array().items(
    Joi.string().valid('Europe', 'Asia', 'Africa', 'Americas', 'Oceania', 'all', 'mistakes')
  ).required(),
  gameMode: Joi.string().valid('20', '50', '100', 'all').default('20'),
  difficulty: Joi.string().valid('easy', 'medium', 'hard', 'expert', 'erudite').default('medium')
});

const submitAnswerSchema = Joi.object({
  gameId: Joi.string().uuid().required(),
  countryId: Joi.string().uuid().required(),
  selectedCountryId: Joi.string().uuid().required(),
  isCorrect: Joi.boolean().required(),
  answerTimeMs: Joi.number().integer().min(0).required(),
  questionNumber: Joi.number().integer().min(1).required()
});

const finishGameSchema = Joi.object({
  gameId: Joi.string().uuid().required(),
  score: Joi.number().integer().min(0).required(),
  totalQuestions: Joi.number().integer().min(1).required(),
  correctAnswers: Joi.number().integer().min(0).required(),
  durationSeconds: Joi.number().integer().min(0).required(),
  answers: Joi.array().items(Joi.object({
    countryId: Joi.string().uuid().required(),
    selectedCountryId: Joi.string().uuid().required(),
    isCorrect: Joi.boolean().required(),
    answerTimeMs: Joi.number().integer().min(0).required(),
    questionNumber: Joi.number().integer().min(1).required()
  })).required()
});

// Начало новой игры
router.post('/start', async (req, res, next) => {
  try {
    const { error, value } = startGameSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { regions, gameMode, difficulty } = value;
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    // Определяем количество вопросов
    const totalQuestions = gameMode === 'all' ? 250 : parseInt(gameMode);

    // Создаем запись игры
    const gameResult = await pool.query(
      `INSERT INTO games (user_id, session_id, total_questions, regions, game_mode, difficulty)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, created_at`,
      [userId, sessionId, totalQuestions, regions, gameMode, difficulty]
    );

    const game = gameResult.rows[0];

    res.status(201).json({
      message: 'Game started successfully',
      game: {
        id: game.id,
        totalQuestions: totalQuestions,
        regions: regions,
        gameMode: gameMode,
        difficulty: difficulty,
        startedAt: game.created_at
      }
    });

  } catch (error) {
    next(error);
  }
});

// Завершение игры
router.post('/finish', async (req, res, next) => {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    const { error, value } = finishGameSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { gameId, score, totalQuestions, correctAnswers, durationSeconds, answers } = value;
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    // Проверяем, что игра существует и принадлежит пользователю
    const gameCheck = await client.query(
      'SELECT id FROM games WHERE id = $1 AND (user_id = $2 OR session_id = $3)',
      [gameId, userId, sessionId]
    );

    if (gameCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'Game not found or access denied'
      });
    }

    // Обновляем информацию об игре
    await client.query(
      `UPDATE games 
       SET score = $1, correct_answers = $2, duration_seconds = $3, completed_at = NOW()
       WHERE id = $4`,
      [score, correctAnswers, durationSeconds, gameId]
    );

    // Сохраняем ответы
    for (const answer of answers) {
      await client.query(
        `INSERT INTO game_answers (game_id, country_id, selected_country_id, is_correct, answer_time_ms, question_number)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [gameId, answer.countryId, answer.selectedCountryId, answer.isCorrect, answer.answerTimeMs, answer.questionNumber]
      );

      // Добавляем ошибки в таблицу ошибок пользователя
      if (!answer.isCorrect) {
        const mistakeQuery = userId 
          ? `INSERT INTO user_mistakes (user_id, country_id, mistake_count, last_mistake_at)
             VALUES ($1, $2, 1, NOW())
             ON CONFLICT (user_id, country_id)
             DO UPDATE SET mistake_count = user_mistakes.mistake_count + 1, last_mistake_at = NOW()`
          : `INSERT INTO user_mistakes (session_id, country_id, mistake_count, last_mistake_at)
             VALUES ($1, $2, 1, NOW())
             ON CONFLICT (session_id, country_id)
             DO UPDATE SET mistake_count = user_mistakes.mistake_count + 1, last_mistake_at = NOW()`;

        await client.query(mistakeQuery, [userId || sessionId, answer.countryId]);
      }
    }

    // Обновляем статистику пользователя
    const statsQuery = userId
      ? `INSERT INTO user_statistics (user_id, total_games, total_questions, total_correct_answers, best_score, last_played_at)
         VALUES ($1, 1, $2, $3, $4, NOW())
         ON CONFLICT (user_id)
         DO UPDATE SET 
           total_games = user_statistics.total_games + 1,
           total_questions = user_statistics.total_questions + $2,
           total_correct_answers = user_statistics.total_correct_answers + $3,
           best_score = GREATEST(user_statistics.best_score, $4),
           last_played_at = NOW(),
           updated_at = NOW()`
      : `INSERT INTO user_statistics (session_id, total_games, total_questions, total_correct_answers, best_score, last_played_at)
         VALUES ($1, 1, $2, $3, $4, NOW())
         ON CONFLICT (session_id)
         DO UPDATE SET 
           total_games = user_statistics.total_games + 1,
           total_questions = user_statistics.total_questions + $2,
           total_correct_answers = user_statistics.total_correct_answers + $3,
           best_score = GREATEST(user_statistics.best_score, $4),
           last_played_at = NOW(),
           updated_at = NOW()`;

    await client.query(statsQuery, [userId || sessionId, totalQuestions, correctAnswers, score]);

    // Получаем обновленную статистику
    const statsResult = await client.query(
      userId 
        ? 'SELECT * FROM user_statistics WHERE user_id = $1'
        : 'SELECT * FROM user_statistics WHERE session_id = $1',
      [userId || sessionId]
    );

    await client.query('COMMIT');

    const userStats = statsResult.rows[0];

    res.json({
      message: 'Game finished successfully',
      gameResults: {
        score: score,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        accuracy: Math.round((correctAnswers / totalQuestions) * 100),
        durationSeconds: durationSeconds
      },
      userStatistics: {
        totalGames: userStats.total_games,
        bestScore: userStats.best_score,
        totalCorrectAnswers: userStats.total_correct_answers,
        totalQuestions: userStats.total_questions,
        overallAccuracy: userStats.total_questions > 0 
          ? Math.round((userStats.total_correct_answers / userStats.total_questions) * 100) 
          : 0
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
});

// Получение истории игр пользователя
router.get('/history', async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const offset = parseInt(req.query.offset) || 0;
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    const query = `
      SELECT 
        id,
        score,
        total_questions,
        correct_answers,
        duration_seconds,
        regions,
        game_mode,
        difficulty,
        completed_at,
        created_at
      FROM games 
      WHERE (user_id = $1 OR session_id = $2) AND completed_at IS NOT NULL
      ORDER BY completed_at DESC
      LIMIT $3 OFFSET $4
    `;

    const result = await pool.query(query, [userId, sessionId, limit, offset]);

    // Получаем общее количество игр
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM games WHERE (user_id = $1 OR session_id = $2) AND completed_at IS NOT NULL',
      [userId, sessionId]
    );

    res.json({
      games: result.rows.map(game => ({
        ...game,
        accuracy: Math.round((game.correct_answers / game.total_questions) * 100)
      })),
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: limit,
        offset: offset,
        hasMore: offset + limit < parseInt(countResult.rows[0].total)
      }
    });

  } catch (error) {
    next(error);
  }
});

// Получение детальной информации об игре
router.get('/:gameId', async (req, res, next) => {
  try {
    const gameId = req.params.gameId;
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    // Получаем основную информацию об игре
    const gameResult = await pool.query(
      `SELECT * FROM games 
       WHERE id = $1 AND (user_id = $2 OR session_id = $3)`,
      [gameId, userId, sessionId]
    );

    if (gameResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Game not found or access denied'
      });
    }

    const game = gameResult.rows[0];

    // Получаем ответы игры с информацией о странах
    const answersResult = await pool.query(
      `SELECT 
        ga.*,
        c1.name_en as correct_country_name,
        c1.flag_url as correct_country_flag,
        c2.name_en as selected_country_name,
        c2.flag_url as selected_country_flag
       FROM game_answers ga
       JOIN countries c1 ON ga.country_id = c1.id
       JOIN countries c2 ON ga.selected_country_id = c2.id
       WHERE ga.game_id = $1
       ORDER BY ga.question_number`,
      [gameId]
    );

    res.json({
      game: {
        ...game,
        accuracy: game.total_questions > 0 
          ? Math.round((game.correct_answers / game.total_questions) * 100) 
          : 0
      },
      answers: answersResult.rows
    });

  } catch (error) {
    next(error);
  }
});

export default router; 