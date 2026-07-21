const express = require('express');
const studentController = require('../controllers/studentController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { imageUpload } = require('../middleware/fileUpload');
const {
  paginationRules,
  studentCreateRules,
  studentUpdateRules,
  objectId,
} = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get(
  '/',
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  paginationRules,
  validate,
  studentController.list
);
router.post(
  '/',
  enforceBranchIsolation,
  checkPermission('canManageStudents'),
  studentCreateRules,
  validate,
  studentController.create
);
router.get('/:id', objectId('id'), validate, studentController.getOne);
router.get('/:id/dashboard', objectId('id'), validate, studentController.dashboard);
router.put(
  '/:id',
  enforceBranchIsolation,
  checkPermission('canManageStudents'),
  studentUpdateRules,
  validate,
  studentController.update
);
router.patch(
  '/:id/status',
  enforceBranchIsolation,
  checkPermission('canManageStudents'),
  objectId('id'),
  body('status').isIn(['active', 'inactive']),
  validate,
  studentController.setStatus
);
router.post(
  '/:id/photo',
  objectId('id'),
  imageUpload.single('photo'),
  (req, res, next) => {
    if (req.userType === 'student' && String(req.params.id) === String(req.user._id)) return next();
    return enforceBranchIsolation(req, res, () =>
      checkPermission('canManageStudents')(req, res, next)
    );
  },
  studentController.uploadPhoto
);
router.post(
  '/:id/fcm-token',
  objectId('id'),
  body('token').isString().isLength({ min: 10 }),
  validate,
  studentController.registerFcmToken
);
router.get(
  '/:id/notification-settings',
  objectId('id'),
  validate,
  (req, res, next) => {
    if (req.userType === 'student' && String(req.params.id) === String(req.user._id)) return next();
    return checkPermission('canManageStudents')(req, res, next);
  },
  studentController.getNotificationSettings
);
router.put(
  '/:id/notification-settings',
  objectId('id'),
  validate,
  (req, res, next) => {
    if (req.userType === 'student' && String(req.params.id) === String(req.user._id)) return next();
    return checkPermission('canManageStudents')(req, res, next);
  },
  studentController.updateNotificationSettings
);

module.exports = router;
