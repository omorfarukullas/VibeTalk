const express = require('express');
const router = express.Router();

/**
 * GET /api/groups
 * Placeholder — will return user's groups.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Groups routes — Sprint 4',
      endpoints: [
        'GET /api/groups',
        'POST /api/groups',
        'GET /api/groups/:id',
        'PUT /api/groups/:id',
        'DELETE /api/groups/:id',
        'POST /api/groups/:id/members',
        'DELETE /api/groups/:id/members/:userId',
        'GET /api/groups/join/:inviteLink',
      ],
    },
  });
});

module.exports = router;
