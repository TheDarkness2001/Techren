require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Level = require('../src/models/Level');
const Lesson = require('../src/models/Lesson');
const ExamGroup = require('../src/models/ExamGroup');

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
  const headers = {
    Authorization: `Bearer ${adminLogin.json.data.accessToken}`,
    'Content-Type': 'application/json',
  };

  const level = await Level.findOne({ moduleType: 'words' });
  const lesson = await Lesson.findOne({ type: 'words', levelId: level?._id });
  const group = await ExamGroup.findOne();

  const practiceOn = level && group
    ? await fetch(`${base}/homework/levels/${level._id}/practice-unlock`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ groupId: group._id.toString(), unlock: true }),
      })
    : null;

  const practiceOff = level && group
    ? await fetch(`${base}/homework/levels/${level._id}/practice-unlock`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ groupId: group._id.toString(), unlock: false }),
      })
    : null;

  const examOn = lesson && group
    ? await fetch(`${base}/homework/lessons/${lesson._id}/toggle-exam-lock`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ groupId: group._id.toString(), unlock: true }),
      })
    : null;

  const examOff = lesson && group
    ? await fetch(`${base}/homework/lessons/${lesson._id}/toggle-exam-lock`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ groupId: group._id.toString(), unlock: false }),
      })
    : null;

  console.log('admin login:', adminLogin.status);
  console.log('practice unlock on:', practiceOn?.status, practiceOn ? (await practiceOn.json()).data?.practiceUnlockedFor?.length : null);
  console.log('practice unlock off:', practiceOff?.status);
  console.log('exam unlock on:', examOn?.status, examOn ? (await examOn.json()).data?.examUnlockedFor?.length : null);
  console.log('exam unlock off:', examOff?.status);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
