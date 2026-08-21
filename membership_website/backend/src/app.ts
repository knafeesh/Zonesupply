import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { testConnection } from './config/database';
import pool from './config/database';
import { applicationRoutes } from './routes/applicationRoutes';
import { adminRoutes } from './routes/adminRoutes';
import { statusRoutes } from './routes/statusRoutes';

dotenv.config();

const app = express();

// ─── Security Middleware ───────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ─── Body Parsers ──────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Static Uploads ───────────────────────────────────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ─── Health Check ─────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({ success: true, message: 'Zone Store Membership API is running', version: '1.0.0' });
});

// ─── Routes ───────────────────────────────────────────────────
app.use('/api', applicationRoutes);
app.use('/api', statusRoutes);
app.use('/api/admin', adminRoutes);

// ─── Route Aliases ─────────────────────────────────────────────
app.use('/admin', adminRoutes);
app.use('/auth', adminRoutes);
app.use('/api/auth', adminRoutes);
app.use('/api/v1/auth', adminRoutes);
app.use('/api/v1', applicationRoutes);
app.use('/api/v1', statusRoutes);
app.use('/api/v1/admin', adminRoutes);

// ─── 404 Handler ──────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ─── Error Handler ────────────────────────────────────────────
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ success: false, message: 'File size exceeds 5MB limit.' });
  }
  res.status(500).json({ success: false, message: err.message || 'Internal server error' });
});

// ─── Start Server ─────────────────────────────────────────────
const PORT: number = Number(process.env.PORT) || 5000;

const seedAdmin = async (): Promise<void> => {
  try {
    const result = await pool.query('SELECT id FROM admin WHERE username = $1', ['admin']);
    if (result.rows.length === 0) {
      const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'Zone@123', 12);
      await pool.query(
        'INSERT INTO admin (username, password_hash) VALUES ($1, $2)',
        ['admin', hash]
      );
      console.log('✅ Admin user created: admin / Zone@123');
    } else {
      console.log('ℹ️  Admin user already exists');
    }
  } catch (err) {
    console.error('Admin seed notice:', err);
  }
};

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server listening on 0.0.0.0:${PORT} (Render Ready)`);
  console.log(`📊 Health check: http://0.0.0.0:${PORT}/api/health`);
  console.log(`🌐 Frontend origin: ${process.env.FRONTEND_URL || '*'}`);

  // Initialize DB in background without blocking server binding
  testConnection().then(() => seedAdmin()).catch((e) => console.error('DB init warning:', e));
});

export default app;
