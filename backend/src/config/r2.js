'use strict';

const { S3Client } = require('@aws-sdk/client-s3');
const env = require('./env');
const logger = require('../utils/logger');

/**
 * Cloudflare R2 S3-compatible client.
 * R2 uses the same AWS S3 SDK but with a custom endpoint.
 */
const r2Client = new S3Client({
  region: env.r2.region,
  endpoint: env.r2.endpoint,
  credentials: {
    accessKeyId: env.r2.accessKey,
    secretAccessKey: env.r2.secretKey,
  },
  forcePathStyle: true, // Required for Supabase Storage S3 compatibility
});

logger.info('✅ Storage client initialized (S3-compatible)');

module.exports = { r2Client, bucket: env.r2.bucket };

