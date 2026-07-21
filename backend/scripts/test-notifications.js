require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const { register: registerNotificationWorker } = require('../src/utils/notificationWorker');
const { initFirebase } = require('../src/config/firebase');
const Student = require('../src/models/Student');
const ClassSchedule = require('../src/models/ClassSchedule');

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
  initFirebase();
  registerNotificationWorker();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const student = await Student.findOne({ email: 'student@techren.uz' });
  const schedule = await ClassSchedule.findOne();
  const studentLogin = await login(base, 'student@techren.uz', 'Student123!');
  const teacherLogin = await login(base, 'teacher@techren.uz', 'Teacher123!', 'teacher');
  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!', 'teacher');

  const studentHeaders = { Authorization: `Bearer ${studentLogin.data.accessToken}`, 'Content-Type': 'application/json' };
  const teacherHeaders = { Authorization: `Bearer ${teacherLogin.data.accessToken}`, 'Content-Type': 'application/json' };
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const list = await fetch(`${base}/notifications`, { headers: studentHeaders });
  const listJson = await list.json();
  const notificationId = listJson.data?.notifications?.[0]?.id;

  const fcm = await fetch(`${base}/students/${student._id}/fcm-token`, {
    method: 'POST',
    headers: studentHeaders,
    body: JSON.stringify({ token: 'dev-fcm-token-demo-1234567890' }),
  });

  const settingsGet = await fetch(`${base}/students/${student._id}/notification-settings`, { headers: adminHeaders });
  const settingsPut = await fetch(`${base}/students/${student._id}/notification-settings`, {
    method: 'PUT',
    headers: adminHeaders,
    body: JSON.stringify({ events: { feedback: true, attendance: true, payment: true, exam: true } }),
  });

  const feedback = schedule
    ? await fetch(`${base}/feedback`, {
        method: 'POST',
        headers: adminHeaders,
        body: JSON.stringify({
          studentId: student._id,
          classScheduleId: schedule._id,
          homework: 85,
          behavior: 90,
          participation: 88,
        }),
      })
    : null;

  const listAfterFeedback = await fetch(`${base}/notifications`, { headers: studentHeaders });
  const markRead = notificationId
    ? await fetch(`${base}/notifications/${notificationId}/read`, { method: 'PATCH', headers: studentHeaders })
    : null;
  const markAll = await fetch(`${base}/notifications/read-all`, { method: 'PATCH', headers: studentHeaders });

  console.log('list:', list.status, listJson.data?.notifications?.length, 'unread:', listJson.data?.unreadCount);
  console.log('pagination meta:', listJson.data?.meta?.page, listJson.data?.meta?.totalPages);
  console.log('fcm token:', fcm.status);
  console.log('settings get:', settingsGet.status);
  console.log('settings put:', settingsPut.status);
  console.log('feedback trigger:', feedback?.status);
  console.log('list after feedback:', listAfterFeedback.status, (await listAfterFeedback.json()).data?.notifications?.length);
  console.log('mark read:', markRead?.status);
  console.log('mark all read:', markAll.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
