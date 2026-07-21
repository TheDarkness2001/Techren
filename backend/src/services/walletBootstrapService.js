const Settings = require('../models/Settings');
const Student = require('../models/Student');
const WalletTransaction = require('../models/WalletTransaction');
const { getOrCreateWallet } = require('./walletService');

const ensureWalletDemoContent = async () => {
  await Settings.findByIdAndUpdate(
    'global',
    { $set: { 'featureFlags.walletEnabled': true } },
    { upsert: false }
  );

  const student = await Student.findOne({ email: 'student@techren.uz' });
  if (!student) return;

  const wallet = await getOrCreateWallet(student._id, student.branchId);
  if (wallet.balanceTyiyn > 0) return;

  wallet.balanceTyiyn = 2500000;
  await wallet.save();

  const existing = await WalletTransaction.exists({ walletId: wallet._id });
  if (!existing) {
    await WalletTransaction.create({
      walletId: wallet._id,
      studentId: student._id,
      type: 'topup',
      amountTyiyn: 2500000,
      balanceAfterTyiyn: 2500000,
      description: 'Demo wallet seed balance',
      referenceId: 'DEMO-SEED',
    });
  }
};

module.exports = { ensureWalletDemoContent };
