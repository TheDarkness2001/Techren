const NotificationLog = require('../models/NotificationLog');
const ParentNotificationSettings = require('../models/ParentNotificationSettings');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const { getTashkentParts } = require('../utils/classWindow');
const { toMinutes } = require('../utils/timeUtils');
const { sendPush } = require('../config/firebase');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const logger = require('../config/logger');

const formatNotification = (doc) => ({
  id: doc._id,
  userId: doc.userId,
  userType: doc.userType,
  studentId: doc.studentId,
  title: doc.title,
  body: doc.body,
  eventType: doc.eventType,
  channel: doc.channel,
  date: doc.date,
  data: doc.data,
  readAt: doc.readAt,
  pushStatus: doc.pushStatus,
  createdAt: doc.createdAt,
});

const formatSettings = (doc) => ({
  studentId: doc.studentId,
  channels: doc.channels,
  events: doc.events,
  quietHoursStart: doc.quietHoursStart,
  quietHoursEnd: doc.quietHoursEnd,
  timezone: doc.timezone,
  updatedAt: doc.updatedAt,
});

const isQuietHours = (settings, parts = getTashkentParts()) => {
  const start = toMinutes(settings.quietHoursStart || '22:00');
  const end = toMinutes(settings.quietHoursEnd || '08:00');
  const now = toMinutes(parts.time);
  if (start < end) return now >= start && now < end;
  return now >= start || now < end;
};

const getParentSettings = async (studentId) => {
  let settings = await ParentNotificationSettings.findOne({ studentId });
  if (!settings) {
    settings = await ParentNotificationSettings.create({ studentId });
  }
  return settings;
};

const updateParentSettings = async (studentId, data) => {
  const settings = await ParentNotificationSettings.findOneAndUpdate(
    { studentId },
    {
      $set: {
        ...(data.channels ? { channels: data.channels } : {}),
        ...(data.events ? { events: data.events } : {}),
        ...(data.quietHoursStart ? { quietHoursStart: data.quietHoursStart } : {}),
        ...(data.quietHoursEnd ? { quietHoursEnd: data.quietHoursEnd } : {}),
        ...(data.timezone ? { timezone: data.timezone } : {}),
      },
    },
    { upsert: true, new: true }
  );
  return formatSettings(settings.toObject());
};

const registerFcmToken = async (studentId, token) => {
  if (!token || token.length < 10) {
    throw Object.assign(new Error('Valid FCM token is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const tokens = new Set(student.fcmTokens || []);
  tokens.add(token);
  student.fcmTokens = [...tokens];
  await student.save();
  return { registered: true, tokenCount: student.fcmTokens.length };
};

const listForUser = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const userType = req.userType === 'student' ? 'student' : 'teacher';
  const filter = {
    userId: req.user._id,
    userType,
    channel: 'in_app',
  };
  if (req.query.unreadOnly === 'true') filter.readAt = null;

  const unreadFilter = {
    userId: req.user._id,
    userType,
    channel: 'in_app',
    readAt: null,
  };

  let queryFilter = { ...filter };
  if (req.query.search) {
    const term = String(req.query.search).trim();
    if (term) {
      queryFilter = {
        $and: [
          filter,
          {
            $or: [
              { title: { $regex: term, $options: 'i' } },
              { body: { $regex: term, $options: 'i' } },
              { eventType: { $regex: term, $options: 'i' } },
            ],
          },
        ],
      };
    }
  }

  const [items, total, unreadCount] = await Promise.all([
    NotificationLog.find(queryFilter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    NotificationLog.countDocuments(queryFilter),
    NotificationLog.countDocuments(unreadFilter),
  ]);

  return {
    notifications: items.map((n) => formatNotification(n.toObject())),
    unreadCount,
    meta: buildPaginationMeta(page, limit, total),
  };
};

const markRead = async (req, id) => {
  const notification = await NotificationLog.findOne({
    _id: id,
    userId: req.user._id,
    userType: req.userType === 'student' ? 'student' : 'teacher',
  });
  if (!notification) {
    throw Object.assign(new Error('Notification not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  notification.readAt = new Date();
  await notification.save();
  return formatNotification(notification.toObject());
};

const markAllRead = async (req) => {
  const userType = req.userType === 'student' ? 'student' : 'teacher';
  const result = await NotificationLog.updateMany(
    { userId: req.user._id, userType, channel: 'in_app', readAt: null },
    { readAt: new Date() }
  );
  return { updated: result.modifiedCount };
};

const createInAppNotification = async ({
  userId,
  userType,
  studentId,
  title,
  body,
  eventType,
  data,
  branchId,
}) => {
  const parts = getTashkentParts();
  const notification = await NotificationLog.create({
    userId,
    userType,
    studentId,
    title,
    body,
    eventType,
    channel: 'in_app',
    date: parts.dateString,
    data: data || {},
    branchId,
    pushStatus: 'skipped',
  });
  return formatNotification(notification.toObject());
};

const sendParentPush = async ({ student, title, body, eventType, data }) => {
  const settings = await getParentSettings(student._id);
  if (!settings.channels?.push || !settings.events?.[eventType.split('_')[0]]) {
    return { status: 'skipped', reason: 'disabled' };
  }
  if (isQuietHours(settings)) {
    return { status: 'skipped', reason: 'quiet_hours' };
  }

  const parts = getTashkentParts();
  const dedupKey = { studentId: student._id, eventType, date: parts.dateString, channel: 'push' };
  const existing = await NotificationLog.findOne(dedupKey);
  if (existing) return { status: 'skipped', reason: 'dedup' };

  const pushResult = await sendPush({
    tokens: student.fcmTokens || [],
    title,
    body,
    data: { eventType, studentId: String(student._id), ...(data || {}) },
  });

  await NotificationLog.create({
    userId: student._id,
    userType: 'parent',
    studentId: student._id,
    title,
    body,
    eventType,
    channel: 'push',
    date: parts.dateString,
    data: data || {},
    branchId: student.branchId,
    pushStatus: pushResult.status === 'stub' ? 'stub' : pushResult.status === 'sent' ? 'sent' : 'skipped',
  });

  return pushResult;
};

const notifyFeedbackSubmitted = async (feedback) => {
  try {
    const student = await Student.findById(feedback.student?._id || feedback.student);
    if (!student) return;

    const className = feedback.className || feedback.classSchedule?.className || 'class';
    const title = 'New feedback received';
    const body = `${student.name}: homework ${feedback.homework}%, behavior ${feedback.behavior}% for ${className}`;

    await createInAppNotification({
      userId: student._id,
      userType: 'student',
      studentId: student._id,
      title,
      body,
      eventType: 'feedback_submitted',
      data: { feedbackId: String(feedback.id || feedback._id), className },
      branchId: student.branchId,
    });

    await sendParentPush({
      student,
      title: 'Class feedback update',
      body: `${student.name} received new feedback for ${className}`,
      eventType: 'feedback_submitted',
      data: { feedbackId: String(feedback.id || feedback._id) },
    });
  } catch (error) {
    logger.warn(`notifyFeedbackSubmitted failed: ${error.message}`);
  }
};

module.exports = {
  formatSettings,
  getParentSettings,
  updateParentSettings,
  registerFcmToken,
  listForUser,
  markRead,
  markAllRead,
  createInAppNotification,
  notifyFeedbackSubmitted,
};
