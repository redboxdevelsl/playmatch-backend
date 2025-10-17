import { Router } from 'express';
import { pool } from '../db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = Router();

// Detailed match list with joins
router.get('/detailed', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT m.*, c.name AS club_name, ct.name AS court_name, gt.name AS game_type_name, lv.name AS level_name, md.name AS modality_name
      FROM matches m
      JOIN clubs c ON c.id = m.club_id
      JOIN courts ct ON ct.id = m.court_id
      LEFT JOIN game_types gt ON gt.id = m.game_type_id
      LEFT JOIN levels lv ON lv.id = m.level_id
      LEFT JOIN modalities md ON md.id = m.modality_id
      ORDER BY m.date DESC, m.time_slot ASC
      LIMIT 200
    `);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Players in a match
router.get('/:matchId/players', authenticateToken, async (req, res) => {
  try {
    const { matchId } = req.params;
    const [rows] = await pool.query(`
      SELECT u.id, u.full_name, u.username, u.level_id
      FROM match_players mp
      JOIN users u ON u.id = mp.user_id
      WHERE mp.match_id = ?
    `, [matchId]);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
