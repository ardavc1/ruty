
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pool } from './utils/db.js';
import authRouter from './routes/auth.js';
import habitsRouter from './routes/habits.js';
import syncRouter from './routes/sync.js';

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.use('/auth', authRouter);
app.use('/habits', habitsRouter);
app.use('/sync', syncRouter);

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Ruty backend listening on :${port}`));
