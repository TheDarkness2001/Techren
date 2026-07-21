require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const notificationService = require('../src/services/notificationService');
const NotificationLog = require('../src/models/NotificationLog');

async function run() {
  await connectDB();

  const sample = await NotificationLog.findOne({ channel: 'in_app' }).select('title body eventType userId userType');
  if (!sample) {
    const any = await NotificationLog.findOne().select('title eventType');
    const term = any?.eventType?.split('_')[0] || 'notification';
    const empty = await notificationService.listForUser({
      query: { page: 1, limit: 20, search: term },
      userType: 'student',
      user: { _id: '000000000000000000000000' },
    });
    if (empty.meta.total !== 0) {
      throw new Error('expected zero results for unknown user inbox search');
    }
    console.log('notification search filter OK (no in-app sample user; empty inbox verified)');
    await disconnectDB();
    return;
  }

  const term = sample.title?.split(' ')[0] || sample.eventType?.split('_')[0] || 'feedback';
  const mockReq = (query = {}) => ({
    query,
    userType: sample.userType,
    user: { _id: sample.userId },
  });

  const all = await notificationService.listForUser(mockReq({ page: 1, limit: 20 }));
  const filtered = await notificationService.listForUser(mockReq({ page: 1, limit: 20, search: term }));

  console.log('notification search term:', term);
  console.log('notification list total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('notification search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0) {
    throw new Error('notification search returned zero matches for known term');
  }

  console.log('notification search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
