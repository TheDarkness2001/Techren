const Payment = require('../models/Payment');
const { getBranchFilter } = require('../utils/branchFilter');

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
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    const dateKey = date.toISOString().slice(0, 10);
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

module.exports = { getSummary, getPending, getChart, getExport };
