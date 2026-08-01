const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const learningQuizService = require('../services/learningQuizService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.listQuizzes = asyncHandler(async (req, res) => {
  try {
    const items = await learningQuizService.listQuizzes({
      subjectId: req.query.subjectId,
      level: req.query.level,
      topic: req.query.topic,
      userType: req.userType,
      studentId: req.userType === 'student' ? req.user._id : null,
    });
    sendSuccess(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.getQuiz = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.getQuiz(req.params.id, {
      userType: req.userType,
      studentId: req.userType === 'student' ? req.user._id : null,
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createQuiz = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.createQuiz(req.body, req.user._id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateQuiz = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.updateQuiz(req.params.id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeQuiz = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.removeQuiz(req.params.id, {
      deletedBy: String(req.user._id),
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.toggleUnlock = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.toggleUnlock(req.params.id, {
      groupId: req.body.groupId,
      unlock: !!req.body.unlock,
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.startAttempt = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Only students can start quiz attempts');
    }
    const data = await learningQuizService.startAttempt({
      quizId: req.params.id,
      studentId: req.user._id,
    });
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.submitAttempt = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Only students can submit quiz attempts');
    }
    const data = await learningQuizService.submitAttempt({
      attemptId: req.params.id,
      studentId: req.user._id,
      answers: req.body.answers,
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.getAttempt = asyncHandler(async (req, res) => {
  try {
    const data = await learningQuizService.getAttempt({
      attemptId: req.params.id,
      userType: req.userType,
      userId: req.user._id,
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.history = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'History is for students');
    }
    const items = await learningQuizService.history({
      studentId: req.user._id,
      subjectId: req.query.subjectId,
    });
    sendSuccess(res, items);
  } catch (e) {
    handle(res, e);
  }
});
