const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const progressService = require('../services/progressService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.overview = asyncHandler(async (req, res) => {
  try {
    const data = await progressService.getOverview(req, req.query.studentId);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.students = asyncHandler(async (req, res) => {
  try {
    const data = await progressService.listStudentsProgress(req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.group = asyncHandler(async (req, res) => {
  try {
    const data = await progressService.getGroupProgress(req, req.params.groupId);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.lessonStudents = asyncHandler(async (req, res) => {
  try {
    const data = await progressService.getLessonStudentProgress(req, req.params.id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.studentVocabLessons = asyncHandler(async (req, res) => {
  try {
    const data = await progressService.getStudentVocabLessonDetails(req, req.params.studentId);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});
