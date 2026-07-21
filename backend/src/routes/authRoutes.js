const express = require('express');
const rateLimit = require('express-rate-limit');
const config = require('../config');
const authController = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { loginRules, refreshRules } = require('../validators/authValidators');

const router = express.Router();

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: config.isDev ? 100 : 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMIT', message: 'Too many login attempts. Please wait a few minutes.' } },
});

const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: config.isDev ? 300 : 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMIT', message: 'Too many refresh attempts. Please wait.' } },
});

router.post('/login', loginLimiter, loginRules, validate, authController.login);
router.post('/teacher/login', loginLimiter, loginRules, validate, authController.teacherLogin);
router.post('/student/login', loginLimiter, loginRules, validate, authController.studentLogin);
router.post('/parent/login', loginLimiter, loginRules, validate, authController.parentLogin);
router.post('/refresh', refreshLimiter, refreshRules, validate, authController.refresh);
router.post('/logout', authController.logout);
router.get('/me', protect, authController.getMe);

module.exports = router;
