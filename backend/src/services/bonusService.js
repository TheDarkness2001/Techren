const mongoose = require('mongoose');
const Penalty = require('../models/Penalty');
const PresentationScore = require('../models/PresentationScore');
const PenaltyPeriod = require('../models/PenaltyPeriod');
const Student = require('../models/Student');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

const monthRange = (year, month) => ({
  start: new Date(year, month - 1, 1),
  end: new Date(year, month, 1),
});

const resolveBranchId = (req, branchId) => branchId || getBranchFilter(req).branchId;

const calculateMonthlyBonuses = async (req, { year, month, branchId }) => {
  const y = Number(year);
  const m = Number(month);
  const resolvedBranchId = resolveBranchId(req, branchId);
  if (!y || !m || !resolvedBranchId) {
    throw Object.assign(new Error('year, month, and branchId are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const { start, end } = monthRange(y, m);
  const branchObjectId = new mongoose.Types.ObjectId(resolvedBranchId);

  const penalties = await Penalty.find({
    branchId: resolvedBranchId,
    date: { $gte: start, $lt: end },
    isReverted: false,
    type: { $ne: 'bonus' },
  });
  const totalPenalties = Math.abs(penalties.reduce((sum, p) => sum + p.points * (p.quantity || 1), 0));

  const presenterStats = await PresentationScore.aggregate([
    { $match: { branchId: branchObjectId, date: { $gte: start, $lt: end } } },
    {
      $group: {
        _id: '$studentId',
        avgScore: { $avg: '$score' },
        count: { $sum: 1 },
      },
    },
    { $sort: { avgScore: -1, count: -1 } },
    { $limit: 5 },
  ]);

  const students = await Student.find({ _id: { $in: presenterStats.map((p) => p._id) } }).select('name studentId');
  const info = new Map(students.map((s) => [String(s._id), s]));

  return {
    year: y,
    month: m,
    branchId: resolvedBranchId,
    totalPenalties,
    firstPlace: { percentage: 40, amount: Math.round(totalPenalties * 0.4) },
    secondPlace: { percentage: 30, amount: Math.round(totalPenalties * 0.3) },
    educationCenter: { percentage: 30, amount: Math.round(totalPenalties * 0.3) },
    topPresenters: presenterStats.map((p, i) => ({
      rank: i + 1,
      studentId: p._id,
      name: info.get(String(p._id))?.name || '-',
      studentCode: info.get(String(p._id))?.studentId || '',
      avgScore: Math.round(p.avgScore * 10) / 10,
      count: p.count,
    })),
  };
};

const distributeBonuses = async (req, { year, month, branchId, firstPlaceStudentId, secondPlaceStudentId }) => {
  const y = Number(year);
  const m = Number(month);
  const resolvedBranchId = resolveBranchId(req, branchId);
  if (!y || !m || !resolvedBranchId || !firstPlaceStudentId || !secondPlaceStudentId) {
    throw Object.assign(new Error('year, month, branchId, firstPlaceStudentId, and secondPlaceStudentId are required'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }
  if (!canAccessBranch(req, resolvedBranchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const existing = await PenaltyPeriod.findOne({ year: y, month: m, branchId: resolvedBranchId, status: 'closed' });
  if (existing) {
    throw Object.assign(new Error('Bonuses already distributed for this month'), { statusCode: 409, code: 'CONFLICT' });
  }

  const preview = await calculateMonthlyBonuses(req, { year: y, month: m, branchId: resolvedBranchId });
  const firstAmount = preview.firstPlace.amount;
  const secondAmount = preview.secondPlace.amount;

  await Penalty.create([
    {
      studentId: firstPlaceStudentId,
      type: 'bonus',
      points: firstAmount,
      quantity: 1,
      date: new Date(),
      notes: `1st place bonus for ${y}-${m}`,
      source: 'auto',
      recordedBy: req.user?._id || null,
      branchId: resolvedBranchId,
    },
    {
      studentId: secondPlaceStudentId,
      type: 'bonus',
      points: secondAmount,
      quantity: 1,
      date: new Date(),
      notes: `2nd place bonus for ${y}-${m}`,
      source: 'auto',
      recordedBy: req.user?._id || null,
      branchId: resolvedBranchId,
    },
  ]);

  const period = await PenaltyPeriod.findOneAndUpdate(
    { year: y, month: m, branchId: resolvedBranchId },
    {
      totalPenalties: preview.totalPenalties,
      totalBonusesDistributed: firstAmount + secondAmount,
      status: 'closed',
      winners: [
        { studentId: firstPlaceStudentId, rank: 1, percentage: 40, amount: firstAmount },
        { studentId: secondPlaceStudentId, rank: 2, percentage: 30, amount: secondAmount },
      ],
    },
    { upsert: true, new: true }
  ).populate('winners.studentId', 'name studentId');

  return period;
};

const getBonusHistory = async (req, { branchId } = {}) => {
  const filter = { ...getBranchFilter(req) };
  if (branchId) filter.branchId = branchId;
  const periods = await PenaltyPeriod.find(filter)
    .sort({ year: -1, month: -1 })
    .populate('winners.studentId', 'name studentId');
  return periods;
};

module.exports = { calculateMonthlyBonuses, distributeBonuses, getBonusHistory };
