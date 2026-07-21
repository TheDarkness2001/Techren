const express = require('express');
const controller = require('../controllers/bonusController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { body } = require('express-validator');

const router = express.Router();

const manageBonuses = checkPermission('canManageRevenue');

router.use(protect);

router.get('/calculate', enforceBranchIsolation, manageBonuses, controller.calculate);
router.post(
  '/distribute',
  enforceBranchIsolation,
  manageBonuses,
  body('year').isInt({ min: 2000 }),
  body('month').isInt({ min: 1, max: 12 }),
  body('firstPlaceStudentId').isMongoId(),
  body('secondPlaceStudentId').isMongoId(),
  validate,
  controller.distribute
);
router.get('/history', enforceBranchIsolation, manageBonuses, controller.history);

module.exports = router;
