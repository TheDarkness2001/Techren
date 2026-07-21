require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}/api/v1`;

  const login = await (await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@techren.uz', password: 'Admin123!', userType: 'teacher' }),
  })).json();

  const headers = { Authorization: `Bearer ${login.data.accessToken}` };
  const unified = await (await fetch(`${base}/exam-groups/unified-view?page=1&limit=20`, { headers })).json();
  const timetable = await (await fetch(`${base}/timetable/admin`, { headers })).json();
  const studentLogin = await (await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'student@techren.uz', password: 'Student123!', userType: 'student' }),
  })).json();
  const studentTt = await (await fetch(`${base}/timetable/student`, {
    headers: { Authorization: `Bearer ${studentLogin.data.accessToken}` },
  })).json();

  const schedules = await (await fetch(`${base}/class-schedules?page=1&limit=20&search=English`, { headers })).json();
  const groupsSearch = await (await fetch(`${base}/exam-groups/unified-view?page=1&limit=20&search=English`, { headers })).json();

  console.log('unified groups:', unified.data?.length, 'meta:', unified.meta);
  console.log('groups search:', groupsSearch.data?.length, 'meta:', groupsSearch.meta);
  console.log('schedules search:', schedules.data?.length, 'meta:', schedules.meta);
  console.log('admin timetable total:', timetable.data?.total);
  console.log('student timetable total:', studentTt.data?.total);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
