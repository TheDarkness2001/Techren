/**
 * Sentence Answer Validator
 * Performs word-level diff and grammar analysis between correct answer and user answer.
 */

const { normalizeText } = require('./textNormalizer');

const ARTICLES = new Set(['a', 'an', 'the']);
const PUNCTUATION_REGEX = /[.,!?;:"']$/;

const PRONOUN_GROUPS = [
  new Set(['he', 'she']),
  new Set(['his', 'her']),
  new Set(['him', 'her']),
];

function arePronounEquivalents(a, b) {
  for (const group of PRONOUN_GROUPS) {
    if (group.has(a) && group.has(b)) return true;
  }
  return false;
}

function tokenize(text) {
  return normalizeText(text)
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean);
}

function normalizeWord(word) {
  return word.replace(/[.,!?;:"']$/, '');
}

function stripNonPeriodPunctuation(word) {
  return word.replace(/[,;:!?"']$/, '');
}

function hasPunctuationDiff(wordA, wordB) {
  const pA = wordA.match(/[.,!?;:"']$/)?.[0] || '';
  const pB = wordB.match(/[.,!?;:"']$/)?.[0] || '';
  return pA !== pB;
}

function hasPeriodDiff(wordA, wordB) {
  const pA = wordA.endsWith('.') ? '.' : '';
  const pB = wordB.endsWith('.') ? '.' : '';
  return pA !== pB;
}

function computeDiff(correctTokens, userTokens) {
  const diff = [];
  let i = 0;
  let j = 0;

  while (i < correctTokens.length || j < userTokens.length) {
    const c = correctTokens[i];
    const u = userTokens[j];

    if (i >= correctTokens.length) {
      diff.push({ type: 'extra', word: u });
      j += 1;
      continue;
    }
    if (j >= userTokens.length) {
      diff.push({ type: 'missing', word: c });
      i += 1;
      continue;
    }

    const cStripped = stripNonPeriodPunctuation(c);
    const uStripped = stripNonPeriodPunctuation(u);

    if (c === u) {
      diff.push({ type: 'correct', word: c });
      i += 1;
      j += 1;
    } else if (cStripped === uStripped) {
      diff.push({ type: 'correct', word: c });
      i += 1;
      j += 1;
    } else if (arePronounEquivalents(normalizeWord(c), normalizeWord(u))) {
      diff.push({ type: 'correct', word: c });
      i += 1;
      j += 1;
    } else if (normalizeWord(c) === normalizeWord(u)) {
      if (hasPeriodDiff(c, u)) {
        diff.push({ type: 'missingPeriod', expected: c, got: u });
      } else {
        diff.push({ type: 'punctuation', expected: c, got: u });
      }
      i += 1;
      j += 1;
    } else {
      let foundMatch = false;
      for (let lookAhead = 1; lookAhead <= 2 && !foundMatch; lookAhead += 1) {
        if (i + lookAhead < correctTokens.length && correctTokens[i + lookAhead] === u) {
          for (let k = 0; k < lookAhead; k += 1) {
            diff.push({ type: 'missing', word: correctTokens[i + k] });
          }
          i += lookAhead;
          foundMatch = true;
        } else if (j + lookAhead < userTokens.length && correctTokens[i] === userTokens[j + lookAhead]) {
          for (let k = 0; k < lookAhead; k += 1) {
            diff.push({ type: 'extra', word: userTokens[j + k] });
          }
          j += lookAhead;
          foundMatch = true;
        }
      }

      if (!foundMatch) {
        diff.push({ type: 'wrong', expected: c, got: u });
        i += 1;
        j += 1;
      }
    }
  }

  return diff;
}

function detectCategories(diff) {
  const categories = new Set();

  for (const item of diff) {
    if (item.type === 'missing') {
      const w = normalizeWord(item.word);
      if (ARTICLES.has(w)) categories.add('missingArticle');
      else categories.add('missingWords');
    } else if (item.type === 'extra') {
      const w = normalizeWord(item.word);
      if (ARTICLES.has(w)) categories.add('wrongArticle');
      else categories.add('extraWords');
    } else if (item.type === 'wrong') {
      const exp = normalizeWord(item.expected);
      const got = normalizeWord(item.got);
      if (ARTICLES.has(exp) && ARTICLES.has(got)) categories.add('wrongArticle');
      else categories.add('wrongWord');
    } else if (item.type === 'punctuation') {
      categories.add('missingPunctuation');
    } else if (item.type === 'missingPeriod') {
      categories.add('missingPeriod');
    }
  }

  const allExpected = diff
    .filter((d) => d.type === 'correct' || d.type === 'missing' || d.type === 'wrong')
    .map((d) => normalizeWord(d.word || d.expected))
    .sort();
  const allGot = diff
    .filter((d) => d.type === 'correct' || d.type === 'extra' || d.type === 'wrong')
    .map((d) => normalizeWord(d.word || d.got))
    .sort();

  const hasSameWords = JSON.stringify(allExpected) === JSON.stringify(allGot);
  const hasWrongOrMissing = diff.some((d) => d.type === 'wrong' || d.type === 'missing' || d.type === 'extra');
  if (hasSameWords && hasWrongOrMissing) {
    categories.add('wrongWordOrder');
  }

  return Array.from(categories);
}

function computeSimilarity(correctTokens, userTokens) {
  const correctSet = new Set(correctTokens.map(normalizeWord));
  const userSet = new Set(userTokens.map(normalizeWord));
  const intersection = new Set([...correctSet].filter((x) => userSet.has(x)));
  const union = new Set([...correctSet, ...userSet]);
  return union.size > 0 ? Math.round((intersection.size / union.size) * 100) : 0;
}

function analyzeSentenceAnswer(correct, userAnswer) {
  const correctTrimmed = normalizeText(correct);
  const userTrimmed = normalizeText(userAnswer);

  const correctTokens = tokenize(correctTrimmed);
  const userTokens = tokenize(userTrimmed);

  const diff = computeDiff(correctTokens, userTokens);
  const categories = detectCategories(diff);
  const similarityScore = computeSimilarity(correctTokens, userTokens);

  const hasRealErrors = diff.some((d) => ['wrong', 'missing', 'extra', 'missingPeriod'].includes(d.type));
  const isCorrect = !hasRealErrors;

  return {
    isCorrect,
    diff,
    categories,
    similarityScore,
    correctTokens,
    userTokens,
  };
}

module.exports = { analyzeSentenceAnswer };
