const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const examGroupService = require('../services/examGroupService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await examGroupService.listExamGroups(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const item = await examGroupService.getExamGroup(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await examGroupService.createExamGroup({
      ...req.body,
      branchId: req.body.branchId || req.branchId,
    });
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await examGroupService.updateExamGroup(req.params.id, getBranchFilter(req), req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await examGroupService.deleteExamGroup(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.addStudents = asyncHandler(async (req, res) => {
  try {
    const group = await examGroupService.addStudentsToGroup(req.params.id, req.body.studentIds || []);
    sendSuccess(res, examGroupService.formatGroup(group));
  } catch (e) { handle(res, e); }
});

exports.removeStudent = asyncHandler(async (req, res) => {
  try {
    const group = await examGroupService.removeStudentFromGroup(req.params.id, req.params.studentId);
    sendSuccess(res, examGroupService.formatGroup(group));
  } catch (e) { handle(res, e); }
});

exports.unifiedView = asyncHandler(async (req, res) => {
  try {
    const result = await examGroupService.getUnifiedView(req, req.query);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.createUnified = asyncHandler(async (req, res) => {
  try {
    const result = await examGroupService.createUnified({
      ...req.body,
      branchId: req.body.branchId || req.branchId,
    });
    sendSuccess(res, result, 201);
  } catch (e) { handle(res, e); }
});
