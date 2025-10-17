const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { pool } = require('../config/db');

async function register(req, res) {
  const { username, email, password, full_name } = req.body || {};
  if (!email || !password || !full_name) {
    return res.status(400).json({ message: 'Faltan campos: email, password, full_name' });
  }
  try {
    const [exists] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (exists.length) return res.status(400).json({ message: 'Email en uso' });

    const id = crypto.randomUUID();
    const hash = await bcrypt.hash(password, 10);
    await pool.query(
      "INSERT INTO users (id, username, full_name, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?, 'member', 'active')",
      [id, username || null, full_name, email, hash]
    );
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
}

async function login(req, res) {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ message: 'Faltan campos' });
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (!rows.length) return res.status(404).json({ message: 'Usuario no encontrado' });
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash || '');
    if (!ok) return res.status(401).json({ message: 'Credenciales inválidas' });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    return res.json({
      token,
      user: { id: user.id, full_name: user.full_name, email: user.email, role: user.role }
    });
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
}

module.exports = { register, login };
