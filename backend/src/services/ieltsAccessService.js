const Student = require('../models/Student');
const ExamGroup = require('../models/ExamGroup');
const ClassSchedule = require('../models/ClassSchedule');
const Subject = require('../models/Subject');

const setStudentAccess = async (studentId, enabled) => {
  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  student.ieltsAccess = enabled === true;
  await student.save();
  return student.toPublicJSON();
};

const resolveStudentIds = async ({ studentIds, examGroupId, classScheduleId, allEnglish }) => {
  if (Array.isArray(studentIds) && studentIds.length) {
    return [...new Set(studentIds.map(String))];
  }

  if (examGroupId) {
    const group = await ExamGroup.findById(examGroupId).select('students');
    if (!group) {
      throw Object.assign(new Error('Exam group not found'), { statusCode: 404, code: 'NOT_FOUND' });
    }
    return (group.students || []).map((id) => String(id));
  }

  if (classScheduleId) {
    const schedule = await ClassSchedule.findById(classScheduleId).select('enrolledStudents');
    if (!schedule) {
      throw Object.assign(new Error('Class schedule not found'), { statusCode: 404, code: 'NOT_FOUND' });
    }
    return (schedule.enrolledStudents || []).map((id) => String(id));
  }

  if (allEnglish) {
    const englishSubjects = await Subject.find({
      name: { $regex: /english/i },
      isDeleted: { $ne: true },
    }).select('_id');
    const subjectIds = englishSubjects.map((s) => s._id);
    if (!subjectIds.length) return [];
    const groups = await ExamGroup.find({ subject: { $in: subjectIds } }).select('students');
    const ids = new Set();
    for (const g of groups) {
      for (const sid of g.students || []) ids.add(String(sid));
    }
    return [...ids];
  }

  throw Object.assign(new Error('Provide studentIds, examGroupId, classScheduleId, or allEnglish'), {
    statusCode: 400,
    code: 'VALIDATION_ERROR',
  });
};

const bulkSetAccess = async (payload) => {
  const enabled = payload.enabled === true;
  const ids = await resolveStudentIds(payload);
  if (!ids.length) {
    return { matched: 0, modified: 0, enabled, studentIds: [] };
  }
  const result = await Student.updateMany({ _id: { $in: ids } }, { $set: { ieltsAccess: enabled } });
  return {
    matched: result.matchedCount ?? result.n ?? 0,
    modified: result.modifiedCount ?? result.nModified ?? 0,
    enabled,
    studentIds: ids,
  };
};

const listWithAccess = async ({ page = 1, limit = 50, search = '' } = {}) => {
  const filter = { ieltsAccess: true };
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } },
      { studentId: { $regex: search, $options: 'i' } },
    ];
  }
  const skip = (Math.max(1, page) - 1) * limit;
  const [items, total] = await Promise.all([
    Student.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
    Student.countDocuments(filter),
  ]);
  return {
    items: items.map((s) => s.toPublicJSON()),
    meta: { page: Number(page), limit: Number(limit), total, totalPages: Math.ceil(total / limit) || 1 },
  };
};

module.exports = { setStudentAccess, bulkSetAccess, listWithAccess };
