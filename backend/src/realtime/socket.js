const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const config = require('../config');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Conversation = require('../models/Conversation');
const Poll = require('../models/Poll');
const communicationService = require('../services/communicationService');
const pollService = require('../services/pollService');
const logger = require('../config/logger');

const attachSocket = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: true,
      credentials: true,
    },
    path: '/socket.io',
  });

  communicationService.setSocketEmitter(({ conversationId, event, payload, participants }) => {
    if (conversationId) {
      io.to(`conv:${conversationId}`).emit(event, payload);
    }
    if (event === 'message' && Array.isArray(participants)) {
      const senderId = payload?.senderId ? String(payload.senderId) : null;
      const senderType = payload?.senderType || null;
      for (const p of participants) {
        if (!p?.userId || p.leftAt) continue;
        if (senderId && String(p.userId) === senderId && p.userType === senderType) continue;
        if (p.muted) continue;
        io.to(`user:${p.userType}:${p.userId}`).emit('notification', {
          type: 'chat_message',
          conversationId: String(conversationId),
          message: payload,
        });
      }
    }
  });

  pollService.setPollEmitter((pollId, event, payload) => {
    io.to(`poll:${pollId}`).emit(event, payload);
  });

  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.query?.token ||
        (socket.handshake.headers.authorization || '').replace(/^Bearer\s+/i, '');
      if (!token) return next(new Error('Unauthorized'));
      const decoded = jwt.verify(token, config.jwt.secret);
      let user = null;
      if (decoded.userType === 'teacher') {
        user = await Teacher.findById(decoded.id);
      } else if (decoded.userType === 'student') {
        user = await Student.findById(decoded.id);
      }
      if (!user) return next(new Error('Unauthorized'));
      socket.user = user;
      socket.userType = decoded.userType === 'student' ? 'student' : 'teacher';
      socket.userId = user._id;
      return next();
    } catch (e) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', async (socket) => {
    const userRoom = `user:${socket.userType}:${socket.userId}`;
    socket.join(userRoom);

    try {
      const presence = await communicationService.setPresence(socket.userId, socket.userType, {
        socketId: socket.id,
      });
      io.emit('user-online', presence);
    } catch (e) {
      logger.warn(`Presence online failed: ${e.message}`);
    }

    socket.on('join-room', async (conversationId, ack) => {
      try {
        const conv = await Conversation.findById(conversationId);
        if (!conv) {
          if (typeof ack === 'function') ack({ ok: false });
          return;
        }
        const ok = communicationService.isParticipant(conv, socket.userId, socket.userType);
        if (!ok) {
          if (typeof ack === 'function') ack({ ok: false });
          return;
        }
        socket.join(`conv:${conversationId}`);
        if (typeof ack === 'function') ack({ ok: true });
      } catch (_) {
        if (typeof ack === 'function') ack({ ok: false });
      }
    });

    socket.on('leave-room', (conversationId) => {
      socket.leave(`conv:${conversationId}`);
    });

    socket.on('join-poll', async (pollId, ack) => {
      try {
        const poll = await Poll.findById(pollId);
        if (!poll) {
          if (typeof ack === 'function') ack({ ok: false });
          return;
        }
        socket.join(`poll:${pollId}`);
        if (typeof ack === 'function') ack({ ok: true });
      } catch (_) {
        if (typeof ack === 'function') ack({ ok: false });
      }
    });

    socket.on('leave-poll', (pollId) => {
      socket.leave(`poll:${pollId}`);
    });

    socket.on('typing', ({ conversationId }) => {
      if (!conversationId) return;
      socket.to(`conv:${conversationId}`).emit('typing', {
        conversationId: String(conversationId),
        userId: String(socket.userId),
        userType: socket.userType,
        name: String(socket.user.name || '').trim().split(/\s+/)[0] || socket.user.name,
      });
    });

    socket.on('stop-typing', ({ conversationId }) => {
      if (!conversationId) return;
      socket.to(`conv:${conversationId}`).emit('stop-typing', {
        conversationId: String(conversationId),
        userId: String(socket.userId),
        userType: socket.userType,
      });
    });

    socket.on('disconnect', async () => {
      try {
        const presence = await communicationService.setPresence(socket.userId, socket.userType, {
          socketId: socket.id,
          removeSocket: true,
        });
        if (presence.status === 'offline') {
          io.emit('user-offline', presence);
        }
      } catch (e) {
        logger.warn(`Presence offline failed: ${e.message}`);
      }
    });
  });

  logger.info('Socket.io attached for communications and polls');
  return io;
};

module.exports = { attachSocket };
