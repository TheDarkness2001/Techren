require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults, getSettings } = require('../src/services/settingsService');
const Student = require('../src/models/Student');
const { ensureWalletDemoContent } = require('../src/services/walletBootstrapService');

async function login(base, email, password, userType = 'student') {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType }),
  });
  return { status: res.status, json: await res.json() };
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();
  await ensureWalletDemoContent();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const studentLogin = await login(base, 'student@techren.uz', 'Student123!');
  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!', 'teacher');
  const studentHeaders = { Authorization: `Bearer ${studentLogin.json.data.accessToken}`, 'Content-Type': 'application/json' };
  const adminHeaders = { Authorization: `Bearer ${adminLogin.json.data.accessToken}`, 'Content-Type': 'application/json' };

  const balance = await fetch(`${base}/wallet/balance`, { headers: studentHeaders });
  const balanceJson = await balance.json();

  const transactions = await fetch(`${base}/wallet/transactions?page=1&limit=20`, { headers: studentHeaders });
  const transactionsJson = await transactions.json();

  const topup = await fetch(`${base}/wallet/topup`, {
    method: 'POST',
    headers: studentHeaders,
    body: JSON.stringify({ amountSom: 10000, description: 'Test top-up' }),
  });
  const topupJson = await topup.json();

  const balanceAfter = await fetch(`${base}/wallet/balance`, { headers: studentHeaders });
  const balanceAfterJson = await balanceAfter.json();

  const student = await Student.findOne({ email: 'student@techren.uz' });
  const deduct = await fetch(`${base}/wallet/deduct`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({
      studentId: student._id.toString(),
      amountSom: 5000,
      type: 'deduction',
      description: 'Test admin deduction',
    }),
  });
  const deductJson = await deduct.json();

  const settings = await getSettings();

  console.log('wallet enabled:', settings.featureFlags.walletEnabled);
  console.log('student login:', studentLogin.status);
  console.log('balance:', balance.status, balanceJson.data?.balanceSom);
  console.log('transactions:', transactions.status, transactionsJson.data?.items?.length, 'meta:', transactionsJson.data?.meta);
  console.log('topup:', topup.status, topupJson.data?.transaction?.type);
  console.log('balance after topup:', balanceAfter.status, balanceAfterJson.data?.balanceSom);
  console.log('admin deduct:', deduct.status, deductJson.data?.transaction?.type);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
