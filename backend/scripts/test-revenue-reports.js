require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

async function login(base, email, password) {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType: 'teacher' }),
  });
  return { status: res.status, json: await res.json() };
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const headers = { Authorization: `Bearer ${adminLogin.json.data.accessToken}` };

  const summary = await fetch(`${base}/revenue/summary`, { headers });
  const chart = await fetch(`${base}/revenue/chart`, { headers });
  const exportRes = await fetch(`${base}/revenue/export`, { headers });
  const pending = await fetch(`${base}/revenue/pending`, { headers });

  const summaryJson = await summary.json();
  const chartJson = await chart.json();
  const exportJson = await exportRes.json();

  console.log('Revenue summary:', summary.status, summaryJson.success ? 'OK' : summaryJson);
  console.log('Revenue chart:', chart.status, chartJson.success ? 'OK' : chartJson);
  console.log('Revenue export:', exportRes.status, exportJson.success ? 'OK' : exportJson);
  console.log('Revenue pending:', pending.status);

  const ok =
    summary.status === 200 &&
    chart.status === 200 &&
    exportRes.status === 200 &&
    pending.status === 200 &&
    summaryJson.success &&
    chartJson.success &&
    exportJson.success &&
    Array.isArray(chartJson.data?.byMonth) &&
    exportJson.data?.generatedAt;

  server.close();
  await disconnectDB();
  process.exit(ok ? 0 : 1);
}

run().catch(async (err) => {
  console.error(err);
  await disconnectDB();
  process.exit(1);
});
