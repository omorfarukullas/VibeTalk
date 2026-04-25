const { Server } = require('socket.io');
const logger = require('../utils/logger');

/**
 * Initialize Socket.IO server with connection handling.
 * @param {import('http').Server} httpServer
 * @returns {Server}
 */
const initSocket = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN || '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    transports: ['websocket', 'polling'],
  });

  // ── Connection Handling ───────────────────────────────────────────────
  io.on('connection', (socket) => {
    const userId = socket.handshake.auth?.userId;
    logger.info('Socket connected', {
      socketId: socket.id,
      userId: userId || 'anonymous',
      transport: socket.conn.transport.name,
    });

    // ── Room Management ───────────────────────────────────────────────
    socket.on('join_room', ({ roomId }) => {
      if (!roomId) return;
      socket.join(roomId);
      logger.info('User joined room', { socketId: socket.id, roomId });
      socket.to(roomId).emit('user_joined', {
        userId,
        roomId,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on('leave_room', ({ roomId }) => {
      if (!roomId) return;
      socket.leave(roomId);
      logger.info('User left room', { socketId: socket.id, roomId });
      socket.to(roomId).emit('user_left', {
        userId,
        roomId,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Messaging ─────────────────────────────────────────────────────
    socket.on('send_message', (data) => {
      const { roomId, message } = data;
      if (!roomId || !message) return;
      logger.debug('Message sent', { socketId: socket.id, roomId });
      socket.to(roomId).emit('receive_message', {
        ...message,
        senderId: userId,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Typing Indicators ─────────────────────────────────────────────
    socket.on('typing', ({ roomId, isTyping }) => {
      if (!roomId) return;
      socket.to(roomId).emit('user_typing', {
        userId,
        isTyping,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Message Status ────────────────────────────────────────────────
    socket.on('message_delivered', ({ messageId, roomId }) => {
      if (!roomId || !messageId) return;
      socket.to(roomId).emit('message_status', {
        messageId,
        status: 'delivered',
        userId,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on('message_read', ({ messageId, roomId }) => {
      if (!roomId || !messageId) return;
      socket.to(roomId).emit('message_status', {
        messageId,
        status: 'read',
        userId,
        timestamp: new Date().toISOString(),
      });
    });

    // ── WebRTC Call Signaling ─────────────────────────────────────────
    socket.on('call_offer', (data) => {
      logger.info('Call offer', { from: socket.id, to: data.targetUserId });
      io.to(data.targetUserId).emit('call_offer', {
        ...data,
        callerId: userId,
      });
    });

    socket.on('call_answer', (data) => {
      logger.info('Call answer', { from: socket.id, to: data.targetUserId });
      io.to(data.targetUserId).emit('call_answer', {
        ...data,
        answererId: userId,
      });
    });

    socket.on('call_ice_candidate', (data) => {
      io.to(data.targetUserId).emit('call_ice_candidate', {
        candidate: data.candidate,
        from: userId,
      });
    });

    socket.on('call_end', (data) => {
      logger.info('Call ended', { from: socket.id, to: data.targetUserId });
      io.to(data.targetUserId).emit('call_end', {
        from: userId,
        reason: data.reason || 'ended',
      });
    });

    // ── Presence ──────────────────────────────────────────────────────
    socket.on('user_online', () => {
      socket.broadcast.emit('user_online', {
        userId,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Disconnection ─────────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      logger.info('Socket disconnected', {
        socketId: socket.id,
        userId: userId || 'anonymous',
        reason,
      });
      socket.broadcast.emit('user_offline', {
        userId,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Error Handling ────────────────────────────────────────────────
    socket.on('error', (error) => {
      logger.error('Socket error', {
        socketId: socket.id,
        error: error.message,
      });
    });
  });

  logger.info('Socket.IO initialized');
  return io;
};

module.exports = { initSocket };
