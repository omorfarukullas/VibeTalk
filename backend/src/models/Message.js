/**
 * Message Model — database queries for the messages table.
 */
const { query } = require('../config/db');

const MessageModel = {
  findById: async (id) => {
    const result = await query(
      'SELECT * FROM messages WHERE id = $1 AND deleted_at IS NULL',
      [id]
    );
    return result.rows[0] || null;
  },

  create: async ({ chat_id, sender_id, content, message_type = 'text', reply_to_id = null }) => {
    const result = await query(
      `INSERT INTO messages (chat_id, sender_id, content, message_type, reply_to_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [chat_id, sender_id, content, message_type, reply_to_id]
    );
    return result.rows[0];
  },

  getByChatId: async (chatId, limit = 50, offset = 0) => {
    const result = await query(
      `SELECT * FROM messages
       WHERE chat_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [chatId, limit, offset]
    );
    return result.rows;
  },

  updateStatus: async (id, status) => {
    const result = await query(
      'UPDATE messages SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    return result.rows[0];
  },

  softDelete: async (id) => {
    const result = await query(
      'UPDATE messages SET deleted_at = NOW() WHERE id = $1 RETURNING *',
      [id]
    );
    return result.rows[0];
  },
};

module.exports = MessageModel;
