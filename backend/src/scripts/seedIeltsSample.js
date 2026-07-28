/**
 * Seed one Academic sample full mock under a subject.
 * Usage: node src/scripts/seedIeltsSample.js <subjectId>
 */
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const mongoose = require('mongoose');
const config = require('../config');
const IeltsExam = require('../models/IeltsExam');
const IeltsSection = require('../models/IeltsSection');
const IeltsQuestion = require('../models/IeltsQuestion');
const Subject = require('../models/Subject');

const seed = async (subjectId) => {
  const subject = await Subject.findById(subjectId);
  if (!subject) throw new Error(`Subject ${subjectId} not found`);

  // Ensure ielts module is enabled on the subject
  const hasIelts = (subject.modules || []).some((m) => m.key === 'ielts');
  if (!hasIelts) {
    subject.modules = [
      ...(subject.modules || []),
      { key: 'ielts', label: 'IELTS Preparation', category: 'learning', icon: 'school', audience: 'all', enabled: true },
    ];
    await subject.save();
  }

  const existing = await IeltsExam.findOne({ subjectId, title: 'Academic Sample Mock 1' });
  if (existing) {
    console.log('Sample exam already exists:', existing._id.toString());
    return existing._id.toString();
  }

  const exam = await IeltsExam.create({
    subjectId,
    title: 'Academic Sample Mock 1',
    description: 'Short practice full mock for TechRen IELTS Phase 1 QA.',
    mode: 'full',
    trainingType: 'academic',
    difficulty: 'official',
    timers: { listeningMinutes: 10, readingMinutes: 15, writingMinutes: 20 },
    published: true,
  });

  const listening = await IeltsSection.create({
    examId: exam._id,
    skill: 'listening',
    order: 0,
    title: 'Listening Part 1',
    instructions: 'Listen carefully. Audio plays once in the full product; for this sample, answer from the prompts.',
  });

  await IeltsQuestion.insertMany([
    {
      sectionId: listening._id,
      examId: exam._id,
      order: 0,
      number: 1,
      type: 'mcq',
      prompt: 'What time does the library open on Monday?',
      options: ['8:00', '9:00', '10:00', '11:00'],
      answers: ['9:00'],
      points: 1,
    },
    {
      sectionId: listening._id,
      examId: exam._id,
      order: 1,
      number: 2,
      type: 'short_answer',
      prompt: 'Write the surname of the receptionist (one word).',
      answers: ['Parker', 'parker'],
      points: 1,
    },
    {
      sectionId: listening._id,
      examId: exam._id,
      order: 2,
      number: 3,
      type: 'form_completion',
      prompt: 'Membership fee: £______',
      answers: ['25', '25.00'],
      points: 1,
    },
  ]);

  const reading = await IeltsSection.create({
    examId: exam._id,
    skill: 'reading',
    order: 1,
    title: 'Reading Passage 1',
    instructions: 'Read the passage and answer the questions.',
    passage:
      'Urban beekeeping has grown rapidly in the last decade. City councils in several European capitals now issue permits for rooftop hives. Researchers found that urban honey often contains fewer pesticides than rural samples collected near intensive farms. However, critics warn that dense hive placement can stress local wild pollinators.',
  });

  await IeltsQuestion.insertMany([
    {
      sectionId: reading._id,
      examId: exam._id,
      order: 0,
      number: 1,
      type: 'tfng',
      prompt: 'Urban honey always contains more pesticides than rural honey.',
      options: ['True', 'False', 'Not Given'],
      answers: ['False'],
      points: 1,
    },
    {
      sectionId: reading._id,
      examId: exam._id,
      order: 1,
      number: 2,
      type: 'tfng',
      prompt: 'Some European city councils allow rooftop hives.',
      options: ['True', 'False', 'Not Given'],
      answers: ['True'],
      points: 1,
    },
    {
      sectionId: reading._id,
      examId: exam._id,
      order: 2,
      number: 3,
      type: 'mcq',
      prompt: 'What do critics worry about?',
      options: [
        'Higher honey prices',
        'Stress on wild pollinators',
        'Lack of rooftop space',
        'Tourist complaints',
      ],
      answers: ['Stress on wild pollinators'],
      points: 1,
    },
  ]);

  const writing1 = await IeltsSection.create({
    examId: exam._id,
    skill: 'writing',
    order: 2,
    title: 'Writing Task 1',
    instructions: 'Write at least 150 words.',
    writingTask: 'task1',
    minWords: 150,
    prompt:
      'The chart below shows the percentage of households with internet access in three countries from 2010 to 2020. Summarise the information by selecting and reporting the main features, and make comparisons where relevant. (Describe an imagined rising trend if no chart image is attached.)',
  });

  const writing2 = await IeltsSection.create({
    examId: exam._id,
    skill: 'writing',
    order: 3,
    title: 'Writing Task 2',
    instructions: 'Write at least 250 words.',
    writingTask: 'task2',
    minWords: 250,
    prompt:
      'Some people believe that unpaid community service should be a compulsory part of high-school education. To what extent do you agree or disagree? Give reasons for your answer and include relevant examples from your own knowledge or experience.',
  });

  await IeltsQuestion.insertMany([
    {
      sectionId: writing1._id,
      examId: exam._id,
      order: 0,
      number: 1,
      type: 'task1',
      prompt: writing1.prompt,
      answers: [],
      points: 0,
    },
    {
      sectionId: writing2._id,
      examId: exam._id,
      order: 0,
      number: 2,
      type: 'task2',
      prompt: writing2.prompt,
      answers: [],
      points: 0,
    },
  ]);

  console.log('Seeded IELTS sample exam:', exam._id.toString());
  return exam._id.toString();
};

const main = async () => {
  const subjectId = process.argv[2];
  if (!subjectId) {
    console.error('Usage: node src/scripts/seedIeltsSample.js <subjectId>');
    process.exit(1);
  }
  await mongoose.connect(config.mongoUri);
  try {
    await seed(subjectId);
  } finally {
    await mongoose.disconnect();
  }
};

if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = { seed };
