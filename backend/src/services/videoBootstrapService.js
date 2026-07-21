const Language = require('../models/Language');
const Level = require('../models/Level');
const VideoLesson = require('../models/VideoLesson');
const TopicTest = require('../models/TopicTest');
const ExamGroup = require('../models/ExamGroup');

const DEMO_VIDEO_URL = 'https://www.youtube.com/watch?v=Vv2M7L4uBzs';

const ensureVideoDemoContent = async () => {
  const exists = await VideoLesson.exists({ title: 'English Greetings' });
  if (exists) return;

  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  const language = await Language.findOne({ moduleType: 'words', name: 'English' });
  const level = language ? await Level.findOne({ languageId: language._id, moduleType: 'words', name: 'Level 1' }) : null;
  if (!group || !language || !level) return;

  const video = await VideoLesson.create({
    title: 'English Greetings',
    description: 'Learn basic English greetings and introductions.',
    youtubeUrl: DEMO_VIDEO_URL,
    languageId: language._id,
    levelId: level._id,
    topic: 'Greetings',
    difficulty: 'beginner',
    requireWatchPercent: 70,
    watchUnlockedFor: [group._id],
  });

  await TopicTest.create({
    videoLessonId: video._id,
    title: 'Greetings Quiz',
    practiceEnabled: true,
    examEnabled: true,
    timerSeconds: 300,
    passingScore: 70,
    questions: [
      {
        type: 'multiple-choice',
        question: 'What is a common English greeting?',
        options: ['Goodbye', 'Hello', 'Thanks', 'Sorry'],
        correctAnswer: 'Hello',
        explanation: '"Hello" is a standard greeting.',
        points: 1,
      },
      {
        type: 'true-false',
        question: '"Good morning" is used to greet someone in the morning.',
        options: ['true', 'false'],
        correctAnswer: 'true',
        explanation: 'Good morning is a time-specific greeting.',
        points: 1,
      },
      {
        type: 'fill-blank',
        question: 'Complete: How ___ you?',
        options: [],
        correctAnswer: ['are'],
        explanation: 'The phrase is "How are you?"',
        points: 1,
      },
    ],
  });
};

module.exports = { ensureVideoDemoContent };
