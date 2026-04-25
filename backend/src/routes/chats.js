const express = require('express');
const router = express.Router();

/**
 * GET /api/chats
 * Placeholder — will return user's chat list.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Chats routes — Sprint 2',
      endpoints: [
        'GET /api/chats',
        'POST /api/chats',
        'GET /api/chats/:id',
        'DELETE /api/chats/:id',
        'GET /api/chats/:id/participants',
      ],
    },
  });
});

module.exports = router;
