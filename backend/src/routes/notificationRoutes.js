const express = require('express');
const controller = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get('/', paginationRules, validate, controller.list);
router.patch('/read-all', controller.markAllRead);

router.post(
  '/device-token',
  body('token').isString().isLength({ min: 10 }),
  body('platform').optional().isIn(['android', 'ios', 'web', 'unknown']),
  body('deviceId').optional().isString(),
  body('previousToken').optional().isString(),
  validate,
  controller.registerDeviceToken
);
router.put(
  '/device-token',
  body('token').isString().isLength({ min: 10 }),
  body('previousToken').optional().isString(),
  body('oldToken').optional().isString(),
  body('platform').optional().isIn(['android', 'ios', 'web', 'unknown']),
  body('deviceId').optional().isString(),
  validate,
  controller.refreshDeviceToken
);
router.delete(
  '/device-token',
  body('token').isString().isLength({ min: 10 }),
  validate,
  controller.removeDeviceToken
);

router.get('/settings/me', controller.getMySettings);
router.put('/settings/me', controller.updateMySettings);

router.patch('/:id/read', objectId('id'), validate, controller.markRead);

module.exports = router;
