const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const settingsService = require('../services/settingsService');

const handleServiceError = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.get = asyncHandler(async (req, res) => {
  try {
    const settings = await settingsService.getSettings();
    sendSuccess(res, {
      rolePermissions: settings.rolePermissions,
      featureFlags: settings.featureFlags,
      updatedAt: settings.updatedAt,
    });
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.update = asyncHandler(async (req, res) => {
  try {
    const settings = await settingsService.updateSettings(req.body);
    sendSuccess(res, {
      rolePermissions: settings.rolePermissions,
      featureFlags: settings.featureFlags,
      updatedAt: settings.updatedAt,
    });
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getPermissions = asyncHandler(async (req, res) => {
  try {
    const permissions = await settingsService.getPermissions();
    sendSuccess(res, permissions);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.updatePermissions = asyncHandler(async (req, res) => {
  try {
    const permissions = await settingsService.updatePermissions(req.body);
    sendSuccess(res, permissions);
  } catch (error) {
    handleServiceError(res, error);
  }
});

exports.getFeature = asyncHandler(async (req, res) => {
  try {
    const enabled = await settingsService.getFeatureFlag(req.params.flag);
    sendSuccess(res, { flag: req.params.flag, enabled });
  } catch (error) {
    handleServiceError(res, error);
  }
});
