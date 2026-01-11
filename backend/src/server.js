import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pool, testConnection } from './utils/db.js';
import authRouter from './routes/auth.js';
import habitsRouter from './routes/habits.js';
import charactersRouter from './routes/characters.js';
import achievementsRouter from './routes/achievements.js';

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(
  cors({
    origin: true, // Tüm origin'lere izin ver (production'da spesifik origin'ler belirtin)
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);
app.use(express.json());

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      ok: true,
      message: 'Server and database are healthy',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      error: error.message,
    });
  }
});

// Routes
app.use('/auth', authRouter);
app.use('/habits', habitsRouter);
app.use('/characters', charactersRouter);
app.use('/achievements', achievementsRouter);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Start server
async function startServer() {
  // Test database connection
  const dbConnected = await testConnection();
  if (!dbConnected) {
    console.error('❌ Failed to connect to database. Exiting...');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`🚀 Ruty backend server listening on port ${PORT}`);
    console.log(`📍 Health check: http://localhost:${PORT}/health`);
  });
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

