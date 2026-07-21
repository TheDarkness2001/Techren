const Teacher = require('../models/Teacher');
const uploadService = require('./uploadService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

const listTeachers = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req), role: { $ne: 'founder' } };

  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
      { teacherId: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  if (req.query.status) filter.status = req.query.status;
  if (req.query.role) filter.role = req.query.role;

  const sortBy = req.query.sortBy === 'createdAt' ? 'createdAt' : 'name';
  const sortOrder = req.query.sortOrder === 'desc' ? -1 : 1;

  const [items, total] = await Promise.all([
    Teacher.find(filter).sort({ [sortBy]: sortOrder }).skip(skip).limit(limit),
    Teacher.countDocuments(filter),
  ]);

  return {
    items: items.map((t) => t.toPublicJSON()),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getTeacher = async (req, id) => {
  const teacher = await Teacher.findById(id);
  if (!teacher || teacher.role === 'founder') {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  return teacher.toPublicJSON();
};

const createTeacher = async (req, data) => {
  const branchId = req.user.role === 'founder' ? data.branchId || req.body.branchId : req.user.branchId;
  if (!branchId) {
    throw Object.assign(new Error('Branch is required'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const existing = await Teacher.findOne({ email: data.email.toLowerCase() });
  if (existing) {
    throw Object.assign(new Error('Email already in use'), { statusCode: 409, code: 'DUPLICATE' });
  }

  const teacher = await Teacher.create({
    name: data.name,
    email: data.email,
    password: data.password,
    phone: data.phone,
    role: data.role || 'teacher',
    subject: data.subject || [],
    branchId,
    status: 'active',
  });

  return teacher.toPublicJSON();
};

const updateTeacher = async (req, id, data) => {
  const teacher = await Teacher.findById(id);
  if (!teacher || teacher.role === 'founder') {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  if (data.email && data.email !== teacher.email) {
    const existing = await Teacher.findOne({ email: data.email.toLowerCase() });
    if (existing) {
      throw Object.assign(new Error('Email already in use'), { statusCode: 409, code: 'DUPLICATE' });
    }
    teacher.email = data.email;
  }

  if (data.name !== undefined) teacher.name = data.name;
  if (data.phone !== undefined) teacher.phone = data.phone;
  if (data.role !== undefined) teacher.role = data.role;
  if (data.subject !== undefined) teacher.subject = data.subject;
  if (data.status !== undefined) teacher.status = data.status;
  if (data.password) teacher.password = data.password;
  if (data.profileImage !== undefined) teacher.profileImage = data.profileImage;

  await teacher.save();
  return teacher.toPublicJSON();
};

const deactivateTeacher = async (req, id) => {
  return updateTeacher(req, id, { status: 'inactive' });
};

const updateTeacherPermissions = async (req, id, permissions) => {
  const teacher = await Teacher.findById(id);
  if (!teacher || teacher.role === 'founder') {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  teacher.permissions = permissions;
  await teacher.save();
  return teacher.toPublicJSON();
};

const updateTeacherPhoto = async (req, id, file) => {
  const teacher = await Teacher.findById(id);
  if (!teacher || teacher.role === 'founder') {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const isSelf = req.userType === 'teacher' && String(teacher._id) === String(req.user._id);
  if (!isSelf && !canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const uploaded = uploadService.saveUploadedFile(file, 'image');
  teacher.profileImage = uploaded.url;
  await teacher.save();
  return teacher.toPublicJSON();
};

module.exports = {
  listTeachers,
  getTeacher,
  createTeacher,
  updateTeacher,
  deactivateTeacher,
  updateTeacherPermissions,
  updateTeacherPhoto,
};
