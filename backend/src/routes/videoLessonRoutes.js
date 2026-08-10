const express = require('express');
const videoController = require('../controllers/videoLessonController');
const testController = require('../controllers/topicTestController');
const { protect } = require('../middleware/auth');
const { editHomework, deleteHomework } = require('../middleware/homeworkAccess');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');

const router = express.Router();

router.use(protect);

router.get('/', videoController.list);
router.get('/tree', videoController.ensureTree);
router.post('/levels', editHomework, videoController.createLevel);
router.post('/', editHomework, videoController.create);
router.get('/:id', objectId('id'), validate, videoController.getById);
router.put('/:id', editHomework, objectId('id'), validate, videoController.update);
router.delete('/:id', deleteHomework, objectId('id'), validate, videoController.remove);

router.post('/:id/track', objectId('id'), validate, videoController.track);
router.post('/:id/complete', objectId('id'), validate, videoController.complete);
router.patch('/:id/toggle-watch-unlock', editHomework, objectId('id'), validate, videoController.toggleWatchUnlock);

router.get('/:id/test', objectId('id'), validate, testController.getTest);
router.put('/:id/test', editHomework, objectId('id'), validate, testController.upsertTest);
router.delete('/:id/test', deleteHomework, objectId('id'), validate, testController.deleteTest);
router.post('/:id/test/attempt', objectId('id'), validate, testController.submitAttempt);
router.post('/:id/test/warning', objectId('id'), validate, testController.recordWarning);
router.get('/:id/test/leaderboard', objectId('id'), validate, testController.leaderboard);

module.exports = router;
