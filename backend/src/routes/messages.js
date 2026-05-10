const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { getMessages, markMessagesRead } = require('../controllers/messagesController');

/**
 * GET /api/messages?chatId=...&limit=50&offset=0
 * Get historical messages for a chat (paginated).
 */
router.get('/', authenticate, getMessages);

/**
 * PATCH /api/messages/read
 * Phase 2: Mark a batch of messages as read and notify sender via Socket.IO.
 */
router.patch('/read', authenticate, markMessagesRead);

module.exports = router;
