const dotenv = require('dotenv');

// Load .env file before anything else
dotenv.config();

/**
 * Environment configuration — loads and validates all required
 * environment variables. Fails fast if any are missing.
 */
const criticalVars = [
  'PORT',
  'DATABASE_URL',
  'JWT_SECRET',
  'JWT_REFRESH_SECRET',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_PRIVATE_KEY',
  'FIREBASE_CLIENT_EMAIL',
];

const missing = criticalVars.filter((key) => !process.env[key]);

if (missing.length > 0) {
  console.error(
    `❌ Missing CRITICAL environment variables:\n  ${missing.join('\n  ')}`
  );
  console.error('\nPlease fill in these values in your .env file.');
  process.exit(1);
}

const env = {
  // Server
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  databaseUrl: process.env.DATABASE_URL,

  // Redis
  redisUrl: process.env.REDIS_URL,

  // JWT
  jwtSecret: process.env.JWT_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',

  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').replace(/\r/g, ''),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  },

  // Cloudflare R2
  r2: {
    bucket: process.env.CLOUDFLARE_R2_BUCKET,
    accessKey: process.env.CLOUDFLARE_R2_ACCESS_KEY,
    secretKey: process.env.CLOUDFLARE_R2_SECRET_KEY,
    endpoint: process.env.CLOUDFLARE_R2_ENDPOINT,
  },

  // Sentry
  sentryDsn: process.env.SENTRY_DSN,
};

module.exports = env;
