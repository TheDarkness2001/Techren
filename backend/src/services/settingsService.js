const Settings = require('../models/Settings');
const { DEFAULT_ROLE_PERMISSIONS } = require('../config/permissions');

const findSettingsDocument = async () => {
  let settings = await Settings.findById('global');
  if (!settings) {
    settings = await Settings.findOne().sort({ updatedAt: -1 });
  }
  return settings;
};

const initDefaults = async () => {
  const existing = await findSettingsDocument();
  if (!existing) {
    await Settings.create({
      _id: 'global',
      rolePermissions: DEFAULT_ROLE_PERMISSIONS,
      featureFlags: {
        walletEnabled: false,
        gamificationEnabled: true,
        parentPortalEnabled: false,
      },
    });
  }
  await ensureRolePermissionDefaults();
  return findSettingsDocument();
};

const ensureRolePermissionDefaults = async () => {
  const settings = await findSettingsDocument();
  if (!settings) return;

  const current = settings.rolePermissions || {};
  let changed = false;

  for (const [role, defaults] of Object.entries(DEFAULT_ROLE_PERMISSIONS)) {
    if (!current[role] || typeof current[role] !== 'object') {
      current[role] = { ...defaults };
      changed = true;
      continue;
    }
    for (const [key, val] of Object.entries(defaults)) {
      if (current[role][key] === undefined) {
        current[role][key] = val;
        changed = true;
      }
    }
  }

  if (changed) {
    settings.rolePermissions = current;
    settings.markModified('rolePermissions');
    await settings.save();
  }
};

const getSettings = async () => {
  const settings = await findSettingsDocument();
  if (!settings) return initDefaults();
  return settings;
};

const updateSettings = async (data) => {
  const settings = await getSettings();
  if (data.featureFlags) {
    settings.featureFlags = { ...settings.featureFlags, ...data.featureFlags };
  }
  await settings.save();
  return settings;
};

const getPermissions = async () => {
  const settings = await getSettings();
  return settings.rolePermissions;
};

const updatePermissions = async (rolePermissions) => {
  const settings = await getSettings();
  settings.rolePermissions = rolePermissions;
  settings.markModified('rolePermissions');
  await settings.save();
  return settings.rolePermissions;
};

const getFeatureFlag = async (flag) => {
  const settings = await getSettings();
  if (flag === 'walletEnabled') {
    return settings.featureFlags?.walletEnabled ?? settings.features?.walletSystem ?? false;
  }
  if (flag === 'gamificationEnabled') {
    return settings.featureFlags?.gamificationEnabled ?? settings.features?.gamification ?? true;
  }
  return settings.featureFlags?.[flag] ?? false;
};

module.exports = {
  initDefaults,
  getSettings,
  findSettingsDocument,
  updateSettings,
  getPermissions,
  updatePermissions,
  getFeatureFlag,
};
