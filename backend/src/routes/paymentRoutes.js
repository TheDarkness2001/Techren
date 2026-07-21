const express = require('express');
const controller = require('../controllers/paymentController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

const allowViewPayments = (req, res, next) => {
  if (req.userType === 'student') return next();
  return checkPermission('canViewPayments')(req, res, next);
};

router.use(protect);

router.get('/', enforceBranchIsolation, allowViewPayments, paginationRules, validate, controller.list);
router.get('/roster', enforceBranchIsolation, allowViewPayments, validate, controller.roster);
router.post(
  '/',
  enforceBranchIsolation,
  checkPermission('canManagePayments'),
  body('studentId').isMongoId(),
  body('amount').isFloat({ min: 0.01 }),
  body('paymentType').isIn(['tuition-fee', 'exam-fee', 'transport-fee', 'library-fee', 'other']),
  body('subject').trim().notEmpty(),
  body('dueDate').isISO8601(),
  body('academicYear').trim().notEmpty(),
  body('term').isIn(['1st-term', '2nd-term', '3rd-term', 'annual']),
  body('month').isInt({ min: 1, max: 12 }),
  body('year').isInt({ min: 2000 }),
  validate,
  controller.create
);
router.get('/:id', enforceBranchIsolation, allowViewPayments, objectId('id'), validate, controller.getOne);
router.put('/:id', checkPermission('canManagePayments'), objectId('id'), validate, controller.update);
router.delete('/:id', checkPermission('canManagePayments'), objectId('id'), validate, controller.remove);

module.exports = router;
