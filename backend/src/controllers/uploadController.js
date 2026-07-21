const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const importService = require('../services/importService');
const uploadService = require('../services/uploadService');
const fs = require('fs');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.parseDocx = asyncHandler(async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'DOCX or TXT file is required');
    }
    const { assertMagicBytes } = require('../utils/fileMagic');
    assertMagicBytes(req.file.path, 'docx');
    const data = await importService.parseDocxFile(req.file.path);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  } finally {
    if (req.file?.path) fs.unlink(req.file.path, () => {});
  }
});

exports.parseOcr = asyncHandler(async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'Image file is required');
    }
    const data = await importService.parseOcrImage(req.file);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.bulkImportWords = asyncHandler(async (req, res) => {
  try {
    const { lessonId, pairs } = req.body;
    if (!lessonId || !Array.isArray(pairs) || pairs.length === 0) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'lessonId and pairs array are required');
    }
    const data = await importService.bulkImportWords(lessonId, pairs);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.bulkImportSentences = asyncHandler(async (req, res) => {
  try {
    const { lessonId, pairs } = req.body;
    if (!lessonId || !Array.isArray(pairs) || pairs.length === 0) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'lessonId and pairs array are required');
    }
    const data = await importService.bulkImportSentences(lessonId, pairs);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.uploadAudio = asyncHandler(async (req, res) => {
  try {
    const data = uploadService.saveUploadedFile(req.file, 'audio');
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.uploadImage = asyncHandler(async (req, res) => {
  try {
    const data = uploadService.saveUploadedFile(req.file, 'image');
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});
