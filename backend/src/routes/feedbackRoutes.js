const express = require('express');
const controller = require('../controllers/feedbackController');
const { protect, checkPermission } = require('../middleware/auth');
const { sendError } = require('../utils/apiResponse');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

const allowViewFeedback = (req, res, next) => {
  if (req.userType === 'student' || req.userType === 'parent') return next();
  return checkPermission('canViewFeedback')(req, res, next);
};

router.use(protect);

router.get(
  '/',
  enforceBranchIsolation,
  allowViewFeedback,
  paginationRules,
  validate,
  controller.list
);
router.post(
  '/',
  enforceBranchIsolation,
  checkPermission('canManageFeedback'),
  body('studentId').isMongoId(),
  body('classScheduleId').isMongoId(),
  body('homework').optional().isInt({ min: 0, max: 100 }),
  body('behavior').optional().isInt({ min: 0, max: 100 }),
  body('participation').optional().isInt({ min: 0, max: 100 }),
  validate,
  controller.create
);
router.get('/:id', enforceBranchIsolation, allowViewFeedback, objectId('id'), validate, controller.getOne);
router.put('/:id', checkPermission('canManageFeedback'), objectId('id'), validate, controller.update);
router.put(
  '/:id/parent-comment',
  objectId('id'),
  body('comment').trim().notEmpty(),
  validate,
  (req, res, next) => {
    if (req.userType === 'parent') return next();
    if (req.userType === 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students cannot add parent comments');
    }
    return checkPermission('canManageFeedback')(req, res, next);
  },
  controller.parentComment
);
router.delete('/:id', checkPermission('canManageFeedback'), objectId('id'), validate, controller.remove);

module.exports = router;
