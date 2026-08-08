const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const authService = require('../services/authService');

exports.login = asyncHandler(async (req, res) => {
  try {
    const identifier = req.body.identifier || req.body.email;
    const { password, userType = 'auto' } = req.body;
    const result = await authService.login(identifier, password, userType);
    sendSuccess(res, result);
  } catch (error) {
    sendError(res, error.statusCode || 401, error.code || 'UNAUTHORIZED', error.message);
  }
});

exports.teacherLogin = asyncHandler(async (req, res) => {
  try {
    const identifier = req.body.identifier || req.body.email;
    const { password } = req.body;
    const result = await authService.loginTeacher(identifier, password);
    sendSuccess(res, result);
  } catch (error) {
    sendError(res, error.statusCode || 401, error.code || 'UNAUTHORIZED', error.message);
  }
});

exports.studentLogin = asyncHandler(async (req, res) => {
  try {
    const identifier = req.body.identifier || req.body.email;
    const { password } = req.body;
    const result = await authService.loginStudent(identifier, password);
    sendSuccess(res, result);
  } catch (error) {
    sendError(res, error.statusCode || 401, error.code || 'UNAUTHORIZED', error.message);
  }
});

exports.parentLogin = asyncHandler(async (req, res) => {
  try {
    const identifier = req.body.identifier || req.body.email;
    const { password } = req.body;
    const result = await authService.loginParent(identifier, password);
    sendSuccess(res, result);
  } catch (error) {
    sendError(res, error.statusCode || 401, error.code || 'UNAUTHORIZED', error.message);
  }
});

exports.getMe = asyncHandler(async (req, res) => {
  const user = await authService.getMe(req.user, req.userType);
  sendSuccess(res, user);
});

exports.logout = asyncHandler(async (req, res) => {
  await authService.logout(req.body.refreshToken);
  sendSuccess(res, { message: 'Logged out successfully' });
});

exports.refresh = asyncHandler(async (req, res) => {
  try {
    const result = await authService.refresh(req.body.refreshToken);
    sendSuccess(res, result);
  } catch (error) {
    sendError(res, error.statusCode || 401, error.code || 'UNAUTHORIZED', error.message);
  }
});

exports.health = asyncHandler(async (req, res) => {
  sendSuccess(res, {
    status: 'ok',
    version: '1.0.0',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});
