const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const videoLessonService = require('../services/videoLessonService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

const ctx = (req) => ({ userType: req.userType, userId: req.user?._id });

exports.list = asyncHandler(async (req, res) => {
  try {
    const items = await videoLessonService.listVideoLessons(req.query, ctx(req));
    sendSuccess(res, { videoLessons: items });
  } catch (e) { handle(res, e); }
});

exports.getById = asyncHandler(async (req, res) => {
  try {
    const data = await videoLessonService.getVideoLessonById(req.params.id, ctx(req));
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await videoLessonService.createVideoLesson(req.body, req.user?._id);
    sendSuccess(res, { videoLesson: item }, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await videoLessonService.updateVideoLesson(req.params.id, req.body);
    sendSuccess(res, { videoLesson: item });
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await videoLessonService.softDeleteVideoLesson(req.params.id);
    sendSuccess(res, { videoLesson: item });
  } catch (e) { handle(res, e); }
});

exports.track = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students only');
    }
    const progress = await videoLessonService.trackWatchProgress(req.user._id, req.params.id, req.body);
    sendSuccess(res, { progress });
  } catch (e) { handle(res, e); }
});

exports.complete = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students only');
    }
    const progress = await videoLessonService.markAsCompleted(req.user._id, req.params.id);
    sendSuccess(res, { progress });
  } catch (e) { handle(res, e); }
});

exports.toggleWatchUnlock = asyncHandler(async (req, res) => {
  try {
    const data = await videoLessonService.toggleWatchUnlock(req.params.id, req.body.groupId);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
