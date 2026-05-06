const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { getMessages } = require('../controllers/messagesController');

/**
 * GET /api/messages?chatId=...
 * Get historical messages for a chat.
 */
router.get('/', authenticate, getMessages);

module.exports = router;

