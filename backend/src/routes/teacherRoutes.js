const express = require('express');
const teacherController = require('../controllers/teacherController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');
const validate = require('../middleware/validate');
const { imageUpload } = require('../middleware/fileUpload');
const {
  paginationRules,
  teacherCreateRules,
  teacherUpdateRules,
  objectId,
} = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect, enforceBranchIsolation);

router.get('/', checkPermission('canViewStudents'), paginationRules, validate, teacherController.list);
router.post('/', checkPermission('canManageStudents'), teacherCreateRules, validate, teacherController.create);
router.get('/:id', checkPermission('canViewStudents'), objectId('id'), validate, teacherController.getOne);
router.put('/:id', checkPermission('canManageStudents'), teacherUpdateRules, validate, teacherController.update);
router.delete('/:id', checkPermission('canManageStudents'), objectId('id'), validate, teacherController.deactivate);
router.put(
  '/:id/permissions',
  checkPermission('canManageSettings'),
  objectId('id'),
  body('permissions').isObject(),
  validate,
  teacherController.updatePermissions
);
router.post(
  '/:id/photo',
  objectId('id'),
  imageUpload.single('photo'),
  (req, res, next) => {
    if (req.userType === 'teacher' && String(req.params.id) === String(req.user._id)) {
      return next();
    }
    return checkPermission('canManageStudents')(req, res, next);
  },
  teacherController.uploadPhoto
);

module.exports = router;
