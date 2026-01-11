import { Router } from 'express';
import { pool } from '../utils/db.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();
router.use(authRequired);

// Get all achievements for user
router.get('/', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    const result = await pool.query(
      'SELECT * FROM achievements WHERE user_id = $1 ORDER BY unlocked_at DESC',
      [user_id]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get achievements error:', error);
    res.status(500).json({
      error: 'Failed to fetch achievements',
      message: error.message,
    });
  }
});

// Unlock achievement
router.post('/unlock', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { type } = req.body;

    if (!type) {
      return res.status(400).json({ error: 'Achievement type is required' });
    }

    // Check if achievement already exists
    const existing = await pool.query(
      'SELECT id, unlocked FROM achievements WHERE user_id = $1 AND type = $2',
      [user_id, type]
    );

    if (existing.rows.length > 0) {
      if (existing.rows[0].unlocked) {
        return res.json({ message: 'Achievement already unlocked' });
      }
      // Update existing
      const result = await pool.query(
        `UPDATE achievements 
         SET unlocked = TRUE, unlocked_at = NOW()
         WHERE user_id = $1 AND type = $2
         RETURNING *`,
        [user_id, type]
      );
      return res.json(result.rows[0]);
    }

    // Create new achievement
    const result = await pool.query(
      `INSERT INTO achievements (user_id, type, unlocked, unlocked_at)
       VALUES ($1, $2, TRUE, NOW())
       RETURNING *`,
      [user_id, type]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Unlock achievement error:', error);
    res.status(500).json({
      error: 'Failed to unlock achievement',
      message: error.message,
    });
  }
});

export default router;

