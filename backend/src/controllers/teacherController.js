const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const teacherService = require('../services/teacherService');

const handleServiceError = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await teacherService.listTeachers(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const teacher = await teacherService.getTeacher(req, req.params.id);
    sendSuccess(res, teacher);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const teacher = await teacherService.createTeacher(req, req.body);
    sendSuccess(res, teacher, 201);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const teacher = await teacherService.updateTeacher(req, req.params.id, req.body);
    sendSuccess(res, teacher);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.deactivate = asyncHandler(async (req, res) => {
  try {
    const teacher = await teacherService.deactivateTeacher(req, req.params.id);
    sendSuccess(res, teacher);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.updatePermissions = asyncHandler(async (req, res) => {
  try {
    const teacher = await teacherService.updateTeacherPermissions(req, req.params.id, req.body.permissions);
    sendSuccess(res, teacher);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.uploadPhoto = asyncHandler(async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'Photo file is required');
    }
    const teacher = await teacherService.updateTeacherPhoto(req, req.params.id, req.file);
    sendSuccess(res, teacher);
  } catch (error) {
    handleServiceError(res, error);
  }
});
