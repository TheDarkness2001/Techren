const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendList, sendError } = require('../utils/apiResponse');
const communicationService = require('../services/communicationService');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.listConversations = asyncHandler(async (req, res) => {
  try {
    const items = await communicationService.listConversations(req);
    sendList(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.getConversation = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.getConversation(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.listMessages = asyncHandler(async (req, res) => {
  try {
    const items = await communicationService.listMessages(req, req.params.id);
    sendList(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.sendMessage = asyncHandler(async (req, res) => {
  try {
    let attachments = [];
    if (req.file) {
      const mime = req.file.mimetype || '';
      let kind = 'file';
      if (mime.startsWith('image/')) kind = 'image';
      else if (mime.startsWith('audio/')) kind = 'audio';
      else if (mime.startsWith('video/')) kind = 'video';
      attachments = [
        {
          kind,
          url: `/api/v1/uploads/communications/${req.file.filename}`,
          name: req.file.originalname,
          mime,
          size: req.file.size,
          durationSec: Number(req.body.durationSec) || 0,
        },
      ];
    } else if (req.body.attachments) {
      try {
        attachments = typeof req.body.attachments === 'string'
          ? JSON.parse(req.body.attachments)
          : req.body.attachments;
      } catch (_) {
        attachments = [];
      }
    }
    const item = await communicationService.sendMessage(req, req.params.id, {
      body: req.body.body,
      attachments,
      replyToId: req.body.replyToId,
      clientId: req.body.clientId,
      mentions: req.body.mentions
        ? typeof req.body.mentions === 'string'
          ? JSON.parse(req.body.mentions)
          : req.body.mentions
        : undefined,
      forwardFromId: req.body.forwardFromId,
      scheduledAt: req.body.scheduledAt,
      pollId: req.body.pollId,
      messageType: req.body.messageType,
      callPayload: req.body.callPayload
        ? typeof req.body.callPayload === 'string'
          ? JSON.parse(req.body.callPayload)
          : req.body.callPayload
        : undefined,
    });
    sendSuccess(res, item, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.markRead = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.markRead(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.createPrivate = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.findOrCreatePrivate(req, {
      targetUserId: req.body.targetUserId || req.body.userId,
      targetUserType: req.body.targetUserType || req.body.userType,
    });
    sendSuccess(res, item, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.createSupport = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.createSupport(req, { body: req.body.body });
    sendSuccess(res, item, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.createBroadcast = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.createBroadcast(req, {
      title: req.body.title,
      body: req.body.body,
      allowReplies: req.body.allowReplies,
      branchId: req.body.branchId,
    });
    sendSuccess(res, item, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateMessage = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.updateMessage(req, req.params.messageId, {
      body: req.body.body,
      deleted: req.body.deleted === true || req.body.delete === true,
    });
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.togglePinMute = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.togglePinMute(req, req.params.id, {
      pinned: req.body.pinned,
      muted: req.body.muted,
      archived: req.body.archived,
    });
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.reactToMessage = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await communicationService.reactToMessage(req, req.params.messageId, req.body.emoji));
  } catch (e) {
    handle(res, e);
  }
});

exports.starMessage = asyncHandler(async (req, res) => {
  try {
    sendSuccess(
      res,
      await communicationService.starMessage(req, req.params.messageId, req.body.starred !== false)
    );
  } catch (e) {
    handle(res, e);
  }
});

exports.pinMessage = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await communicationService.pinMessage(req, req.params.id, req.body.messageId || null));
  } catch (e) {
    handle(res, e);
  }
});

exports.forwardMessage = asyncHandler(async (req, res) => {
  try {
    sendSuccess(
      res,
      await communicationService.forwardMessage(req, req.params.messageId, req.body.conversationId),
      201
    );
  } catch (e) {
    handle(res, e);
  }
});

exports.searchMessages = asyncHandler(async (req, res) => {
  try {
    sendList(res, await communicationService.searchMessages(req));
  } catch (e) {
    handle(res, e);
  }
});

exports.createSubjectRoom = asyncHandler(async (req, res) => {
  try {
    sendSuccess(
      res,
      await communicationService.createSubjectRoom(req, {
        subjectId: req.body.subjectId,
        title: req.body.title,
      }),
      201
    );
  } catch (e) {
    handle(res, e);
  }
});

exports.listSubjectOptions = asyncHandler(async (req, res) => {
  try {
    sendList(res, await communicationService.listSubjectOptions(req));
  } catch (e) {
    handle(res, e);
  }
});

exports.directory = asyncHandler(async (req, res) => {
  try {
    const items = await communicationService.directory(req);
    sendList(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.unreadTotal = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.unreadTotal(req);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.getPresence = asyncHandler(async (req, res) => {
  try {
    const item = await communicationService.getPresence(req.params.userId, req.params.userType);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.moderationInbox = asyncHandler(async (req, res) => {
  try {
    sendList(res, await communicationService.moderationInbox(req));
  } catch (e) {
    handle(res, e);
  }
});

exports.moderateMessage = asyncHandler(async (req, res) => {
  try {
    sendSuccess(
      res,
      await communicationService.moderateMessage(req, req.params.messageId, {
        deleted: req.body.deleted === true || req.body.deleted === 'true',
        note: req.body.note,
      })
    );
  } catch (e) {
    handle(res, e);
  }
});

exports.createChatPoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await communicationService.createChatPoll(req, req.params.id, req.body), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.signalCall = asyncHandler(async (req, res) => {
  try {
    sendSuccess(
      res,
      await communicationService.signalCall(req, req.params.id, {
        action: req.body.action || 'invite',
        media: req.body.media || 'audio',
      }),
      201
    );
  } catch (e) {
    handle(res, e);
  }
});
