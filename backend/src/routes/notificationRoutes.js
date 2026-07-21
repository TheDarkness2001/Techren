const express = require('express');
const controller = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);

router.get('/', paginationRules, validate, controller.list);
router.patch('/read-all', controller.markAllRead);
router.patch('/:id/read', objectId('id'), validate, controller.markRead);

module.exports = router;
