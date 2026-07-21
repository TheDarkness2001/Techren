const Subject = require('../models/Subject');
const ExamGroup = require('../models/ExamGroup');
const ClassSchedule = require('../models/ClassSchedule');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter } = require('../utils/branchFilter');
const { isPrivilegedStaff } = require('../middleware/auth');
const {
  defaultModulesForSubject,
  defaultColorForSubject,
  defaultIconForSubject,
  ensureSubjectLearningFields,
} = require('../utils/learningModules');

const formatSubject = (doc) => {
  const learning = ensureSubjectLearningFields(doc);
  return {
    id: doc._id,
    name: doc.name,
    code: doc.code,
    pricePerClass: doc.pricePerClass,
    branchId: doc.branchId,
    icon: learning.icon,
    color: learning.color,
    description: learning.description,
    modules: learning.modules,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

const withLearningDefaults = (data = {}) => {
  const name = data.name || 'Subject';
  return {
    ...data,
    icon: data.icon || defaultIconForSubject(name),
    color: data.color || defaultColorForSubject(name),
    description: data.description || '',
    modules: Array.isArray(data.modules) && data.modules.length
      ? data.modules
      : defaultModulesForSubject(name),
  };
};

const listSubjects = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };

  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { code: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  const [items, total] = await Promise.all([
    Subject.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
    Subject.countDocuments(filter),
  ]);

  return { items: items.map(formatSubject), meta: buildPaginationMeta(page, limit, total) };
};

const getSubject = async (id, filter) => {
  const subject = await Subject.findOne({ _id: id, ...filter });
  if (!subject) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatSubject(subject);
};

const createSubject = async (data) => {
  if (!data.branchId) {
    throw Object.assign(new Error('Branch is required to create a subject'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }
  const subject = await Subject.create(withLearningDefaults(data));
  return formatSubject(subject);
};

const updateSubject = async (id, filter, data) => {
  const payload = { ...data };
  if (payload.name && (!payload.modules || !payload.modules.length)) {
    // keep existing modules on rename unless explicitly replaced
    delete payload.modules;
  }
  const subject = await Subject.findOneAndUpdate(
    { _id: id, ...filter },
    { $set: payload },
    { new: true, runValidators: true }
  );
  if (!subject) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatSubject(subject);
};

const deleteSubject = async (id, filter) => {
  const groupCount = await ExamGroup.countDocuments({ subject: id });
  if (groupCount > 0) {
    throw Object.assign(
      new Error(`Cannot delete: ${groupCount} group(s) still use this subject. Remove or reassign groups first.`),
      { statusCode: 400, code: 'IN_USE' }
    );
  }
  const subject = await Subject.findOneAndDelete({ _id: id, ...filter });
  if (!subject) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatSubject(subject);
};

const resolveVisibleSubjectIds = async (req) => {
  if (req.userType === 'student') {
    const groups = await ExamGroup.find({ students: req.user._id }).select('subject');
    return [...new Set(groups.map((g) => String(g.subject)))];
  }

  if (req.userType === 'teacher' && isPrivilegedStaff(req.user)) {
    return null; // all in branch
  }

  if (req.userType === 'teacher') {
    const [groups, schedules] = await Promise.all([
      ExamGroup.find({ teachers: req.user._id }).select('subject'),
      ClassSchedule.find({ teacher: req.user._id }).select('subject'),
    ]);
    const ids = [
      ...groups.map((g) => String(g.subject)),
      ...schedules
        .map((s) => {
          const sub = s.subject;
          if (!sub) return null;
          if (typeof sub === 'object' && sub._id) return String(sub._id);
          // Skip free-text subject names that are not ObjectIds
          const value = String(sub);
          return /^[a-f\d]{24}$/i.test(value) ? value : null;
        })
        .filter(Boolean),
    ];
    return [...new Set(ids)];
  }

  return null;
};

const listLearningSubjects = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const visibleIds = await resolveVisibleSubjectIds(req);

  // Students: subject access is membership-based (ExamGroup.students). Do not also
  // require Subject.branchId — legacy subjects may lack branchId and would vanish.
  const filter =
    req.userType === 'student' && Array.isArray(visibleIds)
      ? {}
      : { ...getBranchFilter(req) };

  if (Array.isArray(visibleIds)) {
    if (!visibleIds.length) {
      return { items: [], meta: buildPaginationMeta(page, limit, 0) };
    }
    filter._id = { $in: visibleIds };
  }

  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { code: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  const [items, total] = await Promise.all([
    Subject.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
    Subject.countDocuments(filter),
  ]);

  const audience = req.userType === 'student' ? 'student' : 'staff';
  const enriched = await Promise.all(
    items.map(async (doc) => {
      const base = formatSubject(doc);
      const groups = await ExamGroup.find({ subject: doc._id }).select('groupName students');
      const groupCount = groups.length;
      const studentCount = new Set(groups.flatMap((g) => (g.students || []).map(String))).size;
      const levelLabel = groups[0]?.groupName || base.code || 'Active';
      const modules = (base.modules || []).filter((m) => {
        if (m.enabled === false) return false;
        if (m.audience === 'all') return true;
        return m.audience === audience;
      });

      return {
        ...base,
        modules,
        levelLabel,
        groupCount,
        studentCount,
        progressPercent: 0,
        lastActivity: doc.updatedAt,
      };
    })
  );

  return { items: enriched, meta: buildPaginationMeta(page, limit, total) };
};

const getLearningSubject = async (req, id) => {
  const visibleIds = await resolveVisibleSubjectIds(req);
  if (Array.isArray(visibleIds) && !visibleIds.includes(String(id))) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  // Students: membership already checked via visibleIds; skip branch filter for legacy docs.
  const filter =
    req.userType === 'student' && Array.isArray(visibleIds)
      ? { _id: id }
      : { _id: id, ...getBranchFilter(req) };

  const subject = await Subject.findOne(filter);
  if (!subject) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const base = formatSubject(subject);
  const audience = req.userType === 'student' ? 'student' : 'staff';
  const modules = (base.modules || []).filter((m) => {
    if (m.enabled === false) return false;
    if (m.audience === 'all') return true;
    return m.audience === audience;
  });

  const groups = await ExamGroup.find({ subject: subject._id })
    .populate('students', 'name')
    .select('groupName students');

  const byCategory = {
    learning: modules.filter((m) => m.category === 'learning'),
    assessment: modules.filter((m) => m.category === 'assessment'),
    management: modules.filter((m) => m.category === 'management'),
    statistics: modules.filter((m) => m.category === 'statistics'),
  };

  return {
    ...base,
    modules,
    allModules: base.modules || [],
    modulesByCategory: byCategory,
    levelLabel: groups[0]?.groupName || base.code || 'Active',
    groupCount: groups.length,
    studentCount: new Set(groups.flatMap((g) => (g.students || []).map((s) => String(s._id || s)))).size,
    progressPercent: 0,
    lastActivity: subject.updatedAt,
    groups: groups.map((g) => ({
      id: g._id,
      groupName: g.groupName,
      studentCount: g.students?.length ?? 0,
    })),
  };
};

module.exports = {
  listSubjects,
  getSubject,
  createSubject,
  updateSubject,
  deleteSubject,
  formatSubject,
  withLearningDefaults,
  listLearningSubjects,
  getLearningSubject,
};
