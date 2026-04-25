/**
 * Call Model — database queries for the calls table.
 */
const { query } = require('../config/db');

const CallModel = {
  findById: async (id) => {
    const result = await query('SELECT * FROM calls WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  create: async ({ chat_id, caller_id, call_type }) => {
    const result = await query(
      `INSERT INTO calls (chat_id, caller_id, call_type)
       VALUES ($1, $2, $3) RETURNING *`,
      [chat_id, caller_id, call_type]
    );
    return result.rows[0];
  },

  updateStatus: async (id, status) => {
    const updates = { status };
    if (status === 'ongoing') updates.started_at = new Date();
    if (status === 'ended' || status === 'missed' || status === 'rejected') {
      updates.ended_at = new Date();
    }

    const fields = Object.keys(updates).map((key, i) => `${key} = $${i + 1}`);
    const values = Object.values(updates);
    values.push(id);

    const result = await query(
      `UPDATE calls SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING *`,
      values
    );
    return result.rows[0];
  },

  getByUserId: async (userId, limit = 50) => {
    const result = await query(
      `SELECT c.* FROM calls c
       JOIN chats ch ON c.chat_id = ch.id
       JOIN chat_participants cp ON ch.id = cp.chat_id
       WHERE cp.user_id = $1
       ORDER BY c.started_at DESC NULLS LAST
       LIMIT $2`,
      [userId, limit]
    );
    return result.rows;
  },
};

module.exports = CallModel;
