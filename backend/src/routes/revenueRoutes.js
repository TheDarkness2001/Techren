const express = require('express');
const controller = require('../controllers/revenueController');
const { protect, checkPermission } = require('../middleware/auth');
const enforceBranchIsolation = require('../middleware/branchIsolation');

const router = express.Router();

router.use(protect);
router.use(enforceBranchIsolation);
router.use(checkPermission('canViewRevenue'));

router.get('/summary', controller.summary);
router.get('/pending', controller.pending);
router.get('/chart', controller.chart);
router.get('/export', controller.exportData);

module.exports = router;
