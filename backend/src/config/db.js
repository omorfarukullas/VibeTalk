const { Pool } = require('pg');
const logger = require('../utils/logger');

/**
 * PostgreSQL connection pool using pg.
 * Connection string is read from DATABASE_URL environment variable.
 */
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// Log pool errors
pool.on('error', (err) => {
  logger.error('Unexpected PostgreSQL pool error', { error: err.message });
});

// Log successful connection on first query
pool.on('connect', () => {
  logger.info('PostgreSQL client connected');
});

/**
 * Execute a SQL query with optional parameters.
 * @param {string} text — SQL query string
 * @param {Array} params — Query parameters
 * @returns {Promise<import('pg').QueryResult>}
 */
const query = async (text, params) => {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;
  logger.debug('Executed query', {
    text: text.substring(0, 100),
    duration: `${duration}ms`,
    rows: result.rowCount,
  });
  return result;
};

/**
 * Get a client from the pool for transactions.
 * Remember to release the client after use.
 * @returns {Promise<import('pg').PoolClient>}
 */
const getClient = async () => {
  const client = await pool.connect();
  return client;
};

/**
 * Test the database connection.
 * @returns {Promise<boolean>}
 */
const testConnection = async () => {
  try {
    const result = await pool.query('SELECT NOW() AS current_time');
    logger.info('PostgreSQL connection verified', {
      serverTime: result.rows[0].current_time,
    });
    return true;
  } catch (error) {
    logger.error('PostgreSQL connection failed', { error: error.message });
    return false;
  }
};

module.exports = {
  pool,
  query,
  getClient,
  testConnection,
};
