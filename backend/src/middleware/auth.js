const jwt = require('jsonwebtoken');
const { AppError } = require('./errorHandler');
const logger = require('../utils/logger');

/**
 * JWT authentication middleware.
 * Verifies the Bearer token from the Authorization header
 * and attaches the decoded user to req.user.
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new AppError('Authentication required. Please provide a valid token.', 401, 'AUTH_REQUIRED');
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = {
      id: decoded.userId,
      phone: decoded.phone,
    };
    next();

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new AppError('Token has expired. Please refresh your session.', 401, 'TOKEN_EXPIRED');
    }
    if (error.name === 'JsonWebTokenError') {
      throw new AppError('Invalid token. Please sign in again.', 401, 'INVALID_TOKEN');
    }
    logger.error('Authentication error', { error: error.message });
    throw new AppError('Authentication failed.', 401, 'AUTH_FAILED');
  }
};

/**
 * Optional authentication middleware.
 * Attaches user if token is present, but does not block the request.
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = {
      id: decoded.userId,
      phone: decoded.phone,
    };
  } catch {

    // Silently ignore invalid tokens in optional auth
  }

  next();
};

module.exports = {
  authenticate,
  optionalAuth,
};
