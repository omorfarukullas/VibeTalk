/**
 * Media Model — database queries for the media table.
 */
const { query } = require('../config/db');

const MediaModel = {
  findById: async (id) => {
    const result = await query('SELECT * FROM media WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  create: async ({ message_id, uploader_id, file_url, file_type, file_size, encrypted_key }) => {
    const result = await query(
      `INSERT INTO media (message_id, uploader_id, file_url, file_type, file_size, encrypted_key)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [message_id, uploader_id, file_url, file_type, file_size, encrypted_key]
    );
    return result.rows[0];
  },

  findByMessageId: async (messageId) => {
    const result = await query('SELECT * FROM media WHERE message_id = $1', [messageId]);
    return result.rows;
  },

  delete: async (id) => {
    const result = await query('DELETE FROM media WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },
};

module.exports = MediaModel;
