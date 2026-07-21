const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const recycleBinService = require('../services/recycleBinService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await recycleBinService.listEntries(req.query, req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (e) {
    handle(res, e);
  }
});

exports.snapshots = asyncHandler(async (req, res) => {
  try {
    const data = await recycleBinService.getSnapshotsForEntry(req.params.id, req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.restore = asyncHandler(async (req, res) => {
  try {
    const data = await recycleBinService.restoreEntry(req.params.id, req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.purge = asyncHandler(async (req, res) => {
  try {
    const item = await recycleBinService.purgeEntry(req.params.id, req);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});

exports.purgeAll = asyncHandler(async (req, res) => {
  try {
    const data = await recycleBinService.purgeAll(req.body, req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.toggleImportant = asyncHandler(async (req, res) => {
  try {
    const item = await recycleBinService.toggleImportant(req.params.id, req);
    sendSuccess(res, item);
  } catch (e) {
    handle(res, e);
  }
});
