const mongoose = require('mongoose');
const Sentence = require('../models/Sentence');
const Lesson = require('../models/Lesson');
const Level = require('../models/Level');
const Student = require('../models/Student');
const StudentSentenceProgress = require('../models/StudentSentenceProgress');
const { analyzeSentenceAnswer } = require('../utils/sentenceValidator');
const { normalizeText } = require('../utils/textNormalizer');
const {
  getStudentGroupIds,
  isPracticeUnlockedForStudent,
} = require('./examGateService');

const formatSentence = (doc) => ({
  id: doc._id,
  english: doc.english,
  uzbek: doc.uzbek,
  lessonId: doc.lessonId,
  task: doc.task || '',
  imageUrl: doc.imageUrl || '',
});

const buildLessonFilter = async ({ lessonId, levelId }) => {
  if (lessonId) return { lessonId };
  if (levelId) {
    const lessons = await Lesson.find({ levelId, type: 'sentences' }).select('_id');
    return { lessonId: { $in: lessons.map((l) => l._id) } };
  }
  return {};
};

const listSentences = async (query) => {
  const filter = await buildLessonFilter(query);
  const sentences = await Sentence.find(filter).sort({ createdAt: 1 });
  return sentences.map(formatSentence);
};

const getRandomSentence = async (query) => {
  const filter = await buildLessonFilter(query);
  const count = await Sentence.countDocuments(filter);
  if (count === 0) {
    throw Object.assign(new Error('No sentences available'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const random = Math.floor(Math.random() * count);
  const sentence = await Sentence.findOne(filter).skip(random);
  const direction = query.direction === 'uzToEn' ? 'uzToEn' : 'enToUz';
  return { sentence: formatSentence(sentence), direction };
};

const createSentence = async (data) => {
  const sentence = await Sentence.create({
    english: normalizeText(data.english),
    uzbek: normalizeText(data.uzbek),
    lessonId: data.lessonId,
    task: data.task ? normalizeText(data.task) : '',
    imageUrl: typeof data.imageUrl === 'string' ? data.imageUrl.trim() : '',
  });
  return formatSentence(sentence);
};

const updateSentence = async (id, data) => {
  const updates = {};
  if (data.english?.trim()) updates.english = normalizeText(data.english);
  if (data.uzbek?.trim()) updates.uzbek = normalizeText(data.uzbek);
  if (data.lessonId) updates.lessonId = data.lessonId;
  if (data.task !== undefined) updates.task = data.task ? normalizeText(data.task) : '';
  if (data.imageUrl !== undefined) updates.imageUrl = typeof data.imageUrl === 'string' ? data.imageUrl.trim() : '';
  const sentence = await Sentence.findByIdAndUpdate(id, updates, { new: true, runValidators: true });
  if (!sentence) throw Object.assign(new Error('Sentence not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatSentence(sentence);
};

const removeSentence = async (id) => {
  const sentence = await Sentence.findByIdAndDelete(id);
  if (!sentence) throw Object.assign(new Error('Sentence not found'), { statusCode: 404, code: 'NOT_FOUND' });
  await StudentSentenceProgress.deleteMany({ sentenceId: id });
  return formatSentence(sentence);
};

const checkAnswer = async (studentId, { sentenceId, answer, direction }) => {
  if (!sentenceId || !answer?.trim()) {
    throw Object.assign(new Error('Sentence ID and answer are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const sentence = await Sentence.findById(sentenceId);
  if (!sentence) throw Object.assign(new Error('Sentence not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const dir = direction === 'uzToEn' ? 'uzToEn' : 'enToUz';
  const correctAnswer = dir === 'uzToEn' ? sentence.english : sentence.uzbek;
  const analysis = analyzeSentenceAnswer(correctAnswer, normalizeText(answer));

  if (studentId) {
    let progress = await StudentSentenceProgress.findOne({ studentId, sentenceId });
    if (!progress) progress = new StudentSentenceProgress({ studentId, sentenceId });
    progress.attempts += 1;
    if (analysis.isCorrect) progress.correctCount += 1;
    progress.lastPracticeDate = new Date();
    await progress.save();

    if (analysis.isCorrect) {
      const gamificationService = require('./gamificationService');
      await gamificationService.awardXp(studentId, {
        module: 'sentences',
        amount: gamificationService.XP_REWARDS.sentence_correct,
        reason: 'sentence_correct',
      });
    }
  }

  return {
    isCorrect: analysis.isCorrect,
    correctAnswer,
    yourAnswer: answer.trim(),
    similarityScore: analysis.similarityScore,
    categories: analysis.categories,
    diff: analysis.diff,
  };
};

const getProgress = async (studentId) => {
  const progress = await StudentSentenceProgress.find({ studentId });
  const totalAttempts = progress.reduce((sum, p) => sum + p.attempts, 0);
  const totalCorrect = progress.reduce((sum, p) => sum + p.correctCount, 0);
  return {
    totalAttempts,
    totalCorrect,
    accuracy: totalAttempts > 0 ? Math.round((totalCorrect / totalAttempts) * 100) : 0,
    items: progress,
  };
};

const getLeaderboard = async (req) => {
  const records = await StudentSentenceProgress.find().lean();
  const studentMap = new Map();

  for (const record of records) {
    const sid = String(record.studentId);
    if (!studentMap.has(sid)) studentMap.set(sid, { studentId: sid, totalAttempts: 0, totalCorrect: 0 });
    const entry = studentMap.get(sid);
    entry.totalAttempts += record.attempts;
    entry.totalCorrect += record.correctCount;
  }

  const students = await Student.find({ _id: { $in: [...studentMap.keys()] } }).select('name studentId profileImage');
  const studentInfo = new Map(students.map((s) => [String(s._id), s]));

  const allRanked = [...studentMap.values()]
    .map((s) => ({
      studentId: s.studentId,
      name: studentInfo.get(s.studentId)?.name || 'Unknown',
      studentCode: studentInfo.get(s.studentId)?.studentId || '',
      profileImage: studentInfo.get(s.studentId)?.profileImage || null,
      totalAttempts: s.totalAttempts,
      totalCorrect: s.totalCorrect,
      accuracy: s.totalAttempts > 0 ? Math.round((s.totalCorrect / s.totalAttempts) * 100) : 0,
    }))
    .filter((s) => s.totalAttempts > 0)
    .sort((a, b) => b.accuracy - a.accuracy || b.totalCorrect - a.totalCorrect);

  const leaderboard = allRanked.slice(0, 10).map((s, i) => ({ ...s, rank: i + 1 }));

  let currentStudent = null;
  if (req.userType === 'student' && req.user?._id) {
    const sid = String(req.user._id);
    const idx = allRanked.findIndex((s) => s.studentId === sid);
    if (idx >= 0) currentStudent = { ...allRanked[idx], rank: idx + 1, totalStudents: allRanked.length };
  }

  return { leaderboard, currentStudent };
};

const getStudentLessonTree = async (studentId) => {
  const groupIds = await getStudentGroupIds(studentId);
  const levels = await Level.find({ moduleType: 'sentences' });
  const lessons = await Lesson.find({ type: 'sentences' }).sort({ levelId: 1, order: 1 });
  const sentenceCounts = await Sentence.aggregate([
    { $group: { _id: '$lessonId', count: { $sum: 1 } } },
  ]);
  const countMap = new Map(sentenceCounts.map((c) => [String(c._id), c.count]));

  return levels
    .filter((level) => isPracticeUnlockedForStudent(level, groupIds))
    .map((level) => ({
      id: level._id,
      name: level.name,
      languageId: level.languageId,
      lessons: lessons
        .filter((l) => String(l.levelId) === String(level._id))
        .map((lesson) => ({
          id: lesson._id,
          name: lesson.name,
          order: lesson.order,
          sentenceCount: countMap.get(String(lesson._id)) || 0,
          status: lesson.order === 1 ? 'available' : 'locked',
        })),
    }));
};

module.exports = {
  listSentences,
  getRandomSentence,
  createSentence,
  updateSentence,
  removeSentence,
  checkAnswer,
  getProgress,
  getLeaderboard,
  getStudentLessonTree,
};
