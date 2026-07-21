const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const penaltyService = require('../services/penaltyService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await penaltyService.createPenalty(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.byStudent = asyncHandler(async (req, res) => {
  try {
    const data = await penaltyService.getStudentPenalties(req, req.params.studentId, req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.byGroup = asyncHandler(async (req, res) => {
  try {
    const data = await penaltyService.getGroupPenalties(req, req.params.groupId, req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.monthly = asyncHandler(async (req, res) => {
  try {
    const result = await penaltyService.getMonthlyPenalties(req, req.query);
    sendSuccess(res, { penalties: result.items, total: result.total }, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.revert = asyncHandler(async (req, res) => {
  try {
    const item = await penaltyService.revertPenalty(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.types = asyncHandler(async (req, res) => {
  sendSuccess(res, { types: penaltyService.PENALTY_TYPES });
});
