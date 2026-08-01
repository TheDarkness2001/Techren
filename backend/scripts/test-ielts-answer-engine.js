/**
 * Unit checks for IELTS answer engine (no DB, no AI).
 * Run: node scripts/test-ielts-answer-engine.js
 */
const assert = require('assert');
const {
  normalizeAnswer,
  validateWordLimit,
  evaluateAnswer,
  matchSingleAnswer,
  resolveAcceptedConfig,
} = require('../src/services/ieltsAnswerEngine');
const { scoreObjectiveQuestions, rawToBand } = require('../src/services/ieltsScoringService');

const q = (overrides) => ({
  _id: 'q1',
  type: 'short_answer',
  points: 1,
  answers: ['museum'],
  metadata: {},
  ...overrides,
});

// Normalization
assert.strictEqual(normalizeAnswer('  Museum. '), 'museum');
assert.strictEqual(normalizeAnswer('"Museum"'), 'museum');
assert.strictEqual(normalizeAnswer('MUSEUM'), 'museum');
assert.ok(normalizeAnswer('colour') === 'colour');

// Capitals / punctuation variants match
assert.strictEqual(evaluateAnswer(q(), 'Museum').correct, true);
assert.strictEqual(evaluateAnswer(q(), 'museum.').correct, true);
assert.strictEqual(evaluateAnswer(q(), 'MUSEUM').correct, true);

// Spelling Br/Am
assert.strictEqual(
  evaluateAnswer(q({ answers: ['colour'] }), 'color').correct,
  true
);
assert.strictEqual(
  evaluateAnswer(q({ answers: ['organize'] }), 'organise').correct,
  true
);

// Numbers
assert.strictEqual(evaluateAnswer(q({ answers: ['10'] }), 'ten').correct, true);
assert.strictEqual(evaluateAnswer(q({ answers: ['twenty-one'] }), '21').correct, true);

// Word limit
assert.strictEqual(
  validateWordLimit('one two three', 'NO_MORE_THAN_TWO_WORDS').ok,
  false
);
assert.strictEqual(validateWordLimit('one two', 'NO_MORE_THAN_TWO_WORDS').ok, true);
assert.strictEqual(
  evaluateAnswer(
    q({ answers: ['red bus'], wordLimit: 'NO_MORE_THAN_TWO_WORDS' }),
    'big red bus'
  ).correct,
  false
);

// Alternatives / synonyms / rejected
assert.strictEqual(
  evaluateAnswer(
    q({
      answers: [],
      acceptedAnswers: {
        primary: 'hospital',
        alternatives: ['clinic'],
        synonyms: ['infirmary'],
        rejected: ['school'],
        explanation: 'Medical facility',
      },
      allowArticles: true,
    }),
    'the hospital'
  ).correct,
  true
);
assert.strictEqual(
  evaluateAnswer(
    q({
      acceptedAnswers: { primary: 'hospital', rejected: ['school'] },
      answers: ['hospital'],
    }),
    'school'
  ).correct,
  false
);

// Plurals
assert.strictEqual(
  evaluateAnswer(q({ answers: ['student'], allowPlurals: true }), 'students').correct,
  true
);

// Slash alternatives
assert.strictEqual(evaluateAnswer(q({ answers: ['UK/United Kingdom'] }), 'uk').correct, true);

// Multi-select
assert.strictEqual(
  evaluateAnswer(
    q({
      type: 'mcq',
      selectionMode: 'multiple',
      answers: ['A', 'C'],
    }),
    ['C', 'A']
  ).correct,
  true
);

// GT vs Academic band
assert.strictEqual(rawToBand(23, 40, 'academic'), 6.0);
assert.ok(rawToBand(18, 40, 'general') >= 5.0);

const scored = scoreObjectiveQuestions(
  [q({ _id: 'a' }), q({ _id: 'b', answers: ['library'] })],
  { a: 'museum', b: 'wrong' },
  { trainingType: 'academic' }
);
assert.strictEqual(scored.raw, 1);
assert.strictEqual(scored.max, 2);
assert.ok(scored.review[0].prompt !== undefined);
assert.ok(scored.review[0].type === 'short_answer');

const cfg = resolveAcceptedConfig(q({ answers: ['a', 'b'] }));
assert.deepStrictEqual(cfg.accepted, ['a', 'b']);

console.log('test-ielts-answer-engine: OK');
