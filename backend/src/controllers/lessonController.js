const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const lessonService = require('../services/lessonService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const items = await lessonService.listLessons({ levelId: req.query.levelId, type: req.query.type || 'words' });
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const item = await lessonService.getLesson(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await lessonService.createLesson(req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await lessonService.updateLesson(req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await lessonService.removeLesson(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.toggleExamLock = asyncHandler(async (req, res) => {
  try {
    const item = await lessonService.toggleExamLock(req.params.id, req.body.groupId, req.body.unlock);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.getExam = asyncHandler(async (req, res) => {
  try {
    const data = await lessonService.getExamWords(req.user._id, req.params.id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.submitExam = asyncHandler(async (req, res) => {
  try {
    const data = await lessonService.submitExam(req.user._id, req.params.id, req.body.answers);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.studentProgress = asyncHandler(async (req, res) => {
  try {
    const progressService = require('../services/progressService');
    const data = await progressService.getLessonStudentProgress(req, req.params.id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
