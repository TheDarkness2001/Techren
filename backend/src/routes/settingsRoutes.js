const express = require('express');
const settingsController = require('../controllers/settingsController');
const { protect, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { body } = require('express-validator');

const router = express.Router();

const manageSettings = checkPermission('canManageSettings');

// Any authenticated user may read flags + role matrix (needed for shells/route guards).
router.get('/', protect, settingsController.get);
router.get('/features/:flag', protect, settingsController.getFeature);

// Mutations stay admin-gated.
router.put(
  '/',
  protect,
  manageSettings,
  body('featureFlags').optional().isObject(),
  validate,
  settingsController.update
);
router.get('/permissions', protect, manageSettings, settingsController.getPermissions);
router.put(
  '/permissions',
  protect,
  manageSettings,
  body().isObject(),
  validate,
  settingsController.updatePermissions
);

module.exports = router;
