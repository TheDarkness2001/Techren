const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const paymentService = require('../services/paymentService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await paymentService.list(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.roster = asyncHandler(async (req, res) => {
  try {
    const result = await paymentService.listRoster(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const filter = { ...getBranchFilter(req) };
    if (req.userType === 'student') {
      filter.student = req.user._id;
    }
    const item = await paymentService.getOne(req.params.id, filter);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await paymentService.create(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await paymentService.update(req.params.id, getBranchFilter(req), req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await paymentService.remove(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
