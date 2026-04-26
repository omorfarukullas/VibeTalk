'use strict';

const { S3Client } = require('@aws-sdk/client-s3');
const env = require('./env');
const logger = require('../utils/logger');

/**
 * Cloudflare R2 S3-compatible client.
 * R2 uses the same AWS S3 SDK but with a custom endpoint.
 */
const r2Client = new S3Client({
  region: 'auto',
  endpoint: env.r2.endpoint,
  credentials: {
    accessKeyId: env.r2.accessKey,
    secretAccessKey: env.r2.secretKey,
  },
});

logger.info('✅ Cloudflare R2 client initialized');

module.exports = { r2Client, bucket: env.r2.bucket };
