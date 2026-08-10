const ExamGroup = require('../models/ExamGroup');
const ClassSchedule = require('../models/ClassSchedule');
const { getBranchFilter } = require('../utils/branchFilter');
const { sendError } = require('../utils/apiResponse');
const { hasPermission, isPrivilegedStaff } = require('./auth');

/**
 * Create / update / unlock learning content.
 * Managers with canManageHomework, or teachers with canEditHomework.
 */
const editHomework = async (req, res, next) => {
  if (req.userType !== 'teacher') {
    return sendError(res, 403, 'FORBIDDEN', 'Staff permission required');
  }
  if (
    (await hasPermission(req, 'canManageHomework')) ||
    (await hasPermission(req, 'canEditHomework'))
  ) {
    return next();
  }
  return sendError(res, 403, 'FORBIDDEN', 'Missing permission: canEditHomework');
};

/**
 * Delete learning content — privileged homework managers only.
 */
const deleteHomework = async (req, res, next) => {
  if (req.userType !== 'teacher') {
    return sendError(res, 403, 'FORBIDDEN', 'Staff permission required');
  }
  if (await hasPermission(req, 'canManageHomework')) {
    return next();
  }
  return sendError(res, 403, 'FORBIDDEN', 'Teachers cannot delete learning content');
};

const resolveTeacherGroupIds = async (req) => {
  const teacherId = req.user._id;
  const branch = getBranchFilter(req);
  const [byTeachers, bySchedule] = await Promise.all([
    ExamGroup.find({ teachers: teacherId, ...branch }).select('_id'),
    ClassSchedule.find({
      teacher: teacherId,
      ...branch,
      subjectGroup: { $ne: null },
    }).select('subjectGroup'),
  ]);

  const ids = new Set();
  for (const group of byTeachers) ids.add(String(group._id));
  for (const schedule of bySchedule) {
    if (schedule.subjectGroup) ids.add(String(schedule.subjectGroup));
  }
  return [...ids];
};

/**
 * Teachers may only unlock groups they own. Privileged staff may unlock any group.
 * Expects `groupId` in req.body.
 */
const requireOwnedGroup = async (req, res, next) => {
  try {
    if (req.userType !== 'teacher') {
      return sendError(res, 403, 'FORBIDDEN', 'Staff permission required');
    }
    if (isPrivilegedStaff(req.user) || req.user.role === 'founder') {
      return next();
    }
    if (await hasPermission(req, 'canManageHomework')) {
      return next();
    }

    const groupId = req.body?.groupId;
    if (!groupId) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'groupId is required');
    }

    const owned = await resolveTeacherGroupIds(req);
    if (!owned.includes(String(groupId))) {
      return sendError(res, 403, 'FORBIDDEN', 'You can only unlock your own groups');
    }
    return next();
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  editHomework,
  deleteHomework,
  requireOwnedGroup,
  resolveTeacherGroupIds,
};
