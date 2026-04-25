const express = require('express');
const router = express.Router();

/**
 * GET /api/auth
 * Placeholder — Sprint 1 will implement Firebase Phone Auth flows.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Auth routes — Sprint 1',
      endpoints: [
        'POST /api/auth/send-otp',
        'POST /api/auth/verify-otp',
        'POST /api/auth/refresh-token',
        'POST /api/auth/logout',
      ],
    },
  });
});

module.exports = router;
