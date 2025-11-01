
import { Router } from 'express';
import { pool } from '../utils/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const router = Router();

router.post('/register', async (req, res) => {
  try {
    const { email, password, display_name } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });
    const password_hash = await bcrypt.hash(password, 10);
    const r = await pool.query(
      `INSERT INTO users (email, password_hash, display_name) VALUES ($1,$2,$3)
       RETURNING id, email, display_name`,
      [email, password_hash, display_name || null]
    );
    const user = r.rows[0];
    const token = jwt.sign({ sub: user.id, email: user.email }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });
    res.json({ user, token });
  } catch (e) {
    if (String(e.message).includes('unique')) return res.status(409).json({ error: 'email already exists' });
    res.status(500).json({ error: e.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });
    const r = await pool.query(`SELECT id, email, password_hash, display_name FROM users WHERE email=$1`, [email]);
    const u = r.rows[0];
    if (!u) return res.status(401).json({ error: 'invalid credentials' });
    const ok = await bcrypt.compare(password, u.password_hash);
    if (!ok) return res.status(401).json({ error: 'invalid credentials' });
    const token = jwt.sign({ sub: u.id, email: u.email }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });
    res.json({ user: { id: u.id, email: u.email, display_name: u.display_name }, token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
