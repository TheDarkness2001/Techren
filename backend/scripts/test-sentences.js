require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Lesson = require('../src/models/Lesson');
const Sentence = require('../src/models/Sentence');

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

  const lesson = await Lesson.findOne({ type: 'sentences' });
  const sentence = await Sentence.findOne({ lessonId: lesson._id });

  const tree = await fetch(`${base}/sentences/student-lessons`, { headers });
  const random = await fetch(`${base}/sentences/random?lessonId=${lesson._id}`, { headers });
  const check = await fetch(`${base}/sentences/check`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ sentenceId: sentence._id, answer: sentence.english, direction: 'uzToEn' }),
  });
  const progress = await fetch(`${base}/sentences/progress`, { headers });
  const leaderboard = await fetch(`${base}/sentences/leaderboard`, { headers });

  console.log('student-lessons:', tree.status, (await tree.json()).data?.length);
  console.log('random:', random.status);
  console.log('check:', check.status, (await check.json()).data?.isCorrect);
  console.log('progress:', progress.status);
  console.log('leaderboard:', leaderboard.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
