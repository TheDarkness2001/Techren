const Settings = require('../models/Settings');
const Parent = require('../models/Parent');
const Student = require('../models/Student');

const ensureParentPortalDemo = async () => {
  await Settings.findByIdAndUpdate(
    'global',
    { $set: { 'featureFlags.parentPortalEnabled': true } },
    { upsert: false }
  );

  const exists = await Parent.exists({ email: 'parent@techren.uz' });
  if (exists) return;

  const student = await Student.findOne({ email: 'student@techren.uz' });
  if (!student) return;

  await Parent.create({
    name: student.parentName || 'Demo Parent',
    email: 'parent@techren.uz',
    password: 'Parent123!',
    phone: student.parentPhone || '+998 90 000 0000',
    children: [student._id],
    status: 'active',
  });
};

module.exports = { ensureParentPortalDemo };
