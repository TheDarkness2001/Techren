const mongoose = require('mongoose');
const Word = require('../models/Word');
const Lesson = require('../models/Lesson');
const Level = require('../models/Level');
const HomeworkProgress = require('../models/HomeworkProgress');
const Student = require('../models/Student');
const StudentVocabProgress = require('../models/StudentVocabProgress');
const { checkVocabAnswer } = require('../utils/vocabAnswerChecker');
const { canonicalizeVocabPair, mergeVocabPair, isSameVocabItem, splitVocabList } = require('../utils/vocabList');
const recycleBinService = require('./recycleBinService');
const {
  getStudentGroupIds,
  isExamUnlockedForStudent,
  isPracticeUnlockedForStudent,
} = require('./examGateService');

const formatProgress = (progress) => ({
  totalAttempts: progress?.totalAttempts ?? 0,
  correctAnswers: progress?.correctAnswers ?? 0,
  accuracy: progress?.getAccuracy?.() ?? 0,
  enToUzAccuracy: progress?.getEnToUzAccuracy?.() ?? 0,
  uzToEnAccuracy: progress?.getUzToEnAccuracy?.() ?? 0,
  lastUpdated: progress?.lastUpdated,
});

const pickDirection = (lesson) => {
  if (lesson?.directionMode && lesson.directionMode !== 'mixed') return lesson.directionMode;
  return Math.random() < 0.5 ? 'en-to-uz' : 'uz-to-en';
};

const formatWordPrompt = (word, direction) => {
  const uzbekMeanings = splitVocabList(word.uzbek);
  const englishForms = splitVocabList(word.english);
  return {
    id: word._id,
    english: word.english,
    uzbek: word.uzbek,
    uzbekMeanings,
    englishForms,
    direction,
  };
};

const assertStudentCanPracticeLesson = async (studentId, lessonId) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const level = await Level.findById(lesson.levelId);
  if (!level) {
    throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const groupIds = await getStudentGroupIds(studentId);
  if (!isPracticeUnlockedForStudent(level, groupIds)) {
    throw Object.assign(new Error('This practice is locked for your group.'), { statusCode: 403, code: 'PRACTICE_LOCKED' });
  }
  const progress = await StudentVocabProgress.findOne({ studentId, lessonId });
  const examUnlocked = isExamUnlockedForStudent(lesson, groupIds);
  const status =
    progress?.status === 'passed'
      ? 'passed'
      : examUnlocked
        ? progress?.status || 'available'
        : 'locked';
  if (status === 'locked') {
    throw Object.assign(new Error('This lesson is locked. Pass the exam for the previous class, or ask your teacher to unlock it.'), {
      statusCode: 403,
      code: 'LESSON_LOCKED',
    });
  }
  return { lesson, level };
};

const getRandomWord = async ({ lessonId, levelId, studentId }) => {
  if (studentId && lessonId) {
    await assertStudentCanPracticeLesson(studentId, lessonId);
  }

  let filter = {};
  if (lessonId) {
    filter = { lessonId: new mongoose.Types.ObjectId(lessonId) };
  } else if (levelId) {
    const lessons = await Lesson.find({ levelId }).select('_id');
    filter = { lessonId: { $in: lessons.map((l) => l._id) } };
  } else {
    throw Object.assign(new Error('lessonId or levelId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const count = await Word.countDocuments(filter);
  if (count === 0) {
    throw Object.assign(new Error('No words found for the selected criteria'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const [randomWord] = await Word.aggregate([{ $match: filter }, { $sample: { size: 1 } }]);
  const lesson = lessonId ? await Lesson.findById(lessonId).select('directionMode') : null;
  const direction = pickDirection(lesson);
  return formatWordPrompt(randomWord, direction);
};

const checkAnswer = async ({ wordId, answer, answers, direction }) => {
  const word = await Word.findById(wordId);
  if (!word) {
    throw Object.assign(new Error('Word not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return checkVocabAnswer(word, { answer, answers, direction });
};

const submitResult = async (studentId, sessionStats) => {
  if (!sessionStats) {
    throw Object.assign(new Error('Session stats are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  let progress = await HomeworkProgress.findOne({ studentId });
  if (!progress) progress = new HomeworkProgress({ studentId });

  progress.totalAttempts += sessionStats.totalAttempts || 0;
  progress.correctAnswers += sessionStats.correctAnswers || 0;
  progress.enToUzCorrect += sessionStats.enToUzCorrect || 0;
  progress.enToUzTotal += sessionStats.enToUzTotal || 0;
  progress.uzToEnCorrect += sessionStats.uzToEnCorrect || 0;
  progress.uzToEnTotal += sessionStats.uzToEnTotal || 0;
  progress.lastUpdated = new Date();
  await progress.save();

  const correct = sessionStats.correctAnswers || 0;
  if (correct > 0) {
    const gamificationService = require('./gamificationService');
    await gamificationService.awardXp(studentId, {
      module: 'words',
      amount: correct * gamificationService.XP_REWARDS.word_correct,
      reason: 'word_practice',
    });
  }

  return formatProgress(progress);
};

const getProgress = async (studentId) => {
  const progress = await HomeworkProgress.findOne({ studentId });
  return formatProgress(progress);
};

const getLeaderboard = async (req) => {
  const records = await HomeworkProgress.find().lean();
  const studentIds = records.map((p) => p.studentId);
  const students = await Student.find({ _id: { $in: studentIds } }).select('name studentId profileImage');
  const studentMap = new Map(students.map((s) => [String(s._id), s]));
  const StudentGamification = require('../models/StudentGamification');
  const xpDocs = await StudentGamification.find({ studentId: { $in: studentIds } }).select('studentId moduleXp totalXp');
  const xpMap = new Map(xpDocs.map((d) => [String(d.studentId), d]));

  const allRanked = records
    .map((p) => ({
      studentId: String(p.studentId),
      name: studentMap.get(String(p.studentId))?.name || 'Unknown',
      studentCode: studentMap.get(String(p.studentId))?.studentId || '',
      profileImage: studentMap.get(String(p.studentId))?.profileImage || null,
      totalAttempts: p.totalAttempts,
      correctAnswers: p.correctAnswers,
      accuracy: p.totalAttempts > 0 ? Math.round((p.correctAnswers / p.totalAttempts) * 100) : 0,
      xp: xpMap.get(String(p.studentId))?.moduleXp?.words || 0,
      bestStreak: p.bestStreak || 0,
    }))
    .filter((s) => s.totalAttempts > 0)
    .sort((a, b) => b.accuracy - a.accuracy || b.correctAnswers - a.correctAnswers);

  const leaderboard = allRanked.slice(0, 10).map((s, i) => ({ ...s, rank: i + 1 }));

  let currentStudent = null;
  if (req.userType === 'student' && req.user?._id) {
    const sid = String(req.user._id);
    const idx = allRanked.findIndex((s) => s.studentId === sid);
    if (idx >= 0) {
      currentStudent = { ...allRanked[idx], rank: idx + 1, totalStudents: allRanked.length };
    }
  }

  return { leaderboard, currentStudent };
};

const listWords = async (lessonId) => {
  const filter = lessonId ? { lessonId } : {};
  const words = await Word.find(filter).sort({ createdAt: -1 });
  return words.map((w) => formatStoredWord(w));
};

const formatStoredWord = (word, extras = {}) => ({
  id: word._id,
  english: word.english,
  uzbek: word.uzbek,
  englishForms: splitVocabList(word.english),
  uzbekMeanings: splitVocabList(word.uzbek),
  lessonId: word.lessonId,
  ...extras,
});

const addWord = async ({ english, uzbek, lessonId, mergeDuplicates = false }) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const canonical = canonicalizeVocabPair(english, uzbek);
  if (!canonical.english || !canonical.uzbek) {
    throw Object.assign(new Error('English word and Uzbek meaning are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const existingWords = await Word.find({ lessonId });
  const duplicate = existingWords.find((word) => isSameVocabItem(word, canonical));
  if (duplicate) {
    if (mergeDuplicates) {
      const merged = mergeVocabPair(duplicate, canonical);
      duplicate.english = merged.english;
      duplicate.uzbek = merged.uzbek;
      await duplicate.save();
      return formatStoredWord(duplicate, { merged: true });
    }
    throw Object.assign(new Error('This word already exists in this lesson'), { statusCode: 409, code: 'DUPLICATE' });
  }

  if (lesson.maxWords && lesson.wordIds.length >= lesson.maxWords) {
    throw Object.assign(new Error(`Lesson is full. Maximum ${lesson.maxWords} words allowed.`), { statusCode: 400, code: 'LIMIT_REACHED' });
  }

  const word = await Word.create({
    english: canonical.english,
    uzbek: canonical.uzbek,
    lessonId,
  });
  lesson.wordIds.push(word._id);
  await lesson.save();
  return formatStoredWord(word);
};

const updateWord = async (id, data) => {
  const word = await Word.findById(id);
  if (!word) {
    throw Object.assign(new Error('Word not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const nextEnglish = data.english !== undefined ? data.english : word.english;
  const nextUzbek = data.uzbek !== undefined ? data.uzbek : word.uzbek;
  const canonical = canonicalizeVocabPair(nextEnglish, nextUzbek);
  if (!canonical.english || !canonical.uzbek) {
    throw Object.assign(new Error('English word and Uzbek meaning are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  word.english = canonical.english;
  word.uzbek = canonical.uzbek;
  await word.save();
  return formatStoredWord(word);
};

const removeWord = async (id, req) => {
  const word = await Word.findById(id);
  if (!word) {
    throw Object.assign(new Error('Word not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  await Lesson.updateOne({ _id: word.lessonId }, { $pull: { wordIds: word._id } });
  const deletedBy = req?.user?.email || req?.user?._id?.toString() || 'staff';
  await recycleBinService.softDelete('words', id, {
    deletedBy,
    moduleType: 'words',
  });
  return { id };
};

module.exports = {
  getRandomWord,
  checkAnswer,
  submitResult,
  getProgress,
  getLeaderboard,
  listWords,
  addWord,
  updateWord,
  removeWord,
  formatWordPrompt,
  pickDirection,
  assertStudentCanPracticeLesson,
  formatStoredWord,
};
