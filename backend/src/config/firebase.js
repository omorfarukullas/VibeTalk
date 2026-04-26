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

module.exports = { verifyFirebaseToken, admin };
