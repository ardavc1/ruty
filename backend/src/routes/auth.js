import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../utils/db.js';
import { generateToken, authRequired } from '../middleware/auth.js';

const router = Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { email, password, display_name } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ error: 'Password must be at least 6 characters' });
    }

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, display_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, display_name, created_at`,
      [email.toLowerCase().trim(), passwordHash, display_name || null]
    );

    const user = result.rows[0];

    // Generate token
    const token = generateToken(user.id, user.email);

    // Create default character
    await pool.query(
      `INSERT INTO characters (user_id, type, level, energy, happiness, total_xp)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [user.id, 'cat', 1, 50, 50, 0]
    );

    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
      },
      token,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed', message: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const result = await pool.query(
      'SELECT id, email, password_hash, display_name FROM users WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = result.rows[0];

    // Verify password
    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate token
    const token = generateToken(user.id, user.email);

    res.json({
      user: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
      },
      token,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed', message: error.message });
  }
});

// Get current user profile
router.get('/me', authRequired, async (req, res) => {
  try {
    const { id: user_id } = req.user;

    const result = await pool.query(
      'SELECT id, email, display_name, created_at FROM users WHERE id = $1',
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = result.rows[0];
    res.json({
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      created_at: user.created_at,
    });
  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({ error: 'Failed to fetch user profile', message: error.message });
  }
});

export default router;

