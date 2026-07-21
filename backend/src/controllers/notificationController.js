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
