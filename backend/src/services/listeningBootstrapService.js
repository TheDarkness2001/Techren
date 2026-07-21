const Language = require('../models/Language');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');
const ListeningExercise = require('../models/ListeningExercise');
const ExamGroup = require('../models/ExamGroup');

const DEMO_AUDIO = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

const SAMPLE_EXERCISES = [
  {
    title: 'Morning Greeting',
    script: 'Good morning. How are you today? I am fine, thank you.',
  },
  {
    title: 'At School',
    script: 'The students are in the classroom. The teacher is reading a book.',
  },
];

const ensureListeningDemoContent = async () => {
  const exists = await Language.exists({ moduleType: 'listening', name: 'English' });
  if (exists) return;

  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  if (!group) return;

  const language = await Language.create({ name: 'English', moduleType: 'listening' });
  const level = await Level.create({
    name: 'Level 1',
    languageId: language._id,
    moduleType: 'listening',
    practiceUnlockedFor: [group._id],
  });

  const lesson = await Lesson.create({
    name: 'Exercises',
    levelId: level._id,
    order: 1,
    type: 'listening',
  });

  let order = 1;
  for (const item of SAMPLE_EXERCISES) {
    await ListeningExercise.create({
      title: item.title,
      script: item.script,
      audioFile: DEMO_AUDIO,
      lessonId: lesson._id,
      order: order++,
    });
  }
};

module.exports = { ensureListeningDemoContent };
