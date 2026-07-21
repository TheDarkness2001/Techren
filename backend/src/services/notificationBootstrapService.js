const Student = require('../models/Student');
const notificationService = require('./notificationService');

const ensureNotificationsDemoContent = async () => {
  const student = await Student.findOne({ email: 'student@techren.uz' });
  if (!student) return;

  await notificationService.getParentSettings(student._id);

  const existing = await require('../models/NotificationLog').exists({
    userId: student._id,
    eventType: 'welcome',
  });
  if (existing) return;

  await notificationService.createInAppNotification({
    userId: student._id,
    userType: 'student',
    studentId: student._id,
    title: 'Welcome to TechRen EDU',
    body: 'Your learning journey starts here. Check schedule and practice daily!',
    eventType: 'welcome',
    data: {},
    branchId: student.branchId,
  });
};

module.exports = { ensureNotificationsDemoContent };
