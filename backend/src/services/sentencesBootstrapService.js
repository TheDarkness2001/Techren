const Language = require('../models/Language');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');
const Sentence = require('../models/Sentence');
const ExamGroup = require('../models/ExamGroup');

const SAMPLE_SENTENCES = [
  { english: 'I am a student.', uzbek: "Men talabaman." },
  { english: 'She goes to school every day.', uzbek: 'U har kuni maktabga boradi.' },
  { english: 'The book is on the table.', uzbek: 'Kitob stol ustida.' },
  { english: 'We like learning English.', uzbek: "Biz ingliz tilini o'rganishni yaxshi ko'ramiz." },
  { english: 'He reads a book in the morning.', uzbek: 'U ertalab kitob o\'qiydi.' },
];

const ensureSentencesDemoContent = async () => {
  const exists = await Language.exists({ moduleType: 'sentences', name: 'English' });
  if (exists) return;

  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  if (!group) return;

  const language = await Language.create({ name: 'English', moduleType: 'sentences' });
  const level = await Level.create({
    name: 'Level 1',
    languageId: language._id,
    moduleType: 'sentences',
    practiceUnlockedFor: [group._id],
    minPassScore: 70,
  });

  const lesson = await Lesson.create({
    name: 'Class 1',
    levelId: level._id,
    order: 1,
    type: 'sentences',
    examUnlockedFor: [group._id],
    directionMode: 'mixed',
    maxWords: 20,
  });

  for (const item of SAMPLE_SENTENCES) {
    await Sentence.create({ ...item, lessonId: lesson._id });
  }
};

module.exports = { ensureSentencesDemoContent };
