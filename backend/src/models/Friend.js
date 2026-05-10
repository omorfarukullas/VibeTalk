'use strict';

const { query } = require('../config/db');

/**
 * Friend Model — manages friend requests and accepted friendships.
 * Table: friends (id, requester_id, addressee_id, status, created_at, updated_at)
 * status: 'pending' | 'accepted' | 'declined' | 'blocked'
 */
const FriendModel = {
  /**
   * Ensures the friends table exists. Call once on server startup.
   */
  async createTable() {
    await query(`
      CREATE TABLE IF NOT EXISTS friends (
        id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
        created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (requester_id, addressee_id)
      );
      CREATE INDEX IF NOT EXISTS idx_friends_addressee ON friends(addressee_id);
      CREATE INDEX IF NOT EXISTS idx_friends_requester ON friends(requester_id);
    `);
  },

  /**
   * Send a friend request from requesterId to addresseeId.
   * Returns the created row, or null if a relationship already exists.
   */
  async sendRequest(requesterId, addresseeId) {
    // Check if any relationship already exists (in either direction)
    const existing = await query(
      `SELECT id, status FROM friends
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [requesterId, addresseeId]
    );
    if (existing.rows.length > 0) return { existing: existing.rows[0] };

    const result = await query(
      `INSERT INTO friends (requester_id, addressee_id, status)
       VALUES ($1, $2, 'pending')
       RETURNING *`,
      [requesterId, addresseeId]
    );
    return { created: result.rows[0] };
  },

  /**
   * Update the status of a friend request.
   */
  async updateStatus(requestId, addresseeId, status) {
    const result = await query(
      `UPDATE friends
       SET status = $1, updated_at = NOW()
       WHERE id = $2 AND addressee_id = $3
       RETURNING *`,
      [status, requestId, addresseeId]
    );
    return result.rows[0] || null;
  },

  /**
   * Get all pending incoming requests for a user.
   */
  async getPendingRequests(userId) {
    const result = await query(
      `SELECT f.id, f.created_at,
              u.id AS requester_id, u.name, u.email, u.avatar_url
       FROM friends f
       JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );
    return result.rows;
  },

  /**
   * Get all accepted friends for a user.
   */
  async getFriends(userId) {
    const result = await query(
      `SELECT f.id,
              CASE WHEN f.requester_id = $1 THEN u2.id ELSE u1.id END AS friend_id,
              CASE WHEN f.requester_id = $1 THEN u2.name ELSE u1.name END AS name,
              CASE WHEN f.requester_id = $1 THEN u2.email ELSE u1.email END AS email,
              CASE WHEN f.requester_id = $1 THEN u2.avatar_url ELSE u1.avatar_url END AS avatar_url,
              f.created_at
       FROM friends f
       JOIN users u1 ON u1.id = f.requester_id
       JOIN users u2 ON u2.id = f.addressee_id
       WHERE (f.requester_id = $1 OR f.addressee_id = $1) AND f.status = 'accepted'
       ORDER BY name`,
      [userId]
    );
    return result.rows;
  },

  /**
   * Get the friendship status between two users.
   */
  async getStatus(userId1, userId2) {
    const result = await query(
      `SELECT id, requester_id, addressee_id, status
       FROM friends
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [userId1, userId2]
    );
    return result.rows[0] || null;
  },

  /**
   * Remove a friend (delete the row entirely).
   */
  async removeFriend(userId, friendId) {
    const result = await query(
      `DELETE FROM friends
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)
       RETURNING id`,
      [userId, friendId]
    );
    return result.rowCount > 0;
  },
};

module.exports = FriendModel;
