const express = require('express');
const router = express.Router();

/**
 * GET /api/media
 * Placeholder — will handle file upload/download via Cloudflare R2.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Media routes — Sprint 3',
      endpoints: [
        'POST /api/media/upload',
        'GET /api/media/:id',
        'DELETE /api/media/:id',
        'GET /api/media/:id/download',
      ],
    },
  });
});

module.exports = router;
