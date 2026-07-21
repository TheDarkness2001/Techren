require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

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

  const profile = await fetch(`${base}/gamification/profile`, { headers: studentHeaders });
  const achievements = await fetch(`${base}/gamification/achievements`, { headers: studentHeaders });
  const leaderboard = await fetch(`${base}/gamification/leaderboard`, { headers: studentHeaders });
  const recommendations = await fetch(`${base}/gamification/recommendations`, { headers: studentHeaders });

  const submit = await fetch(`${base}/homework/submit-result`, {
    method: 'POST',
    headers: studentHeaders,
    body: JSON.stringify({ sessionStats: { totalAttempts: 5, correctAnswers: 3, enToUzCorrect: 2, enToUzTotal: 3, uzToEnCorrect: 1, uzToEnTotal: 2 } }),
  });

  const profileAfter = await fetch(`${base}/gamification/profile`, { headers: studentHeaders });
  const profileJson = await profile.json();
  const achievementsJson = await achievements.json();
  const profileAfterJson = await profileAfter.json();

  console.log('profile:', profile.status, profileJson.data?.totalXp, 'level:', profileJson.data?.level);
  console.log('achievements:', achievements.status, achievementsJson.data?.achievements?.length);
  console.log('leaderboard:', leaderboard.status);
  console.log('recommendations:', recommendations.status, (await recommendations.json()).data?.recommendedModule);
  console.log('submit xp:', submit.status);
  console.log('profile after:', profileAfter.status, profileAfterJson.data?.totalXp, 'streak:', profileAfterJson.data?.currentStreak);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
