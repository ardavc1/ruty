
import { Router } from 'express';
import { pool } from '../utils/db.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();
router.use(authRequired);

router.get('/down', async (req, res) => {
  const since = req.query.since || '1970-01-01T00:00:00Z';
  const user_id = req.user.id;
  const habits = await pool.query(`SELECT * FROM habits WHERE user_id=$1 AND updated_at > $2`, [user_id, since]);
  const instances = await pool.query(`
    SELECT hi.* FROM habit_instances hi
    JOIN habits h ON h.id = hi.habit_id
    WHERE h.user_id=$1 AND hi.updated_at > $2`, [user_id, since]);
  res.json({ habits: habits.rows, habit_instances: instances.rows });
});

router.post('/up', async (req, res) => {
  const user_id = req.user.id;
  const { habits = [], habit_instances = [] } = req.body || {};
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const h of habits) {
      if (h.user_id !== user_id) continue;
      await client.query(`
        INSERT INTO habits (id, user_id, title, description, recurrence, difficulty, reminder_time, color, is_deleted, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,COALESCE($9,false),$10)
        ON CONFLICT (id) DO UPDATE SET
          title=EXCLUDED.title,
          description=EXCLUDED.description,
          recurrence=EXCLUDED.recurrence,
          difficulty=EXCLUDED.difficulty,
          reminder_time=EXCLUDED.reminder_time,
          color=EXCLUDED.color,
          is_deleted=EXCLUDED.is_deleted,
          updated_at=EXCLUDED.updated_at
        WHERE habits.updated_at < EXCLUDED.updated_at
      `, [h.id, user_id, h.title, h.description, h.recurrence, h.difficulty, h.reminder_time, h.color, h.is_deleted, h.updated_at]);
    }
    for (const i of habit_instances) {
      await client.query(`
        INSERT INTO habit_instances (id, habit_id, date, completed, xp_awarded, is_deleted, updated_at)
        VALUES ($1,$2,$3,$4,COALESCE($5,0),COALESCE($6,false),$7)
        ON CONFLICT (habit_id, date) DO UPDATE SET
          completed=EXCLUDED.completed,
          xp_awarded=EXCLUDED.xp_awarded,
          is_deleted=EXCLUDED.is_deleted,
          updated_at=EXCLUDED.updated_at
        WHERE habit_instances.updated_at < EXCLUDED.updated_at
      `, [i.id, i.habit_id, i.date, i.completed, i.xp_awarded, i.is_deleted, i.updated_at]);
    }
    await client.query('COMMIT');
    res.json({ ok: true });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: e.message });
  } finally {
    client.release();
  }
});

export default router;
