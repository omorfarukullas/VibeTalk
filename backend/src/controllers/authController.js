const jwt = require('jsonwebtoken');
const { getAuth } = require('firebase-admin/auth');
const { pool } = require('../config/db');
const env = require('../config/env');
const logger = require('../utils/logger');

/**
 * Generate Access and Refresh Tokens
 */
const generateTokens = (userId) => {
  const accessToken = jwt.sign({ userId }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });
  const refreshToken = jwt.sign({ userId }, env.jwtRefreshSecret, {
    expiresIn: env.jwtRefreshExpiresIn,
  });
  return { accessToken, refreshToken };
};

/**
 * Login or Register user via Firebase Phone Auth Token
 * POST /api/auth/register
 */
const register = async (req, res) => {
  const { firebaseToken } = req.body;

  if (!firebaseToken) {
    return res.status(400).json({ error: 'Firebase token is required' });
  }

  try {
    // 1. Verify the Firebase token
    const decodedToken = await getAuth().verifyIdToken(firebaseToken);
    const email = decodedToken.email;
    const uid = decodedToken.uid;

    if (!email) {
      return res.status(400).json({ error: 'Token does not contain an email address' });
    }

    // 2. Check if user exists in our PostgreSQL database
    const userQuery = await pool.query('SELECT * FROM users WHERE firebase_uid = $1 OR email = $2', [uid, email]);
    let user = userQuery.rows[0];

    // 3. If user doesn't exist, create them (Registration)
    if (!user) {
      const insertQuery = await pool.query(
        'INSERT INTO users (email, firebase_uid, status) VALUES ($1, $2, $3) RETURNING *',
        [email, uid, 'active']
      );
      user = insertQuery.rows[0];
      logger.info(`New user registered: ${user.id}`);
    }

    // 4. Generate VibeTalk JWTs
    const tokens = generateTokens(user.id);

    // 5. Update user's last_seen
    await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [user.id]);

    res.status(200).json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        username: user.username,
        avatarUrl: user.avatar_url,
        isProfileComplete: !!user.name && !!user.username, // True if they have set a display name and username
      },
      tokens,
    });
  } catch (error) {
    logger.error('Login error', { error: error.message });
    res.status(401).json({ error: 'Invalid or expired Firebase token' });
  }
};

/**
 * Refresh Access Token
 * POST /api/auth/refresh
 */
const refresh = async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: 'Refresh token is required' });
  }

  try {
    // Verify the refresh token
    const decoded = jwt.verify(refreshToken, env.jwtRefreshSecret);
    
    // Generate new tokens
    const tokens = generateTokens(decoded.userId);

    res.status(200).json(tokens);
  } catch (error) {
    logger.error('Token refresh error', { error: error.message });
    res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
};

/**
 * Logout User
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  // In a real implementation, we would blacklist the refresh token in Redis
  res.status(200).json({ message: 'Logged out successfully' });
};

/**
 * Get Current User
 * GET /api/auth/me
 */
const getMe = async (req, res) => {
  try {
    const userQuery = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const user = userQuery.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json({
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.username,
      avatarUrl: user.avatar_url,
      bio: user.bio,
    });
  } catch (error) {
    logger.error('Get profile error', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  register,
  refresh,
  logout,
  getMe,
};
