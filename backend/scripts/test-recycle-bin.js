require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const RecycleBin = require('../src/models/RecycleBin');
const Word = require('../src/models/Word');

async function login(base, email, password) {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType: 'teacher' }),
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

  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const list = await fetch(`${base}/admin/recycle-bin?page=1&limit=20`, { headers: adminHeaders });
  const listJson = await list.json();
  const entryId = listJson.data?.[0]?.id;

  const snapshots = entryId
    ? await fetch(`${base}/admin/recycle-bin/${entryId}/snapshots`, { headers: adminHeaders })
    : null;
  const toggle = entryId
    ? await fetch(`${base}/admin/recycle-bin/${entryId}/toggle-important`, {
        method: 'PATCH',
        headers: adminHeaders,
      })
    : null;
  const restore = entryId
    ? await fetch(`${base}/admin/recycle-bin/${entryId}/restore`, {
        method: 'POST',
        headers: adminHeaders,
      })
    : null;

  const wordAfterRestore = await Word.findOne({ english: 'good' });
  const reDelete = wordAfterRestore
    ? await fetch(`${base}/homework/words/${wordAfterRestore._id}`, {
        method: 'DELETE',
        headers: adminHeaders,
      })
    : null;

  const listAfter = await fetch(`${base}/admin/recycle-bin?page=1&limit=20`, { headers: adminHeaders });
  const entryAfter = (await listAfter.json()).data?.[0];
  const purge = entryAfter?.id
    ? await fetch(`${base}/admin/recycle-bin/${entryAfter.id}/purge`, {
        method: 'POST',
        headers: adminHeaders,
      })
    : null;

  const finalList = await fetch(`${base}/admin/recycle-bin?page=1&limit=20`, { headers: adminHeaders });
  const finalJson = await finalList.json();

  console.log('list:', list.status, listJson.data?.length, 'meta:', listJson.meta?.page, listJson.meta?.totalPages);
  console.log('snapshots:', snapshots?.status);
  console.log('toggle important:', toggle?.status);
  console.log('restore:', restore?.status, (await restore?.json?.())?.data?.restoredCount);
  console.log('re-delete word:', reDelete?.status);
  console.log('purge:', purge?.status);
  console.log('final list:', finalList.status, finalJson.data?.length);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
