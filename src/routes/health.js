import { Router } from 'express';
import { pool } from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  res.json({ status: 'ok' });
});

router.get('/db', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT 1 AS ok');
    res.json({ db: rows[0].ok === 1 ? 'up' : 'down' });
  } catch (e) {
    res.status(500).json({ db: 'down', error: e.message });
  }
});

export default router;
