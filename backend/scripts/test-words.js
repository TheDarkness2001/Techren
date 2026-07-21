require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Lesson = require('../src/models/Lesson');
const Word = require('../src/models/Word');

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
  const studentHeaders = { Authorization: `Bearer ${studentLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const lesson = await Lesson.findOne();
  const word = await Word.findOne({ lessonId: lesson._id });

  const languages = await fetch(`${base}/homework/languages?moduleType=words`, { headers: studentHeaders });
  const studentLessons = await fetch(`${base}/homework/student-lessons`, { headers: studentHeaders });
  const random = await fetch(`${base}/homework/words/random?lessonId=${lesson._id}`, { headers: studentHeaders });
  const check = await fetch(`${base}/homework/check-answer`, {
    method: 'POST',
    headers: studentHeaders,
    body: JSON.stringify({ wordId: word._id, answer: word.uzbek.split(',')[0].trim(), direction: 'en-to-uz' }),
  });
  const submit = await fetch(`${base}/homework/submit-result`, {
    method: 'POST',
    headers: studentHeaders,
    body: JSON.stringify({ sessionStats: { totalAttempts: 1, correctAnswers: 1, enToUzCorrect: 1, enToUzTotal: 1 } }),
  });
  const leaderboard = await fetch(`${base}/homework/leaderboard`, { headers: studentHeaders });
  const exam = await fetch(`${base}/homework/lessons/${lesson._id}/exam`, { headers: studentHeaders });

  console.log('languages:', languages.status);
  console.log('student-lessons:', studentLessons.status, (await studentLessons.json()).data?.length);
  console.log('random word:', random.status);
  console.log('check-answer:', check.status, (await check.json()).data?.isCorrect);
  console.log('submit-result:', submit.status);
  console.log('leaderboard:', leaderboard.status);
  console.log('exam (class hours):', exam.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
