const BranchExpense = require('../models/BranchExpense');
const Branch = require('../models/Branch');
const Teacher = require('../models/Teacher');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { forbidden } = require('../utils/resourceAccess');
const { billingPeriodFromQuery } = require('../utils/classWindow');

const isPrivilegedStaff = (user) => ['founder', 'admin', 'manager'].includes(user?.role);

const CATEGORIES = BranchExpense.CATEGORIES || [
  'teacher-payment',
  'rent',
  'electricity',
  'repair',
  'other',
];

const assertCanManage = (req) => {
  if (req.userType !== 'teacher' || !isPrivilegedStaff(req.user)) {
    throw forbidden('Founder, admin, or manager only');
  }
};

const format = (doc) => ({
  id: doc._id,
  branchId: doc.branchId?._id || doc.branchId,
  branchName: doc.branchId?.name || '',
  category: doc.category,
  amount: Number(doc.amount || 0),
  month: doc.month,
  year: doc.year,
  notes: doc.notes || '',
  teacherId: doc.teacherId?._id || doc.teacherId || null,
  teacherName: doc.teacherName || doc.teacherId?.name || '',
  recordedByName: doc.recordedBy?.name || '',
  createdAt: doc.createdAt,
});

const list = async (req) => {
  assertCanManage(req);
  const { month, year } = billingPeriodFromQuery(req.query);
  const { page, limit, skip } = parsePagination(req.query);
  const filter = {
    month,
    year,
    ...getBranchFilter(req),
  };
  if (req.query.category && CATEGORIES.includes(req.query.category)) {
    filter.category = req.query.category;
  }

  const [items, total] = await Promise.all([
    BranchExpense.find(filter)
      .populate('branchId', 'name')
      .populate('teacherId', 'name')
      .populate('recordedBy', 'name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    BranchExpense.countDocuments(filter),
  ]);

  const allForMonth = await BranchExpense.find(filter).select('amount category');
  const byCategory = allForMonth.reduce((acc, row) => {
    acc[row.category] = (acc[row.category] || 0) + Number(row.amount || 0);
    return acc;
  }, {});
  const totalAmount = allForMonth.reduce((sum, row) => sum + Number(row.amount || 0), 0);

  return {
    items: items.map(format),
    meta: {
      ...buildPaginationMeta(page, limit, total),
      month,
      year,
      totalAmount,
      byCategory,
    },
  };
};

const create = async (req, data) => {
  assertCanManage(req);
  const { month, year } = billingPeriodFromQuery({ month: data.month, year: data.year });
  const branchId = data.branchId || req.branchId || req.user?.branchId;
  if (!branchId) {
    throw Object.assign(new Error('Branch is required'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }
  if (!canAccessBranch(req, branchId)) {
    throw forbidden();
  }
  const branch = await Branch.findById(branchId);
  if (!branch) {
    throw Object.assign(new Error('Branch not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const category = String(data.category || '').trim();
  if (!CATEGORIES.includes(category)) {
    throw Object.assign(new Error('Invalid expense category'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const amount = Number(data.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw Object.assign(new Error('Enter an amount greater than 0'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  let teacherName = String(data.teacherName || '').trim();
  let teacherId = data.teacherId || null;
  if (teacherId) {
    const teacher = await Teacher.findById(teacherId).select('name');
    if (teacher) teacherName = teacher.name;
  }

  const notes = String(data.notes || '').trim();
  if (category === 'other' && !notes) {
    throw Object.assign(new Error('Add a note for other expenses'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const doc = await BranchExpense.create({
    branchId,
    category,
    amount,
    month,
    year,
    notes,
    teacherId: teacherId || undefined,
    teacherName,
    recordedBy: req.user?._id,
  });

  return getOne(doc._id, req);
};

const getOne = async (id, req) => {
  const doc = await BranchExpense.findOne({ _id: id, ...getBranchFilter(req) })
    .populate('branchId', 'name')
    .populate('teacherId', 'name')
    .populate('recordedBy', 'name');
  if (!doc) {
    throw Object.assign(new Error('Expense not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(doc);
};

const update = async (req, id, data) => {
  assertCanManage(req);
  const doc = await BranchExpense.findOne({ _id: id, ...getBranchFilter(req) });
  if (!doc) {
    throw Object.assign(new Error('Expense not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, doc.branchId)) {
    throw forbidden();
  }

  const category = String(data.category || doc.category).trim();
  if (!CATEGORIES.includes(category)) {
    throw Object.assign(new Error('Invalid expense category'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const amount = Number(data.amount ?? doc.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw Object.assign(new Error('Enter an amount greater than 0'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  let teacherName = String(data.teacherName ?? doc.teacherName ?? '').trim();
  let teacherId = data.teacherId !== undefined ? data.teacherId : doc.teacherId;
  if (teacherId) {
    const teacher = await Teacher.findById(teacherId).select('name');
    if (teacher) teacherName = teacher.name;
  } else {
    teacherId = null;
    teacherName = '';
  }

  const notes = String(data.notes ?? doc.notes ?? '').trim();
  if (category === 'other' && !notes) {
    throw Object.assign(new Error('Add a note for other expenses'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  doc.category = category;
  doc.amount = amount;
  doc.notes = notes;
  doc.teacherId = teacherId || undefined;
  doc.teacherName = teacherName;
  await doc.save();

  return getOne(doc._id, req);
};

const remove = async (req, id) => {
  assertCanManage(req);
  const doc = await BranchExpense.findOne({ _id: id, ...getBranchFilter(req) });
  if (!doc) {
    throw Object.assign(new Error('Expense not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, doc.branchId)) {
    throw forbidden();
  }
  await doc.deleteOne();
  return { deleted: true, id: String(id) };
};

const totalsByBranch = async ({ month, year, branchFilter = {} }) => {
  const rows = await BranchExpense.find({ month, year, ...branchFilter }).select('branchId amount category');
  const map = new Map();
  for (const row of rows) {
    const id = String(row.branchId);
    if (!map.has(id)) map.set(id, { expenses: 0, byCategory: {} });
    const entry = map.get(id);
    const amount = Number(row.amount || 0);
    entry.expenses += amount;
    entry.byCategory[row.category] = (entry.byCategory[row.category] || 0) + amount;
  }
  return map;
};

module.exports = {
  CATEGORIES,
  list,
  create,
  getOne,
  update,
  remove,
  totalsByBranch,
};
