const express = require('express');
const { body } = require('express-validator');
const controller = require('../controllers/uploadController');
const { protect, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { docxUpload, imageUpload, audioUpload, ocrUpload } = require('../middleware/fileUpload');

const router = express.Router();
const manageHomework = checkPermission('canManageHomework');

router.use(protect, manageHomework);

router.post('/parse-docx', docxUpload.single('file'), controller.parseDocx);
router.post('/parse-ocr', ocrUpload.single('image'), controller.parseOcr);
router.post(
  '/bulk-import/words',
  body('lessonId').isMongoId(),
  body('pairs').isArray({ min: 1 }),
  body('pairs.*.english').trim().notEmpty(),
  body('pairs.*.uzbek').trim().notEmpty(),
  validate,
  controller.bulkImportWords
);
router.post(
  '/bulk-import/sentences',
  body('lessonId').isMongoId(),
  body('pairs').isArray({ min: 1 }),
  body('pairs.*.english').trim().notEmpty(),
  body('pairs.*.uzbek').trim().notEmpty(),
  body('pairs.*.task').optional({ nullable: true }).isString(),
  body('pairs.*.imageUrl').optional({ nullable: true }).isString(),
  validate,
  controller.bulkImportSentences
);
router.post('/audio', audioUpload.single('audio'), controller.uploadAudio);
router.post('/image', imageUpload.single('image'), controller.uploadImage);

module.exports = router;
