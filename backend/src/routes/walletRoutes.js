const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/walletController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { paginationRules } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);

router.get('/balance', controller.balance);
router.get('/transactions', paginationRules, validate, controller.transactions);
router.post(
  '/topup',
  body('studentId').isMongoId(),
  body('amountSom').optional().isFloat({ min: 10000 }),
  body('amount').optional().isFloat({ min: 10000 }),
  body().custom((_, { req }) => {
    if (req.body.amountSom == null && req.body.amount == null) {
      throw new Error('amountSom or amount is required');
    }
    return true;
  }),
  validate,
  controller.topup
);
router.post(
  '/deduct',
  body('studentId').isMongoId(),
  body('amountSom').optional().isFloat({ min: 0.01 }),
  body('amountTyiyn').optional().isInt({ min: 1 }),
  body('type').optional().isIn(['deduction', 'penalty', 'adjustment', 'topup', 'refund']),
  body('description').optional().isString(),
  body().custom((_, { req }) => {
    if (req.body.amountSom == null && req.body.amountTyiyn == null && req.body.amount == null) {
      throw new Error('amountSom or amountTyiyn is required');
    }
    return true;
  }),
  validate,
  controller.deduct
);

module.exports = router;
