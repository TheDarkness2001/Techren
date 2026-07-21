const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const staffEarningService = require('../services/staffEarningService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await staffEarningService.listEarnings(req, req.query);
    sendSuccess(res, { earnings: result.items }, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.account = asyncHandler(async (req, res) => {
  try {
    const account = await staffEarningService.getAccount(req, req.query);
    sendSuccess(res, { account });
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await staffEarningService.createEarning(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.approve = asyncHandler(async (req, res) => {
  try {
    const item = await staffEarningService.approveEarning(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.bonus = asyncHandler(async (req, res) => {
  try {
    const item = await staffEarningService.addBonus(req, req.params.id, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.penalty = asyncHandler(async (req, res) => {
  try {
    const item = await staffEarningService.addPenalty(req, req.params.id, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.adjustment = asyncHandler(async (req, res) => {
  try {
    const item = await staffEarningService.addAdjustment(req, req.params.id, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.recalculate = asyncHandler(async (req, res) => {
  try {
    const staffId = req.body.staffId || req.params.staffId;
    const account = await staffEarningService.recalculate(req, staffId);
    sendSuccess(res, { account });
  } catch (e) { handle(res, e); }
});
