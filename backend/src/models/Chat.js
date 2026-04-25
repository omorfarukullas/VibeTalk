/**
 * Chat Model — database queries for chats and chat_participants.
 */
const { query } = require('../config/db');

const ChatModel = {
  findById: async (id) => {
    const result = await query('SELECT * FROM chats WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  create: async (type) => {
    const result = await query(
      'INSERT INTO chats (type) VALUES ($1) RETURNING *',
      [type]
    );
    return result.rows[0];
  },

  addParticipant: async (chatId, userId, role = 'member') => {
    const result = await query(
      `INSERT INTO chat_participants (chat_id, user_id, role)
       VALUES ($1, $2, $3) RETURNING *`,
      [chatId, userId, role]
    );
    return result.rows[0];
  },

  getParticipants: async (chatId) => {
    const result = await query(
      `SELECT u.* FROM users u
       JOIN chat_participants cp ON u.id = cp.user_id
       WHERE cp.chat_id = $1`,
      [chatId]
    );
    return result.rows;
  },

  getUserChats: async (userId) => {
    const result = await query(
      `SELECT c.* FROM chats c
       JOIN chat_participants cp ON c.id = cp.chat_id
       WHERE cp.user_id = $1
       ORDER BY c.created_at DESC`,
      [userId]
    );
    return result.rows;
  },
};

module.exports = ChatModel;
