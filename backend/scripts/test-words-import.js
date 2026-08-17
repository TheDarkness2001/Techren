/**
 * Unit checks for Words import + answer checking (no DB).
 * Run: node scripts/test-words-import.js
 */
const assert = require('assert');
const { parsePairsFromText, parseCsvPairs } = require('../src/utils/importParser');
const { parseCsv } = require('../src/utils/csvParser');
const { canonicalizeVocabPair, isSameVocabItem, splitVocabList } = require('../src/utils/vocabList');
const { checkVocabAnswer } = require('../src/utils/vocabAnswerChecker');

const word = (english, uzbek) => ({ english, uzbek });

// Test 1: hello | salom
{
  const parsed = parsePairsFromText('hello | salom');
  assert.strictEqual(parsed.pairCount, 1, 'test1 pair count');
  assert.deepStrictEqual(parsed.pairs[0].englishForms, ['hello']);
  assert.deepStrictEqual(parsed.pairs[0].uzbekMeanings, ['salom']);
}

// Test 2: go, went, gone | bormoq, ketmoq
{
  const parsed = parsePairsFromText('go, went, gone | bormoq, ketmoq');
  assert.strictEqual(parsed.pairCount, 1, 'test2 pair count');
  assert.deepStrictEqual(parsed.pairs[0].englishForms, ['go', 'went', 'gone']);
  assert.deepStrictEqual(parsed.pairs[0].uzbekMeanings, ['bormoq', 'ketmoq']);
}

// Test 3: beautiful | chiroyli, go'zal, latofatli
{
  const parsed = parsePairsFromText("beautiful | chiroyli, go'zal, latofatli");
  assert.strictEqual(parsed.pairCount, 1, 'test3 pair count');
  assert.strictEqual(parsed.pairs[0].uzbekMeanings.length, 3, 'test3 meanings');
  assert.ok(parsed.pairs[0].uzbek.includes("go'zal"));
}

// Test 4: 20-row file stays 20 items even with extra translations
{
  const lines = [];
  for (let i = 1; i <= 18; i += 1) lines.push(`word${i} | meaning${i}`);
  lines.push('go, went, gone | bormoq, ketmoq');
  lines.push("beautiful | chiroyli, go'zal, latofatli");
  const parsed = parsePairsFromText(lines.join('\n'));
  assert.strictEqual(parsed.pairCount, 20, `test4 expected 20 items, got ${parsed.pairCount}`);
}

// Test 5: quoted CSV commas stay in one item
{
  const csv = `"English","Uzbek"\n"go, went, gone","bormoq, ketmoq"`;
  const rows = parseCsv(csv);
  assert.strictEqual(rows[1][0], 'go, went, gone');
  assert.strictEqual(rows[1][1], 'bormoq, ketmoq');
  const parsed = parseCsvPairs(csv);
  assert.strictEqual(parsed.pairCount, 1, 'test5 pair count');
  assert.strictEqual(parsed.pairs[0].englishForms.length, 3);
  assert.strictEqual(parsed.pairs[0].uzbekMeanings.length, 2);
}

// Naive split would have created 5 fields — parser must not
{
  const csv = `"go, went, gone","bormoq, ketmoq"`;
  const naive = csv.split(',');
  assert.ok(naive.length > 2, 'sanity: naive split is wrong');
  const parsed = parseCsvPairs(csv);
  assert.strictEqual(parsed.pairCount, 1);
}

// Test 6: duplicate hello / HELLO
{
  const parsed = parsePairsFromText('hello | salom\nHELLO | salom');
  assert.strictEqual(parsed.pairCount, 1, 'test6 keeps one item');
  assert.ok(parsed.duplicateCount >= 1, 'test6 duplicate detected');
}

// Unquoted 2-column CSV with header
{
  const parsed = parsePairsFromText('English,Uzbek\nhello,salom\nbeautiful,"chiroyli, go\'zal"');
  assert.strictEqual(parsed.pairCount, 2, `csv header pairs, got ${parsed.pairCount}`);
  const beautiful = parsed.pairs.find((p) => p.english === 'beautiful');
  assert.ok(beautiful);
  assert.strictEqual(beautiful.uzbekMeanings.length, 2);
}

// Canonicalize trims, dedupes, preserves Uzbek apostrophe
{
  const canonical = canonicalizeVocabPair('  Hello  ', " bormoq , Bormoq , go'zal ");
  assert.deepStrictEqual(canonical.englishForms, ['Hello']);
  assert.deepStrictEqual(canonical.uzbekMeanings, ['bormoq', "go'zal"]);
  assert.ok(isSameVocabItem({ english: 'hello' }, { english: 'HELLO' }));
}

// Tests 7-10: answer checking
{
  const item = word('go, went, gone', 'bormoq, ketmoq');
  assert.strictEqual(checkVocabAnswer(item, { answer: 'ketmoq', direction: 'en-to-uz' }).isCorrect, true, 'test7');
  assert.strictEqual(checkVocabAnswer(item, { answer: 'bormoq', direction: 'en-to-uz' }).isCorrect, true, 'test8');
  assert.strictEqual(checkVocabAnswer(item, { answer: 'bormoq, ketmoq', direction: 'en-to-uz' }).isCorrect, true, 'test9');
  assert.strictEqual(checkVocabAnswer(item, { answer: 'KETMOQ', direction: 'en-to-uz' }).isCorrect, true, 'test10');
  assert.strictEqual(checkVocabAnswer(item, { answer: 'bormoq, kitob', direction: 'en-to-uz' }).isCorrect, false);
  assert.strictEqual(checkVocabAnswer(item, { answer: 'went', direction: 'uz-to-en' }).isCorrect, true);
  assert.strictEqual(checkVocabAnswer(item, { answer: 'GO', direction: 'uz-to-en' }).isCorrect, true);
}

assert.deepStrictEqual(splitVocabList('go, went, gone'), ['go', 'went', 'gone']);

console.log('test-words-import: all assertions passed');
