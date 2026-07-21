const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/teacherSelfAttendanceController');
const { protect, checkPermission } = require('../middleware/auth');
const { requireStaff } = require('../middleware/roleGuards');
const validate = require('../middleware/validate');

const router = express.Router();

router.use(protect, requireStaff);

router.get('/roster', checkPermission('canViewAttendance'), controller.roster);
router.post(
  '/roster/mark',
  checkPermission('canManageAttendance'),
  body('teacherId').isMongoId(),
  body('dailyStatus').isIn(['present', 'absent', 'late']),
  body('date').optional().isString(),
  body('notes').optional().isString(),
  validate,
  controller.markRoster
);

router.get('/', controller.list);
router.get('/today-status', controller.todayStatus);
router.post('/check-in', controller.checkIn);
router.post('/check-out', controller.checkOut);

module.exports = router;
