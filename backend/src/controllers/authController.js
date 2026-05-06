'use strict';

const jwt = require('jsonwebtoken');
const { getAuth } = require('firebase-admin/auth');
const { pool } = require('../config/db');
const env = require('../config/env');
const logger = require('../utils/logger');

/**
 * Generate Access and Refresh Tokens
 */
const generateTokens = (userId) => {
  const accessToken = jwt.sign({ userId }, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
  const refreshToken = jwt.sign({ userId }, env.jwtRefreshSecret, { expiresIn: env.jwtRefreshExpiresIn });
  return { accessToken, refreshToken };
};

/**
 * Helper: verify Firebase token and upsert user in DB.
 * Returns { user, tokens } on success, throws on failure.
 */
const verifyAndUpsert = async (firebaseToken) => {
  const decodedToken = await getAuth().verifyIdToken(firebaseToken);
  const email = decodedToken.email;
  const uid = decodedToken.uid;

  if (!email) throw new Error('TOKEN_NO_EMAIL');

  const userQuery = await pool.query(
    'SELECT * FROM users WHERE firebase_uid = $1 OR email = $2',
    [uid, email]
  );
  let user = userQuery.rows[0];

  if (!user) {
    const insertResult = await pool.query(
      'INSERT INTO users (email, firebase_uid, status) VALUES ($1, $2, $3) RETURNING *',
      [email, uid, 'active']
    );
    user = insertResult.rows[0];
    logger.info(`New user registered: ${user.id}`);
  }

  const tokens = generateTokens(user.id);
  await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [user.id]);

  return { user, tokens };
};

/**
 * POST /api/auth/register
 * Client presents Firebase ID token → server verifies, upserts user, issues JWTs.
 */
const register = async (req, res) => {
  const { firebaseToken } = req.body;

  if (!firebaseToken) {
    return res.status(400).json({ error: 'Firebase token is required' });
  }

  try {
    const { user, tokens } = await verifyAndUpsert(firebaseToken);
    return res.status(200).json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatar_url,
        isProfileComplete: !!user.name,
      },
      tokens,
    });
  } catch (error) {
    // Retry once on ECONNREFUSED — Firebase public key cache cold-start race condition
    if (error.code === 'ECONNREFUSED' || error.message?.includes('ECONNREFUSED')) {
      logger.warn('Firebase key cache miss — retrying in 1.5s...');
      try {
        await new Promise((r) => setTimeout(r, 1500));
        const { user, tokens } = await verifyAndUpsert(firebaseToken);
        return res.status(200).json({
          message: 'Login successful',
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            avatarUrl: user.avatar_url,
            isProfileComplete: !!user.name,
          },
          tokens,
        });
      } catch (retryErr) {
        logger.error('Login retry failed', { errorCode: retryErr.code, errorMessage: retryErr.message });
        return res.status(503).json({ error: 'Auth service temporarily unavailable. Please try again.' });
      }
    }

    logger.error('Login error', {
      errorCode: error.code,
      errorMessage: error.message,
      tokenPreview: firebaseToken ? firebaseToken.substring(0, 50) + '...' : 'MISSING',
    });
    return res.status(401).json({ error: 'Invalid or expired Firebase token', detail: error.code });
  }
};

/**
 * POST /api/auth/refresh
 */
const refresh = async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Refresh token is required' });

  try {
    const decoded = jwt.verify(refreshToken, env.jwtRefreshSecret);
    const tokens = generateTokens(decoded.userId);
    return res.status(200).json(tokens);
  } catch (error) {
    logger.error('Token refresh error', { error: error.message });
    return res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
};

/**
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  res.status(200).json({ message: 'Logged out successfully' });
};

/**
 * GET /api/auth/me
 */
const getMe = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.userId]);
    const user = result.rows[0];
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.status(200).json({ id: user.id, email: user.email, name: user.name, avatarUrl: user.avatar_url });
  } catch (error) {
    logger.error('Get profile error', { error: error.message });
    return res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { register, refresh, logout, getMe };
