const Teacher = require('../models/Teacher');
const ExamGroup = require('../models/ExamGroup');
const DeviceToken = require('../models/DeviceToken');
const RefreshToken = require('../models/RefreshToken');
const uploadService = require('./uploadService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

const listTeachers = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  // Include founder + all staff roles so People → Staff shows everyone.
  const filter = { ...getBranchFilter(req) };

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
  if (!teacher) {
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
    subject: Array.isArray(data.subject) ? data.subject : data.subject ? [data.subject] : [],
    department: data.department || '',
    branchId,
    status: data.status || 'active',
  });

  return teacher.toPublicJSON();
};

const updateTeacher = async (req, id, data) => {
  const teacher = await Teacher.findById(id);
  if (!teacher) {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  // Founder account is visible in Staff, but cannot be demoted or deactivated here.
  if (teacher.role === 'founder') {
    if (req.user.role !== 'founder') {
      throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
    }
    if (data.role !== undefined && data.role !== 'founder') {
      throw Object.assign(new Error('Founder role cannot be changed'), { statusCode: 400, code: 'VALIDATION_ERROR' });
    }
    if (data.status === 'inactive') {
      throw Object.assign(new Error('Founder cannot be deactivated'), { statusCode: 400, code: 'VALIDATION_ERROR' });
    }
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
  if (data.role !== undefined && teacher.role !== 'founder') teacher.role = data.role;
  if (data.subject !== undefined) {
    teacher.subject = Array.isArray(data.subject) ? data.subject : data.subject ? [data.subject] : [];
  }
  if (data.department !== undefined) teacher.department = data.department || '';
  if (data.status !== undefined) teacher.status = data.status;
  if (data.password) teacher.password = data.password;
  if (data.profileImage !== undefined) teacher.profileImage = data.profileImage;

  await teacher.save();
  return teacher.toPublicJSON();
};

const deactivateTeacher = async (req, id) => {
  return updateTeacher(req, id, { status: 'inactive' });
};

const deleteTeacher = async (req, id) => {
  if (req.user?.role !== 'founder') {
    throw Object.assign(new Error('Founder only'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  const teacher = await Teacher.findById(id);
  if (!teacher) {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (teacher.role === 'founder') {
    throw Object.assign(new Error('Founder cannot be deleted'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }
  if (String(teacher._id) === String(req.user._id)) {
    throw Object.assign(new Error('You cannot delete your own account'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }
  if (!canAccessBranch(req, teacher.branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  await Promise.all([
    ExamGroup.updateMany({ teachers: teacher._id }, { $pull: { teachers: teacher._id } }),
    DeviceToken.deleteMany({ userId: teacher._id, userType: 'teacher' }),
    RefreshToken.deleteMany({ userId: teacher._id, userType: 'teacher' }),
  ]);
  await teacher.deleteOne();
  return { deleted: true, id: String(teacher._id) };
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
  if (!teacher) {
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
  deleteTeacher,
  updateTeacherPermissions,
  updateTeacherPhoto,
};
