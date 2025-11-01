
import { Router } from 'express';
import { pool } from '../utils/db.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();
router.use(authRequired);

router.get('/', async (req, res) => {
  const { id: user_id } = req.user;
  const r = await pool.query(`SELECT * FROM habits WHERE user_id=$1 AND is_deleted=false ORDER BY updated_at DESC`, [user_id]);
  res.json(r.rows);
});

router.post('/', async (req, res) => {
  const { id: user_id } = req.user;
  const { title, description, recurrence, difficulty, reminder_time, color } = req.body || {};
  const r = await pool.query(`
    INSERT INTO habits (user_id, title, description, recurrence, difficulty, reminder_time, color, is_deleted, updated_at)
    VALUES ($1,$2,$3,$4,COALESCE($5,1),$6,$7,false,NOW())
    RETURNING *`,
    [user_id, title, description, recurrence, difficulty, reminder_time, color]
  );
  res.status(201).json(r.rows[0]);
});

router.patch('/:id', async (req, res) => {
  const { id: user_id } = req.user;
  const { id } = req.params;
  const { title, description, recurrence, difficulty, reminder_time, color, is_deleted } = req.body || {};
  const r = await pool.query(`
    UPDATE habits SET
      title=COALESCE($3, title),
      description=COALESCE($4, description),
      recurrence=COALESCE($5, recurrence),
      difficulty=COALESCE($6, difficulty),
      reminder_time=COALESCE($7, reminder_time),
      color=COALESCE($8, color),
      is_deleted=COALESCE($9, is_deleted),
      updated_at=NOW()
    WHERE id=$1 AND user_id=$2
    RETURNING *`,
    [id, user_id, title, description, recurrence, difficulty, reminder_time, color, is_deleted]
  );
  if (!r.rowCount) return res.status(404).json({ error: 'not found' });
  res.json(r.rows[0]);
});

router.post('/:id/check', async (req, res) => {
  const { id: user_id } = req.user;
  const { id } = req.params;
  const { date, completed } = req.body || {};
  const day = date || new Date().toISOString().slice(0,10);
  const h = await pool.query(`SELECT id FROM habits WHERE id=$1 AND user_id=$2 AND is_deleted=false`, [id, user_id]);
  if (!h.rowCount) return res.status(404).json({ error: 'habit not found' });

  const r = await pool.query(`
    INSERT INTO habit_instances (habit_id, date, completed, xp_awarded, is_deleted, updated_at)
    VALUES ($1,$2,COALESCE($3,true),0,false,NOW())
    ON CONFLICT (habit_id, date)
    DO UPDATE SET completed=EXCLUDED.completed, updated_at=NOW()
    RETURNING *`,
    [id, day, completed]
  );
  res.json(r.rows[0]);
});

export default router;
