'use strict';

const { query } = require('../config/db');

/**
 * UserKey Model — db queries for the user_keys table (Signal Protocol).
 */
const UserKeyModel = {
  /**
   * Insert or update the key bundle for a user.
   * Uses ON CONFLICT DO UPDATE since each user has exactly one active set.
   */
  upsert: async ({ user_id, identity_key, signed_prekey, prekey_bundle }) => {
    const result = await query(
      `INSERT INTO user_keys (user_id, identity_key, signed_prekey, prekey_bundle)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id)
       DO UPDATE SET
         identity_key  = EXCLUDED.identity_key,
         signed_prekey = EXCLUDED.signed_prekey,
         prekey_bundle = EXCLUDED.prekey_bundle,
         created_at    = NOW()
       RETURNING *`,
      [user_id, identity_key, signed_prekey, prekey_bundle ? JSON.stringify(prekey_bundle) : null],
    );
    return result.rows[0];
  },

  /**
   * Find key bundle by user ID.
   * @param {string} userId — UUID
   */
  findByUserId: async (userId) => {
    const result = await query(
      'SELECT * FROM user_keys WHERE user_id = $1',
      [userId],
    );
    return result.rows[0] || null;
  },
};

module.exports = UserKeyModel;
