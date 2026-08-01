/**
 * Local IELTS answer normalization & matching (no external AI/LLM).
 */
const path = require('path');
const fs = require('fs');

const loadJson = (name) => {
  try {
    return JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data', name), 'utf8'));
  } catch (_) {
    return {};
  }
};

const SPELLING = loadJson('ieltsSpellingVariants.json');
const NUMBERS = loadJson('ieltsNumberWords.json');

const ARTICLES = new Set(['a', 'an', 'the']);

const WORD_LIMITS = {
  ONE_WORD: { maxWords: 1, allowNumber: false },
  TWO_WORDS: { maxWords: 2, allowNumber: false },
  THREE_WORDS: { maxWords: 3, allowNumber: false },
  NO_MORE_THAN_TWO_WORDS: { maxWords: 2, allowNumber: false },
  NO_MORE_THAN_THREE_WORDS: { maxWords: 3, allowNumber: false },
  ONE_NUMBER: { maxWords: 1, allowNumber: true, numberOnly: true },
  ONE_WORD_AND_OR_A_NUMBER: { maxWords: 2, allowNumber: true },
  NO_MORE_THAN_TWO_WORDS_AND_OR_A_NUMBER: { maxWords: 3, allowNumber: true },
};

const stripDiacritics = (s) =>
  s.normalize('NFKD').replace(/[\u0300-\u036f]/g, '');

/** Normalize a single answer token/string for comparison. */
const normalizeAnswer = (value) => {
  let s = String(value ?? '');
  s = stripDiacritics(s);
  s = s.replace(/[\u2018\u2019\u201A\u201B]/g, "'");
  s = s.replace(/[\u201C\u201D\u201E\u201F]/g, '"');
  s = s.replace(/[\u2010\u2011\u2012\u2013\u2014\u2015]/g, '-');
  s = s.replace(/[\t\r\n]+/g, ' ');
  s = s.trim().toLowerCase();
  s = s.replace(/^["'`]+|["'`]+$/g, '');
  s = s.replace(/[.,;:!?]+$/g, '');
  s = s.replace(/[.,;:!?'"()_/\\]+/g, ' ');
  s = s.replace(/\s*-\s*/g, '-');
  s = s.replace(/\s+/g, ' ').trim();
  return s;
};

const tokenize = (normalized) => (normalized ? normalized.split(' ').filter(Boolean) : []);

const isNumericToken = (t) => /^-?\d+(\.\d+)?%?$/.test(t) || NUMBERS[t] != null;

const countWordsForLimit = (normalized) => {
  const tokens = tokenize(normalized);
  return tokens.filter((t) => !/^[-–—]$/.test(t)).length;
};

/**
 * @returns {{ ok: boolean, reason?: string }}
 */
const validateWordLimit = (rawStudent, wordLimit) => {
  if (!wordLimit || !WORD_LIMITS[wordLimit]) return { ok: true };
  const rule = WORD_LIMITS[wordLimit];
  const normalized = normalizeAnswer(rawStudent);
  if (!normalized) return { ok: true };

  const tokens = tokenize(normalized);
  if (rule.numberOnly) {
    const allNumeric = tokens.length > 0 && tokens.every(isNumericToken);
    if (!allNumeric) {
      return { ok: false, reason: 'Answer must be a number' };
    }
    return { ok: true };
  }

  const words = countWordsForLimit(normalized);
  if (words > rule.maxWords) {
    return {
      ok: false,
      reason: `Answer exceeds word limit (${wordLimit.replace(/_/g, ' ').toLowerCase()})`,
    };
  }
  return { ok: true };
};

const expandVariants = (normalized) => {
  const set = new Set([normalized]);
  if (!normalized) return set;

  // Spelling variants per token
  const tokens = tokenize(normalized);
  const swapped = tokens.map((t) => SPELLING[t] || t).join(' ');
  set.add(swapped);
  set.add(normalizeAnswer(swapped));

  // Number ↔ word
  if (NUMBERS[normalized]) {
    set.add(normalizeAnswer(NUMBERS[normalized]));
  }
  for (const t of tokens) {
    if (NUMBERS[t]) set.add(normalizeAnswer(tokens.map((x) => (x === t ? NUMBERS[t] : x)).join(' ')));
  }

  // Optional leading article stripping (candidate side)
  const withoutArticle = tokens.filter((t, i) => !(i === 0 && ARTICLES.has(t))).join(' ');
  if (withoutArticle) set.add(withoutArticle);

  // Simple plural: trailing s
  if (normalized.endsWith('s') && normalized.length > 2) {
    set.add(normalized.slice(0, -1));
  } else {
    set.add(`${normalized}s`);
  }

  return set;
};

const stripArticles = (normalized) =>
  tokenize(normalized)
    .filter((t, i) => !(i === 0 && ARTICLES.has(t)))
    .join(' ');

const pluralForms = (normalized) => {
  const forms = new Set([normalized]);
  if (!normalized) return forms;
  if (normalized.endsWith('ies') && normalized.length > 4) {
    forms.add(`${normalized.slice(0, -3)}y`);
  } else if (normalized.endsWith('es') && normalized.length > 3) {
    forms.add(normalized.slice(0, -2));
  } else if (normalized.endsWith('s') && normalized.length > 2) {
    forms.add(normalized.slice(0, -1));
  } else {
    forms.add(`${normalized}s`);
    if (normalized.endsWith('y') && normalized.length > 2) {
      forms.add(`${normalized.slice(0, -1)}ies`);
    }
  }
  return forms;
};

/**
 * Resolve accepted answer config from question document.
 */
const resolveAcceptedConfig = (question) => {
  const meta = question.metadata || {};
  const structured = question.acceptedAnswers || meta.acceptedAnswers || null;

  const primary = structured?.primary
    ?? (Array.isArray(question.answers) && question.answers[0] != null ? question.answers[0] : null);
  const alternatives = [
    ...(structured?.alternatives || []),
    ...(Array.isArray(question.answers) ? question.answers.slice(primary != null ? 1 : 0) : []),
  ].map(String).filter(Boolean);
  const synonyms = (structured?.synonyms || []).map(String).filter(Boolean);
  const rejected = (structured?.rejected || meta.rejectedAnswers || []).map(String).filter(Boolean);
  const explanation = structured?.explanation || meta.explanation || '';

  const allAccepted = [primary, ...alternatives, ...synonyms]
    .filter((v) => v != null && String(v).trim() !== '')
    .map(String);

  // Slash / pipe alternatives inside a single string
  const expanded = [];
  for (const a of allAccepted) {
    if (/[/|]/.test(a)) {
      expanded.push(...a.split(/[/|]/).map((p) => p.trim()).filter(Boolean));
    } else {
      expanded.push(a);
    }
  }

  return {
    accepted: [...new Set(expanded)],
    rejected,
    explanation,
    wordLimit: question.wordLimit || meta.wordLimit || null,
    allowArticles: question.allowArticles === true || meta.allowArticles === true,
    allowPlurals: question.allowPlurals === true || meta.allowPlurals === true,
    instruction: question.instruction || meta.instruction || '',
  };
};

const candidatesMatch = (studentNorm, acceptedNorm, { allowArticles, allowPlurals }) => {
  let studentSet = expandVariants(studentNorm);
  let acceptedSet = expandVariants(acceptedNorm);

  if (allowArticles) {
    studentSet = new Set([...studentSet, stripArticles(studentNorm)]);
    acceptedSet = new Set([...acceptedSet, stripArticles(acceptedNorm)]);
  }
  if (allowPlurals) {
    const moreS = new Set(studentSet);
    const moreA = new Set(acceptedSet);
    for (const s of studentSet) for (const f of pluralForms(s)) moreS.add(f);
    for (const a of acceptedSet) for (const f of pluralForms(a)) moreA.add(f);
    studentSet = moreS;
    acceptedSet = moreA;
  }

  for (const s of studentSet) {
    if (acceptedSet.has(s)) return true;
  }
  return false;
};

/**
 * Score a single student value against accepted list.
 * @returns {{ correct: boolean, reason?: string }}
 */
const matchSingleAnswer = (rawStudent, config) => {
  const limitCheck = validateWordLimit(rawStudent, config.wordLimit);
  if (!limitCheck.ok) {
    return { correct: false, reason: limitCheck.reason };
  }

  const studentNorm = normalizeAnswer(rawStudent);
  if (!studentNorm) return { correct: false, reason: 'Empty answer' };

  for (const rej of config.rejected) {
    if (candidatesMatch(studentNorm, normalizeAnswer(rej), config)) {
      return { correct: false, reason: 'Rejected answer' };
    }
  }

  for (const acc of config.accepted) {
    if (candidatesMatch(studentNorm, normalizeAnswer(acc), config)) {
      return { correct: true };
    }
  }
  return { correct: false };
};

/**
 * Compare student answer (string | array | blank map) to question.
 */
const evaluateAnswer = (question, studentAnswer) => {
  const config = resolveAcceptedConfig(question);
  const meta = question.metadata || {};
  const blanks = question.blanks || meta.blanks || [];
  const selectionMode = question.selectionMode || meta.selectionMode || 'single';

  // Multi-select MCQ: student sends array of options
  if (selectionMode === 'multiple' || Array.isArray(studentAnswer)) {
    const studentVals = (Array.isArray(studentAnswer) ? studentAnswer : [studentAnswer])
      .map((v) => normalizeAnswer(v))
      .filter(Boolean)
      .sort();
    const acceptedVals = config.accepted.map(normalizeAnswer).filter(Boolean).sort();
    const correct =
      studentVals.length === acceptedVals.length
      && studentVals.every((v, i) => v === acceptedVals[i]);
    return {
      correct,
      reason: correct ? undefined : 'Incorrect selection',
      studentAnswer,
      correctAnswers: config.accepted,
      explanation: config.explanation,
    };
  }

  // Blank map: { blankId: value }
  if (studentAnswer && typeof studentAnswer === 'object' && !Array.isArray(studentAnswer)) {
    const entries = blanks.length
      ? blanks.map((b) => [b.id || b.key || String(b.order ?? ''), b])
      : Object.keys(studentAnswer).map((k) => [k, { id: k }]);

    if (entries.length === 0) {
      // Treat as single string field stored under a key — fall through to string
      const first = Object.values(studentAnswer)[0];
      const result = matchSingleAnswer(first, config);
      return {
        ...result,
        studentAnswer,
        correctAnswers: config.accepted,
        explanation: config.explanation,
      };
    }

    // Per-blank accepted answers in metadata.blankAnswers or accepted as "id=value"
    const blankAnswers = meta.blankAnswers || {};
    let allCorrect = true;
    let reason;
    for (const [blankId] of entries) {
      const raw = studentAnswer[blankId];
      const perBlankAccepted = blankAnswers[blankId]
        || config.accepted
          .filter((a) => a.startsWith(`${blankId}=`) || a.startsWith(`${blankId}:`))
          .map((a) => a.split(/[=:]/).slice(1).join('=').trim())
          .filter(Boolean);

      const blankConfig = {
        ...config,
        accepted: perBlankAccepted.length ? perBlankAccepted : config.accepted,
      };
      const result = matchSingleAnswer(raw, blankConfig);
      if (!result.correct) {
        allCorrect = false;
        reason = result.reason || 'Incorrect blank';
        break;
      }
    }
    return {
      correct: allCorrect,
      reason,
      studentAnswer,
      correctAnswers: config.accepted,
      explanation: config.explanation,
    };
  }

  const result = matchSingleAnswer(studentAnswer, config);
  return {
    ...result,
    studentAnswer: studentAnswer ?? null,
    correctAnswers: config.accepted,
    explanation: config.explanation,
  };
};

module.exports = {
  normalizeAnswer,
  validateWordLimit,
  expandVariants,
  resolveAcceptedConfig,
  matchSingleAnswer,
  evaluateAnswer,
  WORD_LIMITS,
  SPELLING,
  NUMBERS,
};
