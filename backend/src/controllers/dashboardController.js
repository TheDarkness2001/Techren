const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const dashboardService = require('../services/dashboardService');

exports.get = asyncHandler(async (req, res) => {
  try {
    const data = await dashboardService.getDashboard(req);
    sendSuccess(res, data);
  } catch (error) {
    sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);
  }
});
