const ExamGroup = require('../models/ExamGroup');
const Subject = require('../models/Subject');
const ClassSchedule = require('../models/ClassSchedule');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter } = require('../utils/branchFilter');
const { normalizeScheduledDays } = require('../utils/dayNames');
const {
  addStudentsToGroup,
  removeStudentFromGroup,
  linkScheduleAndGroup,
} = require('./scheduleSyncService');

const formatStudentPreview = (student) => {
  if (!student) return null;
  if (typeof student === 'object' && student._id) {
    return {
      id: student._id,
      name: student.name || '',
      studentCode: student.studentId || '',
      profileImage: student.profileImage || null,
    };
  }
  return { id: student, name: '', studentCode: '', profileImage: null };
};

const formatGroup = (doc) => {
  const students = (doc.students || []).map(formatStudentPreview).filter(Boolean);
  return {
    id: doc._id,
    groupName: doc.groupName,
    subject: doc.subject,
    subjectName: doc.subject?.name,
    students,
    studentCount: students.length || doc.students?.length || 0,
    teachers: doc.teachers,
    branchId: doc.branchId,
    linkedScheduleId: doc.linkedScheduleId,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

const listExamGroups = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };

  if (req.query.search) {
    filter.groupName = { $regex: req.query.search, $options: 'i' };
  }
  if (req.query.subjectId) filter.subject = req.query.subjectId;

  const [items, total] = await Promise.all([
    ExamGroup.find(filter)
      .populate('subject', 'name code')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    ExamGroup.countDocuments(filter),
  ]);

  return { items: items.map(formatGroup), meta: buildPaginationMeta(page, limit, total) };
};

const getExamGroup = async (id, filter) => {
  const group = await ExamGroup.findOne({ _id: id, ...filter })
    .populate('subject', 'name code pricePerClass')
    .populate('students', 'name email studentId status profileImage')
    .populate('teachers', 'name email role');
  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatGroup(group);
};

const createExamGroup = async (data) => {
  const group = await ExamGroup.create(data);
  await group.populate('subject', 'name code');
  return formatGroup(group);
};

const updateExamGroup = async (id, filter, data) => {
  const allowed = {};
  if (data.groupName !== undefined) allowed.groupName = data.groupName;
  if (data.subject !== undefined) allowed.subject = data.subject;
  if (data.teachers !== undefined) allowed.teachers = data.teachers;
  if (data.students !== undefined) allowed.students = data.students;
  if (data.teacherIds !== undefined) allowed.teachers = data.teacherIds;
  if (data.studentIds !== undefined) allowed.students = data.studentIds;

  const group = await ExamGroup.findOneAndUpdate(
    { _id: id, ...filter },
    { $set: allowed },
    { new: true, runValidators: true }
  )
    .populate('subject', 'name code')
    .populate('students', 'name email studentId status profileImage');

  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const scheduleUpdates = {};
  if (allowed.groupName) scheduleUpdates.className = allowed.groupName;
  if (allowed.students) scheduleUpdates.enrolledStudents = allowed.students;
  if (Object.keys(scheduleUpdates).length) {
    await ClassSchedule.updateMany({ subjectGroup: id }, { $set: scheduleUpdates });
  }

  return formatGroup(group);
};

const deleteExamGroup = async (id, filter) => {
  const group = await ExamGroup.findOneAndDelete({ _id: id, ...filter });
  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  await ClassSchedule.updateMany({ subjectGroup: id }, { $unset: { subjectGroup: '' } });
  return formatGroup(group);
};

const createUnified = async (data) => {
  const { subject: subjectData, group: groupData, schedule: scheduleData, branchId } = data;

  let subject = subjectData.id
    ? await Subject.findById(subjectData.id)
    : null;

  if (!subject) {
    const { withLearningDefaults } = require('./subjectService');
    subject = await Subject.create(
      withLearningDefaults({
        name: subjectData.name,
        code: subjectData.code,
        pricePerClass: subjectData.pricePerClass || 0,
        branchId,
      })
    );
  }

  const group = await ExamGroup.create({
    groupName: groupData.groupName || `${subject.name} Group`,
    subject: subject._id,
    students: groupData.studentIds || [],
    teachers: groupData.teacherIds || [scheduleData.teacherId],
    branchId,
  });

  const schedule = await ClassSchedule.create({
    className: scheduleData.className || group.groupName,
    subject: subject._id,
    subjectGroup: group._id,
    enrolledStudents: group.students,
    teacher: scheduleData.teacherId,
    scheduledDays: normalizeScheduledDays(scheduleData.scheduledDays || []),
    startTime: scheduleData.startTime,
    endTime: scheduleData.endTime,
    branchId,
  });

  await linkScheduleAndGroup(group._id, schedule._id);

  const classScheduleService = require('./classScheduleService');
  const formattedSchedule = await classScheduleService.getSchedule(schedule._id, {});

  return {
    subject: { id: subject._id, name: subject.name, code: subject.code, pricePerClass: subject.pricePerClass },
    group: formatGroup(await group.populate('subject', 'name code')),
    schedule: formattedSchedule,
  };
};

const getUnifiedView = async (req, query = {}) => {
  const filter = { ...getBranchFilter(req) };
  const { page, limit, skip } = parsePagination(query);

  if (query.search) {
    const term = String(query.search).trim();
    if (term) {
      const branchScope = getBranchFilter(req);
      const subjects = await Subject.find({
        ...(branchScope.branchId ? { branchId: branchScope.branchId } : {}),
        name: { $regex: term, $options: 'i' },
      }).select('_id');
      const subjectIds = subjects.map((subject) => subject._id);
      const searchClause = {
        $or: [
          { groupName: { $regex: term, $options: 'i' } },
          ...(subjectIds.length ? [{ subject: { $in: subjectIds } }] : []),
        ],
      };
      Object.assign(filter, searchClause);
    }
  }

  const [groups, total] = await Promise.all([
    ExamGroup.find(filter)
      .populate('subject', 'name code')
      .populate('students', 'name studentId profileImage status')
      .sort({ groupName: 1 })
      .skip(skip)
      .limit(limit),
    ExamGroup.countDocuments(filter),
  ]);

  const groupIds = groups.map((group) => group._id);
  const schedules = groupIds.length
    ? await ClassSchedule.find({ ...filter, subjectGroup: { $in: groupIds } })
        .populate('teacher', 'name email')
        .populate('subjectGroup', 'groupName')
    : [];

  const items = groups.map((group) => {
    const schedule = schedules.find((s) => String(s.subjectGroup?._id || s.subjectGroup) === String(group._id));
    return {
      group: formatGroup(group),
      schedule: schedule
        ? {
            id: schedule._id,
            className: schedule.className,
            teacher: schedule.teacher,
            teacherName: schedule.teacher?.name,
            scheduledDays: schedule.scheduledDays,
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            studentCount: schedule.enrolledStudents?.length ?? group.students?.length ?? 0,
          }
        : null,
    };
  });

  return { items, meta: buildPaginationMeta(page, limit, total) };
};

module.exports = {
  listExamGroups,
  getExamGroup,
  createExamGroup,
  updateExamGroup,
  deleteExamGroup,
  addStudentsToGroup,
  removeStudentFromGroup,
  createUnified,
  getUnifiedView,
  formatGroup,
};
