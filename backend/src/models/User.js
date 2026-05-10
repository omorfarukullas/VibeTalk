'use strict';

const { query } = require('../config/db');

/**
 * User Model — database queries for the users table.
 */
const UserModel = {
  /**
   * Find a user by their internal UUID.
   * @param {string} id — UUID
   */
  findById: async (id) => {
    const result = await query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  /**
   * Find a user by phone number.
   * @param {string} phoneNumber
   */
  findByPhone: async (phoneNumber) => {
    const result = await query(
      'SELECT * FROM users WHERE phone_number = $1',
      [phoneNumber],
    );
    return result.rows[0] || null;
  },

  /**
   * Create a new user.
   * @param {object} userData
   * @param {string} userData.phone_number
   * @param {string|null} [userData.name]
   * @param {string|null} [userData.avatar_url]
   * @param {string|null} [userData.firebase_uid]
   */
  create: async ({ phone_number, name = null, avatar_url = null, firebase_uid = null }) => {
    const result = await query(
      `INSERT INTO users (phone_number, name, avatar_url)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [phone_number, name, avatar_url],
    );
    return result.rows[0];
  },

  /**
   * Update user profile fields.
   * Only updates fields that are explicitly provided.
   * @param {string} id — UUID
   * @param {object} updates — e.g. { name, bio, avatar_url }
   */
  update: async (id, updates) => {
    const allowedFields = ['name', 'bio', 'avatar_url', 'status', 'last_seen', 'username'];
    const fields = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        fields.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (fields.length === 0) return null;

    values.push(id);

    const result = await query(
      `UPDATE users
       SET ${fields.join(', ')}, updated_at = NOW()
       WHERE id = $${paramIndex}
       RETURNING *`,
      values,
    );
    return result.rows[0] || null;
  },

  /**
   * Update the last_seen timestamp for a user.
   * @param {string} id — UUID
   */
  updateLastSeen: async (id) => {
    await query(
      'UPDATE users SET last_seen = NOW() WHERE id = $1',
      [id],
    );
  },
};

module.exports = UserModel;
