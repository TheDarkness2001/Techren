const Language = require('../models/Language');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');
const Word = require('../models/Word');
const ExamGroup = require('../models/ExamGroup');
const StudentVocabProgress = require('../models/StudentVocabProgress');

const SAMPLE_WORDS = [
  { english: 'hello', uzbek: 'salom' },
  { english: 'book', uzbek: 'kitob' },
  { english: 'water', uzbek: 'suv' },
  { english: 'school', uzbek: 'maktab' },
  { english: 'teacher', uzbek: "o'qituvchi" },
  { english: 'student', uzbek: 'talaba, o\'quvchi' },
  { english: 'go, went, gone', uzbek: 'bormoq' },
  { english: 'good', uzbek: 'yaxshi' },
];

const ensureWordsDemoContent = async () => {
  const exists = await Language.exists({ moduleType: 'words', name: 'English' });
  if (exists) return;

  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  if (!group) return;

  const language = await Language.create({ name: 'English', moduleType: 'words' });
  const level = await Level.create({
    name: 'Level 1',
    languageId: language._id,
    moduleType: 'words',
    practiceUnlockedFor: [group._id],
    wordsPerClass: 20,
    minPassScore: 70,
  });

  const lesson = await Lesson.create({
    name: 'Class 1',
    levelId: level._id,
    order: 1,
    type: 'words',
    examUnlockedFor: [group._id],
    directionMode: 'mixed',
    maxWords: 20,
  });

  const wordDocs = [];
  for (const item of SAMPLE_WORDS) {
    const word = await Word.create({ ...item, lessonId: lesson._id });
    wordDocs.push(word._id);
  }
  lesson.wordIds = wordDocs;
  await lesson.save();

  const student = group.students?.[0];
  if (student) {
    await StudentVocabProgress.findOneAndUpdate(
      { studentId: student, lessonId: lesson._id },
      { status: 'available', unlockedAt: new Date() },
      { upsert: true }
    );
  }
};

module.exports = { ensureWordsDemoContent };
