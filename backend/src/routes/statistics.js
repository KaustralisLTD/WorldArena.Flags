import express from 'express';
import pool from '../config/database.js';

const router = express.Router();

// Получение общей статистики пользователя
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    const statsQuery = `
      SELECT 
        s.*,
        (SELECT COUNT(*) FROM user_mistakes WHERE ${userId ? 'user_id = $1' : 'session_id = $1'}) as total_mistakes
      FROM user_statistics s
      WHERE ${userId ? 'user_id = $1' : 'session_id = $1'}
    `;

    const result = await pool.query(statsQuery, [userId || sessionId]);

    if (result.rows.length === 0) {
      // Создаем начальную статистику если её нет
      const createStatsQuery = userId
        ? 'INSERT INTO user_statistics (user_id) VALUES ($1) RETURNING *'
        : 'INSERT INTO user_statistics (session_id) VALUES ($1) RETURNING *';

      const newStatsResult = await pool.query(createStatsQuery, [userId || sessionId]);
      const newStats = newStatsResult.rows[0];

      return res.json({
        statistics: {
          ...newStats,
          total_mistakes: 0,
          accuracy: 0
        }
      });
    }

    const stats = result.rows[0];

    res.json({
      statistics: {
        ...stats,
        accuracy: stats.total_questions > 0 
          ? Math.round((stats.total_correct_answers / stats.total_questions) * 100) 
          : 0
      }
    });

  } catch (error) {
    next(error);
  }
});

// Получение ошибок пользователя
router.get('/mistakes', async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const sessionId = req.sessionId;
    const language = req.query.language || 'en';
    const limit = parseInt(req.query.limit) || 50;

    const nameField = language === 'en' ? 'c.name_en' 
      : `COALESCE(c.name_${language}, c.name_en)`;

    const query = `
      SELECT 
        um.id,
        um.mistake_count,
        um.last_mistake_at,
        c.id as country_id,
        c.code,
        ${nameField} as name,
        c.region,
        c.subregion,
        c.flag_url
      FROM user_mistakes um
      JOIN countries c ON um.country_id = c.id
      WHERE um.${userId ? 'user_id' : 'session_id'} = $1 AND c.is_active = true
      ORDER BY um.last_mistake_at DESC, um.mistake_count DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [userId || sessionId, limit]);

    res.json({
      mistakes: result.rows,
      total: result.rows.length,
      language: language
    });

  } catch (error) {
    next(error);
  }
});

// Удаление ошибки (когда пользователь правильно ответил)
router.delete('/mistakes/:countryId', async (req, res, next) => {
  try {
    const countryId = req.params.countryId;
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    const deleteQuery = userId
      ? 'DELETE FROM user_mistakes WHERE user_id = $1 AND country_id = $2'
      : 'DELETE FROM user_mistakes WHERE session_id = $1 AND country_id = $2';

    const result = await pool.query(deleteQuery, [userId || sessionId, countryId]);

    if (result.rowCount === 0) {
      return res.status(404).json({
        error: 'Mistake not found'
      });
    }

    res.json({
      message: 'Mistake removed successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Получение статистики по регионам
router.get('/regions', async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const sessionId = req.sessionId;

    const query = `
      SELECT 
        c.region,
        COUNT(ga.*) as total_questions,
        SUM(CASE WHEN ga.is_correct THEN 1 ELSE 0 END) as correct_answers,
        AVG(ga.answer_time_ms) as avg_answer_time
      FROM game_answers ga
      JOIN games g ON ga.game_id = g.id
      JOIN countries c ON ga.country_id = c.id
      WHERE g.${userId ? 'user_id' : 'session_id'} = $1 AND g.completed_at IS NOT NULL
      GROUP BY c.region
      ORDER BY correct_answers DESC
    `;

    const result = await pool.query(query, [userId || sessionId]);

    const regionStats = result.rows.map(row => ({
      region: row.region,
      totalQuestions: parseInt(row.total_questions),
      correctAnswers: parseInt(row.correct_answers),
      accuracy: row.total_questions > 0 
        ? Math.round((row.correct_answers / row.total_questions) * 100) 
        : 0,
      avgAnswerTime: Math.round(parseFloat(row.avg_answer_time) || 0)
    }));

    res.json({
      regionStatistics: regionStats
    });

  } catch (error) {
    next(error);
  }
});

// Получение статистики производительности за последние игры
router.get('/performance', async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const sessionId = req.sessionId;
    const limit = parseInt(req.query.limit) || 10;

    const query = `
      SELECT 
        g.id,
        g.score,
        g.total_questions,
        g.correct_answers,
        g.duration_seconds,
        g.game_mode,
        g.difficulty,
        g.completed_at,
        ROUND((g.correct_answers::float / g.total_questions) * 100) as accuracy
      FROM games g
      WHERE g.${userId ? 'user_id' : 'session_id'} = $1 AND g.completed_at IS NOT NULL
      ORDER BY g.completed_at DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [userId || sessionId, limit]);

    // Вычисляем тренды
    const games = result.rows;
    let accuracyTrend = 0;
    let speedTrend = 0;

    if (games.length >= 2) {
      const recentAccuracy = games.slice(0, Math.min(3, games.length))
        .reduce((sum, game) => sum + game.accuracy, 0) / Math.min(3, games.length);
      
      const olderAccuracy = games.slice(-Math.min(3, games.length))
        .reduce((sum, game) => sum + game.accuracy, 0) / Math.min(3, games.length);

      accuracyTrend = recentAccuracy - olderAccuracy;

      const recentSpeed = games.slice(0, Math.min(3, games.length))
        .reduce((sum, game) => sum + (game.duration_seconds / game.total_questions), 0) / Math.min(3, games.length);
      
      const olderSpeed = games.slice(-Math.min(3, games.length))
        .reduce((sum, game) => sum + (game.duration_seconds / game.total_questions), 0) / Math.min(3, games.length);

      speedTrend = olderSpeed - recentSpeed; // Положительный тренд = быстрее
    }

    res.json({
      recentGames: games,
      trends: {
        accuracy: Math.round(accuracyTrend * 10) / 10,
        speed: Math.round(speedTrend * 10) / 10
      }
    });

  } catch (error) {
    next(error);
  }
});

// Получение глобальной статистики (топы, рейтинги)
router.get('/leaderboard', async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const type = req.query.type || 'best_score'; // best_score, accuracy, total_games

    let orderBy;
    switch (type) {
      case 'accuracy':
        orderBy = '(s.total_correct_answers::float / NULLIF(s.total_questions, 0)) DESC';
        break;
      case 'total_games':
        orderBy = 's.total_games DESC';
        break;
      default:
        orderBy = 's.best_score DESC';
    }

    const query = `
      SELECT 
        u.username,
        s.best_score,
        s.total_games,
        s.total_correct_answers,
        s.total_questions,
        s.last_played_at,
        ROUND((s.total_correct_answers::float / NULLIF(s.total_questions, 0)) * 100) as accuracy
      FROM user_statistics s
      JOIN users u ON s.user_id = u.id
      WHERE s.total_games > 0 AND u.is_active = true
      ORDER BY ${orderBy}
      LIMIT $1
    `;

    const result = await pool.query(query, [limit]);

    res.json({
      leaderboard: result.rows.map((row, index) => ({
        rank: index + 1,
        username: row.username,
        bestScore: row.best_score,
        totalGames: row.total_games,
        accuracy: row.accuracy || 0,
        lastPlayedAt: row.last_played_at
      })),
      type: type
    });

  } catch (error) {
    next(error);
  }
});

export default router; 