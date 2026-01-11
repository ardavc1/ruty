import { Router } from 'express';
import { pool } from '../utils/db.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();
router.use(authRequired); // Tüm route'lar authentication gerektirir

// Get all habits for user (including deleted ones)
router.get('/all', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    // Get all habits with related data (including deleted)
    const habitsResult = await pool.query(
      `SELECT * FROM habits 
       WHERE user_id = $1 
       ORDER BY updated_at DESC`,
      [user_id]
    );

    const habits = habitsResult.rows;

    // For each habit, get related data
    for (let habit of habits) {
      // Get daily days if daily recurrence
      if (habit.recurrence === 'daily' && !habit.is_one_time) {
        const dailyDaysResult = await pool.query(
          'SELECT day_of_week FROM habit_daily_days WHERE habit_id = $1 ORDER BY day_of_week',
          [habit.id]
        );
        habit.daily_days = dailyDaysResult.rows.map(r => r.day_of_week);
      }

      // Get monthly days if monthly recurrence
      if (habit.recurrence === 'monthly' && !habit.is_one_time) {
        const monthlyDaysResult = await pool.query(
          'SELECT day_of_month FROM habit_monthly_days WHERE habit_id = $1 ORDER BY day_of_month',
          [habit.id]
        );
        habit.monthly_days = monthlyDaysResult.rows.map(r => r.day_of_month);
      }

      // Get one-time date if one-time task
      if (habit.is_one_time) {
        const oneTimeDateResult = await pool.query(
          'SELECT task_date FROM habit_one_time_dates WHERE habit_id = $1',
          [habit.id]
        );
        if (oneTimeDateResult.rows.length > 0) {
          habit.one_time_date = oneTimeDateResult.rows[0].task_date;
        }
      }
    }

    res.json(habits);
  } catch (error) {
    console.error('Get all habits error:', error);
    res.status(500).json({ error: 'Failed to fetch all habits', message: error.message });
  }
});

// Get all habits for user (only active)
router.get('/', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    // Get habits with related data
    const habitsResult = await pool.query(
      `SELECT * FROM habits 
       WHERE user_id = $1 AND is_deleted = FALSE 
       ORDER BY updated_at DESC`,
      [user_id]
    );

    const habits = habitsResult.rows;

    // For each habit, get related data
    for (let habit of habits) {
      // Get daily days if daily recurrence
      if (habit.recurrence === 'daily' && !habit.is_one_time) {
        const dailyDaysResult = await pool.query(
          'SELECT day_of_week FROM habit_daily_days WHERE habit_id = $1 ORDER BY day_of_week',
          [habit.id]
        );
        habit.daily_days = dailyDaysResult.rows.map(r => r.day_of_week);
      }

      // Get monthly days if monthly recurrence
      if (habit.recurrence === 'monthly' && !habit.is_one_time) {
        const monthlyDaysResult = await pool.query(
          'SELECT day_of_month FROM habit_monthly_days WHERE habit_id = $1 ORDER BY day_of_month',
          [habit.id]
        );
        habit.monthly_days = monthlyDaysResult.rows.map(r => r.day_of_month);
      }

      // Get one-time date if one-time task
      if (habit.is_one_time) {
        const oneTimeDateResult = await pool.query(
          'SELECT task_date FROM habit_one_time_dates WHERE habit_id = $1',
          [habit.id]
        );
        if (oneTimeDateResult.rows.length > 0) {
          habit.one_time_date = oneTimeDateResult.rows[0].task_date;
        }
      }
    }

    res.json(habits);
  } catch (error) {
    console.error('Get habits error:', error);
    res.status(500).json({ error: 'Failed to fetch habits', message: error.message });
  }
});

// Get single habit
router.get('/:id', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { id } = req.params;

    const result = await pool.query(
      'SELECT * FROM habits WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    const habit = result.rows[0];

    // Get daily days if daily recurrence
    if (habit.recurrence === 'daily' && !habit.is_one_time) {
      const dailyDaysResult = await pool.query(
        'SELECT day_of_week FROM habit_daily_days WHERE habit_id = $1 ORDER BY day_of_week',
        [habit.id]
      );
      habit.daily_days = dailyDaysResult.rows.map(r => r.day_of_week);
    }

    // Get monthly days if monthly recurrence
    if (habit.recurrence === 'monthly' && !habit.is_one_time) {
      const monthlyDaysResult = await pool.query(
        'SELECT day_of_month FROM habit_monthly_days WHERE habit_id = $1 ORDER BY day_of_month',
        [habit.id]
      );
      habit.monthly_days = monthlyDaysResult.rows.map(r => r.day_of_month);
    }

    // Get one-time date if one-time task
    if (habit.is_one_time) {
      const oneTimeDateResult = await pool.query(
        'SELECT task_date FROM habit_one_time_dates WHERE habit_id = $1',
        [habit.id]
      );
      if (oneTimeDateResult.rows.length > 0) {
        habit.one_time_date = oneTimeDateResult.rows[0].task_date;
      }
    }

    res.json(habit);
  } catch (error) {
    console.error('Get habit error:', error);
    res.status(500).json({ error: 'Failed to fetch habit', message: error.message });
  }
});

// Create habit
router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const { id: user_id } = req.user;
    const {
      title,
      description,
      is_one_time,
      recurrence,
      difficulty,
      reminder_time,
      has_reminder,
      color,
      target_value,
      target_unit,
      has_end_date,
      end_date_type,
      end_date,
      end_days,
      time_of_day,
      daily_days,
      monthly_days,
      one_time_date,
    } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Title is required' });
    }

    // Validate is_one_time and recurrence
    const isOneTime = is_one_time === true;
    const finalRecurrence = isOneTime ? 'daily' : (recurrence || 'daily');

    // Create habit
    const habitResult = await client.query(
      `INSERT INTO habits (
        user_id, title, description, is_one_time, recurrence, difficulty, 
        reminder_time, has_reminder, color, target_value, target_unit,
        has_end_date, end_date_type, end_date, end_days, time_of_day
      )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
       RETURNING *`,
      [
        user_id,
        title.trim(),
        description?.trim() || null,
        isOneTime,
        finalRecurrence,
        difficulty || 1,
        reminder_time || null,
        has_reminder || false,
        color || null,
        target_value || null,
        target_unit || null,
        has_end_date || false,
        end_date_type || null,
        end_date || null,
        end_days || null,
        time_of_day !== undefined ? time_of_day : null,
      ]
    );

    const habit = habitResult.rows[0];

    // Handle daily days
    if (!isOneTime && finalRecurrence === 'daily' && daily_days && Array.isArray(daily_days)) {
      for (const day of daily_days) {
        if (day >= 1 && day <= 7) {
          await client.query(
            'INSERT INTO habit_daily_days (habit_id, day_of_week) VALUES ($1, $2)',
            [habit.id, day]
          );
        }
      }
    }

    // Handle monthly days
    if (!isOneTime && finalRecurrence === 'monthly' && monthly_days && Array.isArray(monthly_days)) {
      for (const day of monthly_days) {
        if (day >= 1 && day <= 31) {
          await client.query(
            'INSERT INTO habit_monthly_days (habit_id, day_of_month) VALUES ($1, $2)',
            [habit.id, day]
          );
        }
      }
    }

    // Handle one-time date
    if (isOneTime && one_time_date) {
      await client.query(
        'INSERT INTO habit_one_time_dates (habit_id, task_date) VALUES ($1, $2)',
        [habit.id, one_time_date]
      );
      habit.one_time_date = one_time_date;
    }

    await client.query('COMMIT');

    // Fetch complete habit with related data
    if (!isOneTime && finalRecurrence === 'daily') {
      const dailyDaysResult = await pool.query(
        'SELECT day_of_week FROM habit_daily_days WHERE habit_id = $1 ORDER BY day_of_week',
        [habit.id]
      );
      habit.daily_days = dailyDaysResult.rows.map(r => r.day_of_week);
    }

    if (!isOneTime && finalRecurrence === 'monthly') {
      const monthlyDaysResult = await pool.query(
        'SELECT day_of_month FROM habit_monthly_days WHERE habit_id = $1 ORDER BY day_of_month',
        [habit.id]
      );
      habit.monthly_days = monthlyDaysResult.rows.map(r => r.day_of_month);
    }

    res.status(201).json(habit);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create habit error:', error);
    res.status(500).json({ error: 'Failed to create habit', message: error.message });
  } finally {
    client.release();
  }
});

// Update habit
router.patch('/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const { id: user_id } = req.user;
    const { id } = req.params;
    const {
      title,
      description,
      is_one_time,
      recurrence,
      difficulty,
      reminder_time,
      has_reminder,
      color,
      is_deleted,
      target_value,
      target_unit,
      has_end_date,
      end_date_type,
      end_date,
      end_days,
      time_of_day,
      daily_days,
      monthly_days,
      one_time_date,
    } = req.body;

    // Check if habit exists and belongs to user
    const checkResult = await client.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2',
      [id, user_id]
    );

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Habit not found' });
    }

    // Build update query dynamically
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (title !== undefined) {
      updates.push(`title = $${paramIndex++}`);
      values.push(title.trim());
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(description?.trim() || null);
    }
    if (is_one_time !== undefined) {
      updates.push(`is_one_time = $${paramIndex++}`);
      values.push(is_one_time);
    }
    if (recurrence !== undefined) {
      updates.push(`recurrence = $${paramIndex++}`);
      values.push(recurrence);
    }
    if (target_value !== undefined) {
      updates.push(`target_value = $${paramIndex++}`);
      values.push(target_value || null);
    }
    if (target_unit !== undefined) {
      updates.push(`target_unit = $${paramIndex++}`);
      values.push(target_unit || null);
    }
    if (difficulty !== undefined) {
      updates.push(`difficulty = $${paramIndex++}`);
      values.push(difficulty);
    }
    if (reminder_time !== undefined) {
      updates.push(`reminder_time = $${paramIndex++}`);
      values.push(reminder_time || null);
    }
    if (has_reminder !== undefined) {
      updates.push(`has_reminder = $${paramIndex++}`);
      values.push(has_reminder);
    }
    if (color !== undefined) {
      updates.push(`color = $${paramIndex++}`);
      values.push(color || null);
    }
    if (has_end_date !== undefined) {
      updates.push(`has_end_date = $${paramIndex++}`);
      values.push(has_end_date);
    }
    if (end_date_type !== undefined) {
      updates.push(`end_date_type = $${paramIndex++}`);
      values.push(end_date_type || null);
    }
    if (end_date !== undefined) {
      updates.push(`end_date = $${paramIndex++}`);
      values.push(end_date || null);
    }
    if (end_days !== undefined) {
      updates.push(`end_days = $${paramIndex++}`);
      values.push(end_days || null);
    }
    if (time_of_day !== undefined) {
      updates.push(`time_of_day = $${paramIndex++}`);
      values.push(time_of_day !== null ? time_of_day : null);
    }
    if (is_deleted !== undefined) {
      updates.push(`is_deleted = $${paramIndex++}`);
      values.push(is_deleted);
    }

    if (updates.length > 0) {
      values.push(id, user_id);
      await client.query(
        `UPDATE habits 
         SET ${updates.join(', ')}, updated_at = NOW()
         WHERE id = $${paramIndex++} AND user_id = $${paramIndex++}
         RETURNING *`,
        values
      );
    }

    // Update related tables if provided
    if (daily_days !== undefined) {
      // Delete existing and insert new
      await client.query('DELETE FROM habit_daily_days WHERE habit_id = $1', [id]);
      if (Array.isArray(daily_days)) {
        for (const day of daily_days) {
          if (day >= 1 && day <= 7) {
            await client.query(
              'INSERT INTO habit_daily_days (habit_id, day_of_week) VALUES ($1, $2)',
              [id, day]
            );
          }
        }
      }
    }

    if (monthly_days !== undefined) {
      // Delete existing and insert new
      await client.query('DELETE FROM habit_monthly_days WHERE habit_id = $1', [id]);
      if (Array.isArray(monthly_days)) {
        for (const day of monthly_days) {
          if (day >= 1 && day <= 31) {
            await client.query(
              'INSERT INTO habit_monthly_days (habit_id, day_of_month) VALUES ($1, $2)',
              [id, day]
            );
          }
        }
      }
    }

    if (one_time_date !== undefined) {
      // Delete existing and insert new
      await client.query('DELETE FROM habit_one_time_dates WHERE habit_id = $1', [id]);
      if (one_time_date) {
        await client.query(
          'INSERT INTO habit_one_time_dates (habit_id, task_date) VALUES ($1, $2)',
          [id, one_time_date]
        );
      }
    }

    await client.query('COMMIT');

    // Fetch updated habit with related data
    const result = await pool.query(
      'SELECT * FROM habits WHERE id = $1 AND user_id = $2',
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    const habit = result.rows[0];

    // Get related data
    if (habit.recurrence === 'daily' && !habit.is_one_time) {
      const dailyDaysResult = await pool.query(
        'SELECT day_of_week FROM habit_daily_days WHERE habit_id = $1 ORDER BY day_of_week',
        [habit.id]
      );
      habit.daily_days = dailyDaysResult.rows.map(r => r.day_of_week);
    }

    if (habit.recurrence === 'monthly' && !habit.is_one_time) {
      const monthlyDaysResult = await pool.query(
        'SELECT day_of_month FROM habit_monthly_days WHERE habit_id = $1 ORDER BY day_of_month',
        [habit.id]
      );
      habit.monthly_days = monthlyDaysResult.rows.map(r => r.day_of_month);
    }

    if (habit.is_one_time) {
      const oneTimeDateResult = await pool.query(
        'SELECT task_date FROM habit_one_time_dates WHERE habit_id = $1',
        [habit.id]
      );
      if (oneTimeDateResult.rows.length > 0) {
        habit.one_time_date = oneTimeDateResult.rows[0].task_date;
      }
    }

    res.json(habit);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Update habit error:', error);
    res.status(500).json({ error: 'Failed to update habit', message: error.message });
  } finally {
    client.release();
  }
});

// Delete habit (soft delete)
router.delete('/:id', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { id } = req.params;

    const result = await pool.query(
      `UPDATE habits 
       SET is_deleted = TRUE, updated_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    res.json({ message: 'Habit deleted successfully' });
  } catch (error) {
    console.error('Delete habit error:', error);
    res.status(500).json({ error: 'Failed to delete habit', message: error.message });
  }
});

// Check habit (complete/incomplete for a date)
router.post('/:id/check', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { id } = req.params;
    const { date, completed } = req.body;

    // Validate date format
    const checkDate = date || new Date().toISOString().split('T')[0];

    // Check if habit exists and belongs to user
    const habitCheck = await pool.query(
      'SELECT id, difficulty FROM habits WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, user_id]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    const habit = habitCheck.rows[0];
    const isCompleted = completed !== undefined ? completed : true;

    // Calculate XP based on difficulty (1-5)
    const xpAwarded = isCompleted ? habit.difficulty * 10 : 0;

    // Upsert habit instance
    const result = await pool.query(
      `INSERT INTO habit_instances (habit_id, date, completed, xp_awarded)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (habit_id, date)
       DO UPDATE SET 
         completed = EXCLUDED.completed,
         xp_awarded = EXCLUDED.xp_awarded,
         updated_at = NOW()
       RETURNING *`,
      [id, checkDate, isCompleted, xpAwarded]
    );

    // Update character XP if completed
    if (isCompleted && xpAwarded > 0) {
      // Get current character stats
      const characterResult = await pool.query(
        'SELECT total_xp, level FROM characters WHERE user_id = $1',
        [user_id]
      );

      if (characterResult.rows.length > 0) {
        const currentXp = characterResult.rows[0].total_xp;
        const currentLevel = characterResult.rows[0].level;
        const newXp = currentXp + xpAwarded;

        // Calculate required XP for each level (starts at 100, increases by 50 each level)
        // Level 1->2: 100 XP, Level 2->3: 150 XP, Level 3->4: 200 XP, etc.
        function calculateLevelFromXp(xp) {
          if (xp < 100) return 1;
          let level = 1;
          let requiredXp = 100;
          let totalRequiredXp = 0;
          
          while (xp >= totalRequiredXp + requiredXp) {
            totalRequiredXp += requiredXp;
            level++;
            requiredXp += 50; // Each level needs 50 more XP than previous
          }
          
          return level;
        }

        const newLevel = calculateLevelFromXp(newXp);

        // Update character with new XP and level
        await pool.query(
          `UPDATE characters 
           SET total_xp = $1,
               level = $2,
               energy = LEAST(100, energy + $3),
               happiness = LEAST(100, happiness + $4),
               updated_at = NOW()
           WHERE user_id = $5`,
          [
            newXp,
            newLevel,
            Math.floor(xpAwarded / 5), // Energy increase
            Math.floor(xpAwarded / 5), // Happiness increase
            user_id,
          ]
        );
      }
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Check habit error:', error);
    res.status(500).json({ error: 'Failed to check habit', message: error.message });
  }
});

// Get all instances for user (all habits)
router.get('/instances/all', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    // Get all habit IDs for this user
    const habitsResult = await pool.query(
      'SELECT id FROM habits WHERE user_id = $1',
      [user_id]
    );

    if (habitsResult.rows.length === 0) {
      return res.json([]);
    }

    const habitIds = habitsResult.rows.map(row => row.id);

    // Get all instances for these habits
    const instancesResult = await pool.query(
      `SELECT hi.* FROM habit_instances hi
       INNER JOIN habits h ON hi.habit_id = h.id
       WHERE hi.habit_id = ANY($1) AND hi.is_deleted = FALSE
       ORDER BY hi.date DESC`,
      [habitIds]
    );

    res.json(instancesResult.rows);
  } catch (error) {
    console.error('Get all instances error:', error);
    res.status(500).json({ error: 'Failed to fetch all instances', message: error.message });
  }
});

// Get habit instances (completions) for a date range
router.get('/:id/instances', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { id } = req.params;
    const { start_date, end_date } = req.query;

    // Check if habit belongs to user
    const habitCheck = await pool.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, user_id]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    let query =
      'SELECT * FROM habit_instances WHERE habit_id = $1 AND is_deleted = FALSE';
    const params = [id];

    if (start_date && end_date) {
      query += ' AND date BETWEEN $2 AND $3';
      params.push(start_date, end_date);
    } else if (start_date) {
      query += ' AND date >= $2';
      params.push(start_date);
    }

    query += ' ORDER BY date DESC';

    const result = await pool.query(query, params);

    res.json(result.rows);
  } catch (error) {
    console.error('Get habit instances error:', error);
    res.status(500).json({
      error: 'Failed to fetch habit instances',
      message: error.message,
    });
  }
});

// Get habit streak and statistics
router.get('/:id/statistics', async (req, res) => {
  try {
    const { id: user_id } = req.user;
    const { id } = req.params;

    // Check if habit belongs to user
    const habitCheck = await pool.query(
      'SELECT id FROM habits WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, user_id]
    );

    if (habitCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }

    // Get all completed instances ordered by date
    const instancesResult = await pool.query(
      `SELECT date, completed 
       FROM habit_instances 
       WHERE habit_id = $1 AND is_deleted = FALSE 
       ORDER BY date ASC`,
      [id]
    );

    const instances = instancesResult.rows;
    const today = new Date().toISOString().split('T')[0];
    const todayDate = new Date(today);

    // Calculate current streak
    let currentStreak = 0;
    let streakBroken = false;
    const completedDates = new Set(
      instances
        .filter((i) => i.completed)
        .map((i) => i.date.toISOString().split('T')[0])
    );

    // Check backwards from today
    let checkDate = new Date(todayDate);
    while (true) {
      const dateStr = checkDate.toISOString().split('T')[0];
      if (completedDates.has(dateStr)) {
        currentStreak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        // If today is not completed, check if yesterday was
        if (dateStr === today && !completedDates.has(dateStr)) {
          const yesterday = new Date(checkDate);
          yesterday.setDate(yesterday.getDate() - 1);
          const yesterdayStr = yesterday.toISOString().split('T')[0];
          if (completedDates.has(yesterdayStr)) {
            // Streak is still active, just today not done yet
            break;
          }
        }
        streakBroken = true;
        break;
      }
    }

    // Calculate longest streak
    let longestStreak = 0;
    let tempStreak = 0;
    const sortedDates = Array.from(completedDates).sort();
    
    for (let i = 0; i < sortedDates.length; i++) {
      const currentDate = new Date(sortedDates[i]);
      if (i === 0) {
        tempStreak = 1;
      } else {
        const prevDate = new Date(sortedDates[i - 1]);
        const daysDiff = Math.floor(
          (currentDate - prevDate) / (1000 * 60 * 60 * 24)
        );
        if (daysDiff === 1) {
          tempStreak++;
        } else {
          longestStreak = Math.max(longestStreak, tempStreak);
          tempStreak = 1;
        }
      }
    }
    longestStreak = Math.max(longestStreak, tempStreak);

    // Get streak status
    let streakStatus = 'devam_ediyor';
    if (streakBroken && currentStreak === 0) {
      const yesterday = new Date(todayDate);
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];
      if (completedDates.has(yesterdayStr)) {
        streakStatus = 'dun_kacirildi';
      } else {
        streakStatus = 'koptu';
      }
    }

    // Calculate completion rates
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfToday);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay()); // Start of week (Sunday)
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Daily (today)
    const todayStr = today;
    const dailyCompleted = completedDates.has(todayStr) ? 1 : 0;
    const dailyTotal = 1;
    const dailyRate = dailyTotal > 0 ? Number(((dailyCompleted / dailyTotal) * 100).toFixed(2)) : 0.0;

    // Weekly (this week)
    const weekDates = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek);
      date.setDate(date.getDate() + i);
      weekDates.push(date.toISOString().split('T')[0]);
    }
    const weeklyCompleted = weekDates.filter((d) => completedDates.has(d)).length;
    const weeklyRate = Number(((weeklyCompleted / 7) * 100).toFixed(2));

    // Monthly (this month)
    const monthDates = [];
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    for (let d = new Date(startOfMonth); d <= endOfMonth; d.setDate(d.getDate() + 1)) {
      monthDates.push(d.toISOString().split('T')[0]);
    }
    const monthlyCompleted = monthDates.filter((d) => completedDates.has(d)).length;
    const monthlyRate = monthDates.length > 0 ? Number(((monthlyCompleted / monthDates.length) * 100).toFixed(2)) : 0.0;

    res.json({
      currentStreak: Number(currentStreak),
      longestStreak: Number(longestStreak),
      streakStatus,
      daily: {
        completed: dailyCompleted,
        total: dailyTotal,
        rate: dailyRate,
      },
      weekly: {
        completed: weeklyCompleted,
        total: 7,
        rate: weeklyRate,
      },
      monthly: {
        completed: monthlyCompleted,
        total: monthDates.length,
        rate: monthlyRate,
      },
      totalCompleted: Number(completedDates.size),
      instances: instances.map((i) => ({
        date: i.date.toISOString().split('T')[0],
        completed: i.completed,
      })),
    });
  } catch (error) {
    console.error('Get habit statistics error:', error);
    res.status(500).json({
      error: 'Failed to fetch habit statistics',
      message: error.message,
    });
  }
});

// Get all habits statistics (aggregated)
router.get('/statistics/all', async (req, res) => {
  try {
    const { id: user_id } = req.user;

    // Get all habits for user
    const habitsResult = await pool.query(
      `SELECT id FROM habits 
       WHERE user_id = $1 AND is_deleted = FALSE`,
      [user_id]
    );

    const habitIds = habitsResult.rows.map((r) => r.id);
    if (habitIds.length === 0) {
      return res.json({
        totalHabits: 0,
        overallDailyRate: 0.0,
        overallWeeklyRate: 0.0,
        overallMonthlyRate: 0.0,
        averageStreak: 0.0,
        habits: [],
      });
    }

    // Get all instances for all habits
    const instancesResult = await pool.query(
      `SELECT habit_id, date, completed 
       FROM habit_instances 
       WHERE habit_id = ANY($1) AND is_deleted = FALSE 
       ORDER BY date ASC`,
      [habitIds]
    );

    const instancesByHabit = {};
    habitIds.forEach((id) => {
      instancesByHabit[id] = [];
    });

    instancesResult.rows.forEach((row) => {
      if (instancesByHabit[row.habit_id]) {
        instancesByHabit[row.habit_id].push(row);
      }
    });

    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    let totalDailyCompleted = 0;
    let totalWeeklyCompleted = 0;
    let totalMonthlyCompleted = 0;
    let totalStreak = 0;
    const habitsStats = [];

    habitIds.forEach((habitId) => {
      const instances = instancesByHabit[habitId];
      const completedDates = new Set(
        instances
          .filter((i) => i.completed)
          .map((i) => i.date.toISOString().split('T')[0])
      );

      // Daily
      if (completedDates.has(today)) totalDailyCompleted++;

      // Weekly
      for (let i = 0; i < 7; i++) {
        const date = new Date(startOfWeek);
        date.setDate(date.getDate() + i);
        if (completedDates.has(date.toISOString().split('T')[0])) {
          totalWeeklyCompleted++;
        }
      }

      // Monthly
      for (let d = new Date(startOfMonth); d <= endOfMonth; d.setDate(d.getDate() + 1)) {
        if (completedDates.has(d.toISOString().split('T')[0])) {
          totalMonthlyCompleted++;
        }
      }

      // Streak
      let streak = 0;
      let checkDate = new Date(today);
      while (completedDates.has(checkDate.toISOString().split('T')[0])) {
        streak++;
        checkDate.setDate(checkDate.getDate() - 1);
      }
      totalStreak += streak;

      habitsStats.push({
        habitId,
        currentStreak: streak,
        dailyCompleted: completedDates.has(today) ? 1 : 0,
      });
    });

    const totalHabits = habitIds.length;
    const overallDailyRate = totalHabits > 0 ? Number(((totalDailyCompleted / totalHabits) * 100).toFixed(2)) : 0.0;
    const overallWeeklyRate = totalHabits > 0 ? Number(((totalWeeklyCompleted / (totalHabits * 7)) * 100).toFixed(2)) : 0.0;
    const daysInMonth = endOfMonth.getDate();
    const overallMonthlyRate = totalHabits > 0 ? Number(((totalMonthlyCompleted / (totalHabits * daysInMonth)) * 100).toFixed(2)) : 0.0;
    const averageStreak = totalHabits > 0 ? Number((totalStreak / totalHabits).toFixed(2)) : 0.0;

    res.json({
      totalHabits,
      overallDailyRate,
      overallWeeklyRate,
      overallMonthlyRate,
      averageStreak,
      habits: habitsStats,
    });
  } catch (error) {
    console.error('Get all habits statistics error:', error);
    res.status(500).json({
      error: 'Failed to fetch statistics',
      message: error.message,
    });
  }
});

export default router;

