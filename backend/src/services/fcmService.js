const DeviceToken = require('../models/DeviceToken');
const Student = require('../models/Student');
const Parent = require('../models/Parent');
const Teacher = require('../models/Teacher');
const { sendPush, isFirebaseReady } = require('../config/firebase');
const logger = require('../config/logger');

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

const stringifyData = (data = {}) =>
  Object.fromEntries(
    Object.entries(data)
      .filter(([, v]) => v != null)
      .map(([k, v]) => [k, typeof v === 'string' ? v : String(v)])
  );

const collectLegacyTokens = async (userId, userType) => {
  if (userType === 'student') {
    const s = await Student.findById(userId).select('fcmTokens').lean();
    return s?.fcmTokens || [];
  }
  if (userType === 'parent') {
    const p = await Parent.findById(userId).select('fcmTokens').lean();
    return p?.fcmTokens || [];
  }
  if (userType === 'teacher') {
    const t = await Teacher.findById(userId).select('fcmTokens').lean();
    return t?.fcmTokens || [];
  }
  return [];
};

const getActiveTokensForUser = async (userId, userType) => {
  const docs = await DeviceToken.find({
    userId,
    userType,
    active: true,
  }).select('token');
  const fromDb = docs.map((d) => d.token).filter(Boolean);
  if (fromDb.length) return [...new Set(fromDb)];
  const legacy = await collectLegacyTokens(userId, userType);
  return [...new Set(legacy.filter(Boolean))];
};

const deactivateTokens = async (tokens = []) => {
  if (!tokens.length) return 0;
  const result = await DeviceToken.updateMany(
    { token: { $in: tokens } },
    { $set: { active: false } }
  );
  // Also strip from Student/Parent legacy arrays
  await Promise.all([
    Student.updateMany({}, { $pull: { fcmTokens: { $in: tokens } } }),
    Parent.updateMany({}, { $pull: { fcmTokens: { $in: tokens } } }),
    Teacher.updateMany({}, { $pull: { fcmTokens: { $in: tokens } } }),
  ]);
  return result.modifiedCount || 0;
};

/**
 * Register / refresh a device token for the authenticated user.
 */
const upsertDeviceToken = async ({
  userId,
  userType,
  token,
  platform = 'unknown',
  deviceId = '',
  previousToken,
}) => {
  if (!token || String(token).length < 10) {
    throw Object.assign(new Error('Valid FCM token is required'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }
  const now = new Date();

  if (previousToken && previousToken !== token) {
    await DeviceToken.updateMany(
      { token: previousToken, userId, userType },
      { $set: { active: false } }
    );
  }

  const existing = await DeviceToken.findOne({ token });
  if (existing) {
    existing.userId = userId;
    existing.userType = userType;
    existing.platform = platform || existing.platform;
    if (deviceId) existing.deviceId = deviceId;
    existing.active = true;
    existing.lastSeenAt = now;
    await existing.save();
  } else {
    await DeviceToken.create({
      userId,
      userType,
      token,
      platform: platform || 'unknown',
      deviceId: deviceId || '',
      active: true,
      lastSeenAt: now,
    });
  }

  // Keep legacy student/parent arrays in sync during migration.
  if (userType === 'student') {
    await Student.findByIdAndUpdate(userId, { $addToSet: { fcmTokens: token } });
  } else if (userType === 'parent') {
    await Parent.findByIdAndUpdate(userId, { $addToSet: { fcmTokens: token } });
  } else if (userType === 'teacher') {
    await Teacher.findByIdAndUpdate(userId, { $addToSet: { fcmTokens: token } });
  }

  return { registered: true };
};

const removeDeviceToken = async ({ userId, userType, token }) => {
  if (!token) {
    throw Object.assign(new Error('Token is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  await DeviceToken.updateMany(
    { token, userId, userType },
    { $set: { active: false } }
  );
  if (userType === 'student') {
    await Student.findByIdAndUpdate(userId, { $pull: { fcmTokens: token } });
  } else if (userType === 'parent') {
    await Parent.findByIdAndUpdate(userId, { $pull: { fcmTokens: token } });
  } else if (userType === 'teacher') {
    await Teacher.findByIdAndUpdate(userId, { $pull: { fcmTokens: token } });
  }
  return { removed: true };
};

const sendToUser = async ({ userId, userType, title, body, data = {} }) => {
  const tokens = await getActiveTokensForUser(userId, userType);
  if (!tokens.length) {
    return { sent: 0, failed: 0, status: 'skipped', reason: 'no_tokens' };
  }

  const result = await sendPush({
    tokens,
    title,
    body,
    data: stringifyData(data),
  });

  const invalid = (result.invalidTokens || []).filter((t) => tokens.includes(t));
  if (invalid.length) {
    await deactivateTokens(invalid);
    logger.info(`Deactivated ${invalid.length} invalid FCM token(s) for ${userType}:${userId}`);
  }

  return result;
};

const sendToUsers = async ({ recipients = [], title, body, data = {} }) => {
  let sent = 0;
  let failed = 0;
  for (const r of recipients) {
    if (!r?.userId || !r?.userType) continue;
    const result = await sendToUser({
      userId: r.userId,
      userType: r.userType,
      title,
      body,
      data,
    });
    sent += result.sent || 0;
    failed += result.failed || 0;
  }
  return { sent, failed, status: failed ? 'partial' : 'sent' };
};

const sendToParentsOfStudent = async ({ studentId, title, body, data = {} }) => {
  const parents = await Parent.find({ children: studentId, status: { $ne: 'inactive' } })
    .select('_id')
    .lean();
  if (!parents.length) {
    return { sent: 0, failed: 0, status: 'skipped', reason: 'no_parents' };
  }
  return sendToUsers({
    recipients: parents.map((p) => ({ userId: p._id, userType: 'parent' })),
    title,
    body,
    data: { ...data, studentId: String(studentId) },
  });
};

module.exports = {
  upsertDeviceToken,
  removeDeviceToken,
  getActiveTokensForUser,
  deactivateTokens,
  sendToUser,
  sendToUsers,
  sendToParentsOfStudent,
  INVALID_TOKEN_CODES,
  isFirebaseReady,
};
