const express = require('express');
const controller = require('../controllers/progressController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { paginationRules, objectId } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);

router.get('/overview', controller.overview);
router.get(
  '/students',
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  paginationRules,
  validate,
  controller.students
);
router.get(
  '/students/:studentId/vocab-lessons',
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  objectId('studentId'),
  validate,
  controller.studentVocabLessons
);
router.get(
  '/groups/:groupId',
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  objectId('groupId'),
  validate,
  controller.group
);

module.exports = router;
