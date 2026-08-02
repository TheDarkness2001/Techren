/**
 * Smoke-test Typing Speed Challenge: start → finish → dashboard → leaderboard.
 * Usage: node scripts/smoke-typing.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const Subject = require('../src/models/Subject');
const Student = require('../src/models/Student');
const { ensureSubjectLearningFields, isItTypingSubject } = require('../src/utils/learningModules');
const typingService = require('../src/services/typingService');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/techren_edu';

async function main() {
  await mongoose.connect(MONGO_URI);
  console.log('Connected');

  const subjects = await Subject.find({}).lean();
  let it = subjects.find((s) => isItTypingSubject(s.name));
  if (!it) {
    throw new Error('No IT subject found. Create an IT subject first.');
  }

  const fields = ensureSubjectLearningFields(it);
  const hasTyping = fields.modules.some((m) => m.key === 'typing');
  console.log(`Subject: ${it.name} (${it._id}) typing module: ${hasTyping}`);
  if (!hasTyping) throw new Error('typing module missing after ensure');

  // Persist merge so API subjectHasTyping works from stored+ensure path
  await Subject.updateOne({ _id: it._id }, { $set: { modules: fields.modules } });

  const student = await Student.findOne({ status: { $ne: 'inactive' } });
  if (!student) throw new Error('No student found');
  console.log(`Student: ${student.name} (${student._id})`);

  const fakeReq = { userType: 'student', user: student };

  const started = await typingService.start(fakeReq, {
    subjectId: String(it._id),
    mode: 'programming',
    difficulty: 'medium',
    durationSec: 60,
  });
  console.log(`Start OK — prompt length ${started.prompt.text.length}, mode ${started.session.mode}`);

  const finished = await typingService.finish(fakeReq, {
    subjectId: String(it._id),
    mode: 'programming',
    difficulty: 'medium',
    durationSec: 60,
    wpm: 42,
    rawWpm: 48,
    accuracy: 96,
    correctChars: 210,
    incorrectChars: 8,
    totalChars: 218,
    mistakes: 8,
    wordsTyped: 40,
    correctWords: 38,
    wrongWords: 2,
    elapsedSec: 60,
    contentId: started.prompt.contentId,
  });
  console.log(
    `Finish OK — WPM ${finished.result.wpm}, XP +${finished.result.xpEarned}, level ${finished.level}`
  );

  const dash = await typingService.dashboard(fakeReq, { subjectId: String(it._id) });
  console.log(
    `Dashboard OK — best ${dash.bestWpm}, tests ${dash.testsCompleted}, rank ${dash.currentRank}`
  );

  const board = await typingService.leaderboard(fakeReq, { subjectId: String(it._id), period: 'all' });
  console.log(`Leaderboard OK — ${board.items.length} entries`);

  const daily = await typingService.daily(fakeReq, { subjectId: String(it._id) });
  console.log(`Daily OK — date ${daily.date}, completed ${daily.completed}`);

  console.log('SMOKE_PASS');
  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error('SMOKE_FAIL', err.message);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});
