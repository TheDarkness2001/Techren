const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/parentController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);
router.use(controller.requireParent);

router.get('/children', controller.children);
router.get('/children/:studentId/overview', objectId('studentId'), validate, controller.overview);
router.get('/children/:studentId/feedback', objectId('studentId'), paginationRules, validate, controller.feedback);
router.get('/children/:studentId/attendance', objectId('studentId'), paginationRules, validate, controller.attendance);
router.get('/children/:studentId/exams', objectId('studentId'), paginationRules, validate, controller.exams);
router.get('/children/:studentId/payments', objectId('studentId'), validate, controller.payments);
router.get('/children/:studentId/alerts', objectId('studentId'), validate, controller.alerts);
router.get('/children/:studentId/homework', objectId('studentId'), validate, controller.homework);
router.get('/children/:studentId/schedule', objectId('studentId'), validate, controller.schedule);
router.post(
  '/children/:studentId/attendance/:attendanceId/excuse',
  objectId('studentId'),
  objectId('attendanceId'),
  body('reason').isString().trim().isLength({ min: 3, max: 2000 }),
  validate,
  controller.submitExcuse
);

module.exports = router;
