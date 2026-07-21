const Feedback = require('../models/Feedback');
const ClassSchedule = require('../models/ClassSchedule');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const { getBranchFilter } = require('../utils/branchFilter');
const { getTashkentParts, isWithinClassWindow, canBypassTimeWindow } = require('../utils/classWindow');
const { isPrivilegedStaff } = require('../middleware/auth');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const logger = require('../config/logger');

const format = (doc) => ({
  id: doc._id,
  student: doc.student,
  studentName: doc.student?.name,
  classSchedule: doc.classSchedule,
  className: doc.classSchedule?.className,
  teacher: doc.teacher,
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
});

const assertFeedbackWindow = (schedule, user) => {
  if (canBypassTimeWindow(user)) return;
  if (!isWithinClassWindow(schedule)) {
    throw Object.assign(
      new Error('Feedback can only be submitted during class hours (+30 min grace)'),
      { statusCode: 403, code: 'OUTSIDE_TIME_WINDOW' }
    );
  }
};

const applyFeedbackSearch = async (filter, term, options = {}) => {
  const trimmed = String(term).trim();
  if (!trimmed) return filter;

  const branchScope = options.branchId ? { branchId: options.branchId } : {};
  const [students, teachers, schedules] = await Promise.all([
    options.studentId
      ? Promise.resolve([])
      : Student.find({
          ...branchScope,
          $or: [
            { name: { $regex: trimmed, $options: 'i' } },
            { studentId: { $regex: trimmed, $options: 'i' } },
          ],
        }).select('_id'),
    Teacher.find({
      ...branchScope,
      name: { $regex: trimmed, $options: 'i' },
    }).select('_id'),
    ClassSchedule.find({
      ...branchScope,
      className: { $regex: trimmed, $options: 'i' },
    }).select('_id'),
  ]);

  const searchOr = [
    ...(students.length ? [{ student: { $in: students.map((student) => student._id) } }] : []),
    ...(teachers.length ? [{ teacher: { $in: teachers.map((teacher) => teacher._id) } }] : []),
    ...(schedules.length ? [{ classSchedule: { $in: schedules.map((schedule) => schedule._id) } }] : []),
    { date: { $regex: trimmed, $options: 'i' } },
    { notes: { $regex: trimmed, $options: 'i' } },
  ];

  return { $and: [filter, { $or: searchOr }] };
};

const list = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  let filter = { ...getBranchFilter(req) };

  if (req.userType === 'student') {
    // Never allow query overrides to read another student's feedback.
    filter.student = req.user._id;
  } else if (req.query.studentId) {
    filter.student = req.query.studentId;
  }
  if (req.userType === 'teacher' && req.user.role === 'teacher') filter.teacher = req.user._id;
  if (req.query.classScheduleId) filter.classSchedule = req.query.classScheduleId;
  if (req.query.date) filter.date = req.query.date;

  if (req.query.search) {
    const branchFilter = getBranchFilter(req);
    filter = await applyFeedbackSearch(filter, req.query.search, {
      branchId: branchFilter.branchId,
      studentId: filter.student,
    });
  }

  const [items, total] = await Promise.all([
    Feedback.find(filter)
      .populate('student', 'name studentId')
      .populate('classSchedule', 'className')
      .populate('teacher', 'name')
      .sort({ date: -1 })
      .skip(skip)
      .limit(limit),
    Feedback.countDocuments(filter),
  ]);

  return { items: items.map(format), meta: buildPaginationMeta(page, limit, total) };
};

const create = async (req, data) => {
  const schedule = await ClassSchedule.findById(data.classScheduleId);
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (req.userType === 'teacher' && !isPrivilegedStaff(req.user) && String(schedule.teacher) !== String(req.user._id)) {
    throw Object.assign(new Error('You can only submit feedback for your classes'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  assertFeedbackWindow(schedule, req.user);

  const date = data.date || getTashkentParts().dateString;
  const teacherId = req.userType === 'teacher' && isPrivilegedStaff(req.user)
    ? schedule.teacher
    : req.user._id;

  const feedback = await Feedback.findOneAndUpdate(
    {
      student: data.studentId,
      classSchedule: data.classScheduleId,
      date,
    },
    {
      $set: {
        teacher: teacherId,
        branchId: schedule.branchId,
        homework: data.homework ?? 0,
        behavior: data.behavior ?? 0,
        participation: data.participation ?? 0,
        isExamDay: data.isExamDay ?? false,
        examPercentage: data.isExamDay ? data.examPercentage : undefined,
        notes: data.notes,
      },
    },
    { upsert: true, new: true }
  )
    .populate('student', 'name studentId')
    .populate('classSchedule', 'className')
    .populate('teacher', 'name');

  logger.info(`TEACHER_FEEDBACK: student=${data.studentId} class=${data.classScheduleId} date=${date}`);
  const formatted = format(feedback);
  const { emit } = require('../utils/notificationWorker');
  emit('feedback:created', formatted);
  return formatted;
};

const update = async (req, id, data) => {
  const feedback = await Feedback.findById(id);
  if (!feedback) {
    throw Object.assign(new Error('Feedback not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const schedule = await ClassSchedule.findById(feedback.classSchedule);
  assertFeedbackWindow(schedule, req.user);

  Object.assign(feedback, {
    homework: data.homework ?? feedback.homework,
    behavior: data.behavior ?? feedback.behavior,
    participation: data.participation ?? feedback.participation,
    isExamDay: data.isExamDay ?? feedback.isExamDay,
    examPercentage: data.examPercentage ?? feedback.examPercentage,
    notes: data.notes ?? feedback.notes,
  });
  await feedback.save();
  return format(await feedback.populate(['student', 'classSchedule', 'teacher']));
};

const addParentComment = async (req, id, comment) => {
  const feedback = await Feedback.findById(id);
  if (!feedback) {
    throw Object.assign(new Error('Feedback not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (req?.userType === 'parent') {
    const parentService = require('./parentService');
    await parentService.assertChildAccess(req.user, feedback.student);
  }

  const updated = await Feedback.findByIdAndUpdate(
    id,
    { parentComments: comment },
    { new: true }
  )
    .populate('student', 'name')
    .populate('classSchedule', 'className');
  return format(updated);
};

const getOne = async (id, filter = {}) => {
  const feedback = await Feedback.findOne({ _id: id, ...filter })
    .populate('student', 'name studentId')
    .populate('classSchedule', 'className')
    .populate('teacher', 'name');
  if (!feedback) {
    throw Object.assign(new Error('Feedback not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(feedback);
};

const remove = async (id, filter = {}) => {
  const feedback = await Feedback.findOneAndDelete({ _id: id, ...filter });
  if (!feedback) {
    throw Object.assign(new Error('Feedback not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return format(feedback);
};

module.exports = { list, create, update, addParentComment, getOne, remove, format, applyFeedbackSearch };
