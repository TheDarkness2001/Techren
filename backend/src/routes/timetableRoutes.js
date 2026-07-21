const express = require('express');
const timetableController = require('../controllers/timetableController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');

const router = express.Router();

router.use(protect);

router.get(
  '/admin',
  enforceBranchIsolation,
  checkPermission('canViewTimetable'),
  timetableController.admin
);
router.get('/teacher', timetableController.teacher);
router.get('/student', timetableController.student);

module.exports = router;
