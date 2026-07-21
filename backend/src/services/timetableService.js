const ClassSchedule = require('../models/ClassSchedule');
const { DAYS } = require('../models/ClassSchedule');
const { getBranchFilter } = require('../utils/branchFilter');
const { normalizeDay } = require('../utils/dayNames');

const resolveTeacherId = (teacher) => {
  if (!teacher) return undefined;
  if (typeof teacher === 'string') return teacher;
  if (teacher._id) return String(teacher._id);
  if (teacher.id) return String(teacher.id);
  return undefined;
};

const resolveSubjectName = (schedule) => {
  const sub = schedule.subject;
  if (sub && typeof sub === 'object' && sub.name) return sub.name;
  // Legacy free-text subject labels (not ObjectIds)
  if (typeof sub === 'string' && sub.trim() && !/^[a-f\d]{24}$/i.test(sub)) {
    return sub.trim();
  }
  const groupSub = schedule.subjectGroup?.subject;
  if (groupSub && typeof groupSub === 'object' && groupSub.name) return groupSub.name;
  return undefined;
};

const formatEntry = (schedule, day) => ({
  id: schedule._id,
  className: schedule.className,
  subject: resolveSubjectName(schedule),
  day,
  startTime: schedule.startTime,
  endTime: schedule.endTime,
  teacher: schedule.teacher,
  teacherId: resolveTeacherId(schedule.teacher),
  teacherName: schedule.teacher?.name,
  groupName: schedule.subjectGroup?.groupName,
  studentCount: schedule.enrolledStudents?.length ?? 0,
});

const buildGrid = (schedules) => {
  const grid = {};
  for (const day of DAYS) {
    grid[day] = [];
  }

  for (const schedule of schedules) {
    for (const rawDay of schedule.scheduledDays || []) {
      const day = normalizeDay(rawDay);
      if (day && grid[day]) {
        grid[day].push(formatEntry(schedule, day));
      }
    }
  }

  for (const day of DAYS) {
    grid[day].sort((a, b) => a.startTime.localeCompare(b.startTime));
  }

  return grid;
};

const schedulePopulate = [
  { path: 'teacher', select: 'name email' },
  { path: 'subject', select: 'name' },
  {
    path: 'subjectGroup',
    select: 'groupName subject',
    populate: { path: 'subject', select: 'name' },
  },
];

const getAdminTimetable = async (req) => {
  const filter = { ...getBranchFilter(req) };
  const schedules = await ClassSchedule.find(filter)
    .populate(schedulePopulate)
    .sort({ startTime: 1 });

  return { role: 'admin', weekStart: req.query.weekStart || null, grid: buildGrid(schedules), total: schedules.length };
};

const getTeacherTimetable = async (req) => {
  const schedules = await ClassSchedule.find({ teacher: req.user._id })
    .populate(schedulePopulate)
    .sort({ startTime: 1 });

  return { role: 'teacher', weekStart: req.query.weekStart || null, grid: buildGrid(schedules), total: schedules.length };
};

const getStudentTimetable = async (req) => {
  const schedules = await ClassSchedule.find({ enrolledStudents: req.user._id })
    .populate(schedulePopulate)
    .sort({ startTime: 1 });

  return { role: 'student', weekStart: req.query.weekStart || null, grid: buildGrid(schedules), total: schedules.length };
};

const getTimetable = async (req, type) => {
  if (type === 'admin') return getAdminTimetable(req);
  if (type === 'teacher') return getTeacherTimetable(req);
  if (type === 'student') return getStudentTimetable(req);
  throw Object.assign(new Error('Invalid timetable type'), { statusCode: 400, code: 'VALIDATION_ERROR' });
};

module.exports = { getTimetable, buildGrid, DAYS };
