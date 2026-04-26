'use strict';

const { verifyFirebaseToken } = require('../config/firebase');
const { AppError } = require('./errorHandler');
const logger = require('../utils/logger');

/**
 * Firebase Token Verification Middleware.
 *
 * Used ONLY on the /register endpoint where the client presents
 * a raw Firebase ID token (from phone OTP). After registration
 * the client uses our own JWT; subsequent requests use auth.js (JWT).
 *
 * - Returns 401 if Authorization header is missing or token is invalid.
 * - Returns 403 if token is expired.
 * - Attaches { uid, phone_number } to req.firebaseUser on success.
 */
const verifyFirebaseMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(
      new AppError(
        'Firebase ID token required. Provide Authorization: Bearer <token>.',
        401,
        'FIREBASE_TOKEN_MISSING',
      ),
    );
  }

  const idToken = authHeader.split(' ')[1];

  try {
    const decoded = await verifyFirebaseToken(idToken);

    req.firebaseUser = {
      uid: decoded.uid,
      phone_number: decoded.phone_number,
    };

    next();
  } catch (error) {
    logger.warn('Firebase token verification failed', { error: error.code });

    if (
      error.code === 'auth/id-token-expired' ||
      error.code === 'auth/token-expired'
    ) {
      return next(
        new AppError(
          'Firebase token has expired. Re-authenticate and try again.',
          403,
          'FIREBASE_TOKEN_EXPIRED',
        ),
      );
    }

    return next(
      new AppError(
        'Invalid Firebase ID token. Please sign in again.',
        401,
        'FIREBASE_TOKEN_INVALID',
      ),
    );
  }
};

module.exports = { verifyFirebaseMiddleware };
