const Branch = require('../models/Branch');
const { Teacher, Student } = require('../models');
const { getBranchStats } = require('./branchService');
const { buildDuesByStudent } = require('./paymentService');

const currentMonthYear = () => {
  const now = new Date();
  return { month: now.getMonth() + 1, year: now.getFullYear() };
};

/** Active students with at least one course still due this month. */
const countUnpaidStudents = async (studentFilter = {}) => {
  const students = await Student.find({ status: 'active', ...studentFilter }).select('_id');
  if (!students.length) return 0;

  const { month, year } = currentMonthYear();
  const duesMap = await buildDuesByStudent({
    studentIds: students.map((s) => s._id),
    month,
    year,
  });

  let unpaid = 0;
  for (const student of students) {
    const dues = duesMap.get(String(student._id));
    if (!dues || !dues.courses.length) continue;
    if (dues.overallStatus === 'paid' || dues.amountRemaining <= 0) continue;
    unpaid += 1;
  }
  return unpaid;
};

const getFounderDashboard = async () => {
  const [branches, students, teachers, activeBranches, activeStudents, unpaidStudents] =
    await Promise.all([
      Branch.countDocuments(),
      Student.countDocuments(),
      Teacher.countDocuments({ role: { $ne: 'founder' } }),
      Branch.countDocuments({ isActive: true }),
      Student.countDocuments({ status: 'active' }),
      countUnpaidStudents(),
    ]);

  const recentBranches = await Branch.find().sort({ createdAt: -1 }).limit(5);

  return {
    role: 'founder',
    stats: {
      branches,
      activeBranches,
      students,
      teachers,
      activeStudents,
      unpaidStudents,
    },
    recentBranches: recentBranches.map((b) => ({
      id: b._id,
      name: b.name,
      isActive: b.isActive,
    })),
  };
};

const getAdminDashboard = async (branchId, role = 'admin') => {
  const [stats, unpaidStudents] = await Promise.all([
    getBranchStats(branchId),
    countUnpaidStudents({ branchId }),
  ]);
  const branch = await Branch.findById(branchId);

  const recentStudents = await Student.find({ branchId })
    .sort({ createdAt: -1 })
    .limit(5)
    .select('name email status studentId createdAt');

  return {
    role,
    branch: branch ? { id: branch._id, name: branch.name, isActive: branch.isActive } : null,
    stats: {
      ...stats,
      unpaidStudents,
    },
    recentStudents: recentStudents.map((s) => ({
      id: s._id,
      name: s.name,
      email: s.email,
      status: s.status,
      studentId: s.studentId,
    })),
  };
};

const getTeacherDashboard = async (teacher) => {
  const branch = await Branch.findById(teacher.branchId);
  const studentsInBranch = await Student.countDocuments({
    branchId: teacher.branchId,
    status: 'active',
  });

  return {
    role: 'teacher',
    branch: branch ? { id: branch._id, name: branch.name } : null,
    stats: {
      studentsInBranch,
      subjects: teacher.subject?.length || 0,
    },
    greeting: teacher.name,
  };
};

const getStudentDashboard = async (student) => {
  const branch = await Branch.findById(student.branchId);

  return {
    role: 'student',
    branch: branch ? { id: branch._id, name: branch.name } : null,
    profile: student.toPublicJSON(),
    stats: {
      examEligibility: student.examEligibility,
      status: student.status,
    },
  };
};

const getDashboard = async (req) => {
  if (req.userType === 'student') {
    return getStudentDashboard(req.user);
  }

  if (req.user.role === 'founder') {
    return getFounderDashboard();
  }

  if (req.user.role === 'admin') {
    return getAdminDashboard(req.user.branchId, 'admin');
  }

  if (req.user.role === 'manager') {
    return getAdminDashboard(req.user.branchId, 'manager');
  }

  if (req.user.role === 'sales') {
    return getAdminDashboard(req.user.branchId, 'sales');
  }

  if (req.user.role === 'receptionist') {
    return getAdminDashboard(req.user.branchId, 'receptionist');
  }

  if (req.user.role === 'teacher') {
    return getTeacherDashboard(req.user);
  }

  return getAdminDashboard(req.user.branchId);
};

module.exports = { getDashboard, getBranchStats };
