import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';

const router = Router();

router.post('/login', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    if (!password || (!username && !email)) {
      return res.status(400).json({ error: 'username/email and password required' });
    }
    const [rows] = await pool.query(
      `SELECT id, username, email, password_hash, role, status, full_name FROM users WHERE ${username ? 'username = ?' : 'email = ?'} LIMIT 1`,
      [username || email]
    );
    if (!rows.length) return res.status(401).json({ error: 'Invalid credentials' });
    const user = rows[0];
    if (user.status && user.status !== 'active') {
      return res.status(403).json({ error: 'User not active' });
    }
    const ok = user.password_hash ? await bcrypt.compare(password, user.password_hash) : false;
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ id: user.id, role: user.role, name: user.full_name }, process.env.JWT_SECRET, { expiresIn: '12h' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email, role: user.role, name: user.full_name } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/register', async (req, res) => {
  try {
    const { id, username, email, password, full_name, role = 'member', club_id = null } = req.body;
    if (!password || (!username && !email) || !full_name) {
      return res.status(400).json({ error: 'full_name, password and username or email are required' });
    }
    const password_hash = await bcrypt.hash(password, 10);
    const userId = id || crypto.randomUUID();
    const [result] = await pool.query(
      `INSERT INTO users (id, username, email, full_name, password_hash, role, status, club_id, registration_date)
       VALUES (?, ?, ?, ?, ?, ?, 'active', ?, UTC_TIMESTAMP())`,
      [userId, username || null, email || null, full_name, password_hash, role, club_id]
    );
    res.status(201).json({ id: userId });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'username or email already exists' });
    }
    res.status(500).json({ error: e.message });
  }
});

export default router;
