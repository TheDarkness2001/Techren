const ClassSchedule = require('../models/ClassSchedule');
const ExamGroup = require('../models/ExamGroup');
const { getTashkentParts, isWithinClassWindow, isScheduleToday } = require('../utils/classWindow');

const isStudentInClassWindow = async (studentId) => {
  const schedules = await ClassSchedule.find({ enrolledStudents: studentId });
  const parts = getTashkentParts();
  const active = schedules.find((schedule) => isScheduleToday(schedule, parts) && isWithinClassWindow(schedule, 0, parts));
  if (active) return { allowed: true, schedule: active };
  return { allowed: false, reason: 'Exam is only available during your class hours.' };
};

const getStudentGroupIds = async (studentId) => {
  const groups = await ExamGroup.find({ students: studentId }).select('_id');
  return groups.map((g) => String(g._id));
};

const isExamUnlockedForStudent = (lesson, groupIds) =>
  (lesson.examUnlockedFor || []).some((g) => groupIds.includes(String(g)));

const isPracticeUnlockedForStudent = (level, groupIds) =>
  (level.practiceUnlockedFor || []).some((g) => groupIds.includes(String(g)));

const hasTakenExamToday = (progress) => {
  if (!progress?.lastExamDate) return false;
  const parts = getTashkentParts();
  const last = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Tashkent' }).format(new Date(progress.lastExamDate));
  return last === parts.dateString;
};

module.exports = {
  isStudentInClassWindow,
  getStudentGroupIds,
  isExamUnlockedForStudent,
  isPracticeUnlockedForStudent,
  hasTakenExamToday,
};
