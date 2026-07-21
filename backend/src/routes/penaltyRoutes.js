const express = require('express');
const controller = require('../controllers/penaltyController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();
const manageCompetition = checkPermission('canManageFeedback');

const allowStudentOrStaff = (req, res, next) => {
  if (req.userType === 'student') return next();
  return manageCompetition(req, res, next);
};

router.use(protect);

router.get('/types', controller.types);
router.get('/monthly', enforceBranchIsolation, manageCompetition, paginationRules, validate, controller.monthly);
router.post(
  '/',
  enforceBranchIsolation,
  manageCompetition,
  body('studentId').isMongoId(),
  body('type').notEmpty(),
  body('points').isNumeric(),
  validate,
  controller.create
);
router.get('/student/:studentId', objectId('studentId'), validate, controller.byStudent);
router.get('/group/:groupId', enforceBranchIsolation, manageCompetition, objectId('groupId'), validate, controller.byGroup);
router.post('/:id/revert', enforceBranchIsolation, manageCompetition, objectId('id'), validate, controller.revert);

module.exports = router;
