const Parent = require('../models/Parent');
const Student = require('../models/Student');
const Feedback = require('../models/Feedback');
const StudentAttendance = require('../models/StudentAttendance');
const Exam = require('../models/Exam');
const { getFeatureFlag } = require('./settingsService');
const feedbackService = require('./feedbackService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const assertPortalEnabled = async () => {
  const enabled = await getFeatureFlag('parentPortalEnabled');
  if (!enabled) {
    throw Object.assign(new Error('Parent portal is not enabled'), { statusCode: 501, code: 'NOT_ENABLED' });
  }
};

const assertChildAccess = async (parent, studentId) => {
  const allowed = (parent.children || []).some((childId) => String(childId) === String(studentId));
  if (!allowed) {
    throw Object.assign(new Error('Child not linked to this parent account'), { statusCode: 403, code: 'FORBIDDEN' });
  }
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

const listChildren = async (parent) => {
  await assertPortalEnabled();
  const students = await Student.find({ _id: { $in: parent.children || [] } });
  return students.map(formatChild);
};

const getChildOverview = async (parent, studentId) => {
  await assertPortalEnabled();
  await assertChildAccess(parent, studentId);

  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const [feedbackCount, attendanceRecords, exams] = await Promise.all([
    Feedback.countDocuments({ student: studentId }),
    StudentAttendance.find({ student: studentId }).sort({ date: -1 }).limit(30),
    Exam.find({ 'results.student': studentId }).select('examName subject examDate status results'),
  ]);

  const present = attendanceRecords.filter((a) => a.status === 'present').length;
  const absent = attendanceRecords.filter((a) => a.status === 'absent').length;

  return {
    child: formatChild(student),
    summary: {
      feedbackCount,
      attendance: { present, absent, total: attendanceRecords.length },
      examCount: exams.length,
    },
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
      .sort({ date: -1 })
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
      homework: doc.homework,
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
      .sort({ date: -1 })
      .skip(skip)
      .limit(limit),
    StudentAttendance.countDocuments(filter),
  ]);

  return {
    items: records.map((doc) => ({
      id: doc._id,
      className: doc.classSchedule?.className,
      date: doc.date,
      status: doc.status,
      createdAt: doc.createdAt,
    })),
    meta: buildPaginationMeta(page, limit, total),
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

module.exports = {
  assertPortalEnabled,
  assertChildAccess,
  listChildren,
  getChildOverview,
  getChildFeedback,
  getChildAttendance,
  getChildExams,
};
