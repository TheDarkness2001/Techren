const express = require('express');
const subjectController = require('../controllers/subjectController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect, enforceBranchIsolation);

router.get('/', checkPermission('canViewScheduler'), paginationRules, validate, subjectController.list);
router.post(
  '/',
  checkPermission('canManageScheduler'),
  body('name').trim().notEmpty(),
  body('pricePerClass').optional().isNumeric(),
  validate,
  subjectController.create
);
router.get('/:id', checkPermission('canViewScheduler'), objectId('id'), validate, subjectController.getOne);
router.put('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, subjectController.update);
router.delete('/:id', checkPermission('canManageScheduler'), objectId('id'), validate, subjectController.remove);

module.exports = router;
