const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const studentAttendanceService = require('../services/studentAttendanceService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await studentAttendanceService.list(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.todayClasses = asyncHandler(async (req, res) => {
  try {
    const items = await studentAttendanceService.getClassesForFeedback(req);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.mark = asyncHandler(async (req, res) => {
  try {
    const items = await studentAttendanceService.markBulk(req, req.body);
    sendSuccess(res, items, 201);
  } catch (e) { handle(res, e); }
});

exports.studentHistory = asyncHandler(async (req, res) => {
  try {
    const result = await studentAttendanceService.getStudentHistory(req.params.studentId, req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.eligibility = asyncHandler(async (req, res) => {
  try {
    const data = await studentAttendanceService.getEligibility(req.params.studentId, req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
