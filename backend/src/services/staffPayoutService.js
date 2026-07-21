const StaffPayout = require('../models/StaffPayout');
const StaffEarning = require('../models/StaffEarning');
const StaffAccount = require('../models/StaffAccount');
const Teacher = require('../models/Teacher');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const { isPrivilegedStaff } = require('../middleware/auth');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const staffEarningService = require('./staffEarningService');

const formatPayout = (doc) => ({
  id: doc._id,
  payoutRef: doc.payoutRef,
  staffId: doc.staffId?._id || doc.staffId,
  staffName: doc.staffId?.name,
  earningIds: doc.earningIds,
  amount: doc.amount,
  method: doc.method,
  status: doc.status,
  referenceNumber: doc.referenceNumber,
  approvedBy: doc.approvedBy?._id || doc.approvedBy,
  approvedByName: doc.approvedBy?.name,
  completedAt: doc.completedAt,
  cancelledAt: doc.cancelledAt,
  cancellationReason: doc.cancellationReason,
  notes: doc.notes,
  branchId: doc.branchId,
  createdAt: doc.createdAt,
});

const resolveStaffId = (req, queryStaffId) => {
  if (req.userType === 'teacher' && !isPrivilegedStaff(req.user)) {
    return queryStaffId && String(queryStaffId) === String(req.user._id) ? String(req.user._id) : String(req.user._id);
  }
  return queryStaffId || null;
};

const listPayouts = async (req, query = {}) => {
  const staffId = resolveStaffId(req, query.staffId);
  let filter = { ...getBranchFilter(req) };
  if (staffId) filter.staffId = staffId;
  if (query.status) filter.status = query.status;

  if (query.search) {
    const term = String(query.search).trim();
    if (term) {
      const branchScope = getBranchFilter(req);
      const searchOr = [
        { payoutRef: { $regex: term, $options: 'i' } },
        { referenceNumber: { $regex: term, $options: 'i' } },
        { notes: { $regex: term, $options: 'i' } },
        { method: { $regex: term, $options: 'i' } },
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
  const [payouts, total] = await Promise.all([
    StaffPayout.find(filter)
      .populate('staffId', 'name email')
      .populate('approvedBy', 'name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    StaffPayout.countDocuments(filter),
  ]);

  return {
    items: payouts.map((p) => formatPayout(p.toObject())),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const previewPayout = async (req, { staffId, earningIds }) => {
  if (!staffId || !earningIds?.length) {
    throw Object.assign(new Error('staffId and earningIds are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const ids = Array.isArray(earningIds) ? earningIds : String(earningIds).split(',');
  const earnings = await StaffEarning.find({
    _id: { $in: ids },
    staffId,
    status: 'approved',
  });

  if (earnings.length !== ids.length) {
    throw Object.assign(new Error('Some earnings are not approved or do not belong to this staff'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }

  const totalAmount = earnings.reduce((sum, e) => sum + e.amount, 0);
  return {
    staffId,
    earningsCount: earnings.length,
    totalAmount,
    earnings: earnings.map((e) => staffEarningService.formatEarning(e.toObject())),
  };
};

const createPayout = async (req, { staffId, earningIds, method, notes, bankDetails }) => {
  const teacher = await Teacher.findById(staffId);
  if (!teacher) throw Object.assign(new Error('Staff not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const preview = await previewPayout(req, { staffId, earningIds });
  if (preview.totalAmount <= 0) {
    throw Object.assign(new Error('Payout amount must be positive'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const account = await StaffAccount.findOne({ staffId });
  if (!account || account.availableForPayout < preview.totalAmount) {
    throw Object.assign(new Error('Insufficient available balance for payout'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const payout = await StaffPayout.create({
    staffId,
    earningIds,
    amount: preview.totalAmount,
    method,
    notes: notes || '',
    bankDetails: bankDetails || undefined,
    referenceNumber: `REF-${Date.now()}`,
    approvedBy: req.user._id,
    branchId: teacher.branchId,
    status: 'pending',
  });

  await StaffEarning.updateMany(
    { _id: { $in: earningIds } },
    { status: 'paid', payoutId: payout._id, paidAt: new Date() }
  );

  account.totalPaidOut += preview.totalAmount;
  account.availableForPayout -= preview.totalAmount;
  account.approvedNotPaid -= preview.totalAmount;
  account.lastPayoutDate = new Date();
  await account.save();
  await staffEarningService.recalculate(req, staffId);

  return formatPayout(payout.toObject());
};

const completePayout = async (req, id) => {
  const payout = await StaffPayout.findById(id);
  if (!payout) throw Object.assign(new Error('Payout not found'), { statusCode: 404, code: 'NOT_FOUND' });
  if (!canAccessBranch(req, payout.branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  if (payout.status !== 'pending') {
    throw Object.assign(new Error('Only pending payouts can be completed'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  payout.status = 'completed';
  payout.completedAt = new Date();
  await payout.save();
  return formatPayout(payout.toObject());
};

const cancelPayout = async (req, id, reason) => {
  if (!reason || reason.length < 10) {
    throw Object.assign(new Error('Cancellation reason must be at least 10 characters'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const payout = await StaffPayout.findById(id);
  if (!payout) throw Object.assign(new Error('Payout not found'), { statusCode: 404, code: 'NOT_FOUND' });
  if (payout.status !== 'pending') {
    throw Object.assign(new Error('Only pending payouts can be cancelled'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  await StaffEarning.updateMany(
    { _id: { $in: payout.earningIds } },
    { status: 'approved', payoutId: null, paidAt: null }
  );

  payout.status = 'cancelled';
  payout.cancelledAt = new Date();
  payout.cancellationReason = reason;
  await payout.save();
  await staffEarningService.recalculate(req, payout.staffId);

  return formatPayout(payout.toObject());
};

module.exports = {
  listPayouts,
  previewPayout,
  createPayout,
  completePayout,
  cancelPayout,
};
