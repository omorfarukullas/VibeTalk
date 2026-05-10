'use strict';

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  sendRequest,
  getPendingRequests,
  respondToRequest,
  getFriends,
  removeFriend,
  getFriendStatus,
} = require('../controllers/friendsController');

/**
 * POST /api/friends/request
 * Send a friend request.
 */
router.post('/request', authenticate, sendRequest);

/**
 * GET /api/friends/requests
 * Get all pending incoming friend requests.
 */
router.get('/requests', authenticate, getPendingRequests);

/**
 * PUT /api/friends/requests/:id
 * Accept or decline a friend request.
 */
router.put('/requests/:id', authenticate, respondToRequest);

/**
 * GET /api/friends
 * Get all accepted friends.
 */
router.get('/', authenticate, getFriends);

/**
 * GET /api/friends/status/:userId
 * Check friendship status with a specific user.
 */
router.get('/status/:userId', authenticate, getFriendStatus);

/**
 * DELETE /api/friends/:friendId
 * Remove a friend.
 */
router.delete('/:friendId', authenticate, removeFriend);

module.exports = router;
