'use strict';

const MessageModel = require('../models/Message');
const ChatModel = require('../models/Chat');
const { AppError } = require('../middleware/errorHandler');

/**
 * GET /api/messages?chatId=...&limit=50&offset=0
 * Get messages for a specific chat.
 */
const getMessages = async (req, res, next) => {
  try {
    const { chatId, limit = 50, offset = 0 } = req.query;

    if (!chatId) {
      return next(new AppError('chatId is required in query params', 400, 'VALIDATION_ERROR'));
    }

    // Verify user is a participant of the chat
    const participants = await ChatModel.getParticipants(chatId);
    const isParticipant = participants.some((p) => p.id === req.user.id);

    if (!isParticipant) {
      return next(new AppError('Unauthorized access to this chat', 403, 'FORBIDDEN'));
    }

    const messages = await MessageModel.getByChatId(chatId, parseInt(limit), parseInt(offset));

    return res.json({
      success: true,
      data: { messages },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMessages,
};
