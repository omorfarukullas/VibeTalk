const express = require('express');
const router = express.Router();

/**
 * GET /api/users
 * Placeholder — will return user list / search.
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      message: 'Users routes — Sprint 1',
      endpoints: [
        'GET /api/users/:id',
        'PUT /api/users/:id',
        'GET /api/users/search?phone=',
        'DELETE /api/users/:id',
      ],
    },
  });
});

module.exports = router;
