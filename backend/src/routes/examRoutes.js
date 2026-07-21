const express = require('express');
const controller = require('../controllers/examController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

const allowViewExams = (req, res, next) => {
  if (req.userType === 'student') return next();
  return checkPermission('canViewExams')(req, res, next);
};

router.use(protect);

router.get('/', enforceBranchIsolation, allowViewExams, paginationRules, validate, controller.list);
router.post(
  '/',
  enforceBranchIsolation,
  checkPermission('canManageExams'),
  body('examName').trim().notEmpty(),
  body('subject').optional().trim().notEmpty(),
  body('class').optional().trim().notEmpty(),
  body('examDate').isISO8601(),
  body('startTime').optional().trim().notEmpty(),
  body('duration').isInt({ min: 1 }),
  body('totalMarks').isInt({ min: 1 }),
  body('passingMarks').isInt({ min: 0 }),
  body('scheduleId').optional().isMongoId(),
  body('subjectGroup').optional().isMongoId(),
  body('groupId').optional().isMongoId(),
  body().custom((_, { req }) => {
    if (!req.body.subjectGroup && !req.body.groupId && !req.body.scheduleId) {
      if (!req.body.subject || !req.body.class) {
        throw new Error('Provide subjectGroup (or scheduleId) with subject and class');
      }
    }
    return true;
  }),
  validate,
  controller.create
);
router.get('/:id', enforceBranchIsolation, allowViewExams, objectId('id'), validate, controller.getOne);
router.put('/:id', checkPermission('canManageExams'), objectId('id'), validate, controller.update);
router.delete('/:id', checkPermission('canManageExams'), objectId('id'), validate, controller.remove);
router.post('/:id/enroll', checkPermission('canManageExams'), objectId('id'), validate, controller.enroll);
router.put(
  '/:id/results/:studentId',
  checkPermission('canManageExams'),
  objectId('id'),
  objectId('studentId'),
  body('marksObtained').isInt({ min: 0 }),
  validate,
  controller.updateResult
);
router.post('/:id/mark-absent-failed', checkPermission('canManageExams'), objectId('id'), validate, controller.markAbsentFailed);
router.post(
  '/:id/students',
  checkPermission('canManageExams'),
  objectId('id'),
  body('studentId').isMongoId(),
  validate,
  controller.addStudent
);
router.delete(
  '/:id/students/:studentId',
  checkPermission('canManageExams'),
  objectId('id'),
  objectId('studentId'),
  validate,
  controller.removeStudent
);

module.exports = router;
