const { Server } = require('socket.io');
const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');
const { redis } = require('../config/redis');
const MessageModel = require('../models/Message');

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

  // ── Authentication Middleware ─────────────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
      return next(new Error('Authentication error: Token required'));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = {
        id: decoded.userId,
        phone: decoded.phone,
      };
      next();
    } catch (error) {
      logger.error('Socket authentication failed', { error: error.message });
      next(new Error('Authentication error: Invalid or expired token'));
    }
  });

  // ── Connection Handling ───────────────────────────────────────────────
  io.on('connection', async (socket) => {
    const userId = socket.user.id;
    logger.info('Socket connected', {
      socketId: socket.id,
      userId,
      transport: socket.conn.transport.name,
    });

    // Track presence in Redis
    await redis.sadd(`user:${userId}:sockets`, socket.id);
    
    // Announce online status
    socket.broadcast.emit('user_online', {
      userId,
      timestamp: new Date().toISOString(),
    });

    // ── Token Refresh ─────────────────────────────────────────────────
    socket.on('refresh_token', ({ token }, callback) => {
      if (!token) return;
      try {
        const decoded = jwt.verify(token, env.jwtSecret);
        socket.user = { id: decoded.userId };
        logger.info('Socket token refreshed', { socketId: socket.id, userId: socket.user.id });
        if (typeof callback === 'function') callback({ success: true });
      } catch (error) {
        logger.error('Socket token refresh failed', { socketId: socket.id, error: error.message });
        if (typeof callback === 'function') callback({ success: false, error: 'Invalid token' });
      }
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
    socket.on('send_message', async (data) => {
      const { roomId, message } = data;
      // Note: frontend currently sends data directly, not nested in `message`
      // So let's handle if it's flat:
      const payload = message || data;
      const chatRoomId = payload.roomId || roomId;
      
      if (!chatRoomId || !payload.ciphertext) return;
      
      try {
        let msgType = payload.messageType || 'text';
        if (msgType === 'file') msgType = 'document';

        // Persist message to database
        const savedMessage = await MessageModel.create({
          chat_id: chatRoomId,
          sender_id: userId,
          content: JSON.stringify({
             ciphertext: payload.ciphertext,
             iv: payload.iv,
             sessionKey: payload.sessionKey,
             text: payload.text, // Mock only
             mediaUrl: payload.mediaUrl // Mock only for images/files
          }),
          message_type: msgType,
        });


        logger.debug('Message persisted & sent', { socketId: socket.id, roomId: chatRoomId, msgId: savedMessage.id });
        
        // Broadcast to room
        socket.to(chatRoomId).emit('receive_message', {
          ...payload,
          id: savedMessage.id, // Use DB generated UUID
          senderId: userId,
          status: 'sent',
          timestamp: savedMessage.created_at,
        });
      } catch (err) {
        logger.error('Failed to persist message', { error: err.message });
      }
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
    socket.on('message_delivered', async ({ messageId, roomId }) => {
      if (!roomId || !messageId) return;
      try {
        await MessageModel.updateStatus(messageId, 'delivered');
        socket.to(roomId).emit('message_status', {
          messageId,
          status: 'delivered',
          userId,
          timestamp: new Date().toISOString(),
        });
      } catch (err) {
        logger.error('Failed to update delivered status', { error: err.message });
      }
    });

    socket.on('message_read', async ({ messageId, roomId }) => {
      if (!roomId || !messageId) return;
      try {
        await MessageModel.updateStatus(messageId, 'read');
        socket.to(roomId).emit('message_status', {
          messageId,
          status: 'read',
          userId,
          timestamp: new Date().toISOString(),
        });
      } catch (err) {
        logger.error('Failed to update read status', { error: err.message });
      }
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

    // ── Disconnection ─────────────────────────────────────────────────
    socket.on('disconnect', async (reason) => {
      logger.info('Socket disconnected', {
        socketId: socket.id,
        userId,
        reason,
      });

      // Remove socket from Redis
      await redis.srem(`user:${userId}:sockets`, socket.id);
      
      // If no sockets left, user is fully offline
      const activeSockets = await redis.scard(`user:${userId}:sockets`);
      if (activeSockets === 0) {
        // Broadcast offline status
        socket.broadcast.emit('user_offline', {
          userId,
          timestamp: new Date().toISOString(),
        });

        // Persist last_seen to DB
        try {
          const UserModel = require('../models/User');
          await UserModel.updateLastSeen(userId);
          logger.debug('Updated last_seen for user', { userId });
        } catch (err) {
          logger.error('Failed to update last_seen', { error: err.message });
        }
      }
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
