const { pool } = require('../config/db');
const crypto = require('crypto');

async function listMatches(req, res) {
  try {
    const [rows] = await pool.query('SELECT id, club_id, court_id, date, time_slot, status FROM matches ORDER BY date DESC, time_slot DESC LIMIT 200');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

async function createMatch(req, res) {
  const { club_id, court_id, date, time_slot, status='open' } = req.body || {};
  if (!club_id || !court_id || !date || !time_slot) return res.status(400).json({ message: 'Faltan campos' });
  try {
    const id = crypto.randomUUID();
    await pool.query(
      'INSERT INTO matches (id, club_id, court_id, date, time_slot, status) VALUES (?, ?, ?, ?, ?, ?)',
      [id, club_id, court_id, date, time_slot, status]
    );
    res.status(201).json({ id, club_id, court_id, date, time_slot, status });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

module.exports = { listMatches, createMatch };
