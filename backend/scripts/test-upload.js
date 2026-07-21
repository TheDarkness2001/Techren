require('dotenv').config();
const fs = require('fs');
const path = require('path');

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Lesson = require('../src/models/Lesson');

async function login(base, email, password, userType = 'teacher') {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType }),
  });
  return { status: res.status, json: await res.json() };
}

async function uploadFile(base, token, endpoint, fieldName, filePath, mimeType) {
  const buffer = fs.readFileSync(filePath);
  const form = new FormData();
  form.append(fieldName, new Blob([buffer], { type: mimeType }), path.basename(filePath));

  const res = await fetch(`${base}${endpoint}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });

  const json = await res.json();
  return { status: res.status, json };
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const teacherLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const token = teacherLogin.json.data.accessToken;

  const lesson = await Lesson.findOne({ type: 'words' }).sort({ order: 1 });
  const sentenceLesson = await Lesson.findOne({ type: 'sentences' }).sort({ order: 1 });

  const fixturePath = path.join(__dirname, 'fixtures', 'sample-words.txt');
  const parseDocx = await uploadFile(base, token, '/upload/parse-docx', 'file', fixturePath, 'text/plain');

  const bulkWords = await fetch(`${base}/upload/bulk-import/words`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      lessonId: lesson._id.toString(),
      pairs: [
        { english: 'water', uzbek: 'suv' },
        { english: 'school', uzbek: 'maktab' },
      ],
    }),
  });

  const bulkSentences = sentenceLesson
    ? await fetch(`${base}/upload/bulk-import/sentences`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lessonId: sentenceLesson._id.toString(),
          pairs: [{ english: 'I am happy', uzbek: 'Men baxtliman' }],
        }),
      })
    : null;

  const imagePath = path.join(__dirname, 'fixtures', 'sample.png');
  if (!fs.existsSync(imagePath)) {
    fs.writeFileSync(imagePath, Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64'));
  }
  const imageUpload = await uploadFile(base, token, '/upload/image', 'image', imagePath, 'image/png');

  const audioPath = path.join(__dirname, 'fixtures', 'sample.mp3');
  if (!fs.existsSync(audioPath)) {
    fs.writeFileSync(audioPath, Buffer.from([0xff, 0xfb, 0x90, 0x00]));
  }
  const audioUpload = await uploadFile(base, token, '/upload/audio', 'audio', audioPath, 'audio/mpeg');

  const bulkWordsJson = await bulkWords.json();
  const bulkSentencesJson = bulkSentences ? await bulkSentences.json() : null;

  console.log('teacher login:', teacherLogin.status);
  console.log('parse-docx:', parseDocx.status, parseDocx.json.data?.pairCount);
  console.log('bulk words:', bulkWords.status, bulkWordsJson.data?.created);
  console.log('bulk sentences:', bulkSentences.status, bulkSentencesJson?.data?.created);
  console.log('image upload:', imageUpload.status, imageUpload.json.data?.url);
  console.log('audio upload:', audioUpload.status, audioUpload.json.data?.url);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
