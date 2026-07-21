require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
require('../src/models');
const staffEarningService = require('../src/services/staffEarningService');
const staffPayoutService = require('../src/services/staffPayoutService');
const StaffEarning = require('../src/models/StaffEarning');
const StaffPayout = require('../src/models/StaffPayout');
const Teacher = require('../src/models/Teacher');

const mockReq = (query = {}) => ({
  query,
  userType: 'teacher',
  user: { role: 'founder', branchId: null, _id: null },
});

async function run() {
  await connectDB();

  const teacher = await Teacher.findOne().select('_id name');
  const earning = await StaffEarning.findOne().select('earningType status description reason staffId');
  const payout = await StaffPayout.findOne().select('payoutRef status method staffId');

  if (teacher && earning) {
    const term = earning.earningType || earning.status || 'pending';
    const all = await staffEarningService.listEarnings(mockReq(), {
      page: 1,
      limit: 20,
      staffId: String(earning.staffId || teacher._id),
    });
    const filtered = await staffEarningService.listEarnings(mockReq(), {
      page: 1,
      limit: 20,
      staffId: String(earning.staffId || teacher._id),
      search: term,
    });
    console.log('earnings search term:', term);
    console.log('earnings total:', all.meta.total, 'filtered:', filtered.meta.total);
    if (filtered.meta.total > all.meta.total) {
      throw new Error('earnings search returned more results than unfiltered list');
    }
  } else {
    console.log('skip earnings search: no earnings in database');
  }

  if (payout) {
    const term = payout.payoutRef?.split('-')[0] || payout.status || 'PAYOUT';
    const all = await staffPayoutService.listPayouts(mockReq(), {
      page: 1,
      limit: 20,
      staffId: payout.staffId ? String(payout.staffId) : undefined,
    });
    const filtered = await staffPayoutService.listPayouts(mockReq(), {
      page: 1,
      limit: 20,
      staffId: payout.staffId ? String(payout.staffId) : undefined,
      search: term,
    });
    console.log('payouts search term:', term);
    console.log('payouts total:', all.meta.total, 'filtered:', filtered.meta.total);
    if (filtered.meta.total > all.meta.total) {
      throw new Error('payouts search returned more results than unfiltered list');
    }
  } else {
    console.log('skip payouts search: no payouts in database');
  }

  console.log('staff finance search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
