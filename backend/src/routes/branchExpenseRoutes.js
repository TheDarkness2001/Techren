const express = require('express');
const controller = require('../controllers/branchExpenseController');
const { protect } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);
router.use(enforceBranchIsolation);

router.get('/', paginationRules, validate, controller.list);
router.post(
  '/',
  body('category').isIn(['teacher-payment', 'rent', 'electricity', 'repair', 'other']),
  body('amount').isFloat({ min: 0.01 }),
  body('month').isInt({ min: 1, max: 12 }),
  body('year').isInt({ min: 2000 }),
  body('branchId').optional().isMongoId(),
  body('teacherId').optional({ nullable: true, checkFalsy: true }).isMongoId(),
  body('notes').optional().trim(),
  body('teacherName').optional().trim(),
  body('spentAt').optional().isISO8601(),
  validate,
  controller.create
);
router.put(
  '/:id',
  objectId('id'),
  body('category').optional().isIn(['teacher-payment', 'rent', 'electricity', 'repair', 'other']),
  body('amount').optional().isFloat({ min: 0.01 }),
  body('teacherId').optional({ nullable: true, checkFalsy: true }).isMongoId(),
  body('notes').optional().trim(),
  body('teacherName').optional().trim(),
  body('spentAt').optional().isISO8601(),
  validate,
  controller.update
);
router.delete('/:id', objectId('id'), validate, controller.remove);

module.exports = router;
