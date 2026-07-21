require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Teacher = require('../src/models/Teacher');

async function login(base, email, password, userType = 'teacher') {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType }),
  });
  return res.json();
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const teacher = await Teacher.findOne({ email: 'teacher@techren.uz' });
  const teacherLogin = await login(base, 'teacher@techren.uz', 'Teacher123!');
  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const teacherHeaders = { Authorization: `Bearer ${teacherLogin.data.accessToken}`, 'Content-Type': 'application/json' };
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const list = await fetch(`${base}/staff-earnings?staffId=${teacher._id}&page=1&limit=20`, { headers: teacherHeaders });
  const account = await fetch(`${base}/staff-earnings/account?staffId=${teacher._id}`, { headers: teacherHeaders });
  const listJson = await list.json();
  const earningId = listJson.data?.earnings?.[0]?.id;

  const approve = earningId
    ? await fetch(`${base}/staff-earnings/${earningId}/approve`, { method: 'PATCH', headers: adminHeaders })
    : null;
  const bonus = await fetch(`${base}/staff-earnings/${teacher._id}/bonus`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({ amount: 10000, reason: 'Excellent student feedback this month' }),
  });

  const earningsAfter = await fetch(`${base}/staff-earnings?staffId=${teacher._id}&status=approved&page=1&limit=20`, { headers: adminHeaders });
  const earningsJson = await earningsAfter.json();
  const approvedIds = (earningsJson.data?.earnings || []).map((e) => e.id);

  const preview = approvedIds.length
    ? await fetch(`${base}/staff-payouts/preview?staffId=${teacher._id}&earningIds=${approvedIds.join(',')}`, { headers: adminHeaders })
    : null;
  const payout = approvedIds.length
    ? await fetch(`${base}/staff-payouts`, {
        method: 'POST',
        headers: adminHeaders,
        body: JSON.stringify({ staffId: teacher._id, earningIds: approvedIds.slice(0, 1), method: 'cash' }),
      })
    : null;
  const payouts = await fetch(`${base}/staff-payouts?staffId=${teacher._id}&page=1&limit=20`, { headers: teacherHeaders });
  const payoutsJson = await payouts.json();

  console.log('earnings list:', list.status, listJson.data?.earnings?.length, 'meta:', listJson.meta);
  console.log('account:', account.status, (await account.json()).data?.account?.pendingEarnings);
  console.log('approve:', approve?.status);
  console.log('bonus:', bonus.status);
  console.log('preview:', preview?.status);
  console.log('create payout:', payout?.status);
  console.log('payouts list:', payouts.status, payoutsJson.data?.payouts?.length, 'meta:', payoutsJson.meta);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
