const mongoose = require('mongoose');
const StudentAttendance = require('../models/StudentAttendance');
const Student = require('../models/Student');
const ClassSchedule = require('../models/ClassSchedule');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const { getTashkentParts, isScheduleToday, isWithinClassWindow, canBypassTimeWindow } = require('../utils/classWindow');
const { isPrivilegedStaff } = require('../middleware/auth');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { findSettingsDocument } = require('./settingsService');

const format = (doc) => ({
  id: doc._id,
  student: doc.student,
  studentName: doc.student?.name,
  classSchedule: doc.classSchedule,
  className: doc.classSchedule?.className,
  date: doc.date,
  status: doc.status,
  markedBy: doc.markedBy,
  createdAt: doc.createdAt,
});

const assertCanMark = (schedule, user) => {
  if (canBypassTimeWindow(user)) return;
  if (!isWithinClassWindow(schedule)) {
    throw Object.assign(
      new Error('Attendance can only be marked during class hours (+30 min grace)'),
      { statusCode: 403, code: 'OUTSIDE_TIME_WINDOW' }
    );
  }
};

const getTodayClassesForTeacher = async (teacherId) => {
  const parts = getTashkentParts();
  const schedules = await ClassSchedule.find({ teacher: teacherId })
    .populate('teacher', 'name subject')
    .populate('enrolledStudents', 'name email studentId status profileImage')
    .populate('subjectGroup', 'groupName')
    .sort({ startTime: 1 });

  return await buildClassSessions(schedules, parts, { scopeToday: true });
};

const resolveSubjectName = (schedule) => {
  if (schedule.subject && typeof schedule.subject === 'object' && schedule.subject.name) {
    return schedule.subject.name;
  }
  if (typeof schedule.subject === 'string' && schedule.subject.trim()) return schedule.subject;
  const teacherSubject = schedule.teacher?.subject?.[0];
  if (teacherSubject) return teacherSubject;
  return 'General';
};

const buildClassSessions = async (schedules, parts, { scopeToday = true, feedbackDate } = {}) => {
  const relevant = scopeToday ? schedules.filter((s) => isScheduleToday(s, parts)) : schedules;
  const dateString = feedbackDate || parts.dateString;

  const attendance = await StudentAttendance.find({
    classSchedule: { $in: relevant.map((s) => s._id) },
    date: dateString,
  });

  const Feedback = require('../models/Feedback');
  const feedbackRecords = await Feedback.find({
    classSchedule: { $in: relevant.map((s) => s._id) },
    date: dateString,
  });

  return relevant.map((schedule) => ({
    schedule: {
      id: schedule._id,
      className: schedule.className,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      scheduledDays: schedule.scheduledDays,
      studentCount: schedule.enrolledStudents?.length ?? 0,
      teacherName: schedule.teacher?.name,
      teacherId: schedule.teacher?._id || schedule.teacher,
      subjectName: resolveSubjectName(schedule),
      room: schedule.subjectGroup?.groupName || schedule.className,
    },
    isWithinWindow: isWithinClassWindow(schedule, 30, parts),
    students: (schedule.enrolledStudents || []).map((student) => {
      const mark = attendance.find(
        (a) => String(a.student) === String(student._id) && String(a.classSchedule) === String(schedule._id)
      );
      const feedback = feedbackRecords.find(
        (f) => String(f.student) === String(student._id) && String(f.classSchedule) === String(schedule._id)
      );
      return {
        id: student._id,
        name: student.name,
        studentId: student.studentId,
        status: student.status,
        profileImage: student.profileImage,
        attendance: mark ? { id: mark._id, status: mark.status } : null,
        hasFeedback: Boolean(feedback),
      };
    }),
  }));
};

const getClassesForFeedback = async (req) => {
  const dateParam = typeof req.query.date === 'string' && req.query.date.trim()
    ? req.query.date.trim()
    : null;
  // Use noon local parse so weekday matches the intended calendar day in Tashkent.
  const parts = dateParam
    ? getTashkentParts(new Date(`${dateParam}T12:00:00+05:00`))
    : getTashkentParts();

  const filter = { ...getBranchFilter(req) };
  const privileged = req.userType === 'teacher' && isPrivilegedStaff(req.user);

  if (req.query.teacherId && req.query.teacherId !== 'all') {
    if (mongoose.Types.ObjectId.isValid(req.query.teacherId)) {
      filter.teacher = new mongoose.Types.ObjectId(req.query.teacherId);
    } else {
      filter.teacher = req.query.teacherId;
    }
  } else if (!privileged && req.userType === 'teacher') {
    filter.teacher = req.user._id;
  }

  const schedules = await ClassSchedule.find(filter)
    .populate('teacher', 'name subject')
    .populate('enrolledStudents', 'name email studentId status profileImage')
    .populate('subjectGroup', 'groupName')
    .sort({ startTime: 1 });

  const scopeToday = req.query.scope !== 'all';
  return await buildClassSessions(schedules, parts, {
    scopeToday,
    feedbackDate: dateParam || parts.dateString,
  });
};

const markBulk = async (req, { classScheduleId, date, records }) => {
  const schedule = await ClassSchedule.findById(classScheduleId).populate('enrolledStudents', '_id');
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (req.userType === 'teacher' && !isPrivilegedStaff(req.user) && String(schedule.teacher) !== String(req.user._id)) {
    throw Object.assign(new Error('You can only mark your own classes'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  assertCanMark(schedule, req.user);

  const markDate = date || getTashkentParts().dateString;
  const results = [];

  for (const record of records) {
    const attendance = await StudentAttendance.findOneAndUpdate(
      { student: record.studentId, classSchedule: classScheduleId, date: markDate },
      {
        $set: {
          status: record.status,
          markedBy: req.user._id,
          teacher: schedule.teacher,
          branchId: schedule.branchId,
        },
      },
      { upsert: true, new: true }
    );
    results.push(attendance);

    if (record.status === 'absent') {
      await updateExamEligibility(record.studentId);
    }
  }

  return results.map((r) => format(r));
};

const updateExamEligibility = async (studentId) => {
  const parts = getTashkentParts();
  const threeDaysAgo = new Date(parts.dateString);
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 2);
  const fromDate = threeDaysAgo.toISOString().slice(0, 10);

  const recentAbsent = await StudentAttendance.find({
    student: studentId,
    status: 'absent',
    date: { $gte: fromDate, $lte: parts.dateString },
  }).sort({ date: -1 });

  const uniqueDates = [...new Set(recentAbsent.map((a) => a.date))];
  if (uniqueDates.length >= 3) {
    await Student.findByIdAndUpdate(studentId, { examEligibility: false });
  }
};

const assertCanAccessStudentData = async (req, studentId) => {
  const sid = String(studentId);

  if (req.userType === 'student') {
    if (String(req.user._id) !== sid) {
      throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
    }
    return;
  }

  if (req.userType === 'parent') {
    const children = req.user.children || [];
    const ok = children.some((child) => String(child._id || child) === sid);
    if (!ok) {
      throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
    }
    return;
  }

  if (req.userType !== 'teacher') {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  if (!isPrivilegedStaff(req.user)) {
    const settings = req.settings || (await findSettingsDocument());
    const rolePerms = settings?.rolePermissions?.[req.user.role];
    const allowed =
      rolePerms?.canViewAttendance === true
      || req.user.permissions?.get?.('canViewAttendance') === true
      || req.user.permissions?.canViewAttendance === true;
    if (!allowed) {
      throw Object.assign(new Error('Missing permission: canViewAttendance'), {
        statusCode: 403,
        code: 'FORBIDDEN',
      });
    }
  }

  const student = await Student.findById(studentId).select('branchId');
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, student.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }
};

const getStudentHistory = async (studentId, req) => {
  await assertCanAccessStudentData(req, studentId);
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { student: studentId, ...getBranchFilter(req) };

  const [items, total] = await Promise.all([
    StudentAttendance.find(filter)
      .populate('classSchedule', 'className startTime endTime')
      .sort({ date: -1 })
      .skip(skip)
      .limit(limit),
    StudentAttendance.countDocuments(filter),
  ]);

  return { items: items.map(format), meta: buildPaginationMeta(page, limit, total) };
};

const getEligibility = async (studentId, req) => {
  await assertCanAccessStudentData(req, studentId);
  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const parts = getTashkentParts();
  const threeDaysAgo = new Date(parts.dateString);
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 2);
  const fromDate = threeDaysAgo.toISOString().slice(0, 10);

  const recentAbsent = await StudentAttendance.find({
    student: studentId,
    status: 'absent',
    date: { $gte: fromDate, $lte: parts.dateString },
  });

  return {
    studentId,
    examEligibility: student.examEligibility,
    recentAbsences: recentAbsent.length,
    blocked: !student.examEligibility,
  };
};

const list = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };
  if (req.query.date) filter.date = req.query.date;
  if (req.query.classScheduleId) filter.classSchedule = req.query.classScheduleId;

  const [items, total] = await Promise.all([
    StudentAttendance.find(filter)
      .populate('student', 'name studentId')
      .populate('classSchedule', 'className')
      .sort({ date: -1 })
      .skip(skip)
      .limit(limit),
    StudentAttendance.countDocuments(filter),
  ]);

  return { items: items.map(format), meta: buildPaginationMeta(page, limit, total) };
};

module.exports = {
  getTodayClassesForTeacher,
  getClassesForFeedback,
  markBulk,
  getStudentHistory,
  getEligibility,
  list,
  updateExamEligibility,
};
