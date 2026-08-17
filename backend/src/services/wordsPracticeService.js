const crypto = require('crypto');
const Word = require('../models/Word');
const Lesson = require('../models/Lesson');
const HomeworkProgress = require('../models/HomeworkProgress');
const { checkVocabAnswer } = require('../utils/vocabAnswerChecker');
const { splitVocabList } = require('../utils/vocabList');
const { getTashkentParts } = require('../utils/classWindow');
const { shuffle, scrambleWord, maskWord } = require('../utils/wordsPracticeFormat');
const homeworkService = require('./homeworkService');
const gamificationService = require('./gamificationService');
const lessonService = require('./lessonService');

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

const DAILY_XP_CAP = 200;
const PER_CORRECT_XP = gamificationService.XP_REWARDS.word_correct || 5;
const QUESTION_TTL_MS = 10 * 60 * 1000;
const pendingQuestions = new Map();

const pick = (items) => items[Math.floor(Math.random() * items.length)];

const cleanupPending = () => {
  const now = Date.now();
  for (const [id, question] of pendingQuestions.entries()) {
    if (question.expiresAt <= now) pendingQuestions.delete(id);
  }
};

const storeQuestion = (payload) => {
  cleanupPending();
  const id = crypto.randomUUID();
  pendingQuestions.set(id, { ...payload, expiresAt: Date.now() + QUESTION_TTL_MS });
  return id;
};

const takeQuestion = (questionId, studentId) => {
  const question = pendingQuestions.get(questionId);
  if (!question || question.expiresAt <= Date.now()) {
    pendingQuestions.delete(questionId);
    throw Object.assign(new Error('This question expired. Get the next word.'), { statusCode: 400, code: 'QUESTION_EXPIRED' });
  }
  if (String(question.studentId) !== String(studentId)) {
    throw Object.assign(new Error('This question does not belong to you.'), { statusCode: 403, code: 'FORBIDDEN' });
  }
  pendingQuestions.delete(questionId);
  return question;
};

const loadLessonWords = async (studentId, lessonId, { requireStudent = true } = {}) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (requireStudent && studentId) {
    await homeworkService.assertStudentCanPracticeLesson(studentId, lessonId);
  }
  const words = await Word.find({ lessonId: lesson._id });
  if (words.length === 0) {
    throw Object.assign(new Error('No words found for this lesson'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return { lesson, words };
};

const resolveDirection = (lesson, requested) => {
  if (requested === 'en-to-uz' || requested === 'uz-to-en') {
    if (lesson.directionMode && lesson.directionMode !== 'mixed' && lesson.directionMode !== requested) {
      return lesson.directionMode;
    }
    return requested;
  }
  return homeworkService.pickDirection(lesson);
};

const publicQuestion = (id, question) => {
  const base = {
    questionId: id,
    mode: question.mode,
    direction: question.direction,
    promptText: question.promptText,
    hint: question.hint || null,
    timeLimitMs: question.timeLimitMs || null,
  };
  if (question.choices) base.choices = question.choices;
  if (question.statement) base.statement = question.statement;
  if (question.masked) base.masked = question.masked;
  if (question.scrambled) base.scrambled = question.scrambled;
  if (question.cards) base.cards = question.cards;
  return base;
};

const buildTypedQuestion = (word, lesson, mode, requestedDirection) => {
  const direction = resolveDirection(lesson, requestedDirection);
  const forms = splitVocabList(word.english);
  const meanings = splitVocabList(word.uzbek);
  const targetForm = pick(forms);
  const promptText = direction === 'en-to-uz' ? forms.join(', ') : pick(meanings);
  return {
    wordId: String(word._id),
    lessonId: String(lesson._id),
    mode,
    direction,
    promptText,
    expectedForm: targetForm,
    checkDirection: direction,
  };
};

const buildMultipleChoice = (word, words, lesson, requestedDirection) => {
  const direction = resolveDirection(lesson, requestedDirection);
  const forms = splitVocabList(word.english);
  const meanings = splitVocabList(word.uzbek);
  const correct = direction === 'en-to-uz' ? pick(meanings) : pick(forms);
  const pool = words
    .filter((item) => String(item._id) !== String(word._id))
    .map((item) => (direction === 'en-to-uz' ? pick(splitVocabList(item.uzbek)) : pick(splitVocabList(item.english))))
    .filter((item) => item && item.toLowerCase() !== correct.toLowerCase());
  const distractors = shuffle([...new Set(pool)]).slice(0, 3);
  while (distractors.length < 3) distractors.push(`option ${distractors.length + 1}`);
  const choices = shuffle([correct, ...distractors.slice(0, 3)]);
  return {
    wordId: String(word._id),
    lessonId: String(lesson._id),
    mode: 'multipleChoice',
    direction,
    promptText: direction === 'en-to-uz' ? forms.join(', ') : pick(meanings),
    choices,
    correctChoice: correct,
    checkDirection: direction,
  };
};

const buildTrueFalse = (word, words, lesson, requestedDirection) => {
  const direction = resolveDirection(lesson, requestedDirection);
  const forms = splitVocabList(word.english);
  const meanings = splitVocabList(word.uzbek);
  const english = forms.join(', ');
  const trueUzbek = pick(meanings);
  const others = words
    .filter((item) => String(item._id) !== String(word._id))
    .flatMap((item) => splitVocabList(item.uzbek));
  const isTrue = others.length === 0 ? true : Math.random() < 0.5;
  const shownUzbek = isTrue ? trueUzbek : pick(others) || trueUzbek;
  return {
    wordId: String(word._id),
    lessonId: String(lesson._id),
    mode: 'trueFalse',
    direction,
    promptText: english,
    statement: `${english} = ${shownUzbek}`,
    isTrue: shownUzbek.toLowerCase() === trueUzbek.toLowerCase() || meanings.some((m) => m.toLowerCase() === shownUzbek.toLowerCase()),
    checkDirection: direction,
  };
};

const buildFormQuestion = (word, lesson, mode) => {
  const forms = splitVocabList(word.english);
  const meanings = splitVocabList(word.uzbek);
  const targetForm = pick(forms);
  return {
    wordId: String(word._id),
    lessonId: String(lesson._id),
    mode,
    direction: 'form',
    promptText: pick(meanings),
    hint: pick(meanings),
    expectedForm: targetForm,
    masked: mode === 'missingLetters' ? maskWord(targetForm) : undefined,
    scrambled: mode === 'scramble' ? scrambleWord(targetForm) : undefined,
    checkDirection: 'form',
  };
};

const buildMemoryQuestion = (words, lesson) => {
  const selected = shuffle(words).slice(0, Math.min(6, words.length));
  const cards = [];
  for (const word of selected) {
    const wordId = String(word._id);
    cards.push({ id: `${wordId}-en`, wordId, side: 'en', text: splitVocabList(word.english).join(', ') });
    cards.push({ id: `${wordId}-uz`, wordId, side: 'uz', text: pick(splitVocabList(word.uzbek)) });
  }
  return {
    lessonId: String(lesson._id),
    mode: 'memory',
    direction: 'mixed',
    promptText: 'Match English with Uzbek',
    cards: shuffle(cards),
    pairCount: selected.length,
    checkDirection: 'memory',
  };
};

const nextQuestion = async (studentId, { lessonId, mode = 'classic', direction, rushStep = 0, userType }) => {
  if (!PRACTICE_MODES.includes(mode)) {
    throw Object.assign(new Error('Unknown practice mode'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const requireStudent = userType === 'student';
  const { lesson, words } = await loadLessonWords(studentId, lessonId, { requireStudent });
  const word = pick(words);

  let payload;
  if (mode === 'multipleChoice') payload = buildMultipleChoice(word, words, lesson, direction);
  else if (mode === 'trueFalse') payload = buildTrueFalse(word, words, lesson, direction);
  else if (mode === 'missingLetters' || mode === 'scramble') payload = buildFormQuestion(word, lesson, mode);
  else if (mode === 'memory') payload = buildMemoryQuestion(words, lesson);
  else payload = buildTypedQuestion(word, lesson, mode, direction);

  if (mode === 'wordRush') {
    payload.timeLimitMs = Math.max(3000, 10000 - Number(rushStep || 0) * 500);
  }

  payload.studentId = String(studentId || 'staff');
  payload.issuedAt = Date.now();
  const questionId = storeQuestion(payload);
  return publicQuestion(questionId, payload);
};

const getOrCreateProgress = async (studentId) => {
  let progress = await HomeworkProgress.findOne({ studentId });
  if (!progress) progress = new HomeworkProgress({ studentId });
  return progress;
};

const awardCappedXp = async (studentId, amount, progress) => {
  if (!studentId || amount <= 0) return 0;
  const today = getTashkentParts().dateString;
  if (progress.practiceXpDate !== today) {
    progress.practiceXpDate = today;
    progress.practiceXpToday = 0;
  }
  const remaining = Math.max(0, DAILY_XP_CAP - (progress.practiceXpToday || 0));
  const granted = Math.min(amount, remaining);
  if (granted <= 0) return 0;
  progress.practiceXpToday += granted;
  await gamificationService.awardXp(studentId, {
    module: 'words',
    amount: granted,
    reason: 'word_practice',
  });
  return granted;
};

const recordAttempt = async (studentId, lessonId, { isCorrect, direction, mode, streak, timeAttackScore, timeAttackDuration, wordRushScore }) => {
  const progress = await getOrCreateProgress(studentId);
  progress.totalAttempts += 1;
  if (isCorrect) progress.correctAnswers += 1;
  if (direction === 'en-to-uz') {
    progress.enToUzTotal += 1;
    if (isCorrect) progress.enToUzCorrect += 1;
  } else if (direction === 'uz-to-en') {
    progress.uzToEnTotal += 1;
    if (isCorrect) progress.uzToEnCorrect += 1;
  }

  if (mode === 'streak' || mode === 'classic' || mode === 'timeAttack' || mode === 'wordRush') {
    progress.currentStreak = isCorrect ? (progress.currentStreak || 0) + 1 : 0;
    if (typeof streak === 'number') progress.currentStreak = streak;
    progress.bestStreak = Math.max(progress.bestStreak || 0, progress.currentStreak || 0);
  }
  if (mode === 'timeAttack' && timeAttackScore != null && [30, 60, 90].includes(Number(timeAttackDuration))) {
    const key = String(Number(timeAttackDuration));
    if (!progress.bestTimeAttack) progress.bestTimeAttack = {};
    progress.bestTimeAttack[key] = Math.max(progress.bestTimeAttack[key] || 0, timeAttackScore);
    progress.markModified('bestTimeAttack');
  }
  if (mode === 'wordRush' && wordRushScore != null) {
    progress.bestWordRush = Math.max(progress.bestWordRush || 0, wordRushScore);
  }

  let xpAwarded = 0;
  if (isCorrect) {
    let amount = PER_CORRECT_XP;
    if (mode === 'streak' && (progress.currentStreak || 0) > 0 && progress.currentStreak % 10 === 0) {
      amount += 5;
    }
    xpAwarded = await awardCappedXp(studentId, amount, progress);
  }
  progress.lastUpdated = new Date();
  await progress.save();

  if (lessonId) {
    await lessonService.updatePracticeStats(studentId, lessonId, {
      attempts: 1,
      correct: isCorrect ? 1 : 0,
    });
  }

  return {
    xpAwarded,
    currentStreak: progress.currentStreak || 0,
    bestStreak: progress.bestStreak || 0,
    bestTimeAttack: progress.bestTimeAttack || {},
    bestWordRush: progress.bestWordRush || 0,
    accuracy: progress.getAccuracy(),
    correctAnswers: progress.correctAnswers,
    totalAttempts: progress.totalAttempts,
    dailyXpRemaining: Math.max(0, DAILY_XP_CAP - (progress.practiceXpToday || 0)),
  };
};

const submitAnswer = async (studentId, body = {}, { userType } = {}) => {
  const question = takeQuestion(body.questionId, String(studentId || 'staff'));
  if (userType === 'student' && question.lessonId) {
    await homeworkService.assertStudentCanPracticeLesson(studentId, question.lessonId);
  }

  if (question.mode === 'wordRush' && question.timeLimitMs) {
    const elapsed = Date.now() - question.issuedAt;
    if (elapsed > question.timeLimitMs + 2000) {
      const stats = await recordAttempt(studentId, question.lessonId, {
        isCorrect: false,
        direction: question.direction,
        mode: question.mode,
        streak: 0,
      });
      return { isCorrect: false, correctAnswer: question.expectedForm || '', userAnswer: '', timedOut: true, stats };
    }
  }

  let isCorrect = false;
  let correctAnswer = '';
  let userAnswer = '';

  if (question.mode === 'memory') {
    const matches = Array.isArray(body.matches) ? body.matches : [];
    const byId = new Map((question.cards || []).map((card) => [card.id, card]));
    const used = new Set();
    let correctPairs = 0;
    for (const pair of matches) {
      const left = byId.get(pair[0] || pair.a);
      const right = byId.get(pair[1] || pair.b);
      if (!left || !right) continue;
      if (used.has(left.id) || used.has(right.id)) continue;
      if (left.wordId === right.wordId && left.side !== right.side) {
        correctPairs += 1;
        used.add(left.id);
        used.add(right.id);
      }
    }
    isCorrect = correctPairs === (question.pairCount || 0) && matches.length >= (question.pairCount || 0);
    correctAnswer = `${question.pairCount} matches`;
    userAnswer = `${correctPairs} matches`;
  } else if (question.mode === 'trueFalse') {
    const value = body.answer === true || String(body.answer).toLowerCase() === 'true';
    isCorrect = value === Boolean(question.isTrue);
    correctAnswer = question.isTrue ? 'true' : 'false';
    userAnswer = value ? 'true' : 'false';
  } else if (question.mode === 'multipleChoice') {
    const choice = String(body.answer || '').trim();
    isCorrect = choice.toLowerCase() === String(question.correctChoice || '').toLowerCase();
    correctAnswer = question.correctChoice;
    userAnswer = choice;
  } else {
    const word = await Word.findById(question.wordId);
    if (!word) {
      throw Object.assign(new Error('Word not found'), { statusCode: 404, code: 'NOT_FOUND' });
    }
    const result = checkVocabAnswer(word, {
      answer: body.answer,
      answers: body.answers,
      direction: question.checkDirection === 'form' ? 'form' : question.direction,
      expectedForm: question.expectedForm,
    });
    isCorrect = result.isCorrect;
    correctAnswer = result.correctAnswer;
    userAnswer = result.userAnswer;
  }

  if (userType !== 'student') {
    return { isCorrect, correctAnswer, userAnswer, direction: question.direction, mode: question.mode, stats: null };
  }

  const stats = await recordAttempt(studentId, question.lessonId, {
    isCorrect,
    direction: question.direction,
    mode: question.mode,
    streak: body.streak,
    timeAttackScore: body.timeAttackScore,
    timeAttackDuration: body.timeAttackDuration,
    wordRushScore: body.wordRushScore,
  });

  return { isCorrect, correctAnswer, userAnswer, direction: question.direction, mode: question.mode, stats };
};

const getPracticeStats = async (studentId) => {
  const progress = await HomeworkProgress.findOne({ studentId });
  if (!progress) {
    return {
      accuracy: 0,
      correctAnswers: 0,
      totalAttempts: 0,
      currentStreak: 0,
      bestStreak: 0,
      bestTimeAttack: { 30: 0, 60: 0, 90: 0 },
      bestWordRush: 0,
    };
  }
  return {
    accuracy: progress.getAccuracy(),
    correctAnswers: progress.correctAnswers,
    totalAttempts: progress.totalAttempts,
    currentStreak: progress.currentStreak || 0,
    bestStreak: progress.bestStreak || 0,
    bestTimeAttack: progress.bestTimeAttack || { 30: 0, 60: 0, 90: 0 },
    bestWordRush: progress.bestWordRush || 0,
  };
};

module.exports = {
  PRACTICE_MODES,
  DAILY_XP_CAP,
  nextQuestion,
  submitAnswer,
  getPracticeStats,
  scrambleWord,
  maskWord,
  pendingQuestions,
};
