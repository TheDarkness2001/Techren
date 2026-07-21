const express = require('express');
const subjectController = require('../controllers/subjectController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect, enforceBranchIsolation);

router.get('/subjects', paginationRules, validate, subjectController.listLearning);
router.get('/subjects/:id', objectId('id'), validate, subjectController.getLearningOne);
router.post(
  '/subjects',
  checkPermission('canManageHomework'),
  body('name').trim().notEmpty(),
  body('code').optional().trim(),
  body('description').optional().trim(),
  body('icon').optional().trim(),
  body('color').optional().trim(),
  body('branchId').optional().isMongoId(),
  body('modules').optional().isArray(),
  validate,
  subjectController.create
);
router.put(
  '/subjects/:id',
  checkPermission('canManageHomework'),
  objectId('id'),
  body('name').optional().trim().notEmpty(),
  body('code').optional().trim(),
  body('description').optional().trim(),
  body('icon').optional().trim(),
  body('color').optional().trim(),
  body('modules').optional().isArray(),
  validate,
  subjectController.update
);
router.delete(
  '/subjects/:id',
  checkPermission('canManageHomework'),
  objectId('id'),
  validate,
  subjectController.remove
);

module.exports = router;
