const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { getChats, createChat } = require('../controllers/chatsController');

/**
 * GET /api/chats
 * Get all chats for the authenticated user.
 */
router.get('/', authenticate, getChats);

/**
 * POST /api/chats
 * Create or get a direct chat.
 */
router.post('/', authenticate, createChat);

module.exports = router;

