const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { uploadMediaMiddleware } = require('../services/uploadService');
const { uploadMedia } = require('../controllers/mediaController');

/**
 * POST /api/media/upload
 * Upload a media file to Cloudflare R2.
 */
router.post('/upload', authenticate, uploadMediaMiddleware, uploadMedia);

module.exports = router;

