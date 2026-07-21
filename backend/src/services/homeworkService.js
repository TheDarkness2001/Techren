const mongoose = require('mongoose');
const Word = require('../models/Word');
const Lesson = require('../models/Lesson');
const HomeworkProgress = require('../models/HomeworkProgress');
const Student = require('../models/Student');
const { checkVocabAnswer } = require('../utils/vocabAnswerChecker');
const { normalizeText } = require('../utils/textNormalizer');
const recycleBinService = require('./recycleBinService');

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
  const uzbekMeanings = word.uzbek
    ? word.uzbek.split(',').map((m) => m.trim()).filter(Boolean).slice(0, 3)
    : [];
  const englishForms = word.english
    ? word.english.split(',').map((f) => f.trim()).filter(Boolean).slice(0, 3)
    : [];
  return {
    id: word._id,
    english: word.english,
    uzbek: word.uzbek,
    uzbekMeanings,
    englishForms,
    direction,
  };
};

const getRandomWord = async ({ lessonId, levelId }) => {
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

  const allRanked = records
    .map((p) => ({
      studentId: String(p.studentId),
      name: studentMap.get(String(p.studentId))?.name || 'Unknown',
      studentCode: studentMap.get(String(p.studentId))?.studentId || '',
      profileImage: studentMap.get(String(p.studentId))?.profileImage || null,
      totalAttempts: p.totalAttempts,
      correctAnswers: p.correctAnswers,
      accuracy: p.totalAttempts > 0 ? Math.round((p.correctAnswers / p.totalAttempts) * 100) : 0,
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
  return words.map((w) => ({
    id: w._id,
    english: w.english,
    uzbek: w.uzbek,
    lessonId: w.lessonId,
  }));
};

const addWord = async ({ english, uzbek, lessonId }) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (lesson.maxWords && lesson.wordIds.length >= lesson.maxWords) {
    throw Object.assign(new Error(`Lesson is full. Maximum ${lesson.maxWords} words allowed.`), { statusCode: 400, code: 'LIMIT_REACHED' });
  }

  const trimmedEnglish = normalizeText(english).toLowerCase();
  const trimmedUzbek = normalizeText(uzbek).toLowerCase();
  const duplicate = await Word.findOne({ lessonId, english: trimmedEnglish, uzbek: trimmedUzbek });
  if (duplicate) {
    throw Object.assign(new Error('This word already exists in this lesson'), { statusCode: 409, code: 'DUPLICATE' });
  }

  const word = await Word.create({ english: trimmedEnglish, uzbek: trimmedUzbek, lessonId });
  lesson.wordIds.push(word._id);
  await lesson.save();
  return { id: word._id, english: word.english, uzbek: word.uzbek, lessonId: word.lessonId };
};

const updateWord = async (id, data) => {
  const word = await Word.findById(id);
  if (!word) {
    throw Object.assign(new Error('Word not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (data.english !== undefined) word.english = normalizeText(data.english).toLowerCase();
  if (data.uzbek !== undefined) word.uzbek = normalizeText(data.uzbek).toLowerCase();
  await word.save();
  return { id: word._id, english: word.english, uzbek: word.uzbek, lessonId: word.lessonId };
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
};
