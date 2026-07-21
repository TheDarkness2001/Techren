const ClassSchedule = require('../models/ClassSchedule');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter } = require('../utils/branchFilter');
const { daysOverlap, timesOverlap } = require('../utils/timeUtils');
const { normalizeScheduledDays } = require('../utils/dayNames');
const { syncScheduleToGroup } = require('./scheduleSyncService');

const formatSchedule = (doc) => {
  const subjectDoc = doc.subject && typeof doc.subject === 'object' && doc.subject._id
    ? doc.subject
    : null;
  return {
    id: doc._id,
    subject: subjectDoc ? subjectDoc._id : doc.subject,
    subjectName: subjectDoc?.name || null,
    subjectGroup: doc.subjectGroup,
    groupName: doc.subjectGroup?.groupName,
    className: doc.className,
    enrolledStudents: doc.enrolledStudents,
    studentCount: doc.enrolledStudents?.length ?? 0,
    teacher: doc.teacher,
    teacherName: doc.teacher?.name,
    scheduledDays: normalizeScheduledDays(doc.scheduledDays),
    startTime: doc.startTime,
    endTime: doc.endTime,
    branchId: doc.branchId,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

const listSchedules = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };

  if (req.query.teacherId) filter.teacher = req.query.teacherId;
  if (req.query.search) {
    filter.className = { $regex: req.query.search, $options: 'i' };
  }

  const [items, total] = await Promise.all([
    ClassSchedule.find(filter)
      .populate('teacher', 'name email role')
      .populate('subject', 'name')
      .populate('subjectGroup', 'groupName')
      .sort({ className: 1 })
      .skip(skip)
      .limit(limit),
    ClassSchedule.countDocuments(filter),
  ]);

  return { items: items.map(formatSchedule), meta: buildPaginationMeta(page, limit, total) };
};

const getSchedule = async (id, filter) => {
  const schedule = await ClassSchedule.findOne({ _id: id, ...filter })
    .populate('teacher', 'name email role')
    .populate('subject', 'name')
    .populate('subjectGroup', 'groupName')
    .populate('enrolledStudents', 'name email studentId status');
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatSchedule(schedule);
};

const createSchedule = async (data) => {
  const payload = {
    ...data,
    scheduledDays: normalizeScheduledDays(data.scheduledDays),
  };
  const schedule = await ClassSchedule.create(payload);
  await syncScheduleToGroup(schedule);
  return getSchedule(schedule._id, {});
};

const updateSchedule = async (id, filter, data) => {
  const schedule = await ClassSchedule.findOne({ _id: id, ...filter });
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const payload = { ...data };
  if (payload.scheduledDays) {
    payload.scheduledDays = normalizeScheduledDays(payload.scheduledDays);
  }
  Object.assign(schedule, payload);
  await schedule.save();
  await syncScheduleToGroup(schedule);
  return getSchedule(schedule._id, filter);
};

const deleteSchedule = async (id, filter) => {
  const schedule = await ClassSchedule.findOneAndDelete({ _id: id, ...filter });
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatSchedule(schedule);
};

const syncStudentsFromGroup = async (id, filter) => {
  const schedule = await ClassSchedule.findOne({ _id: id, ...filter });
  if (!schedule) {
    throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!schedule.subjectGroup) {
    throw Object.assign(new Error('Schedule has no linked exam group'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const ExamGroup = require('../models/ExamGroup');
  const group = await ExamGroup.findById(schedule.subjectGroup);
  schedule.enrolledStudents = group?.students || [];
  await schedule.save();
  return getSchedule(schedule._id, filter);
};

const detectConflicts = async (req) => {
  const filter = { ...getBranchFilter(req) };
  const { teacherId, scheduledDays, startTime, endTime, excludeId } = req.query;

  if (!teacherId || !scheduledDays || !startTime || !endTime) {
    throw Object.assign(new Error('teacherId, scheduledDays, startTime, endTime required'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const days = Array.isArray(scheduledDays) ? scheduledDays : String(scheduledDays).split(',');
  const query = { ...filter, teacher: teacherId };
  if (excludeId) query._id = { $ne: excludeId };

  const existing = await ClassSchedule.find(query);
  const conflicts = existing.filter(
    (s) => daysOverlap(s.scheduledDays, days) && timesOverlap(s.startTime, s.endTime, startTime, endTime)
  );

  return conflicts.map(formatSchedule);
};

const createFromGroup = async (groupId, scheduleData, branchId) => {
  const ExamGroup = require('../models/ExamGroup');
  const group = await ExamGroup.findById(groupId).populate('subject');
  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const schedule = await ClassSchedule.create({
    className: scheduleData.className || group.groupName,
    subject: group.subject._id || group.subject,
    subjectGroup: group._id,
    enrolledStudents: group.students,
    teacher: scheduleData.teacherId,
    scheduledDays: scheduleData.scheduledDays || [],
    startTime: scheduleData.startTime,
    endTime: scheduleData.endTime,
    branchId,
  });

  group.linkedScheduleId = schedule._id;
  await group.save();

  return getSchedule(schedule._id, {});
};

module.exports = {
  listSchedules,
  getSchedule,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  syncStudentsFromGroup,
  detectConflicts,
  createFromGroup,
  formatSchedule,
};
