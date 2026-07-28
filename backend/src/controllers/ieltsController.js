const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const ieltsAccessService = require('../services/ieltsAccessService');
const ieltsExamService = require('../services/ieltsExamService');
const ieltsAttemptService = require('../services/ieltsAttemptService');
const path = require('path');
const fs = require('fs');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

// —— Access (founder) ——
exports.setIeltsAccess = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAccessService.setStudentAccess(req.params.id, req.body.enabled);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.bulkIeltsAccess = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAccessService.bulkSetAccess(req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.listIeltsAccess = asyncHandler(async (req, res) => {
  try {
    const result = await ieltsAccessService.listWithAccess(req.query);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

// —— Exams CMS ——
exports.listExams = asyncHandler(async (req, res) => {
  try {
    const publishedOnly = req.userType === 'student';
    const items = await ieltsExamService.listExams({
      subjectId: req.query.subjectId,
      mode: req.query.mode,
      publishedOnly,
    });
    sendSuccess(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.getExam = asyncHandler(async (req, res) => {
  try {
    const includeAnswers = req.userType !== 'student';
    const data = await ieltsExamService.getExam(req.params.id, {
      includeAnswers,
      includeAudioPath: req.userType !== 'student',
    });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createExam = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.createExam(req.body, req.user._id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateExam = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.updateExam(req.params.id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeExam = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.removeExam(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createSection = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.createSection(req.params.examId, req.body, req.file);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateSection = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.updateSection(req.params.id, req.body, req.file);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeSection = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.removeSection(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createQuestion = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.createQuestion(req.params.sectionId, req.body);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateQuestion = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.updateQuestion(req.params.id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeQuestion = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.removeQuestion(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.streamSectionAudio = asyncHandler(async (req, res) => {
  try {
    const { filePath } = await ieltsExamService.resolveAudioPath(req.params.id);
    const ext = path.extname(filePath).toLowerCase();
    const types = { '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.m4a': 'audio/mp4' };
    res.setHeader('Content-Type', types[ext] || 'application/octet-stream');
    fs.createReadStream(filePath).pipe(res);
  } catch (e) {
    handle(res, e);
  }
});

// —— Attempts ——
exports.startAttempt = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.startAttempt(req.user._id, req.params.examId);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.getAttempt = asyncHandler(async (req, res) => {
  try {
    const asStaff = req.userType === 'teacher';
    const data = await ieltsAttemptService.getAttempt(req.params.id, req.user._id, { asStaff });
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.autosave = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.autosave(req.params.id, req.user._id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.submitAttempt = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.submitAttempt(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.history = asyncHandler(async (req, res) => {
  try {
    const result = await ieltsAttemptService.listHistory(req.user._id, req.query);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.writingQueue = asyncHandler(async (req, res) => {
  try {
    const result = await ieltsAttemptService.listWritingQueue(req.query);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.reviewWriting = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.upsertWritingReview(req.params.attemptId, req.user._id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});
