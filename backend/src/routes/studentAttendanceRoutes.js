const express = require('express');
const controller = require('../controllers/studentAttendanceController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get(
  '/today-classes',
  checkPermission('canManageAttendance'),
  controller.todayClasses
);
router.post(
  '/mark',
  enforceBranchIsolation,
  checkPermission('canManageAttendance'),
  body('classScheduleId').isMongoId(),
  body('records').isArray({ min: 1 }),
  body('records.*.studentId').isMongoId(),
  body('records.*.status').isIn(['present', 'absent', 'late', 'excused']),
  validate,
  controller.mark
);
router.get(
  '/',
  enforceBranchIsolation,
  checkPermission('canViewAttendance'),
  paginationRules,
  validate,
  controller.list
);
router.get('/student/:studentId', objectId('studentId'), validate, controller.studentHistory);
router.get('/eligibility/:studentId', objectId('studentId'), validate, controller.eligibility);

module.exports = router;
