/**
 * Messages Controller — Sprint 2 implementation.
 */

const getMessages = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get messages — Sprint 2' } });
};

const sendMessage = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Message sent — Sprint 2' } });
};

const deleteMessage = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Message deleted — Sprint 2' } });
};

const updateStatus = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Status updated — Sprint 2' } });
};

module.exports = { getMessages, sendMessage, deleteMessage, updateStatus };
