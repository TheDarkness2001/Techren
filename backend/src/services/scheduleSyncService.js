const ExamGroup = require('../models/ExamGroup');
const ClassSchedule = require('../models/ClassSchedule');

const syncGroupToSchedules = async (groupId, studentIds) => {
  await ClassSchedule.updateMany(
    { subjectGroup: groupId },
    { $set: { enrolledStudents: studentIds } }
  );
};

const syncScheduleToGroup = async (schedule) => {
  if (!schedule.subjectGroup) return;
  const group = await ExamGroup.findById(schedule.subjectGroup);
  if (!group) return;

  group.students = schedule.enrolledStudents;
  if (!group.linkedScheduleId) {
    group.linkedScheduleId = schedule._id;
  }
  await group.save();
};

const addStudentsToGroup = async (groupId, studentIds) => {
  const group = await ExamGroup.findById(groupId);
  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const merged = [...new Set([...group.students.map(String), ...studentIds.map(String)])];
  group.students = merged;
  await group.save();
  await syncGroupToSchedules(groupId, group.students);
  return group;
};

const removeStudentFromGroup = async (groupId, studentId) => {
  const group = await ExamGroup.findById(groupId);
  if (!group) {
    throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  group.students = group.students.filter((id) => String(id) !== String(studentId));
  await group.save();
  await syncGroupToSchedules(groupId, group.students);
  return group;
};

const linkScheduleAndGroup = async (groupId, scheduleId) => {
  await ExamGroup.findByIdAndUpdate(groupId, { linkedScheduleId: scheduleId });
  const group = await ExamGroup.findById(groupId);
  if (group) {
    await ClassSchedule.findByIdAndUpdate(scheduleId, {
      subjectGroup: groupId,
      enrolledStudents: group.students,
    });
  }
};

module.exports = {
  syncGroupToSchedules,
  syncScheduleToGroup,
  addStudentsToGroup,
  removeStudentFromGroup,
  linkScheduleAndGroup,
};
