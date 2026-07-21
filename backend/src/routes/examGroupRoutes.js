const express = require('express');
const examGroupController = require('../controllers/examGroupController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect, enforceBranchIsolation);

router.get('/unified-view', checkPermission('canViewScheduler'), paginationRules, validate, examGroupController.unifiedView);
router.post(
  '/unified',
  checkPermission('canManageScheduler'),
  body('schedule.teacherId').isMongoId(),
  body('schedule.startTime').notEmpty(),
  body('schedule.endTime').notEmpty(),
  validate,
  examGroupController.createUnified
);
router.get('/', checkPermission('canViewScheduler'), paginationRules, validate, examGroupController.list);
router.post(
  '/',
  checkPermission('canManageScheduler'),
  body('groupName').trim().notEmpty(),
  body('subject').isMongoId(),
  validate,
  examGroupController.create
);
router.get('/:id', checkPermission('canViewScheduler'), objectId('id'), validate, examGroupController.getOne);
router.put('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, examGroupController.update);
router.delete('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, examGroupController.remove);
router.post(
  '/:id/students',
  checkPermission('canManageScheduler'),
  objectId('id'),
  body('studentIds').isArray({ min: 1 }),
  validate,
  examGroupController.addStudents
);
router.delete(
  '/:id/students/:studentId',
  checkPermission('canManageScheduler'),
  objectId('id'),
  objectId('studentId'),
  validate,
  examGroupController.removeStudent
);

module.exports = router;
