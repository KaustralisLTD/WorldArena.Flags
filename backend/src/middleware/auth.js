import jwt from 'jsonwebtoken';
import pool from '../config/database.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Проверяем, что пользователь еще существует и активен
    const result = await pool.query(
      'SELECT id, email, username, preferred_language, is_active FROM users WHERE id = $1 AND is_active = true',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid token. User not found.' });
    }

    req.user = result.rows[0];
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token.' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired.' });
    }
    
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Internal server error.' });
  }
};

// Middleware для анонимных пользователей (использует session_id)
export const sessionMiddleware = (req, res, next) => {
  // Получаем session_id из заголовков или создаем новый
  const sessionId = req.header('X-Session-ID') || generateSessionId();
  req.sessionId = sessionId;
  
  // Добавляем заголовок в ответ для клиента
  res.setHeader('X-Session-ID', sessionId);
  
  next();
};

// Комбинированный middleware - поддерживает и авторизованных, и анонимных пользователей
export const optionalAuthMiddleware = async (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      const result = await pool.query(
        'SELECT id, email, username, preferred_language, is_active FROM users WHERE id = $1 AND is_active = true',
        [decoded.userId]
      );

      if (result.rows.length > 0) {
        req.user = result.rows[0];
      }
    } catch (error) {
      // Игнорируем ошибки токена для анонимных пользователей
      console.log('Token verification failed, continuing as anonymous user');
    }
  }
  
  // Если нет пользователя, устанавливаем session_id
  if (!req.user) {
    const sessionId = req.header('X-Session-ID') || generateSessionId();
    req.sessionId = sessionId;
    res.setHeader('X-Session-ID', sessionId);
  }
  
  next();
};

function generateSessionId() {
  return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
} 