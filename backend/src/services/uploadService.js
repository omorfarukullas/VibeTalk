'use strict';

const { PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { r2Client, bucket } = require('../config/r2');
const multer = require('multer');
const { AppError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

// ── Multer (memory storage) ──────────────────────────────────────────

const ALLOWED_MIME_TYPES = [
  // Images
  'image/jpeg', 'image/png', 'image/webp', 'image/gif',
  // Video
  'video/mp4', 'video/quicktime', 'video/x-msvideo',
  // Audio
  'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/ogg',
  // Documents
  'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'text/plain'
];
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50 MB


const multerUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  // Allow all file types for chat media and documents
  fileFilter: (_req, file, cb) => {
    cb(null, true);
  },
});

/** Multer middleware for single avatar upload — field name: "avatar". */
const uploadAvatarMiddleware = multerUpload.single('avatar');

/** Multer middleware for single media upload — field name: "file". */
const uploadMediaMiddleware = multerUpload.single('file');


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

  // Convert Supabase S3 API endpoint to the public URL format
  // Example endpoint: https://<project>.supabase.co/storage/v1/s3
  // Target public URL: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<key>
  const endpoint = process.env.CLOUDFLARE_R2_ENDPOINT || '';
  const baseUrl = endpoint.replace('/s3', '/object/public');
  const publicUrl = `${baseUrl}/${bucket}/${key}`;

  logger.info('File uploaded to storage', { key, size: buffer.length });

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

module.exports = { uploadFile, deleteFile, uploadAvatarMiddleware, uploadMediaMiddleware, multerUpload };

