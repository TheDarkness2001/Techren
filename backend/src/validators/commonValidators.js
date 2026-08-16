const { body, param, query } = require('express-validator');

const objectId = (field, location = 'param') => {
  const chain = location === 'param' ? param(field) : query(field);
  return chain.isMongoId().withMessage(`Invalid ${field}`);
};

const paginationRules = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 500 }).toInt(),
  query('search').optional().isString().trim(),
  query('sortOrder').optional().isIn(['asc', 'desc']),
];

const branchCreateRules = [
  body('name').trim().notEmpty().withMessage('Branch name is required'),
  body('address').optional().trim(),
  body('phone').optional().trim(),
];

const branchUpdateRules = [
  param('id').isMongoId(),
  body('name').optional().trim().notEmpty(),
  body('address').optional().trim(),
  body('phone').optional().trim(),
];

const teacherCreateRules = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('phone').optional().trim(),
  body('role').optional().isIn(['admin', 'teacher', 'sales', 'receptionist', 'manager']),
  body('subject').optional().isArray(),
  body('branchId').optional().isMongoId(),
];

const teacherUpdateRules = [
  param('id').isMongoId(),
  body('name').optional().trim().notEmpty(),
  body('email').optional().isEmail().normalizeEmail(),
  body('password').optional().isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('phone').optional().trim(),
  body('role').optional().isIn(['admin', 'teacher', 'sales', 'receptionist', 'manager']),
  body('subject').optional().isArray(),
  body('status').optional().isIn(['active', 'inactive']),
];

const studentCreateRules = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('studentId').trim().notEmpty().withMessage('Student ID is required'),
  body('parentName').optional().trim(),
  body('parentPhone').optional().trim(),
  body('coursePrice').optional().isFloat({ min: 0 }),
  body('branchId').optional().isMongoId(),
  body('address').optional().trim(),
  body('phone').optional().trim(),
  body('gender').optional().isIn(['male', 'female', 'other', '']),
  body('bloodGroup').optional().trim(),
  body('medicalConditions').optional().trim(),
  body('status').optional().isIn(['active', 'inactive', 'graduated']),
];

const studentUpdateRules = [
  param('id').isMongoId(),
  body('name').optional().trim().notEmpty(),
  body('email').optional().isEmail().normalizeEmail(),
  body('studentId').optional().trim().notEmpty().withMessage('Student ID cannot be empty'),
  // Empty string = "keep current password" — do not run min-length on blanks.
  body('password')
    .optional({ values: 'falsy' })
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters'),
  body('parentName').optional().trim(),
  body('parentPhone').optional().trim(),
  body('coursePrice').optional().isFloat({ min: 0 }),
  body('status').optional().isIn(['active', 'inactive', 'graduated']),
  body('address').optional().trim(),
  body('phone').optional().trim(),
  body('gender').optional().isIn(['male', 'female', 'other', '']),
  body('bloodGroup').optional().trim(),
  body('medicalConditions').optional().trim(),
  body('parentAccount').optional().isObject(),
  body('parentAccount.username')
    .optional({ values: 'falsy' })
    .matches(/^[a-z0-9._-]{3,40}$/)
    .withMessage('Parent username must be 3–40 characters (letters, numbers, . _ -)'),
  body('parentAccount.password')
    .optional({ values: 'falsy' })
    .isLength({ min: 4 })
    .withMessage('Parent password must be at least 4 characters'),
];

module.exports = {
  objectId,
  paginationRules,
  branchCreateRules,
  branchUpdateRules,
  teacherCreateRules,
  teacherUpdateRules,
  studentCreateRules,
  studentUpdateRules,
};
