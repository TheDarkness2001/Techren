const config = require('../config');
const { Branch, Teacher, Student } = require('../models');
const examGroupService = require('./examGroupService');
const { ensureWordsDemoContent } = require('./wordsBootstrapService');
const { ensureSentencesDemoContent } = require('./sentencesBootstrapService');
const { ensureListeningDemoContent } = require('./listeningBootstrapService');
const { ensureVideoDemoContent } = require('./videoBootstrapService');
const { ensureCompetitionDemoContent } = require('./competitionBootstrapService');
const { ensureStaffFinanceDemoContent } = require('./staffFinanceBootstrapService');
const { ensureRecycleBinDemoContent } = require('./recycleBinBootstrapService');
const { ensureNotificationsDemoContent } = require('./notificationBootstrapService');
const { ensureGamificationDemoContent } = require('./gamificationBootstrapService');
const { ensureParentPortalDemo } = require('./parentBootstrapService');
const { ensureWalletDemoContent } = require('./walletBootstrapService');
const { ensureManagerDemo } = require('./managerBootstrapService');

/** Only seeds demo users when SEED_DEMO_DATA=true. Never overwrites Atlas accounts. */
const ensureDevAccounts = async () => {
  if (!config.isDev || !config.seedDemoData) return;

  await ensureManagerDemo();

  const founderExists = await Teacher.exists({ role: 'founder' });
  if (founderExists) return;

  const branch = await Branch.create({
    name: 'TechRen HQ',
    address: 'Tashkent, Uzbekistan',
    phone: '+998 71 000 0000',
    isActive: true,
  });

  const founder = await Teacher.create({
    name: 'Founder',
    email: config.founder.email.toLowerCase(),
    password: config.founder.password,
    role: 'founder',
    branchId: branch._id,
    status: 'active',
  });

  branch.createdBy = founder._id;
  await branch.save();

  const admin = await Teacher.create({
    name: 'Branch Admin',
    email: 'admin@techren.uz',
    password: 'Admin123!',
    role: 'admin',
    branchId: branch._id,
    status: 'active',
  });

  await Teacher.create({
    name: 'Branch Manager',
    email: 'manager@techren.uz',
    password: 'Manager123!',
    role: 'manager',
    branchId: branch._id,
    status: 'active',
  });

  await Teacher.create({
    name: 'Sales Staff',
    email: 'sales@techren.uz',
    password: 'Sales123!',
    role: 'sales',
    branchId: branch._id,
    status: 'active',
  });

  await Teacher.create({
    name: 'Front Desk',
    email: 'receptionist@techren.uz',
    password: 'Reception123!',
    role: 'receptionist',
    branchId: branch._id,
    status: 'active',
  });

  const demoTeacher = await Teacher.create({
    name: 'Demo Teacher',
    email: 'teacher@techren.uz',
    password: 'Teacher123!',
    role: 'teacher',
    branchId: branch._id,
    status: 'active',
    subject: ['English'],
  });

  const student = await Student.create({
    name: 'Demo Student',
    email: 'student@techren.uz',
    password: 'Student123!',
    branchId: branch._id,
    status: 'active',
  });

  await examGroupService.createUnified({
    branchId: branch._id,
    subject: { name: 'English', code: 'ENG', pricePerClass: 50000 },
    group: { groupName: 'English Morning A', studentIds: [student._id], teacherIds: [demoTeacher._id] },
    schedule: {
      className: 'English Morning A',
      teacherId: demoTeacher._id,
      scheduledDays: ['Mon', 'Wed', 'Fri'],
      startTime: '10:00',
      endTime: '11:30',
    },
  });

  await ensureWordsDemoContent();
  await ensureRecycleBinDemoContent();
  await ensureNotificationsDemoContent();
  await ensureGamificationDemoContent();
  await ensureSentencesDemoContent();
  await ensureListeningDemoContent();
  await ensureVideoDemoContent();
  await ensureCompetitionDemoContent();
  await ensureStaffFinanceDemoContent();
  await ensureParentPortalDemo();
  await ensureWalletDemoContent();
};

module.exports = { ensureDevAccounts };
