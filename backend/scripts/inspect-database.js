require('dotenv').config();
const mongoose = require('mongoose');
const config = require('../src/config');
const { configureAtlasDns } = require('../src/config/database');

const SAMPLE_COLLECTIONS = [
  'branches',
  'teachers',
  'students',
  'parents',
  'subjects',
  'examgroups',
  'classschedules',
  'classes',
  'timetables',
  'attendances',
  'homeworkprogresses',
  'words',
  'sentences',
  'settings',
  'teacherearnings',
  'salarypayouts',
  'payments',
  'exams',
];

const run = async () => {
  const uri = config.mongoUri;
  const masked = uri.replace(/:([^:@/]+)@/, ':****@');

  console.log('Connecting to:', masked);
  console.log('Atlas URI:', config.isAtlasUri ? 'yes' : 'no');
  console.log('Seed demo on startup:', config.seedDemoData ? 'yes' : 'no');
  console.log('Memory fallback:', config.useMemoryFallback ? 'yes' : 'no');
  console.log('');

  configureAtlasDns();
  await mongoose.connect(uri);

  const db = mongoose.connection.db;
  const dbName = db.databaseName;
  const collections = await db.listCollections().toArray();
  const names = collections.map((c) => c.name).sort();

  console.log(`Database: ${dbName}`);
  console.log(`Collections (${names.length}):`);

  for (const name of names) {
    const count = await db.collection(name).countDocuments();
    const marker = SAMPLE_COLLECTIONS.includes(name) ? ' *' : '';
    console.log(`  - ${name}: ${count}${marker}`);
  }

  console.log('');
  console.log('Key collection samples:');

  for (const name of SAMPLE_COLLECTIONS) {
    if (!names.includes(name)) continue;
    const sample = await db.collection(name).findOne({}, { projection: { name: 1, email: 1, role: 1, title: 1 } });
    if (sample) {
      console.log(`  ${name}:`, JSON.stringify(sample));
    }
  }

  await mongoose.disconnect();
  console.log('\nConnection OK.');
};

run().catch((error) => {
  console.error('Database inspection failed:', error.message);
  if (config.isAtlasUri) {
    console.error('Tip: whitelist your IP in Atlas Network Access and verify MONGO_URI credentials.');
  }
  process.exit(1);
});
