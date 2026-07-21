const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const listeningService = require('../services/listeningService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const includeScript = req.userType !== 'student';
    const items = await listeningService.listExercises(req.query, { includeScript });
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.random = asyncHandler(async (req, res) => {
  try {
    const item = await listeningService.getRandomExercise(req.query);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await listeningService.createExercise(req.body, req.file);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await listeningService.updateExercise(req.params.id, req.body, req.file);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await listeningService.removeExercise(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.check = asyncHandler(async (req, res) => {
  try {
    const studentId = req.userType === 'student' ? req.user._id : null;
    const data = await listeningService.checkAnswer(studentId, req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.progress = asyncHandler(async (req, res) => {
  try {
    const studentId = req.userType === 'student' ? req.user._id : req.query.studentId;
    const data = await listeningService.getProgress(studentId);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const data = await listeningService.getLeaderboard(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.studentLevels = asyncHandler(async (req, res) => {
  try {
    const data = await listeningService.getStudentLevelTree(req.user._id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.signedUrl = asyncHandler(async (req, res) => {
  try {
    await listeningService.getAudioStreamMeta(req.params.id);
    const token = listeningService.createAudioAccessToken(req.user._id, req.params.id);
    sendSuccess(res, {
      url: `/api/v1/listening/exercises/${req.params.id}/audio?token=${token}`,
      expiresIn: 900,
    });
  } catch (e) { handle(res, e); }
});

exports.streamAudio = asyncHandler(async (req, res) => {
  try {
    const exercise = await listeningService.getAudioStreamMeta(req.params.id);
    const audio = listeningService.resolveAudioPath(exercise.audioFile);
    if (audio.remote) return res.redirect(302, audio.url);
    res.setHeader('Content-Type', audio.mimeType);
    res.setHeader('Accept-Ranges', 'bytes');
    return res.sendFile(audio.path);
  } catch (e) { handle(res, e); }
});
