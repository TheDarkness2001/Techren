/**
 * Unit checks for Words practice helpers (no DB).
 * Run: node scripts/test-words-practice.js
 */
const assert = require('assert');
const { scrambleWord, maskWord } = require('../src/utils/wordsPracticeFormat');
const { checkVocabAnswer } = require('../src/utils/vocabAnswerChecker');

const PRACTICE_MODES = [
  'classic',
  'timeAttack',
  'streak',
  'wordRush',
  'multipleChoice',
  'trueFalse',
  'missingLetters',
  'scramble',
  'memory',
];

assert.deepStrictEqual(PRACTICE_MODES.length, 9);

const scrambled = scrambleWord('hello').replace(/ /g, '');
assert.strictEqual(scrambled.length, 5);
assert.strictEqual([...scrambled].sort().join(''), 'ehllo');

const masked = maskWord('hello');
assert.ok(masked.includes('_'));
assert.ok(masked.replace(/ /g, '').length === 5);

const formCheck = checkVocabAnswer(
  { english: 'go, went, gone', uzbek: 'bormoq' },
  { answer: 'went', direction: 'form', expectedForm: 'went' }
);
assert.strictEqual(formCheck.isCorrect, true);

const wrongForm = checkVocabAnswer(
  { english: 'hello', uzbek: 'salom' },
  { answer: 'hallo', direction: 'form', expectedForm: 'hello' }
);
assert.strictEqual(wrongForm.isCorrect, false);

console.log('test-words-practice: all assertions passed');
