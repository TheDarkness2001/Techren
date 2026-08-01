const express = require('express');
const controller = require('../controllers/learningQuizController');
const { protect } = require('../middleware/auth');
const { requireStaff } = require('../middleware/roleGuards');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get('/', controller.listQuizzes);
router.get('/history', controller.history);
router.get('/attempts/:id', objectId('id'), validate, controller.getAttempt);
router.post('/attempts/:id/submit', objectId('id'), validate, controller.submitAttempt);

router.get('/:id', objectId('id'), validate, controller.getQuiz);
router.post('/:id/attempts', objectId('id'), validate, controller.startAttempt);

router.post('/', requireStaff, controller.createQuiz);
router.put('/:id', requireStaff, objectId('id'), validate, controller.updateQuiz);
router.delete('/:id', requireStaff, objectId('id'), validate, controller.removeQuiz);
router.post(
  '/:id/unlock',
  requireStaff,
  objectId('id'),
  body('groupId').isMongoId(),
  body('unlock').isBoolean(),
  validate,
  controller.toggleUnlock
);

module.exports = router;
