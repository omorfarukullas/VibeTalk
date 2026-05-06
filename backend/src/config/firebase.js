'use strict';

const admin = require('firebase-admin');
const env = require('./env');
const logger = require('../utils/logger');

/**
 * Firebase Admin SDK — initialized once at server start.
 * Used to verify Firebase ID tokens issued by the mobile client
 * (phone OTP auth) before issuing our own JWT tokens.
 */
let firebaseApp;

const initFirebase = () => {
  if (admin.apps.length > 0) {
    return admin.apps[0];
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.firebase.projectId,
        privateKey: env.firebase.privateKey,
        clientEmail: env.firebase.clientEmail,
      }),
    });

    logger.info('✅ Firebase Admin SDK initialized');
    return firebaseApp;
  } catch (error) {
    logger.error('❌ Firebase Admin SDK initialization failed', {
      error: error.message,
    });
    throw error;
  }
};

/**
 * Verify a Firebase ID token and return the decoded payload.
 * @param {string} idToken — The raw Firebase ID token from the mobile client.
 * @returns {Promise<admin.auth.DecodedIdToken>}
 */
const verifyFirebaseToken = async (idToken) => {
  const app = admin.apps.length > 0 ? admin.apps[0] : initFirebase();
  return app.auth().verifyIdToken(idToken);
};

// Initialise on module load
initFirebase();

/**
 * Pre-warm the Firebase public key cache.
 * Firebase Admin fetches JWT signing keys from googleapis.com on first
 * verifyIdToken() call. If that happens during a cold-start race the
 * request can ECONNREFUSED. We trigger a dummy verification here so the
 * keys are cached before the first real login request arrives.
 */
const warmupFirebaseKeys = async (attempts = 5, delayMs = 1000) => {
  for (let i = 0; i < attempts; i++) {
    try {
      // This will throw argument-error (dummy token) but WILL fetch+cache the public keys.
      // Do NOT swallow the error here — let the catch block decide.
      await admin.auth().verifyIdToken('warmup-dummy-token');
    } catch (err) {
      if (err.code === 'ECONNREFUSED' || err.message?.includes('ECONNREFUSED')) {
        // Keys not fetched yet — retry with backoff
        logger.warn(`Firebase key warmup attempt ${i + 1}/${attempts} — ECONNREFUSED, retrying in ${delayMs}ms`);
        await new Promise((r) => setTimeout(r, delayMs));
        delayMs = Math.min(delayMs * 2, 8000);
        continue;
      }
      // Any other error (argument-error, invalid-id-token, etc.) means
      // the HTTPS key fetch succeeded — keys are now cached.
      logger.info('✅ Firebase public key cache warmed up');
      return;
    }
  }
  logger.warn('⚠️  Firebase key warmup exhausted retries — first login may be slow');
};

warmupFirebaseKeys();

module.exports = { verifyFirebaseToken, admin };
