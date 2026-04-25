const express = require('express');
const router = express.Router();
const { testConnection: testDB } = require('../config/db');
const { testConnection: testRedis } = require('../config/redis');
const logger = require('../utils/logger');

/**
 * GET /api/health
 * Returns server status, database status, and Redis status.
 */
router.get('/', async (req, res) => {
  const startTime = Date.now();

  // Check database
  let dbStatus = 'disconnected';
  try {
    const { pool } = require('../config/db');
    const result = await pool.query('SELECT 1');
    dbStatus = result ? 'connected' : 'disconnected';
  } catch (error) {
    logger.warn('Health check — DB failed', { error: error.message });
    dbStatus = 'error';
  }

  // Check Redis
  let redisStatus = 'disconnected';
  try {
    const { redis } = require('../config/redis');
    const pong = await redis.ping();
    redisStatus = pong === 'PONG' ? 'connected' : 'disconnected';
  } catch (error) {
    logger.warn('Health check — Redis failed', { error: error.message });
    redisStatus = 'error';
  }

  const uptime = process.uptime();
  const responseTime = Date.now() - startTime;

  const health = {
    success: true,
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: `${Math.floor(uptime)}s`,
      responseTime: `${responseTime}ms`,
      version: '1.0.0',
      services: {
        server: 'running',
        database: dbStatus,
        redis: redisStatus,
      },
      memory: {
        rss: `${Math.round(process.memoryUsage().rss / 1024 / 1024)}MB`,
        heap: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
      },
    },
  };

  // Return 503 if any critical service is down
  const statusCode =
    dbStatus === 'connected' && redisStatus === 'connected' ? 200 : 503;

  res.status(statusCode).json(health);
});

module.exports = router;
