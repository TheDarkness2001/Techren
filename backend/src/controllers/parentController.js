const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const parentService = require('../services/parentService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

const requireParent = (req, res, next) => {
  if (req.userType !== 'parent') {
    return sendError(res, 403, 'FORBIDDEN', 'Parent access required');
  }
  next();
};

exports.children = asyncHandler(async (req, res) => {
  try {
    const items = await parentService.listChildren(req.user);
    sendSuccess(res, { children: items });
  } catch (e) {
    handle(res, e);
  }
});

exports.overview = asyncHandler(async (req, res) => {
  try {
    const data = await parentService.getChildOverview(req.user, req.params.studentId);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.feedback = asyncHandler(async (req, res) => {
  try {
    const result = await parentService.getChildFeedback(req.user, req.params.studentId, req.query);
    sendSuccess(res, { feedback: result.items }, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.attendance = asyncHandler(async (req, res) => {
  try {
    const result = await parentService.getChildAttendance(req.user, req.params.studentId, req.query);
    sendSuccess(res, { attendance: result.items }, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.exams = asyncHandler(async (req, res) => {
  try {
    const result = await parentService.getChildExams(req.user, req.params.studentId, req.query);
    sendSuccess(res, { exams: result.items }, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.requireParent = requireParent;
