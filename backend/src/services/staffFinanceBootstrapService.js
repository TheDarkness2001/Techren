const Teacher = require('../models/Teacher');
const StaffEarning = require('../models/StaffEarning');
const staffEarningService = require('./staffEarningService');

const ensureStaffFinanceDemoContent = async () => {
  const exists = await StaffEarning.exists({});
  if (exists) return;

  const teacher = await Teacher.findOne({ email: 'teacher@techren.uz' });
  if (!teacher) return;

  teacher.perClassEarning = 50000;
  await teacher.save();

  await StaffEarning.create({
    staffId: teacher._id,
    amount: 50000,
    earningType: 'per-class',
    status: 'pending',
    referenceDate: new Date(),
    description: 'Demo class earning',
    createdByType: 'system',
    branchId: teacher.branchId,
  });

  await staffEarningService.recalculate({ userType: 'teacher', user: { role: 'founder' } }, teacher._id);
};

module.exports = { ensureStaffFinanceDemoContent };
