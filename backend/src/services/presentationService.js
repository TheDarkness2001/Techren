const mongoose = require('mongoose');
const PresentationScore = require('../models/PresentationScore');
const Student = require('../models/Student');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

const formatPresentation = (doc) => ({
  id: doc._id,
  studentId: doc.studentId?._id || doc.studentId,
  studentName: doc.studentId?.name,
  studentCode: doc.studentId?.studentId,
  score: doc.score,
  date: doc.date,
  classScheduleId: doc.classScheduleId,
  notes: doc.notes,
  evaluatedBy: doc.evaluatedBy?._id || doc.evaluatedBy,
  evaluatedByName: doc.evaluatedBy?.name,
  branchId: doc.branchId,
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

const recordPresentation = async (req, data) => {
  const { studentId, score, date, classScheduleId, notes } = data;
  if (!studentId || score === undefined || score === null) {
    throw Object.assign(new Error('studentId and score are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  if (score < 1 || score > 10) {
    throw Object.assign(new Error('Score must be between 1 and 10'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const student = await Student.findById(studentId);
  if (!student) throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const branchId = data.branchId || student.branchId;
  if (!canAccessBranch(req, branchId)) {
    throw Object.assign(new Error('Branch access denied'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  if (req.userType !== 'teacher') {
    throw Object.assign(new Error('Staff required'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const presentation = await PresentationScore.create({
    studentId,
    score,
    date: date || new Date(),
    classScheduleId: classScheduleId || null,
    notes: notes || '',
    evaluatedBy: req.user._id,
    branchId,
  });

  return formatPresentation(presentation.toObject());
};

const getStudentPresentations = async (req, studentId, { year, month } = {}) => {
  assertStudentAccess(req, studentId);
  const query = { studentId };
  if (year && month) {
    const { start, end } = monthRange(Number(year), Number(month));
    query.date = { $gte: start, $lt: end };
  }

  const presentations = await PresentationScore.find(query)
    .populate('studentId', 'name studentId')
    .populate('evaluatedBy', 'name')
    .sort({ date: -1 });

  const formatted = presentations.map((p) => formatPresentation(p.toObject()));
  const avgScore = formatted.length
    ? Math.round((formatted.reduce((sum, p) => sum + p.score, 0) / formatted.length) * 10) / 10
    : 0;
  return { presentations: formatted, avgScore, count: formatted.length };
};

const getMonthlyPresentations = async (req, { year, month, branchId }) => {
  if (!year || !month) {
    throw Object.assign(new Error('year and month are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const filter = { ...getBranchFilter(req) };
  if (branchId) filter.branchId = branchId;
  const { start, end } = monthRange(Number(year), Number(month));
  filter.date = { $gte: start, $lt: end };

  const presentations = await PresentationScore.find(filter)
    .populate('studentId', 'name studentId')
    .sort({ date: -1 });

  const byStudent = new Map();
  for (const p of presentations) {
    const sid = String(p.studentId?._id || p.studentId);
    if (!byStudent.has(sid)) {
      byStudent.set(sid, { student: p.studentId, scores: [], total: 0 });
    }
    const entry = byStudent.get(sid);
    entry.scores.push(formatPresentation(p.toObject()));
    entry.total += p.score;
  }

  return [...byStudent.values()].map((s) => ({
    student: { id: s.student._id, name: s.student.name, studentCode: s.student.studentId },
    count: s.scores.length,
    average: s.scores.length ? Math.round((s.total / s.scores.length) * 10) / 10 : 0,
    scores: s.scores,
  }));
};

const getTopPresenters = async (req, { year, month, branchId, limit = 10 }) => {
  if (!year || !month) {
    throw Object.assign(new Error('year and month are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const resolvedBranchId = branchId || getBranchFilter(req).branchId;
  if (!resolvedBranchId) {
    throw Object.assign(new Error('branchId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const { start, end } = monthRange(Number(year), Number(month));
  const branchObjectId = new mongoose.Types.ObjectId(resolvedBranchId);

  const topPresenters = await PresentationScore.aggregate([
    { $match: { branchId: branchObjectId, date: { $gte: start, $lt: end } } },
    {
      $group: {
        _id: '$studentId',
        avgScore: { $avg: '$score' },
        count: { $sum: 1 },
        totalScore: { $sum: '$score' },
      },
    },
    { $sort: { avgScore: -1, count: -1 } },
    { $limit: Number(limit) },
  ]);

  const students = await Student.find({ _id: { $in: topPresenters.map((p) => p._id) } }).select('name studentId');
  const info = new Map(students.map((s) => [String(s._id), s]));

  return topPresenters.map((p, i) => ({
    rank: i + 1,
    studentId: p._id,
    name: info.get(String(p._id))?.name || '-',
    studentCode: info.get(String(p._id))?.studentId || '',
    avgScore: Math.round(p.avgScore * 10) / 10,
    count: p.count,
    totalScore: p.totalScore,
  }));
};

module.exports = {
  recordPresentation,
  getStudentPresentations,
  getMonthlyPresentations,
  getTopPresenters,
};
