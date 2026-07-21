const express = require('express');
const branchController = require('../controllers/branchController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const { requireFounder } = require('../middleware/roleGuards');
const validate = require('../middleware/validate');
const {
  paginationRules,
  branchCreateRules,
  branchUpdateRules,
  objectId,
} = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get('/', paginationRules, validate, branchController.list);
router.post('/', requireFounder, branchCreateRules, validate, branchController.create);
router.get('/:id', objectId('id'), validate, branchController.getOne);
router.put('/:id', requireFounder, branchUpdateRules, validate, branchController.update);
router.patch(
  '/:id/status',
  requireFounder,
  objectId('id'),
  body('isActive').isBoolean(),
  validate,
  branchController.setStatus
);
router.get(
  '/:id/stats',
  objectId('id'),
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  validate,
  branchController.stats
);

module.exports = router;
