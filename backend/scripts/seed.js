require('dotenv').config();

const connectDB = require('../src/config/database');
const { Branch, Teacher } = require('../src/models');
const { initDefaults } = require('../src/services/settingsService');
const config = require('../src/config');

/**
 * Seeds founder only. Does not create demo role accounts and never deletes existing users.
 */
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
  } else {
    console.log(`Founder already exists: ${founderEmail}`);
  }

  console.log('\nSeed complete. Create staff/students from the app — no demo accounts are added.');
  process.exit(0);
};

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
