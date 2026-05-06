const express = require('express');
const authController = require('../controllers/authController');

const router = express.Router();

// POST /api/auth/login — Login/Register with Firebase token
router.post('/login', authController.register);

// POST /api/auth/refresh — Refresh access token
router.post('/refresh', authController.refresh);

// POST /api/auth/logout
router.post('/logout', authController.logout);

module.exports = router;
