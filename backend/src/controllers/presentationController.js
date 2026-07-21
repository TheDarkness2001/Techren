const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const presentationService = require('../services/presentationService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await presentationService.recordPresentation(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.byStudent = asyncHandler(async (req, res) => {
  try {
    const data = await presentationService.getStudentPresentations(req, req.params.studentId, req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.monthly = asyncHandler(async (req, res) => {
  try {
    const data = await presentationService.getMonthlyPresentations(req, req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.top = asyncHandler(async (req, res) => {
  try {
    const data = await presentationService.getTopPresenters(req, req.query);
    sendSuccess(res, { leaderboard: data });
  } catch (e) { handle(res, e); }
});
