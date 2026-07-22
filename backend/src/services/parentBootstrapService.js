const Settings = require('../models/Settings');

/** Enables parent portal flag only. Does not create a demo parent account. */
const ensureParentPortalDemo = async () => {
  await Settings.findByIdAndUpdate(
    'global',
    { $set: { 'featureFlags.parentPortalEnabled': true } },
    { upsert: false }
  );
};

module.exports = { ensureParentPortalDemo };
