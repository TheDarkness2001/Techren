const express = require('express');
const controller = require('../controllers/ieltsController');
const { protect } = require('../middleware/auth');
const { requireFounder, requireStaff } = require('../middleware/roleGuards');
const { requireIeltsAccess } = require('../middleware/ieltsAccess');
const { upload } = require('../middleware/ieltsAudioUpload');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');
const { sendError } = require('../utils/apiResponse');
const ieltsExamService = require('../services/ieltsExamService');

const router = express.Router();

const streamAuth = async (req, res, next) => {
  try {
    if (req.headers.authorization?.startsWith('Bearer ')) {
      return protect(req, res, () => requireIeltsAccess(req, res, next));
    }
    const token = req.query.token;
    if (!token) {
      return sendError(res, 401, 'UNAUTHORIZED', 'Authentication required for audio stream');
    }
    ieltsExamService.verifyAudioAccessToken(token, req.params.id);
    next();
  } catch (error) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Invalid or expired audio token');
  }
};

router.get('/sections/:id/audio', streamAuth, objectId('id'), validate, controller.streamSectionAudio);

router.use(protect);

// Founder access management
router.get('/access', requireFounder, controller.listIeltsAccess);
router.post(
  '/access/bulk',
  requireFounder,
  body('enabled').isBoolean(),
  validate,
  controller.bulkIeltsAccess
);
router.patch(
  '/access/:id',
  requireFounder,
  objectId('id'),
  body('enabled').isBoolean(),
  validate,
  controller.setIeltsAccess
);

// Exam listing (students need access)
router.get('/exams', requireIeltsAccess, controller.listExams);
router.get('/exams/:id', requireIeltsAccess, objectId('id'), validate, controller.getExam);

// Staff CMS
router.post('/exams', requireStaff, controller.createExam);
router.post('/exams/import', requireStaff, controller.importExamJson);
router.put('/exams/:id', requireStaff, objectId('id'), validate, controller.updateExam);
router.delete('/exams/:id', requireStaff, objectId('id'), validate, controller.removeExam);
router.post('/exams/:id/duplicate', requireStaff, objectId('id'), validate, controller.duplicateExam);
router.get('/exams/:id/export', requireStaff, objectId('id'), validate, controller.exportExamJson);
router.get('/exams/:id/export.csv', requireStaff, objectId('id'), validate, controller.exportExamCsv);
router.get('/exams/:examId/analytics/difficulty', requireStaff, objectId('examId'), validate, controller.examDifficultyAnalytics);

router.post(
  '/exams/:examId/sections',
  requireStaff,
  objectId('examId'),
  upload.single('audio'),
  validate,
  controller.createSection
);
router.put(
  '/sections/:id',
  requireStaff,
  objectId('id'),
  upload.single('audio'),
  validate,
  controller.updateSection
);
router.delete('/sections/:id', requireStaff, objectId('id'), validate, controller.removeSection);
router.post('/sections/:id/duplicate', requireStaff, objectId('id'), validate, controller.duplicateSection);
router.get('/sections/:id/signed-url', requireIeltsAccess, objectId('id'), validate, controller.signedSectionAudio);

router.post(
  '/sections/:sectionId/questions',
  requireStaff,
  objectId('sectionId'),
  validate,
  controller.createQuestion
);
router.post(
  '/sections/:sectionId/questions/from-bank',
  requireStaff,
  objectId('sectionId'),
  body('versionId').notEmpty(),
  validate,
  controller.addBankToSection
);
router.put('/questions/:id', requireStaff, objectId('id'), validate, controller.updateQuestion);
router.delete('/questions/:id', requireStaff, objectId('id'), validate, controller.removeQuestion);
router.post(
  '/questions/:questionId/to-bank',
  requireStaff,
  objectId('questionId'),
  validate,
  controller.importQuestionToBank
);

// Sources CMS
router.get('/sources/meta', requireStaff, controller.sourceMeta);
router.get('/sources', requireStaff, controller.listSources);
router.get('/sources/:id', requireStaff, objectId('id'), validate, controller.getSource);
router.post('/sources', requireStaff, controller.createSource);
router.put('/sources/:id', requireStaff, objectId('id'), validate, controller.updateSource);
router.delete('/sources/:id', requireStaff, objectId('id'), validate, controller.removeSource);

// Question bank
router.get('/bank', requireStaff, controller.listBank);
router.get('/bank/:id', requireStaff, objectId('id'), validate, controller.getBankItem);
router.post('/bank', requireStaff, controller.createBankItem);
router.put('/bank/:id', requireStaff, objectId('id'), validate, controller.updateBankItem);
router.post('/bank/:id/versions', requireStaff, objectId('id'), validate, controller.publishBankVersion);
router.delete('/bank/:id', requireStaff, objectId('id'), validate, controller.removeBankItem);

// Analytics
router.get('/analytics/staff', requireStaff, controller.staffAnalytics);
router.get('/analytics/me', requireIeltsAccess, controller.studentAnalytics);

// Student attempts
router.post('/exams/:examId/attempts', requireIeltsAccess, objectId('examId'), validate, controller.startAttempt);
router.get('/attempts/history', requireIeltsAccess, controller.history);
router.get('/attempts/:id', requireIeltsAccess, objectId('id'), validate, controller.getAttempt);
router.patch('/attempts/:id/autosave', requireIeltsAccess, objectId('id'), validate, controller.autosave);
router.post('/attempts/:id/submit', requireIeltsAccess, objectId('id'), validate, controller.submitAttempt);

// Teacher writing review
router.get('/writing-queue', requireStaff, controller.writingQueue);
router.put(
  '/attempts/:attemptId/writing-review',
  requireStaff,
  objectId('attemptId'),
  body('taskAchievement').isFloat({ min: 0, max: 9 }),
  body('coherenceCohesion').isFloat({ min: 0, max: 9 }),
  body('lexicalResource').isFloat({ min: 0, max: 9 }),
  body('grammaticalRange').isFloat({ min: 0, max: 9 }),
  validate,
  controller.reviewWriting
);

module.exports = router;
