const Parent = require('../models/Parent');
const Student = require('../models/Student');
const Feedback = require('../models/Feedback');
const StudentAttendance = require('../models/StudentAttendance');
const Exam = require('../models/Exam');
const Payment = require('../models/Payment');
const { getFeatureFlag } = require('./settingsService');
const feedbackService = require('./feedbackService');
const paymentService = require('./paymentService');
const communicationService = require('./communicationService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { assertParentChild } = require('../utils/resourceAccess');
const { billingPeriodFromQuery, getTashkentParts, addCalendarDays } = require('../utils/classWindow');
const homeworkService = require('./homeworkService');
const timetableService = require('./timetableService');

const assertPortalEnabled = async () => {
  const enabled = await getFeatureFlag('parentPortalEnabled');
  if (!enabled) {
    throw Object.assign(new Error('Parent portal is not enabled'), { statusCode: 501, code: 'NOT_ENABLED' });
  }
};

const assertChildAccess = async (parent, studentId) => {
  assertParentChild(parent, studentId);
};

const formatChild = (student) => ({
  id: student._id,
  studentId: student.studentId,
  name: student.name,
  email: student.email,
  status: student.status,
  examEligibility: student.examEligibility,
  branchId: student.branchId,
  profileImage: student.profileImage,
});

const relationLabel = (relation) => {
  if (relation === 'mother') return 'mother';
  if (relation === 'father') return 'father';
  return 'guardian';
};

const listChildren = async (parent) => {
  await assertPortalEnabled();
  const students = await Student.find({ _id: { $in: parent.children || [] } });
  return students.map(formatChild);
};

const getChildPayments = async (parent, studentId, query = {}) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const { month, year } = billingPeriodFromQuery(query);

  const dues = await paymentService.getStudentDues(studentId, month, year);
  const amountPaid = (dues.courses || []).reduce((sum, c) => sum + Number(c.amountPaid || 0), 0);
  const amountDue = (dues.courses || []).reduce((sum, c) => sum + Number(c.amountDue || 0), 0);

  const recent = await Payment.find({ student: studentId })
    .sort({ createdAt: -1 })
    .limit(20)
    .lean();

  return {
    month,
    year,
    overallStatus: dues.overallStatus,
    amountRemaining: dues.amountRemaining,
    amountPaid,
    amountDue,
    isPaid: dues.isPaid,
    courses: dues.courses,
    recentPayments: recent.map((p) => ({
      id: p._id,
      amount: p.amount,
      status: p.status,
      paymentType: p.paymentType,
      subject: p.subject,
      month: p.month,
      year: p.year,
      dueDate: p.dueDate,
      paidDate: p.paidDate,
      createdAt: p.createdAt,
    })),
  };
};

const getChildAlerts = async (parent, studentId) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const now = new Date();
  const { month, year } = billingPeriodFromQuery();
  const sinceAttendanceStr = addCalendarDays(getTashkentParts().dateString, -14);
  const sinceFeedback = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const [dues, absences, recentFeedback] = await Promise.all([
    paymentService.getStudentDues(studentId, month, year),
    StudentAttendance.find({
      student: studentId,
      status: 'absent',
      date: { $gte: sinceAttendanceStr },
      $or: [{ excuseSubmittedAt: null }, { excuseSubmittedAt: { $exists: false } }, { excuseReason: '' }],
    })
      .sort({ date: -1 })
      .limit(10),
    Feedback.find({ student: studentId, createdAt: { $gte: sinceFeedback } })
      .sort({ createdAt: -1 })
      .limit(10),
  ]);

  const alerts = [];

  if (Number(dues.amountRemaining || 0) > 0 || ['unpaid', 'partial', 'overdue'].includes(dues.overallStatus)) {
    alerts.push({
      type: 'payment',
      severity: dues.overallStatus === 'overdue' ? 'high' : 'medium',
      title: 'Payment remaining',
      body: `Remaining this month: ${Number(dues.amountRemaining || 0).toFixed(0)} UZS (${dues.overallStatus})`,
      createdAt: now.toISOString(),
      refId: null,
    });
  }

  for (const a of absences) {
    alerts.push({
      type: 'attendance',
      severity: 'high',
      title: 'Absence needs explanation',
      body: `Absent on ${a.date}. Please send a reason to the teacher.`,
      createdAt: a.createdAt || now.toISOString(),
      refId: String(a._id),
    });
  }

  for (const f of recentFeedback) {
    alerts.push({
      type: 'feedback',
      severity: 'low',
      title: 'New teacher feedback',
      body: `Feedback on ${f.date || ''}`,
      createdAt: f.createdAt || now.toISOString(),
      refId: String(f._id),
    });
  }

  alerts.sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
  return { alerts };
};

const getChildOverview = async (parent, studentId) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const now = new Date();
  const [feedbackCount, attendanceRecords, exams, payments, alerts] = await Promise.all([
    Feedback.countDocuments({ student: studentId }),
    StudentAttendance.find({ student: studentId }).sort({ date: -1 }).limit(30),
    Exam.find({ 'results.student': studentId }).select('examName subject examDate status results'),
    getChildPayments(parent, studentId, billingPeriodFromQuery()),
    getChildAlerts(parent, studentId),
  ]);

  const present = attendanceRecords.filter((a) => a.status === 'present').length;
  const absent = attendanceRecords.filter((a) => a.status === 'absent').length;

  return {
    child: formatChild(student),
    summary: {
      feedbackCount,
      attendance: { present, absent, total: attendanceRecords.length },
      examCount: exams.length,
      payments: {
        overallStatus: payments.overallStatus,
        amountRemaining: payments.amountRemaining,
        amountPaid: payments.amountPaid,
        isPaid: payments.isPaid,
      },
    },
    alerts: alerts.alerts,
  };
};

const getChildFeedback = async (parent, studentId, query = {}) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const { page, limit, skip } = parsePagination(query);
  let filter = { student: studentId };

  if (query.search) {
    const student = await Student.findById(studentId).select('branchId');
    filter = await feedbackService.applyFeedbackSearch(filter, query.search, {
      branchId: student?.branchId,
      studentId,
    });
  }

  const [items, total] = await Promise.all([
    Feedback.find(filter)
      .populate('classSchedule', 'className')
      .populate('teacher', 'name')
      .sort({ date: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Feedback.countDocuments(filter),
  ]);

  return {
    items: items.map((doc) => ({
      id: doc._id,
      student: doc.student,
      className: doc.classSchedule?.className,
      teacherName: doc.teacher?.name,
      date: doc.date,
      homework: doc.homework ?? 0,
      words: doc.words ?? 0,
      sentence: doc.sentence ?? 0,
      metricsMode: doc.metricsMode || 'standard',
      behavior: doc.behavior,
      participation: doc.participation,
      isExamDay: doc.isExamDay,
      examPercentage: doc.examPercentage,
      parentComments: doc.parentComments,
      notes: doc.notes,
      createdAt: doc.createdAt,
    })),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getChildAttendance = async (parent, studentId, query = {}) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const { page, limit, skip } = parsePagination(query);
  const filter = { student: studentId };

  const [records, total] = await Promise.all([
    StudentAttendance.find(filter)
      .populate('classSchedule', 'className')
      .populate('teacher', 'name')
      .sort({ date: -1 })
      .skip(skip)
      .limit(limit),
    StudentAttendance.countDocuments(filter),
  ]);

  return {
    items: records.map((doc) => ({
      id: doc._id,
      className: doc.classSchedule?.className,
      teacherName: doc.teacher?.name || null,
      date: doc.date,
      status: doc.status,
      excuseReason: doc.excuseReason || '',
      excuseSubmittedAt: doc.excuseSubmittedAt || null,
      canSubmitExcuse: doc.status === 'absent' && !doc.excuseSubmittedAt,
      createdAt: doc.createdAt,
    })),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const submitAbsenceExcuse = async (parent, studentId, attendanceId, reason) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const text = String(reason || '').trim();
  if (text.length < 3) {
    throw Object.assign(new Error('Please enter a short reason'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const attendance = await StudentAttendance.findById(attendanceId);
  if (!attendance || String(attendance.student) !== String(studentId)) {
    throw Object.assign(new Error('Attendance record not found'), {
      statusCode: 404,
      code: 'NOT_FOUND',
    });
  }
  if (attendance.status !== 'absent') {
    throw Object.assign(new Error('Only absences can be explained'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }
  if (attendance.excuseSubmittedAt) {
    throw Object.assign(new Error('An excuse was already sent for this absence'), {
      statusCode: 409,
      code: 'DUPLICATE',
    });
  }

  const teacherId = attendance.teacher || attendance.markedBy;
  if (!teacherId) {
    throw Object.assign(new Error('No teacher is linked to this absence'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const student = await Student.findById(studentId).select('studentId name');
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const parentDoc = await Parent.findById(parent._id);
  const studentCode = student.studentId || String(student._id).slice(-4);
  const rel = relationLabel(parentDoc?.relation);
  const parentName = parentDoc?.name || parent.name || 'Parent';

  const body = [
    'Absence excuse',
    `Student ID: ${studentCode}`,
    `Parent: ${parentName} (${rel})`,
    `Date: ${attendance.date}`,
    `Reason: ${text}`,
  ].join('\n');

  const sent = await communicationService.sendParentAbsenceExcuse({
    parent: parentDoc || parent,
    teacherId,
    body,
  });

  attendance.excuseReason = text;
  attendance.excuseSubmittedAt = new Date();
  attendance.excuseMessageId = sent.messageId;
  attendance.excuseConversationId = sent.conversationId;
  await attendance.save();

  return {
    ok: true,
    attendanceId: String(attendance._id),
    conversationId: sent.conversationId,
    messageId: sent.messageId,
  };
};

const getChildExams = async (parent, studentId, query = {}) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const { page, limit, skip } = parsePagination(query);
  const filter = { 'results.student': studentId };

  const [exams, total] = await Promise.all([
    Exam.find(filter)
      .select('examName subject class examDate status results totalMarks passingMarks')
      .sort({ examDate: -1 })
      .skip(skip)
      .limit(limit),
    Exam.countDocuments(filter),
  ]);

  return {
    items: exams.map((exam) => {
      const result = exam.results.find((r) => String(r.student) === String(studentId));
      return {
        id: exam._id,
        examName: exam.examName,
        subject: exam.subject,
        className: exam.class,
        examDate: exam.examDate,
        status: exam.status,
        totalMarks: exam.totalMarks,
        passingMarks: exam.passingMarks,
        marksObtained: result?.marksObtained ?? null,
        grade: result?.grade ?? '',
        passed: result?.passed ?? false,
      };
    }),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getChildHomework = async (parent, studentId) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);
  const progress = await homeworkService.getProgress(studentId);
  return { progress };
};

const getChildSchedule = async (parent, studentId) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);
  return timetableService.getTimetableForStudent(studentId);
};

module.exports = {
  assertPortalEnabled,
  assertChildAccess,
  listChildren,
  getChildOverview,
  getChildFeedback,
  getChildAttendance,
  getChildExams,
  getChildPayments,
  getChildAlerts,
  getChildHomework,
  getChildSchedule,
  submitAbsenceExcuse,
};
