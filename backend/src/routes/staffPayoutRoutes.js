const express = require('express');
const controller = require('../controllers/staffPayoutController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();
const manageRevenue = checkPermission('canManageRevenue');

const allowStaffSelfOrRevenue = (req, res, next) => {
  if (req.userType === 'teacher') return next();
  return checkPermission('canViewRevenue')(req, res, next);
};

router.use(protect);

router.get('/preview', manageRevenue, controller.preview);
router.get('/', allowStaffSelfOrRevenue, enforceBranchIsolation, paginationRules, validate, controller.list);
router.post(
  '/',
  manageRevenue,
  enforceBranchIsolation,
  body('staffId').isMongoId(),
  body('earningIds').isArray({ min: 1 }),
  body('method').notEmpty(),
  validate,
  controller.create
);
router.patch('/:id/complete', manageRevenue, objectId('id'), validate, controller.complete);
router.patch(
  '/:id/cancel',
  manageRevenue,
  objectId('id'),
  body('reason').isLength({ min: 10 }),
  validate,
  controller.cancel
);

module.exports = router;
