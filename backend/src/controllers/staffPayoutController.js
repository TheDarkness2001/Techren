const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const staffPayoutService = require('../services/staffPayoutService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await staffPayoutService.listPayouts(req, req.query);
    sendSuccess(res, { payouts: result.items }, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.preview = asyncHandler(async (req, res) => {
  try {
    const earningIds = req.query.earningIds
      ? String(req.query.earningIds).split(',')
      : req.body?.earningIds;
    const data = await staffPayoutService.previewPayout(req, {
      staffId: req.query.staffId || req.body?.staffId,
      earningIds,
    });
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await staffPayoutService.createPayout(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.complete = asyncHandler(async (req, res) => {
  try {
    const item = await staffPayoutService.completePayout(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.cancel = asyncHandler(async (req, res) => {
  try {
    const item = await staffPayoutService.cancelPayout(req, req.params.id, req.body.reason);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
