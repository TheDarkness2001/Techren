const express = require('express');
const controller = require('../controllers/ieltsController');
const { protect } = require('../middleware/auth');
const { requireFounder, requireStaff } = require('../middleware/roleGuards');
const { requireIeltsAccess } = require('../middleware/ieltsAccess');
const { upload } = require('../middleware/ieltsAudioUpload');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

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

// Staff CMS — any staff (founder/admin/teacher); access grant stays founder-only
router.post('/exams', requireStaff, controller.createExam);
router.put('/exams/:id', requireStaff, objectId('id'), validate, controller.updateExam);
router.delete('/exams/:id', requireStaff, objectId('id'), validate, controller.removeExam);

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
router.get('/sections/:id/audio', requireIeltsAccess, objectId('id'), validate, controller.streamSectionAudio);

router.post(
  '/sections/:sectionId/questions',
  requireStaff,
  objectId('sectionId'),
  validate,
  controller.createQuestion
);
router.put('/questions/:id', requireStaff, objectId('id'), validate, controller.updateQuestion);
router.delete('/questions/:id', requireStaff, objectId('id'), validate, controller.removeQuestion);

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
