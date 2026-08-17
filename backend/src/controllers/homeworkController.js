const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const homeworkService = require('../services/homeworkService');
const wordsPracticeService = require('../services/wordsPracticeService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.randomWord = asyncHandler(async (req, res) => {
  try {
    const data = await homeworkService.getRandomWord({
      ...req.query,
      studentId: req.userType === 'student' ? req.user._id : null,
    });
    sendSuccess(res, { word: data });
  } catch (e) { handle(res, e); }
});

exports.checkAnswer = asyncHandler(async (req, res) => {
  try {
    const data = await homeworkService.checkAnswer(req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.submitResult = asyncHandler(async (req, res) => {
  try {
    const data = await homeworkService.submitResult(req.user._id, req.body.sessionStats);
    sendSuccess(res, { progress: data });
  } catch (e) { handle(res, e); }
});

exports.progress = asyncHandler(async (req, res) => {
  try {
    const studentId = req.userType === 'student' ? req.user._id : req.query.studentId;
    const data = await homeworkService.getProgress(studentId);
    sendSuccess(res, { progress: data });
  } catch (e) { handle(res, e); }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const data = await homeworkService.getLeaderboard(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.listWords = asyncHandler(async (req, res) => {
  try {
    const items = await homeworkService.listWords(req.query.lessonId);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.addWord = asyncHandler(async (req, res) => {
  try {
    const item = await homeworkService.addWord(req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.updateWord = asyncHandler(async (req, res) => {
  try {
    const item = await homeworkService.updateWord(req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.removeWord = asyncHandler(async (req, res) => {
  try {
    const item = await homeworkService.removeWord(req.params.id, req);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.studentLessons = asyncHandler(async (req, res) => {
  try {
    const lessonService = require('../services/lessonService');
    const items = await lessonService.getStudentLessonTree(req.user._id);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.practiceStats = asyncHandler(async (req, res) => {
  try {
    const lessonService = require('../services/lessonService');
    const data = await lessonService.updatePracticeStats(req.user._id, req.body.lessonId, req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.practiceNext = asyncHandler(async (req, res) => {
  try {
    const data = await wordsPracticeService.nextQuestion(req.user._id, {
      lessonId: req.body.lessonId,
      mode: req.body.mode,
      direction: req.body.direction,
      rushStep: req.body.rushStep,
      userType: req.userType,
    });
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.practiceAnswer = asyncHandler(async (req, res) => {
  try {
    const data = await wordsPracticeService.submitAnswer(req.user._id, req.body, { userType: req.userType });
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.practiceOverview = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendSuccess(res, { accuracy: 0, correctAnswers: 0, totalAttempts: 0 });
    }
    const data = await wordsPracticeService.getPracticeStats(req.user._id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
