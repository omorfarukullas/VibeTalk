const express = require('express');
const router = express.Router();

/**
 * GET /api/calls
 * Placeholder — will handle call history and signaling metadata.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Calls routes — Sprint 3',
      endpoints: [
        'GET /api/calls',
        'POST /api/calls',
        'PATCH /api/calls/:id/status',
        'GET /api/calls/:id',
      ],
    },
  });
});

module.exports = router;
