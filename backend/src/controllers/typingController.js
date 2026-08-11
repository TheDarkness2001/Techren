const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const typingService = require('../services/typingService');
const { requireStaff } = require('../middleware/roleGuards');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.dashboard = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.dashboard(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.start = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.start(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.more = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.moreText(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.finish = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.finish(req, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.leaderboard(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.daily = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.daily(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.history = asyncHandler(async (req, res) => {
  try {
    const data = await typingService.history(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.listContent = asyncHandler(async (req, res) => {
  try {
    if (req.userType === 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Staff only');
    }
    const data = await typingService.listContent(req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

// Keep requireStaff import used for future CMS routes.
exports._requireStaff = requireStaff;
