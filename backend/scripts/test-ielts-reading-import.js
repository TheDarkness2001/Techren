/**
 * Unit checks for IELTS reading generator → TechRen mapping (no DB).
 * Run: node backend/scripts/test-ielts-reading-import.js
 */
const assert = require('assert');
const {
  isReadingGeneratorPayload,
  mapReadingGeneratorToExam,
  mapQuestionType,
} = require('../src/services/ieltsReadingGeneratorImport');

const sample = {
  title: 'The Future of Artificial Intelligence',
  module: 'Academic',
  duration: 60,
  totalQuestions: 6,
  passages: [
    {
      title: 'AI in Healthcare',
      topic: 'Medicine',
      difficulty: 'Easy',
      content: Array(80).fill('word').join(' '),
      questions: [
        {
          number: 1,
          type: 'TRUE_FALSE_NOT_GIVEN',
          question: 'AI can diagnose some conditions.',
          answer: 'TRUE',
          explanation: 'Stated in paragraph 1.',
        },
        {
          number: 2,
          type: 'MULTIPLE_CHOICE',
          question: 'Which field benefits most?',
          options: ['Farming', 'Healthcare', 'Mining', 'Sports'],
          answer: 'Healthcare',
          explanation: 'Passage focus.',
        },
      ],
    },
    {
      title: 'Climate Models',
      topic: 'Climate Change',
      difficulty: 'Medium',
      content: Array(90).fill('word').join(' '),
      questions: [
        {
          number: 3,
          type: 'YES_NO_NOT_GIVEN',
          question: 'The author argues models are perfect.',
          answer: 'NO',
          explanation: 'Author notes limits.',
        },
        {
          number: 4,
          type: 'SENTENCE_COMPLETION',
          question: 'Models need more ____ data.',
          answer: 'ocean',
          explanation: 'Paragraph 2.',
        },
      ],
    },
    {
      title: 'Ancient Trade Routes',
      topic: 'History',
      difficulty: 'Hard',
      content: Array(100).fill('word').join(' '),
      questions: [
        {
          number: 5,
          type: 'MATCHING_HEADINGS',
          question: 'Choose the correct heading for paragraph A.',
          options: ['Early markets', 'Naval power', 'Tax reforms', 'Desert climate'],
          answer: 'Early markets',
          explanation: 'Paragraph A.',
        },
        {
          number: 6,
          type: 'SHORT_ANSWER',
          question: 'Name one traded commodity.',
          answer: 'silk',
          explanation: 'Mentioned explicitly.',
        },
      ],
    },
  ],
};

assert.strictEqual(isReadingGeneratorPayload(sample), true);
assert.strictEqual(mapQuestionType('TRUE_FALSE_NOT_GIVEN').type, 'tfng');
assert.strictEqual(mapQuestionType('True False Not Given').type, 'tfng');
assert.strictEqual(mapQuestionType('NOTES_COMPLETION').type, 'form_completion');
assert.strictEqual(mapQuestionType('FLOW_CHART_COMPLETION').layout, 'flow_chart');

const mapped = mapReadingGeneratorToExam(sample, { subjectId: 'subj1', strict: true });
assert.strictEqual(mapped.mode, 'reading');
assert.strictEqual(mapped.trainingType, 'academic');
assert.strictEqual(mapped.timers.readingMinutes, 60);
assert.strictEqual(mapped.sections.length, 3);
assert.strictEqual(mapped.sections.reduce((n, s) => n + s.questions.length, 0), 6);
assert.strictEqual(mapped.sections[0].questions[0].type, 'tfng');
assert.strictEqual(mapped.sections[0].questions[1].type, 'mcq');
assert.ok(mapped.sections[0].questions[0].acceptedAnswers.primary === 'TRUE');

const single = {
  title: 'The Rise of Urban Farming',
  difficulty: 'Medium',
  estimatedBand: 6.5,
  readingTimeMinutes: 8,
  wordCount: 420,
  module: 'Academic',
  passage: 'Urban farming is growing in cities worldwide. '.repeat(20),
  questions: Array.from({ length: 13 }, (_, i) => ({
    number: i + 1,
    type: i % 3 === 0 ? 'MULTIPLE_CHOICE' : i % 3 === 1 ? 'TRUE_FALSE_NOT_GIVEN' : 'SHORT_ANSWER',
    question: `Question ${i + 1}?`,
    options: i % 3 === 0 ? ['A', 'B', 'C', 'D'] : i % 3 === 1 ? ['True', 'False', 'Not Given'] : undefined,
    answer: i % 3 === 0 ? 'A' : i % 3 === 1 ? 'True' : 'rooftops',
    explanation: 'Based on the passage.',
  })),
};
assert.strictEqual(isReadingGeneratorPayload(single), true);
const mappedSingle = mapReadingGeneratorToExam(single, { subjectId: 'subj1', strict: true });
assert.strictEqual(mappedSingle.sections.length, 1);
assert.strictEqual(mappedSingle.sections[0].questions.length, 13);
assert.ok(mappedSingle.sections[0].passage.includes('Urban farming'));

let threw = false;
try {
  mapReadingGeneratorToExam({ ...sample, passages: sample.passages.slice(0, 2) }, { strict: true });
} catch (e) {
  threw = true;
  assert.strictEqual(e.statusCode, 400);
}
assert.ok(threw, 'should reject non-3 passages for full exams');

console.log('ielts reading import mapping: OK');
