const NotificationLog = require('../models/NotificationLog');
const ParentNotificationSettings = require('../models/ParentNotificationSettings');
const StudentNotificationSettings = require('../models/StudentNotificationSettings');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Parent = require('../models/Parent');
const { getTashkentParts } = require('../utils/classWindow');
const { toMinutes } = require('../utils/timeUtils');
const fcmService = require('./fcmService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const logger = require('../config/logger');

const actorUserType = (req) =>
  req.userType === 'student' ? 'student' : req.userType === 'parent' ? 'parent' : 'teacher';

const lastTestPushAt = new Map();

const formatNotification = (doc) => ({
  id: String(doc._id || doc.id || ''),
  userId: doc.userId != null ? String(doc.userId) : '',
  userType: doc.userType,
  studentId: doc.studentId != null ? String(doc.studentId) : null,
  title: doc.title,
  body: doc.body,
  eventType: doc.eventType,
  channel: doc.channel,
  date: doc.date,
  data: doc.data || {},
  readAt: doc.readAt,
  pushStatus: doc.pushStatus,
  createdAt: doc.createdAt,
});

const formatSettings = (doc) => {
  const o = doc && typeof doc.toObject === 'function' ? doc.toObject() : doc || {};
  return {
    studentId: String(o.studentId || ''),
    channels: {
      push: o.channels?.push !== false,
      inApp: o.channels?.inApp !== false,
    },
    events: {
      feedback: o.events?.feedback !== false,
      attendance: o.events?.attendance !== false,
      payment: o.events?.payment !== false,
      exam: o.events?.exam !== false,
      messages: o.events?.messages !== false,
      news: o.events?.news !== false,
    },
    quietHoursStart: o.quietHoursStart || '22:00',
    quietHoursEnd: o.quietHoursEnd || '08:00',
    timezone: o.timezone || 'Asia/Tashkent',
    updatedAt: o.updatedAt,
  };
};

const isQuietHours = (settings, parts = getTashkentParts()) => {
  const start = toMinutes(settings.quietHoursStart || '22:00');
  const end = toMinutes(settings.quietHoursEnd || '08:00');
  const now = toMinutes(parts.time);
  if (start < end) return now >= start && now < end;
  return now >= start || now < end;
};

const eventEnabledKey = (eventType) => {
  const raw = String(eventType || '');
  if (raw.startsWith('feedback')) return 'feedback';
  if (raw.startsWith('attendance')) return 'attendance';
  if (raw.startsWith('payment')) return 'payment';
  if (raw.startsWith('exam')) return 'exam';
  if (raw.startsWith('chat') || raw.startsWith('message')) return 'messages';
  if (raw.startsWith('news') || raw.startsWith('announcement')) return 'news';
  return raw.split('_')[0];
};

const screenForEvent = (eventType, data = {}) => {
  if (data.screen) return String(data.screen);
  const key = eventEnabledKey(eventType);
  const map = {
    payment: 'payments',
    feedback: 'feedback',
    attendance: 'schedule',
    messages: 'messages',
    news: 'news',
    exam: 'exams',
  };
  return map[key] || 'notifications';
};

const formatStudentSettings = (doc) => {
  const o = doc && typeof doc.toObject === 'function' ? doc.toObject() : doc || {};
  return {
    studentId: String(o.studentId || ''),
    channels: {
      push: o.channels?.push !== false,
      inApp: o.channels?.inApp !== false,
    },
    events: {
      feedback: o.events?.feedback !== false,
      attendance: o.events?.attendance !== false,
      payment: o.events?.payment !== false,
      messages: o.events?.messages !== false,
      news: o.events?.news !== false,
      exam: o.events?.exam !== false,
    },
    // Critical: payment reminders + lock cannot be silenced for OS push.
    alwaysPush: ['payment', 'payment_lock'],
  };
};

const getStudentSettings = async (studentId) => {
  let settings = await StudentNotificationSettings.findOne({ studentId });
  if (!settings) {
    try {
      settings = await StudentNotificationSettings.create({ studentId });
    } catch (error) {
      if (error.code === 11000) {
        settings = await StudentNotificationSettings.findOne({ studentId });
      } else throw error;
    }
  }
  return formatStudentSettings(settings);
};

const updateStudentSettings = async (studentId, data = {}) => {
  const settings = await StudentNotificationSettings.findOneAndUpdate(
    { studentId },
    {
      $set: {
        ...(data.channels ? { channels: data.channels } : {}),
        ...(data.events ? { events: data.events } : {}),
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  return formatStudentSettings(settings);
};

/** Whether student opted out of non-critical push. Payment/lock always allowed. */
const studentAllowsPush = async (studentId, eventType) => {
  const key = eventEnabledKey(eventType);
  if (key === 'payment' || String(eventType).includes('lock')) return true;
  const settings = await getStudentSettings(studentId);
  if (!settings.channels.push) return false;
  if (settings.events[key] === false) return false;
  return true;
};

const getParentSettings = async (studentId) => {
  let settings = await ParentNotificationSettings.findOne({ studentId });
  if (!settings) {
    try {
      settings = await ParentNotificationSettings.create({ studentId });
    } catch (error) {
      // Race: another request created settings — re-read.
      if (error?.code === 11000) {
        settings = await ParentNotificationSettings.findOne({ studentId });
      } else {
        throw error;
      }
    }
  }
  if (!settings) {
    throw Object.assign(new Error('Could not load notification settings'), {
      statusCode: 500,
      code: 'SETTINGS_ERROR',
    });
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
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  return formatSettings(settings);
};

const registerFcmToken = async (studentId, token, meta = {}) => {
  if (!token || token.length < 10) {
    throw Object.assign(new Error('Valid FCM token is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  await fcmService.upsertDeviceToken({
    userId: studentId,
    userType: 'student',
    token,
    platform: meta.platform || 'unknown',
    deviceId: meta.deviceId || '',
  });
  const tokens = new Set(student.fcmTokens || []);
  tokens.add(token);
  student.fcmTokens = [...tokens];
  await student.save();
  return { registered: true, tokenCount: student.fcmTokens.length };
};

const registerDeviceTokenForActor = async (req, body = {}) => {
  const userType = actorUserType(req);
  return fcmService.upsertDeviceToken({
    userId: req.user._id,
    userType,
    token: body.token,
    platform: body.platform || 'unknown',
    deviceId: body.deviceId || '',
    previousToken: body.previousToken,
  });
};

const refreshDeviceTokenForActor = async (req, body = {}) => {
  const userType = actorUserType(req);
  return fcmService.upsertDeviceToken({
    userId: req.user._id,
    userType,
    token: body.token,
    platform: body.platform || 'unknown',
    deviceId: body.deviceId || '',
    previousToken: body.previousToken || body.oldToken,
  });
};

const removeDeviceTokenForActor = async (req, body = {}) => {
  const userType = actorUserType(req);
  return fcmService.removeDeviceToken({
    userId: req.user._id,
    userType,
    token: body.token,
  });
};

const listForUser = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const userType = actorUserType(req);
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
    userType: actorUserType(req),
  });
  if (!notification) {
    throw Object.assign(new Error('Notification not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  notification.readAt = new Date();
  await notification.save();
  return formatNotification(notification.toObject());
};

const markAllRead = async (req) => {
  const userType = actorUserType(req);
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
  dedupe = false,
  date,
  allowInactive = false,
  push = false,
  forcePush = false,
}) => {
  if (studentId && !allowInactive) {
    const student = await Student.findById(studentId).select('status');
    if (student && student.status === 'inactive' && !String(eventType).includes('lock')) {
      return null;
    }
  }

  const parts = getTashkentParts();
  const dateKey = date || parts.dateString;

  if (dedupe && studentId) {
    const existing = await NotificationLog.findOne({
      studentId,
      eventType,
      date: dateKey,
      channel: 'in_app',
    });
    if (existing) {
      if (push || forcePush) {
        await maybePushToRecipient({
          userId,
          userType,
          studentId,
          title,
          body,
          eventType,
          data: { ...(data || {}), notificationId: String(existing._id) },
          forcePush,
        });
      }
      return formatNotification(existing.toObject());
    }
  }

  const notification = await NotificationLog.create({
    userId,
    userType,
    studentId,
    title,
    body,
    eventType,
    channel: 'in_app',
    date: dateKey,
    data: data || {},
    branchId,
    pushStatus: 'skipped',
  });

  const formatted = formatNotification(notification.toObject());

  if (push || forcePush) {
    const pushResult = await maybePushToRecipient({
      userId,
      userType,
      studentId,
      title,
      body,
      eventType,
      data: { ...(data || {}), notificationId: formatted.id },
      forcePush,
    });
    if (pushResult?.status) {
      notification.pushStatus =
        pushResult.status === 'sent' || pushResult.status === 'stub'
          ? pushResult.status === 'stub'
            ? 'stub'
            : 'sent'
          : 'skipped';
      await notification.save();
      formatted.pushStatus = notification.pushStatus;
    }
  }

  return formatted;
};

const maybePushToRecipient = async ({
  userId,
  userType,
  studentId,
  title,
  body,
  eventType,
  data = {},
  forcePush = false,
}) => {
  try {
    const type = userType === 'student' ? 'student' : userType === 'parent' ? 'parent' : 'teacher';
    if (type === 'student' && !forcePush) {
      const ok = await studentAllowsPush(userId, eventType);
      if (!ok) return { status: 'skipped', reason: 'student_prefs' };
    }

    const isChat =
      String(eventType || '').toLowerCase().includes('chat') ||
      String(eventType || '').toLowerCase().includes('message') ||
      String(data.screen || '').toLowerCase() === 'messages' ||
      String(data.actions || '') === 'chat';

    const payloadData = {
      eventType: String(eventType || ''),
      screen: screenForEvent(eventType, data),
      notificationId: data.notificationId != null ? String(data.notificationId) : '',
      messageId: data.messageId != null ? String(data.messageId) : '',
      studentId: studentId != null ? String(studentId) : '',
      conversationId: data.conversationId != null ? String(data.conversationId) : '',
      feedbackId: data.feedbackId != null ? String(data.feedbackId) : '',
      postId: data.postId != null ? String(data.postId) : '',
      kind: data.kind != null ? String(data.kind) : '',
      ...(isChat || data.actions != null ? { actions: String(data.actions || 'chat') } : {}),
      ...(data.title != null ? { title: String(data.title) } : {}),
      ...(data.body != null ? { body: String(data.body) } : {}),
    };

    return fcmService.sendToUser({
      userId,
      userType: type,
      title,
      body,
      data: payloadData,
    });
  } catch (error) {
    logger.warn(`maybePushToRecipient failed: ${error.message}`);
    return { status: 'failed', reason: error.message };
  }
};

const formatMoney = (amount) => {
  const value = Math.round(Number(amount) || 0);
  return `${value.toLocaleString('en-US')} UZS`;
};

const monthLabel = (month, year) => {
  const names = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return `${names[Math.max(0, Math.min(11, month - 1))] || month} ${year}`;
};

const sendParentPush = async ({ student, title, body, eventType, data, skipQuietHours = false }) => {
  if (!student) {
    return { status: 'skipped', reason: 'no_student' };
  }

  const settingsDoc = await getParentSettings(student._id);
  const settings = formatSettings(settingsDoc);
  const eventKey = eventEnabledKey(eventType);
  if (!settings.channels.push || !settings.events[eventKey]) {
    return { status: 'skipped', reason: 'disabled' };
  }
  if (!skipQuietHours && isQuietHours(settings)) {
    return { status: 'skipped', reason: 'quiet_hours' };
  }

  const parts = getTashkentParts();
  const dedupKey = {
    studentId: student._id,
    eventType: `parent_${eventType}`,
    date: parts.dateString,
    channel: 'push',
  };
  const existing = await NotificationLog.findOne(dedupKey);
  if (existing) return { status: 'skipped', reason: 'dedup' };

  const pushResult = await fcmService.sendToParentsOfStudent({
    studentId: student._id,
    title,
    body,
    data: {
      eventType: String(eventType),
      screen: screenForEvent(eventType, data),
      studentId: String(student._id),
      ...(data || {}),
    },
  });

  await NotificationLog.create({
    userId: student._id,
    userType: 'parent',
    studentId: student._id,
    title,
    body,
    eventType: `parent_${eventType}`,
    channel: 'push',
    date: parts.dateString,
    data: data || {},
    branchId: student.branchId,
    pushStatus:
      pushResult.status === 'stub'
        ? 'stub'
        : pushResult.sent > 0
          ? 'sent'
          : 'skipped',
  });

  return pushResult;
};

const notifyFeedbackSubmitted = async (feedback) => {
  try {
    const student = await Student.findById(feedback.student?._id || feedback.student);
    if (!student || student.status === 'inactive') return;

    const className = feedback.className || feedback.classSchedule?.className || 'class';
    const homework = feedback.homework ?? 0;
    const behavior = feedback.behavior ?? 0;
    const participation = feedback.participation ?? 0;
    const title = 'Daily feedback';
    const body =
      `Daily feedback for ${className}: homework ${homework}%, ` +
      `behavior ${behavior}%, participation ${participation}%.`;

    await createInAppNotification({
      userId: student._id,
      userType: 'student',
      studentId: student._id,
      title,
      body,
      eventType: 'feedback_submitted',
      data: {
        feedbackId: String(feedback.id || feedback._id),
        className,
        kind: 'daily_feedback',
        screen: 'feedback',
      },
      branchId: student.branchId,
      push: true,
    });

    await sendParentPush({
      student,
      title: 'Daily feedback update',
      body: `${student.name} received daily feedback for ${className}`,
      eventType: 'feedback_submitted',
      data: { feedbackId: String(feedback.id || feedback._id), screen: 'feedback' },
    });
  } catch (error) {
    logger.warn(`notifyFeedbackSubmitted failed: ${error.message}`);
  }
};

const notifyAttendanceMarked = async ({ studentId, status, className, date, branchId }) => {
  try {
    const student = await Student.findById(studentId);
    if (!student || student.status === 'inactive') return;

    const statusLabel = String(status || 'present').replace(/_/g, ' ');
    const lesson = className || 'class';
    const title = 'Attendance update';
    const body = `Attendance: you were marked ${statusLabel} for ${lesson}${date ? ` on ${date}` : ''}.`;

    await createInAppNotification({
      userId: student._id,
      userType: 'student',
      studentId: student._id,
      title,
      body,
      eventType: 'attendance_marked',
      data: {
        status,
        className: lesson,
        date,
        kind: 'attendance',
        screen: 'schedule',
      },
      branchId: branchId || student.branchId,
      push: true,
    });

    await sendParentPush({
      student,
      title: 'Attendance update',
      body: `${student.name} was marked ${statusLabel} for ${lesson}`,
      eventType: 'attendance_marked',
      data: { status, className: lesson, date, screen: 'schedule' },
    });
  } catch (error) {
    logger.warn(`notifyAttendanceMarked failed: ${error.message}`);
  }
};

/**
 * Send monthly payment reminders to unpaid students.
 * Days 1–7: once/day (morning). Days 8–10: 3×/day. Skip after full payment.
 */
const runPaymentDueReminders = async (forcedSlot = null) => {
  const parts = getTashkentParts();
  const [yearStr, monthStr, dayStr] = parts.dateString.split('-');
  const day = Number(dayStr);
  const month = Number(monthStr);
  const year = Number(yearStr);
  const hour = Number(parts.time.slice(0, 2));
  const minute = Number(parts.time.slice(3, 5));

  if (day < 1 || day > 10) {
    return { skipped: true, reason: 'outside_reminder_window' };
  }

  const slotByHour = {
    9: 'payment_due_am',
    14: 'payment_due_mid',
    19: 'payment_due_pm',
  };

  let eventType = forcedSlot;
  if (!eventType) {
    // Run only in the first 8 minutes of a reminder hour so a 1-minute ticker fires once.
    if (minute > 7) return { skipped: true, reason: 'outside_slot_minute' };
    eventType = slotByHour[hour];
  }

  if (!eventType) return { skipped: true, reason: 'no_slot' };

  if (day <= 7 && eventType !== 'payment_due_am') {
    return { skipped: true, reason: 'early_month_once_daily' };
  }

  const { buildDuesByStudent } = require('./paymentService');
  const students = await Student.find({ status: 'active' }).select('_id name branchId');
  if (!students.length) return { sent: 0 };

  const duesMap = await buildDuesByStudent({
    studentIds: students.map((s) => s._id),
    month,
    year,
  });

  let sent = 0;
  let skippedPaid = 0;
  let skippedDedup = 0;

  for (const student of students) {
    const dues = duesMap.get(String(student._id));
    if (!dues || !dues.courses.length) continue;
    if (dues.overallStatus === 'paid' || dues.amountRemaining <= 0) {
      skippedPaid += 1;
      continue;
    }

    const amountText = formatMoney(dues.amountRemaining);
    const period = monthLabel(month, year);
    const title = 'Monthly payment reminder';
    const body =
      `Payment due for ${period}: ${amountText}. ` +
      `Please pay between the 1st and 10th. ` +
      `If you don't pay, TechRen App will be locked and you cannot use the system.`;

    const before = await NotificationLog.findOne({
      studentId: student._id,
      eventType,
      date: parts.dateString,
      channel: 'in_app',
    });
    if (before) {
      skippedDedup += 1;
      continue;
    }

    await createInAppNotification({
      userId: student._id,
      userType: 'student',
      studentId: student._id,
      title,
      body,
      eventType,
      data: {
        kind: 'payment',
        month,
        year,
        amountRemaining: dues.amountRemaining,
        courses: dues.courses,
        screen: 'payments',
      },
      branchId: student.branchId,
      dedupe: true,
      date: parts.dateString,
      forcePush: true, // payment reminders always push
    });

    try {
      await sendParentPush({
        student,
        title,
        body,
        eventType: 'payment_due',
        data: {
          kind: 'payment',
          month,
          year,
          amountRemaining: dues.amountRemaining,
          screen: 'payments',
        },
      });
    } catch (pushErr) {
      logger.warn(`payment reminder parent push failed for ${student._id}: ${pushErr.message}`);
    }
    sent += 1;
  }

  logger.info(
    `payment due reminders slot=${eventType} day=${day} sent=${sent} skippedPaid=${skippedPaid} dedup=${skippedDedup}`
  );
  return { sent, skippedPaid, skippedDedup, eventType, day };
};

/**
 * After the 1–10 payment window, auto-lock unpaid active students so the app
 * blocks learning until staff reactivates / payment is cleared.
 */
const runPaymentLockSweep = async () => {
  const parts = getTashkentParts();
  const [yearStr, monthStr, dayStr] = parts.dateString.split('-');
  const day = Number(dayStr);
  const month = Number(monthStr);
  const year = Number(yearStr);

  if (day < 11) {
    return { skipped: true, reason: 'inside_grace_window' };
  }

  // Run once per day in the morning slot window.
  const hour = Number(parts.time.slice(0, 2));
  const minute = Number(parts.time.slice(3, 5));
  if (hour !== 9 || minute > 7) {
    return { skipped: true, reason: 'outside_lock_slot' };
  }

  const { buildDuesByStudent } = require('./paymentService');
  const students = await Student.find({ status: 'active' }).select('_id name branchId fcmTokens');
  if (!students.length) return { locked: 0 };

  const duesMap = await buildDuesByStudent({
    studentIds: students.map((s) => s._id),
    month,
    year,
  });

  let locked = 0;
  for (const student of students) {
    const dues = duesMap.get(String(student._id));
    if (!dues || !dues.courses.length) continue;
    if (dues.overallStatus === 'paid' || dues.amountRemaining <= 0) continue;

    const already = await NotificationLog.findOne({
      studentId: student._id,
      eventType: 'payment_lock',
      date: parts.dateString,
      channel: 'in_app',
    });
    if (already) continue;

    const amountText = formatMoney(dues.amountRemaining);
    const period = monthLabel(month, year);
    const title = 'App locked — payment required';
    const body =
      `Your TechRen account was locked because payment for ${period} is still unpaid (${amountText}). ` +
      `Pay at the office or contact administration to restore access.`;

    await createInAppNotification({
      userId: student._id,
      userType: 'student',
      studentId: student._id,
      title,
      body,
      eventType: 'payment_lock',
      data: {
        kind: 'payment',
        locked: true,
        month,
        year,
        amountRemaining: dues.amountRemaining,
        screen: 'payments',
      },
      branchId: student.branchId,
      dedupe: true,
      date: parts.dateString,
      allowInactive: true,
      forcePush: true,
    });

    student.status = 'inactive';
    await student.save();

    try {
      await sendParentPush({
        student,
        title,
        body,
        eventType: 'payment_due',
        data: { kind: 'payment', locked: true, screen: 'payments' },
        skipQuietHours: true,
      });
    } catch (pushErr) {
      logger.warn(`payment lock parent push failed for ${student._id}: ${pushErr.message}`);
    }

    locked += 1;
  }

  logger.info(`payment lock sweep day=${day} locked=${locked}`);
  return { locked, day, month, year };
};

const sendTestPushForActor = async (req) => {
  const userType = actorUserType(req);
  const key = `${userType}:${req.user._id}`;
  const prev = lastTestPushAt.get(key) || 0;
  if (Date.now() - prev < 15000) {
    throw Object.assign(new Error('Wait a few seconds before sending another test'), {
      statusCode: 429,
      code: 'RATE_LIMIT',
    });
  }
  lastTestPushAt.set(key, Date.now());

  const result = await fcmService.sendToUser({
    userId: req.user._id,
    userType,
    title: 'TechRen test',
    body: 'Push is working. You can close this notification.',
    data: { eventType: 'test_push', screen: 'notifications' },
  });

  return {
    sent: result.sent || 0,
    failed: result.failed || 0,
    status: result.status || 'skipped',
    reason: result.reason || null,
    firebaseConfigured: Boolean(fcmService.isFirebaseReady()),
  };
};

module.exports = {
  formatSettings,
  getParentSettings,
  updateParentSettings,
  getStudentSettings,
  updateStudentSettings,
  registerFcmToken,
  registerDeviceTokenForActor,
  refreshDeviceTokenForActor,
  removeDeviceTokenForActor,
  listForUser,
  markRead,
  markAllRead,
  createInAppNotification,
  maybePushToRecipient,
  notifyFeedbackSubmitted,
  notifyAttendanceMarked,
  runPaymentDueReminders,
  runPaymentLockSweep,
  sendTestPushForActor,
  screenForEvent,
};
