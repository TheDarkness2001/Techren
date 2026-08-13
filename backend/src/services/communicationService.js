const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const UserPresence = require('../models/UserPresence');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Parent = require('../models/Parent');
const ExamGroup = require('../models/ExamGroup');
const notificationService = require('./notificationService');
const { hasPermission, isPrivilegedStaff } = require('../middleware/auth');

const badRequest = (msg) => Object.assign(new Error(msg), { statusCode: 400, code: 'BAD_REQUEST' });
const notFound = (msg) => Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });
const forbidden = (msg) => Object.assign(new Error(msg), { statusCode: 403, code: 'FORBIDDEN' });

const actorKey = (req) => ({
  userId: req.user._id,
  userType:
    req.userType === 'student' ? 'student' : req.userType === 'parent' ? 'parent' : 'teacher',
});

const isParticipant = (conversation, userId, userType) =>
  (conversation.participants || []).some(
    (p) =>
      String(p.userId) === String(userId) &&
      p.userType === userType &&
      !p.leftAt
  );

const getParticipant = (conversation, userId, userType) =>
  (conversation.participants || []).find(
    (p) => String(p.userId) === String(userId) && p.userType === userType && !p.leftAt
  );

const privateKeyFor = (a, b) => {
  const parts = [
    `${a.userType}:${a.userId}`,
    `${b.userType}:${b.userId}`,
  ].sort();
  return parts.join('|');
};

const formatAttachment = (a) => ({
  kind: a.kind,
  url: a.url,
  name: a.name || '',
  mime: a.mime || '',
  size: a.size || 0,
  durationSec: a.durationSec || 0,
});

const firstNameOf = (name) => {
  const n = String(name || '').trim();
  if (!n) return '';
  return n.split(/\s+/)[0];
};

const loadUserProfiles = async (pairs = []) => {
  const teacherIds = [
    ...new Set(pairs.filter((p) => p.userType === 'teacher' && p.userId).map((p) => String(p.userId))),
  ];
  const studentIds = [
    ...new Set(pairs.filter((p) => p.userType === 'student' && p.userId).map((p) => String(p.userId))),
  ];
  const parentIds = [
    ...new Set(pairs.filter((p) => p.userType === 'parent' && p.userId).map((p) => String(p.userId))),
  ];
  const [teachers, students, parents] = await Promise.all([
    teacherIds.length
      ? Teacher.find({ _id: { $in: teacherIds } }).select('name profileImage').lean()
      : [],
    studentIds.length
      ? Student.find({ _id: { $in: studentIds } }).select('name profileImage').lean()
      : [],
    parentIds.length
      ? Parent.find({ _id: { $in: parentIds } }).select('name relation').lean()
      : [],
  ]);
  const map = new Map();
  for (const t of teachers) {
    map.set(`teacher:${t._id}`, {
      name: t.name || '',
      firstName: firstNameOf(t.name),
      profileImage: t.profileImage || null,
    });
  }
  for (const s of students) {
    map.set(`student:${s._id}`, {
      name: s.name || '',
      firstName: firstNameOf(s.name),
      profileImage: s.profileImage || null,
    });
  }
  for (const p of parents) {
    const relation = p.relation || 'guardian';
    const label = `${p.name || 'Parent'} (${relation})`;
    map.set(`parent:${p._id}`, {
      name: label,
      firstName: firstNameOf(p.name) || 'Parent',
      profileImage: null,
    });
  }
  return map;
};

const applySenderProfile = (formatted, profile) => ({
  ...formatted,
  senderName: profile?.name || formatted.senderName || '',
  senderFirstName: profile?.firstName || formatted.senderFirstName || firstNameOf(profile?.name || ''),
  senderProfileImage: profile?.profileImage || formatted.senderProfileImage || null,
});

const formatMessage = (doc, viewer = null) => {
  const starred =
    viewer &&
    (doc.starredBy || []).some(
      (s) => String(s.userId) === String(viewer.userId) && s.userType === viewer.userType
    );
  const reactionCounts = {};
  for (const r of doc.reactions || []) {
    reactionCounts[r.emoji] = (reactionCounts[r.emoji] || 0) + 1;
  }
  return {
    id: String(doc._id),
    conversationId: String(doc.conversationId),
    senderId: String(doc.senderId),
    senderType: doc.senderType,
    senderName: '',
    senderFirstName: '',
    senderProfileImage: null,
    body: doc.deletedAt ? '' : doc.body || '',
    attachments: doc.deletedAt ? [] : (doc.attachments || []).map(formatAttachment),
    replyToId: doc.replyToId ? String(doc.replyToId) : null,
    forwardFromId: doc.forwardFromId ? String(doc.forwardFromId) : null,
    reactions: reactionCounts,
    myReactions: viewer
      ? (doc.reactions || [])
          .filter((r) => String(r.userId) === String(viewer.userId) && r.userType === viewer.userType)
          .map((r) => r.emoji)
      : [],
    mentions: (doc.mentions || []).map((m) => ({
      userId: String(m.userId),
      userType: m.userType,
      name: m.name || '',
    })),
    starred: !!starred,
    status: doc.deletedAt ? 'deleted' : doc.status,
    messageType: doc.messageType || 'text',
    pollId: doc.pollId ? String(doc.pollId) : null,
    scheduledAt: doc.scheduledAt || null,
    callPayload: doc.callPayload || null,
    editedAt: doc.editedAt,
    deletedAt: doc.deletedAt,
    clientId: doc.clientId || null,
    moderationNote: doc.moderationNote || '',
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

const enrichMessage = async (doc, viewer = null) => {
  const formatted = formatMessage(doc, viewer);
  const profiles = await loadUserProfiles([
    { userId: formatted.senderId, userType: formatted.senderType },
  ]);
  return applySenderProfile(
    formatted,
    profiles.get(`${formatted.senderType}:${formatted.senderId}`)
  );
};

const enrichMessages = async (docs, viewer = null) => {
  const formatted = docs.map((d) => formatMessage(d, viewer));
  const profiles = await loadUserProfiles(
    formatted.map((f) => ({ userId: f.senderId, userType: f.senderType }))
  );
  return formatted.map((f) =>
    applySenderProfile(f, profiles.get(`${f.senderType}:${f.senderId}`))
  );
};

const unreadCountFor = (conversation, userId, userType) => {
  const p = getParticipant(conversation, userId, userType);
  if (!p) return 0;
  // Approximate: 1 if last message after lastReadAt (exact count computed in list)
  if (!conversation.lastMessageAt) return 0;
  if (!p.lastReadAt) return conversation.lastMessageAt ? 1 : 0;
  return conversation.lastMessageAt > p.lastReadAt ? 1 : 0;
};

const formatConversation = (doc, { userId, userType, unreadCount = 0 } = {}) => {
  const p = userId ? getParticipant(doc, userId, userType) : null;
  return {
    id: String(doc._id),
    type: doc.type,
    title: doc.title || '',
    description: doc.description || '',
    avatarUrl: doc.avatarUrl || null,
    examGroupId: doc.examGroupId ? String(doc.examGroupId) : null,
    subjectId: doc.subjectId ? String(doc.subjectId) : null,
    branchId: doc.branchId ? String(doc.branchId) : null,
    allowReplies: doc.allowReplies !== false,
    archived: doc.archived === true,
    pinned: p?.pinned === true,
    muted: p?.muted === true,
    lastMessageAt: doc.lastMessageAt,
    lastMessagePreview: doc.lastMessagePreview || '',
    participantCount: (doc.participants || []).filter((x) => !x.leftAt).length,
    participants: (doc.participants || [])
      .filter((x) => !x.leftAt)
      .map((x) => ({
        userId: String(x.userId),
        userType: x.userType,
        role: x.role,
        lastReadAt: x.lastReadAt,
      })),
    unreadCount,
    pinnedMessageId: doc.pinnedMessageId ? String(doc.pinnedMessageId) : null,
    peerUserId: null,
    peerUserType: null,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

const assertCanUse = async (req) => {
  if (req.userType === 'student') return;
  // Parents may only use communications via dedicated excuse helper (not general chat APIs).
  if (req.userType === 'parent') throw forbidden('Parents cannot open the chat directory');
  if (req.user.role === 'founder') return;
  const ok = await hasPermission(req, 'canUseCommunications');
  if (!ok) throw forbidden('Missing permission: canUseCommunications');
};

const assertCanBroadcast = async (req) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (req.user.role === 'founder') return;
  const ok = await hasPermission(req, 'canBroadcast');
  if (!ok) throw forbidden('Missing permission: canBroadcast');
};

const resolvePrivatePeer = async (conversation, viewer) => {
  if (conversation.type !== 'private') {
    return {
      title: conversation.title || 'Chat',
      avatarUrl: conversation.avatarUrl || null,
      peerUserId: null,
      peerUserType: null,
    };
  }
  const other = (conversation.participants || []).find(
    (p) => !(String(p.userId) === String(viewer.userId) && p.userType === viewer.userType)
  );
  if (!other) {
    return {
      title: conversation.title || 'Chat',
      avatarUrl: conversation.avatarUrl || null,
      peerUserId: null,
      peerUserType: null,
    };
  }
  let fullName = 'Chat';
  let avatarUrl = null;
  if (other.userType === 'teacher') {
    const u = await Teacher.findById(other.userId).select('name profileImage').lean();
    fullName = u?.name || 'Staff';
    avatarUrl = u?.profileImage || null;
  } else if (other.userType === 'parent') {
    const u = await Parent.findById(other.userId).select('name relation').lean();
    fullName = u ? `${u.name || 'Parent'} (${u.relation || 'guardian'})` : 'Parent';
  } else {
    const u = await Student.findById(other.userId).select('name profileImage').lean();
    fullName = u?.name || 'Student';
    avatarUrl = u?.profileImage || null;
  }
  return {
    title: firstNameOf(fullName) || fullName,
    avatarUrl,
    peerUserId: String(other.userId),
    peerUserType: other.userType,
  };
};

const resolveDisplayTitle = async (conversation, viewer) => {
  const peer = await resolvePrivatePeer(conversation, viewer);
  return peer.title;
};

const listConversations = async (req) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const filter = {
    participants: { $elemMatch: { userId, userType, leftAt: null } },
  };
  if (req.query.archived === 'true' || req.query.archived === '1') {
    filter.archived = true;
  } else {
    filter.archived = { $ne: true };
  }
  if (req.query.type) filter.type = req.query.type;
  if (req.query.pinned === 'true') {
    filter.participants = { $elemMatch: { userId, userType, leftAt: null, pinned: true } };
  }

  const items = await Conversation.find(filter).sort({ lastMessageAt: -1, updatedAt: -1 }).limit(100);
  const result = [];
  for (const doc of items) {
    const p = getParticipant(doc, userId, userType);
    const since = p?.lastReadAt || new Date(0);
    const unreadCount = await Message.countDocuments({
      conversationId: doc._id,
      createdAt: { $gt: since },
      deletedAt: null,
      // Messages not sent by this viewer (match both id + type).
      $nor: [{ senderId: userId, senderType: userType }],
    });
    const formatted = formatConversation(doc, { userId, userType, unreadCount });
    const peer = await resolvePrivatePeer(doc, { userId, userType });
    formatted.title = peer.title;
    if (peer.avatarUrl) formatted.avatarUrl = peer.avatarUrl;
    formatted.peerUserId = peer.peerUserId;
    formatted.peerUserType = peer.peerUserType;
    result.push(formatted);
  }
  return result;
};

const getConversation = async (req, id) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const doc = await Conversation.findById(id);
  if (!doc) throw notFound('Conversation not found');
  if (!isParticipant(doc, userId, userType) && !(await hasPermission(req, 'canModerateCommunications'))) {
    throw forbidden('Not a participant');
  }
  const p = getParticipant(doc, userId, userType);
  const since = p?.lastReadAt || new Date(0);
  const unreadCount = await Message.countDocuments({
    conversationId: doc._id,
    createdAt: { $gt: since },
    deletedAt: null,
    $nor: [{ senderId: userId, senderType: userType }],
  });
  const formatted = formatConversation(doc, { userId, userType, unreadCount });
  const peer = await resolvePrivatePeer(doc, { userId, userType });
  formatted.title = peer.title;
  if (peer.avatarUrl) formatted.avatarUrl = peer.avatarUrl;
  formatted.peerUserId = peer.peerUserId;
  formatted.peerUserType = peer.peerUserType;
  return formatted;
};

const listMessages = async (req, conversationId) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv) throw notFound('Conversation not found');
  if (!isParticipant(conv, userId, userType)) throw forbidden('Not a participant');

  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const filter = {
    conversationId,
    deletedAt: null,
    $or: [
      { status: { $ne: 'scheduled' } },
      { status: 'scheduled', senderId: userId, senderType: userType },
    ],
  };
  if (req.query.before) {
    filter.createdAt = { $lt: new Date(req.query.before) };
  }
  if (req.query.q) {
    filter.body = { $regex: String(req.query.q).trim(), $options: 'i' };
  }
  if (req.query.files === '1' || req.query.files === 'true') {
    filter['attachments.0'] = { $exists: true };
  }

  const items = await Message.find(filter).sort({ createdAt: -1 }).limit(limit);
  return enrichMessages(items.reverse(), { userId, userType });
};

const notifyParticipants = async (conversation, message, sender) => {
  const preview = (message.body || '').slice(0, 120) || 'New attachment';
  const profiles = await loadUserProfiles([{ userId: sender.userId, userType: sender.userType }]);
  const senderProfile = profiles.get(`${sender.userType}:${sender.userId}`);
  const title =
    senderProfile?.firstName ||
    firstNameOf(senderProfile?.name) ||
    conversation.title ||
    'New message';
  const body = preview || 'New message';
  for (const p of conversation.participants || []) {
    if (p.leftAt) continue;
    if (String(p.userId) === String(sender.userId) && p.userType === sender.userType) continue;
    if (p.muted) continue;
    try {
      await notificationService.createInAppNotification({
        userId: p.userId,
        userType: p.userType,
        studentId: p.userType === 'student' ? p.userId : undefined,
        title,
        body,
        eventType: 'chat_message',
        data: {
          conversationId: String(conversation._id),
          messageId: String(message._id),
          senderId: String(sender.userId),
          senderType: sender.userType,
          senderFirstName: senderProfile?.firstName || '',
          senderProfileImage: senderProfile?.profileImage || null,
          screen: 'messages',
          actions: 'chat',
          title,
          body,
        },
        push: true,
      });
    } catch (_) {
      /* non-fatal */
    }
  }
};

let socketEmit = null;
const setSocketEmitter = (fn) => {
  socketEmit = fn;
};

const emitToConversation = (conversationId, event, payload, participants) => {
  if (typeof socketEmit === 'function') {
    socketEmit({
      conversationId: String(conversationId),
      event,
      payload,
      participants,
    });
  }
};

const sendMessage = async (
  req,
  conversationId,
  { body, attachments, replyToId, clientId, mentions, forwardFromId, scheduledAt, pollId, messageType, callPayload }
) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv) throw notFound('Conversation not found');
  if (!isParticipant(conv, userId, userType)) throw forbidden('Not a participant');
  if (conv.type === 'broadcast' && !conv.allowReplies) {
    const canPost =
      req.userType === 'teacher' &&
      (req.user.role === 'founder' ||
        (await hasPermission(req, 'canBroadcast')) ||
        (await hasPermission(req, 'canModerateCommunications')));
    if (!canPost) throw forbidden('Replies disabled on this broadcast');
  }

  if (clientId) {
    const existing = await Message.findOne({ conversationId, clientId });
    if (existing) return enrichMessage(existing, { userId, userType });
  }

  const text = String(body || '').trim();
  const files = Array.isArray(attachments) ? attachments : [];
  const type = messageType || (pollId ? 'poll' : callPayload ? 'call' : 'text');
  if (!text && files.length === 0 && !pollId && type !== 'call') {
    throw badRequest('Message body or attachment required');
  }

  let mentionList = Array.isArray(mentions) ? mentions : [];
  if (!mentionList.length && text) {
    mentionList = await resolveMentionsFromText(text, conv);
  }

  const when = scheduledAt ? new Date(scheduledAt) : null;
  const isScheduled = when && when.getTime() > Date.now() + 5000;

  const message = await Message.create({
    conversationId,
    senderId: userId,
    senderType: userType,
    body: text,
    attachments: files,
    replyToId: replyToId || null,
    forwardFromId: forwardFromId || null,
    mentions: mentionList,
    clientId: clientId || null,
    pollId: pollId || null,
    messageType: type,
    callPayload: callPayload || undefined,
    scheduledAt: isScheduled ? when : null,
    status: isScheduled ? 'scheduled' : 'sent',
  });

  if (isScheduled) {
    return enrichMessage(message, { userId, userType });
  }

  const preview =
    type === 'poll'
      ? '📊 Poll'
      : type === 'call'
        ? '📞 Call'
        : text || (files[0]?.kind === 'audio' ? '🎤 Voice note' : files[0]?.name ? `📎 ${files[0].name}` : 'Attachment');
  conv.lastMessageAt = message.createdAt;
  conv.lastMessagePreview = preview.slice(0, 200);
  const p = getParticipant(conv, userId, userType);
  if (p) p.lastReadAt = new Date();
  await conv.save();

  const formatted = await enrichMessage(message, { userId, userType });
  emitToConversation(conversationId, 'message', formatted, conv.participants);
  if (type === 'call') {
    emitToConversation(conversationId, 'call-signal', formatted, conv.participants);
  }
  await notifyParticipants(conv, message, { userId, userType });
  for (const m of mentionList) {
    try {
      await notificationService.createInAppNotification({
        userId: m.userId,
        userType: m.userType,
        studentId: m.userType === 'student' ? m.userId : undefined,
        title: `Mentioned in ${conv.title || 'chat'}`,
        body: text.slice(0, 120),
        eventType: 'chat_mention',
        data: { conversationId: String(conv._id), messageId: String(message._id) },
      });
    } catch (_) {
      /* non-fatal */
    }
  }
  return formatted;
};

const resolveMentionsFromText = async (text, conversation) => {
  const tags = [...text.matchAll(/@([A-Za-z0-9._-]+)/g)].map((m) => m[1].toLowerCase());
  if (!tags.length) return [];
  const participants = (conversation.participants || []).filter((p) => !p.leftAt);
  const teacherIds = participants.filter((p) => p.userType === 'teacher').map((p) => p.userId);
  const studentIds = participants.filter((p) => p.userType === 'student').map((p) => p.userId);
  const [teachers, students] = await Promise.all([
    Teacher.find({ _id: { $in: teacherIds } }).select('name'),
    Student.find({ _id: { $in: studentIds } }).select('name'),
  ]);
  const people = [
    ...teachers.map((t) => ({ userId: t._id, userType: 'teacher', name: t.name })),
    ...students.map((s) => ({ userId: s._id, userType: 'student', name: s.name })),
  ];
  const found = [];
  for (const tag of tags) {
    const match = people.find((p) => {
      const name = String(p.name || '').toLowerCase();
      const first = name.split(/\s+/)[0];
      return name === tag || first === tag || name.replace(/\s+/g, '') === tag;
    });
    if (match && !found.some((f) => String(f.userId) === String(match.userId))) {
      found.push(match);
    }
  }
  return found;
};

const markRead = async (req, conversationId) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv) throw notFound('Conversation not found');
  if (!isParticipant(conv, userId, userType)) throw forbidden('Not a participant');

  const p = getParticipant(conv, userId, userType);
  if (p) {
    // Always clear through the latest message (avoids clock/race leaving a sticky unread).
    const latestMs = Math.max(Date.now(), conv.lastMessageAt ? new Date(conv.lastMessageAt).getTime() : 0);
    p.lastReadAt = new Date(latestMs + 1);
  }
  await conv.save();

  await Message.updateMany(
    {
      conversationId,
      status: { $in: ['sent', 'delivered'] },
      $nor: [{ senderId: userId, senderType: userType }],
    },
    { $set: { status: 'seen' } }
  );

  emitToConversation(conversationId, 'message-seen', {
    conversationId: String(conversationId),
    userId: String(userId),
    userType,
    at: new Date().toISOString(),
  });

  return { ok: true };
};

const findOrCreatePrivate = async (req, { targetUserId, targetUserType }) => {
  await assertCanUse(req);
  const me = actorKey(req);
  const otherType = targetUserType === 'student' ? 'student' : 'teacher';
  if (!targetUserId) throw badRequest('targetUserId required');
  if (String(targetUserId) === String(me.userId) && otherType === me.userType) {
    throw badRequest('Cannot chat with yourself');
  }

  if (otherType === 'teacher') {
    const t = await Teacher.findById(targetUserId);
    if (!t) throw notFound('User not found');
  } else {
    const s = await Student.findById(targetUserId);
    if (!s) throw notFound('User not found');
  }

  // Permission: teachers can DM; students only teachers in their groups (or support uses other endpoint)
  if (me.userType === 'student' && otherType === 'student') {
    throw forbidden('Students cannot DM other students');
  }
  if (me.userType === 'student' && otherType === 'teacher') {
    const groups = await ExamGroup.find({ students: me.userId, teachers: targetUserId }).limit(1);
    const staff = await Teacher.findById(targetUserId).select('role');
    const privileged = ['founder', 'admin', 'manager'].includes(staff?.role);
    if (!groups.length && !privileged) throw forbidden('You can only message your teachers or administration');
  }

  const key = privateKeyFor(me, { userId: targetUserId, userType: otherType });
  let conv = await Conversation.findOne({ privateKey: key, type: 'private' });
  if (!conv) {
    conv = await Conversation.create({
      type: 'private',
      privateKey: key,
      title: '',
      allowReplies: true,
      createdBy: me.userId,
      createdByType: me.userType,
      participants: [
        { userId: me.userId, userType: me.userType, role: 'member' },
        { userId: targetUserId, userType: otherType, role: 'member' },
      ],
    });
  }
  return getConversation(req, conv._id);
};

const createSupport = async (req, { body: firstMessage } = {}) => {
  await assertCanUse(req);
  if (req.userType !== 'student') throw badRequest('Support chat is for students');
  const me = actorKey(req);

  let conv = await Conversation.findOne({
    type: 'support',
    participants: { $elemMatch: { userId: me.userId, userType: 'student', leftAt: null } },
    archived: { $ne: true },
  });

  if (!conv) {
    const staff = await Teacher.find({
      role: { $in: ['founder', 'admin', 'manager'] },
      status: { $ne: 'inactive' },
    }).select('_id');

    const participants = [
      { userId: me.userId, userType: 'student', role: 'member' },
      ...staff.map((t) => ({ userId: t._id, userType: 'teacher', role: 'admin' })),
    ];

    conv = await Conversation.create({
      type: 'support',
      title: 'Administration Support',
      allowReplies: true,
      createdBy: me.userId,
      createdByType: 'student',
      branchId: req.user.branchId || null,
      participants,
    });
  }

  if (firstMessage && String(firstMessage).trim()) {
    req.params = { ...(req.params || {}), id: String(conv._id) };
    await sendMessage(req, conv._id, { body: firstMessage });
  }
  return getConversation(req, conv._id);
};

const createBroadcast = async (req, { title, body, allowReplies = false, branchId }) => {
  await assertCanBroadcast(req);
  const me = actorKey(req);
  const studentFilter = { status: { $ne: 'inactive' } };
  if (branchId) studentFilter.branchId = branchId;
  else if (req.user.branchId && req.user.role !== 'founder') studentFilter.branchId = req.user.branchId;

  const students = await Student.find(studentFilter).select('_id');
  const participants = [
    { userId: me.userId, userType: 'teacher', role: 'owner' },
    ...students.map((s) => ({ userId: s._id, userType: 'student', role: 'member' })),
  ];

  const conv = await Conversation.create({
    type: 'broadcast',
    title: title || 'Announcement',
    description: '',
    allowReplies: allowReplies === true,
    createdBy: me.userId,
    createdByType: 'teacher',
    branchId: branchId || req.user.branchId || null,
    participants,
  });

  if (body && String(body).trim()) {
    await sendMessage(req, conv._id, { body });
  }
  return getConversation(req, conv._id);
};

const syncGroupConversation = async (examGroup) => {
  if (!examGroup?._id) return null;
  const group =
    examGroup.students && examGroup.teachers
      ? examGroup
      : await ExamGroup.findById(examGroup._id || examGroup).populate('subject', 'name');

  if (!group) return null;

  let conv = await Conversation.findOne({ type: 'group', examGroupId: group._id });
  const studentIds = (group.students || []).map((s) => (s._id ? s._id : s));
  const teacherIds = (group.teachers || []).map((t) => (t._id ? t._id : t));

  const participants = [
    ...teacherIds.map((id) => ({ userId: id, userType: 'teacher', role: 'admin' })),
    ...studentIds.map((id) => ({ userId: id, userType: 'student', role: 'member' })),
  ];

  const title = group.groupName || group.subject?.name || 'Class chat';

  if (!conv) {
    conv = await Conversation.create({
      type: 'group',
      title,
      examGroupId: group._id,
      subjectId: group.subject?._id || group.subject || null,
      branchId: group.branchId || null,
      allowReplies: true,
      participants,
    });
  } else {
    conv.title = title;
    conv.participants = participants;
    conv.subjectId = group.subject?._id || group.subject || conv.subjectId;
    await conv.save();
  }
  return conv;
};

const updateMessage = async (req, messageId, { body, deleted }) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const message = await Message.findById(messageId);
  if (!message) throw notFound('Message not found');
  const conv = await Conversation.findById(message.conversationId);
  if (!conv) throw notFound('Conversation not found');

  const isOwner = String(message.senderId) === String(userId) && message.senderType === userType;
  const canMod =
    req.user.role === 'founder' || (await hasPermission(req, 'canModerateCommunications'));
  if (!isOwner && !canMod) throw forbidden('Cannot modify this message');

  if (deleted) {
    message.deletedAt = new Date();
    message.status = 'deleted';
    message.body = '';
    message.attachments = [];
  } else if (body != null) {
    message.body = String(body).trim();
    message.status = 'edited';
    message.editedAt = new Date();
  }
  await message.save();
  const formatted = await enrichMessage(message, { userId, userType });
  emitToConversation(message.conversationId, 'message', formatted, conv.participants);
  return formatted;
};

const togglePinMute = async (req, conversationId, { pinned, muted, archived }) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv) throw notFound('Conversation not found');
  const p = getParticipant(conv, userId, userType);
  if (!p) throw forbidden('Not a participant');
  if (pinned !== undefined) p.pinned = !!pinned;
  if (muted !== undefined) p.muted = !!muted;
  if (archived !== undefined) conv.archived = !!archived;
  await conv.save();
  return getConversation(req, conversationId);
};

const reactToMessage = async (req, messageId, emoji) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const message = await Message.findById(messageId);
  if (!message || message.deletedAt) throw notFound('Message not found');
  const conv = await Conversation.findById(message.conversationId);
  if (!conv || !isParticipant(conv, userId, userType)) throw forbidden('Not a participant');
  const e = String(emoji || '').trim().slice(0, 16);
  if (!e) throw badRequest('Emoji required');

  const existingIdx = (message.reactions || []).findIndex(
    (r) => String(r.userId) === String(userId) && r.userType === userType && r.emoji === e
  );
  if (existingIdx >= 0) {
    message.reactions.splice(existingIdx, 1);
  } else {
    message.reactions = (message.reactions || []).filter(
      (r) => !(String(r.userId) === String(userId) && r.userType === userType && r.emoji === e)
    );
    message.reactions.push({ emoji: e, userId, userType });
  }
  await message.save();
  const formatted = await enrichMessage(message, { userId, userType });
  emitToConversation(message.conversationId, 'message', formatted, conv.participants);
  return formatted;
};

const starMessage = async (req, messageId, starred = true) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const message = await Message.findById(messageId);
  if (!message) throw notFound('Message not found');
  const conv = await Conversation.findById(message.conversationId);
  if (!conv || !isParticipant(conv, userId, userType)) throw forbidden('Not a participant');

  message.starredBy = (message.starredBy || []).filter(
    (s) => !(String(s.userId) === String(userId) && s.userType === userType)
  );
  if (starred) message.starredBy.push({ userId, userType });
  await message.save();
  return enrichMessage(message, { userId, userType });
};

const pinMessage = async (req, conversationId, messageId) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv || !isParticipant(conv, userId, userType)) throw forbidden('Not a participant');
  if (messageId) {
    const message = await Message.findById(messageId);
    if (!message || String(message.conversationId) !== String(conversationId)) {
      throw notFound('Message not found');
    }
    conv.pinnedMessageId = message._id;
  } else {
    conv.pinnedMessageId = null;
  }
  await conv.save();
  return getConversation(req, conversationId);
};

const forwardMessage = async (req, messageId, targetConversationId) => {
  await assertCanUse(req);
  const source = await Message.findById(messageId);
  if (!source || source.deletedAt) throw notFound('Message not found');
  const { userId, userType } = actorKey(req);
  const sourceConv = await Conversation.findById(source.conversationId);
  if (!sourceConv || !isParticipant(sourceConv, userId, userType)) throw forbidden('Not a participant');

  return sendMessage(req, targetConversationId, {
    body: source.body || '',
    attachments: source.attachments || [],
    forwardFromId: source._id,
  });
};

const searchMessages = async (req) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const q = String(req.query.q || '').trim();
  if (!q) return [];
  const limit = Math.min(Number(req.query.limit) || 40, 100);
  const myConvs = await Conversation.find({
    participants: { $elemMatch: { userId, userType, leftAt: null } },
    archived: { $ne: true },
  }).select('_id');
  const ids = myConvs.map((c) => c._id);
  const filter = {
    conversationId: { $in: ids },
    deletedAt: null,
    $or: [
      { body: { $regex: q, $options: 'i' } },
      { 'attachments.name': { $regex: q, $options: 'i' } },
    ],
  };
  if (req.query.files === '1' || req.query.files === 'true') {
    filter['attachments.0'] = { $exists: true };
  }
  const items = await Message.find(filter).sort({ createdAt: -1 }).limit(limit);
  return enrichMessages(items, { userId, userType });
};

const listSubjectOptions = async (req) => {
  await assertCanUse(req);
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  const role = req.user.role;
  const filter =
    role === 'founder' || role === 'admin' || role === 'manager' ? {} : { teachers: req.user._id };
  const groups = await ExamGroup.find(filter).populate('subject', 'name').select('subject');
  const map = new Map();
  for (const g of groups) {
    const s = g.subject;
    if (!s) continue;
    const id = String(s._id || s);
    if (!map.has(id)) {
      map.set(id, { id, name: s.name || 'Subject' });
    }
  }
  return [...map.values()].sort((a, b) => String(a.name).localeCompare(String(b.name)));
};

const createSubjectRoom = async (req, { subjectId, title }) => {
  await assertCanUse(req);
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (!subjectId) throw badRequest('subjectId required');
  const Subject = require('../models/Subject');
  const subject = await Subject.findById(subjectId);
  if (!subject) throw notFound('Subject not found');

  let conv = await Conversation.findOne({ type: 'subject', subjectId });
  const groups = await ExamGroup.find({ subject: subjectId }).select('students teachers branchId');
  const participantMap = new Map();
  const addP = (id, type, role = 'member') => {
    if (!id) return;
    const key = `${type}:${id}`;
    if (!participantMap.has(key)) {
      participantMap.set(key, { userId: id, userType: type, role });
    }
  };
  addP(req.user._id, 'teacher', 'admin');
  for (const g of groups) {
    for (const t of g.teachers || []) addP(t, 'teacher');
    for (const s of g.students || []) addP(s, 'student');
  }
  const participants = [...participantMap.values()];
  const roomTitle = title || `${subject.name} discussion`;

  if (!conv) {
    conv = await Conversation.create({
      type: 'subject',
      title: roomTitle,
      subjectId,
      branchId: subject.branchId || groups[0]?.branchId || req.user.branchId,
      participants,
      createdBy: req.user._id,
      createdByType: 'teacher',
      allowReplies: true,
    });
  } else {
    conv.title = roomTitle;
    conv.participants = participants;
    await conv.save();
  }
  return getConversation(req, conv._id);
};

const directory = async (req) => {
  await assertCanUse(req);
  const q = String(req.query.search || '').trim();
  const role = req.query.role;
  const limit = Math.min(Number(req.query.limit) || 40, 100);
  const results = [];

  if (req.userType === 'student') {
    const groups = await ExamGroup.find({ students: req.user._id }).select('teachers');
    const teacherIds = [...new Set(groups.flatMap((g) => (g.teachers || []).map(String)))];
    const teachers = await Teacher.find({
      _id: { $in: teacherIds },
      ...(q
        ? {
            $or: [
              { name: { $regex: q, $options: 'i' } },
              { email: { $regex: q, $options: 'i' } },
              { phone: { $regex: q, $options: 'i' } },
            ],
          }
        : {}),
    })
      .select('name email phone role profileImage')
      .limit(limit);
    for (const t of teachers) {
      results.push({
        id: String(t._id),
        userType: 'teacher',
        name: t.name,
        email: t.email,
        phone: t.phone,
        role: t.role,
        profileImage: t.profileImage,
      });
    }
    return results;
  }

  // Staff directory
  if (!role || role === 'teacher' || role === 'staff') {
    const teacherFilter = {
      status: { $ne: 'inactive' },
      ...(q
        ? {
            $or: [
              { name: { $regex: q, $options: 'i' } },
              { email: { $regex: q, $options: 'i' } },
              { phone: { $regex: q, $options: 'i' } },
            ],
          }
        : {}),
    };
    if (role === 'teacher') teacherFilter.role = 'teacher';
    const teachers = await Teacher.find(teacherFilter).select('name email phone role profileImage').limit(limit);
    for (const t of teachers) {
      results.push({
        id: String(t._id),
        userType: 'teacher',
        name: t.name,
        email: t.email,
        phone: t.phone,
        role: t.role,
        profileImage: t.profileImage,
      });
    }
  }

  if (!role || role === 'student') {
    const studentFilter = {
      status: { $ne: 'inactive' },
      ...(q
        ? {
            $or: [
              { name: { $regex: q, $options: 'i' } },
              { email: { $regex: q, $options: 'i' } },
              { phone: { $regex: q, $options: 'i' } },
            ],
          }
        : {}),
    };
    if (req.user.branchId && req.user.role !== 'founder') {
      studentFilter.branchId = req.user.branchId;
    }
    const students = await Student.find(studentFilter).select('name email phone profileImage').limit(limit);
    for (const s of students) {
      results.push({
        id: String(s._id),
        userType: 'student',
        name: s.name,
        email: s.email,
        phone: s.phone,
        role: 'student',
        profileImage: s.profileImage,
      });
    }
  }

  return results.slice(0, limit);
};

const setPresence = async (userId, userType, { status, socketId, removeSocket }) => {
  let doc = await UserPresence.findOne({ userId, userType });
  if (!doc) {
    doc = new UserPresence({ userId, userType, socketIds: [] });
  }
  if (socketId && !removeSocket) {
    const set = new Set(doc.socketIds || []);
    set.add(socketId);
    doc.socketIds = [...set];
    doc.status = 'online';
  }
  if (socketId && removeSocket) {
    doc.socketIds = (doc.socketIds || []).filter((id) => id !== socketId);
    if (doc.socketIds.length === 0) {
      doc.status = 'offline';
      doc.lastSeenAt = new Date();
    }
  }
  if (status === 'offline' && (!doc.socketIds || doc.socketIds.length === 0)) {
    doc.status = 'offline';
    doc.lastSeenAt = new Date();
  }
  await doc.save();
  return {
    userId: String(userId),
    userType,
    status: doc.status,
    lastSeenAt: doc.lastSeenAt,
  };
};

/** Clear all presence on server boot — in-memory sockets are gone after restart. */
const resetAllPresenceOffline = async () => {
  const result = await UserPresence.updateMany(
    {},
    { $set: { status: 'offline', socketIds: [], lastSeenAt: new Date() } }
  );
  return { updated: result.modifiedCount || 0 };
};

/** Drop socket IDs that are no longer connected to this process. */
const reconcileStalePresence = async (isAliveFn) => {
  if (typeof isAliveFn !== 'function') return { cleaned: 0 };
  const docs = await UserPresence.find({ status: 'online' }).limit(500);
  let cleaned = 0;
  for (const doc of docs) {
    const live = (doc.socketIds || []).filter((id) => isAliveFn(id));
    if (live.length === (doc.socketIds || []).length) continue;
    doc.socketIds = live;
    if (live.length === 0) {
      doc.status = 'offline';
      doc.lastSeenAt = new Date();
    }
    await doc.save();
    cleaned += 1;
  }
  return { cleaned };
};

const getPresence = async (userId, userType) => {
  const doc = await UserPresence.findOne({ userId, userType });
  if (!doc) {
    return {
      userId: String(userId),
      userType,
      status: 'offline',
      lastSeenAt: null,
    };
  }

  // Validate against live sockets when available (prevents false "online").
  try {
    const { isSocketAlive } = require('../realtime/socket');
    const ids = doc.socketIds || [];
    if (ids.length) {
      const live = ids.filter((id) => isSocketAlive(id));
      if (live.length !== ids.length) {
        doc.socketIds = live;
        if (live.length === 0) {
          doc.status = 'offline';
          doc.lastSeenAt = new Date();
        } else {
          doc.status = 'online';
        }
        await doc.save();
      }
    } else if (doc.status === 'online') {
      doc.status = 'offline';
      doc.lastSeenAt = new Date();
      await doc.save();
    }
  } catch (_) {
    /* socket module may not be ready during early boot */
  }

  return {
    userId: String(userId),
    userType,
    status: doc.status || 'offline',
    lastSeenAt: doc.lastSeenAt || null,
  };
};

const unreadTotal = async (req) => {
  await assertCanUse(req);
  const list = await listConversations(req);
  return { unread: list.reduce((n, c) => n + (c.unreadCount || 0), 0) };
};

const assertCanModerate = async (req) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (req.user.role === 'founder') return;
  if (!(await hasPermission(req, 'canModerateCommunications'))) {
    throw forbidden('Missing permission: canModerateCommunications');
  }
};

const flushScheduledMessages = async () => {
  const due = await Message.find({
    status: 'scheduled',
    scheduledAt: { $lte: new Date() },
    deletedAt: null,
  }).limit(100);
  let released = 0;
  for (const message of due) {
    const conv = await Conversation.findById(message.conversationId);
    if (!conv) {
      message.status = 'deleted';
      message.deletedAt = new Date();
      await message.save();
      continue;
    }
    message.status = 'sent';
    await message.save();
    const preview =
      message.messageType === 'poll'
        ? '📊 Poll'
        : message.body ||
          (message.attachments?.[0]?.kind === 'audio'
            ? '🎤 Voice note'
            : message.attachments?.[0]?.name
              ? `📎 ${message.attachments[0].name}`
              : 'Attachment');
    conv.lastMessageAt = new Date();
    conv.lastMessagePreview = preview.slice(0, 200);
    await conv.save();
    const formatted = await enrichMessage(message);
    emitToConversation(message.conversationId, 'message', formatted, conv.participants);
    await notifyParticipants(conv, message, {
      userId: message.senderId,
      userType: message.senderType,
    });
    released += 1;
  }
  return { released };
};

const moderationInbox = async (req) => {
  await assertCanModerate(req);
  const q = String(req.query.q || '').trim();
  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const filter = { deletedAt: null };
  if (q) filter.body = { $regex: q, $options: 'i' };
  if (req.query.conversationId) filter.conversationId = req.query.conversationId;
  const items = await Message.find(filter).sort({ createdAt: -1 }).limit(limit);
  return enrichMessages(items);
};

const moderateMessage = async (req, messageId, { deleted, note } = {}) => {
  await assertCanModerate(req);
  const message = await Message.findById(messageId);
  if (!message) throw notFound('Message not found');
  if (deleted) {
    message.deletedAt = new Date();
    message.status = 'deleted';
    message.body = '';
    message.attachments = [];
  }
  if (note !== undefined) message.moderationNote = String(note || '').slice(0, 500);
  await message.save();
  const conv = await Conversation.findById(message.conversationId);
  if (conv) {
    const formatted = await enrichMessage(message);
    emitToConversation(message.conversationId, 'message', formatted, conv.participants);
  }
  return enrichMessage(message);
};

const createChatPoll = async (req, conversationId, body = {}) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv || !isParticipant(conv, userId, userType)) throw forbidden('Not a participant');
  const pollService = require('./pollService');
  const poll = await pollService.createPoll(req, {
    ...body,
    conversationId,
    status: 'published',
    audience: { mode: 'everyone' },
  });
  return sendMessage(req, conversationId, {
    body: `📊 ${poll.question}`,
    pollId: poll.id,
    messageType: 'poll',
  });
};

const signalCall = async (req, conversationId, { action = 'invite', media = 'audio' } = {}) => {
  await assertCanUse(req);
  const { userId, userType } = actorKey(req);
  const conv = await Conversation.findById(conversationId);
  if (!conv || !isParticipant(conv, userId, userType)) throw forbidden('Not a participant');
  const roomId = `call_${conversationId}_${Date.now()}`;
  return sendMessage(req, conversationId, {
    body:
      action === 'invite'
        ? `📞 ${media === 'video' ? 'Video' : 'Audio'} call`
        : `📞 Call ${action}`,
    messageType: 'call',
    callPayload: { action, roomId, media },
  });
};

/**
 * Narrow parent→teacher DM used only for absence excuses.
 * Display identity uses parent name + relation (not the student's name).
 */
const sendParentAbsenceExcuse = async ({
  parent,
  teacherId,
  body,
}) => {
  if (!parent?._id) throw badRequest('Parent required');
  if (!teacherId) throw badRequest('Teacher required');
  const teacher = await Teacher.findById(teacherId).select('_id name');
  if (!teacher) throw notFound('Teacher not found');

  const me = { userId: parent._id, userType: 'parent' };
  const other = { userId: teacher._id, userType: 'teacher' };
  const key = privateKeyFor(me, other);

  let conv = await Conversation.findOne({ privateKey: key, type: 'private' });
  if (!conv) {
    conv = await Conversation.create({
      type: 'private',
      privateKey: key,
      title: '',
      allowReplies: true,
      createdBy: parent._id,
      createdByType: 'parent',
      participants: [
        { userId: parent._id, userType: 'parent', role: 'member' },
        { userId: teacher._id, userType: 'teacher', role: 'member' },
      ],
    });
  }

  const text = String(body || '').trim();
  if (!text) throw badRequest('Excuse reason required');

  const message = await Message.create({
    conversationId: conv._id,
    senderId: parent._id,
    senderType: 'parent',
    body: text,
    status: 'sent',
    messageType: 'text',
  });

  conv.lastMessageAt = message.createdAt;
  conv.lastMessagePreview = text.slice(0, 200);
  await conv.save();

  const formatted = await enrichMessage(message, me);
  emitToConversation(String(conv._id), 'message', formatted, conv.participants);
  await notifyParticipants(conv, message, me);

  return {
    conversationId: String(conv._id),
    messageId: String(message._id),
    message: formatted,
  };
};

module.exports = {
  listConversations,
  getConversation,
  listMessages,
  sendMessage,
  markRead,
  findOrCreatePrivate,
  createSupport,
  sendParentAbsenceExcuse,
  createBroadcast,
  syncGroupConversation,
  updateMessage,
  togglePinMute,
  reactToMessage,
  starMessage,
  pinMessage,
  forwardMessage,
  searchMessages,
  createSubjectRoom,
  listSubjectOptions,
  directory,
  setPresence,
  getPresence,
  resetAllPresenceOffline,
  reconcileStalePresence,
  unreadTotal,
  flushScheduledMessages,
  moderationInbox,
  moderateMessage,
  createChatPoll,
  signalCall,
  setSocketEmitter,
  formatMessage,
  formatConversation,
  isParticipant,
  actorKey,
};
