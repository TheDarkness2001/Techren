const express = require('express');
const controller = require('../controllers/staffEarningController');
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

router.get('/account', allowStaffSelfOrRevenue, controller.account);
router.get('/', allowStaffSelfOrRevenue, enforceBranchIsolation, paginationRules, validate, controller.list);

router.post('/recalculate', manageRevenue, enforceBranchIsolation, body('staffId').isMongoId(), validate, controller.recalculate);
router.post(
  '/',
  manageRevenue,
  enforceBranchIsolation,
  body('staffId').isMongoId(),
  body('amount').isNumeric(),
  validate,
  controller.create
);
router.patch('/:id/approve', manageRevenue, objectId('id'), validate, controller.approve);
router.post(
  '/:id/bonus',
  manageRevenue,
  objectId('id'),
  body('amount').isNumeric(),
  body('reason').isLength({ min: 10 }),
  validate,
  controller.bonus
);
router.post(
  '/:id/penalty',
  manageRevenue,
  objectId('id'),
  body('amount').isNumeric(),
  body('reason').isLength({ min: 10 }),
  validate,
  controller.penalty
);
router.post(
  '/:id/adjustment',
  manageRevenue,
  objectId('id'),
  body('amount').isNumeric(),
  body('direction').isIn(['credit', 'debit']),
  body('reason').isLength({ min: 10 }),
  validate,
  controller.adjustment
);

module.exports = router;
