const Redis = require('ioredis');
const logger = require('../utils/logger');

/**
 * Redis client using ioredis.
 * Connection string is read from REDIS_URL environment variable.
 */
const redis = new Redis(process.env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 1000,
  lazyConnect: true,
  enableReadyCheck: true,
  reconnectOnError: (err) => {
    const targetErrors = ['READONLY', 'ECONNRESET', 'ECONNREFUSED'];
    return targetErrors.some((e) => err.message.includes(e));
  },
});

redis.on('connect', () => {
  logger.info('Redis client connected');
});

redis.on('ready', () => {
  logger.info('Redis client ready');
});

redis.on('error', (err) => {
  logger.error('Redis client error', { error: err.message });
});

redis.on('close', () => {
  logger.warn('Redis connection closed');
});

redis.on('reconnecting', (delay) => {
  logger.info('Redis reconnecting', { delay });
});

/**
 * Test the Redis connection.
 * @returns {Promise<boolean>}
 */
const testConnection = async () => {
  try {
    await redis.connect();
    const pong = await redis.ping();
    logger.info('Redis connection verified', { response: pong });
    return true;
  } catch (error) {
    // If already connected, just ping
    if (error.message.includes('already')) {
      try {
        const pong = await redis.ping();
        logger.info('Redis connection verified', { response: pong });
        return true;
      } catch (pingError) {
        logger.error('Redis ping failed', { error: pingError.message });
        return false;
      }
    }
    logger.error('Redis connection failed', { error: error.message });
    return false;
  }
};

/**
 * Cache helper — set a key with optional TTL.
 * @param {string} key
 * @param {*} value
 * @param {number} [ttlSeconds]
 */
const setCache = async (key, value, ttlSeconds) => {
  const serialized = JSON.stringify(value);
  if (ttlSeconds) {
    await redis.set(key, serialized, 'EX', ttlSeconds);
  } else {
    await redis.set(key, serialized);
  }
};

/**
 * Cache helper — get a key and parse JSON.
 * @param {string} key
 * @returns {Promise<*|null>}
 */
const getCache = async (key) => {
  const data = await redis.get(key);
  if (!data) return null;
  try {
    return JSON.parse(data);
  } catch {
    return data;
  }
};

/**
 * Cache helper — delete a key.
 * @param {string} key
 */
const deleteCache = async (key) => {
  await redis.del(key);
};

module.exports = {
  redis,
  testConnection,
  setCache,
  getCache,
  deleteCache,
};
