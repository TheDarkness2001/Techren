const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const pollService = require('../services/pollService');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.createPoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.createPoll(req, req.body), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updatePoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.updatePoll(req, req.params.id, req.body));
  } catch (e) {
    handle(res, e);
  }
});

exports.closePoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.closePoll(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.reopenPoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.reopenPoll(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.duplicatePoll = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.duplicatePoll(req, req.params.id), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.vote = asyncHandler(async (req, res) => {
  try {
    const optionIds = req.body?.optionIds || req.body?.optionId;
    sendSuccess(res, await pollService.vote(req, req.params.id, optionIds));
  } catch (e) {
    handle(res, e);
  }
});

exports.getResults = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await pollService.getResults(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.exportResultsCsv = asyncHandler(async (req, res) => {
  try {
    const { filename, csv } = await pollService.exportResultsCsv(req, req.params.id);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(csv);
  } catch (e) {
    handle(res, e);
  }
});
