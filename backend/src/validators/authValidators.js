const { body } = require('express-validator');

const loginRules = [
  body('email')
      .isEmail()
      .withMessage('Valid email is required')
      .normalizeEmail({ gmail_remove_dots: false, gmail_remove_subaddress: false }),
  body('password').notEmpty().withMessage('Password is required'),
  body('userType').optional().isIn(['auto', 'teacher', 'student', 'parent']),
];

const refreshRules = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
];

module.exports = { loginRules, refreshRules };
