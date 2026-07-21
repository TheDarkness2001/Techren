const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const examService = require('../services/examService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await examService.list(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const item = await examService.getOne(req.params.id, getBranchFilter(req), req);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await examService.create(req, req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await examService.update(req.params.id, getBranchFilter(req), req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await examService.remove(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.enroll = asyncHandler(async (req, res) => {
  try {
    const result = await examService.enrollFromSchedule(req.params.id, getBranchFilter(req));
    sendSuccess(res, result);
  } catch (e) { handle(res, e); }
});

exports.updateResult = asyncHandler(async (req, res) => {
  try {
    const item = await examService.updateResult(req, req.params.id, req.params.studentId, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.markAbsentFailed = asyncHandler(async (req, res) => {
  try {
    const result = await examService.markAbsentFailed(req.params.id, getBranchFilter(req));
    sendSuccess(res, result);
  } catch (e) { handle(res, e); }
});

exports.addStudent = asyncHandler(async (req, res) => {
  try {
    const item = await examService.addStudent(req.params.id, req.body.studentId, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.removeStudent = asyncHandler(async (req, res) => {
  try {
    const item = await examService.removeStudent(req.params.id, req.params.studentId, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
