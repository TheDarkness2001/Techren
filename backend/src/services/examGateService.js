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

/**
 * Groups that control unlocks for a student.
 * Prefer ExamGroup.students, and also include subjectGroup from any schedule
 * the student is enrolled in (covers out-of-sync group membership).
 */
const getStudentGroupIds = async (studentId) => {
  const [groups, schedules] = await Promise.all([
    ExamGroup.find({ students: studentId }).select('_id'),
    ClassSchedule.find({
      enrolledStudents: studentId,
      subjectGroup: { $ne: null },
    }).select('subjectGroup'),
  ]);

  const ids = new Set();
  for (const group of groups) ids.add(String(group._id));
  for (const schedule of schedules) {
    if (schedule.subjectGroup) ids.add(String(schedule.subjectGroup._id || schedule.subjectGroup));
  }
  return [...ids];
};

const isExamUnlockedForStudent = (lesson, groupIds) => {
  if (!groupIds?.length) return false;
  const unlocked = (lesson.examUnlockedFor || []).map((g) => String(g._id || g));
  return unlocked.some((g) => groupIds.includes(g));
};

const isPracticeUnlockedForStudent = (level, groupIds) => {
  if (!groupIds?.length) return false;
  const unlocked = (level.practiceUnlockedFor || []).map((g) => String(g._id || g));
  return unlocked.some((g) => groupIds.includes(g));
};

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
