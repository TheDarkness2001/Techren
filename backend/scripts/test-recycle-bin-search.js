require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const recycleBinService = require('../src/services/recycleBinService');
const RecycleBin = require('../src/models/RecycleBin');

async function run() {
  await connectDB();

  const sample = await RecycleBin.findOne({
    purgedAt: null,
    restoredAt: null,
  }).select('label collectionName moduleType');

  if (!sample) {
    console.log('skip recycle bin search: no active entries in database');
    await disconnectDB();
    return;
  }

  const term = sample.label?.split(/[\s/]/).find((part) => part.length > 1)
    || sample.moduleType
    || sample.collectionName;
  const all = await recycleBinService.listEntries({ page: 1, limit: 20 });
  const filtered = await recycleBinService.listEntries({ page: 1, limit: 20, search: term });

  console.log('recycle bin search term:', term);
  console.log('recycle bin list total:', all.meta.total, 'filtered:', filtered.meta.total);
  if (filtered.meta.total > all.meta.total) {
    throw new Error('recycle bin search returned more results than unfiltered list');
  }
  if (filtered.meta.total === 0) {
    throw new Error('recycle bin search returned zero matches for known term');
  }

  console.log('recycle bin search OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
