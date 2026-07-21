const mongoose = require('mongoose');
const Penalty = require('../models/Penalty');
const ExamGroup = require('../models/ExamGroup');
const Student = require('../models/Student');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const PENALTY_TYPES = ['spoken_uzbek', 'missed_presentation', 'missed_writing_homework', 'missed_word_memorization', 'other', 'bonus'];

const formatPenalty = (doc) => ({
  id: doc._id,
  studentId: doc.studentId?._id || doc.studentId,
  studentName: doc.studentId?.name,
  studentCode: doc.studentId?.studentId,
  type: doc.type,
  points: doc.points,
  quantity: doc.quantity,
  totalPoints: doc.points * (doc.quantity || 1),
  date: doc.date,
  classScheduleId: doc.classScheduleId,
  notes: doc.notes,
  source: doc.source,
  recordedBy: doc.recordedBy?._id || doc.recordedBy,
  recordedByName: doc.recordedBy?.name,
  branchId: doc.branchId,
  isReverted: doc.isReverted,
});

const monthRange = (year, month) => ({
  start: new Date(year, month - 1, 1),
  end: new Date(year, month, 1),
});

const assertStudentAccess = (req, studentId) => {
  if (req.userType === 'student' && String(req.user._id) !== String(studentId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }
};

const createPenalty = async (req, data) => {
  const { studentId, type, points, quantity, date, classScheduleId, notes } = data;
  if (!studentId || !type || points === undefined || points === null) {
    throw Object.assign(new Error('studentId, type, and points are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  if (!PENALTY_TYPES.includes(type)) {
    throw Object.assign(new Error('Invalid penalty type'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const student = await Student.findById(studentId);
  if (!student) throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const branchId = data.branchId || student.branchId;
  if (!canAccessBranch(req, branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const penalty = await Penalty.create({
    studentId,
    type,
    points,
    quantity: quantity || 1,
    date: date || new Date(),
    classScheduleId: classScheduleId || null,
    notes: notes || '',
    source: 'manual',
    recordedBy: req.userType === 'teacher' ? req.user._id : null,
    branchId,
  });

  return formatPenalty(penalty.toObject());
};

const getStudentPenalties = async (req, studentId, { year, month } = {}) => {
  assertStudentAccess(req, studentId);
  const query = { studentId, isReverted: false };
  if (year && month) {
    const { start, end } = monthRange(Number(year), Number(month));
    query.date = { $gte: start, $lt: end };
  }

  const penalties = await Penalty.find(query)
    .populate('studentId', 'name studentId')
    .populate('recordedBy', 'name')
    .sort({ date: -1 });

  const formatted = penalties.map((p) => formatPenalty(p.toObject()));
  const total = formatted.reduce((sum, p) => sum + p.totalPoints, 0);
  return { penalties: formatted, total };
};

const getGroupPenalties = async (req, groupId, { date } = {}) => {
  const group = await ExamGroup.findById(groupId).populate('students', 'name studentId status');
  if (!group) throw Object.assign(new Error('Group not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const students = (group.students || []).filter((s) => s && s.status === 'active');
  const studentIds = students.map((s) => s._id);

  const query = { studentId: { $in: studentIds }, isReverted: false };
  if (date) {
    const d = new Date(date);
    const start = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const end = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
    query.date = { $gte: start, $lt: end };
  }

  const penalties = await Penalty.find(query)
    .populate('studentId', 'name studentId')
    .sort({ date: -1 });

  const byStudent = students.map((student) => {
    const items = penalties.filter((p) => String(p.studentId?._id || p.studentId) === String(student._id));
    const total = items.reduce((sum, p) => sum + p.points * (p.quantity || 1), 0);
    return {
      student: { id: student._id, name: student.name, studentCode: student.studentId },
      penalties: items.map((p) => formatPenalty(p.toObject())),
      total,
    };
  });

  return byStudent;
};

const getMonthlyPenalties = async (req, query = {}) => {
  const { year, month, branchId } = query;
  if (!year || !month) {
    throw Object.assign(new Error('year and month are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const filter = { ...getBranchFilter(req), isReverted: false };
  if (branchId) filter.branchId = branchId;
  const { start, end } = monthRange(Number(year), Number(month));
  filter.date = { $gte: start, $lt: end };

  const { page, limit, skip } = parsePagination(query);
  const [penalties, totalCount, sumAgg] = await Promise.all([
    Penalty.find(filter).populate('studentId', 'name studentId').sort({ date: -1 }).skip(skip).limit(limit),
    Penalty.countDocuments(filter),
    Penalty.aggregate([
      { $match: filter },
      { $group: { _id: null, total: { $sum: { $multiply: ['$points', { $ifNull: ['$quantity', 1] }] } } } },
    ]),
  ]);

  const formatted = penalties.map((p) => formatPenalty(p.toObject()));
  const total = sumAgg[0]?.total ?? 0;

  return {
    items: formatted,
    total,
    meta: buildPaginationMeta(page, limit, totalCount),
  };
};

const revertPenalty = async (req, id) => {
  const penalty = await Penalty.findById(id);
  if (!penalty) throw Object.assign(new Error('Penalty not found'), { statusCode: 404, code: 'NOT_FOUND' });
  if (!canAccessBranch(req, penalty.branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  penalty.isReverted = true;
  await penalty.save();
  return formatPenalty(penalty.toObject());
};

module.exports = {
  createPenalty,
  getStudentPenalties,
  getGroupPenalties,
  getMonthlyPenalties,
  revertPenalty,
  PENALTY_TYPES,
};
