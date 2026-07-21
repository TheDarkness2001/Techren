const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const sentenceService = require('../services/sentenceService');
const learningContentService = require('../services/learningContentService');
const lessonService = require('../services/lessonService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.random = asyncHandler(async (req, res) => {
  try {
    const data = await sentenceService.getRandomSentence(req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.check = asyncHandler(async (req, res) => {
  try {
    const studentId = req.userType === 'student' ? req.user._id : null;
    const data = await sentenceService.checkAnswer(studentId, req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.progress = asyncHandler(async (req, res) => {
  try {
    const studentId = req.userType === 'student' ? req.user._id : req.query.studentId;
    const data = await sentenceService.getProgress(studentId);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const data = await sentenceService.getLeaderboard(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.studentLessons = asyncHandler(async (req, res) => {
  try {
    const data = await sentenceService.getStudentLessonTree(req.user._id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.list = asyncHandler(async (req, res) => {
  try {
    const items = await sentenceService.listSentences(req.query);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await sentenceService.createSentence(req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await sentenceService.updateSentence(req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await sentenceService.removeSentence(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.listLanguages = asyncHandler(async (req, res) => {
  try {
    const items = await learningContentService.listLanguages('sentences');
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.listLevels = asyncHandler(async (req, res) => {
  try {
    const items = await learningContentService.listLevels({ languageId: req.query.languageId, moduleType: 'sentences' });
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.listLessons = asyncHandler(async (req, res) => {
  try {
    const items = await lessonService.listLessons({ levelId: req.query.levelId, type: 'sentences' });
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});
