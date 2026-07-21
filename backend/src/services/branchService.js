const Branch = require('../models/Branch');
const { Teacher, Student } = require('../models');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { canAccessBranch } = require('../utils/branchFilter');

const formatBranch = (branch) => ({
  id: branch._id,
  name: branch.name,
  address: branch.address,
  phone: branch.phone,
  isActive: branch.isActive,
  createdBy: branch.createdBy,
  createdAt: branch.createdAt,
  updatedAt: branch.updatedAt,
});

const listBranches = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = {};

  if (req.userType === 'teacher' && req.user.role !== 'founder') {
    filter._id = req.user.branchId;
  }

  if (req.query.search) {
    filter.name = { $regex: req.query.search, $options: 'i' };
  }

  if (req.query.isActive !== undefined) {
    filter.isActive = req.query.isActive === 'true';
  }

  const [items, total] = await Promise.all([
    Branch.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
    Branch.countDocuments(filter),
  ]);

  return {
    items: items.map(formatBranch),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getBranch = async (req, id) => {
  const branch = await Branch.findById(id);
  if (!branch) {
    throw Object.assign(new Error('Branch not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (!canAccessBranch(req, branch._id)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  return formatBranch(branch);
};

const createBranch = async (req, data) => {
  const branch = await Branch.create({
    name: data.name,
    address: data.address,
    phone: data.phone,
    createdBy: req.user._id,
  });
  return formatBranch(branch);
};

const updateBranch = async (req, id, data) => {
  const branch = await Branch.findById(id);
  if (!branch) {
    throw Object.assign(new Error('Branch not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (data.name !== undefined) branch.name = data.name;
  if (data.address !== undefined) branch.address = data.address;
  if (data.phone !== undefined) branch.phone = data.phone;
  await branch.save();
  return formatBranch(branch);
};

const setBranchStatus = async (id, isActive) => {
  const branch = await Branch.findByIdAndUpdate(id, { isActive }, { new: true });
  if (!branch) {
    throw Object.assign(new Error('Branch not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return formatBranch(branch);
};

const getBranchStats = async (branchId) => {
  const [students, teachers, activeStudents] = await Promise.all([
    Student.countDocuments({ branchId }),
    Teacher.countDocuments({ branchId, role: { $ne: 'founder' } }),
    Student.countDocuments({ branchId, status: 'active' }),
  ]);

  return {
    branchId,
    students,
    teachers,
    activeStudents,
    inactiveStudents: students - activeStudents,
  };
};

module.exports = {
  listBranches,
  getBranch,
  createBranch,
  updateBranch,
  setBranchStatus,
  getBranchStats,
  formatBranch,
};
