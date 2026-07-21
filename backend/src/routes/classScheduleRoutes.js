const express = require('express');
const classScheduleController = require('../controllers/classScheduleController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect, enforceBranchIsolation);

router.get('/conflicts', checkPermission('canViewScheduler'), classScheduleController.conflicts);
router.post(
  '/from-group',
  checkPermission('canManageScheduler'),
  body('groupId').isMongoId(),
  body('teacherId').isMongoId(),
  body('startTime').notEmpty(),
  body('endTime').notEmpty(),
  validate,
  classScheduleController.createFromGroup
);
router.get('/', checkPermission('canViewScheduler'), paginationRules, validate, classScheduleController.list);
router.post(
  '/',
  checkPermission('canManageScheduler'),
  body('className').trim().notEmpty(),
  body('teacher').isMongoId(),
  body('startTime').notEmpty(),
  body('endTime').notEmpty(),
  validate,
  classScheduleController.create
);
router.get('/:id', checkPermission('canViewScheduler'), objectId('id'), validate, classScheduleController.getOne);
router.put('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, classScheduleController.update);
router.delete('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, classScheduleController.remove);
router.post(
  '/:id/sync-students',
  checkPermission('canManageScheduler'),
  objectId('id'),
  validate,
  classScheduleController.syncStudents
);

module.exports = router;
