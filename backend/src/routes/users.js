'use strict';

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { uploadAvatarMiddleware } = require('../services/uploadService');
const {
  updateProfile,
  uploadAvatar,
  uploadKeys,
  getKeys,
  findContacts,
  searchUsers,
} = require('../controllers/usersController');

/**
 * GET /api/users/search
 * Search users by name or email.
 */
router.get('/search', authenticate, searchUsers);


/**
 * PUT /api/users/profile
 * Update name, bio, avatar_url.
 */
router.put('/profile', authenticate, updateProfile);

/**
 * POST /api/users/avatar
 * Multipart image upload → R2 → update avatar_url in DB.
 */
router.post('/avatar', authenticate, uploadAvatarMiddleware, uploadAvatar);

/**
 * POST /api/users/keys
 * Store Signal Protocol public key bundle.
 */
router.post('/keys', authenticate, uploadKeys);

/**
 * GET /api/users/keys/:userId
 * Retrieve public key bundle for a specific user.
 */
router.get('/keys/:userId', authenticate, getKeys);

/**
 * POST /api/users/contacts
 * Check which phone numbers are registered VibeTalk users.
 */
router.post('/contacts', authenticate, findContacts);

module.exports = router;
