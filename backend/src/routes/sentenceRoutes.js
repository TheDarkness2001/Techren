const express = require('express');
const controller = require('../controllers/sentenceController');
const { protect, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();
const manageHomework = checkPermission('canManageHomework');

router.use(protect);

router.get('/random', controller.random);
router.post(
  '/check',
  body('sentenceId').isMongoId(),
  body('answer').trim().notEmpty(),
  validate,
  controller.check
);
router.get('/progress', controller.progress);
router.get('/leaderboard', controller.leaderboard);
router.get('/student-lessons', (req, res, next) => {
  if (req.userType !== 'student') {
    return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Students only' } });
  }
  next();
}, controller.studentLessons);

router.get('/languages', controller.listLanguages);
router.get('/levels', controller.listLevels);
router.get('/lessons', controller.listLessons);

router.get('/', controller.list);
router.post(
  '/',
  manageHomework,
  body('english').trim().notEmpty(),
  body('uzbek').trim().notEmpty(),
  body('lessonId').isMongoId(),
  validate,
  controller.create
);
router.put('/:id', manageHomework, objectId('id'), validate, controller.update);
router.delete('/:id', manageHomework, objectId('id'), validate, controller.remove);

module.exports = router;
