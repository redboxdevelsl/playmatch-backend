const { pool } = require('../config/db');

async function listUsers(req, res) {
  try {
    const [rows] = await pool.query('SELECT id, username, full_name, email, role, status FROM users ORDER BY full_name LIMIT 200');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

module.exports = { listUsers };
