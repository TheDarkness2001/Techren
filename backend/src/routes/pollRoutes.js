const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/pollController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);

router.post(
  '/',
  body('question').optional().trim(),
  validate,
  controller.createPoll
);

router.put('/:id', objectId('id'), validate, controller.updatePoll);
router.post('/:id/close', objectId('id'), validate, controller.closePoll);
router.post('/:id/reopen', objectId('id'), validate, controller.reopenPoll);
router.post('/:id/duplicate', objectId('id'), validate, controller.duplicatePoll);
router.post('/:id/vote', objectId('id'), validate, controller.vote);
router.get('/:id/results', objectId('id'), validate, controller.getResults);
router.get('/:id/export.csv', objectId('id'), validate, controller.exportResultsCsv);

module.exports = router;
