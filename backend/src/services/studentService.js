const Student = require('../models/Student');
const Parent = require('../models/Parent');
const uploadService = require('./uploadService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

const normalizeUsername = (value) => String(value || '').trim().toLowerCase();

const findParentForStudent = async (studentId) =>
  Parent.findOne({ children: studentId });

const formatStudentWithParent = async (studentJson, studentId) => {
  const parent = await findParentForStudent(studentId);
  return {
    ...studentJson,
    parentAccount: parent ? parent.toStaffJSON() : null,
  };
};

/**
 * Upsert parent portal credentials linked to a student.
 * parentAccount: { name, username, password?, relation?, phone? }
 */
const upsertParentAccount = async (student, parentAccount) => {
  if (!parentAccount || typeof parentAccount !== 'object') return null;

  const username = normalizeUsername(parentAccount.username);
  const name = String(parentAccount.name || student.parentName || '').trim();
  const relation = ['mother', 'father', 'guardian'].includes(parentAccount.relation)
    ? parentAccount.relation
    : 'guardian';
  const phone = parentAccount.phone != null
    ? String(parentAccount.phone).trim()
    : (student.parentPhone || '');
  const password = parentAccount.password != null ? String(parentAccount.password) : '';

  if (!username && !name && !password) return findParentForStudent(student._id);

  if (!username) {
    throw Object.assign(new Error('Parent username is required'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }
  if (!/^[a-z0-9._-]{3,40}$/.test(username)) {
    throw Object.assign(
      new Error('Parent username must be 3–40 characters (letters, numbers, . _ -)'),
      { statusCode: 400, code: 'VALIDATION_ERROR' }
    );
  }
  if (!name) {
    throw Object.assign(new Error('Parent name is required'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  let parent = await findParentForStudent(student._id);
  if (!parent) {
    parent = await Parent.findOne({ username });
  }

  if (parent && String(parent.username || '') !== username) {
    const taken = await Parent.findOne({ username, _id: { $ne: parent._id } });
    if (taken) {
      throw Object.assign(new Error('Parent username already in use'), {
        statusCode: 409,
        code: 'DUPLICATE',
      });
    }
    parent.username = username;
  } else if (!parent) {
    const taken = await Parent.findOne({ username });
    if (taken) {
      // Reuse existing parent account and link this child.
      parent = taken;
    }
  }

  if (!parent) {
    if (!password || password.length < 4) {
      throw Object.assign(new Error('Parent password is required (min 4 characters)'), {
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      });
    }
    parent = await Parent.create({
      name,
      username,
      password,
      phone,
      relation,
      children: [student._id],
      status: 'active',
    });
    return parent;
  }

  parent.name = name;
  parent.username = username;
  parent.relation = relation;
  if (phone !== undefined) parent.phone = phone;
  if (password) {
    if (password.length < 4) {
      throw Object.assign(new Error('Parent password must be at least 4 characters'), {
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      });
    }
    parent.password = password;
  }
  const childId = String(student._id);
  const children = (parent.children || []).map((c) => String(c));
  if (!children.includes(childId)) {
    parent.children = [...(parent.children || []), student._id];
  }
  await parent.save();
  return parent;
};

const listStudents = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };

  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
      { studentId: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  if (req.query.status) filter.status = req.query.status;

  const sortBy = req.query.sortBy === 'name' ? 'name' : 'createdAt';
  const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;

  const [items, total] = await Promise.all([
    Student.find(filter).sort({ [sortBy]: sortOrder }).skip(skip).limit(limit),
    Student.countDocuments(filter),
  ]);

  const mapped = await Promise.all(
    items.map((s) => formatStudentWithParent(s.toPublicJSON(), s._id))
  );
  return {
    items: mapped,
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getStudent = async (req, id) => {
  const student = await Student.findById(id);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (req.userType === 'student' && String(student._id) !== String(req.user._id)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  if (req.userType === 'teacher' && !canAccessBranch(req, student.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  return formatStudentWithParent(student.toPublicJSON(), student._id);
};

const createStudent = async (req, data) => {
  const branchId = req.user.role === 'founder' ? data.branchId || req.body.branchId : req.user.branchId;
  if (!branchId) {
    throw Object.assign(new Error('Branch is required'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  if (data.email) {
    const existing = await Student.findOne({ email: data.email.toLowerCase(), branchId });
    if (existing) {
      throw Object.assign(new Error('Email already in use in this branch'), { statusCode: 409, code: 'DUPLICATE' });
    }
  }

  const subjectFees = Array.isArray(data.subjectFees)
    ? data.subjectFees
        .filter((f) => f && String(f.subject || '').trim())
        .map((f) => ({ subject: String(f.subject).trim(), amount: Number(f.amount) || 0 }))
    : [];
  const feesTotal = subjectFees.reduce((sum, f) => sum + f.amount, 0);
  const coursePrice =
    data.coursePrice != null && data.coursePrice !== ''
      ? Number(data.coursePrice)
      : feesTotal;

  const allowedStatus = ['active', 'inactive', 'graduated'];
  const status = allowedStatus.includes(data.status) ? data.status : 'active';

  const student = await Student.create({
    name: data.name,
    email: data.email,
    password: data.password,
    phone: data.phone || '',
    parentName: data.parentName,
    parentPhone: data.parentPhone,
    coursePrice: Number.isFinite(coursePrice) ? coursePrice : 0,
    subjectFees,
    dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
    gender: data.gender || '',
    bloodGroup: data.bloodGroup || '',
    address: data.address || '',
    medicalConditions: data.medicalConditions || '',
    branchId,
    status,
  });

  if (data.parentAccount) {
    await upsertParentAccount(student, data.parentAccount);
    if (data.parentAccount.name) student.parentName = String(data.parentAccount.name).trim();
    if (data.parentAccount.phone != null) student.parentPhone = String(data.parentAccount.phone).trim();
    await student.save();
  }

  return formatStudentWithParent(student.toPublicJSON(), student._id);
};

const updateStudent = async (req, id, data) => {
  const student = await Student.findById(id);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, student.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  if (data.email && data.email !== student.email) {
    const existing = await Student.findOne({ email: data.email.toLowerCase(), branchId: student.branchId });
    if (existing) {
      throw Object.assign(new Error('Email already in use in this branch'), { statusCode: 409, code: 'DUPLICATE' });
    }
    student.email = data.email;
  }

  if (data.name !== undefined) student.name = data.name;
  if (data.phone !== undefined) student.phone = data.phone;
  if (data.parentName !== undefined) student.parentName = data.parentName;
  if (data.parentPhone !== undefined) student.parentPhone = data.parentPhone;
  if (data.coursePrice !== undefined) student.coursePrice = Number(data.coursePrice) || 0;
  if (data.subjectFees !== undefined) {
    student.subjectFees = Array.isArray(data.subjectFees)
      ? data.subjectFees
          .filter((f) => f && String(f.subject || '').trim())
          .map((f) => ({ subject: String(f.subject).trim(), amount: Number(f.amount) || 0 }))
      : [];
  }
  if (data.dateOfBirth !== undefined) {
    student.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : null;
  }
  if (data.gender !== undefined) student.gender = data.gender || '';
  if (data.bloodGroup !== undefined) student.bloodGroup = data.bloodGroup || '';
  if (data.address !== undefined) student.address = data.address || '';
  if (data.medicalConditions !== undefined) student.medicalConditions = data.medicalConditions || '';
  if (data.status !== undefined) student.status = data.status;
  if (data.password) student.password = data.password;
  if (data.profileImage !== undefined) student.profileImage = data.profileImage;

  await student.save();

  if (data.parentAccount) {
    await upsertParentAccount(student, data.parentAccount);
    if (data.parentAccount.name) {
      student.parentName = String(data.parentAccount.name).trim();
      await student.save();
    }
    if (data.parentAccount.phone != null) {
      student.parentPhone = String(data.parentAccount.phone).trim();
      await student.save();
    }
  }

  return formatStudentWithParent(student.toPublicJSON(), student._id);
};

const setStudentStatus = async (req, id, status) => updateStudent(req, id, { status });

const updateStudentPhoto = async (req, id, file) => {
  const student = await Student.findById(id);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const isSelf = req.userType === 'student' && String(student._id) === String(req.user._id);
  if (!isSelf && !canAccessBranch(req, student.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const uploaded = uploadService.saveUploadedFile(file, 'image');
  student.profileImage = uploaded.url;
  await student.save();
  return student.toPublicJSON();
};

module.exports = {
  listStudents,
  getStudent,
  createStudent,
  updateStudent,
  setStudentStatus,
  updateStudentPhoto,
};
