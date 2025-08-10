import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Joi from 'joi';
import pool from '../config/database.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

// Схемы валидации
const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  username: Joi.string().min(3).max(30).required(),
  password: Joi.string().min(6).required(),
  preferredLanguage: Joi.string().valid('ru', 'en', 'es', 'uk', 'ca', 'zh').default('ru')
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

// Регистрация пользователя
router.post('/register', async (req, res, next) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { email, username, password, preferredLanguage } = value;

    // Проверяем, существует ли пользователь
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [email, username]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'User with this email or username already exists'
      });
    }

    // Хешируем пароль
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Создаем пользователя
    const result = await pool.query(
      `INSERT INTO users (email, username, password_hash, preferred_language) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, email, username, preferred_language, created_at`,
      [email, username, passwordHash, preferredLanguage]
    );

    const user = result.rows[0];

    // Создаем начальную статистику
    await pool.query(
      'INSERT INTO user_statistics (user_id) VALUES ($1)',
      [user.id]
    );

    // Генерируем JWT токен
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        preferredLanguage: user.preferred_language,
        createdAt: user.created_at
      },
      token
    });

  } catch (error) {
    next(error);
  }
});

// Вход пользователя
router.post('/login', async (req, res, next) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { email, password } = value;

    // Находим пользователя
    const result = await pool.query(
      'SELECT id, email, username, password_hash, preferred_language, is_active FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Invalid credentials'
      });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(401).json({
        error: 'Account is deactivated'
      });
    }

    // Проверяем пароль
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid credentials'
      });
    }

    // Обновляем время последней активности
    await pool.query(
      'UPDATE users SET last_active = NOW() WHERE id = $1',
      [user.id]
    );

    // Генерируем JWT токен
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        preferredLanguage: user.preferred_language
      },
      token
    });

  } catch (error) {
    next(error);
  }
});

// Получение профиля пользователя
router.get('/profile', authMiddleware, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT u.id, u.email, u.username, u.preferred_language, u.created_at, u.last_active,
              s.total_games, s.best_score, s.total_correct_answers, s.total_questions
       FROM users u
       LEFT JOIN user_statistics s ON u.id = s.user_id
       WHERE u.id = $1`,
      [req.user.id]
    );

    const user = result.rows[0];

    res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        preferredLanguage: user.preferred_language,
        createdAt: user.created_at,
        lastActive: user.last_active,
        statistics: {
          totalGames: user.total_games || 0,
          bestScore: user.best_score || 0,
          totalCorrectAnswers: user.total_correct_answers || 0,
          totalQuestions: user.total_questions || 0,
          accuracy: user.total_questions > 0 
            ? Math.round((user.total_correct_answers / user.total_questions) * 100) 
            : 0
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Обновление профиля пользователя
router.put('/profile', authMiddleware, async (req, res, next) => {
  try {
    const updateSchema = Joi.object({
      username: Joi.string().min(3).max(30),
      preferredLanguage: Joi.string().valid('ru', 'en', 'es', 'uk', 'ca', 'zh')
    });

    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (value.username) {
      updates.push(`username = $${paramCount++}`);
      values.push(value.username);
    }

    if (value.preferredLanguage) {
      updates.push(`preferred_language = $${paramCount++}`);
      values.push(value.preferredLanguage);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        error: 'No valid fields to update'
      });
    }

    updates.push(`updated_at = NOW()`);
    values.push(req.user.id);

    const result = await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} 
       RETURNING id, email, username, preferred_language, updated_at`,
      values
    );

    res.json({
      message: 'Profile updated successfully',
      user: result.rows[0]
    });

  } catch (error) {
    next(error);
  }
});

export default router; 