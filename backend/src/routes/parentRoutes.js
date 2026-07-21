const express = require('express');
const controller = require('../controllers/parentController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId, paginationRules } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);
router.use(controller.requireParent);

router.get('/children', controller.children);
router.get('/children/:studentId/overview', objectId('studentId'), validate, controller.overview);
router.get('/children/:studentId/feedback', objectId('studentId'), paginationRules, validate, controller.feedback);
router.get('/children/:studentId/attendance', objectId('studentId'), paginationRules, validate, controller.attendance);
router.get('/children/:studentId/exams', objectId('studentId'), paginationRules, validate, controller.exams);

module.exports = router;
