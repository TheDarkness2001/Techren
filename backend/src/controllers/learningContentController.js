const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const learningContentService = require('../services/learningContentService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.listLanguages = asyncHandler(async (req, res) => {
  try {
    const items = await learningContentService.listLanguages(req.query.moduleType || 'words');
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.createLanguage = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.createLanguage(req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.updateLanguage = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.updateLanguage(req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.removeLanguage = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.removeLanguage(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.listLevels = asyncHandler(async (req, res) => {
  try {
    const items = await learningContentService.listLevels({
      languageId: req.query.languageId,
      moduleType: req.query.moduleType || 'words',
    });
    sendSuccess(res, items);
  } catch (e) { handle(res, e); }
});

exports.createLevel = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.createLevel(req.body);
    sendSuccess(res, item, 201);
  } catch (e) { handle(res, e); }
});

exports.updateLevel = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.updateLevel(req.params.id, req.body);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.removeLevel = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.removeLevel(req.params.id);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});

exports.togglePracticeUnlock = asyncHandler(async (req, res) => {
  try {
    const item = await learningContentService.togglePracticeUnlock(req.params.id, req.body.groupId, req.body.unlock);
    sendSuccess(res, item);
  } catch (e) { handle(res, e); }
});
