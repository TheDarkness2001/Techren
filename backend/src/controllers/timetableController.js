const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const timetableService = require('../services/timetableService');

exports.admin = asyncHandler(async (req, res) => {
  try {
    const data = await timetableService.getTimetable(req, 'admin');
    sendSuccess(res, data);
  } catch (e) {
    sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);
  }
});

exports.teacher = asyncHandler(async (req, res) => {
  try {
    const data = await timetableService.getTimetable(req, 'teacher');
    sendSuccess(res, data);
  } catch (e) {
    sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);
  }
});

exports.student = asyncHandler(async (req, res) => {
  try {
    const data = await timetableService.getTimetable(req, 'student');
    sendSuccess(res, data);
  } catch (e) {
    sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);
  }
});
