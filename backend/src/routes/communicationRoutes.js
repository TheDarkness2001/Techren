const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/communicationController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { communicationsUpload } = require('../middleware/fileUpload');

const router = express.Router();

router.use(protect);

router.get('/conversations', controller.listConversations);
router.post(
  '/conversations/private',
  body('targetUserId').optional().isMongoId(),
  body('userId').optional().isMongoId(),
  validate,
  controller.createPrivate
);
router.post('/conversations/support', controller.createSupport);
router.post(
  '/broadcasts',
  body('title').optional().trim(),
  body('body').optional().trim(),
  validate,
  controller.createBroadcast
);
router.get('/directory', controller.directory);
router.get('/unread', controller.unreadTotal);
router.get('/search', controller.searchMessages);
router.get('/moderation', controller.moderationInbox);
router.post('/messages/:messageId/moderate', objectId('messageId'), validate, controller.moderateMessage);
router.get('/presence/:userType/:userId', objectId('userId'), validate, controller.getPresence);
router.patch('/messages/:messageId', objectId('messageId'), validate, controller.updateMessage);
router.post('/messages/:messageId/react', objectId('messageId'), validate, controller.reactToMessage);
router.post('/messages/:messageId/star', objectId('messageId'), validate, controller.starMessage);
router.post('/messages/:messageId/forward', objectId('messageId'), validate, controller.forwardMessage);

router.get('/subjects', controller.listSubjectOptions);
router.post(
  '/conversations/subject',
  body('subjectId').optional().isMongoId(),
  validate,
  controller.createSubjectRoom
);

router.get('/conversations/:id', objectId('id'), validate, controller.getConversation);
router.get('/conversations/:id/messages', objectId('id'), validate, controller.listMessages);
router.post(
  '/conversations/:id/messages',
  objectId('id'),
  validate,
  communicationsUpload.single('file'),
  controller.sendMessage
);
router.patch('/conversations/:id/read', objectId('id'), validate, controller.markRead);
router.patch('/conversations/:id', objectId('id'), validate, controller.togglePinMute);
router.post('/conversations/:id/pin-message', objectId('id'), validate, controller.pinMessage);
router.post('/conversations/:id/poll', objectId('id'), validate, controller.createChatPoll);
router.post('/conversations/:id/call', objectId('id'), validate, controller.signalCall);

module.exports = router;
