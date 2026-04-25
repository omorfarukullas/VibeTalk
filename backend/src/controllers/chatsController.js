/**
 * Chats Controller — Sprint 2 implementation.
 */

const getChats = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get chats — Sprint 2' } });
};

const createChat = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Chat created — Sprint 2' } });
};

const getChat = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get chat — Sprint 2' } });
};

const deleteChat = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Chat deleted — Sprint 2' } });
};

module.exports = { getChats, createChat, getChat, deleteChat };
