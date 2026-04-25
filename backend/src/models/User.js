/**
 * User Model — database queries for the users table.
 * Sprint 1 will implement full CRUD.
 */
const { query } = require('../config/db');

const UserModel = {
  /**
   * Find a user by ID.
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
    const result = await query('SELECT * FROM users WHERE phone_number = $1', [phoneNumber]);
    return result.rows[0] || null;
  },

  /**
   * Create a new user.
   * @param {object} userData — { phone_number, name }
   */
  create: async ({ phone_number, name }) => {
    const result = await query(
      `INSERT INTO users (phone_number, name) VALUES ($1, $2)
       RETURNING *`,
      [phone_number, name]
    );
    return result.rows[0];
  },

  /**
   * Update user profile.
   * @param {string} id — UUID
   * @param {object} updates — { name, bio, avatar_url }
   */
  update: async (id, updates) => {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      fields.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }

    fields.push(`updated_at = NOW()`);
    values.push(id);

    const result = await query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    return result.rows[0];
  },
};

module.exports = UserModel;
