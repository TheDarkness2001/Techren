const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const topicTestService = require('../services/topicTestService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

const isStaff = (req) => req.userType === 'teacher';

exports.getTest = asyncHandler(async (req, res) => {
  try {
    const data = await topicTestService.getTopicTest(req.params.id, {
      userType: req.userType,
      userId: req.user?._id,
      mode: req.query.mode,
      isStaff: isStaff(req),
    });
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.upsertTest = asyncHandler(async (req, res) => {
  try {
    const test = await topicTestService.upsertTopicTest(req.params.id, req.body);
    sendSuccess(res, { test });
  } catch (e) { handle(res, e); }
});

exports.deleteTest = asyncHandler(async (req, res) => {
  try {
    const data = await topicTestService.deleteTopicTest(req.params.id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.submitAttempt = asyncHandler(async (req, res) => {
  try {
    if (req.userType !== 'student') {
      return sendError(res, 403, 'FORBIDDEN', 'Students only');
    }
    const data = await topicTestService.submitTestAttempt(req.params.id, req.user._id, req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.recordWarning = asyncHandler(async (req, res) => {
  try {
    const data = await topicTestService.recordAntiCheatWarning(req.params.id, req.body.warnings || 0);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.leaderboard = asyncHandler(async (req, res) => {
  try {
    const data = await topicTestService.getTestLeaderboard(req.params.id);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
