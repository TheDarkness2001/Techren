require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

async function login(base, email, password, userType = 'parent') {
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

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const parentLogin = await login(base, 'parent@techren.uz', 'Parent123!');
  if (parentLogin.status !== 200) {
    console.log('parent login failed:', parentLogin.status, parentLogin.json);
    server.close();
    await disconnectDB();
    process.exit(1);
  }
  const parentHeaders = { Authorization: `Bearer ${parentLogin.json.data.accessToken}`, 'Content-Type': 'application/json' };

  const children = await fetch(`${base}/parent/children`, { headers: parentHeaders });
  const childrenJson = await children.json();
  const studentId = childrenJson.data?.children?.[0]?.id;

  const overview = studentId
    ? await fetch(`${base}/parent/children/${studentId}/overview`, { headers: parentHeaders })
    : null;
  const feedbackRes = studentId
    ? await fetch(`${base}/parent/children/${studentId}/feedback?page=1&limit=20`, { headers: parentHeaders })
    : null;
  const feedbackJson = feedbackRes ? await feedbackRes.json() : null;
  const attendanceRes = studentId
    ? await fetch(`${base}/parent/children/${studentId}/attendance?page=1&limit=20`, { headers: parentHeaders })
    : null;
  const attendanceJson = attendanceRes ? await attendanceRes.json() : null;
  const examsRes = studentId
    ? await fetch(`${base}/parent/children/${studentId}/exams?page=1&limit=20`, { headers: parentHeaders })
    : null;
  const examsJson = examsRes ? await examsRes.json() : null;

  const feedbackItem = feedbackJson?.data?.feedback?.[0];
  const comment = feedbackItem?.id
    ? await fetch(`${base}/feedback/${feedbackItem.id}/parent-comment`, {
        method: 'PUT',
        headers: parentHeaders,
        body: JSON.stringify({ comment: 'Thank you teacher, we will practice more at home.' }),
      })
    : null;

  console.log('parent login:', parentLogin.status);
  console.log('children:', children.status, childrenJson.data?.children?.length);
  console.log('overview:', overview?.status);
  console.log('feedback:', feedbackRes?.status, feedbackJson?.data?.feedback?.length, 'meta:', feedbackJson?.meta);
  console.log('attendance:', attendanceRes?.status, attendanceJson?.data?.attendance?.length, 'meta:', attendanceJson?.meta);
  console.log('exams:', examsRes?.status, examsJson?.data?.exams?.length, 'meta:', examsJson?.meta);
  console.log('parent comment:', comment?.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
