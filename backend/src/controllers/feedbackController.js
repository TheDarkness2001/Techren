const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const feedbackService = require('../services/feedbackService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await feedbackService.list(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await feedbackService.create(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const filter = { ...getBranchFilter(req) };
    if (req.userType === 'student') {
      filter.student = req.user._id;
    } else if (req.userType === 'parent') {
      filter.student = { $in: (req.user.children || []).map((c) => c._id || c) };
    }
    const item = await feedbackService.getOne(req.params.id, filter);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await feedbackService.update(req, req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.parentComment = asyncHandler(async (req, res) => {
  try {
    const item = await feedbackService.addParentComment(req, req.params.id, req.body.comment);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await feedbackService.remove(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
