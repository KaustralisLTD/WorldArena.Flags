import express from 'express';
import Joi from 'joi';
import pool from '../config/database.js';
import { optionalAuthMiddleware } from '../middleware/auth.js';

const router = express.Router();

// Применяем middleware для поддержки авторизованных и анонимных пользователей
router.use(optionalAuthMiddleware);

// Схема валидации запроса стран
const getCountriesSchema = Joi.object({
  regions: Joi.array().items(
    Joi.string().valid('Europe', 'Asia', 'Africa', 'Americas', 'Oceania', 'all')
  ).default(['all']),
  language: Joi.string().valid('en', 'ru', 'es', 'uk', 'ca', 'zh').default('en'),
  limit: Joi.number().integer().min(1).max(250).default(50),
  includeInactive: Joi.boolean().default(false)
});

// Получение списка стран по регионам
router.get('/', async (req, res, next) => {
  try {
    const { error, value } = getCountriesSchema.validate(req.query);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { regions, language, limit, includeInactive } = value;

    let whereConditions = [];
    let queryParams = [];
    let paramCount = 1;

    // Фильтр по активности
    if (!includeInactive) {
      whereConditions.push('is_active = true');
    }

    // Фильтр по регионам
    if (!regions.includes('all')) {
      const regionConditions = regions.map(region => {
        if (region === 'Americas') {
          return `(region = 'Americas' OR subregion IN ('Northern America', 'Central America', 'Caribbean', 'South America'))`;
        }
        return `region = $${paramCount++}`;
      });
      
      if (!regions.includes('Americas')) {
        queryParams.push(...regions);
      }
      
      whereConditions.push(`(${regionConditions.join(' OR ')})`);
    }

    const whereClause = whereConditions.length > 0 
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    // Определяем поле названия в зависимости от языка
    const nameField = language === 'en' ? 'name_en' 
      : `COALESCE(name_${language}, name_en)`;

    const query = `
      SELECT 
        id,
        code,
        ${nameField} as name,
        region,
        subregion,
        flag_url,
        capital,
        population,
        area
      FROM countries
      ${whereClause}
      ORDER BY ${nameField}
      LIMIT $${paramCount}
    `;

    queryParams.push(limit);

    const result = await pool.query(query, queryParams);

    res.json({
      countries: result.rows,
      total: result.rows.length,
      regions: regions,
      language: language
    });

  } catch (error) {
    next(error);
  }
});

// Получение стран для игры (с рандомизацией)
router.get('/for-game', async (req, res, next) => {
  try {
    const gameSchema = Joi.object({
      regions: Joi.array().items(
        Joi.string().valid('Europe', 'Asia', 'Africa', 'Americas', 'Oceania', 'all', 'mistakes')
      ).default(['all']),
      language: Joi.string().valid('en', 'ru', 'es', 'uk', 'ca', 'zh').default('en'),
      count: Joi.number().integer().min(1).max(250).default(20),
      difficulty: Joi.string().valid('easy', 'medium', 'hard', 'expert', 'erudite').default('medium')
    });

    const { error, value } = getCountriesSchema.validate(req.query);
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const { regions, language, count, difficulty } = value;

    // Если запрашиваются ошибки пользователя
    if (regions.includes('mistakes')) {
      const userIdentifier = req.user ? req.user.id : req.sessionId;
      const identifierField = req.user ? 'user_id' : 'session_id';

      const mistakesQuery = `
        SELECT DISTINCT
          c.id,
          c.code,
          ${language === 'en' ? 'c.name_en' : `COALESCE(c.name_${language}, c.name_en)`} as name,
          c.region,
          c.subregion,
          c.flag_url,
          c.capital,
          um.mistake_count
        FROM countries c
        INNER JOIN user_mistakes um ON c.id = um.country_id
        WHERE um.${identifierField} = $1 AND c.is_active = true
        ORDER BY um.last_mistake_at DESC, um.mistake_count DESC
        LIMIT $2
      `;

      const mistakesResult = await pool.query(mistakesQuery, [userIdentifier, count]);

      return res.json({
        countries: mistakesResult.rows,
        total: mistakesResult.rows.length,
        regions: regions,
        language: language,
        type: 'mistakes'
      });
    }

    // Обычная логика для получения стран
    let whereConditions = ['is_active = true'];
    let queryParams = [];
    let paramCount = 1;

    // Фильтр по регионам
    if (!regions.includes('all')) {
      const regionConditions = regions.map(region => {
        if (region === 'Americas') {
          return `(region = 'Americas' OR subregion IN ('Northern America', 'Central America', 'Caribbean', 'South America'))`;
        }
        return `region = $${paramCount++}`;
      });
      
      if (!regions.includes('Americas')) {
        queryParams.push(...regions);
      }
      
      whereConditions.push(`(${regionConditions.join(' OR ')})`);
    }

    // Фильтр по сложности (по размеру населения или площади)
    if (difficulty === 'easy') {
      whereConditions.push('population > 10000000'); // Только крупные страны
    } else if (difficulty === 'hard') {
      whereConditions.push('population < 1000000'); // Только малые страны
    }
    // Для expert и erudite не добавляем дополнительные фильтры по населению

    const whereClause = `WHERE ${whereConditions.join(' AND ')}`;
    const nameField = language === 'en' ? 'name_en' 
      : `COALESCE(name_${language}, name_en)`;

    // Для expert и erudite нужно сначала получить общее количество стран в регионе
    let finalCount = count;
    if (difficulty === 'expert' || difficulty === 'erudite') {
      const countQuery = `
        SELECT COUNT(*) as total
        FROM countries
        ${whereClause}
      `;
      
      const countResult = await pool.query(countQuery, queryParams);
      const totalCountries = parseInt(countResult.rows[0].total);
      
      if (difficulty === 'expert') {
        finalCount = Math.ceil(totalCountries * 0.5); // 50% стран
      } else if (difficulty === 'erudite') {
        finalCount = totalCountries; // 100% стран
      }
    }

    const query = `
      SELECT 
        id,
        code,
        ${nameField} as name,
        region,
        subregion,
        flag_url,
        capital,
        population,
        area
      FROM countries
      ${whereClause}
      ORDER BY RANDOM()
      LIMIT $${paramCount}
    `;

    queryParams.push(finalCount);

    const result = await pool.query(query, queryParams);

    res.json({
      countries: result.rows,
      total: result.rows.length,
      regions: regions,
      language: language,
      difficulty: difficulty,
      type: 'game'
    });

  } catch (error) {
    next(error);
  }
});

// Получение информации о конкретной стране
router.get('/:id', async (req, res, next) => {
  try {
    const countryId = req.params.id;
    const language = req.query.language || 'en';

    const nameField = language === 'en' ? 'name_en' 
      : `COALESCE(name_${language}, name_en)`;

    const query = `
      SELECT 
        id,
        code,
        ${nameField} as name,
        name_en,
        name_ru,
        name_es,
        name_uk,
        name_ca,
        name_zh,
        region,
        subregion,
        flag_url,
        capital,
        population,
        area,
        created_at
      FROM countries
      WHERE id = $1 AND is_active = true
    `;

    const result = await pool.query(query, [countryId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Country not found'
      });
    }

    res.json({
      country: result.rows[0]
    });

  } catch (error) {
    next(error);
  }
});

// Поиск стран
router.get('/search/:query', async (req, res, next) => {
  try {
    const searchQuery = req.params.query;
    const language = req.query.language || 'en';
    const limit = parseInt(req.query.limit) || 10;

    if (searchQuery.length < 2) {
      return res.status(400).json({
        error: 'Search query must be at least 2 characters long'
      });
    }

    const nameField = language === 'en' ? 'name_en' 
      : `COALESCE(name_${language}, name_en)`;

    const query = `
      SELECT 
        id,
        code,
        ${nameField} as name,
        region,
        subregion,
        flag_url,
        capital
      FROM countries
      WHERE (
        LOWER(${nameField}) LIKE LOWER($1) OR
        LOWER(name_en) LIKE LOWER($1) OR
        LOWER(code) LIKE LOWER($1) OR
        LOWER(capital) LIKE LOWER($1)
      ) AND is_active = true
      ORDER BY 
        CASE 
          WHEN LOWER(${nameField}) = LOWER($2) THEN 1
          WHEN LOWER(${nameField}) LIKE LOWER($3) THEN 2
          ELSE 3
        END,
        ${nameField}
      LIMIT $4
    `;

    const result = await pool.query(query, [
      `%${searchQuery}%`,
      searchQuery,
      `${searchQuery}%`,
      limit
    ]);

    res.json({
      countries: result.rows,
      total: result.rows.length,
      query: searchQuery,
      language: language
    });

  } catch (error) {
    next(error);
  }
});

export default router; 