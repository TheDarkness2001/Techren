const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/newsController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { newsUpload } = require('../middleware/fileUpload');

const router = express.Router();

router.use(protect);

router.get('/categories', controller.listCategories);
router.get('/feed', controller.listFeed);
router.get('/admin', controller.listAdmin);
router.post('/upload', newsUpload.single('file'), controller.upload);
router.post('/link-preview', controller.fetchLinkPreview);

router.post(
  '/',
  body('title').optional().trim(),
  validate,
  controller.createPost
);

router.get('/:id', objectId('id'), validate, controller.getPost);
router.put('/:id', objectId('id'), validate, controller.updatePost);
router.delete('/:id', objectId('id'), validate, controller.deletePost);

router.post('/:id/publish', objectId('id'), validate, controller.publishPost);
router.post('/:id/unpublish', objectId('id'), validate, controller.unpublishPost);
router.post('/:id/pin', objectId('id'), validate, controller.pinPost);
router.post('/:id/archive', objectId('id'), validate, controller.archivePost);
router.post('/:id/duplicate', objectId('id'), validate, controller.duplicatePost);

router.post('/:id/react', objectId('id'), validate, controller.react);
router.delete('/:id/react', objectId('id'), validate, controller.unreact);

router.get('/:id/comments', objectId('id'), validate, controller.listComments);
router.post('/:id/comments', objectId('id'), validate, controller.addComment);
router.post('/:id/view', objectId('id'), validate, controller.recordView);
router.post('/:id/click', objectId('id'), validate, controller.recordClick);
router.post('/:id/register', objectId('id'), validate, controller.registerForEvent);

module.exports = router;
