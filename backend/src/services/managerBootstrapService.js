const { Teacher, Branch } = require('../models');

const LIMITED_STAFF_ACCOUNTS = [
  {
    name: 'Branch Manager',
    email: 'manager@techren.uz',
    password: 'Manager123!',
    role: 'manager',
  },
  {
    name: 'Sales Staff',
    email: 'sales@techren.uz',
    password: 'Sales123!',
    role: 'sales',
  },
  {
    name: 'Front Desk',
    email: 'receptionist@techren.uz',
    password: 'Reception123!',
    role: 'receptionist',
  },
];

const ensureLimitedStaffDemo = async () => {
  const branch = await Branch.findOne({ isActive: true }).sort({ createdAt: 1 });
  if (!branch) return;

  for (const account of LIMITED_STAFF_ACCOUNTS) {
    const exists = await Teacher.exists({ email: account.email });
    if (exists) continue;

    await Teacher.create({
      name: account.name,
      email: account.email,
      password: account.password,
      role: account.role,
      branchId: branch._id,
      status: 'active',
    });
  }
};

const ensureManagerDemo = ensureLimitedStaffDemo;

module.exports = { ensureManagerDemo, ensureLimitedStaffDemo };
