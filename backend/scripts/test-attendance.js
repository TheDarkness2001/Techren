require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const ClassSchedule = require('../src/models/ClassSchedule');
const Student = require('../src/models/Student');

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

  const teacherLogin = await login(base, 'teacher@techren.uz', 'Teacher123!');
  const teacherHeaders = { Authorization: `Bearer ${teacherLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const checkIn = await fetch(`${base}/attendance/check-in`, { method: 'POST', headers: teacherHeaders, body: '{}' });
  const todayClasses = await fetch(`${base}/student-attendance/today-classes`, { headers: teacherHeaders });

  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const schedule = await ClassSchedule.findOne();
  const student = await Student.findOne({ email: 'student@techren.uz' });

  const mark = await fetch(`${base}/student-attendance/mark`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({
      classScheduleId: schedule._id,
      records: [{ studentId: student._id, status: 'present' }],
    }),
  });

  const feedback = await fetch(`${base}/feedback`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({
      studentId: student._id,
      classScheduleId: schedule._id,
      homework: 85,
      behavior: 90,
      participation: 88,
    }),
  });

  const studentLogin = await login(base, 'student@techren.uz', 'Student123!', 'student');
  const studentFeedback = await fetch(`${base}/feedback?page=1&limit=20`, {
    headers: { Authorization: `Bearer ${studentLogin.data.accessToken}` },
  });
  const studentFeedbackJson = await studentFeedback.json();

  console.log('check-in:', checkIn.status);
  console.log('today-classes:', todayClasses.status, (await todayClasses.json()).data?.length);
  console.log('mark attendance:', mark.status);
  console.log('submit feedback:', feedback.status);
  console.log(
    'student feedback list:',
    studentFeedback.status,
    studentFeedbackJson.data?.length,
    'meta:',
    studentFeedbackJson.meta
  );

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
