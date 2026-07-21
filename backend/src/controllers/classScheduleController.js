const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const classScheduleService = require('../services/classScheduleService');
const { getBranchFilter } = require('../utils/branchFilter');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await classScheduleService.listSchedules(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) { handle(res, e); }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.getSchedule(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.createSchedule({
      ...req.body,
      branchId: req.body.branchId || req.branchId,
    });
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.updateSchedule(req.params.id, getBranchFilter(req), req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.remove = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.deleteSchedule(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.syncStudents = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.syncStudentsFromGroup(req.params.id, getBranchFilter(req));
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.conflicts = asyncHandler(async (req, res) => {
  try {
    const items = await classScheduleService.detectConflicts(req);
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.createFromGroup = asyncHandler(async (req, res) => {
  try {
    const item = await classScheduleService.createFromGroup(
      req.body.groupId,
      req.body,
      req.body.branchId || req.branchId
    );
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});
