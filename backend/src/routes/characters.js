import { Router } from 'express';
import { pool } from '../utils/db.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();
router.use(authRequired);

// Get user's character
router.get('/', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    const result = await pool.query(
      'SELECT * FROM characters WHERE user_id = $1',
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Character not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get character error:', error);
    res.status(500).json({ error: 'Failed to fetch character', message: error.message });
  }
});

// Create character (for initial selection)
router.post('/', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { type, custom_name } = req.body;

    // Validation
    if (!type) {
      return res.status(400).json({ error: 'Character type is required' });
    }

    // Validate character type
    const validTypes = ['cat', 'dog', 'rabbit', 'fox'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ error: 'Invalid character type' });
    }

    // Check if character already exists
    const existingResult = await pool.query(
      'SELECT id FROM characters WHERE user_id = $1',
      [user_id]
    );

    if (existingResult.rows.length > 0) {
      return res.status(409).json({ error: 'Character already exists. Use PATCH to update.' });
    }

    // Create character
    const result = await pool.query(
      `INSERT INTO characters (user_id, type, level, energy, happiness, total_xp, custom_name)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [user_id, type, 1, 50, 50, 0, custom_name?.trim() || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create character error:', error);
    res.status(500).json({
      error: 'Failed to create character',
      message: error.message,
    });
  }
});

// Update character
router.patch('/', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { type, custom_name, level, energy, happiness } = req.body;

    // Check if character exists
    const checkResult = await pool.query(
      'SELECT id FROM characters WHERE user_id = $1',
      [user_id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Character not found' });
    }

    // Build update query
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (type !== undefined) {
      updates.push(`type = $${paramIndex++}`);
      values.push(type);
    }
    if (custom_name !== undefined) {
      updates.push(`custom_name = $${paramIndex++}`);
      values.push(custom_name?.trim() || null);
    }
    if (level !== undefined) {
      updates.push(`level = $${paramIndex++}`);
      values.push(level);
    }
    if (energy !== undefined) {
      updates.push(`energy = $${paramIndex++}`);
      values.push(Math.max(0, Math.min(100, energy)));
    }
    if (happiness !== undefined) {
      updates.push(`happiness = $${paramIndex++}`);
      values.push(Math.max(0, Math.min(100, happiness)));
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(user_id);
    const result = await pool.query(
      `UPDATE characters 
       SET ${updates.join(', ')}, updated_at = NOW()
       WHERE user_id = $${paramIndex++}
       RETURNING *`,
      values
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update character error:', error);
    res.status(500).json({
      error: 'Failed to update character',
      message: error.message,
    });
  }
});

export default router;

