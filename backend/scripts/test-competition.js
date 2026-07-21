require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Student = require('../src/models/Student');
const Branch = require('../src/models/Branch');
const ExamGroup = require('../src/models/ExamGroup');

async function login(base, email, password, userType = 'student') {
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

  const student = await Student.findOne({ email: 'student@techren.uz' });
  const branch = await Branch.findOne();
  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  const now = new Date();

  const studentLogin = await login(base, 'student@techren.uz', 'Student123!');
  const teacherLogin = await login(base, 'teacher@techren.uz', 'Teacher123!', 'teacher');
  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!', 'teacher');

  const studentHeaders = { Authorization: `Bearer ${studentLogin.data.accessToken}`, 'Content-Type': 'application/json' };
  const teacherHeaders = { Authorization: `Bearer ${teacherLogin.data.accessToken}`, 'Content-Type': 'application/json' };
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const studentPenalties = await fetch(`${base}/penalties/student/${student._id}`, { headers: studentHeaders });
  const studentPresentations = await fetch(`${base}/presentations/student/${student._id}`, { headers: studentHeaders });
  const groupPenalties = await fetch(`${base}/penalties/group/${group._id}`, { headers: teacherHeaders });
  const monthly = await fetch(`${base}/penalties/monthly?year=${now.getFullYear()}&month=${now.getMonth() + 1}&branchId=${branch._id}&page=1&limit=20`, { headers: teacherHeaders });
  const monthlyJson = await monthly.json();
  const top = await fetch(`${base}/presentations/top?year=${now.getFullYear()}&month=${now.getMonth() + 1}&branchId=${branch._id}`, { headers: teacherHeaders });
  const calculate = await fetch(`${base}/bonuses/calculate?year=${now.getFullYear()}&month=${now.getMonth() + 1}&branchId=${branch._id}`, { headers: adminHeaders });
  const history = await fetch(`${base}/bonuses/history?branchId=${branch._id}`, { headers: adminHeaders });

  const penaltyJson = await studentPenalties.json();
  const presentationJson = await studentPresentations.json();
  const calcJson = await calculate.json();

  console.log('student penalties:', studentPenalties.status, penaltyJson.data?.penalties?.length, 'total', penaltyJson.data?.total);
  console.log('student presentations:', studentPresentations.status, presentationJson.data?.count);
  console.log('group penalties:', groupPenalties.status);
  console.log('monthly penalties:', monthly.status, monthlyJson.data?.penalties?.length, 'meta:', monthlyJson.meta);
  console.log('top presenters:', top.status);
  console.log('bonus calculate:', calculate.status, calcJson.data?.totalPenalties);
  console.log('bonus history:', history.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
