const express = require('express');
const videoController = require('../controllers/videoLessonController');
const testController = require('../controllers/topicTestController');
const { protect, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');

const router = express.Router();
const manageHomework = checkPermission('canManageHomework');

router.use(protect);

router.get('/', videoController.list);
router.post('/', manageHomework, videoController.create);
router.get('/:id', objectId('id'), validate, videoController.getById);
router.put('/:id', manageHomework, objectId('id'), validate, videoController.update);
router.delete('/:id', manageHomework, objectId('id'), validate, videoController.remove);

router.post('/:id/track', objectId('id'), validate, videoController.track);
router.post('/:id/complete', objectId('id'), validate, videoController.complete);
router.patch('/:id/toggle-watch-unlock', manageHomework, objectId('id'), validate, videoController.toggleWatchUnlock);

router.get('/:id/test', objectId('id'), validate, testController.getTest);
router.put('/:id/test', manageHomework, objectId('id'), validate, testController.upsertTest);
router.delete('/:id/test', manageHomework, objectId('id'), validate, testController.deleteTest);
router.post('/:id/test/attempt', objectId('id'), validate, testController.submitAttempt);
router.post('/:id/test/warning', objectId('id'), validate, testController.recordWarning);
router.get('/:id/test/leaderboard', objectId('id'), validate, testController.leaderboard);

module.exports = router;
