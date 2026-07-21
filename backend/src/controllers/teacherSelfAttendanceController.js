const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const teacherSelfAttendanceService = require('../services/teacherSelfAttendanceService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const items = await teacherSelfAttendanceService.listOwn(req.user._id, req.query);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.checkIn = asyncHandler(async (req, res) => {
  try {
    const item = await teacherSelfAttendanceService.checkIn(req.user, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.checkOut = asyncHandler(async (req, res) => {
  try {
    const item = await teacherSelfAttendanceService.checkOut(req.user, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.todayStatus = asyncHandler(async (req, res) => {
  try {
    const item = await teacherSelfAttendanceService.getTodayStatus(req.user._id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.roster = asyncHandler(async (req, res) => {
  try {
    const items = await teacherSelfAttendanceService.listRoster(req, req.query);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.markRoster = asyncHandler(async (req, res) => {
  try {
    const item = await teacherSelfAttendanceService.markRoster(req, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
