const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const subjectService = require('../services/subjectService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await subjectService.listSubjects(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const item = await subjectService.getSubject(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await subjectService.createSubject({
      ...req.body,
      branchId: req.body.branchId || req.branchId || req.user?.branchId,
    });
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await subjectService.updateSubject(req.params.id, getBranchFilter(req), req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await subjectService.deleteSubject(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.listLearning = asyncHandler(async (req, res) => {
  try {
    const result = await subjectService.listLearningSubjects(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getLearningOne = asyncHandler(async (req, res) => {
  try {
    const item = await subjectService.getLearningSubject(req, req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
