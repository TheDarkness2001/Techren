require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
require('../src/models');
const feedbackService = require('../src/services/feedbackService');
const Feedback = require('../src/models/Feedback');

const mockReq = (query = {}) => ({
  query,
  userType: 'teacher',
  user: { role: 'founder', branchId: null },
});

async function run() {
  await connectDB();

  const sample = await Feedback.findOne()
    .populate('classSchedule', 'className')
    .populate('student', 'name');
  if (!sample) {
    console.log('skip feedback search: no feedback in database');
    await disconnectDB();
    return;
  }

  const term = sample.classSchedule?.className?.split(' ')[0]
    || sample.student?.name?.split(' ')[0]
    || sample.date
    || '202';
  const all = await feedbackService.list(mockReq({ page: 1, limit: 20 }));
  const filtered = await feedbackService.list(mockReq({ page: 1, limit: 20, search: term }));

  console.log('feedback search term:', term);
  console.log('feedback list total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('feedback search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0) {
    throw new Error('feedback search returned zero matches for known term');
  }

  console.log('feedback search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
