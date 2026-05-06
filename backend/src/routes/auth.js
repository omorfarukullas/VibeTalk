'use strict';

const express = require('express');
const router = express.Router();
const { register, refresh, logout, getMe } = require('../controllers/authController');
const { verifyFirebaseMiddleware } = require('../middleware/authMiddleware');
const { authenticate } = require('../middleware/auth');

/**
 * POST /api/auth/register
 * Client presents Firebase ID token in body → server verifies, creates/finds user, issues JWTs.
 */
router.post('/register', register);

/**
 * POST /api/auth/refresh
 * Client presents refresh token → server validates, rotates both tokens.
 */
router.post('/refresh', refresh);

/**
 * POST /api/auth/logout
 * Requires our own JWT. Deletes refresh token from Redis.
 */
router.post('/logout', authenticate, logout);

/**
 * GET /api/auth/me
 * Requires our own JWT. Returns current user profile.
 */
router.get('/me', authenticate, getMe);

module.exports = router;
