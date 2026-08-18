const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const branchExpenseService = require('../services/branchExpenseService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await branchExpenseService.list(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await branchExpenseService.create(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await branchExpenseService.update(req, req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await branchExpenseService.remove(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
