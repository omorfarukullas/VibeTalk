/**
 * Chats Controller — Sprint 2 implementation.
 */

const ChatModel = require('../models/Chat');
const { AppError } = require('../middleware/errorHandler');

const getChats = async (req, res, next) => {
  try {
    const chats = await ChatModel.getUserChats(req.user.id);

    return res.json({
      success: true,
      data: { chats },
    });
  } catch (error) {
    next(error);
  }
};

const createChat = async (req, res, next) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return next(new AppError('userId is required', 400, 'VALIDATION_ERROR'));
    }

    if (userId === req.user.id) {
      return next(new AppError('Cannot create a chat with yourself', 400, 'VALIDATION_ERROR'));
    }

    const chat = await ChatModel.createDirectChat(req.user.id, userId);

    return res.status(201).json({
      success: true,
      data: { chat },
    });
  } catch (error) {
    next(error);
  }
};

const getChat = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get chat — Sprint 2' } });
};

const deleteChat = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Chat deleted — Sprint 2' } });
};

module.exports = { getChats, createChat, getChat, deleteChat };

