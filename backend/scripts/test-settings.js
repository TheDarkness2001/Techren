require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

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

  const founderLogin = await login(base, 'founder@techren.uz', 'Founder123!');
  const headers = {
    Authorization: `Bearer ${founderLogin.json.data.accessToken}`,
    'Content-Type': 'application/json',
  };

  const getRes = await fetch(`${base}/settings`, { headers });
  const getJson = await getRes.json();

  const updateRes = await fetch(`${base}/settings`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({
      featureFlags: {
        walletEnabled: true,
        gamificationEnabled: true,
        parentPortalEnabled: true,
      },
    }),
  });
  const updateJson = await updateRes.json();

  const featureRes = await fetch(`${base}/settings/features/walletEnabled`, { headers });
  const featureJson = await featureRes.json();

  const permsRes = await fetch(`${base}/settings/permissions`, { headers });
  const permsJson = await permsRes.json();

  console.log('founder login:', founderLogin.status);
  console.log('get settings:', getRes.status, getJson.data?.featureFlags?.walletEnabled);
  console.log('update flags:', updateRes.status, updateJson.data?.featureFlags?.parentPortalEnabled);
  console.log('feature check:', featureRes.status, featureJson.data?.enabled);
  console.log('permissions:', permsRes.status, Object.keys(permsJson.data ?? {}).join(','));

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
