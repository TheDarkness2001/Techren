const Exam = require('../models/Exam');
const Student = require('../models/Student');
const ClassSchedule = require('../models/ClassSchedule');
const ExamGroup = require('../models/ExamGroup');
const { getBranchFilter } = require('../utils/branchFilter');
const { isPrivilegedStaff } = require('../middleware/auth');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const gradeFromMarks = (marks, total) => {
  const pct = total > 0 ? (marks / total) * 100 : 0;
  if (pct >= 90) return 'A';
  if (pct >= 80) return 'B';
  if (pct >= 70) return 'C';
  if (pct >= 60) return 'D';
  if (pct >= 50) return 'E';
  return 'F';
};

const formatResult = (result, passingMarks) => ({
  student: result.student?._id || result.student,
  studentName: result.student?.name,
  studentCode: result.student?.studentId,
  marksObtained: result.marksObtained,
  grade: result.grade,
  remarks: result.remarks,
  enrollmentStatus: result.enrollmentStatus,
  passed: result.marksObtained >= passingMarks,
});

const format = (doc) => ({
  id: doc._id,
  examName: doc.examName,
  subject: doc.subject,
  class: doc.class,
  scheduleId: doc.scheduleId?._id || doc.scheduleId,
  subjectGroup: doc.subjectGroup?._id || doc.subjectGroup,
  groupName: doc.subjectGroup?.groupName,
  className: doc.scheduleId?.className || doc.class,
  examDate: doc.examDate,
  startTime: doc.startTime,
  duration: doc.duration,
  totalMarks: doc.totalMarks,
  passingMarks: doc.passingMarks,
  examType: doc.examType,
  teacher: doc.teacher,
  teacherName: doc.teacher?.name,
  status: doc.status,
  results: (doc.results || []).map((r) => formatResult(r.toObject?.() || r, doc.passingMarks)),
  branchId: doc.branchId,
  createdAt: doc.createdAt,
});

const toResultRows = (studentIds) =>
  (studentIds || []).map((studentId) => ({
    student: studentId,
    marksObtained: 0,
    grade: '',
    remarks: '',
    enrollmentStatus: 'enrolled',
  }));

const buildListFilter = async (req) => {
  const filter = { ...getBranchFilter(req) };

  if (req.userType === 'student') {
    filter['results.student'] = req.user._id;
    return filter;
  }

  if (req.userType === 'teacher' && req.user.role === 'teacher' && !isPrivilegedStaff(req.user)) {
    const schedules = await ClassSchedule.find({ teacher: req.user._id }).select('_id');
    const scheduleIds = schedules.map((s) => s._id);
    const branchId = filter.branchId || req.user.branchId;
    delete filter.branchId;
    filter.$or = [
      { teacher: req.user._id, ...(branchId ? { branchId } : {}) },
      { scheduleId: { $in: scheduleIds } },
    ];
  }

  if (req.query.subject) filter.subject = req.query.subject;
  if (req.query.status) filter.status = req.query.status;
  else if (!req.query.includeArchived) filter.status = { $ne: 'archived' };
  if (req.query.class) filter.class = req.query.class;
  if (req.query.startDate && req.query.endDate) {
    filter.examDate = {
      $gte: new Date(req.query.startDate),
      $lte: new Date(req.query.endDate),
    };
  }

  if (req.query.search) {
    const term = String(req.query.search).trim();
    if (term) {
      const searchClause = {
        $or: [
          { examName: { $regex: term, $options: 'i' } },
          { subject: { $regex: term, $options: 'i' } },
          { class: { $regex: term, $options: 'i' } },
        ],
      };
      if (filter.$or) {
        filter.$and = [{ $or: filter.$or }, searchClause];
        delete filter.$or;
      } else {
        Object.assign(filter, searchClause);
      }
    }
  }

  return filter;
};

const populateExam = (query) =>
  query
    .populate('teacher', 'name email')
    .populate('scheduleId', 'className startTime endTime')
    .populate('subjectGroup', 'groupName')
    .populate('results.student', 'name studentId examEligibility status');

const maybeArchive = async (exam) => {
  const allEntered = exam.results.length > 0 && exam.results.every(
    (r) => r.marksObtained !== undefined && r.marksObtained !== null && r.marksObtained >= 0
  );
  if (allEntered && exam.status !== 'archived') {
    exam.status = 'archived';
    await exam.save();
  }
};

const list = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = await buildListFilter(req);

  const [items, total] = await Promise.all([
    populateExam(Exam.find(filter).sort({ examDate: -1 }).skip(skip).limit(limit)),
    Exam.countDocuments(filter),
  ]);

  return { items: items.map(format), meta: buildPaginationMeta(page, limit, total) };
};

const getOne = async (id, filter = {}, req = null) => {
  const exam = await populateExam(Exam.findOne({ _id: id, ...filter }));
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (req?.userType === 'student') {
    const enrolled = exam.results.some((r) => String(r.student?._id || r.student) === String(req.user._id));
    if (!enrolled) {
      throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
    }
  }
  return format(exam);
};

const create = async (req, data) => {
  const payload = { ...data };
  delete payload.groupId;

  let branchId = payload.branchId || req.branchId || req.user?.branchId;
  let studentIds = [];
  const groupId = payload.subjectGroup || data.groupId;

  if (groupId) {
    const group = await ExamGroup.findById(groupId)
      .populate('subject', 'name')
      .populate('students', '_id');
    if (!group) {
      throw Object.assign(new Error('Group not found'), { statusCode: 404, code: 'NOT_FOUND' });
    }
    payload.subjectGroup = group._id;
    branchId = branchId || group.branchId;
    if (!payload.class) payload.class = group.groupName;
    if (!payload.subject) payload.subject = group.subject?.name || group.groupName;
    if (!payload.scheduleId && group.linkedScheduleId) {
      payload.scheduleId = group.linkedScheduleId;
    }
    if (!payload.teacher && group.teachers?.length) {
      payload.teacher = group.teachers[0];
    }
    studentIds = (group.students || []).map((s) => s._id || s);
  }

  if (payload.scheduleId) {
    const schedule = await ClassSchedule.findById(payload.scheduleId)
      .populate('subject', 'name')
      .populate('enrolledStudents', '_id');
    if (schedule) {
      branchId = branchId || schedule.branchId;
      if (!payload.class) payload.class = schedule.className;
      if (!payload.subject) payload.subject = schedule.subject?.name || schedule.className;
      if (!payload.teacher) payload.teacher = schedule.teacher;
      if (!payload.startTime) payload.startTime = schedule.startTime || '09:00';
      if (!payload.subjectGroup && schedule.subjectGroup) {
        payload.subjectGroup = schedule.subjectGroup;
      }
      if (!studentIds.length && schedule.enrolledStudents?.length) {
        studentIds = schedule.enrolledStudents.map((s) => s._id || s);
      }
    }
  }

  if (!payload.startTime) payload.startTime = '09:00';
  if (!payload.subject || !payload.class) {
    throw Object.assign(new Error('Subject and class are required (assign a group or schedule)'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }

  const exam = await Exam.create({
    ...payload,
    teacher: payload.teacher || req.user._id,
    branchId,
  });

  if (studentIds.length) {
    exam.results = toResultRows(studentIds);
    await exam.save();
  }

  return getOne(exam._id, {}, req);
};

const update = async (id, filter, data) => {
  const exam = await Exam.findOneAndUpdate({ _id: id, ...filter }, data, { new: true, runValidators: true });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return getOne(exam._id, {}, req);
};

const remove = async (id, filter = {}) => {
  const exam = await Exam.findOneAndDelete({ _id: id, ...filter });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(exam);
};

const enrollFromSchedule = async (id, filter = {}) => {
  const exam = await Exam.findOne({ _id: id, ...filter });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!exam.scheduleId) {
    throw Object.assign(new Error('Exam is not linked to a schedule'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const schedule = await ClassSchedule.findById(exam.scheduleId).populate('enrolledStudents', '_id');
  let added = 0;
  for (const student of schedule?.enrolledStudents || []) {
    const exists = exam.results.some((r) => String(r.student) === String(student._id));
    if (!exists) {
      exam.results.push({
        student: student._id,
        marksObtained: 0,
        grade: '',
        remarks: '',
        enrollmentStatus: 'enrolled',
      });
      added += 1;
    }
  }
  await exam.save();
  return { exam: await getOne(exam._id), added };
};

const updateResult = async (req, examId, studentId, data) => {
  const exam = await Exam.findOne({ _id: examId, ...getBranchFilter(req) });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (req.userType === 'teacher' && !isPrivilegedStaff(req.user)) {
    if (String(exam.teacher) !== String(req.user._id)) {
      const schedule = exam.scheduleId ? await ClassSchedule.findById(exam.scheduleId) : null;
      if (!schedule || String(schedule.teacher) !== String(req.user._id)) {
        throw Object.assign(new Error('You can only enter marks for your exams'), { statusCode: 403, code: 'FORBIDDEN' });
      }
    }
  }

  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (student.examEligibility === false) {
    throw Object.assign(
      new Error('Student is not eligible due to 3+ consecutive absences'),
      { statusCode: 403, code: 'EXAM_INELIGIBLE' }
    );
  }

  const index = exam.results.findIndex((r) => String(r.student) === String(studentId));
  if (index === -1) {
    throw Object.assign(new Error('Student not enrolled in this exam'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const marksObtained = data.marksObtained ?? exam.results[index].marksObtained;
  exam.results[index].marksObtained = marksObtained;
  exam.results[index].grade = data.grade || gradeFromMarks(marksObtained, exam.totalMarks);
  exam.results[index].remarks = data.remarks ?? exam.results[index].remarks;
  if (data.enrollmentStatus) exam.results[index].enrollmentStatus = data.enrollmentStatus;

  await exam.save();
  await maybeArchive(exam);
  return getOne(exam._id, {}, req);
};

const markAbsentFailed = async (id, filter = {}) => {
  const exam = await Exam.findOne({ _id: id, ...filter });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  let updated = 0;
  for (const result of exam.results) {
    if (result.marksObtained === 0 && !result.grade) {
      const student = await Student.findById(result.student);
      if (student?.examEligibility === false) continue;
      result.grade = 'F';
      result.remarks = 'Absent - Marked as Failed';
      result.enrollmentStatus = 'absent';
      updated += 1;
    }
  }
  await exam.save();
  await maybeArchive(exam);
  return { exam: await getOne(exam._id), updated };
};

const addStudent = async (id, studentId, filter = {}) => {
  const exam = await Exam.findOne({ _id: id, ...filter });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (exam.results.some((r) => String(r.student) === String(studentId))) {
    throw Object.assign(new Error('Student already enrolled'), { statusCode: 400, code: 'DUPLICATE' });
  }
  exam.results.push({
    student: studentId,
    marksObtained: 0,
    grade: '',
    remarks: '',
    enrollmentStatus: 'enrolled',
  });
  await exam.save();
  return getOne(exam._id, {}, req);
};

const removeStudent = async (id, studentId, filter = {}) => {
  const exam = await Exam.findOne({ _id: id, ...filter });
  if (!exam) {
    throw Object.assign(new Error('Exam not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  exam.results = exam.results.filter((r) => String(r.student) !== String(studentId));
  await exam.save();
  return getOne(exam._id, {}, req);
};

module.exports = {
  list,
  getOne,
  create,
  update,
  remove,
  enrollFromSchedule,
  updateResult,
  markAbsentFailed,
  addStudent,
  removeStudent,
  format,
};
