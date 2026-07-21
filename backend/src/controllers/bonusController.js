const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const bonusService = require('../services/bonusService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.calculate = asyncHandler(async (req, res) => {
  try {
    const data = await bonusService.calculateMonthlyBonuses(req, req.query);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.distribute = asyncHandler(async (req, res) => {
  try {
    const data = await bonusService.distributeBonuses(req, req.body);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.history = asyncHandler(async (req, res) => {
  try {
    const data = await bonusService.getBonusHistory(req, req.query);
    sendSuccess(res, { periods: data });
  } catch (e) { handle(res, e); }
});
