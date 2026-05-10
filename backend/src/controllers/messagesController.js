'use strict';

const MessageModel = require('../models/Message');
const ChatModel = require('../models/Chat');
const { AppError } = require('../middleware/errorHandler');
const { query } = require('../config/db');

/**
 * GET /api/messages?chatId=...&limit=50&offset=0
 * Get messages for a specific chat with pagination support.
 */
const getMessages = async (req, res, next) => {
  try {
    const { chatId, limit = 50, offset = 0 } = req.query;

    if (!chatId) {
      return next(new AppError('chatId is required in query params', 400, 'VALIDATION_ERROR'));
    }

    const parsedLimit = Math.min(parseInt(limit, 10) || 50, 100); // Cap at 100
    const parsedOffset = parseInt(offset, 10) || 0;

    // Verify user is a participant of the chat
    const participants = await ChatModel.getParticipants(chatId);
    const isParticipant = participants.some((p) => p.id === req.user.id);

    if (!isParticipant) {
      return next(new AppError('Unauthorized access to this chat', 403, 'FORBIDDEN'));
    }

    const messages = await MessageModel.getByChatId(chatId, parsedLimit, parsedOffset);

    return res.json({
      success: true,
      data: {
        messages,
        pagination: {
          limit: parsedLimit,
          offset: parsedOffset,
          hasMore: messages.length === parsedLimit,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/messages/read
 * Phase 2: Mark multiple messages as read in bulk.
 * Body: { roomId: string, messageIds: string[] }
 */
const markMessagesRead = async (req, res, next) => {
  try {
    const { roomId, messageIds } = req.body;

    if (!roomId || !Array.isArray(messageIds) || messageIds.length === 0) {
      return next(
        new AppError('roomId and a non-empty messageIds array are required.', 400, 'VALIDATION_ERROR'),
      );
    }

    // Verify participant
    const participants = await ChatModel.getParticipants(roomId);
    const isParticipant = participants.some((p) => p.id === req.user.id);
    if (!isParticipant) {
      return next(new AppError('Unauthorized', 403, 'FORBIDDEN'));
    }

    // Bulk update — only mark messages NOT sent by this user
    const placeholders = messageIds.map((_, i) => `$${i + 3}`).join(', ');
    await query(
      `UPDATE messages
       SET status = 'read'
       WHERE chat_id = $1
         AND sender_id != $2
         AND id IN (${placeholders})
         AND status != 'read'`,
      [roomId, req.user.id, ...messageIds],
    );

    // Notify sender(s) via Socket.IO
    const io = req.app.get('io');
    if (io) {
      messageIds.forEach((msgId) => {
        io.to(roomId).emit('message_status', {
          messageId: msgId,
          status: 'read',
          userId: req.user.id,
          timestamp: new Date().toISOString(),
        });
      });
    }

    return res.json({
      success: true,
      data: { updated: messageIds.length },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getMessages, markMessagesRead };
