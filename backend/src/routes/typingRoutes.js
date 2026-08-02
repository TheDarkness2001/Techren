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
  body('mode').optional().isIn(['english', 'programming', 'code']),
  body('difficulty').optional().isIn(['easy', 'medium', 'hard', 'expert']),
  body('durationSec').optional().isInt({ min: 0, max: 300 }),
  body('isDaily').optional().isBoolean(),
  body('unlimited').optional().isBoolean(),
  validate,
  controller.start
);

router.post(
  '/finish',
  body('subjectId').isMongoId(),
  body('mode').optional().isIn(['english', 'programming', 'code']),
  body('wpm').isFloat({ min: 0 }),
  body('accuracy').isFloat({ min: 0, max: 100 }),
  validate,
  controller.finish
);

router.get(
  '/leaderboard',
  query('subjectId').isMongoId(),
  query('period').optional().isIn(['all', 'weekly']),
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
