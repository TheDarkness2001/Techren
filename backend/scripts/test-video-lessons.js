require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const VideoLesson = require('../src/models/VideoLesson');

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

  const studentLogin = await login(base, 'student@techren.uz', 'Student123!');
  const headers = { Authorization: `Bearer ${studentLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const video = await VideoLesson.findOne({ title: 'English Greetings' });

  const list = await fetch(`${base}/video-lessons`, { headers });
  const listJson = await list.json();
  const detail = await fetch(`${base}/video-lessons/${video._id}`, { headers });
  const detailJson = await detail.json();
  const track = await fetch(`${base}/video-lessons/${video._id}/track`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ watchPercent: 75, lastTimestamp: 60, delta: 30 }),
  });
  const practiceTest = await fetch(`${base}/video-lessons/${video._id}/test?mode=practice`, { headers });
  const practiceJson = await practiceTest.json();
  const q0 = practiceJson.data?.test?.questions?.[0];
  const attempt = await fetch(`${base}/video-lessons/${video._id}/test/attempt`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      mode: 'practice',
      answers: [{ questionId: q0.id, answer: 'Hello' }],
    }),
  });
  const attemptJson = await attempt.json();
  const examTest = await fetch(`${base}/video-lessons/${video._id}/test?mode=exam`, { headers });
  const leaderboard = await fetch(`${base}/video-lessons/${video._id}/test/leaderboard`, { headers });
  const warning = await fetch(`${base}/video-lessons/${video._id}/test/warning`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ warnings: 1 }),
  });

  const hasCorrectInPractice = JSON.stringify(practiceJson).includes('correctAnswer');

  console.log('list:', list.status, listJson.data?.videoLessons?.length);
  console.log('detail:', detail.status, detailJson.data?.hasTest);
  console.log('track:', track.status, (await track.json()).data?.progress?.watchPercent);
  console.log('practice test:', practiceTest.status, practiceJson.data?.test?.questions?.length);
  console.log('answers hidden:', !hasCorrectInPractice);
  console.log('attempt:', attempt.status, attemptJson.data?.score);
  console.log('exam gate (should pass after track):', examTest.status);
  console.log('leaderboard:', leaderboard.status);
  console.log('warning:', warning.status, (await warning.json()).data?.terminate);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
