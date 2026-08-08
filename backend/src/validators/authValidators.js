const { body } = require('express-validator');

const loginRules = [
  // Accept username or email via `identifier` (preferred) or legacy `email`.
  body('identifier')
    .optional()
    .isString()
    .trim()
    .notEmpty()
    .withMessage('Username or email is required'),
  body('email')
    .optional()
    .isString()
    .trim()
    .notEmpty()
    .withMessage('Username or email is required'),
  body().custom((_, { req }) => {
    const id = (req.body.identifier || req.body.email || '').toString().trim();
    if (!id) {
      throw new Error('Username or email is required');
    }
    req.body.identifier = id;
    return true;
  }),
  body('password').notEmpty().withMessage('Password is required'),
  body('userType').optional().isIn(['auto', 'teacher', 'student', 'parent']),
];

const refreshRules = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
];

module.exports = { loginRules, refreshRules };
