const { pool } = require('../config/db');
const crypto = require('crypto');

async function listClubs(req, res) {
  try {
    const [rows] = await pool.query('SELECT id, name, city, country, status FROM clubs ORDER BY name LIMIT 200');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

async function createClub(req, res) {
  const { name, city, country, status='active' } = req.body || {};
  if (!name) return res.status(400).json({ message: 'Falta name' });
  try {
    const id = crypto.randomUUID();
    await pool.query('INSERT INTO clubs (id, name, city, country, status) VALUES (?, ?, ?, ?, ?)', 
      [id, name, city || null, country || null, status]);
    res.status(201).json({ id, name, city, country, status });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

module.exports = { listClubs, createClub };
