const mongoose = require('mongoose');
const StaffEarning = require('../models/StaffEarning');
const StaffAccount = require('../models/StaffAccount');
const Teacher = require('../models/Teacher');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const { isPrivilegedStaff } = require('../middleware/auth');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const formatEarning = (doc) => ({
  id: doc._id,
  staffId: doc.staffId?._id || doc.staffId,
  staffName: doc.staffId?.name,
  amount: doc.amount,
  earningType: doc.earningType,
  status: doc.status,
  referenceDate: doc.referenceDate,
  description: doc.description,
  reason: doc.reason,
  approvedBy: doc.approvedBy?._id || doc.approvedBy,
  approvedByName: doc.approvedBy?.name,
  approvedAt: doc.approvedAt,
  payoutId: doc.payoutId,
  paidAt: doc.paidAt,
  branchId: doc.branchId,
  createdAt: doc.createdAt,
});

const syncAccountFromEarnings = async (staffId) => {
  const earnings = await StaffEarning.find({ staffId, status: { $ne: 'cancelled' } });
  const account = await StaffAccount.getOrCreate(staffId);

  let pending = 0;
  let approved = 0;
  let paid = 0;
  let total = 0;

  for (const e of earnings) {
    total += e.amount;
    if (e.status === 'pending') pending += e.amount;
    if (e.status === 'approved') approved += e.amount;
    if (e.status === 'paid') paid += e.amount;
  }

  account.totalEarned = total;
  account.pendingEarnings = pending;
  account.approvedNotPaid = approved;
  account.totalPaidOut = paid;
  account.availableForPayout = approved;
  account.lastEarningDate = earnings.length ? earnings[0].referenceDate : account.lastEarningDate;
  await account.save();
  return account;
};

const resolveStaffId = (req, queryStaffId) => {
  if (req.userType === 'teacher' && !isPrivilegedStaff(req.user)) {
    return String(req.user._id);
  }
  return queryStaffId || String(req.user._id);
};

const listEarnings = async (req, query = {}) => {
  const staffId = resolveStaffId(req, query.staffId);
  let filter = { staffId, ...getBranchFilter(req) };
  if (query.status) filter.status = query.status;
  if (query.earningType) filter.earningType = query.earningType;

  if (query.search) {
    const term = String(query.search).trim();
    if (term) {
      const branchScope = getBranchFilter(req);
      const searchOr = [
        { description: { $regex: term, $options: 'i' } },
        { reason: { $regex: term, $options: 'i' } },
        { earningType: { $regex: term, $options: 'i' } },
        { status: { $regex: term, $options: 'i' } },
      ];
      if (!staffId) {
        const teachers = await Teacher.find({
          ...(branchScope.branchId ? { branchId: branchScope.branchId } : {}),
          name: { $regex: term, $options: 'i' },
        }).select('_id');
        if (teachers.length) {
          searchOr.push({ staffId: { $in: teachers.map((teacher) => teacher._id) } });
        }
      }
      filter = { $and: [filter, { $or: searchOr }] };
    }
  }

  const { page, limit, skip } = parsePagination(query);
  const [earnings, total] = await Promise.all([
    StaffEarning.find(filter)
      .populate('staffId', 'name email')
      .populate('approvedBy', 'name')
      .sort({ referenceDate: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit),
    StaffEarning.countDocuments(filter),
  ]);

  return {
    items: earnings.map((e) => formatEarning(e.toObject())),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getAccount = async (req, query = {}) => {
  const staffId = resolveStaffId(req, query.staffId);
  const account = await StaffAccount.findOne({ staffId });
  if (!account) {
    return {
      staffId,
      totalEarned: 0,
      totalPaidOut: 0,
      availableForPayout: 0,
      pendingEarnings: 0,
      approvedNotPaid: 0,
      currency: 'UZS',
    };
  }
  return {
    staffId: account.staffId,
    totalEarned: account.totalEarned,
    totalPaidOut: account.totalPaidOut,
    availableForPayout: account.availableForPayout,
    pendingEarnings: account.pendingEarnings,
    approvedNotPaid: account.approvedNotPaid,
    lastEarningDate: account.lastEarningDate,
    lastPayoutDate: account.lastPayoutDate,
    currency: account.currency,
  };
};

const createEarning = async (req, data) => {
  const teacher = await Teacher.findById(data.staffId);
  if (!teacher) throw Object.assign(new Error('Staff not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const branchId = data.branchId || teacher.branchId;
  if (!canAccessBranch(req, branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const amount = Number(data.amount);
  if (!amount) throw Object.assign(new Error('Amount is required'), { statusCode: 400, code: 'BAD_REQUEST' });

  const earning = await StaffEarning.create({
    staffId: data.staffId,
    classScheduleId: data.classScheduleId || null,
    studentId: data.studentId || null,
    amount,
    earningType: data.earningType || 'per-class',
    status: 'pending',
    referenceDate: data.referenceDate || new Date(),
    description: data.description || '',
    createdBy: req.user?._id || null,
    createdByType: req.user?.role || 'admin',
    branchId,
  });

  await syncAccountFromEarnings(data.staffId);
  return formatEarning(earning.toObject());
};

const approveEarning = async (req, id) => {
  const earning = await StaffEarning.findById(id);
  if (!earning) throw Object.assign(new Error('Earning not found'), { statusCode: 404, code: 'NOT_FOUND' });
  if (!canAccessBranch(req, earning.branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  if (earning.status !== 'pending') {
    throw Object.assign(new Error('Only pending earnings can be approved'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  earning.status = 'approved';
  earning.approvedBy = req.user._id;
  earning.approvedAt = new Date();
  await earning.save();
  await syncAccountFromEarnings(earning.staffId);
  return formatEarning(earning.toObject());
};

const addBonus = async (req, staffId, { amount, reason }) => {
  if (!reason || reason.length < 10) {
    throw Object.assign(new Error('Reason must be at least 10 characters'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const teacher = await Teacher.findById(staffId);
  if (!teacher) throw Object.assign(new Error('Staff not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const earning = await StaffEarning.create({
    staffId,
    amount: Math.abs(Number(amount)),
    earningType: 'bonus',
    status: 'approved',
    referenceDate: new Date(),
    description: 'Bonus',
    reason,
    approvedBy: req.user._id,
    approvedAt: new Date(),
    createdBy: req.user._id,
    createdByType: req.user.role,
    branchId: teacher.branchId,
  });
  await syncAccountFromEarnings(staffId);
  return formatEarning(earning.toObject());
};

const addPenalty = async (req, staffId, { amount, reason }) => {
  if (!reason || reason.length < 10) {
    throw Object.assign(new Error('Reason must be at least 10 characters'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const teacher = await Teacher.findById(staffId);
  if (!teacher) throw Object.assign(new Error('Staff not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const earning = await StaffEarning.create({
    staffId,
    amount: -Math.abs(Number(amount)),
    earningType: 'penalty',
    status: 'approved',
    referenceDate: new Date(),
    description: 'Penalty',
    reason,
    approvedBy: req.user._id,
    approvedAt: new Date(),
    createdBy: req.user._id,
    createdByType: req.user.role,
    branchId: teacher.branchId,
  });
  await syncAccountFromEarnings(staffId);
  return formatEarning(earning.toObject());
};

const addAdjustment = async (req, staffId, { amount, direction, reason }) => {
  if (!['credit', 'debit'].includes(direction)) {
    throw Object.assign(new Error('Direction must be credit or debit'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  if (!reason || reason.length < 10) {
    throw Object.assign(new Error('Reason must be at least 10 characters'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const teacher = await Teacher.findById(staffId);
  if (!teacher) throw Object.assign(new Error('Staff not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const value = direction === 'debit' ? -Math.abs(Number(amount)) : Math.abs(Number(amount));
  const earning = await StaffEarning.create({
    staffId,
    amount: value,
    earningType: 'adjustment',
    status: 'approved',
    referenceDate: new Date(),
    description: `Manual ${direction} adjustment`,
    reason,
    approvedBy: req.user._id,
    approvedAt: new Date(),
    createdBy: req.user._id,
    createdByType: req.user.role,
    branchId: teacher.branchId,
  });
  await syncAccountFromEarnings(staffId);
  return formatEarning(earning.toObject());
};

const recalculate = async (req, staffId) => {
  if (!mongoose.Types.ObjectId.isValid(staffId)) {
    throw Object.assign(new Error('Invalid staff ID'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  return syncAccountFromEarnings(staffId);
};

module.exports = {
  listEarnings,
  getAccount,
  createEarning,
  approveEarning,
  addBonus,
  addPenalty,
  addAdjustment,
  recalculate,
  formatEarning,
};
