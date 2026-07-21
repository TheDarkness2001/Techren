require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
require('../src/models');
const walletService = require('../src/services/walletService');
const { initDefaults } = require('../src/services/settingsService');
const WalletTransaction = require('../src/models/WalletTransaction');
const Student = require('../src/models/Student');
const Settings = require('../src/models/Settings');

async function ensureWalletEnabled() {
  await initDefaults();
  const settings = await Settings.findOne().sort({ updatedAt: -1 });
  if (!settings) return;
  settings.featureFlags = { ...(settings.featureFlags || {}), walletEnabled: true };
  settings.features = { ...(settings.features || {}), walletSystem: true };
  settings.markModified('featureFlags');
  settings.markModified('features');
  await settings.save();
}

async function run() {
  await connectDB();
  await ensureWalletEnabled();

  const sample = await WalletTransaction.findOne().select('type description referenceId studentId');
  if (!sample) {
    const student = await Student.findOne().select('_id');
    if (!student) {
      console.log('skip wallet search: no students in database');
      await disconnectDB();
      return;
    }
    const mockReq = {
      query: { studentId: String(student._id), page: 1, limit: 20, search: 'topup' },
      userType: 'teacher',
      user: { role: 'founder', branchId: null },
    };
    const result = await walletService.listTransactions(mockReq);
    if (result.meta.total !== 0) {
      throw new Error('expected zero transactions for empty wallet search');
    }
    console.log('wallet search filter OK (no transactions; empty result verified)');
    await disconnectDB();
    return;
  }

  const term = sample.type || sample.description?.split(' ')[0] || 'topup';
  const mockReq = {
    query: { studentId: String(sample.studentId), page: 1, limit: 20 },
    userType: 'teacher',
    user: { role: 'founder', branchId: null },
  };
  const all = await walletService.listTransactions(mockReq);
  const filtered = await walletService.listTransactions({
    ...mockReq,
    query: { ...mockReq.query, search: term },
  });

  console.log('wallet search term:', term);
  console.log('wallet transactions total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('wallet search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0 && all.meta.total > 0) {
    throw new Error('wallet search returned zero matches for known term');
  }

  console.log('wallet transactions search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
