const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const revenueService = require('../services/revenueService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.summary = asyncHandler(async (req, res) => {
  try {
    const data = await revenueService.getSummary(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.pending = asyncHandler(async (req, res) => {
  try {
    const data = await revenueService.getPending(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.chart = asyncHandler(async (req, res) => {
  try {
    const data = await revenueService.getChart(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});

exports.exportData = asyncHandler(async (req, res) => {
  try {
    const data = await revenueService.getExport(req);
    sendSuccess(res, data);
  } catch (e) { handle(res, e); }
});
