const express = require('express');
const authController = require('../controllers/authController');

const router = express.Router();

// POST /api/auth/login — Login with Firebase token
router.post('/login', authController.login);

// POST /api/auth/refresh — Refresh access token
router.post('/refresh', authController.refreshToken);

module.exports = router;
