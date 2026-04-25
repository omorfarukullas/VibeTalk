const express = require('express');
const router = express.Router();

/**
 * GET /api/messages
 * Placeholder — will return messages for a chat.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Messages routes — Sprint 2',
      endpoints: [
        'GET /api/messages?chatId=',
        'POST /api/messages',
        'DELETE /api/messages/:id',
        'PATCH /api/messages/:id/status',
      ],
    },
  });
});

module.exports = router;
