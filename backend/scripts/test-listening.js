require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Level = require('../src/models/Level');
const ListeningExercise = require('../src/models/ListeningExercise');

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

  const level = await Level.findOne({ moduleType: 'listening' });
  const exercise = await ListeningExercise.findOne({ lessonId: { $exists: true } });

  const tree = await fetch(`${base}/listening/student-levels`, { headers });
  const treeJson = await tree.json();
  const random = await fetch(`${base}/listening/random?levelId=${level._id}`, { headers });
  const randomJson = await random.json();
  const signed = await fetch(`${base}/listening/exercises/${exercise._id}/signed-url`, { headers });
  const signedJson = await signed.json();
  const audioPath = signedJson.data?.url;
  const audio = audioPath ? await fetch(`http://127.0.0.1:${server.address().port}${audioPath}`) : null;

  const check = await fetch(`${base}/listening/check`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ listeningId: exercise._id, answer: exercise.script }),
  });
  const checkJson = await check.json();

  const progress = await fetch(`${base}/listening/progress`, { headers });
  const leaderboard = await fetch(`${base}/listening/leaderboard`, { headers });

  const listAsStudent = await fetch(`${base}/listening/exercises?levelId=${level._id}`, { headers });
  const listJson = await listAsStudent.json();
  const hasScript = JSON.stringify(listJson).includes('script');

  console.log('student-levels:', tree.status, treeJson.data?.length);
  console.log('random:', random.status, randomJson.data?.title);
  console.log('signed-url:', signed.status, Boolean(audioPath));
  console.log('audio stream:', audio?.status, audio?.headers.get('content-type'));
  console.log('check:', check.status, checkJson.data?.tier, checkJson.data?.accuracyPercent);
  console.log('progress:', progress.status);
  console.log('leaderboard:', leaderboard.status);
  console.log('script hidden from student:', !hasScript);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
