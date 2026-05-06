'use strict';

const { uploadFile } = require('../services/uploadService');
const { AppError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * POST /api/media/upload
 * Upload a media file (image, document, video, etc.) to Cloudflare R2
 * and return the public URL.
 */
const uploadMedia = async (req, res, next) => {
  try {
    if (!req.file) {
      return next(new AppError('No file provided.', 400));
    }

    // Determine the type folder based on mimetype
    let folder = 'attachments';
    if (req.file.mimetype.startsWith('image/')) {
      folder = 'images';
    } else if (req.file.mimetype.startsWith('video/')) {
      folder = 'videos';
    }

    const fileName = `${req.user.id}_${Date.now()}_${req.file.originalname.replace(/[^a-zA-Z0-9.]/g, '_')}`;
    
    const publicUrl = await uploadFile(
      req.file.buffer,
      fileName,
      req.file.mimetype,
      folder
    );

    logger.info('Media uploaded', { userId: req.user.id, url: publicUrl, type: req.file.mimetype });

    return res.status(201).json({
      success: true,
      data: {
        url: publicUrl,
        type: req.file.mimetype,
        name: req.file.originalname,
        size: req.file.size
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { uploadMedia };
