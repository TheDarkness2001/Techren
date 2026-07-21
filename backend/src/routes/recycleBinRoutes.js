const express = require('express');
const controller = require('../controllers/recycleBinController');
const { protect, isPlatformAdmin } = require('../middleware/auth');
const { sendError } = require('../utils/apiResponse');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);
router.use((req, res, next) => {
  // Managers are intentionally excluded — recycle bin is platform-admin only.
  if (req.userType !== 'teacher' || !isPlatformAdmin(req.user)) {
    return sendError(res, 403, 'FORBIDDEN', 'Admin access required');
  }
  next();
});

router.get('/', paginationRules, validate, controller.list);
router.post(
  '/purge-all',
  body('olderThanDays').optional().isInt({ min: 1 }),
  validate,
  controller.purgeAll
);
router.get('/:id/snapshots', objectId('id'), validate, controller.snapshots);
router.post('/:id/restore', objectId('id'), validate, controller.restore);
router.post('/:id/purge', objectId('id'), validate, controller.purge);
router.patch('/:id/toggle-important', objectId('id'), validate, controller.toggleImportant);

module.exports = router;
