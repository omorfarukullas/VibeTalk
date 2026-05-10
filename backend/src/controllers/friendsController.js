'use strict';

const FriendModel = require('../models/Friend');
const { AppError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * POST /api/friends/request
 * Send a friend request to another user.
 */
const sendRequest = async (req, res, next) => {
  try {
    const { addresseeId } = req.body;

    if (!addresseeId) {
      return next(new AppError('addresseeId is required.', 400, 'VALIDATION_ERROR'));
    }
    if (addresseeId === req.user.id) {
      return next(new AppError('You cannot send a friend request to yourself.', 400, 'VALIDATION_ERROR'));
    }

    const result = await FriendModel.sendRequest(req.user.id, addresseeId);

    if (result.existing) {
      const status = result.existing.status;
      if (status === 'accepted') {
        return res.json({ success: true, message: 'You are already friends.' });
      }
      if (status === 'pending') {
        return res.json({ success: true, message: 'Friend request already sent.' });
      }
      if (status === 'blocked') {
        return next(new AppError('Unable to send request.', 403, 'BLOCKED'));
      }
    }

    logger.info('Friend request sent', { from: req.user.id, to: addresseeId });

    return res.status(201).json({
      success: true,
      message: 'Friend request sent!',
      data: { request: result.created },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/friends/requests
 * Get all pending incoming friend requests for the authenticated user.
 */
const getPendingRequests = async (req, res, next) => {
  try {
    const requests = await FriendModel.getPendingRequests(req.user.id);
    return res.json({
      success: true,
      data: { requests },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/friends/requests/:id
 * Accept or decline a friend request.
 * Body: { action: 'accept' | 'decline' }
 */
const respondToRequest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { action } = req.body;

    if (!['accept', 'decline'].includes(action)) {
      return next(new AppError('action must be "accept" or "decline".', 400, 'VALIDATION_ERROR'));
    }

    const newStatus = action === 'accept' ? 'accepted' : 'declined';
    const updated = await FriendModel.updateStatus(id, req.user.id, newStatus);

    if (!updated) {
      return next(new AppError('Request not found or not addressed to you.', 404, 'NOT_FOUND'));
    }

    logger.info('Friend request responded', { id, action, userId: req.user.id });

    return res.json({
      success: true,
      message: action === 'accept' ? 'Friend request accepted!' : 'Friend request declined.',
      data: { friendship: updated },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/friends
 * Get all accepted friends for the authenticated user.
 */
const getFriends = async (req, res, next) => {
  try {
    const friends = await FriendModel.getFriends(req.user.id);
    return res.json({
      success: true,
      data: { friends },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/friends/:friendId
 * Remove a friend.
 */
const removeFriend = async (req, res, next) => {
  try {
    const { friendId } = req.params;
    const removed = await FriendModel.removeFriend(req.user.id, friendId);

    if (!removed) {
      return next(new AppError('Friendship not found.', 404, 'NOT_FOUND'));
    }

    return res.json({ success: true, message: 'Friend removed.' });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/friends/status/:userId
 * Check friendship status with a specific user.
 */
const getFriendStatus = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const status = await FriendModel.getStatus(req.user.id, userId);
    return res.json({
      success: true,
      data: { status: status ? status.status : null, request: status },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendRequest,
  getPendingRequests,
  respondToRequest,
  getFriends,
  removeFriend,
  getFriendStatus,
};
