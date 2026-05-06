// Load and validate environment variables FIRST
const env = require('./config/env');

const http = require('http');
const app = require('./app');
const { initSocket } = require('./socket');
const { testConnection: testDB } = require('./config/db');
const { testConnection: testRedis } = require('./config/redis');
const logger = require('./utils/logger');

const PORT = env.port;

/**
 * Create HTTP server and attach Socket.IO.
 */
const server = http.createServer(app);

// Initialize Socket.IO
const io = initSocket(server);

// Make io accessible in routes via req.app
app.set('io', io);

/**
 * Start the server.
 */
const start = async () => {
  try {
    // Test database connection
    const dbConnected = await testDB();
    if (dbConnected) {
      logger.info('✅ PostgreSQL connected');
    } else {
      logger.warn('⚠️  PostgreSQL connection failed — server starting without DB');
    }

    // Test Redis connection
    const redisConnected = await testRedis();
    if (redisConnected) {
      logger.info('✅ Redis connected');
    } else {
      logger.warn('⚠️  Redis connection failed — server starting without cache');
    }

    // Start listening
    server.listen(PORT, () => {
      logger.info(`🚀 VibeTalk server running on port ${PORT}`);
      logger.info(`📡 Environment: ${env.nodeEnv}`);
      logger.info(`🏥 Health check: http://localhost:${PORT}/api/health`);
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
};

// ── Graceful Shutdown ──────────────────────────────────────────────────
const shutdown = async (signal) => {
  logger.info(`${signal} received. Shutting down gracefully...`);

  server.close(() => {
    logger.info('HTTP server closed');
  });

  // Close Socket.IO connections
  io.close(() => {
    logger.info('Socket.IO server closed');
  });

  // Close database pool
  const { pool } = require('./config/db');
  await pool.end();
  logger.info('PostgreSQL pool closed');

  // Close Redis connection
  const { redis } = require('./config/redis');
  redis.disconnect();
  logger.info('Redis connection closed');

  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection', { reason: reason?.toString() });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

start();
