/**
 * Group Model — database queries for the groups table.
 */
const { query } = require('../config/db');

const GroupModel = {
  findById: async (id) => {
    const result = await query('SELECT * FROM groups WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  create: async ({ chat_id, name, created_by, avatar_url = null }) => {
    const result = await query(
      `INSERT INTO groups (chat_id, name, created_by, avatar_url)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [chat_id, name, created_by, avatar_url]
    );
    return result.rows[0];
  },

  update: async (id, updates) => {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      fields.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }

    values.push(id);

    const result = await query(
      `UPDATE groups SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    return result.rows[0];
  },

  findByInviteLink: async (inviteLink) => {
    const result = await query('SELECT * FROM groups WHERE invite_link = $1', [inviteLink]);
    return result.rows[0] || null;
  },
};

module.exports = GroupModel;
