const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const ieltsAccessService = require('../services/ieltsAccessService');
const ieltsExamService = require('../services/ieltsExamService');
const ieltsAttemptService = require('../services/ieltsAttemptService');
const ieltsSourceService = require('../services/ieltsSourceService');
const ieltsQuestionBankService = require('../services/ieltsQuestionBankService');
const ieltsAnalyticsService = require('../services/ieltsAnalyticsService');
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
      includeArchived: req.query.includeArchived === 'true' && req.userType !== 'student',
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

exports.signedSectionAudio = asyncHandler(async (req, res) => {
  try {
    await ieltsExamService.resolveAudioPath(req.params.id);
    const token = ieltsExamService.createAudioAccessToken(req.user._id, req.params.id);
    sendSuccess(res, { url: `/api/v1/ielts/sections/${req.params.id}/audio?token=${token}` });
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

exports.advanceSkill = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.advanceSkill(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.uploadSpeaking = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.uploadSpeakingRecording(
      req.params.id,
      req.user._id,
      req.params.sectionId,
      req.file,
      { durationSec: req.body?.durationSec }
    );
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.streamSpeakingAudio = asyncHandler(async (req, res) => {
  try {
    const asStaff = req.userType === 'teacher';
    const { filePath } = await ieltsAttemptService.resolveSpeakingRecordingPath(
      req.params.id,
      req.params.sectionId,
      req.user._id,
      { asStaff }
    );
    const ext = path.extname(filePath).toLowerCase();
    const type =
      ext === '.mp3'
        ? 'audio/mpeg'
        : ext === '.wav'
          ? 'audio/wav'
          : ext === '.m4a'
            ? 'audio/mp4'
            : 'audio/webm';
    res.setHeader('Content-Type', type);
    fs.createReadStream(filePath).pipe(res);
  } catch (e) {
    handle(res, e);
  }
});

exports.speakingQueue = asyncHandler(async (req, res) => {
  try {
    const result = await ieltsAttemptService.listSpeakingQueue(req.query);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.reviewSpeaking = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAttemptService.upsertSpeakingReview(req.params.attemptId, req.user._id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

// —— Sources ——
exports.listSources = asyncHandler(async (req, res) => {
  try {
    const items = await ieltsSourceService.listSources(req.query);
    sendSuccess(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.getSource = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsSourceService.getSource(req.params.id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createSource = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsSourceService.createSource(req.body, req.user._id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateSource = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsSourceService.updateSource(req.params.id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeSource = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsSourceService.removeSource(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.sourceMeta = asyncHandler(async (req, res) => {
  sendSuccess(res, {
    topics: ieltsSourceService.TOPICS,
    difficulties: ieltsSourceService.DIFFICULTIES,
  });
});

// —— Question bank ——
exports.listBank = asyncHandler(async (req, res) => {
  try {
    const items = await ieltsQuestionBankService.listBank(req.query);
    sendSuccess(res, items);
  } catch (e) {
    handle(res, e);
  }
});

exports.getBankItem = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.getBankItem(req.params.id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.createBankItem = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.createBankItem(req.body, req.user._id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updateBankItem = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.updateBankItemMeta(req.params.id, req.body);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.publishBankVersion = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.publishNewVersion(req.params.id, req.body, req.user._id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.removeBankItem = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.removeBankItem(req.params.id, req.user._id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.addBankToSection = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.addVersionToSection(
      req.params.sectionId,
      req.body.versionId,
      req.body
    );
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.importQuestionToBank = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsQuestionBankService.importQuestionToBank(
      req.params.questionId,
      req.body,
      req.user._id
    );
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

// —— Analytics ——
exports.staffAnalytics = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAnalyticsService.staffOverview(req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.studentAnalytics = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAnalyticsService.studentAnalytics(req.user._id, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.examDifficultyAnalytics = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsAnalyticsService.examQuestionDifficulty(req.params.examId);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

// —— Admin ops ——
exports.duplicateExam = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.duplicateExam(req.params.id, req.user._id, req.body);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.duplicateSection = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.duplicateSection(req.params.id);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.exportExamJson = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.exportExamJson(req.params.id);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.exportExamCsv = asyncHandler(async (req, res) => {
  try {
    const csv = await ieltsExamService.exportExamCsvRows(req.params.id);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="ielts-exam-${req.params.id}.csv"`);
    res.status(200).send(csv);
  } catch (e) {
    handle(res, e);
  }
});

exports.importExamJson = asyncHandler(async (req, res) => {
  try {
    const data = await ieltsExamService.importExamJson(req.body, req.user._id, {
      subjectId: req.body.subjectId || req.query.subjectId,
    });
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});
