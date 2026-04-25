const logger = require('../utils/logger');

/**
 * Global error handler middleware.
 * Catches all errors passed via next(error) and returns
 * a structured JSON error response.
 *
 * Must be registered AFTER all routes in Express.
 */
const errorHandler = (err, req, res, _next) => {
  // Default to 500 Internal Server Error
  const statusCode = err.statusCode || err.status || 500;
  const isOperational = err.isOperational || statusCode < 500;

  // Log the error
  if (statusCode >= 500) {
    logger.error('Internal server error', {
      error: err.message,
      stack: err.stack,
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userId: req.user?.id,
    });
  } else {
    logger.warn('Client error', {
      error: err.message,
      statusCode,
      method: req.method,
      url: req.originalUrl,
    });
  }

  // Build response
  const response = {
    success: false,
    error: {
      message: isOperational
        ? err.message
        : 'An unexpected error occurred. Please try again later.',
      code: err.code || 'INTERNAL_ERROR',
    },
  };

  // Include stack trace in development only
  if (process.env.NODE_ENV === 'development') {
    response.error.stack = err.stack;
  }

  // Include validation errors if present
  if (err.errors) {
    response.error.details = err.errors;
  }

  res.status(statusCode).json(response);
};

/**
 * Custom application error class for operational errors.
 * Use this for expected errors (validation, auth, not found, etc.)
 */
class AppError extends Error {
  /**
   * @param {string} message — Human-readable error message
   * @param {number} statusCode — HTTP status code
   * @param {string} [code] — Machine-readable error code
   */
  constructor(message, statusCode, code) {
    super(message);
    this.statusCode = statusCode;
    this.code = code || 'APP_ERROR';
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * 404 handler — catches requests to undefined routes.
 * Must be registered AFTER all routes but BEFORE errorHandler.
 */
const notFoundHandler = (req, res, _next) => {
  res.status(404).json({
    success: false,
    error: {
      message: `Route ${req.method} ${req.originalUrl} not found`,
      code: 'NOT_FOUND',
    },
  });
};

module.exports = {
  errorHandler,
  notFoundHandler,
  AppError,
};
