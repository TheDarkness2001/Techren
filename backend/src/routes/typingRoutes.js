const express = require('express');
const controller = require('../controllers/typingController');
const { protect } = require('../middleware/auth');
const { requireStaff } = require('../middleware/roleGuards');
const validate = require('../middleware/validate');
const { body, query } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get(
  '/dashboard',
  query('subjectId').isMongoId(),
  validate,
  controller.dashboard
);

router.post(
  '/start',
  body('subjectId').isMongoId(),
  body('mode').optional().isIn(['english', 'uzbek', 'programming', 'code']),
  body('difficulty').optional().isIn(['easy', 'medium', 'hard', 'expert']),
  body('durationSec').optional().isInt({ min: 0, max: 300 }).toInt(),
  body('isDaily').optional().isBoolean().toBoolean(),
  body('unlimited').optional().isBoolean().toBoolean(),
  validate,
  controller.start
);

router.post(
  '/finish',
  body('subjectId').isMongoId(),
  body('mode').optional().isIn(['english', 'uzbek', 'programming', 'code']),
  body('wpm').isFloat({ min: 0 }).toFloat(),
  body('accuracy').isFloat({ min: 0, max: 100 }).toFloat(),
  validate,
  controller.finish
);

router.get(
  '/leaderboard',
  query('subjectId').isMongoId(),
  query('period').optional().isIn(['all', 'weekly']),
  query('durationSec').optional().toInt().isIn([15, 30, 60]),
  query('minAccuracy').optional().isFloat({ min: 0, max: 100 }).toFloat(),
  validate,
  controller.leaderboard
);

router.get(
  '/daily',
  query('subjectId').isMongoId(),
  validate,
  controller.daily
);

router.get(
  '/history',
  query('subjectId').isMongoId(),
  validate,
  controller.history
);

router.get('/content', requireStaff, controller.listContent);

module.exports = router;
