require('dotenv').config();

const connectDB = require('../src/config/database');
const { Branch, Teacher, Student } = require('../src/models');
const { initDefaults } = require('../src/services/settingsService');
const config = require('../src/config');

const seed = async () => {
  await connectDB();
  await initDefaults();

  let branch = await Branch.findOne({ name: 'TechRen HQ' });
  if (!branch) {
    branch = await Branch.create({
      name: 'TechRen HQ',
      address: 'Tashkent, Uzbekistan',
      phone: '+998 71 000 0000',
      isActive: true,
    });
    console.log('Created branch: TechRen HQ');
  }

  const founderEmail = config.founder.email.toLowerCase();
  let founder = await Teacher.findOne({ email: founderEmail });
  if (!founder) {
    founder = await Teacher.create({
      name: 'Founder',
      email: founderEmail,
      password: config.founder.password,
      role: 'founder',
      branchId: branch._id,
      status: 'active',
    });
    branch.createdBy = founder._id;
    await branch.save();
    console.log(`Created founder: ${founderEmail}`);
  }

  const studentEmail = 'student@techren.uz';
  let student = await Student.findOne({ email: studentEmail });
  if (!student) {
    student = await Student.create({
      name: 'Demo Student',
      email: studentEmail,
      password: 'Student123!',
      branchId: branch._id,
      status: 'active',
    });
    console.log(`Created student: ${studentEmail}`);
  }

  console.log('\nSeed complete.');
  console.log(`Founder login: ${founderEmail} / ${config.founder.password}`);
  console.log('Student login: student@techren.uz / Student123!');
  process.exit(0);
};

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
