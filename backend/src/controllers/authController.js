'use strict';

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { verifyFirebaseToken } = require('../config/firebase');
const { setCache, getCache, deleteCache } = require('../config/redis');
const UserModel = require('../models/User');
const { AppError } = require('../middleware/errorHandler');
const env = require('../config/env');
const logger = require('../utils/logger');

// ── Token helpers ─────────────────────────────────────────────────────

const REFRESH_TOKEN_TTL = 30 * 24 * 60 * 60; // 30 days in seconds

/**
 * Issue a short-lived JWT access token.
 */
const signAccessToken = (userId, phone) => {
  return jwt.sign(
    { id: userId, phone },
    env.jwtSecret,
    { expiresIn: '15m' },
  );
};

/**
 * Issue a long-lived JWT refresh token.
 */
const signRefreshToken = (userId) => {
  return jwt.sign(
    { id: userId, type: 'refresh' },
    env.jwtRefreshSecret,
    { expiresIn: '30d' },
  );
};

/**
 * Hash a refresh token before storing in Redis.
 */
const hashToken = async (token) => {
  return bcrypt.hash(token, 10);
};

/**
 * Compare a refresh token against its stored hash.
 */
const compareToken = async (token, hash) => {
  return bcrypt.compare(token, hash);
};

// ── Controllers ───────────────────────────────────────────────────────

/**
 * POST /api/auth/register
 *
 * 1. Verify Firebase ID token (set by verifyFirebaseMiddleware).
 * 2. Find or create user in PostgreSQL by phone_number.
 * 3. Issue access + refresh tokens.
 * 4. Store hashed refresh token in Redis.
 */
const register = async (req, res, next) => {
  try {
    const { name, avatar_url } = req.body;
    const { uid: firebase_uid, phone_number } = req.firebaseUser;

    if (!phone_number) {
      return next(
        new AppError(
          'Phone number not found in Firebase token. Ensure phone auth was used.',
          400,
          'PHONE_MISSING',
        ),
      );
    }

    // Find or create user
    let user = await UserModel.findByPhone(phone_number);
    const isNewUser = !user;

    if (isNewUser) {
      user = await UserModel.create({
        phone_number,
        name: name || null,
        avatar_url: avatar_url || null,
        firebase_uid,
      });
      logger.info('New user created', { userId: user.id, phone: phone_number });
    } else {
      logger.info('Existing user logged in', { userId: user.id });
    }

    // Issue tokens
    const accessToken = signAccessToken(user.id, user.phone_number);
    const refreshToken = signRefreshToken(user.id);
    const tokenHash = await hashToken(refreshToken);

    // Store hashed refresh token in Redis with 30-day TTL
    await setCache(`refresh:${user.id}`, tokenHash, REFRESH_TOKEN_TTL);

    const { id, phone_number: phone, avatar_url: avatar, bio, status, created_at } = user;

    return res.status(isNewUser ? 201 : 200).json({
      success: true,
      data: {
        user: { id, phone_number: phone, name: user.name, avatar_url: avatar, bio, status, created_at },
        access_token: accessToken,
        refresh_token: refreshToken,
        is_new_user: isNewUser,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/refresh
 *
 * 1. Validate the provided refresh token (JWT signature + Redis hash).
 * 2. Issue new access token + rotated refresh token.
 * 3. Update Redis with new hash.
 */
const refresh = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return next(new AppError('refresh_token is required.', 400, 'REFRESH_TOKEN_MISSING'));
    }

    // Validate JWT signature
    let decoded;
    try {
      decoded = jwt.verify(refresh_token, env.jwtRefreshSecret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return next(new AppError('Refresh token expired. Please sign in again.', 401, 'REFRESH_TOKEN_EXPIRED'));
      }
      return next(new AppError('Invalid refresh token.', 401, 'REFRESH_TOKEN_INVALID'));
    }

    if (decoded.type !== 'refresh') {
      return next(new AppError('Invalid token type.', 401, 'REFRESH_TOKEN_INVALID'));
    }

    // Validate against stored hash
    const storedHash = await getCache(`refresh:${decoded.id}`);
    if (!storedHash) {
      return next(new AppError('Session not found. Please sign in again.', 401, 'SESSION_NOT_FOUND'));
    }

    const isValid = await compareToken(refresh_token, storedHash);
    if (!isValid) {
      // Possible token theft — invalidate session
      await deleteCache(`refresh:${decoded.id}`);
      return next(new AppError('Token mismatch. Session invalidated for security.', 401, 'REFRESH_TOKEN_MISMATCH'));
    }

    // Fetch user to get current phone
    const user = await UserModel.findById(decoded.id);
    if (!user) {
      return next(new AppError('User not found.', 404, 'USER_NOT_FOUND'));
    }

    // Rotate tokens
    const newAccessToken = signAccessToken(user.id, user.phone_number);
    const newRefreshToken = signRefreshToken(user.id);
    const newHash = await hashToken(newRefreshToken);

    await setCache(`refresh:${user.id}`, newHash, REFRESH_TOKEN_TTL);

    return res.json({
      success: true,
      data: {
        access_token: newAccessToken,
        refresh_token: newRefreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/logout
 * Requires: JWT auth middleware (req.user.id set).
 */
const logout = async (req, res, next) => {
  try {
    await deleteCache(`refresh:${req.user.id}`);
    logger.info('User logged out', { userId: req.user.id });

    return res.json({
      success: true,
      data: { message: 'Logged out successfully.' },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/auth/me
 * Requires: JWT auth middleware.
 */
const getMe = async (req, res, next) => {
  try {
    const user = await UserModel.findById(req.user.id);
    if (!user) {
      return next(new AppError('User not found.', 404, 'USER_NOT_FOUND'));
    }

    const { id, phone_number, name, avatar_url, bio, status, last_seen, created_at, updated_at } = user;

    return res.json({
      success: true,
      data: {
        user: { id, phone_number, name, avatar_url, bio, status, last_seen, created_at, updated_at },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, refresh, logout, getMe };
