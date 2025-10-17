import { Router } from 'express';
import { pool } from '../db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = Router();

// Whitelist of tables from your schema
const ALLOWED_TABLES = [
  'clubs','game_types','modalities','levels','user_role_tags','users','user_groups','user_group_members',
  'user_passes','courts','court_game_types','court_blocks','court_block_slots','matches','match_players',
  'bookings','chats','chat_participants','messages','bar_tables','bar_orders','bar_order_items',
  'cash_drawer_sessions','access_logs','internal_messages','internal_message_readers','themes'
];

async function getTableMeta(table) {
  const [pkRows] = await pool.query(
    `SELECT k.COLUMN_NAME
     FROM information_schema.TABLE_CONSTRAINTS t
     JOIN information_schema.KEY_COLUMN_USAGE k
       ON k.CONSTRAINT_NAME = t.CONSTRAINT_NAME AND k.TABLE_SCHEMA = DATABASE() AND k.TABLE_NAME = t.TABLE_NAME
     WHERE t.TABLE_SCHEMA = DATABASE() AND t.TABLE_NAME = ? AND t.CONSTRAINT_TYPE = 'PRIMARY KEY'
     ORDER BY k.ORDINAL_POSITION`, [table]);
  const [cols] = await pool.query(`SHOW COLUMNS FROM \`${table}\``);
  return { pk: pkRows.map(r => r.COLUMN_NAME), columns: cols.map(c => c.Field) };
}

// List
router.get('/:table', authenticateToken, async (req, res) => {
  try {
    const table = req.params.table;
    if (!ALLOWED_TABLES.includes(table)) return res.status(404).json({ error: 'Unknown table' });
    const { limit = 50, offset = 0, orderBy = null } = req.query;
    const order = orderBy ? `ORDER BY ${orderBy.replace(/[^a-zA-Z0-9_,\s]/g,'')}` : '';
    const [rows] = await pool.query(`SELECT * FROM \`${table}\` ${order} LIMIT ? OFFSET ?`, [Number(limit), Number(offset)]);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get by id (only works for single-column PK)
router.get('/:table/:id', authenticateToken, async (req, res) => {
  try {
    const table = req.params.table;
    if (!ALLOWED_TABLES.includes(table)) return res.status(404).json({ error: 'Unknown table' });
    const meta = await getTableMeta(table);
    if (meta.pk.length !== 1) return res.status(400).json({ error: 'Composite PK. Use query /:table?pk[col]=val&pk[col2]=val2' });
    const key = meta.pk[0];
    const [rows] = await pool.query(`SELECT * FROM \`${table}\` WHERE \`${key}\` = ? LIMIT 1`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Create
router.post('/:table', authenticateToken, async (req, res) => {
  try {
    const table = req.params.table;
    if (!ALLOWED_TABLES.includes(table)) return res.status(404).json({ error: 'Unknown table' });
    const meta = await getTableMeta(table);
    const payload = req.body || {};
    // Keep only known columns
    const cols = meta.columns.filter(c => Object.prototype.hasOwnProperty.call(payload, c));
    const values = cols.map(c => payload[c]);
    if (!cols.length) return res.status(400).json({ error: 'No valid columns in payload' });
    const placeholders = cols.map(_ => '?').join(',');
    const sql = `INSERT INTO \`${table}\` (${cols.map(c=>`\\`${c}\\``).join(',')}) VALUES (${placeholders})`;
    await pool.query(sql, values);
    res.status(201).json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Update (single-column PK via URL; composite via body.pk object)
router.put('/:table/:id?', authenticateToken, async (req, res) => {
  try {
    const table = req.params.table;
    if (!ALLOWED_TABLES.includes(table)) return res.status(404).json({ error: 'Unknown table' });
    const meta = await getTableMeta(table);
    const payload = { ...(req.body || {}) };
    let whereClause = '';
    let params = [];
    if (meta.pk.length === 1 && req.params.id !== undefined) {
      whereClause = `WHERE \\`${meta.pk[0]}\\` = ?`;
      params.push(req.params.id);
    } else if (payload.pk && typeof payload.pk === 'object') {
      const keys = Object.keys(payload.pk);
      whereClause = 'WHERE ' + keys.map(k => `\\`${k}\\` = ?`).join(' AND ');
      params = keys.map(k => payload.pk[k]);
      delete payload.pk;
    } else {
      return res.status(400).json({ error: 'Missing primary key' });
    }
    const cols = meta.columns.filter(c => Object.prototype.hasOwnProperty.call(payload, c));
    if (!cols.length) return res.status(400).json({ error: 'No updatable columns in payload' });
    const setClause = cols.map(c => `\\`${c}\\` = ?`).join(', ');
    const sql = `UPDATE \\`${table}\\` SET ${setClause} ${whereClause}`;
    const values = cols.map(c => payload[c]);
    await pool.query(sql, [...values, *params]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Delete
router.delete('/:table/:id?', authenticateToken, async (req, res) => {
  try {
    const table = req.params.table;
    if (!ALLOWED_TABLES.includes(table)) return res.status(404).json({ error: 'Unknown table' });
    const meta = await getTableMeta(table);
    let whereClause = '';
    let params = [];
    if (meta.pk.length === 1 && req.params.id !== undefined) {
      whereClause = `WHERE \\`${meta.pk[0]}\\` = ?`;
      params.push(req.params.id);
    } else if (req.body && req.body.pk && typeof req.body.pk === 'object') {
      const keys = Object.keys(req.body.pk);
      whereClause = 'WHERE ' + keys.map(k => `\\`${k}\\` = ?`).join(' AND ');
      params = keys.map(k => req.body.pk[k]);
    } else {
      return res.status(400).json({ error: 'Missing primary key' });
    }
    const sql = `DELETE FROM \\`${table}\\` ${whereClause}`;
    await pool.query(sql, params);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
