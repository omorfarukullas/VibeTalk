'use strict';

const { PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { r2Client, bucket } = require('../config/r2');
const multer = require('multer');
const { AppError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

// ── Multer (memory storage) ──────────────────────────────────────────

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB

const multerUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new AppError(
          'Invalid file type. Only JPEG, PNG, WebP, and GIF images are allowed.',
          400,
          'INVALID_FILE_TYPE',
        ),
        false,
      );
    }
  },
});

/** Multer middleware for single avatar upload — field name: "avatar". */
const uploadAvatarMiddleware = multerUpload.single('avatar');

// ── Upload / Delete helpers ──────────────────────────────────────────

/**
 * Upload a buffer to Cloudflare R2.
 *
 * @param {Buffer}  buffer    — File contents
 * @param {string}  fileName  — Base filename (no extension needed)
 * @param {string}  mimeType  — e.g. "image/jpeg"
 * @param {string}  folder    — R2 folder prefix e.g. "avatars", "media"
 * @returns {Promise<string>} — Public URL of the uploaded object
 */
const uploadFile = async (buffer, fileName, mimeType, folder = 'uploads') => {
  const ext = mimeType.split('/')[1] || 'bin';
  const key = `${folder}/${fileName}.${ext}`;

  await r2Client.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mimeType,
      CacheControl: 'public, max-age=31536000',
    }),
  );

  // R2 public URL format — adjust if using a custom domain
  const publicUrl = `${process.env.CLOUDFLARE_R2_ENDPOINT}/${bucket}/${key}`;

  logger.info('File uploaded to R2', { key, size: buffer.length });

  return publicUrl;
};

/**
 * Delete an object from Cloudflare R2 by its storage key.
 * @param {string} key — The full object key (e.g. "avatars/user123.jpg")
 */
const deleteFile = async (key) => {
  await r2Client.send(
    new DeleteObjectCommand({
      Bucket: bucket,
      Key: key,
    }),
  );

  logger.info('File deleted from R2', { key });
};

module.exports = { uploadFile, deleteFile, uploadAvatarMiddleware, multerUpload };
