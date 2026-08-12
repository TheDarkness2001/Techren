const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const notificationService = require('../services/notificationService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const data = await notificationService.listForUser(req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.markRead = asyncHandler(async (req, res) => {
  try {
    const item = await notificationService.markRead(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.markAllRead = asyncHandler(async (req, res) => {
  try {
    const data = await notificationService.markAllRead(req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.registerDeviceToken = asyncHandler(async (req, res) => {
  try {
    const data = await notificationService.registerDeviceTokenForActor(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.refreshDeviceToken = asyncHandler(async (req, res) => {
  try {
    const data = await notificationService.refreshDeviceTokenForActor(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeDeviceToken = asyncHandler(async (req, res) => {
  try {
    const data = await notificationService.removeDeviceTokenForActor(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.getMySettings = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students only');
    }
    const data = await notificationService.getStudentSettings(req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateMySettings = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students only');
    }
    const data = await notificationService.updateStudentSettings(req.user._id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});
