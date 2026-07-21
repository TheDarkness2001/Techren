const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const studentService = require('../services/studentService');
const notificationService = require('../services/notificationService');
const dashboardService = require('../services/dashboardService');
const Student = require('../models/Student');

const handleServiceError = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.list = asyncHandler(async (req, res) => {
  try {
    const result = await studentService.listStudents(req);
    sendSuccess(res, result.items, 200, result.meta);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getOne = asyncHandler(async (req, res) => {
  try {
    const student = await studentService.getStudent(req, req.params.id);
    sendSuccess(res, student);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.create = asyncHandler(async (req, res) => {
  try {
    const student = await studentService.createStudent(req, req.body);
    sendSuccess(res, student, 201);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const student = await studentService.updateStudent(req, req.params.id, req.body);
    sendSuccess(res, student);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.setStatus = asyncHandler(async (req, res) => {
  try {
    const student = await studentService.setStudentStatus(req, req.params.id, req.body.status);
    sendSuccess(res, student);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.dashboard = asyncHandler(async (req, res) => {
  try {
    await studentService.getStudent(req, req.params.id);
    const student = await Student.findById(req.params.id);
    const data = await dashboardService.getStudentDashboard(student);
    sendSuccess(res, data);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.registerFcmToken = asyncHandler(async (req, res) => {
  try {
    if (req.userType === 'student' && String(req.params.id) !== String(req.user._id)) {
      return sendError(res, 403, 'FORBIDDEN', 'Cannot register token for another student');
    }
    const data = await notificationService.registerFcmToken(req.params.id, req.body.token);
    sendSuccess(res, data);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getNotificationSettings = asyncHandler(async (req, res) => {
  try {
    await studentService.getStudent(req, req.params.id);
    const settings = await notificationService.getParentSettings(req.params.id);
    sendSuccess(res, { settings: notificationService.formatSettings(settings.toObject()) });
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.updateNotificationSettings = asyncHandler(async (req, res) => {
  try {
    await studentService.getStudent(req, req.params.id);
    const settings = await notificationService.updateParentSettings(req.params.id, req.body);
    sendSuccess(res, { settings });
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.uploadPhoto = asyncHandler(async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'Photo file is required');
    }
    const student = await studentService.updateStudentPhoto(req, req.params.id, req.file);
    sendSuccess(res, student);
  } catch (error) {
    handleServiceError(res, error);
  }
});
