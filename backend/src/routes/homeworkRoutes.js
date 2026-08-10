const express = require('express');
const homeworkController = require('../controllers/homeworkController');
const learningController = require('../controllers/learningContentController');
const lessonController = require('../controllers/lessonController');
const { protect } = require('../middleware/auth');
const { editHomework, deleteHomework, requireOwnedGroup } = require('../middleware/homeworkAccess');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');

const router = express.Router();

router.use(protect);

router.get('/words/random', homeworkController.randomWord);
router.post(
  '/check-answer',
  body('wordId').isMongoId(),
  body('direction').isIn(['en-to-uz', 'uz-to-en']),
  validate,
  homeworkController.checkAnswer
);
router.post('/submit-result', homeworkController.submitResult);
router.get('/progress', homeworkController.progress);
router.get('/leaderboard', homeworkController.leaderboard);
router.get('/student-lessons', (req, res, next) => {
  if (req.userType !== 'student') {
    return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Students only' } });
  }
  next();
}, homeworkController.studentLessons);
router.post(
  '/practice-stats',
  body('lessonId').isMongoId(),
  validate,
  homeworkController.practiceStats
);

router.get('/words', editHomework, homeworkController.listWords);
router.post(
  '/words',
  editHomework,
  body('english').trim().notEmpty(),
  body('uzbek').trim().notEmpty(),
  body('lessonId').isMongoId(),
  validate,
  homeworkController.addWord
);
router.put('/words/:id', editHomework, objectId('id'), validate, homeworkController.updateWord);
router.delete('/words/:id', deleteHomework, objectId('id'), validate, homeworkController.removeWord);

router.get('/languages', learningController.listLanguages);
router.post('/languages', editHomework, body('name').trim().notEmpty(), body('moduleType').optional().isIn(['words', 'sentences', 'listening', 'video']), validate, learningController.createLanguage);
router.put('/languages/:id', editHomework, objectId('id'), validate, learningController.updateLanguage);
router.delete('/languages/:id', deleteHomework, objectId('id'), validate, learningController.removeLanguage);

router.get('/levels', learningController.listLevels);
router.post('/levels', editHomework, body('name').trim().notEmpty(), body('languageId').isMongoId(), validate, learningController.createLevel);
router.put('/levels/:id', editHomework, objectId('id'), validate, learningController.updateLevel);
router.delete('/levels/:id', deleteHomework, objectId('id'), validate, learningController.removeLevel);
router.post(
  '/levels/:id/practice-unlock',
  editHomework,
  requireOwnedGroup,
  objectId('id'),
  body('groupId').isMongoId(),
  body('unlock').isBoolean(),
  validate,
  learningController.togglePracticeUnlock
);
router.post(
  '/levels/:id/unlock-all',
  editHomework,
  requireOwnedGroup,
  objectId('id'),
  body('groupId').isMongoId(),
  body('unlock').isBoolean(),
  validate,
  learningController.bulkUnlockLevel
);
router.post(
  '/unlock-all',
  editHomework,
  requireOwnedGroup,
  body('languageId').isMongoId(),
  body('groupId').isMongoId(),
  body('unlock').isBoolean(),
  body('moduleType').optional().isIn(['words', 'sentences', 'listening', 'video']),
  body('includeExam').optional().isBoolean(),
  validate,
  learningController.bulkUnlockForGroup
);

router.get('/lessons', lessonController.list);
router.post('/lessons', editHomework, body('name').trim().notEmpty(), body('levelId').isMongoId(), validate, lessonController.create);
router.get('/lessons/:id/exam', lessonController.getExam);
router.post('/lessons/:id/exam', body('answers').isArray({ min: 1 }), validate, lessonController.submitExam);
router.post(
  '/lessons/:id/toggle-exam-lock',
  editHomework,
  requireOwnedGroup,
  objectId('id'),
  body('groupId').isMongoId(),
  body('unlock').isBoolean(),
  validate,
  lessonController.toggleExamLock
);
router.get('/lessons/:id', objectId('id'), validate, lessonController.getOne);
router.get('/lessons/:id/student-progress', editHomework, objectId('id'), validate, lessonController.studentProgress);
router.put('/lessons/:id', editHomework, objectId('id'), validate, lessonController.update);
router.delete('/lessons/:id', deleteHomework, objectId('id'), validate, lessonController.remove);

module.exports = router;
