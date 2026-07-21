const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const gamificationService = require('../services/gamificationService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.profile = asyncHandler(async (req, res) => {
  try {
    const data = await gamificationService.getProfile(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.achievements = asyncHandler(async (req, res) => {
  try {
    const items = await gamificationService.getAchievements(req, req.query);
    sendSuccess(res, { achievements: items });
  } catch (e) {
    handle(res, e);
  }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const items = await gamificationService.getLeaderboard(req, req.query);
    sendSuccess(res, { leaderboard: items });
  } catch (e) {
    handle(res, e);
  }
});

exports.recommendations = asyncHandler(async (req, res) => {
  try {
    const data = await gamificationService.getRecommendations(req, req.query);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});
