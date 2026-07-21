const express = require('express');
const controller = require('../controllers/gamificationController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

router.get('/profile', controller.profile);
router.get('/achievements', controller.achievements);
router.get('/leaderboard', controller.leaderboard);
router.get('/recommendations', controller.recommendations);

module.exports = router;
