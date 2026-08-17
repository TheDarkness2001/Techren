const Payment = require('../models/Payment');
const Branch = require('../models/Branch');
const Student = require('../models/Student');
const { getBranchFilter } = require('../utils/branchFilter');
const { getTashkentParts, billingPeriodFromQuery } = require('../utils/classWindow');
const { forbidden } = require('../utils/resourceAccess');
const { buildDuesByStudent } = require('./paymentService');
const { aggregateBranchCollections } = require('../utils/branchCollections');
const { totalsByBranch } = require('./branchExpenseService');

const paidFilter = (req) => ({
  ...getBranchFilter(req),
  status: 'paid',
});

const pendingFilter = (req) => ({
  ...getBranchFilter(req),
  status: { $in: ['pending', 'partial', 'overdue'] },
});

const applyDateRange = (filter, startDate, endDate) => {
  if (startDate || endDate) {
    filter.paidDate = {};
    if (startDate) {
      const start = new Date(startDate);
      start.setHours(0, 0, 0, 0);
      filter.paidDate.$gte = start;
    }
    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      filter.paidDate.$lte = end;
    }
  }
  return filter;
};

const groupSum = (payments, keyFn) =>
  payments.reduce((acc, payment) => {
    const key = keyFn(payment) || 'other';
    acc[key] = (acc[key] || 0) + Number(payment.amount || 0);
    return acc;
  }, {});

const getSummary = async (req) => {
  const filter = applyDateRange(paidFilter(req), req.query.startDate, req.query.endDate);
  if (req.query.academicYear) filter.academicYear = req.query.academicYear;
  if (req.query.term) filter.term = req.query.term;

  // Aggregation-only for the dashboard — avoid shipping every payment row to the browser.
  const [payments, pendingPayments] = await Promise.all([
    Payment.find(filter).select('amount paymentType paymentMethod subject'),
    Payment.find(pendingFilter(req)).select('amount'),
  ]);

  return {
    totalRevenue: payments.reduce((sum, p) => sum + Number(p.amount || 0), 0),
    totalTransactions: payments.length,
    totalPending: pendingPayments.reduce((sum, p) => sum + Number(p.amount || 0), 0),
    pendingCount: pendingPayments.length,
    revenueByType: groupSum(payments, (p) => p.paymentType),
    revenueByMethod: groupSum(payments, (p) => p.paymentMethod),
    revenueBySubject: groupSum(payments, (p) => p.subject),
  };
};

const getPending = async (req) => {
  const payments = await Payment.find(pendingFilter(req))
    .populate('student', 'name studentId email')
    .sort({ dueDate: 1 });

  return {
    totalPending: payments.reduce((sum, p) => sum + p.amount, 0),
    count: payments.length,
    payments: payments.map((p) => ({
      id: p._id,
      studentName: p.student?.name,
      studentCode: p.student?.studentId,
      amount: p.amount,
      subject: p.subject,
      status: p.status,
      dueDate: p.dueDate,
      month: p.month,
      year: p.year,
    })),
  };
};

const getChart = async (req) => {
  const filter = applyDateRange(paidFilter(req), req.query.startDate, req.query.endDate);
  const payments = await Payment.find(filter)
    .select('amount paymentType paidDate')
    .sort({ paidDate: 1 });

  const byMonth = {};
  const byDate = {};

  for (const payment of payments) {
    if (!payment.paidDate) continue;
    const date = new Date(payment.paidDate);
    const parts = getTashkentParts(date);
    const monthKey = `${parts.year}-${String(parts.month).padStart(2, '0')}`;
    const dateKey = parts.dateString;
    const amount = Number(payment.amount || 0);
    byMonth[monthKey] = (byMonth[monthKey] || 0) + amount;
    byDate[dateKey] = (byDate[dateKey] || 0) + amount;
  }

  return {
    byMonth: Object.entries(byMonth).map(([label, amount]) => ({ label, amount })),
    byDate: Object.entries(byDate).map(([label, amount]) => ({ label, amount })),
    byType: Object.entries(groupSum(payments, (p) => p.paymentType)).map(([label, amount]) => ({ label, amount })),
  };
};

const getExport = async (req) => {
  const filter = applyDateRange(paidFilter(req), req.query.startDate, req.query.endDate);
  if (req.query.academicYear) filter.academicYear = req.query.academicYear;
  if (req.query.term) filter.term = req.query.term;

  const [summary, payments] = await Promise.all([
    getSummary(req),
    Payment.find(filter)
      .populate('student', 'name studentId')
      .select('amount subject paidDate receiptNumber student')
      .sort({ paidDate: -1 })
      .limit(500),
  ]);

  return {
    generatedAt: new Date().toISOString(),
    ...summary,
    payments: payments.map((p) => ({
      id: p._id,
      studentName: p.student?.name,
      amount: p.amount,
      subject: p.subject,
      paidDate: p.paidDate,
      receiptNumber: p.receiptNumber,
    })),
  };
};

/** Founder-only: expected dues vs collected, per branch, for a billing month. */
const getBranchCollections = async (req) => {
  if (req.userType !== 'teacher' || req.user?.role !== 'founder') {
    throw forbidden('Founder only');
  }

  const { month, year } = billingPeriodFromQuery(req.query);
  const [branches, students] = await Promise.all([
    Branch.find().select('_id name').sort({ name: 1 }),
    Student.find({ status: 'active' }).select('_id branchId'),
  ]);

  const duesMap = await buildDuesByStudent({
    studentIds: students.map((student) => student._id),
    month,
    year,
  });

  const { items, totals } = aggregateBranchCollections({ branches, students, duesMap });
  const expenseMap = await totalsByBranch({ month, year });

  const withExpenses = items.map((row) => {
    const extra = expenseMap.get(row.branchId) || { expenses: 0, byCategory: {} };
    return {
      ...row,
      expenses: extra.expenses,
      leftover: row.collected - extra.expenses,
      expensesByCategory: extra.byCategory,
    };
  });
  const expenseTotal = withExpenses.reduce((sum, row) => sum + row.expenses, 0);
  return {
    month,
    year,
    items: withExpenses,
    totals: {
      ...totals,
      expenses: expenseTotal,
      leftover: totals.collected - expenseTotal,
    },
  };
};

module.exports = { getSummary, getPending, getChart, getExport, getBranchCollections };
