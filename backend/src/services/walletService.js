const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');
const Student = require('../models/Student');
const { getFeatureFlag } = require('./settingsService');
const { getBranchFilter } = require('../utils/branchFilter');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { isPlatformAdmin, hasPermission } = require('../middleware/auth');

const MIN_TOPUP_SOM = 10000;
const TYIYN_PER_SOM = 100;

class WalletError extends Error {
  constructor(message, statusCode = 400, code = 'WALLET_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

const somToTyiyn = (som) => Math.round(Number(som) * TYIYN_PER_SOM);
const tyiynToSom = (tyiyn) => tyiyn / TYIYN_PER_SOM;

const assertWalletEnabled = async () => {
  const enabled = await getFeatureFlag('walletEnabled');
  if (!enabled) {
    throw new WalletError('Wallet module is not enabled', 501, 'NOT_ENABLED');
  }
};

const getOrCreateWallet = async (studentId, branchId) => {
  let wallet = await Wallet.findOne({ studentId });
  if (!wallet) {
    wallet = await Wallet.create({ studentId, branchId, balanceTyiyn: 0 });
  }
  return wallet;
};

const resolveStudentForRequest = async (req, studentId) => {
  if (req.userType === 'student') {
    return req.user;
  }

  if (req.userType !== 'teacher') {
    throw new WalletError('Unsupported user type', 403, 'FORBIDDEN');
  }

  if (!studentId) {
    throw new WalletError('studentId is required', 400, 'VALIDATION_ERROR');
  }

  const filter = { _id: studentId, ...getBranchFilter(req) };
  const student = await Student.findOne(filter);
  if (!student) {
    throw new WalletError('Student not found', 404, 'NOT_FOUND');
  }
  return student;
};

const formatTransaction = (doc) => doc.toPublicJSON();

const getBalance = async (req) => {
  await assertWalletEnabled();

  const studentId = req.userType === 'student' ? req.user._id : req.query.studentId;
  const student = await resolveStudentForRequest(req, studentId);
  const wallet = await getOrCreateWallet(student._id, student.branchId);

  return wallet.toPublicJSON();
};

const listTransactions = async (req) => {
  await assertWalletEnabled();

  const studentId = req.userType === 'student' ? req.user._id : req.query.studentId;
  const student = await resolveStudentForRequest(req, studentId);
  const wallet = await getOrCreateWallet(student._id, student.branchId);

  const { page, limit, skip } = parsePagination(req.query);
  let filter = { walletId: wallet._id };

  if (req.query.search) {
    const term = String(req.query.search).trim();
    if (term) {
      filter = {
        $and: [
          filter,
          {
            $or: [
              { type: { $regex: term, $options: 'i' } },
              { description: { $regex: term, $options: 'i' } },
              { referenceId: { $regex: term, $options: 'i' } },
            ],
          },
        ],
      };
    }
  }

  const [items, total] = await Promise.all([
    WalletTransaction.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    WalletTransaction.countDocuments(filter),
  ]);

  return {
    items: items.map(formatTransaction),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const recordTransaction = async ({ wallet, studentId, type, amountTyiyn, description, referenceId, createdBy }) => {
  const newBalance = wallet.balanceTyiyn + (type === 'topup' || type === 'refund' ? amountTyiyn : -amountTyiyn);
  if (newBalance < 0 && wallet.graceBalanceTyiyn < Math.abs(newBalance)) {
    throw new WalletError('Insufficient wallet balance', 400, 'INSUFFICIENT_BALANCE');
  }

  wallet.balanceTyiyn = Math.max(0, newBalance);
  await wallet.save();

  const tx = await WalletTransaction.create({
    walletId: wallet._id,
    studentId,
    type,
    amountTyiyn,
    balanceAfterTyiyn: wallet.balanceTyiyn,
    description,
    referenceId,
    createdBy,
  });

  return { wallet: wallet.toPublicJSON(), transaction: formatTransaction(tx) };
};

const topup = async (req, data) => {
  await assertWalletEnabled();

  // Staff with canManageWallet (admin defaults on; manager off) can credit.
  if (req.userType !== 'teacher' || !(await hasPermission(req, 'canManageWallet'))) {
    throw new WalletError(
      'Self-service top-up is disabled. Ask staff to credit your wallet.',
      403,
      'FORBIDDEN'
    );
  }

  const student = await resolveStudentForRequest(req, data.studentId);
  const amountSom = Number(data.amountSom ?? data.amount);
  if (!amountSom || amountSom < MIN_TOPUP_SOM) {
    throw new WalletError(`Minimum top-up is ${MIN_TOPUP_SOM.toLocaleString()} so'm`, 400, 'VALIDATION_ERROR');
  }

  const wallet = await getOrCreateWallet(student._id, student.branchId);
  if (wallet.isLocked) {
    throw new WalletError('Wallet is locked', 403, 'WALLET_LOCKED');
  }

  const amountTyiyn = somToTyiyn(amountSom);
  return recordTransaction({
    wallet,
    studentId: student._id,
    type: 'topup',
    amountTyiyn,
    description: data.description || 'Staff wallet credit',
    referenceId: data.referenceId || `TOPUP-${Date.now()}`,
    createdBy: req.user._id,
  });
};

const deduct = async (req, data) => {
  await assertWalletEnabled();

  if (req.userType !== 'teacher' || !(await hasPermission(req, 'canManageWallet'))) {
    throw new WalletError('Admin access required', 403, 'FORBIDDEN');
  }

  const student = await resolveStudentForRequest(req, data.studentId);
  const wallet = await getOrCreateWallet(student._id, student.branchId);
  if (wallet.isLocked) {
    throw new WalletError('Wallet is locked', 403, 'WALLET_LOCKED');
  }

  const amountSom = Number(data.amountSom ?? data.amount);
  const amountTyiyn = data.amountTyiyn != null ? Number(data.amountTyiyn) : somToTyiyn(amountSom);
  if (!amountTyiyn || amountTyiyn < 1) {
    throw new WalletError('Valid deduction amount required', 400, 'VALIDATION_ERROR');
  }

  const type = ['deduction', 'penalty', 'adjustment', 'topup', 'refund'].includes(data.type)
    ? data.type
    : 'deduction';

  return recordTransaction({
    wallet,
    studentId: student._id,
    type,
    amountTyiyn,
    description: data.description || (type === 'topup' || type === 'refund' ? 'Wallet credit' : 'Wallet deduction'),
    referenceId: data.referenceId || `TX-${Date.now()}`,
    createdBy: req.user._id,
  });
};

module.exports = {
  MIN_TOPUP_SOM,
  TYIYN_PER_SOM,
  somToTyiyn,
  tyiynToSom,
  assertWalletEnabled,
  getOrCreateWallet,
  getBalance,
  listTransactions,
  topup,
  deduct,
};
