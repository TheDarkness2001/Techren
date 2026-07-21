const Payment = require('../models/Payment');
const Student = require('../models/Student');
const ExamGroup = require('../models/ExamGroup');
const { getBranchFilter } = require('../utils/branchFilter');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const generateReceipt = () => `RCP-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

const format = (doc) => ({
  id: doc._id,
  student: doc.student,
  studentName: doc.student?.name,
  studentCode: doc.student?.studentId,
  amount: doc.amount,
  paymentType: doc.paymentType,
  paymentMethod: doc.paymentMethod,
  status: doc.status,
  subject: doc.subject,
  dueDate: doc.dueDate,
  paidDate: doc.paidDate,
  receiptNumber: doc.receiptNumber,
  academicYear: doc.academicYear,
  term: doc.term,
  notes: doc.notes,
  recordedBy: doc.recordedBy,
  recordedByName: doc.recordedBy?.name,
  month: doc.month,
  year: doc.year,
  branchId: doc.branchId,
  createdAt: doc.createdAt,
});

const buildFilter = async (req) => {
  const filter = { ...getBranchFilter(req) };

  if (req.userType === 'student') {
    // Never allow query overrides to read another student's payments.
    filter.student = req.user._id;
  } else if (req.query.studentId) {
    filter.student = req.query.studentId;
  }
  if (req.query.status) filter.status = req.query.status;
  if (req.query.paymentType) filter.paymentType = req.query.paymentType;
  if (req.query.subject) filter.subject = req.query.subject;
  if (req.query.academicYear) filter.academicYear = req.query.academicYear;
  if (req.query.term) filter.term = req.query.term;
  if (req.query.month) filter.month = Number(req.query.month);
  if (req.query.year) filter.year = Number(req.query.year);

  if (req.query.search) {
    const term = String(req.query.search).trim();
    if (term) {
      const branchFilter = getBranchFilter(req);
      const studentFilter = {
        $or: [
          { name: { $regex: term, $options: 'i' } },
          { email: { $regex: term, $options: 'i' } },
          { studentId: { $regex: term, $options: 'i' } },
        ],
        ...(branchFilter.branchId ? { branchId: branchFilter.branchId } : {}),
      };
      const matchingStudents = await Student.find(studentFilter).select('_id');
      const studentIds = matchingStudents.map((student) => student._id);

      const searchClause = {
        $or: [
          { student: { $in: studentIds } },
          { subject: { $regex: term, $options: 'i' } },
          { receiptNumber: { $regex: term, $options: 'i' } },
        ],
      };

      if (Object.keys(filter).length > 0) {
        const baseFilter = { ...filter };
        return { $and: [baseFilter, searchClause] };
      }
      return searchClause;
    }
  }

  return filter;
};

const list = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = await buildFilter(req);

  const [items, total] = await Promise.all([
    Payment.find(filter)
      .populate('student', 'name studentId email')
      .populate('recordedBy', 'name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Payment.countDocuments(filter),
  ]);

  return { items: items.map(format), meta: buildPaginationMeta(page, limit, total) };
};

const getOne = async (id, filter = {}) => {
  const payment = await Payment.findOne({ _id: id, ...filter })
    .populate('student', 'name studentId email')
    .populate('recordedBy', 'name');
  if (!payment) {
    throw Object.assign(new Error('Payment not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(payment);
};

const create = async (req, data) => {
  const student = await Student.findById(data.studentId || data.student);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const payload = {
    student: student._id,
    amount: data.amount,
    paymentType: data.paymentType,
    paymentMethod: data.paymentMethod || data.method || 'cash',
    status: data.status || 'pending',
    subject: data.subject,
    dueDate: data.dueDate,
    academicYear: data.academicYear,
    term: data.term,
    notes: data.notes || '',
    month: data.month,
    year: data.year,
    recordedBy: req.user?._id,
    branchId: data.branchId || req.branchId || student.branchId,
  };

  if (payload.status === 'paid') {
    payload.receiptNumber = generateReceipt();
    payload.paidDate = new Date();
  }

  const payment = await Payment.create(payload);
  return getOne(payment._id);
};

const update = async (id, filter, data) => {
  const payment = await Payment.findOne({ _id: id, ...filter });
  if (!payment) {
    throw Object.assign(new Error('Payment not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const updates = { ...data };
  if (updates.method && !updates.paymentMethod) updates.paymentMethod = updates.method;
  delete updates.method;

  if (updates.status === 'paid' && !payment.receiptNumber) {
    updates.receiptNumber = generateReceipt();
    updates.paidDate = updates.paidDate || new Date();
  }

  Object.assign(payment, updates);
  await payment.save();
  return getOne(payment._id);
};

const remove = async (id, filter = {}) => {
  const payment = await Payment.findOneAndDelete({ _id: id, ...filter });
  if (!payment) {
    throw Object.assign(new Error('Payment not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(payment);
};

const termFromMonth = (month) => {
  if (month <= 4) return '1st-term';
  if (month <= 8) return '2nd-term';
  return '3rd-term';
};

/**
 * Monthly student × course payment matrix for staff "accept money" UI.
 */
const listRoster = async (req) => {
  const month = Math.min(12, Math.max(1, Number(req.query.month) || new Date().getMonth() + 1));
  const year = Number(req.query.year) || new Date().getFullYear();
  const search = typeof req.query.search === 'string' ? req.query.search.trim() : '';
  const branchFilter = getBranchFilter(req);

  const studentFilter = {
    status: 'active',
    ...branchFilter,
  };
  if (search) {
    studentFilter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } },
      { studentId: { $regex: search, $options: 'i' } },
    ];
  }

  const students = await Student.find(studentFilter).sort({ name: 1 }).limit(200);
  if (!students.length) {
    return { items: [], meta: { month, year, total: 0 } };
  }

  const studentIds = students.map((s) => s._id);
  const groups = await ExamGroup.find({
    students: { $in: studentIds },
    ...branchFilter,
  })
    .populate('subject', 'name pricePerClass code')
    .select('subject students groupName');

  const payments = await Payment.find({
    student: { $in: studentIds },
    month,
    year,
    ...branchFilter,
  }).select('student subject amount status');

  const paidByStudentSubject = new Map();
  for (const payment of payments) {
    if (payment.status !== 'paid' && payment.status !== 'partial') continue;
    const sid = String(payment.student);
    const subj = String(payment.subject || '').trim().toLowerCase();
    const key = `${sid}::${subj}`;
    paidByStudentSubject.set(key, (paidByStudentSubject.get(key) || 0) + Number(payment.amount || 0));
  }

  const coursesByStudent = new Map();
  for (const group of groups) {
    const subjectDoc = group.subject;
    const subjectName = subjectDoc?.name || group.groupName || 'Course';
    const subjectId = subjectDoc?._id ? String(subjectDoc._id) : null;
    const amountDue = Number(subjectDoc?.pricePerClass || 0);
    for (const studentRef of group.students || []) {
      const sid = String(studentRef);
      if (!coursesByStudent.has(sid)) coursesByStudent.set(sid, new Map());
      const map = coursesByStudent.get(sid);
      const courseKey = subjectName.toLowerCase();
      if (!map.has(courseKey)) {
        map.set(courseKey, {
          subjectId,
          subjectName,
          amountDue,
        });
      } else if (amountDue > 0 && map.get(courseKey).amountDue === 0) {
        map.get(courseKey).amountDue = amountDue;
      }
    }
  }

  const items = students.map((student) => {
    const sid = String(student._id);
    const courseMap = coursesByStudent.get(sid) || new Map();
    const courses = [...courseMap.values()].map((course) => {
      const paidKey = `${sid}::${course.subjectName.toLowerCase()}`;
      const amountPaid = Number(paidByStudentSubject.get(paidKey) || 0);
      const amountDue = course.amountDue > 0 ? course.amountDue : Math.max(amountPaid, 0);
      let status = 'unpaid';
      if (amountDue > 0 && amountPaid >= amountDue) status = 'paid';
      else if (amountPaid > 0) status = 'partial';
      else if (amountDue === 0 && amountPaid > 0) status = 'paid';

      return {
        subjectId: course.subjectId,
        subjectName: course.subjectName,
        amountDue: amountDue || course.amountDue,
        amountPaid,
        status,
      };
    });

    const overallStatus =
      courses.length > 0 && courses.every((c) => c.status === 'paid') ? 'paid' : 'unpaid';

    return {
      id: student._id,
      studentCode: student.studentId,
      name: student.name,
      courses,
      overallStatus,
    };
  });

  // Prefer students who have courses; still show others so fees can be recorded.
  items.sort((a, b) => {
    if (a.overallStatus !== b.overallStatus) return a.overallStatus === 'unpaid' ? -1 : 1;
    return a.name.localeCompare(b.name);
  });

  return {
    items,
    meta: {
      month,
      year,
      total: items.length,
      term: termFromMonth(month),
      academicYear: month >= 9 ? `${year}-${year + 1}` : `${year - 1}-${year}`,
    },
  };
};

module.exports = { list, getOne, create, update, remove, listRoster, format, generateReceipt, termFromMonth };
