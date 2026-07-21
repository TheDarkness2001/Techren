const express = require('express');
const controller = require('../controllers/presentationController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();
const manageCompetition = checkPermission('canManageFeedback');

router.use(protect);

router.post(
  '/',
  enforceBranchIsolation,
  manageCompetition,
  body('studentId').isMongoId(),
  body('score').isInt({ min: 1, max: 10 }),
  validate,
  controller.create
);
router.get('/student/:studentId', objectId('studentId'), validate, controller.byStudent);
router.get('/monthly', enforceBranchIsolation, manageCompetition, controller.monthly);
router.get('/top', enforceBranchIsolation, controller.top);

module.exports = router;
