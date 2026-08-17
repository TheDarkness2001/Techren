/**
 * Unit checks for Words/Sentences 3-try reveal (no DB).
 * Run: node scripts/test-practice-tries.js
 */
const assert = require('assert');
const { MAX_ANSWER_TRIES: wordTries } = require('../src/services/wordsPracticeService');
const { MAX_ANSWER_TRIES: sentenceTries } = require('../src/services/sentenceService');

assert.strictEqual(wordTries, 3);
assert.strictEqual(sentenceTries, 3);

const resolveAfter = (tries, isCorrect, allowRetry = true) =>
  Boolean(isCorrect || !allowRetry || tries >= 3);

assert.strictEqual(resolveAfter(1, false), false);
assert.strictEqual(resolveAfter(2, false), false);
assert.strictEqual(resolveAfter(3, false), true);
assert.strictEqual(resolveAfter(1, true), true);
assert.strictEqual(resolveAfter(2, true), true);
assert.strictEqual(resolveAfter(1, false, false), true);

const publicAnswer = (resolved, answer) => (resolved ? answer : '');
assert.strictEqual(publicAnswer(false, 'olma'), '');
assert.strictEqual(publicAnswer(true, 'olma'), 'olma');

console.log('ok');
