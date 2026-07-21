require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const branchService = require('../src/services/branchService');
const Branch = require('../src/models/Branch');

const mockReq = (query = {}) => ({
  query,
  userType: 'teacher',
  user: { role: 'founder', branchId: null },
});

async function run() {
  await connectDB();

  const sample = await Branch.findOne().select('name');
  if (!sample) {
    console.log('skip branch search: no branches in database');
    await disconnectDB();
    return;
  }

  const term = sample.name.split(' ')[0];
  const all = await branchService.listBranches(mockReq({ page: 1, limit: 20 }));
  const filtered = await branchService.listBranches(mockReq({ page: 1, limit: 20, search: term }));

  console.log('branch search term:', term);
  console.log('branch list total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('branch search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0) {
    throw new Error('branch search returned zero matches for known term');
  }

  console.log('branch search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
