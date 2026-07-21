const mongoose = require('mongoose');
const { DEFAULT_ROLE_PERMISSIONS } = require('../config/permissions');

const settingsSchema = new mongoose.Schema(
  {
    _id: { type: mongoose.Schema.Types.Mixed, default: 'global' },
    rolePermissions: {
      type: mongoose.Schema.Types.Mixed,
      default: () => DEFAULT_ROLE_PERMISSIONS,
    },
    featureFlags: {
      walletEnabled: { type: Boolean, default: false },
      gamificationEnabled: { type: Boolean, default: true },
      parentPortalEnabled: { type: Boolean, default: false },
    },
    features: {
      walletSystem: { type: Boolean },
      teacherEarnings: { type: Boolean },
      gamification: { type: Boolean },
    },
    system: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true, strict: false }
);

module.exports = mongoose.model('Settings', settingsSchema);
