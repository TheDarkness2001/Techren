const express = require('express');
const controller = require('../controllers/listeningController');
const { protect, checkPermission } = require('../middleware/auth');
const { upload } = require('../middleware/audioUpload');
const validate = require('../middleware/validate');
const { objectId } = require('../validators/commonValidators');
const { body } = require('express-validator');
const { sendError } = require('../utils/apiResponse');
const listeningService = require('../services/listeningService');

const router = express.Router();
const manageHomework = checkPermission('canManageHomework');

const streamAuth = async (req, res, next) => {
  try {
    if (req.headers.authorization?.startsWith('Bearer ')) {
      return protect(req, res, next);
    }
    const token = req.query.token;
    if (!token) {
      return sendError(res, 401, 'UNAUTHORIZED', 'Authentication required for audio stream');
    }
    listeningService.verifyAudioAccessToken(token, req.params.id);
    next();
  } catch (error) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Invalid or expired audio token');
  }
};

router.get('/exercises/:id/audio', streamAuth, objectId('id'), validate, controller.streamAudio);
router.get('/exercises/:id/signed-url', protect, objectId('id'), validate, controller.signedUrl);

router.use(protect);

router.get('/random', controller.random);
router.post('/check', body('listeningId').isMongoId(), validate, controller.check);
router.get('/progress', controller.progress);
router.get('/leaderboard', controller.leaderboard);
router.get('/student-levels', (req, res, next) => {
  if (req.userType !== 'student') {
    return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Students only' } });
  }
  next();
}, controller.studentLevels);

router.get('/exercises', controller.list);
router.post('/exercises', manageHomework, upload.single('audio'), controller.create);
router.put('/exercises/:id', manageHomework, objectId('id'), upload.single('audio'), validate, controller.update);
router.delete('/exercises/:id', manageHomework, objectId('id'), validate, controller.remove);

router.get('/languages', async (req, res, next) => {
  req.query.moduleType = 'listening';
  const learningContentService = require('../services/learningContentService');
  try {
    const items = await learningContentService.listLanguages('listening');
    res.json({ success: true, data: items });
  } catch (e) { next(e); }
});

module.exports = router;
