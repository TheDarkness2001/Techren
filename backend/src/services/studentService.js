const Student = require('../models/Student');
const uploadService = require('./uploadService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');

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

  return {
    items: items.map((s) => s.toPublicJSON()),
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

  return student.toPublicJSON();
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

  return student.toPublicJSON();
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
  return student.toPublicJSON();
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
