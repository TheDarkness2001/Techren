const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const branchService = require('../services/branchService');

const handleServiceError = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await branchService.listBranches(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const branch = await branchService.getBranch(req, req.params.id);
    sendSuccess(res, branch);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const branch = await branchService.createBranch(req, req.body);
    sendSuccess(res, branch, 201);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const branch = await branchService.updateBranch(req, req.params.id, req.body);
    sendSuccess(res, branch);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.setStatus = asyncHandler(async (req, res) => {
  try {
    const branch = await branchService.setBranchStatus(req.params.id, req.body.isActive);
    sendSuccess(res, branch);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.stats = asyncHandler(async (req, res) => {
  try {
    const stats = await branchService.getBranchStats(req.params.id);
    sendSuccess(res, stats);
  } catch (error) {
    handleServiceError(res, error);
  }
});
