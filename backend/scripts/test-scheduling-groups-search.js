require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
require('../src/models');
const examGroupService = require('../src/services/examGroupService');
const ExamGroup = require('../src/models/ExamGroup');

const mockReq = (query = {}) => ({
  query,
  userType: 'teacher',
  user: { role: 'founder', branchId: null },
  branchId: null,
});

async function run() {
  await connectDB();

  const sampleGroup = await ExamGroup.findOne().populate('subject', 'name');
  if (!sampleGroup) {
    console.log('skip groups search: no exam groups in database');
    await disconnectDB();
    return;
  }

  const term = sampleGroup.groupName?.split(' ')[0]
    || sampleGroup.subject?.name
    || 'group';
  const all = await examGroupService.getUnifiedView(mockReq(), { page: 1, limit: 20 });
  const filtered = await examGroupService.getUnifiedView(mockReq(), { page: 1, limit: 20, search: term });

  console.log('groups search term:', term);
  console.log('groups list total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('groups search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0) {
    throw new Error('groups search returned zero matches for known term');
  }

  console.log('scheduling groups search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
